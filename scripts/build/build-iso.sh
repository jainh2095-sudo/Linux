#!/bin/bash

# Lightning Linux - ISO Build Script
# Part of HarshitOS / Lightning Linux project
# https://github.com/jainh2095-sudo/Linux

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
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

# Load configuration
CONFIG_FILE="config/build.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    print_error "Configuration file not found: $CONFIG_FILE"
    print_status "Please run ./scripts/config/configure-build.sh first."
    exit 1
fi

print_status "Loading configuration from $CONFIG_FILE..."

# Source configuration
source "$CONFIG_FILE"

# Set default values if not defined
DISTRO_NAME=${DISTRO_NAME:-"Lightning Linux"}
DISTRO_VERSION=${DISTRO_VERSION:-"0.1"}
DISTRO_CODENAME=${DISTRO_CODENAME:-"Harshit"}
ARCHITECTURE=${ARCHITECTURE:-$(uname -m)}
OUTPUT_DIR=${OUTPUT_DIR:-"build/output"}
ISO_NAME=${ISO_NAME:-"lightning-linux-${DISTRO_VERSION}-${ARCHITECTURE}.iso"}

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Temporary build directory
BUILD_DIR="build/tmp"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check dependencies
check_dependencies() {
    print_status "Checking build dependencies..."
    
    local missing_deps=()
    
    # Essential tools
    for tool in mksquashfs xorriso grub-mkrescue; do
        if ! command_exists "$tool"; then
            missing_deps+=("$tool")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_status "Please install them with:"
        print_status "  sudo apt install ${missing_deps[*]}"
        exit 1
    fi
    
    print_success "All dependencies are installed!"
}

# Function to create directory structure
create_structure() {
    print_status "Creating directory structure..."
    
    # Create necessary directories
    mkdir -p "$BUILD_DIR/{rootfs,boot,efi,isofs}"
    mkdir -p "$BUILD_DIR/rootfs/{bin,sbin,etc,var,usr,home,root,dev,proc,sys,tmp,opt}"
    mkdir -p "$BUILD_DIR/rootfs/usr/{bin,sbin,lib,lib64,share,include,local}"
    mkdir -p "$BUILD_DIR/rootfs/etc/{default,init.d,rc.d,sysctl.d,apt,NetworkManager}"
    mkdir -p "$BUILD_DIR/rootfs/var/{cache,log,lib,spool}"
    mkdir -p "$BUILD_DIR/rootfs/boot/grub"
    
    print_success "Directory structure created!"
}

# Function to install base system
install_base_system() {
    print_header "Installing Base System"
    
    print_status "Installing core packages..."
    
    # Use debootstrap for minimal system
    if command_exists debootstrap; then
        print_status "Using debootstrap to create minimal system..."
        debootstrap --arch="$ARCHITECTURE" focal "$BUILD_DIR/rootfs" http://archive.ubuntu.com/ubuntu
    else
        print_error "debootstrap not found. Please install it first."
        exit 1
    fi
    
    print_success "Base system installed!"
}

# Function to configure system
configure_system() {
    print_header "Configuring System"
    
    # Configure basic system settings
    print_status "Configuring basic system settings..."
    
    # Set hostname
    echo "lightning-linux" > "$BUILD_DIR/rootfs/etc/hostname"
    
    # Configure hosts file
    cat > "$BUILD_DIR/rootfs/etc/hosts" <<EOF
127.0.0.1   localhost
127.0.1.1   lightning-linux
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF
    
    # Configure fstab
    cat > "$BUILD_DIR/rootfs/etc/fstab" <<EOF
# <file system> <mount point> <type> <options> <dump> <pass>
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
devpts /dev/pts devpts defaults 0 0
tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0
EOF
    
    # Configure network
    cat > "$BUILD_DIR/rootfs/etc/network/interfaces" <<EOF
auto lo
iface lo inet loopback
EOF
    
    # Configure resolv.conf
    cat > "$BUILD_DIR/rootfs/etc/resolv.conf" <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
    
    # Configure sources.list
    cat > "$BUILD_DIR/rootfs/etc/apt/sources.list" <<EOF
deb http://archive.ubuntu.com/ubuntu focal main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-security main restricted universe multiverse
EOF
    
    # Configure locale
    cat > "$BUILD_DIR/rootfs/etc/default/locale" <<EOF
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8
EOF
    
    # Configure keyboard
    cat > "$BUILD_DIR/rootfs/etc/default/keyboard" <<EOF
XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""
EOF
    
    # Configure time zone
    ln -sf /usr/share/zoneinfo/America/New_York "$BUILD_DIR/rootfs/etc/localtime"
    echo "America/New_York" > "$BUILD_DIR/rootfs/etc/timezone"
    
    print_success "System configuration completed!"
}

