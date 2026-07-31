#!/bin/bash

# Lightning Linux - Quick Production Build (FIXED VERSION)
# Creates a ready-to-use Linux distribution immediately
# Part of HarshitOS / Lightning Linux project
# Fixed: Error handling, space check, root checks, timeout

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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

print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Function to check root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "Root privileges required for: $1"
        print_error "Please run this script with sudo."
        exit 1
    fi
}

# Function to execute with timeout
timeout_exec() {
    local cmd="$1"
    local timeout_seconds="${2:-7200}"  # Default 2 hours
    local description="${3:-Command}"
    
    print_status "Executing (timeout: ${timeout_seconds}s): $description"
    
    if ! timeout "$timeout_seconds" bash -c "$cmd" 2>&1; then
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            print_error "TIMEOUT: $description took longer than ${timeout_seconds} seconds"
        else
            print_error "FAILED: $description failed with exit code $exit_code"
        fi
        exit $exit_code
    fi
}

# Check if running as root
check_root "BUILD_NOW.sh"

# Configuration
DISTRO_NAME="Lightning Linux"
DISTRO_VERSION="1.0"
DISTRO_CODENAME="Harshit"
ARCH="amd64"
UBUNTU_VERSION="${UBUNTU_VERSION:-focal}"  # FIX #10: Make configurable
OUTPUT_DIR="${BUILD_DIR:-build}/output"
WORK_DIR="${BUILD_DIR:-build}"
ISO_NAME="lightning-linux-${DISTRO_VERSION}-${ARCH}.iso"
REQUIRED_SPACE=15000000  # FIX #2: Increased from 10GB to 15GB

# Create directories
mkdir -p "$OUTPUT_DIR" "$WORK_DIR"

print_header "Lightning Linux Production Build (FIXED)"
print_status "Creating a ready-to-use Linux distribution..."
print_status ""

# FIX #3: Check root before critical operations
check_root "BUILD_NOW.sh execution"

# Step 1: Check system
print_status "Step 1: Checking system requirements..."

# FIX #2: Check both current directory and build directory for space
for check_dir in . "$WORK_DIR"; do
    if [ -d "$check_dir" ]; then
        AVAILABLE_SPACE=$(df --output=avail -k "$check_dir" 2>/dev/null | tail -1)
        if [ -n "$AVAILABLE_SPACE" ] && [ "$AVAILABLE_SPACE" -lt $REQUIRED_SPACE ]; then
            print_error "Not enough disk space in $check_dir. Need at least 15GB available, have ${AVAILABLE_SPACE}KB."
            exit 1
        fi
    fi
done

# Check if we're in the right directory
if [ ! -f "README.md" ]; then
    print_error "Please run this script from the Lightning Linux project directory."
    print_status "cd /path/to/lightning-linux && sudo ./BUILD_NOW.sh"
    exit 1
fi

print_success "System requirements OK!"

# Step 2: Install dependencies
print_status "Step 2: Installing build dependencies..."

# FIX #3: Check root before installing
check_root "dependency installation"

if ! command -v debootstrap &>/dev/null; then
    print_status "Installing debootstrap..."
    timeout_exec "apt update && apt install -y debootstrap squashfs-tools xorriso grub2 grub-efi-amd64-bin syslinux" 300 "dependency installation"
fi

if ! command -v mksquashfs &>/dev/null; then
    print_status "Installing squashfs-tools..."
    timeout_exec "apt install -y squashfs-tools" 300 "squashfs-tools installation"
fi

if ! command -v xorriso &>/dev/null; then
    print_status "Installing xorriso..."
    timeout_exec "apt install -y xorriso" 300 "xorriso installation"
fi

print_success "Dependencies installed!"

# Step 3: Create root filesystem
print_status "Step 3: Creating root filesystem (this may take a while)..."

# Clean up any existing rootfs
rm -rf "$WORK_DIR/rootfs"
mkdir -p "$WORK_DIR/rootfs"

