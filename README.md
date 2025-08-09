# RMM Agent Script
Script for one-line installation and updating of the tacticalRMM agent

Where possible i wil try to help technically



> Scripts works with AMD(X64), x86 Arm64, arm6/7 I have tested the code on Debian 10, 11, 12 and ubuntu 22.04, both bare metal and ProxmoxVMS and using Cloud VPS, also works on raspbain (Raspberry Pi OS) On both Raspberry Pi 2,3b, 3b+, 3A, 4B and Pi 0 (Not recommended)


Scripts for other platforms will be available later as we adapt the script to other platforms.
Feel free to adapt the script and submit changes that will contribute!

# Usage

### Tips

Download script with this url: `https://raw.githubusercontent.com/Brandon-Roff/LinuxRMM-Script/refs/heads/main/rmmagent-linux.sh`

For Ubuntu systems try: `wget https://raw.githubusercontent.com/Brandon-Roff/LinuxRMM-Script/refs/heads/main/rmmagent-linux.sh` 
Make executable after downloading with: `sudo chmod +x rmmagent-linux.sh`

### Fix Blank Screen for Ubuntu Workstations (Ubuntu 16+)
Ubuntu uses the Wayland display manager instead of the regular X11 server. This causes MeshCentral to show a blank screen, preventing login, viewing, or controlling the client.
Using the command lines below should solve the problem:
```
sudo sed -i '/WaylandEnable/s/^#//g' /etc/gdm3/custom.conf
sudo systemctl restart gdm
```
This will cause your screen to go blank for a second. You will be able to use remote desktop afterwards.
> If you encounter a 'file not found' error, you are likely using Ubuntu 19 or earlier. On these machines, the config file will be located on /etc/gdm/custom.conf. Modify the command above accordingly. <
Please note that remote desktop features are only installed when you used the workstation agent. You may need to reinstall your mesh agent.


## Automatically Detect System Architecture  

The system architecture is now detected automatically using the following logic:  

1. The `uname -m` command retrieves the current system's architecture.  
2. A `case` statement then checks the architecture and maps it to a standard format:  
   - `x86_64` → `amd64` (for 64-bit Intel/AMD processors)  
   - `i386` or `i686` → `x86` (for older 32-bit Intel processors)  
   - `aarch64` → `arm64` (for 64-bit ARM processors, like Raspberry Pi 4 and Apple M1/M2 chips)  
   - `armv7l` → `armv6` (For Slightly New ARM Devices
   - `armv6l` → `armv6` (for older ARM devices, like Raspberry Pi Zero)  
3. If the architecture isn't recognized, an error message is displayed, and the script exits to prevent issues.  

This ensures the script adapts to different system types automatically without needing manual input.


## Install
To install the agent, launch the script with this argument:

```bash
./rmmagent-linux.sh install 'Mesh agent' 'API URL' 'Client ID' 'Site ID' 'Auth Key' 'Agent Type'
```
The compiling can be quite long, don't panic and wait few minutes... USE THE 'SINGLE QUOTES' IN ALL FIELDS!

The arguments are:



1. Mesh agent

  The url given by mesh for installing new agent.
  Go to mesh.example.com > Add agent > Installation Executable Linux / BSD / macOS > **Select the good system type**
  Copy **ONLY** the URL with the quote but Leaving out `&installflags=x&meshinstall=XX` this is determined by CPU Type.
  
1. API URL

  Your api URL for agent communication usually https://api.example.com.
  
3. Client ID

  The ID of the client in wich agent will be added.
  Can be viewed by hovering over the name of the client in the dashboard.
  
4. Site ID

  The ID of the site in wich agent will be added.
  Can be viewed by hovering over the name of the site in the dashboard.
  
5. Auth Key

  Authentification key given by dashboard by going to dashboard > Agents > Install agent (Windows) > Select manual and show
  Copy **ONLY** the key after *--auth*.
  
6. Agent Type

  Can be *server* or *workstation* and define the type of agent.
  
### Example
```bash
./rmmagent-linux.sh install 'https://mesh.example.com/meshagents?id=XXXXX' 'https://api.example.com' 3 1 'XXXXX' server
```

## Update

Simply launch the script with *update* as argument.

```bash
./rmmagent-linux.sh update
```

## Uninstall
To uninstall the agent, launch the script with this argument:

```bash
./rmmagent-linux.sh uninstall 'Mesh FQDN' 'Mesh ID'
```
Note: Single quotes must be around the Mesh ID for it to uninstall the mesh agent properly

The argument are:

2. Mesh FQDN

  Example of FQDN: mesh.example.com 

3. Mesh ID

  The ID given by mesh for installing new agent.

  Go to mesh.example.com > Add agent > Linux / BSD (Uninstall) > Copy **ONLY** the last value with the single quotes.
  You are looking for a 64 charaters long value of random letter case, numbers, and special characters.

### Example
```bash
./rmmagent-linux.sh uninstall mesh.example.com 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
```

### WARNING
- You should **only** attempt this if the agent removal feature on TacticalRMM is not working.
- Running uninstall will **not** remove the connections from the TacticalRMM and MeshCentral Dashboard. You will need to manually remove them. It only forcefully removes the agents from your linux box.

---

Original Project [Netvolt](https://github.com/netvolt/LinuxRMM-Script)

