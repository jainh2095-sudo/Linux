#!/bin/bash

# Lightning Linux - Build Dependencies Installer
# Part of HarshitOS / Lightning Linux project
# https://github.com/jainh2095-sudo/Linux

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root. Please use sudo."
    exit 1
fi

# Detect distribution
DISTRO=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
elif type lsb_release >/dev/null 2>&1; then
    DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
else
    DISTRO=$(uname -s)
fi

print_status "Detected distribution: $DISTRO"

# Install dependencies based on distribution
case $DISTRO in
    ubuntu|debian|pop)
        print_status "Installing dependencies for Debian/Ubuntu-based system..."
        
        # Update package lists
        print_status "Updating package lists..."
        apt update
        
        # Install essential build tools
        print_status "Installing essential build tools..."
        apt install -y \
            build-essential \
            cmake \
            ninja-build \
            autoconf \
            automake \
            libtool \
            pkg-config \
            git \
            wget \
            curl \
            ca-certificates \
            gnupg \
            lsb-release \
            software-properties-common
        
        # Install filesystem tools
        print_status "Installing filesystem tools..."
        apt install -y \
            squashfs-tools \
            xorriso \
            mtools \
            dosfstools \
            e2fsprogs \
            btrfs-progs \
            xfsprogs \
            ntfs-3g \
            exfat-fuse exfat-utils
        
        # Install QEMU for testing
        print_status "Installing QEMU for testing..."
        apt install -y \
            qemu-system \
            qemu-user \
            qemu-utils \
            qemu-kvm \
            libvirt-daemon-system \
            libvirt-clients \
            bridge-utils
        
        # Install kernel build tools
        print_status "Installing kernel build tools..."
        apt install -y \
            linux-headers-$(uname -r) \
            linux-source \
            libncurses-dev \
            bison \
            flex \
            libssl-dev \
            libelf-dev \
            bc \
            kmod \
            cpio
        
        # Install initramfs tools
        print_status "Installing initramfs tools..."
        apt install -y \
            initramfs-tools \
            busybox \
            klibc-utils
        
        # Install bootloader tools
        print_status "Installing bootloader tools..."
        apt install -y \
            grub2 \
            grub-efi \
            grub-efi-amd64 \
            grub-efi-ia32 \
            syslinux \
            syslinux-common \
            isolinux
        
        # Install package management tools
        print_status "Installing package management tools..."
        apt install -y \
            dpkg \
            apt \
            apt-utils \
            debhelper \
            dh-make \
            devscripts \
            lintian \
            debootstrap
        
        # Install desktop environment build tools
        print_status "Installing desktop environment build tools..."
        apt install -y \
            meson \
            gettext \
            intltool \
            libgtk-3-dev \
            libgtk-2.0-dev \
            libxfce4util-dev \
            libxfce4ui-dev \
            libxfcegui4-dev \
            xfce4-dev-tools
        
        # Install documentation tools
        print_status "Installing documentation tools..."
        apt install -y \
            asciidoc \
            xmlto \
            docbook-xsl \
            docbook-xml \
            dblatex \
            texlive \
            texlive-latex-extra \
            texlive-fonts-recommended
        
        # Install testing tools
        print_status "Installing testing tools..."
        apt install -y \
            shellcheck \
            shunit2 \
            bats \
            check \
            valgrind \
            strace \
            ltrace \
            perf-tools
        
        # Install monitoring tools
        print_status "Installing monitoring tools..."
        apt install -y \
            htop \
            iotop \
            iftop \
            nmon \
            glances \
            sysstat
        
        # Install network tools
        print_status "Installing network tools..."
        apt install -y \
            net-tools \
            iproute2 \
            iputils-ping \
            iputils-tracepath \
            traceroute \
            mtr \
            nmap \
            tcpdump \
            wireshark \
            dnsutils \
            bind9-host
        
        # Install security tools
        print_status "Installing security tools..."
        apt install -y \
            apparmor \
            apparmor-utils \
            ufw \
            nftables \
            iptables \
            cryptsetup \
            gnupg \
            openssl
        
        # Install development tools
        print_status "Installing development tools..."
        apt install -y \
            gdb \
            lldb \
            clang \
            llvm \
            python3-dev \
            python3-venv \
            python3-pip \
            nodejs \
            npm \
            golang \
            rustc \
            cargo
        
        # Clean up
        print_status "Cleaning up..."
        apt autoremove -y
        apt clean
        
        print_success "All dependencies installed successfully for Debian/Ubuntu!"
        ;;
    fedora)
        print_status "Installing dependencies for Fedora-based system..."
        
        # Update package lists
        dnf makecache
        
        # Install essential build tools
        dnf install -y \
            @development-tools \
            cmake \
            ninja-build \
            autoconf \
            automake \
            libtool \
            pkg-config \
            git \
            wget \
            curl \
            ca-certificates \
            gnupg
        
        # Install filesystem tools
        dnf install -y \
            squashfs-tools \
            xorriso \
            mtools \
            dosfstools \
            e2fsprogs \
            btrfs-progs \
            xfsprogs \
            ntfs-3g \
            fuse-exfat
        
        # Install QEMU for testing
        dnf install -y \
            qemu-system-x86 \
            qemu-user \
            qemu-utils \
            qemu-kvm \
            libvirt \
            libvirt-client \
            bridge-utils
        
        # Install kernel build tools
        dnf install -y \
            kernel-headers \
            kernel-devel \
            ncurses-devel \
            bison \
            flex \
            openssl-devel \
            elfutils-libelf-devel \
            bc \
            kmod \
            cpio
        
        print_success "Dependencies installed for Fedora!"
        ;;
    arch|manjaro)
        print_status "Installing dependencies for Arch-based system..."
        
        # Update package lists
        pacman -Syu --noconfirm
        
        # Install essential build tools
        pacman -S --noconfirm \
            base-devel \
            cmake \
            ninja \
            autoconf \
            automake \
            libtool \
            pkgconf \
            git \
            wget \
            curl \
            ca-certificates \
            gnupg
        
        # Install filesystem tools
        pacman -S --noconfirm \
            squashfs-tools \
            xorriso \
            mtools \
            dosfstools \
            e2fsprogs \
            btrfs-progs \
            xfsprogs \
            ntfs-3g \
            exfat-utils
        
        print_success "Dependencies installed for Arch!"
        ;;
    *)
        print_error "Unsupported distribution: $DISTRO"
        print_warning "Attempting to install common dependencies..."
        
        # Try to install common tools
        if command -v apt &> /dev/null; then
            apt update
            apt install -y build-essential cmake git wget curl squashfs-tools xorriso
        elif command -v dnf &> /dev/null; then
            dnf makecache
            dnf install -y @development-tools cmake git wget curl squashfs-tools xorriso
        elif command -v pacman &> /dev/null; then
            pacman -Syu --noconfirm
            pacman -S --noconfirm base-devel cmake git wget curl squashfs-tools xorriso
        else
            print_error "Cannot determine package manager for $DISTRO"
            exit 1
        fi
        ;;
esac

# Verify installation
print_status "Verifying installation..."

# Check for essential tools
MISSING_TOOLS=()
for tool in gcc g++ make cmake git wget curl squashfs xorriso; do
    if ! command -v $tool &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    print_warning "The following tools are missing: ${MISSING_TOOLS[*]}"
    print_warning "Some build features may not work correctly."
else
    print_success "All essential tools are installed and available!"
fi

# Print summary
print_status ""
print_status "=== Build Dependencies Installation Summary ==="
print_status "Distribution: $DISTRO"
print_status "Architecture: $(uname -m)"
print_status "Kernel: $(uname -r)"
print_status ""
print_status "Essential tools:"
print_status "  - GCC: $(gcc --version | head -n1)"
print_status "  - G++: $(g++ --version | head -n1)"
print_status "  - Make: $(make --version | head -n1)"
print_status "  - CMake: $(cmake --version | head -n1)"
print_status "  - Git: $(git --version)"
print_status "  - SquashFS: $(mksquashfs -version 2>&1 | head -n1)"
print_status "  - Xorriso: $(xorriso --version 2>&1 | head -n1)"
print_status ""

print_success "Build dependencies installation completed!"
print_status "You can now proceed with building Lightning Linux."

exit 0