# Function to install kernel
install_kernel() {
    print_header "Installing Kernel"
    
    print_status "Installing Linux kernel $KERNEL_VERSION..."
    
    # For now, use the host kernel
    print_status "Copying host kernel..."
    cp /boot/vmlinuz-$(uname -r) "$BUILD_DIR/rootfs/boot/vmlinuz"
    cp /boot/initrd.img-$(uname -r) "$BUILD_DIR/rootfs/boot/initrd.img"
    
    # Copy kernel modules
    print_status "Copying kernel modules..."
    mkdir -p "$BUILD_DIR/rootfs/lib/modules"
    cp -r /lib/modules/$(uname -r) "$BUILD_DIR/rootfs/lib/modules/"
    
    print_success "Kernel installed!"
}

# Function to configure init system
configure_init() {
    print_header "Configuring Init System"
    
    case "$INIT_SYSTEM" in
        openrc)
            print_status "Configuring OpenRC..."
            
            # Install OpenRC
            chroot "$BUILD_DIR/rootfs" /bin/bash -c "apt update && apt install -y openrc sysvinit-core"
            
            # Configure OpenRC
            cat > "$BUILD_DIR/rootfs/etc/rc.conf" <<EOF
rc_sys="lvm dmraid"
rc_parallel="YES"
rc_logger="NO"
rc_depend_strict="NO"
EOF
            
            # Configure inittab
            cat > "$BUILD_DIR/rootfs/etc/inittab" <<EOF
id:3:initdefault:
si::sysinit:/etc/init.d/rcS
rc::bootwait:/etc/init.d/rc
rb::bootwait:/etc/init.d/rc boot
rw::bootwait:/etc/init.d/rc default
sh::shutdown:/etc/init.d/rc shutdown
EOF
            
            # Create symlink for init
            ln -sf /sbin/openrc-init "$BUILD_DIR/rootfs/sbin/init"
            
            print_success "OpenRC configured!"
            ;;
        systemd)
            print_status "Configuring systemd..."
            
            # Install systemd
            chroot "$BUILD_DIR/rootfs" /bin/bash -c "apt update && apt install -y systemd systemd-sysv"
            
            # Configure systemd
            ln -sf /usr/lib/systemd/systemd "$BUILD_DIR/rootfs/sbin/init"
            
            print_success "systemd configured!"
            ;;
        *)
            print_warning "Unknown init system: $INIT_SYSTEM. Using OpenRC as default."
            INIT_SYSTEM="openrc"
            configure_init
            ;;
    esac
}

# Function to install desktop environment
install_desktop() {
    print_header "Installing Desktop Environment"
    
    case "$DESKTOP_ENVIRONMENT" in
        xfce4)
            print_status "Installing Xfce4..."
            
            # Install Xfce4
            chroot "$BUILD_DIR/rootfs" /bin/bash -c "apt update && apt install -y xfce4 xfce4-goodies lightdm"
            
            # Configure LightDM
            cat > "$BUILD_DIR/rootfs/etc/lightdm/lightdm.conf" <<EOF
[LightDM]
minimum-display-number=0

[Seat:*]
xserver-command=X -background none
greeter-session=lightdm-greeter
user-session=xfce4

