# Lightning Linux Build Guide

> **A lightweight, multi-purpose Linux distro combining the best of Ubuntu, Kali, and Mint—optimized for 2GB RAM.**

---

## 📋 Table of Contents

1. [Introduction](#-introduction)
2. [Prerequisites](#-prerequisites)
3. [Quick Start](#-quick-start)
4. [Detailed Build Process](#-detailed-build-process)
5. [Configuration Options](#-configuration-options)
6. [Customization](#-customization)
7. [Testing](#-testing)
8. [Troubleshooting](#-troubleshooting)
9. [Advanced Topics](#-advanced-topics)

---

## 🎯 Introduction

This guide provides step-by-step instructions for building Lightning Linux (HarshitOS) from source. Lightning Linux is designed to be:

- **Lightweight**: ≤2GB RAM usage, ≤10GB storage
- **Multi-Purpose**: General use, security tools, user-friendly
- **Compatible**: Runs on old hardware (i5 6th gen + 4GB RAM)
- **Fast**: Boot time <10 seconds

---

## 📦 Prerequisites

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 4GB | 8GB+ |
| Storage | 50GB | 100GB+ |
| Architecture | x86_64 | x86_64 |

### Software Requirements

**Supported Build Environments:**
- Ubuntu 22.04 LTS (Recommended)
- Ubuntu 20.04 LTS
- Debian 11 (Bullseye)
- Debian 12 (Bookworm)
- Fedora 36+
- Arch Linux

**Required Tools:**
- Git
- GCC/Clang
- Make
- CMake
- Autoconf/Automake
- QEMU (for testing)
- SquashFS tools
- xorriso

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
# Clone the Lightning Linux repository
git clone https://github.com/jainh2095-sudo/Linux.git lightning-linux
cd lightning-linux
```

### 2. Install Build Dependencies

```bash
# Install all required build dependencies
sudo ./scripts/build/install-dependencies.sh
```

### 3. Configure the Build

```bash
# Run the configuration script
./scripts/config/configure-build.sh
```

Follow the interactive prompts to configure your build.

### 4. Build the ISO

```bash
# Build the ISO image
sudo ./scripts/build/build-iso.sh
```

### 5. Test the ISO

```bash
# Test in QEMU
qemu-system-x86_64 -m 2048 -smp 2 -cdrom build/output/lightning-linux-*.iso

# Or test in VirtualBox
VBoxManage createvm --name "Lightning Linux" --ostype Linux_64 --register
VBoxManage modifyvm "Lightning Linux" --memory 2048 --cpus 2
VBoxManage storagectl "Lightning Linux" --name "SATA Controller" --add sata
VBoxManage storageattach "Lightning Linux" --storagectl "SATA Controller" --port 0 --device 0 --type dvddrive --medium build/output/lightning-linux-*.iso
VBoxManage startvm "Lightning Linux"
```

---

## 🏗️ Detailed Build Process

### Step 1: Set Up Build Environment

#### 1.1. Install Required Packages

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y git build-essential cmake ninja-build autoconf automake libtool pkg-config
sudo apt install -y squashfs-tools xorriso mtools dosfstools e2fsprogs btrfs-progs
sudo apt install -y qemu-system qemu-utils debootstrap
```

**Fedora:**
```bash
sudo dnf install -y git gcc gcc-c++ make cmake ninja-build autoconf automake libtool pkgconf
sudo dnf install -y squashfs-tools xorriso mtools dosfstools e2fsprogs btrfs-progs
sudo dnf install -y qemu-system-x86 qemu-utils
```

**Arch Linux:**
```bash
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm git base-devel cmake ninja autoconf automake libtool pkgconf
sudo pacman -S --noconfirm squashfs-tools xorriso mtools dosfstools e2fsprogs btrfs-progs
sudo pacman -S --noconfirm qemu
```

#### 1.2. Clone the Repository

```bash
git clone https://github.com/jainh2095-sudo/Linux.git lightning-linux
cd lightning-linux
```

#### 1.3. Verify Dependencies

```bash
# Check if all dependencies are installed
./scripts/build/install-dependencies.sh --check
```

### Step 2: Configure the Build

#### 2.1. Quick Configuration

```bash
# Run interactive configuration
./scripts/config/configure-build.sh
```

This will guide you through the configuration process with sensible defaults.

#### 2.2. Manual Configuration

Edit `config/build.conf` manually:

```bash
nano config/build.conf
```

**Key Configuration Options:**

```ini
[General]
DISTRO_NAME="Lightning Linux"
DISTRO_VERSION="0.1"
DISTRO_CODENAME="Harshit"
ARCHITECTURE="x86_64"

[Kernel]
KERNEL_VERSION="6.1.85"

[Init]
INIT_SYSTEM="openrc"  # or "systemd"

[LibC]
LIBC_IMPLEMENTATION="glibc"  # or "musl"

[Desktop]
DESKTOP_ENVIRONMENT="xfce4"  # or "openbox", "lxqt", "none"
DISPLAY_MANAGER="lightdm"

[Optimizations]
ENABLE_ZRAM="yes"
ENABLE_ZSWAP="yes"
ENABLE_THP="yes"
IO_SCHEDULER="bfq"
CPU_GOVERNOR="schedutil"

[Packages]
INCLUDE_SECURITY="yes"
INCLUDE_DEVELOPMENT="yes"
INCLUDE_MEDIA="yes"
INCLUDE_OFFICE="yes"
```

#### 2.3. Configuration Profiles

**Lightweight Profile (2GB RAM target):**
```bash
# Use OpenRC, musl libc, Openbox
./scripts/config/configure-build.sh --profile lightweight
```

**Desktop Profile (4GB RAM target):**
```bash
# Use systemd, glibc, Xfce4
./scripts/config/configure-build.sh --profile desktop
```

**Server Profile (No GUI):**
```bash
# Use OpenRC, glibc, no desktop
./scripts/config/configure-build.sh --profile server
```

### Step 3: Build the Base System

#### 3.1. Create Build Directory

```bash
# Create build directories
mkdir -p build/{output,tmp,logs}
```

#### 3.2. Build Using debootstrap

The build script uses `debootstrap` to create a minimal Ubuntu-based system:

```bash
# Manually create base system (optional)
sudo debootstrap --arch=amd64 focal build/tmp/rootfs http://archive.ubuntu.com/ubuntu
```

#### 3.3. Run the Build Script

```bash
# Build the complete ISO
sudo ./scripts/build/build-iso.sh
```

**Build Process Overview:**
1. Check dependencies
2. Create directory structure
3. Install base system
4. Configure system settings
5. Install kernel
6. Configure init system
7. Install desktop environment
8. Install packages
9. Configure optimizations
10. Configure GRUB
11. Create initramfs
12. Create SquashFS image
13. Create ISO image
14. Clean up

### Step 4: Customize the Build

#### 4.1. Add Custom Packages

Edit the package lists in `packages/` directory:

```bash
# Add packages to base system
nano packages/base/base-packages.txt

# Add security tools
nano packages/security/security-tools.txt

# Add desktop packages
nano packages/desktop/xfce4-packages.txt
```

#### 4.2. Add Custom Configuration

Add custom configuration files to `configs/` directory:

```bash
# System configuration
mkdir -p configs/system
nano configs/system/rc.local

# Desktop configuration
mkdir -p configs/desktop
nano configs/desktop/xfce4-settings.conf

# Services configuration
mkdir -p configs/services
nano configs/services/lightdm.conf
```

#### 4.3. Add Custom Scripts

Add custom scripts to `scripts/` directory:

```bash
# Post-install scripts
mkdir -p scripts/post-install
nano scripts/post-install/01-custom-setup.sh

# Pre-removal scripts
mkdir -p scripts/pre-removal
nano scripts/pre-removal/01-custom-cleanup.sh
```

### Step 5: Build and Test

#### 5.1. Build the ISO

```bash
sudo ./scripts/build/build-iso.sh
```

#### 5.2. Test in QEMU

```bash
# Basic test
qemu-system-x86_64 -m 2048 -smp 2 -cdrom build/output/lightning-linux-*.iso

# Advanced test with KVM
qemu-system-x86_64 \
  -enable-kvm \
  -m 4096 \
  -smp 4 \
  -cdrom build/output/lightning-linux-*.iso \
  -net nic -net user \
  -vga virtio \
  -display sdl,gl=on
```

#### 5.3. Test in VirtualBox

```bash
# Create VM
VBoxManage createvm --name "Lightning Linux" --ostype Linux_64 --register
VBoxManage modifyvm "Lightning Linux" --memory 2048 --cpus 2 --acpi on --boot1 dvd
VBoxManage storagectl "Lightning Linux" --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach "Lightning Linux" --storagectl "SATA Controller" --port 0 --device 0 --type dvddrive --medium build/output/lightning-linux-*.iso
VBoxManage startvm "Lightning Linux"
```

#### 5.4. Test on Real Hardware

**Create Bootable USB:**

```bash
# Using dd (Linux/macOS)
sudo dd if=build/output/lightning-linux-*.iso of=/dev/sdX bs=4M status=progress
sync

# Using Rufus (Windows)
# Download from https://rufus.ie/
# Select ISO and USB drive, click Start

# Using Balena Etcher (Cross-platform)
# Download from https://www.balena.io/etcher/
# Select ISO, select USB drive, click Flash
```

**Boot from USB:**
1. Insert USB drive
2. Enter BIOS/UEFI
3. Select USB as boot device
4. Save and exit

---

## ⚙️ Configuration Options

### Kernel Configuration

| Option | Description | Recommended |
|--------|-------------|-------------|
| `KERNEL_VERSION` | Linux kernel version | 6.1.85 (LTS) |
| `KERNEL_PATCHSET` | Custom kernel patches | none, ck, pf, tkg, zen |
| `KERNEL_COMPRESSION` | Kernel compression | xz |

### Init System Configuration

| Option | Description | Recommended |
|--------|-------------|-------------|
| `INIT_SYSTEM` | Init system to use | openrc (lightweight) or systemd (compatible) |

**OpenRC vs systemd:**

| Feature | OpenRC | systemd |
|---------|--------|---------|
| Memory Usage | ~5MB | ~20-30MB |
| Boot Time | ~2-3s | ~4-5s |
| Complexity | Simple | Complex |
| Compatibility | Good | Excellent |
| Features | Basic | Advanced |

### LibC Configuration

| Option | Description | Recommended |
|--------|-------------|-------------|
| `LIBC_IMPLEMENTATION` | C library implementation | glibc (compatible) or musl (lightweight) |

**glibc vs musl:**

| Feature | glibc | musl |
|---------|-------|------|
| Memory Usage | ~5-10MB per process | ~1-2MB per process |
| Compatibility | Full | Most applications |
| Performance | Well-optimized | Faster in some cases |
| Static Linking | Limited | Supported |

### Desktop Environment Configuration

| Option | Description | Memory Usage | Recommended |
|--------|-------------|--------------|-------------|
| `xfce4` | Xfce4 desktop | ~150-200MB | ✅ Best for 2GB RAM |
| `openbox` | Openbox WM | ~50-100MB | ✅ Ultra-lightweight |
| `lxqt` | LXQt desktop | ~200-250MB | Good alternative |
| `none` | No desktop | ~50-100MB | Server/CLI only |

### Performance Optimizations

| Option | Description | Recommended |
|--------|-------------|-------------|
| `ENABLE_ZRAM` | Enable ZRAM swap | yes |
| `ZRAM_SIZE_PERCENT` | ZRAM size as % of RAM | 50 |
| `ZRAM_COMPRESSION` | ZRAM compression algorithm | lz4 |
| `ENABLE_ZSWAP` | Enable ZSWAP | yes |
| `ZSWAP_COMPRESSOR` | ZSWAP compression algorithm | lz4 |
| `ENABLE_THP` | Enable Transparent HugePages | yes |
| `IO_SCHEDULER` | I/O scheduler | bfq (HDD), none (SSD/NVMe) |
| `CPU_GOVERNOR` | CPU frequency governor | schedutil |

### Package Groups

| Option | Description | Size | Recommended |
|--------|-------------|------|-------------|
| `INCLUDE_SECURITY` | Security tools (nmap, wireshark, etc.) | ~500MB | yes |
| `INCLUDE_DEVELOPMENT` | Development tools (gcc, python, etc.) | ~800MB | yes |
| `INCLUDE_MEDIA` | Media applications (vlc, gimp, etc.) | ~400MB | yes |
| `INCLUDE_OFFICE` | Office applications (libreoffice, etc.) | ~500MB | yes |

---

## 🎨 Customization

### 1. Custom Package Lists

Create custom package lists in `packages/` directory:

```bash
# Create custom package list
mkdir -p packages/custom
nano packages/custom/my-packages.txt
```

**Package List Format:**
```
# Comment
package1
package2
package3
```

### 2. Custom Configuration Files

Add custom configuration files to `configs/` directory:

```bash
# System configuration
mkdir -p configs/system
nano configs/system/custom.conf

# Desktop configuration
mkdir -p configs/desktop
nano configs/desktop/custom.conf
```

### 3. Custom Scripts

Add custom scripts to `scripts/` directory:

```bash
# Post-install script
mkdir -p scripts/post-install
nano scripts/post-install/01-custom.sh
```

**Script Format:**
```bash
#!/bin/bash
# Custom post-install script

echo "Running custom post-install script..."

# Your custom commands here
apt install -y my-package

# Exit successfully
exit 0
```

Make scripts executable:
```bash
chmod +x scripts/post-install/01-custom.sh
```

### 4. Custom Kernel Configuration

Create custom kernel configuration:

```bash
# Copy existing config
cp /boot/config-$(uname -r) configs/kernel/config-x86_64

# Edit kernel config
nano configs/kernel/config-x86_64

# Or use menuconfig
make menuconfig
```

**Recommended Kernel Options:**
```
# Memory Management
CONFIG_ZRAM=y
CONFIG_ZRAM_WRITEBACK=y
CONFIG_ZSWAP=y
CONFIG_ZPOOL=y

# CPU Schedulers
CONFIG_SCHED_MUQSS=y
CONFIG_SCHED_BMQ=y

# I/O Schedulers
CONFIG_IOSCHED_BFQ=y
CONFIG_IOSCHED_KYBER=y

# Preemption Model
CONFIG_PREEMPT=y

# Transparent HugePages
CONFIG_TRANSPARENT_HUGEPAGE=y
```

### 5. Custom Boot Splash

Create custom boot splash screen:

```bash
# Install Plymouth
sudo apt install plymouth plymouth-themes

# Create custom theme
mkdir -p configs/plymouth/lightning-linux
nano configs/plymouth/lightning-linux/lightning-linux.plymouth
```

**Plymouth Theme Example:**
```
[Plymouth Theme]
Name=Lightning Linux
Description=A theme for Lightning Linux
ModuleName=two-step

[two-step]
ImageDir=/usr/share/plymouth/themes/lightning-linux
AnimationDir=/usr/share/plymouth/themes/lightning-linux
```

### 6. Custom Wallpapers and Themes

Add custom wallpapers and themes:

```bash
# Create themes directory
mkdir -p configs/themes/wallpapers
mkdir -p configs/themes/gtk
mkdir -p configs/themes/icons

# Add wallpapers
cp my-wallpaper.png configs/themes/wallpapers/

# Add GTK themes
cp -r my-theme configs/themes/gtk/

# Add icon themes
cp -r my-icons configs/themes/icons/
```

---

## 🧪 Testing

### 1. Automated Testing

```bash
# Run all tests
./scripts/test/run-tests.sh

# Run specific test
./scripts/test/run-tests.sh memory
./scripts/test/run-tests.sh cpu
./scripts/test/run-tests.sh storage
```

### 2. Manual Testing

#### Memory Usage Test

```bash
# Check memory usage
free -h

# Check process memory
ps aux --sort=-%mem | head

# Check ZRAM usage
cat /proc/swaps
cat /sys/block/zram0/mem_used_max
```

#### CPU Performance Test

```bash
# Check CPU usage
top
htop

# Check CPU frequency
cat /proc/cpuinfo | grep MHz

# Check CPU governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

#### Storage Performance Test

```bash
# Check disk usage
df -h

# Check I/O scheduler
echo $(cat /sys/block/sda/queue/scheduler)

# Check read-ahead
cat /sys/block/sda/queue/read_ahead_kb
```

#### Boot Time Test

```bash
# Check boot time
systemd-analyze

# Check boot time by service
systemd-analyze blame

# Check critical chain
systemd-analyze critical-chain
```

### 3. Benchmarking

```bash
# Install benchmarking tools
sudo apt install sysbench fio bonnie++

# CPU benchmark
sysbench cpu --threads=4 run

# Memory benchmark
sysbench memory --memory-block-size=1G run

# Disk benchmark
fio --name=benchmark --ioengine=libaio --rw=randread --bs=4k --numjobs=4 --size=1G --runtime=60

# Comprehensive benchmark
bonnie++ -d /tmp -s 1G -n 0 -m TEST -f -b
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Build Dependencies Missing

**Symptoms:**
- Build script fails with "command not found"
- Missing packages error

**Solution:**
```bash
# Install missing dependencies
sudo ./scripts/build/install-dependencies.sh

# Or install manually
sudo apt install missing-package
```

#### 2. debootstrap Fails

**Symptoms:**
- debootstrap: command not found
- debootstrap fails to download packages

**Solution:**
```bash
# Install debootstrap
sudo apt install debootstrap

# Check network connection
ping archive.ubuntu.com

# Use different mirror
sudo debootstrap --arch=amd64 focal build/tmp/rootfs http://mirror.example.com/ubuntu
```

#### 3. ISO Boot Fails

**Symptoms:**
- Black screen on boot
- Kernel panic
- GRUB error

**Solution:**
```bash
# Check ISO integrity
sha256sum build/output/lightning-linux-*.iso

# Test in QEMU with verbose output
qemu-system-x86_64 -m 2048 -cdrom build/output/lightning-linux-*.iso -serial stdio -no-reboot

# Check GRUB configuration
cat build/tmp/isofs/boot/grub/grub.cfg
```

#### 4. Desktop Environment Not Starting

**Symptoms:**
- Black screen after login
- No desktop environment
- Xorg errors

**Solution:**
```bash
# Check Xorg logs
cat /var/log/Xorg.0.log

# Check display manager logs
journalctl -u lightdm

# Start desktop manually
startxfce4

# Check installed packages
apt list --installed | grep xfce4
```

#### 5. Network Not Working

**Symptoms:**
- No internet connection
- Network interface not detected

**Solution:**
```bash
# Check network interfaces
ip a

# Check network service
systemctl status NetworkManager

# Restart network
sudo systemctl restart NetworkManager

# Check DHCP
sudo dhclient
```

#### 6. Performance Issues

**Symptoms:**
- Slow system
- High CPU usage
- High memory usage

**Solution:**
```bash
# Check resource usage
htop

# Check memory usage
free -h

# Check CPU usage
top

# Check I/O usage
iotop

# Disable unnecessary services
sudo systemctl disable unnecessary-service
```

### Debugging Commands

```bash
# System information
uname -a
lsb_release -a
cat /etc/os-release

# Hardware information
lspci -k
lsusb
lshw
inxi -Fxz

# Memory information
free -h
cat /proc/meminfo
top
htop

# Disk information
df -h
lsblk
fdisk -l

# Network information
ip a
ip r
ping google.com
nmcli dev show

# Process information
ps aux
pstree

# Kernel logs
dmesg
dmesg | grep -i error
journalctl -b
journalctl -b | grep -i error

# Xorg logs
cat /var/log/Xorg.0.log
cat /var/log/Xorg.0.log | grep -i error

# Package information
dpkg -l | grep package-name
apt policy package-name
apt-cache show package-name
```

---

## 🎓 Advanced Topics

### 1. Custom Kernel Build

```bash
# Install kernel build dependencies
sudo apt install linux-source build-essential libncurses-dev bison flex libssl-dev libelf-dev

# Download kernel source
apt source linux-source

# Extract kernel source
tar xf linux-*.tar.xz
cd linux-*

# Copy custom config
cp ../../configs/kernel/config-x86_64 .config

# Build kernel
make -j$(nproc) deb-pkg

# Install kernel
sudo dpkg -i ../linux-*.deb
```

### 2. Custom Initramfs

```bash
# Create custom initramfs
mkdir -p initramfs/{bin,dev,etc,lib,lib64,mnt,proc,sys,usr}

# Copy essential binaries
cp /bin/busybox initramfs/bin/
cp /bin/sh initramfs/bin/

# Create init script
cat > initramfs/init <<'EOF'
#!/bin/sh

# Mount essential filesystems
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev

# Load necessary kernel modules
modprobe ext4
modprobe xhci-hcd
modprobe ehci-hcd

# Detect and mount root filesystem
for dev in /dev/sd* /dev/nvme*; do
    if blkid $dev | grep -q "TYPE=\"ext4\""; then
        mount -o ro $dev /mnt/root
        break
    fi
done

# Switch to real root
exec switch_root /mnt/root /sbin/init
EOF

chmod +x initramfs/init

# Create initramfs image
find initramfs | cpio -H newc -o | gzip > initramfs.cpio.gz
```

### 3. Custom Live System

```bash
# Create custom live system
mkdir -p live/{rootfs,boot}

# Use debootstrap to create rootfs
sudo debootstrap --arch=amd64 focal live/rootfs http://archive.ubuntu.com/ubuntu

# Chroot and customize
sudo chroot live/rootfs /bin/bash

# Install additional packages
apt update
apt install -y xfce4 lightdm

# Configure system
echo "lightning-linux" > /etc/hostname

# Exit chroot
exit

# Create SquashFS image
mksquashfs live/rootfs live/rootfs.squashfs -comp xz -Xdict-size 100%

# Create ISO
xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames \
  -volid "Lightning Linux" \
  -b boot/grub/i386-pc/eltorito.img \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -o lightning-linux.iso \
  live
```

### 4. PXE Boot Server

```bash
# Install PXE server
sudo apt install dnsmasq tftpd-hpa syslinux nfs-kernel-server

# Configure dnsmasq
cat > /etc/dnsmasq.conf <<'EOF'
interface=eth0
listen-address=192.168.1.100
dhcp-range=192.168.1.101,192.168.1.200,12h
dhcp-boot=pxelinux.0
enable-tftp
tftp-root=/srv/tftp
EOF

# Configure TFTP
mkdir -p /srv/tftp/pxelinux.cfg
cp /usr/lib/syslinux/modules/bios/{ldlinux.c32,libcom32.c32,libutil.c32,vesamenu.c32} /srv/tftp/
cp /usr/lib/syslinux/pxelinux.0 /srv/tftp/

# Create PXE config
cat > /srv/tftp/pxelinux.cfg/default <<'EOF'
DEFAULT lightning-linux
PROMPT 0
TIMEOUT 50

LABEL lightning-linux
  KERNEL lightning-linux/vmlinuz
  APPEND initrd=lightning-linux/initrd.img root=/dev/nfs ip=dhcp
  INITRD lightning-linux/initrd.img
EOF

# Copy kernel and initramfs
cp build/output/lightning-linux-*.iso /srv/tftp/

# Restart services
sudo systemctl restart dnsmasq
sudo systemctl restart tftpd-hpa
```

### 5. Docker Image Build

```bash
# Create Dockerfile
cat > Dockerfile <<'EOF'
FROM ubuntu:22.04

# Copy Lightning Linux files
COPY build/output/lightning-linux-*.iso /tmp/

# Install dependencies
RUN apt update && apt install -y \
    qemu-user-static \
    binfmt-support

# Extract ISO
RUN mkdir -p /mnt/iso
RUN mount -o loop /tmp/lightning-linux-*.iso /mnt/iso
RUN cp -r /mnt/iso/* /lightning-linux/
RUN umount /mnt/iso

# Set up entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
EOF

# Create entrypoint script
cat > entrypoint.sh <<'EOF'
#!/bin/bash

# Start Lightning Linux in container
exec /lightning-linux/start.sh
EOF

chmod +x entrypoint.sh

# Build Docker image
docker build -t lightning-linux:0.1 .

# Run Docker container
docker run -it --rm lightning-linux:0.1
```

---

## 📚 Additional Resources

### Documentation
- [Official Documentation](https://github.com/jainh2095-sudo/Linux/docs)
- [System Architecture](docs/architecture/SYSTEM_ARCHITECTURE.md)
- [Performance Optimizations](docs/architecture/PERFORMANCE_OPTIMIZATIONS.md)
- [Compatibility Guide](docs/architecture/COMPATIBILITY_GUIDE.md)

### Community
- [GitHub Repository](https://github.com/jainh2095-sudo/Linux)
- [GitHub Issues](https://github.com/jainh2095-sudo/Linux/issues)
- [GitHub Discussions](https://github.com/jainh2095-sudo/Linux/discussions)

### Related Projects
- [Ubuntu](https://ubuntu.com/)
- [Kali Linux](https://www.kali.org/)
- [Linux Mint](https://linuxmint.com/)
- [Alpine Linux](https://alpinelinux.org/)
- [Arch Linux](https://archlinux.org/)

---

## 🎉 Conclusion

You have now successfully built Lightning Linux from source! This guide covered:

1. Setting up the build environment
2. Configuring the build
3. Building the ISO
4. Customizing the build
5. Testing the build
6. Troubleshooting common issues
7. Advanced topics

For more information, refer to the official documentation and community resources.

---

*Happy building! 🚀*

*Built with ❤️ for the Linux community*