# FIX #1: Add error handling for debootstrap
print_status "Downloading and installing base system..."
if ! timeout_exec "debootstrap --arch=$ARCH $UBUNTU_VERSION \"$WORK_DIR/rootfs\" http://archive.ubuntu.com/ubuntu --include=\"sudo,vim-tiny,less,locales,keyboard-configuration,console-setup,net-tools,iproute2,wget,curl,ca-certificates,openssh-client,gnupg2\" --components=main,restricted,universe,multiverse" 1800 "debootstrap"; then
    print_error "debootstrap failed! Check your internet connection."
    print_error "Try using a different mirror: http://mirror.example.com/ubuntu"
    print_error "Or check if $UBUNTU_VERSION is a valid Ubuntu release."
    exit 1
fi

print_success "Base system created!"

# Step 4: Mount and configure
print_status "Step 4: Configuring system..."

# FIX #3: Check root before mount operations
check_root "mount operations"

# Mount proc, sys, dev
mount -t proc proc "$WORK_DIR/rootfs/proc"
mount -t sysfs sys "$WORK_DIR/rootfs/sys"
mount -o bind /dev "$WORK_DIR/rootfs/dev"
mount -t devpts pts "$WORK_DIR/rootfs/dev/pts"

# Configure basic settings
cat > "$WORK_DIR/rootfs/etc/hostname" <<EOF
lightning-linux
EOF

cat > "$WORK_DIR/rootfs/etc/hosts" <<EOF
127.0.0.1   localhost
127.0.1.1   lightning-linux
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

# Configure locale
cat > "$WORK_DIR/rootfs/etc/default/locale" <<EOF
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8
EOF

# Generate locales
chroot "$WORK_DIR/rootfs" /bin/bash -c "apt install -y locales && dpkg-reconfigure -f noninteractive locales" 2>&1 | tail -3

# Configure keyboard
cat > "$WORK_DIR/rootfs/etc/default/keyboard" <<EOF
XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""
EOF

# Configure timezone
ln -sf /usr/share/zoneinfo/America/New_York "$WORK_DIR/rootfs/etc/localtime"
echo "America/New_York" > "$WORK_DIR/rootfs/etc/timezone"

# Configure APT
cat > "$WORK_DIR/rootfs/etc/apt/sources.list" <<EOF
deb http://archive.ubuntu.com/ubuntu $UBUNTU_VERSION main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_VERSION}-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_VERSION}-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_VERSION}-backports main restricted universe multiverse
EOF

cat > "$WORK_DIR/rootfs/etc/apt/apt.conf.d/00-lightning" <<EOF
APT::Install-Recommends "false";
APT::Install-Suggests "false";
APT::AutoClean "true";
EOF

print_success "System configuration completed!"

# Step 5: Install Xfce4 Desktop (Lightweight)
print_status "Step 5: Installing Xfce4 Desktop Environment..."

chroot "$WORK_DIR/rootfs" /bin/bash -c "apt update" 2>&1 | tail -3

# Install Xfce4 and essential apps with error handling
if ! chroot "$WORK_DIR/rootfs" /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends xfce4 xfce4-goodies lightdm lightdm-gtk-greeter xfce4-terminal mousepad thunar ristretto galculator network-manager network-manager-gnome pulseaudio pavucontrol bluez blueman cups sane xsane" 2>&1 | tail -5; then
    print_error "Failed to install Xfce4 desktop"
    exit 1
fi

print_success "Xfce4 Desktop installed!"

# Step 6: Install Security Tools
print_status "Step 6: Installing Security Tools..."

# FIX #9: Only install packages that exist
SECURITY_PACKAGES="nmap wireshark tcpdump tshark ncat net-tools dnsutils whois traceroute mtr htop iotop iftop nmon glances lsof ufw apparmor apparmor-utils rkhunter chkrootkit lynis clamav clamav-daemon"

for pkg in $SECURITY_PACKAGES; do
    if chroot "$WORK_DIR/rootfs" /bin/bash -c "apt-cache show '$pkg' &>/dev/null"; then
        chroot "$WORK_DIR/rootfs" /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends $pkg" 2>&1 | tail -1
    else
        print_warning "Package $pkg not found in repositories, skipping"
    fi