[Seat:seat0]
type=xlocal
xserver-command=X
EOF
            
            # Enable LightDM
            chroot "$BUILD_DIR/rootfs" /bin/bash -c "systemctl enable lightdm"
            
            print_success "Xfce4 installed!"
            ;;
        openbox)
            print_status "Installing Openbox..."
            
            # Install Openbox
            chroot "$BUILD_DIR/rootfs" /bin/bash -c "apt update && apt install -y openbox tint2 pcmanfm lightdm"
            
            # Configure Openbox
            mkdir -p "$BUILD_DIR/rootfs/etc/xdg/openbox"
            cat > "$BUILD_DIR/rootfs/etc/xdg/openbox/rc.xml" <<EOF
<openbox_config>
  <resistance>
    <strength>10</strength>
    <screen_edge_strength>20</screen_edge_strength>
  </resistance>
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
    <autoRaise>no</autoRaise>
  </focus>
  <placement>
    <policy>Smart</policy>
  </placement>
</openbox_config>
EOF
            
            print_success "Openbox installed!"
            ;;
        lxqt)
            print_status "Installing LXQt..."
            
            # Install LXQt
            chroot "$BUILD_DIR/rootfs" /bin/bash -c "apt update && apt install -y lxqt sddm"
            
            # Configure SDDM
            cat > "$BUILD_DIR/rootfs/etc/sddm.conf" <<EOF
[General]
InputMethod=
Numlock=on

[Autologin]
User=
Session=

[Theme]
Current=maldives
EOF
            
            print_success "LXQt installed!"
            ;;
        none)
            print_status "Skipping desktop environment installation..."
            ;;
        *)
            print_warning "Unknown desktop environment: $DESKTOP_ENVIRONMENT. Skipping..."
            ;;
    esac
}

# Function to install packages
install_packages() {
    print_header "Installing Packages"
    
    # Update package lists
    chroot "$BUILD_DIR/rootfs" /bin/bash -c "apt update"
    
    # Install essential packages
    print_status "Installing essential packages..."
    chroot "$BUILD_DIR/rootfs" /bin/bash -c "apt install -y \
        sudo \
        bash \
        coreutils \
        util-linux \
        findutils \
        grep \
        sed \
        awk \
        gzip \
        bzip2 \
        xz-utils \
        tar \
        curl \
        wget \
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
        os-prober \
        grub2 \
        grub-efi \
        syslinux"
    
    # Install security tools
    if [ "$INCLUDE_SECURITY" = "yes" ]; then
        print_status "Installing security tools..."
        chroot "$BUILD_DIR/rootfs" /bin/bash -c "apt install -y \
            nmap \
            wireshark \
            tcpdump \
            tshark \
            ncat \
            net-tools \
            iproute2 \
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
            ss \
            ipset \
            iptables \
            nftables \
            ufw \
            apparmor \
            apparmor-utils \
            rkhunter \
            chkrootkit \
            lynis \
            clamav \
            clamav-daemon"
    fi
    
    # Install development tools
    if [ "$INCLUDE_DEVELOPMENT" = "yes" ]; then
        print_status "Installing development tools..."
        chroot "$BUILD_DIR/rootfs" /bin/bash -c "apt install -y \
            build-essential \
            gcc \
            g++ \
            make \
            cmake \
            ninja-build \
            autoconf \
            automake \
            libtool \
            pkg-config \
            git \
            subversion \
            mercurial \
            bzr \
            patch \
            diffutils \
            strace \
            ltrace \
            gdb \
            valgrind \
            python3 \
            python3-pip \
            python3-venv \
            python3-dev \
            nodejs \
            npm \
            default-jdk \
            maven \
            gradle \
            golang \
            rustc \
            cargo \
            ruby \
            php \
            composer \
            docker.io \
            docker-compose \
            podman \
            lxc \
            lxd"
    fi
    
    # Install media applications
    if [ "$INCLUDE_MEDIA" = "yes" ]; then
        print_status "Installing media applications..."
        chroot "$BUILD_DIR/rootfs" /bin/bash -c "apt install -y \
            vlc \
            mpv \
            audacious \
            clementine \
            deadbeef \
            gimp \
            inkscape \
            pinta \
            feh \
            scrot \
            flameshot \
            simplescreenrecorder \
            obs-studio \
            ffmpeg \
            audacity \
            ardour \
            lmms \
            hydrogen \
            openshot \
            kdenlive \
            shotcut \
            pitivi"
    fi
    
    # Install office applications
    if [ "$INCLUDE_OFFICE" = "yes" ]; then
        print_status "Installing office applications..."
        chroot "$BUILD_DIR/rootfs" /bin/bash -c "apt install -y \
            libreoffice \
            libreoffice-l10n-en-us \
            abiword \
            gnumeric \
            evince \
            okular \
            qpdfview \
            poppler-utils \
            ghostscript \
            thunderbird \
            claws-mail \
            geary \
            evolution \
            orage \
            firefox \
            chromium-browser \
            falkon \
            midori"
    fi
    
    # Install Flatpak
    print_status "Installing Flatpak..."
    chroot "$BUILD_DIR/rootfs" /bin/bash -c "apt install -y flatpak"
    chroot "$BUILD_DIR/rootfs" /bin/bash -c "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
    
    # Install Snap
    print_status "Installing Snap..."
    chroot "$BUILD_DIR/rootfs" /bin/bash -c "apt install -y snapd"
    
    print_success "Packages installed!"
}

