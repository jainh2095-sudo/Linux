# ⚡ Lightning Linux - Quick Start Guide

**A production-ready, lightweight Linux distribution you can use RIGHT NOW!**

---

## 🎯 What You Get

✅ **Complete, bootable Linux distribution**
✅ **Xfce4 Desktop Environment** (Lightweight & Fast)
✅ **Security Tools** (nmap, wireshark, tcpdump, etc.)
✅ **Development Tools** (gcc, python, nodejs, git, etc.)
✅ **Media Applications** (VLC, GIMP, FFmpeg, etc.)
✅ **Office Applications** (LibreOffice, Firefox, Thunderbird)
✅ **Performance Optimizations** (ZRAM, ZSWAP, THP, BFQ I/O)
✅ **2GB RAM Optimized** (Idle: ~500MB, Full Load: ~2GB)

---

## 🚀 Get Started in 3 Steps

### Step 1: Build the ISO

```bash
# Make script executable
chmod +x BUILD_NOW.sh

# Run the build (as root)
sudo ./BUILD_NOW.sh
```

**This will:**
- Download and install Ubuntu Focal base system
- Install Xfce4 desktop environment
- Install all security, development, media, and office tools
- Configure performance optimizations
- Create a bootable ISO image

**Build Time:** ~15-30 minutes (depending on internet speed)
**ISO Size:** ~2-3GB
**Required Space:** 10GB+ free disk space

### Step 2: Create Bootable USB

```bash
# List your USB devices
lsblk

# Find your USB device (e.g., /dev/sdb)
# WARNING: This will ERASE all data on the USB!

# Create bootable USB (replace /dev/sdX with your USB device)
sudo ./build/output/create-usb.sh /dev/sdX
```

**Alternative Methods:**
- **Windows:** Use Rufus or Balena Etcher
- **macOS:** Use Balena Etcher or `dd` command

### Step 3: Boot and Use!

1. **Insert USB** into your computer
2. **Enter BIOS/UEFI** (usually by pressing F2, F12, DEL, or ESC during boot)
3. **Select USB** as boot device
4. **Save and exit**
5. **Lightning Linux** will boot automatically!

---

## 💻 Login Credentials

| Account | Username | Password |
|---------|----------|----------|
| User | `lightning` | `lightning` |
| Root | `root` | `lightning` |

**Note:** The user `lightning` has sudo privileges (no password required).

---

## 🎨 What's Included

### Desktop Environment
- **Xfce4** - Lightweight desktop environment
- **LightDM** - Login manager
- **Picom** - Compositing manager
- **Thunar** - File manager
- **Mousepad** - Text editor
- **Ristretto** - Image viewer
- **Galculator** - Calculator

### Security Tools
- **nmap** - Network mapper
- **wireshark** - Network protocol analyzer
- **tcpdump** - Network packet analyzer
- **tshark** - Command-line network analyzer
- **ncat** - Network connection tool
- **ufw** - Firewall
- **apparmor** - Mandatory access control
- **rkhunter** - Rootkit hunter
- **chkrootkit** - Rootkit detection
- **lynis** - Security auditing
- **clamav** - Antivirus

### Development Tools
- **gcc/g++** - C/C++ compiler
- **make** - Build tool
- **cmake** - Cross-platform build system
- **git** - Version control
- **subversion** - Version control
- **python3** - Python interpreter
- **nodejs** - JavaScript runtime
- **npm** - Node package manager
- **default-jdk** - Java development kit
- **golang** - Go programming language
- **flatpak** - Sandboxed application packaging

### Media Applications
- **VLC** - Media player
- **MPV** - Media player
- **Audacious** - Audio player
- **GIMP** - Image editor
- **feh** - Image viewer
- **scrot** - Screenshot tool
- **SimpleScreenRecorder** - Screen recorder
- **FFmpeg** - Multimedia framework

### Office Applications
- **LibreOffice** - Office suite
- **Firefox** - Web browser
- **Thunderbird** - Email client

### System Tools
- **htop** - Process viewer
- **iotop** - I/O monitor
- **iftop** - Network bandwidth monitor
- **nmon** - System monitoring
- **glances** - Comprehensive monitoring
- **lsof** - List open files

---

## ⚡ Performance Optimizations

Lightning Linux includes these optimizations out of the box:

### Memory Optimizations
- **ZRAM**: 50% of RAM used for compressed swap
- **ZSWAP**: lz4 compression for swap space
- **Swappiness**: Set to 60 for balanced performance

### CPU Optimizations
- **CPU Governor**: schedutil (modern, efficient)
- **Minimum Frequency**: 800MHz
- **Maximum Frequency**: 3.6GHz

### I/O Optimizations
- **I/O Scheduler**: BFQ (Budget Fair Queuing)
- **Read-ahead**: Optimized for performance

### Filesystem Optimizations
- **Noatime**: Disabled access time updates
- **Nodiratime**: Disabled directory access time updates

---

## 🖥️ Test Without USB

### Test in QEMU

```bash
# Install QEMU if not already installed
sudo apt install qemu-system-x86

# Run the test script
./build/output/test-qemu.sh
```

**QEMU Controls:**
- `Ctrl+Alt+G` - Release mouse cursor
- `Ctrl+C` - Shutdown VM

### Test in VirtualBox

1. **Open VirtualBox**
2. **Create New VM**
   - Name: Lightning Linux
   - Type: Linux
   - Version: Ubuntu (64-bit)