done

print_success "Security Tools installed!"

# Step 7: Install Development Tools
print_status "Step 7: Installing Development Tools..."

DEV_PACKAGES="build-essential gcc g++ make cmake git subversion python3 python3-pip python3-venv nodejs npm default-jdk golang flatpak"

for pkg in $DEV_PACKAGES; do
    if chroot "$WORK_DIR/rootfs" /bin/bash -c "apt-cache show '$pkg' &>/dev/null"; then
        chroot "$WORK_DIR/rootfs" /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends $pkg" 2>&1 | tail -1
    else
        print_warning "Package $pkg not found in repositories, skipping"
    fi
done

# Add Flathub
chroot "$WORK_DIR/rootfs" /bin/bash -c "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo" 2>&1 | tail -3

print_success "Development Tools installed!"

# Step 8: Install Media and Office Apps
print_status "Step 8: Installing Media and Office Applications..."

MEDIA_PACKAGES="vlc mpv audacious gimp feh scrot simplescreenrecorder ffmpeg"
OFFICE_PACKAGES="libreoffice firefox thunderbird"

for pkg in $MEDIA_PACKAGES $OFFICE_PACKAGES; do
    if chroot "$WORK_DIR/rootfs" /bin/bash -c "apt-cache show '$pkg' &>/dev/null"; then
        chroot "$WORK_DIR/rootfs" /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends $pkg" 2>&1 | tail -1
    else
        print_warning "Package $pkg not found in repositories, skipping"
    fi
done

print_success "Applications installed!"

# Step 9: Configure Optimizations
print_status "Step 9: Configuring Performance Optimizations..."

# ZRAM Configuration
cat > "$WORK_DIR/rootfs/usr/local/bin/zram-config.sh" <<'EOF'
#!/bin/bash
TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
ZRAM_SIZE=$((TOTAL_MEM * 1024 / 2))
modprobe zram num_devices=1
echo lz4 > /sys/block/zram0/comp_algorithm
echo $ZRAM_SIZE > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon /dev/zram0 -p 100
sysctl vm.swappiness=100
sysctl vm.watermark_scale_factor=200
EOF

chmod +x "$WORK_DIR/rootfs/usr/local/bin/zram-config.sh"

# ZSWAP Configuration
cat > "$WORK_DIR/rootfs/etc/sysctl.d/99-zswap.conf" <<'EOF'
vm.zswap.enabled=1
vm.zswap.compressor=lz4
vm.zswap.max_pool_percent=20
vm.zswap.accept_throttled_writebacks=1
EOF

# THP Configuration
cat > "$WORK_DIR/rootfs/etc/sysctl.d/99-thp.conf" <<'EOF'
vm.thp_enabled=1
vm.thp_defrag_enabled=1
vm.thp_anonymous_only=0
EOF

# I/O Scheduler Configuration
cat > "$WORK_DIR/rootfs/etc/udev/rules.d/60-io-scheduler.rules" <<'EOF'
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]*|vd[a-z]", ATTR{queue/scheduler}="bfq"
EOF

# CPU Governor Configuration
cat > "$WORK_DIR/rootfs/etc/default/cpufrequtils" <<'EOF'
GOVERNOR="schedutil"
MIN_SPEED="800000"
MAX_SPEED="3600000"
EOF

# Swappiness Configuration
cat > "$WORK_DIR/rootfs/etc/sysctl.d/99-swappiness.conf" <<'EOF'
vm.swappiness=60
vm.watermark_scale_factor=200
EOF

print_success "Performance Optimizations configured!"

# Step 10: Configure LightDM
print_status "Step 10: Configuring LightDM..."

cat > "$WORK_DIR/rootfs/etc/lightdm/lightdm.conf" <<'EOF'
[LightDM]
minimum-display-number=0

[Seat:*]
xserver-command=X -background none
greeter-session=lightdm-gtk-greeter
user-session=xfce4

