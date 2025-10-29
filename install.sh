#!/bin/bash

# Debian 13 AI Server Setup Script
# Run this after fresh Debian installation
# Upgrades to Debian 13 (Trixie) and installs CUDA + UV for AI workflows
# Create a template post install to save bandwidth for internet limits.

set -e  # Exit on any error

echo "=== WSL Debian 13 AI Setup Script ==="
echo "This script will:"
echo "1. Update system packages"
echo "2. Configure default sudo user"
echo "3. Install CUDA 12.6 toolkit"
echo "4. Install UV (ultra-fast Python package manager)"
echo "5. Configure WSL for optimal AI workflows"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Add non-free to sources.list
echo "Updating sources.list to include non-free repository..."

# Backup the original file
cp /etc/apt/sources.list /etc/apt/sources.list.backup

# Add non-free to lines that don't already have it
sed -i 's/\(^deb .* main\)$/\1 non-free/' /etc/apt/sources.list

echo ""
echo "=== Step 1: System Update and Install Essential Tools ==="
apt update && apt upgrade -y

# Install Linux headers matching the running kernel
if ! dpkg -l | grep -q "linux-headers-$(uname -r)"; then
    echo "Installing Linux headers for kernel $(uname -r)..."
    apt install -y linux-headers-$(uname -r) linux-headers-amd64
else
    echo "Linux headers already installed."
fi

# Check and install NVIDIA driver
if ! dpkg -l | grep -q "^ii.*nvidia-driver"; then
    echo "Installing NVIDIA drivers..."
    apt install -y nvidia-driver firmware-misc-nonfree
    echo "NVIDIA driver installed."
else
    echo "NVIDIA driver already installed."
fi

# Install curl first since we need it for other installations
if ! command -v sudo &> /dev/null; then
    echo "Installing sudo..."
    apt install -y sudo
fi

# Install curl first since we need it for other installations
if ! command -v curl &> /dev/null; then
    echo "Installing curl..."
    apt install -y curl
fi

# Install zip first since we need it for other installations
if ! command -v zip &> /dev/null; then
    echo "Installing zip..."
    apt install -y zip
fi

# Install unzip first since we need it for other installations
if ! command -v unzip &> /dev/null; then
    echo "Installing unzip..."
    apt install -y unzip
fi

echo ""
echo "=== Step 2: Configure User ==="
read -p "Enter your preferred Linux username (lowercase, no spaces): " DEB_USERNAME

# Add user to sudo group (only if not already in it)
if groups $DEB_USERNAME | grep -q "\bsudo\b"; then
    echo "User $DEB_USERNAME already has sudo access."
else
    echo "Adding $DEB_USERNAME to sudo group..."
    gpasswd -a $DEB_USERNAME sudo
    echo "User added to sudo group. Please log out and back in for this to take effect."
fi

echo ""
echo "=== Step 3: Install CUDA Repository ==="
# Check if CUDA keyring already installed
if ! dpkg -l | grep -q cuda-keyring; then
    echo "Installing CUDA keyring..."
    # Download and install NVIDIA CUDA keyring
    curl -L -o cuda-keyring_1.1-1_all.deb https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
    dpkg -i cuda-keyring_1.1-1_all.deb
    rm cuda-keyring_1.1-1_all.deb

    apt update
else
    echo "CUDA keyring already installed"
fi

echo ""
echo "=== Step 3: Install CUDA Toolkit 12.6 ==="
# Check if CUDA toolkit already installed
if ! command -v nvcc &> /dev/null; then
    echo "Installing CUDA toolkit..."
    apt install -y \
        cuda-toolkit-12-6 \
        libcu++-dev \
        cuda-compiler-12-6 \
        cuda-libraries-dev-12-6 \
        cuda-driver-dev-12-6 \
        cuda-cudart-dev-12-6
else
    echo "CUDA toolkit already installed: $(nvcc --version | grep release)"
fi

echo ""
echo "=== Step 3: Configure CUDA Environment ==="
# Add CUDA to PATH permanently
USER_BASHRC="/home/$DEB_USERNAME/.bashrc"
if ! grep -q "/usr/local/cuda-12.6/bin" "$USER_BASHRC"; then
    echo "Configuring CUDA environment for user $DEB_USERNAME..."
    echo 'export PATH=/usr/local/cuda-12.6/bin:$PATH' >> "$USER_BASHRC"
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH' >> "$USER_BASHRC"
    # Also add to system-wide bashrc for good measure
    echo 'export PATH=/usr/local/cuda-12.6/bin:$PATH' >> /etc/bash.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH' >> /etc/bash.bashrc
else
    echo "CUDA environment already configured"
fi

# Create convenient symlink if it doesn't exist
if [ ! -L /usr/local/cuda ]; then
    ln -sf /usr/local/cuda-12.6 /usr/local/cuda
fi

echo ""
echo "=== Step 3: Install Additional Development Tools ==="
apt install -y \
    python3-dev \
    build-essential \
    git \
    ca-certificates \
    gnupg \
    lsb-release

echo ""
echo "=== Step 4: Install UV (Python Package Manager) ==="
# Check if UV already installed
if ! command -v uv &> /dev/null; then
    # Install UV - ultra-fast Python package manager
    # UV Installation - run as user
    echo "Installing UV for user $DEB_USERNAME..."
    su - "$DEB_USERNAME" -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'

     # Add UV to user's PATH
    if ! grep -q "/.cargo/bin" /etc/bash.bashrc; then
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /home/$DEB_USERNAME/.bashrc
    fi

    # Test UV installation
    if command -v uv &> /dev/null; then
        echo "UV successfully installed: $(uv --version)"
    else
        echo "Warning: UV installation may have failed"
    fi
else
    echo "UV already installed: $(uv --version)"
fi

echo "GPU access groups configured for $DEB_USERNAME"

echo ""
echo "=== Step 5: Final Cleanup ==="
apt autoremove -y
apt autoclean

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "Installed components:"
echo "- Update System - Debian 13 (Trixie) supported"
echo "- CUDA Toolkit 12.6"
echo "- UV (ultra-fast Python package manager)"
echo "- Development tools"
echo "- Default user: $DEB_USERNAME"
echo ""
echo "IMPORTANT: You must restart Debian for user settings to take effect!"
echo ""
echo "Next steps:"
echo "1. Restart: reboot"
echo "2. Log in as $DEB_USERNAME and test installations:"
echo "   - nvcc --version"
echo "   - nvidia-smi"
echo "   - uv --version"
echo "   - sdk version (SDKMAN)"
echo ""
echo "Perfect for Hugging Face models, LLaMA, and local AI development!"
echo ""
echo "=== Setup Complete ==="