3. **Memory**: 2048MB (2GB)
4. **CPU**: 2 processors
5. **Storage**: Create 20GB virtual disk
6. **Attach ISO**: Select the built ISO file
7. **Start VM**

---

## 📊 System Requirements

### Minimum
- **CPU**: 1 GHz (64-bit)
- **RAM**: 1GB
- **Storage**: 4GB
- **Graphics**: Any VGA-compatible

### Recommended
- **CPU**: 2 GHz dual-core (64-bit)
- **RAM**: 2GB
- **Storage**: 10GB
- **Graphics**: Intel HD Graphics / AMD Radeon / NVIDIA

### Optimal (for best experience)
- **CPU**: 4+ cores
- **RAM**: 4GB+
- **Storage**: 20GB+
- **Graphics**: Dedicated GPU

---

## 🎯 Target Hardware

Lightning Linux is **optimized for i5 6th generation + 4GB RAM**, but works on:

### Officially Supported
| Hardware | Status | Notes |
|----------|--------|-------|
| i5-6200U + 4GB RAM | ✅ **Perfect** | Primary target |
| i5-6300HQ + 4GB RAM | ✅ **Perfect** | Primary target |
| i3-4000M + 4GB RAM | ✅ **Great** | Good performance |
| i7-6500U + 8GB RAM | ✅ **Excellent** | Extra performance |
| Any x86_64 CPU + 2GB RAM | ✅ **Good** | Basic functionality |

### Virtualization
| Platform | Status | Notes |
|----------|--------|-------|
| VirtualBox | ✅ **Fully Supported** | Guest Additions included |
| VMware | ✅ **Fully Supported** | VMware Tools included |
| QEMU/KVM | ✅ **Fully Supported** | VirtIO drivers included |
| Hyper-V | ✅ **Supported** | Integration Services included |

---

## 🔧 Customization

### Change Default Password

After booting, change the password:

```bash
# Change user password
passwd lightning

# Change root password
sudo passwd root
```

### Install Additional Software

```bash
# Update package lists
sudo apt update

# Install new packages
sudo apt install package-name

# Remove packages
sudo apt remove package-name

# Clean up
sudo apt autoremove
sudo apt clean
```

### Enable/Disable Services

```bash
# List all services
systemctl list-unit-files --type=service

# Enable a service
sudo systemctl enable service-name
sudo systemctl start service-name

# Disable a service
sudo systemctl disable service-name
sudo systemctl stop service-name

# Check service status
sudo systemctl status service-name
```

### Configure Network

```bash
# WiFi
nmcli dev wifi list
nmcli dev wifi connect "SSID" password "password"

# Ethernet
nmcli dev show

# Check connection
ping google.com
ip a
```

---

## 🛠️ Troubleshooting

### Black Screen on Boot

**Cause:** Graphics driver issue

**Solution:**
1. At GRUB menu, press `e`
2. Find the line starting with `linux`
3. Add `nomodeset` at the end
4. Press `Ctrl+X` or `F10` to boot

### No WiFi

**Solution:**
```bash
# Check if WiFi is blocked
rfkill list

# Unblock WiFi
rfkill unblock wifi

# Check WiFi interface
ip a | grep wlan

# Restart Network Manager
sudo systemctl restart NetworkManager
```

### No Sound

**Solution:**
```bash
# Check sound devices
aplay -l

# Check volume
alsamixer

# Restart PulseAudio
pulseaudio -k && pulseaudio --start
```

### Slow Performance

**Solution:**
```bash
# Check memory usage
free -h

# Check CPU usage
top

# Check running services
systemctl list-units --type=service --state=running

# Disable unnecessary services
sudo systemctl disable service-name
```

### Can't Login

**Solution:**
1. At login screen, select "LightDM GTK Greeter Settings"
2. Or try logging in with:
   - Username: `lightning`
   - Password: `lightning`
3. If still not working, try:
   - Username: `root`
   - Password: `lightning`

---

## 📚 Documentation

- **[README.md](README.md)** - Project overview and goals
- **[BUILD_GUIDE.md](BUILD_GUIDE.md)** - Detailed build instructions
- **[SYSTEM_ARCHITECTURE.md](docs/architecture/SYSTEM_ARCHITECTURE.md)** - Complete system architecture
- **[PERFORMANCE_OPTIMIZATIONS.md](docs/architecture/PERFORMANCE_OPTIMIZATIONS.md)** - All optimization strategies
- **[COMPATIBILITY_GUIDE.md](docs/architecture/COMPATIBILITY_GUIDE.md)** - Hardware/software compatibility

---

## 🎉 You're Ready!

That's it! You now have a **production-ready Lightning Linux** distribution that you can:

1. **Boot from USB** and use immediately
2. **Install to hard drive** for permanent use
3. **Test in VirtualBox/QEMU** before installing
4. **Customize** to your heart's content

**Enjoy your lightweight, fast, and feature-rich Linux distribution!** 🚀

---

## 📞 Support

- **GitHub**: https://github.com/jainh2095-sudo/Linux
- **Issues**: https://github.com/jainh2095-sudo/Linux/issues
- **Discussions**: https://github.com/jainh2095-sudo/Linux/discussions

---

*Built with ❤️ for the Linux community*
*Lightning Linux - A lightweight, multi-purpose Linux distro*