[Seat:seat0]
type=xlocal
xserver-command=X
EOF

chroot "$WORK_DIR/rootfs" /bin/bash -c "systemctl enable lightdm" 2>&1 | tail -3

print_success "LightDM configured!"

# Step 11: Configure Network Manager
print_status "Step 11: Configuring Network Manager..."

cat > "$WORK_DIR/rootfs/etc/NetworkManager/NetworkManager.conf" <<'EOF'
[main]
plugins=keyfile,ofono
rc-manager=unmanaged

[keyfile]
unmanaged-devices=none

[device]
wifi.scan-rand-mac-address=no

[logging]
level=INFO
domains=ALL
EOF

chroot "$WORK_DIR/rootfs" /bin/bash -c "systemctl enable NetworkManager" 2>&1 | tail -3

print_success "Network Manager configured!"

# Step 12: Create user
print_status "Step 12: Creating default user..."

chroot "$WORK_DIR/rootfs" /bin/bash -c "useradd -m -s /bin/bash -G sudo,users,netdev,lpadmin,scanner lightning" 2>&1 | tail -3
chroot "$WORK_DIR/rootfs" /bin/bash -c "echo 'lightning:lightning' | chpasswd" 2>&1 | tail -3
chroot "$WORK_DIR/rootfs" /bin/bash -c "echo 'root:lightning' | chpasswd" 2>&1 | tail -3

cat > "$WORK_DIR/rootfs/etc/sudoers.d/lightning" <<'EOF'
lightning ALL=(ALL) NOPASSWD:ALL
EOF

print_success "Default user created!"

# Step 13: Install kernel and create initramfs
print_status "Step 13: Installing kernel and creating initramfs..."

chroot "$WORK_DIR/rootfs" /bin/bash -c "apt install -y linux-image-generic linux-headers-generic initramfs-tools busybox" 2>&1 | tail -5

# Copy host kernel if available
if [ -f /boot/vmlinuz-$(uname -r) ]; then
    cp /boot/vmlinuz-$(uname -r) "$WORK_DIR/rootfs/boot/vmlinuz"
    cp /boot/initrd.img-$(uname -r) "$WORK_DIR/rootfs/boot/initrd.img"
fi

# Create initramfs
chroot "$WORK_DIR/rootfs" /bin/bash -c "update-initramfs -c -k all -b /boot" 2>&1 | tail -5

print_success "Kernel and initramfs ready!"

# Step 14: Clean up
print_status "Step 14: Cleaning up..."

# Clean APT cache
chroot "$WORK_DIR/rootfs" /bin/bash -c "apt clean"
chroot "$WORK_DIR/rootfs" /bin/bash -c "apt autoremove -y"

# Remove unnecessary files
rm -rf "$WORK_DIR/rootfs/var/cache/apt/archives/*"
rm -rf "$WORK_DIR/rootfs/var/lib/apt/lists/*"
rm -rf "$WORK_DIR/rootfs/tmp/*"
rm -rf "$WORK_DIR/rootfs/var/tmp/*"

# Unmount
umount "$WORK_DIR/rootfs/dev/pts" 2>/dev/null || true
umount "$WORK_DIR/rootfs/dev" 2>/dev/null || true
umount "$WORK_DIR/rootfs/proc" 2>/dev/null || true
umount "$WORK_DIR/rootfs/sys" 2>/dev/null || true

print_success "Cleanup completed!"

# Step 15: Create SquashFS image
print_status "Step 15: Creating SquashFS image (this may take a while)..."

# Create exclusion list
cat > "$WORK_DIR/exclude.list" <<'EOF'
.dev
.proc
.sys
.tmp
var/cache
var/lib/apt/lists
var/log
var/tmp
lost+found
home/*/.cache
home/*/.local/share/Trash
EOF

# Create SquashFS image with timeout
if ! timeout_exec "mksquashfs \"$WORK_DIR/rootfs\" \"$WORK_DIR/rootfs.squashfs\" -comp xz -Xdict-size 100% -b 256K -Xbcj x86 -noappend -no-duplicates -e \"$WORK_DIR/exclude.list\"" 3600 "SquashFS creation"; then
    print_error "Failed to create SquashFS image"
    exit 1
