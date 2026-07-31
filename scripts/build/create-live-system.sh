#!/bin/bash

# Lightning Linux - Live System Creator
# Creates a production-ready, bootable Linux distribution
# Part of HarshitOS / Lightning Linux project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
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

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root. Please use sudo."
    exit 1
fi

# Check dependencies
print_status "Checking dependencies..."
for cmd in debootstrap squashfs-tools xorriso grub-mkrescue mksquashfs unsquashfs; do
    if ! command -v $cmd &>/dev/null; then
        print_error "Missing dependency: $cmd"
        print_status "Installing missing dependencies..."
        apt update && apt install -y $cmd
    fi
done

print_success "All dependencies are available!"

# Configuration
DISTRO_NAME="Lightning Linux"
DISTRO_VERSION="1.0"
DISTRO_CODENAME="Harshit"
ARCH="amd64"
MIRROR="http://archive.ubuntu.com/ubuntu"
SQUASHFS_COMP="xz"
SQUASHFS_OPTIONS="-Xdict-size 100% -b 256K -Xbcj x86"
ISO_NAME="lightning-linux-${DISTRO_VERSION}-${ARCH}.iso"
OUTPUT_DIR="/workspace/jainh2095-sudo__Linux/build/output"
WORK_DIR="/workspace/jainh2095-sudo__Linux/build"

mkdir -p "$OUTPUT_DIR" "$WORK_DIR"

print_header "Creating Lightning Linux Live System"

# Step 1: Create root filesystem
print_status "Step 1: Creating root filesystem..."
print_status "Using debootstrap to create minimal Ubuntu Focal system..."

# Clean up any existing rootfs
rm -rf "$WORK_DIR/rootfs"
mkdir -p "$WORK_DIR/rootfs"

# Create minimal system using debootstrap
debootstrap --arch="$ARCH" focal "$WORK_DIR/rootfs" "$MIRROR" --include="sudo,vim-tiny,less,locales,keyboard-configuration,console-setup,net-tools,iproute2,wget,curl,ca-certificates,openssh-client,gnupg2" --components=main,restricted,universe,multiverse

print_success "Base system created!"

# Step 2: Mount and configure
print_status "Step 2: Configuring system..."

# Mount proc, sys, dev
mount -t proc proc "$WORK_DIR/rootfs/proc"
mount -t sysfs sys "$WORK_DIR/rootfs/sys"
mount -o bind /dev "$WORK_DIR/rootfs/dev"
mount -t devpts pts "$WORK_DIR/rootfs/dev/pts"

# Chroot and configure
print_status "Configuring system settings..."

# Set up basic configuration
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
chroot "$WORK_DIR/rootfs" /bin/bash -c "apt install -y locales && dpkg-reconfigure -f noninteractive locales"

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
deb http://archive.ubuntu.com/ubuntu focal main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-backports main restricted universe multiverse
EOF

# APT configuration
cat > "$WORK_DIR/rootfs/etc/apt/apt.conf.d/00-lightning" <<EOF
APT::Install-Recommends "false";
APT::Install-Suggests "false";
APT::AutoClean "true";
EOF

print_success "System configuration completed!"

# Step 3: Install core packages
print_status "Step 3: Installing core packages..."

chroot "$WORK_DIR/rootfs" /bin/bash -c "apt update"

# Install essential packages
chroot "$WORK_DIR/rootfs" /bin/bash -c "apt install -y --no-install-recommends \
    bash-completion \
    coreutils \
    findutils \
    grep \
    sed \
    awk \
    gzip \
    bzip2 \
    xz-utils \
    tar \
    ca-certificates \
    openssl \
    net-tools \
    iproute2 \
    iputils-ping \
    less \
    nano \
    vim-tiny \
    man-db \
    info \
    file \
    mime-support \
    udev \
    e2fsprogs \
    xfsprogs \
    btrfs-progs \
    ntfs-3g \
    dosfstools \
    hdparm \
    smartmontools \
    lm-sensors \
    fancontrol \
    acpi \
    pciutils \
    usbutils \
    lsb-release \
    os-prober"

print_success "Core packages installed!"

# Step 4: Install Xfce4 Desktop
print_status "Step 4: Installing Xfce4 Desktop Environment..."