# Function to configure optimizations
configure_optimizations() {
    print_header "Configuring Optimizations"
    
    # Configure ZRAM
    if [ "$ENABLE_ZRAM" = "yes" ]; then
        print_status "Configuring ZRAM..."
        
        # Create ZRAM script
        cat > "$BUILD_DIR/rootfs/usr/local/bin/zram-config.sh" <<'EOF'
#!/bin/bash

# Calculate ZRAM size (50% of total RAM)
TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
ZRAM_SIZE=$((TOTAL_MEM * 1024 / 2))

# Load zram module
modprobe zram num_devices=1

# Configure zram0
echo lz4 > /sys/block/zram0/comp_algorithm
echo $ZRAM_SIZE > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon /dev/zram0 -p 100

# Set swappiness
sysctl vm.swappiness=100
sysctl vm.watermark_scale_factor=200
EOF
        
        chmod +x "$BUILD_DIR/rootfs/usr/local/bin/zram-config.sh"
        
        # Create systemd service
        cat > "$BUILD_DIR/rootfs/etc/systemd/system/zram-config.service" <<'EOF'
[Unit]
Description=Configure ZRAM swap devices
After=sysinit.target
Before=swap.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/zram-config.sh

[Install]
WantedBy=multi-user.target
EOF
        
        # Create OpenRC init script
        cat > "$BUILD_DIR/rootfs/etc/init.d/zram-config" <<'EOF'
#!/sbin/openrc-run

name="zram-config"
description="Configure ZRAM swap devices"
start_cmd="/usr/local/bin/zram-config.sh"

supervise_daemon_args="--stdout /var/log/zram-config.log --stderr /var/log/zram-config.err"
EOF
        
        chmod +x "$BUILD_DIR/rootfs/etc/init.d/zram-config"
        
        print_success "ZRAM configured!"
    fi
    
    # Configure ZSWAP
    if [ "$ENABLE_ZSWAP" = "yes" ]; then
        print_status "Configuring ZSWAP..."
        
        cat > "$BUILD_DIR/rootfs/etc/sysctl.d/99-zswap.conf" <<'EOF'
# Enable ZSWAP
vm.zswap.enabled=1

# Use lz4 compression
vm.zswap.compressor=lz4

# Maximum percentage of RAM to use for ZSWAP pool
vm.zswap.max_pool_percent=20

# Accept throttled writebacks
vm.zswap.accept_throttled_writebacks=1
EOF
        
        print_success "ZSWAP configured!"
    fi
    
    # Configure THP
    if [ "$ENABLE_THP" = "yes" ]; then
        print_status "Configuring Transparent HugePages..."
        
        cat > "$BUILD_DIR/rootfs/etc/sysctl.d/99-thp.conf" <<'EOF'
# Enable THP
vm.thp_enabled=1

# Enable THP defragmentation
vm.thp_defrag_enabled=1

# Enable THP for anonymous pages
vm.thp_anonymous_only=0
EOF
        
        print_success "THP configured!"
    fi
    
    # Configure I/O Scheduler
    print_status "Configuring I/O Scheduler to $IO_SCHEDULER..."
    
    cat > "$BUILD_DIR/rootfs/etc/udev/rules.d/60-io-scheduler.rules" <<EOF
# Set I/O scheduler for all block devices
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]*|vd[a-z]", ATTR{queue/scheduler}="$IO_SCHEDULER"
EOF
    
    # Configure CPU Governor
    print_status "Configuring CPU Governor to $CPU_GOVERNOR..."
    
    cat > "$BUILD_DIR/rootfs/etc/default/cpufrequtils" <<EOF