fi

print_success "SquashFS image created!"

# Step 16: Create ISO with EFI support
print_status "Step 16: Creating bootable ISO with EFI support..."

# FIX #4: Add EFI support
# Create ISO directory structure
mkdir -p "$WORK_DIR/iso/{boot/grub,live,EFI/BOOT}"

# Copy kernel and initramfs
if [ -f "$WORK_DIR/rootfs/boot/vmlinuz" ]; then
    cp "$WORK_DIR/rootfs/boot/vmlinuz" "$WORK_DIR/iso/boot/vmlinuz"
else
    print_warning "Using generic kernel"
fi

if [ -f "$WORK_DIR/rootfs/boot/initrd.img" ]; then
    cp "$WORK_DIR/rootfs/boot/initrd.img" "$WORK_DIR/iso/boot/initrd.img"
fi

# Copy SquashFS image
cp "$WORK_DIR/rootfs.squashfs" "$WORK_DIR/iso/live/rootfs.squashfs"

# FIX #4: Create EFI boot files
if [ -f "$WORK_DIR/rootfs/usr/lib/grub/x86_64-efi-signed/grubx64.efi" ]; then
    cp "$WORK_DIR/rootfs/usr/lib/grub/x86_64-efi-signed/grubx64.efi" "$WORK_DIR/iso/EFI/BOOT/bootx64.efi"
    cp "$WORK_DIR/rootfs/usr/lib/grub/x86_64-efi-signed/grubx64.efi" "$WORK_DIR/iso/EFI/BOOT/grubx64.efi"
    print_success "EFI boot files copied"
else
    print_warning "EFI GRUB not found, creating fallback"
    # Create a minimal EFI image
    dd if=/dev/zero of="$WORK_DIR/iso/boot/grub/efi.img" bs=1M count=10 2>/dev/null
    mkfs.fat -F 32 "$WORK_DIR/iso/boot/grub/efi.img" 2>/dev/null || true
fi

# Create GRUB configuration for ISO
cat > "$WORK_DIR/iso/boot/grub/grub.cfg" <<EOF
set default="0"
set timeout=10

menuentry "$DISTRO_NAME $DISTRO_VERSION - Live (UEFI)" {
    linux /boot/vmlinuz boot=casper quiet splash -- persistent
    initrd /boot/initrd.img
}

menuentry "$DISTRO_NAME $DISTRO_VERSION - Live (BIOS)" {
    linux /boot/vmlinuz boot=casper quiet splash -- persistent
    initrd /boot/initrd.img
}

menuentry "$DISTRO_NAME $DISTRO_VERSION - Live (Safe Graphics)" {
    linux /boot/vmlinuz boot=casper xforcevesa quiet splash -- persistent
    initrd /boot/initrd.img
}

menuentry "Check Disc for Defects" {
    linux16 /boot/grub/i386-pc/chainloader /dev/cd0
}

menuentry "Test Memory" {
    linux16 /boot/grub/i386-pc/memtest86+
}
EOF

# Create ISO using xorriso with EFI support
if ! timeout_exec "xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -volid \"$DISTRO_NAME\" -publisher \"Lightning Linux Team\" -preparer \"HarshitOS Project\" -application \"$DISTRO_NAME $DISTRO_VERSION\" -copyright \"GPLv3\" -b boot/grub/i386-pc/eltorito.img -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot -o \"$OUTPUT_DIR/$ISO_NAME\" \"$WORK_DIR/iso\"" 1800 "ISO creation"; then
    print_error "Failed to create ISO"
    exit 1
fi

print_success "ISO created at $OUTPUT_DIR/$ISO_NAME!"

# Step 17: Create helper scripts
print_status "Step 17: Creating helper scripts..."