chroot "$WORK_DIR/rootfs" /bin/bash -c "apt install -y --no-install-recommends \
    xfce4 \
    xfce4-goodies \
    lightdm \
    lightdm-gtk-greeter \
    xfce4-terminal \
    mousepad \
    thunar \
    thunar-archive-plugin \
    thunar-volman \
    ristretto \
    galculator \
    catfish \
    xfce4-screenshooter \
    xfce4-clipman-plugin \
    xfce4-whiskermenu-plugin \
    xfce4-pulseaudio-plugin \
    xfce4-netload-plugin \
    xfce4-cpugraph-plugin \
    xfce4-systemload-plugin \
    picom \
    network-manager \
    network-manager-gnome \
    pulseaudio \
    pulseaudio-utils \
    pavucontrol \
    alsa-base \
    alsa-utils \
    bluez \
    blueman \
    cups \
    cups-bsd \
    printer-driver-all \
    sane \
    sane-utils \
    xsane"

print_success "Xfce4 Desktop installed!"

# Step 5: Install Security Tools
print_status "Step 5: Installing Security Tools..."

chroot "$WORK_DIR/rootfs" /bin/bash -c "apt install -y --no-install-recommends \
    nmap \
    wireshark \
    tcpdump \
    tshark \
    ncat \
    net-tools \
    dnsutils \
    whois \
    traceroute \
    mtr \
    htop \
    iotop \
    iftop \
    nmon \
    glances \
    lsof \
    netstat-nat \
    ufw \
    apparmor \
    apparmor-utils \
    rkhunter \
    chkrootkit \
    lynis \
    clamav \
    clamav-daemon"

print_success "Security Tools installed!"

# Step 6: Install Development Tools
print_status "Step 6: Installing Development Tools..."

chroot "$WORK_DIR/rootfs" /bin/bash -c "apt install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    git \
    subversion \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    default-jdk \
    golang \
    flatpak"

# Add Flathub repository
chroot "$WORK_DIR/rootfs" /bin/bash -c "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"

print_success "Development Tools installed!"

# Step 7: Install Media Applications
print_status "Step 7: Installing Media Applications..."

chroot "$WORK_DIR/rootfs" /bin/bash -c "apt install -y --no-install-recommends \
    vlc \
    mpv \
    audacious \
    gimp \
    feh \
    scrot \
    simplescreenrecorder \
    ffmpeg"

print_success "Media Applications installed!"

# Step 8: Install Office Applications
print_status "Step 8: Installing Office Applications..."

chroot "$WORK_DIR/rootfs" /bin/bash -c "apt install -y --no-install-recommends \
    libreoffice \
    libreoffice-l10n-en-us \
    evince \
    firefox \
    thunderbird"

print_success "Office Applications installed!"

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

# Enable LightDM
chroot "$WORK_DIR/rootfs" /bin/bash -c "systemctl enable lightdm"

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

# Enable Network Manager
chroot "$WORK_DIR/rootfs" /bin/bash -c "systemctl enable NetworkManager"

print_success "Network Manager configured!"

# Step 12: Configure GRUB
print_status "Step 12: Configuring GRUB..."

# Install GRUB
chroot "$WORK_DIR/rootfs" /bin/bash -c "apt install -y grub2 grub-efi-amd64 grub-efi-amd64-bin"

cat > "$WORK_DIR/rootfs/etc/default/grub" <<EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR="$DISTRO_NAME"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20 zswap.accept_throttled_writebacks=1 mitigations=off nowatchdog"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL="console"
GRUB_GFXMODE="1920x1080"
GRUB_DISABLE_OS_PROBER=false
EOF

print_success "GRUB configured!"

# Step 13: Create initramfs
print_status "Step 13: Creating initramfs..."

chroot "$WORK_DIR/rootfs" /bin/bash -c "apt install -y initramfs-tools busybox"

cat > "$WORK_DIR/rootfs/etc/initramfs-tools/initramfs.conf" <<'EOF'
MODULES=most
BUSYBOX=y
COMPRESS=lz4
BOOTTIME=y
DEVICE_MAPPER=y
LVM2=y
MDADM=y
DMRAID=y
BTRFS=y
ZFS=y
CRYPTSETUP=y
KEYMAP=y
FIRMWARE=y
EOF