GOVERNOR="$CPU_GOVERNOR"
MIN_SPEED="800000"
MAX_SPEED="3600000"
EOF
    
    # Configure swappiness
    cat > "$BUILD_DIR/rootfs/etc/sysctl.d/99-swappiness.conf" <<'EOF'
# Swappiness
vm.swappiness=60

# Watermark scale factor
vm.watermark_scale_factor=200
EOF
    
    print_success "Optimizations configured!"
}

# Function to configure GRUB
configure_grub() {
    print_header "Configuring GRUB"
    
    print_status "Installing GRUB..."
    
    # Install GRUB
    chroot "$BUILD_DIR/rootfs" /bin/bash -c "grub-install --target=i386-pc /dev/loop0"
    
    # Configure GRUB
    cat > "$BUILD_DIR/rootfs/etc/default/grub" <<EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR="$DISTRO_NAME"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20 zswap.accept_throttled_writebacks=1 mitigations=off nowatchdog"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL="console"
GRUB_GFXMODE="1920x1080"
GRUB_GFXPAYLOAD_LINUX="keep"
GRUB_DISABLE_OS_PROBER=false
EOF
    
    # Create GRUB configuration
    chroot "$BUILD_DIR/rootfs" /bin/bash -c "update-grub"
    
    # Copy GRUB files
    cp -r /usr/lib/grub/i386-pc "$BUILD_DIR/rootfs/boot/grub/"
    
    print_success "GRUB configured!"
}

# Function to create initramfs
create_initramfs() {
    print_header "Creating Initramfs"
    
    print_status "Creating initramfs..."
    
    # Create initramfs configuration
    cat > "$BUILD_DIR/rootfs/etc/initramfs-tools/initramfs.conf" <<EOF
MODULES=most
BUSYBOX=y
COMPRESS=lz4
COMPRESS_OPTIONS="-9"
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
    
    # Create initramfs
    chroot "$BUILD_DIR/rootfs" /bin/bash -c "update-initramfs -c -k $(uname -r) -b /boot"
    
    print_success "Initramfs created!"
}

# Function to create SquashFS image
create_squashfs() {
    print_header "Creating SquashFS Image"
    
    print_status "Creating SquashFS image..."
    
    # Create SquashFS image
    mksquashfs "$BUILD_DIR/rootfs" "$BUILD_DIR/squashfs-root.xz" \
        -comp xz \
        -Xdict-size 100% \
        -b 256K \
        -Xbcj x86 \
        -noappend \
        -no-duplicates
    
    print_success "SquashFS image created!"
}

