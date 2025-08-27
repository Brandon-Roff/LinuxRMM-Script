#!/bin/bash
# Tactical RMM Linux installer/updater/uninstaller

set -euo pipefail

#--- cleanup trap --------------------------------------------------------------
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf /tmp/temp_rmmagent \
           /tmp/rmmagent-master \
           /tmp/meshagent \
           /tmp/meshagent.msh \
           /tmp/golang.tar.gz \
           ./go 2>/dev/null || true
}
trap cleanup EXIT

#--- safety: require root -------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root (e.g. sudo $0 ...)"
    exit 1
fi

#--- usage / guards -------------------------------------------------------------
if [[ -z "${1:-}" ]]; then
    echo "First argument is empty!"
    echo "Type 'help' for more information"
    exit 1
fi

if [[ "$1" == "help" ]]; then
    cat <<'EOF'
There is help, but more information is available at:
  github.com/Brandon-Roff/LinuxRMM-Script

List of INSTALL arguments (positional, no names):
  Arg 1: 'install'
  Arg 2: Mesh agent BASE URL (WITHOUT &installflags / &meshinstall)
         e.g. https://mesh.example.com/meshagents?id=ENCODED_ID
  Arg 3: RMM API URL (e.g. https://rmm-api.example.com)
  Arg 4: Client ID
  Arg 5: Site ID
  Arg 6: Auth Key
  Arg 7: Agent Type: 'server' or 'workstation'

List of UPDATE arguments:
  Arg 1: 'update'

List of UNINSTALL arguments:
  Arg 1: 'uninstall'
  Arg 2: Mesh agent FQDN (e.g. mesh.example.com)
  Arg 3: Mesh agent id (wrap in single quotes if it contains special chars)


  Install:
    sudo bash rmmagent-linux.sh install \
      "https://mesh.example.com/meshagents?id=ENCODED_ID" \
      "https://rmm-api.example.com" \
      1 2 "SuperSecretAuthKey" server

  Update:
    sudo bash rmmagent-linux.sh update

  Uninstall:
    sudo bash rmmagent-linux.sh uninstall mesh.bjr-home.uk 'your_mesh_id_here'
EOF
    exit 0
fi

if [[ "$1" != "install" && "$1" != "update" && "$1" != "uninstall" ]]; then
    echo "First argument can only be 'install' or 'update' or 'uninstall'!"
    echo "Type 'help' for more information"
    exit 1
fi

#--- arch detection -------------------------------------------------------------
system=$(uname -m)
case "$system" in
    x86_64) system="amd64" ;;
    i386|i686) system="x86" ;;
    aarch64) system="arm64" ;;
    armv6l) system="armv6" ;;
    armv7l) system="armv6" ;;   # Mesh uses the armv6 build/flag for armv7
    *) echo "Unsupported architecture: $system"; exit 1 ;;
esac

#--- inputs --------------------------------------------------------------------
mesh_url=$2           # for install: base mesh url WITHOUT flags
rmm_url=$3
rmm_client_id=$4
rmm_site_id=$5
rmm_auth=$6
rmm_agent_type=$7

# for uninstall path:
mesh_fqdn=$2          # fqdn like mesh.example.com
mesh_id=$3            # mesh agent id

#--- versions / URLs -----------------------------------------------------------
go_version="1.24.6"
go_url_amd64="https://go.dev/dl/go${go_version}.linux-amd64.tar.gz"
go_url_x86="https://go.dev/dl/go${go_version}.linux-386.tar.gz"
go_url_arm64="https://go.dev/dl/go${go_version}.linux-arm64.tar.gz"
go_url_armv6="https://go.dev/dl/go${go_version}.linux-armv6l.tar.gz"

# Mesh flags by arch
mesh_amd64="&installflags=0&meshinstall=6"
mesh_arm6l="&installflags=0&meshinstall=25"
mesh_arm64="&installflags=0&meshinstall=26"

#--- helpers -------------------------------------------------------------------
function go_install() {
    if ! command -v go >/dev/null 2>&1; then
        echo "Installing Go $go_version for $system..."
        case "$system" in
            amd64) url="$go_url_amd64" ;;
            x86)   url="$go_url_x86" ;;
            arm64) url="$go_url_arm64" ;;
            armv6) url="$go_url_armv6" ;;
        esac
        wget -O /tmp/golang.tar.gz "$url"
        rm -rf /usr/local/go/
        tar -xvzf /tmp/golang.tar.gz -C /usr/local/

        # ensure /usr/local/go/bin is on PATH for this session and future logins
        export PATH=/usr/local/go/bin:$PATH
        if ! grep -q "/usr/local/go/bin" /etc/profile; then
            echo 'export PATH=/usr/local/go/bin:$PATH' >> /etc/profile
        fi
        echo "Go is installed."
    fi
}