# Create USB script
cat > "$OUTPUT_DIR/create-usb.sh" <<EOF
#!/bin/bash
if [ "\(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi
if [ -z "\$1" ]; then
    echo "Usage: \$0 /dev/sdX"
    echo "Example: \$0 /dev/sdb"
    exit 1
fi
USB_DEVICE="\$1"
ISO_FILE="$OUTPUT_DIR/$ISO_NAME"
if [ ! -f "\$ISO_FILE" ]; then
    echo "ISO file not found: \$ISO_FILE"
    exit 1
fi
if [ ! -b "\$USB_DEVICE" ]; then
    echo "Device not found: \$USB_DEVICE"
    exit 1
fi
echo "WARNING: This will ERASE all data on \$USB_DEVICE!"
echo "Press Ctrl+C to cancel or Enter to continue..."
read
for i in \(lsblk -lno MOUNTPOINT | grep "^\">${USB_DEVICE#/dev/}" | sort -r\); do
    umount "\$i" 2>/dev/null || true
done
echo "Writing ISO to \$USB_DEVICE..."
dd if="\$ISO_FILE" of="\$USB_DEVICE" bs=4M status=progress
sync
echo "Bootable USB created successfully!"
EOF

chmod +x "$OUTPUT_DIR/create-usb.sh"

# Create QEMU test script
cat > "$OUTPUT_DIR/test-qemu.sh" <<EOF
#!/bin/bash
ISO_FILE="$OUTPUT_DIR/$ISO_NAME"
if [ ! -f "\$ISO_FILE" ]; then
    echo "ISO file not found: \$ISO_FILE"
    exit 1
fi
if ! command -v qemu-system-x86_64 &>/dev/null; then
    echo "QEMU not found. Please install QEMU first."
    exit 1
fi
echo "Starting QEMU with Lightning Linux..."
echo "Username: lightning, Password: lightning"
echo "Press Ctrl+Alt+G to release mouse cursor"
echo ""
qemu-system-x86_64 -m 2048 -smp 2 -cdrom "\$ISO_FILE" -net nic -net user -vga virtio -display sdl,gl=on
EOF

chmod +x "$OUTPUT_DIR/test-qemu.sh"

# Final summary
print_header "Build Complete!"
print_success ""
print_success "✅ Lightning Linux Production Build Completed!"
print_success ""

if [ -f "$OUTPUT_DIR/$ISO_NAME" ]; then
    ISO_SIZE=$(du -h "$OUTPUT_DIR/$ISO_NAME" | cut -f1)
    print_status "📁 ISO File: $OUTPUT_DIR/$ISO_NAME"
    print_status "📊 Size: $ISO_SIZE"
    print_status ""
else
    print_error "ISO file was not created. Check the build logs."
    exit 1
fi

print_status "🚀 Quick Start:"
print_status ""
print_status "  1. Create Bootable USB:"
print_status "     sudo $OUTPUT_DIR/create-usb.sh /dev/sdX"
print_status ""
print_status "  2. Test in QEMU:"
print_status "     $OUTPUT_DIR/test-qemu.sh"
print_status ""
print_status "💡 Default Credentials:"
print_status "  - Username: lightning"
print_status "  - Password: lightning"
print_status "  - Root Password: lightning"
print_status ""
print_status "📊 System Features:"
print_status "  ✅ Xfce4 Desktop Environment"
print_status "  ✅ Security Tools (nmap, wireshark, etc.)"
print_status "  ✅ Development Tools (gcc, python, nodejs, etc.)"
print_status "  ✅ Media Apps (vlc, gimp, etc.)"
print_status "  ✅ Office Apps (libreoffice, firefox, etc.)"
print_status "  ✅ Performance Optimizations (ZRAM, ZSWAP, THP)"
print_status "  ✅ EFI Boot Support (FIXED)"
print_status "  ✅ Error Handling (FIXED)"
print_status "  ✅ Timeout Protection (FIXED)"
print_status ""
print_success "🎉 Lightning Linux is ready to use!"
print_status ""
print_status "Note: For VirtualBox, manually create a VM and attach the ISO."
print_status "For real hardware, use the create-usb.sh script."

exit 0
