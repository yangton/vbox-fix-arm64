# VirtualBox ARM64 Guest Additions Patch (Snapdragon)

[![Developed by yangton](https://img.shields.io/badge/Author-yangton-black?style=for-the-badge&logo=github)](https://github.com/yangton)
[![Platform](https://img.shields.io/badge/Platform-Win11_ARM_%7C_Snapdragon-333333?style=for-the-badge)](#)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-7.x_ARM64-005073?style=for-the-badge)](#)

A lightweight initialization wrapper designed to resolve critical VirtualBox Guest Additions failures on ARM64 host architectures (specifically Snapdragon X Elite and Snapdragon X Plus). Mitigates resolution locks, shared clipboard failures, and drag-and-drop service crashes in Kali Linux and Ubuntu VMs.

---

## Background & Root Cause Analysis

Deploying ARM-based Linux distributions (e.g., Kali Linux ARM64) on Windows on ARM (WoA) via VirtualBox 7.x frequently results in broken guest integration. Standard symptoms include:

- Display output locked at `800x600` or `1024x768` (no dynamic scaling).
- Host-to-Guest shared clipboard daemon failing to load.
- Drag & Drop subsystem errors.
- Manual execution of `VBoxClient --all` hanging indefinitely or returning a `VERR_RESOURCE_BUSY` exception.

**The Root Cause:**
The default autostart implementation on ARM64 Linux builds (under GNOME/Wayland/X11) creates a severe race condition during boot. The system attempts to aggressively initialize all `VBoxClient` modules concurrently *before* the `vboxvideo` kernel module is fully loaded and ready to accept calls. This immediately crashes the VMSVGA display service, subsequently halting the initialization of the clipboard and file-sharing daemons.

---

## The Patch Implementation

`vbox_fix.sh` acts as a controlled execution pipeline to bypass the race condition. 

**Execution Flow:**
1. **Persistence Setup:** Injects a `.desktop` entry into `~/.config/autostart/` to ensure automated execution upon subsequent user logins.
2. **Process Sanitization:** Identifies and terminates orphaned, hanging, or bugged `VBoxClient` processes blocking system resources.
3. **Module Injection:** Probes for the `vboxvideo` kernel module via `lsmod` and forces `modprobe` if missing.
4. **Sequential Execution:** Staggers the launch of essential services with calculated delays, bypassing the `VERR_RESOURCE_BUSY` lock:
   - `--vmsvga-session` (Enables dynamic resolution scaling)
   - `--clipboard` (Initializes Host-Guest text transfer)
   - `--draganddrop` (Initializes file transfer)

---

## Deployment


Execute the Patch**
Clone the repository and run the script. Persistence is handled automatically.
```bash
git clone https://github.com/yangton/vbox-fix-arm64.git
cd vbox-fix-arm64
chmod +x vbox_fix.sh
./vbox_fix.sh
```

---

## Required Hypervisor Configuration

For stable execution on Snapdragon hardware, the VirtualBox VM must be configured strictly as follows. Deviating from these parameters will result in UI degradation or kernel panics.

| Setting | Target Value | Justification |
|---------|--------------|---------------|
| **Graphics Controller** | `VMSVGA` | The only controller properly supporting dynamic resolution scaling on modern Linux guests. |
| **Video Memory** | `128 MB` | Prevents VRAM exhaustion and screen tearing during buffer resizing. |
| **3D Acceleration** | **Disabled** | VirtualBox ARM64 currently lacks native Adreno GPU passthrough. Enabling this forces `llvmpipe` software rendering, causing severe interface lag and system freezes. |

---

## Troubleshooting & Forensics

Execution logs are appended to `~/vbox_fix.log` for debugging purposes:
```bash
cat ~/vbox_fix.log
```

If the display session locks up during heavy CPU load, force a manual Xrandr display refresh:
```bash
xrandr --output Virtual-1 --auto
```

---

## Validated Environments

- **Host OS:** Windows 11 ARM64
- **Target Hardware:** Snapdragon X Elite (Tested on X1E-78-100 / X1E-80-100 / X1E-84-100)
- **Hypervisor:** VirtualBox 7.x (ARM64 Edition)
- **Target Guest OS:** Kali Linux ARM64 (kernel `6.19+`) / Ubuntu ARM64

---

## Contributing

If this patch streamlined your lab setup, consider starring the repository. 
Bug reports and validation PRs for Apple Silicon (M1/M2/M3) environments are welcome via the Issues tab.

<br>

*Developed by [@yangton](https://github.com/yangton) with frustration :)*
