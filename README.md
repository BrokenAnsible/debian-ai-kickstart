# debian-ai-kickstart

Bare metal post-installation script that brings a fresh Debian 13 (Trixie) install up to an Nvidia AI workstation baseline.

## What It Installs

- CUDA Toolkit 13.1 + cuda-drivers (595.x) from Nvidia's official Debian 13 repo
- CUDA runtime and dev libraries (`cuda-cudart-dev-13-1`, `libcu++-dev`)
- CUDA environment configured in `.bashrc` and `/etc/bash.bashrc`
- UV — ultra-fast Python package manager (astral.sh)
- Essential build tools: `python3-dev`, `build-essential`, `git`, `ca-certificates`, `gnupg`

## Requirements

- Debian 13 (Trixie) fresh bare metal install
    - Tested on Debian 13.4.0 NETINST amd64
    - Select **SSH server** and **standard system utilities** only during install — no GUI
- Nvidia GPU (tested on RTX 4060 Ti)
- AMD or Intel CPU (tested on Ryzen 3700X)
- Internet connection

## Pre-Script Steps

These steps must be done manually before running the script.

### 1. Boot with nomodeset (Nvidia GPU required)

On a fresh Debian install with an Nvidia GPU, the system will hang at boot due to the `nouveau` driver. At the GRUB menu:

1. Highlight the **Debian GNU/Linux** entry and press **E**
2. Find the line starting with `linux`
3. Go to the end of that line and add a space followed by `nomodeset`
4. Press **Ctrl+X** to boot

> This is temporary and only applies to the current boot. Once the Nvidia driver is installed by the script, this is no longer needed.

### 2. Blacklist nouveau

Once booted, blacklist the nouveau driver before running the script:

```bash
echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
sudo update-initramfs -u
sudo reboot
```

### 3. Install curl

A minimal Debian install does not include curl. Install it manually:

```bash
sudo apt install -y curl
```

## Installation

Download and run the script:

```bash
curl -fsSL https://raw.githubusercontent.com/BrokenAnsible/debian-ai-kickstart/main/install.sh -o install.sh
sudo bash install.sh
```

## Interactive Prompts

This script is **not unattended**. You will be prompted for:

1. **Username** — your preferred Linux username for sudo and environment configuration
2. **Keyboard layout** — prompted during the Nvidia driver install

## Post-Install

After the script completes, reboot the system:

```bash
sudo reboot
```

Then verify the installation:

```bash
nvidia-smi        # Should show your GPU with driver 595.x and CUDA 13.2
nvcc --version    # Should show CUDA compilation tools 13.1
uv --version      # Should show UV version
```

## Notes

- The script adds `contrib non-free non-free-firmware` to `/etc/apt/sources.list` automatically
- A backup of the original `sources.list` is saved to `/etc/apt/sources.list.backup`
- CUDA drivers are installed from Nvidia's official Debian 13 repo — **not** from Debian's non-free repo — to ensure the correct driver version is paired with CUDA 13.1
- UV is installed to `~/.local/bin` for the configured user

## Tested On

| Component | Version |
|-----------|---------|
| Debian | 13.4.0 (Trixie) |
| Kernel | 6.12.86+deb13-amd64 |
| GPU | Nvidia GeForce RTX 4060 Ti |
| Nvidia Driver | 595.71.05 |
| CUDA Toolkit | 13.1 |
| CPU | AMD Ryzen 3700X |

## License

Apache-2.0