# Copy kernel from host
if [ -f /boot/vmlinuz-$(uname -r) ]; then
    cp /boot/vmlinuz-$(uname -r) "$WORK_DIR/rootfs/boot/vmlinuz"
    cp /boot/initrd.img-$(uname -r) "$WORK_DIR/rootfs/boot/initrd.img"
else
    print_warning "Host kernel not found, will use debootstrap kernel"
fi

# Create initramfs
chroot "$WORK_DIR/rootfs" /bin/bash -c "update-initramfs -c -k all -b /boot"

print_success "initramfs created!"

# Step 14: Create user
print_status "Step 14: Creating default user..."

chroot "$WORK_DIR/rootfs" /bin/bash -c "useradd -m -s /bin/bash -G sudo,users,netdev,lpadmin,scanner lightning"
chroot "$WORK_DIR/rootfs" /bin/bash -c "echo 'lightning:lightning' | chpasswd"
chroot "$WORK_DIR/rootfs" /bin/bash -c "echo 'root:lightning' | chpasswd"

# Set up sudo
chroot "$WORK_DIR/rootfs" /bin/bash -c "usermod -aG sudo lightning"
cat > "$WORK_DIR/rootfs/etc/sudoers.d/lightning" <<'EOF'
lightning ALL=(ALL) NOPASSWD:ALL
EOF

print_success "Default user created!"

# Step 15: Clean up
print_status "Step 15: Cleaning up..."

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

# Step 16: Create SquashFS image
print_status "Step 16: Creating SquashFS image..."

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

# Create SquashFS image
mksquashfs "$WORK_DIR/rootfs" "$WORK_DIR/rootfs.squashfs" \
    -comp xz \
    -Xdict-size 100% \
    -b 256K \
    -Xbcj x86 \
    -noappend \
    -no-duplicates \
    -e "$WORK_DIR/exclude.list"

print_success "SquashFS image created!"

# Step 17: Create ISO
print_status "Step 17: Creating bootable ISO..."

# Create ISO directory structure
mkdir -p "$WORK_DIR/iso/{boot/grub,live}"

# Copy kernel and initramfs
if [ -f "$WORK_DIR/rootfs/boot/vmlinuz" ]; then
    cp "$WORK_DIR/rootfs/boot/vmlinuz" "$WORK_DIR/iso/boot/vmlinuz"
else
    # Use a generic kernel if not available
    print_warning "Using generic kernel"
fi

if [ -f "$WORK_DIR/rootfs/boot/initrd.img" ]; then
    cp "$WORK_DIR/rootfs/boot/initrd.img" "$WORK_DIR/iso/boot/initrd.img"
fi

# Copy SquashFS image
cp "$WORK_DIR/rootfs.squashfs" "$WORK_DIR/iso/live/rootfs.squashfs"

# Create GRUB configuration for ISO
cat > "$WORK_DIR/iso/boot/grub/grub.cfg" <<EOF
set default="0"
set timeout=10