# Function to create ISO image
create_iso() {
    print_header "Creating ISO Image"
    
    print_status "Creating ISO image..."
    
    # Copy kernel and initramfs to ISO directory
    cp "$BUILD_DIR/rootfs/boot/vmlinuz" "$BUILD_DIR/isofs/boot/vmlinuz"
    cp "$BUILD_DIR/rootfs/boot/initrd.img" "$BUILD_DIR/isofs/boot/initrd.img"
    
    # Copy SquashFS image
    cp "$BUILD_DIR/squashfs-root.xz" "$BUILD_DIR/isofs/"
    
    # Create GRUB configuration for ISO
    cat > "$BUILD_DIR/isofs/boot/grub/grub.cfg" <<EOF
set default="0"
set timeout=10

menuentry "$DISTRO_NAME $DISTRO_VERSION" {
    linux /boot/vmlinuz root=/dev/ram0 ramdisk_size=1000000 quiet splash
    initrd /boot/initrd.img
}

menuentry "$DISTRO_NAME (Persistent)" {
    linux /boot/vmlinuz root=/dev/ram0 ramdisk_size=1000000 quiet splash persistent
    initrd /boot/initrd.img
}

menuentry "Check Disc" {
    linux16 /boot/grub/i386-pc/chainloader /dev/cd0
}

menuentry "Memory Test" {
    linux16 /boot/grub/i386-pc/memtest86+
}
EOF
    
    # Create ISO image
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
        "$BUILD_DIR/isofs"
    
    print_success "ISO image created at $OUTPUT_DIR/$ISO_NAME!"
}

# Function to clean up
cleanup() {
    print_header "Cleaning Up"
    
    print_status "Cleaning up temporary files..."
    
    # Remove temporary build directory
    rm -rf "$BUILD_DIR"
    
    print_success "Cleanup completed!"
}

# Function to display summary
show_summary() {
    print_header "Build Summary"
    
    print_status "Distribution: $DISTRO_NAME $DISTRO_VERSION ($DISTRO_CODENAME)"
    print_status "Architecture: $ARCHITECTURE"
    print_status "Kernel: $KERNEL_VERSION"
    print_status "Init System: $INIT_SYSTEM"
    print_status "LibC: $LIBC_IMPLEMENTATION"
    print_status "Desktop: $DESKTOP_ENVIRONMENT"
    print_status "Display Manager: $DISPLAY_MANAGER"
    print_status ""
    print_status "Optimizations:"
    print_status "  - ZRAM: $ENABLE_ZRAM"
    print_status "  - ZSWAP: $ENABLE_ZSWAP"
    print_status "  - THP: $ENABLE_THP"
    print_status "  - I/O Scheduler: $IO_SCHEDULER"
    print_status "  - CPU Governor: $CPU_GOVERNOR"
    print_status ""
    print_status "Packages:"
    print_status "  - Security: $INCLUDE_SECURITY"
    print_status "  - Development: $INCLUDE_DEVELOPMENT"
    print_status "  - Media: $INCLUDE_MEDIA"
    print_status "  - Office: $INCLUDE_OFFICE"
    print_status ""
    print_status "Output:"
    print_status "  - ISO: $OUTPUT_DIR/$ISO_NAME"
    print_status ""
}

# Main script execution
print_header "Lightning Linux ISO Build Script"

# Check dependencies
check_dependencies

# Create structure
create_structure

# Install base system
install_base_system

# Configure system
configure_system

# Install kernel
install_kernel

# Configure init system
configure_init

# Install desktop environment
install_desktop

# Install packages
install_packages

# Configure optimizations
configure_optimizations

# Configure GRUB
configure_grub

# Create initramfs
create_initramfs

# Create SquashFS image
create_squashfs

# Create ISO image
create_iso

# Clean up
cleanup

# Show summary
show_summary

print_success ""
print_success "Lightning Linux ISO build completed successfully!"
print_success "The ISO image is available at: $OUTPUT_DIR/$ISO_NAME"
print_success ""
print_status "You can now test the ISO in a virtual machine or burn it to a USB drive."

# Display ISO information
if [ -f "$OUTPUT_DIR/$ISO_NAME" ]; then
    print_status ""
    print_status "ISO Information:"
    print_status "  - Size: $(du -h "$OUTPUT_DIR/$ISO_NAME" | cut -f1)"
    print_status "  - Path: $(realpath "$OUTPUT_DIR/$ISO_NAME")"
fi

exit 0
