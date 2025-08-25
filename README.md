# TacticalRMM Agent Installation & Management Script

This repository contains a **one-line installation, update, and removal script** for the TacticalRMM agent on Linux systems.

The script is designed for reliability and flexibility, supporting multiple system architectures and ensuring smooth deployment across different environments.

---

## 📌 Table of Contents

* [Supported Architectures & Platforms](#supported-architectures--platforms)
* [Script Download & Setup](#script-download--setup)
* [Fix Blank Screen on Ubuntu](#fix-blank-screen-for-ubuntu-workstations-16)
* [Automatic Architecture Detection](#automatic-architecture-detection)
* [Install the Agent](#install-the-agent)
* [Update the Agent](#update-the-agent)
* [Uninstall the Agent](#uninstall-the-agent)
* [Installation Wiki](https://github.com/Brandon-Roff/LinuxRMM-Script/wiki)
* [Credits](#credits)

---

## ✅ Supported Architectures & Platforms

* **x86\_64 (AMD/Intel 64-bit)**
* **x86 (32-bit)**
* **ARM64 (aarch64, Raspberry Pi 4, Apple M1/M2)**
* **ARMv6 / ARMv7 (Raspberry Pi Zero, Pi 2/3 series)**

### Tested On

* Debian 10, 11, 12
* Ubuntu 22.04
* Raspbian (Pi 2, 3, 3B+, 3A, 4B, Pi Zero)
* Cloud VPS providers
* Proxmox VMs

> ⚠️ Raspberry Pi Zero is **not recommended** due to performance limitations.

Future support for additional platforms will be added.

---

## 📥 Script Download & Setup

Download the script:

```bash
wget https://raw.githubusercontent.com/Brandon-Roff/LinuxRMM-Script/refs/heads/main/rmmagent-linux.sh
```

Make it executable:

```bash
sudo chmod +x rmmagent-linux.sh
```

📖 Full installation guide available here: [Installation Wiki](https://github.com/Brandon-Roff/LinuxRMM-Script/wiki)

---

## 🖥️ Fix Blank Screen for Ubuntu Workstations (16+)

Ubuntu uses **Wayland** by default, which may cause **MeshCentral** remote desktop sessions to display a blank screen.

Run the following commands to switch back to X11:

```bash
sudo sed -i '/WaylandEnable/s/^#//g' /etc/gdm3/custom.conf
sudo systemctl restart gdm
```

> 🔹 On Ubuntu 19 and earlier, the file path is `/etc/gdm/custom.conf`.

After restarting, remote desktop functionality will work properly.

---

## ⚙️ Automatic Architecture Detection

The script automatically detects system architecture using `uname -m` and maps it to the correct agent type:

* `x86_64` → **amd64**
* `i386` / `i686` → **x86**
* `aarch64` → **arm64**
* `armv7l` → **armv6**
* `armv6l` → **armv6**

If the architecture is unrecognized, the script exits safely with an error message.

---

## 🚀 Install the Agent

Run the script with the following syntax:

```bash
./rmmagent-linux.sh install 'Mesh Agent URL' 'API URL' ClientID SiteID 'Auth Key' 'Agent Type'
```

### Parameters:

1. **Mesh Agent URL** – Provided by MeshCentral (`Add Agent > Installation Executable Linux/BSD/macOS`). Copy only the base URL, leaving out install flags.
2. **API URL** – TacticalRMM API endpoint, usually `https://api.example.com`.
3. **Client ID** – Visible when hovering over the client name in TacticalRMM.
4. **Site ID** – Visible when hovering over the site name in TacticalRMM.
5. **Auth Key** – Generated under `Agents > Install Agent (Windows) > Manual`. Copy the value after `--auth`.
6. **Agent Type** – `server` or `workstation`.

### Example:

```bash
./rmmagent-linux.sh install 'https://mesh.example.com/meshagents?id=XXXXX' 'https://api.example.com' 3 1 'XXXXX' server
```

⏳ *Note: Compilation may take several minutes depending on hardware. Please be patient.*

---

## 🔄 Update the Agent

To update an installed agent:

```bash
./rmmagent-linux.sh update
```

---

## ❌ Uninstall the Agent

To remove the agent:

```bash
./rmmagent-linux.sh uninstall 'Mesh FQDN' 'Mesh ID'
```

### Parameters:

* **Mesh FQDN** – Example: `mesh.example.com`
* **Mesh ID** – 64-character alphanumeric ID (Linux/BSD uninstall instructions in MeshCentral).

### Example:

```bash
./rmmagent-linux.sh uninstall mesh.example.com 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
```

⚠️ **Important Notes:**

* Only use this method if agent removal in TacticalRMM is not working.
* This process **does not remove records** from TacticalRMM or MeshCentral dashboards. Cleanup must be done manually.

---

## 📌 Credits

This project is based on [Netvolt’s LinuxRMM-Script](https://github.com/netvolt/LinuxRMM-Script), with extended compatibility and refinements.

---

✨ **Professional, robust, and multi-platform ready — the easiest way to manage TacticalRMM agents on Linux.**