menuentry "$DISTRO_NAME $DISTRO_VERSION - Live" {
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

# Create ISO using xorriso
xorriso \
    -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "$DISTRO_NAME" \
    -publisher "Lightning Linux Team" \
    -preparer "HarshitOS Project" \
    -application "$DISTRO_NAME $DISTRO_VERSION" \
    -copyright "GPLv3" \
    -b boot/grub/i386-pc/eltorito.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -o "$OUTPUT_DIR/$ISO_NAME" \
    "$WORK_DIR/iso"

print_success "ISO created at $OUTPUT_DIR/$ISO_NAME!"

# Step 18: Create bootable USB script
print_status "Step 18: Creating bootable USB script..."

cat > "$OUTPUT_DIR/create-usb.sh" <<EOF
#!/bin/bash

# Lightning Linux - Create Bootable USB
# Usage: sudo ./create-usb.sh /dev/sdX

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

echo "⚠️  WARNING: This will ERASE all data on \$USB_DEVICE!"
echo "Press Ctrl+C to cancel or Enter to continue..."
read

# Unmount any mounted partitions
for i in $(lsblk -lno MOUNTPOINT | grep "^${USB_DEVICE#/dev/}" | sort -r); do
    umount "\$i" 2>/dev/null || true
done

# Write ISO to USB
echo "Writing ISO to \$USB_DEVICE..."
dd if="\$ISO_FILE" of="\$USB_DEVICE" bs=4M status=progress
sync

echo "✅ Bootable USB created successfully!"
echo "You can now boot from \$USB_DEVICE"
EOF

chmod +x "$OUTPUT_DIR/create-usb.sh"

# Step 19: Create VirtualBox test script
print_status "Step 19: Creating VirtualBox test script..."

cat > "$OUTPUT_DIR/test-virtualbox.sh" <<EOF
#!/bin/bash

# Lightning Linux - Test in VirtualBox
# Usage: ./test-virtualbox.sh

ISO_FILE="$OUTPUT_DIR/$ISO_NAME"
VM_NAME="Lightning Linux"

if [ ! -f "\$ISO_FILE" ]; then
    echo "ISO file not found: \$ISO_FILE"
    exit 1
fi

if ! command -v VBoxManage &>/dev/null; then
    echo "VirtualBox not found. Please install VirtualBox first."
    exit 1
fi

echo "Creating VirtualBox VM..."

# Create VM
VBoxManage createvm --name "\$VM_NAME" --ostype Ubuntu_64 --register

# Configure VM
VBoxManage modifyvm "\$VM_NAME" --memory 2048 --cpus 2 --acpi on --boot1 dvd
VBoxManage modifyvm "\$VM_NAME" --graphicscontroller vboxsvga --vrde on

# Add SATA controller
VBoxManage storagectl "\$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci

# Attach ISO
VBoxManage storageattach "\$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type dvddrive --medium "\$ISO_FILE"

# Start VM
echo "Starting VM..."
VBoxManage startvm "\$VM_NAME"

# Display VM info
VBoxManage showvminfo "\$VM_NAME"
EOF

chmod +x "$OUTPUT_DIR/test-virtualbox.sh"

# Step 20: Create QEMU test script
print_status "Step 20: Creating QEMU test script..."

cat > "$OUTPUT_DIR/test-qemu.sh" <<EOF
#!/bin/bash

# Lightning Linux - Test in QEMU
# Usage: ./test-qemu.sh

ISO_FILE="$OUTPUT_DIR/$ISO_NAME"

if [ ! -f "\$ISO_FILE" ]; then
    echo "ISO file not found: \$ISO_FILE"
    exit 1
fi

if ! command -v qemu-system-x86_64 &>/dev/null; then
    echo "QEMU not found. Please install QEMU first."
    exit 1
fi

echo "Starting QEMU with Lightning Linux ISO..."
echo "Press Ctrl+Alt+G to release mouse cursor"
echo ""

qemu-system-x86_64 \
    -m 2048 \
    -smp 2 \
    -cdrom "\$ISO_FILE" \
    -net nic -net user \
    -vga virtio \
    -display sdl,gl=on \
    -enable-kvm \
    -cpu host
EOF

chmod +x "$OUTPUT_DIR/test-qemu.sh"

# Final summary
print_header "Build Complete!"
print_success ""
print_success "✅ Lightning Linux Live System Created Successfully!"
print_success ""
print_status "📁 Files Created:"
print_status "  - ISO: $OUTPUT_DIR/$ISO_NAME"
print_status "  - Size: $(du -h "$OUTPUT_DIR/$ISO_NAME" 2>/dev/null | cut -f1)"
print_status ""
print_status "🚀 Quick Start:"
print_status ""
print_status "  1. Create Bootable USB:"
print_status "     sudo $OUTPUT_DIR/create-usb.sh /dev/sdX"
print_status ""
print_status "  2. Test in VirtualBox:"
print_status "     $OUTPUT_DIR/test-virtualbox.sh"
print_status ""
print_status "  3. Test in QEMU:"
print_status "     $OUTPUT_DIR/test-qemu.sh"
print_status ""
print_status "💡 Default Credentials:"
print_status "  - Username: lightning"
print_status "  - Password: lightning"
print_status "  - Root Password: lightning"
print_status ""
print_status "📊 System Information:"
print_status "  - Distribution: $DISTRO_NAME $DISTRO_VERSION"
print_status "  - Desktop: Xfce4"
print_status "  - Kernel: $(uname -r)"
print_status "  - Architecture: $ARCH"
print_status "  - Optimizations: ZRAM, ZSWAP, THP, BFQ I/O Scheduler"
print_status ""
print_success "🎉 You can now use Lightning Linux!"

exit 0
