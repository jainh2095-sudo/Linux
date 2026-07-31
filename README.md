# HarshitOS / Lightning Linux

> **A lightweight, multi-purpose Linux distro combining the best of Ubuntu, Kali, and Mint—optimized for 2GB RAM.**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Status: Development](https://img.shields.io/badge/Status-Development-yellow.svg)]()
[![Target: 2GB RAM](https://img.shields.io/badge/Target-2GB%20RAM-green.svg)]()
[![Storage: ≤10GB](https://img.shields.io/badge/Storage-≤10GB-orange.svg)]()

---

## 🎯 Core Goals

### 1. **Lightweight**
- **RAM Usage**: ≤2GB (idle: ~500MB, full load: ~2GB)
- **Storage**: ≤10GB (compressed)
- **Boot Time**: <10 seconds

### 2. **Multi-Purpose**
- **General Use**: Pre-installed with tools for daily tasks (office, media, development)
- **Security**: Include Kali-like tools (nmap, metasploit, wireshark)
- **User-Friendly**: Mint-like UI (Cinnamon/Xfce desktop, easy package management)

### 3. **Compatibility**
- Runs on old hardware (e.g., i5 6th gen + 4GB RAM)
- Supports Windows dual-boot/VM (VirtualBox, WSL2)
- Cross-platform packages (Flatpak/Snap for Windows compatibility)

### 4. **Performance**
- Use lightweight alternatives (Openbox instead of GNOME, musl libc instead of glibc)
- ZRAM/ZSWAP for memory compression
- Systemd optimizations (disable unnecessary services)

---

## 📋 Project Structure

```
harshitOS/
├── docs/
│   ├── architecture/          # System architecture documents
│   ├── development/           # Development guidelines
│   └── user-guide/            # User documentation
├── scripts/
│   ├── build/                 # Build scripts
│   ├── config/                # Configuration scripts
│   └── packages/              # Package management scripts
├── configs/
│   ├── system/                # System configuration files
│   ├── desktop/               # Desktop environment configs
│   └── services/              # Service configuration files
├── packages/
│   ├── base/                  # Base system packages
│   ├── security/              # Security tools
│   ├── desktop/               # Desktop environment
│   ├── development/           # Development tools
│   └── media/                 # Media applications
└── README.md
```

---

## 🚀 Quick Start

### Prerequisites
- Linux build environment (Ubuntu 22.04 LTS recommended)
- 50GB free disk space
- 8GB RAM (16GB recommended)
- Root/sudo access

### Build from Source

```bash
# Clone the repository
git clone https://github.com/jainh2095-sudo/Linux.git harshitOS
cd harshitOS

# Install build dependencies
sudo apt update
sudo ./scripts/build/install-dependencies.sh

# Configure the build
./scripts/config/configure-build.sh

# Build the ISO
./scripts/build/build-iso.sh

# Output will be in build/output/
```

---

## 📦 Package Lists

### Base System (≤500MB RAM idle)
- **Init System**: OpenRC (lightweight alternative to systemd)
- **LibC**: musl libc (lightweight alternative to glibc)
- **Kernel**: Linux LTS (6.1.x) with custom optimizations
- **Core Utilities**: BusyBox (lightweight core utilities)

### Desktop Environment (≤1GB RAM with apps)
- **Primary**: Xfce4 (lightweight, customizable)
- **Alternative**: Openbox (ultra-lightweight)
- **Window Manager**: Picom (compositor)
- **Display Manager**: LightDM (lightweight)

### Security Tools
- **Network**: nmap, wireshark, tcpdump
- **Penetration Testing**: metasploit-framework, sqlmap
- **Forensics**: testdisk, photorec
- **Monitoring**: htop, netdata

### Development Tools
- **Editors**: VS Code (via Flatpak), Geany, Nano
- **Compilers**: GCC, Clang, Python, Node.js
- **Version Control**: Git, Mercurial
- **Containers**: Podman (lightweight Docker alternative)

### Media Applications
- **Audio**: Audacious, PulseAudio
- **Video**: MPV, VLC (lightweight builds)
- **Graphics**: GIMP (optional), feh, scrot
- **Office**: LibreOffice (lightweight), AbiWord, Gnumeric

---

## ⚙️ System Optimizations

### Memory Management
- **ZRAM**: Enabled by default (50% of RAM)
- **ZSWAP**: Enabled for swap compression
- **OOM Killer**: Tuned for desktop use

### Performance Tweaks
- **Kernel Parameters**: Optimized for low-memory systems
- **Services**: Only essential services enabled
- **Preload**: Preload frequently used applications
- **I/O Scheduler**: BFQ for better responsiveness

### Storage Optimization
- **Compression**: SquashFS for read-only filesystem
- **Package Management**: APT with compression
- **Cleanup**: Automatic cache cleanup

---

## 🎨 Desktop Customization

### Themes
- **GTK Theme**: Matcha (lightweight, modern)
- **Icons**: Papirus
- **Cursor**: Bibata
- **Fonts**: Noto Sans (compressed)

### Default Applications
- **File Manager**: Thunar (Xfce) / PCManFM (LXDE)
- **Terminal**: Xfce4-terminal / Sakura
- **Browser**: Firefox (optimized) / Falkon
- **Email**: Claws Mail (lightweight)

---

## 🔧 Configuration Files

### System Configuration
- `/etc/lightning-linux-release` - Distribution identification
- `/etc/default/grub` - Bootloader configuration
- `/etc/fstab` - Filesystem mount points
- `/etc/sysctl.conf` - Kernel parameters

### Desktop Configuration
- `~/.config/xfce4/` - Xfce4 settings
- `~/.config/openbox/` - Openbox configuration
- `~/.config/picom/` - Picom compositor settings

---

## 📊 Benchmarks

### Target Performance Metrics
| Metric | Target | Current |
|--------|--------|---------|
| Boot Time | <10s | TBD |
| RAM Usage (Idle) | ≤500MB | TBD |
| RAM Usage (Full Load) | ≤2GB | TBD |
| Storage (Compressed) | ≤10GB | TBD |
| Package Count | ~1500 | TBD |

### Hardware Compatibility
| Hardware | Status |
|----------|--------|
| i5 6th Gen | ✅ Supported |
| 4GB RAM | ✅ Supported |
| VirtualBox | ✅ Supported |
| WSL2 | 🟡 Experimental |
| Dual Boot | ✅ Supported |

---

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Shell scripts: Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Configuration files: Consistent indentation (2 spaces)
- Comments: Explain why, not what

### Testing
- **Unit Tests**: Bash scripts with assertions
- **Integration Tests**: Full system builds
- **Performance Tests**: Benchmark scripts

---

## 📜 License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Ubuntu**: Base system and package management
- **Kali Linux**: Security tools and penetration testing
- **Linux Mint**: User-friendly desktop experience
- **Arch Linux**: Lightweight philosophy and optimization
- **Alpine Linux**: musl libc and lightweight approach

---

## 📞 Contact

- **Maintainer**: Harshit Jain (jainh2095-sudo)
- **GitHub**: [jainh2095-sudo/Linux](https://github.com/jainh2095-sudo/Linux)
- **Issues**: [GitHub Issues](https://github.com/jainh2095-sudo/Linux/issues)
- **Discussions**: [GitHub Discussions](https://github.com/jainh2095-sudo/Linux/discussions)

---

## 🔮 Roadmap

### Version 0.1 (Alpha)
- [ ] Base system with musl libc
- [ ] OpenRC init system
- [ ] Xfce4 desktop environment
- [ ] Basic package management

### Version 0.2 (Beta)
- [ ] Security tools integration
- [ ] Performance optimizations
- [ ] Hardware compatibility testing
- [ ] User documentation

### Version 0.3 (RC)
- [ ] Full feature set
- [ ] Comprehensive testing
- [ ] Performance benchmarks
- [ ] Release candidates

### Version 1.0 (Stable)
- [ ] Final optimizations
- [ ] Complete documentation
- [ ] Community feedback integration
- [ ] Official release

---

*Built with ❤️ for the Linux community*