function agent_compile() {
    echo "Compiling Tactical RMM agent for $system..."
    wget -O /tmp/rmmagent.tar.gz "https://github.com/amidaware/rmmagent/archive/refs/heads/master.tar.gz"
    tar -xf /tmp/rmmagent.tar.gz -C /tmp/
    cd /tmp/rmmagent-master

    case "$system" in
        amd64) env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-s -w" -o /tmp/temp_rmmagent ;;
        x86)   env CGO_ENABLED=0 GOOS=linux GOARCH=386   go build -ldflags "-s -w" -o /tmp/temp_rmmagent ;;
        arm64) env CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags "-s -w" -o /tmp/temp_rmmagent ;;
        armv6) env CGO_ENABLED=0 GOOS=linux GOARCH=arm   go build -ldflags "-s -w" -o /tmp/temp_rmmagent ;;
    esac

    cd /tmp
    echo "Agent compiled."
}

function update_agent() {
    echo "Updating tacticalagent binary..."
    systemctl stop tacticalagent || true
    install -m 0755 /tmp/temp_rmmagent /usr/local/bin/rmmagent
    systemctl start tacticalagent || true
    echo "Update complete."
}

function install_agent() {
    echo "Installing tacticalagent service..."
    install -m 0755 /tmp/temp_rmmagent /usr/local/bin/rmmagent
    /usr/local/bin/rmmagent -m install \
        -api "$rmm_url" \
        -client-id "$rmm_client_id" \
        -site-id "$rmm_site_id" \
        -agent-type "$rmm_agent_type" \
        -auth "$rmm_auth"

    cat >/etc/systemd/system/tacticalagent.service <<'EOF'
[Unit]
Description=Tactical RMM Linux Agent
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/rmmagent -m svc
User=root
Group=root
Restart=always
RestartSec=5s
LimitNOFILE=1000000
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now tacticalagent
    echo "tacticalagent service installed and started."
}

function install_mesh() {
    echo "Installing MeshCentral agent for $system..."
    case "$system" in
        amd64) mesh_param="$mesh_amd64" ;;
        armv6) mesh_param="$mesh_arm6l" ;;
        arm64) mesh_param="$mesh_arm64" ;;
        x86)   mesh_param="$mesh_amd64" ;; # adjust if Mesh supports 32-bit properly
        *) echo "No Mesh installer flag for this architecture: $system"; exit 1 ;;
    esac

    # Expect mesh_url to be base URL WITHOUT flags; we append the arch flags here
    full_mesh_url="${mesh_url}${mesh_param}"

    wget -O /tmp/meshagent "$full_mesh_url"
    chmod +x /tmp/meshagent
    mkdir -p /opt/tacticalmesh
    /tmp/meshagent -install --installPath="/opt/tacticalmesh"
    systemctl enable --now meshagent
    systemctl restart meshagent
    echo "Mesh agent installed."
}

function uninstall_agent() {
    echo "Uninstalling tacticalagent..."
    systemctl stop tacticalagent || true
    systemctl disable tacticalagent || true
    rm -f /etc/systemd/system/tacticalagent.service
    systemctl daemon-reload
    rm -f /usr/local/bin/rmmagent
    rm -rf /etc/tacticalagent
    echo "tacticalagent uninstalled."
}

function uninstall_mesh() {
    echo "Uninstalling MeshCentral agent..."
    if [[ -z "$mesh_fqdn" || -z "$mesh_id" ]]; then
        echo "Mesh FQDN and Mesh ID are required for uninstall."
        exit 1
    fi

    # Try with proxy and without proxy
    wget "https://${mesh_fqdn}/meshagents?script=1" -O /tmp/meshinstall.sh \
        || wget "https://${mesh_fqdn}/meshagents?script=1" --no-proxy -O /tmp/meshinstall.sh

    chmod 755 /tmp/meshinstall.sh
    /tmp/meshinstall.sh uninstall "https://${mesh_fqdn}" "$mesh_id" || true
    echo "Mesh agent uninstall attempted (see messages above)."
}

#--- dispatcher ----------------------------------------------------------------
case "$1" in
    install)
        go_install
        install_mesh
        agent_compile
        install_agent
        echo "Tactical Agent Install is done"
        ;;
    update)
        go_install
        agent_compile
        update_agent
        echo "Tactical Agent Update is done"
        ;;
    uninstall)
        uninstall_agent
        uninstall_mesh
        echo "Tactical Agent Uninstall is done"
        ;;
esac
