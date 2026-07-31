# Performance Optimizations - HarshitOS / Lightning Linux

## 🎯 Performance Targets

| Metric | Target | Current Status |
|--------|--------|----------------|
| **Boot Time** | <10 seconds | ⚠️ TBD |
| **RAM Usage (Idle)** | ≤500MB | ⚠️ TBD |
| **RAM Usage (Full Load)** | ≤2GB | ⚠️ TBD |
| **Storage (Compressed)** | ≤10GB | ⚠️ TBD |
| **CPU Usage (Idle)** | ≤5% | ⚠️ TBD |
| **Disk I/O (Idle)** | ≤1MB/s | ⚠️ TBD |

---

## 📊 Optimization Categories

### 1. **Memory Optimization** (Primary Focus)
### 2. **CPU Optimization**
### 3. **Storage Optimization**
### 4. **I/O Optimization**
### 5. **Network Optimization**
### 6. **Graphics Optimization**
### 7. **Boot Optimization**

---

## 1. Memory Optimization

### 🎯 Goal: Reduce RAM usage to ≤500MB idle, ≤2GB full load

### 1.1 ZRAM Configuration

**Purpose**: Compress RAM contents to effectively increase available memory

**Implementation**:

```bash
# /usr/local/bin/zram-config.sh
#!/bin/bash

# Calculate optimal ZRAM size based on total RAM
TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')

# Use 50% of RAM for ZRAM (adjustable)
ZRAM_SIZE=$((TOTAL_MEM * 1024 / 2))

# For systems with ≤2GB RAM, use 100% of RAM
if [ "$TOTAL_MEM" -le 2097152 ]; then
    ZRAM_SIZE=$((TOTAL_MEM * 1024))
fi

# Load zram module with multiple devices
MODPROBE_OPTIONS=""
if [ "$TOTAL_MEM" -ge 8388608 ]; then  # 8GB+
    NUM_DEVICES=4
elif [ "$TOTAL_MEM" -ge 4194304 ]; then  # 4GB+
    NUM_DEVICES=2
else
    NUM_DEVICES=1
fi

modprobe zram num_devices=$NUM_DEVICES $MODPROBE_OPTIONS

# Configure each zram device
for i in $(seq 0 $((NUM_DEVICES - 1))); do
    DEVICE="/dev/zram$i"
    
    # Use lz4 compression (best balance of speed and compression)
    echo lz4 > /sys/block/zram$i/comp_algorithm
    
    # Set device size
    echo $((ZRAM_SIZE / NUM_DEVICES)) > /sys/block/zram$i/disksize
    
    # Create swap on zram device
    mkswap $DEVICE
    
    # Enable swap with priority (higher priority for zram)
    swapon $DEVICE -p 100
    
    # Configure writeback (if kernel supports it)
    if [ -f /sys/block/zram$i/writeback ]; then
        echo 1 > /sys/block/zram$i/writeback
    fi
done

# Tune swappiness
sysctl vm.swappiness=100

# Tune watermark scale factor for better memory reclaim
sysctl vm.watermark_scale_factor=200
```

**Systemd Service**:

```ini
# /etc/systemd/system/zram-config.service
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
```

**OpenRC Init Script**:

```bash
# /etc/init.d/zram-config
#!/sbin/openrc-run

name="zram-config"
description="Configure ZRAM swap devices"
start_cmd="/usr/local/bin/zram-config.sh"

supervise_daemon_args="--stdout /var/log/zram-config.log --stderr /var/log/zram-config.err"
```

### 1.2 ZSWAP Configuration

**Purpose**: Compress swap space to reduce disk I/O

**Kernel Parameters**:

```bash
# /etc/sysctl.d/99-zswap.conf
# Enable ZSWAP
vm.zswap.enabled=1

# Use lz4 compression (fastest with good compression)
vm.zswap.compressor=lz4

# Maximum percentage of RAM to use for ZSWAP pool
vm.zswap.max_pool_percent=20

# Accept throttled writebacks (prevents stalls)
vm.zswap.accept_throttled_writebacks=1

# Same-filled pages handling
vm.zswap.same_filled_pages_enabled=1
```

**Alternative Compressors**:
- `lz4`: Fastest, good compression (recommended)
- `lz4hc`: Better compression, slower
- `lzo`: Balanced
- `zstd`: Best compression, slower

### 1.3 OOM Killer Tuning

**Purpose**: Prevent system crashes when memory is exhausted

**Configuration**:

```bash
# /etc/sysctl.d/99-oom.conf
# Overcommit memory settings
vm.overcommit_memory=1  # Heuristic overcommit
vm.overcommit_ratio=80  # 80% of RAM + swap

# OOM killer settings
vm.oom_kill_allocating_task=1  # Kill the task that triggered OOM
vm.oom_dump_tasks=1  # Dump task information

# Memory pressure stall information
vm.pressure_stall_info=1
```

**OOM Score Adjustments**:

```bash
# /etc/systemd/system/oom-score-adjust.service
[Unit]
Description=Adjust OOM scores for critical processes
After=sysinit.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/oom-score-adjust.sh

[Install]
WantedBy=multi-user.target
```

```bash
# /usr/local/bin/oom-score-adjust.sh
#!/bin/bash

# Protect critical system processes
for process in dbus systemd-logind NetworkManager lightdm; do
    for pid in $(pgrep $process); do
        echo -1000 > /proc/$pid/oom_score_adj 2>/dev/null
    done
done

# Protect desktop environment
for process in xfce4-session xfwm4 xfce4-panel; do
    for pid in $(pgrep $process); do
        echo -500 > /proc/$pid/oom_score_adj 2>/dev/null
    done
done

# Deprioritize non-critical applications
for process in firefox chromium vlc; do
    for pid in $(pgrep $process); do
        echo 500 > /proc/$pid/oom_score_adj 2>/dev/null
    done
done
```

### 1.4 Transparent HugePages (THP)

**Purpose**: Reduce TLB misses and improve performance for large memory accesses

**Configuration**:

```bash
# /etc/sysctl.d/99-thp.conf
# Enable THP
vm.thp_enabled=1

# Enable THP defragmentation
vm.thp_defrag_enabled=1

# Enable THP for anonymous pages
vm.thp_anonymous_only=0

# THP allocation behavior
vm.thp_khugepaged_enabled=1

# THP defrag settings
vm.thp_defrag_all=0
vm.thp_defrag_max_defer=16
vm.thp_defrag_max_scan=1000
```

**Kernel Boot Parameters**:

```
transparent_hugepage=always
```

**Note**: THP can increase memory usage. Monitor with:
```bash
cat /proc/meminfo | grep -i huge
```

### 1.5 Memory Cgroups (for systemd)

**Purpose**: Limit memory usage for specific services

**Configuration**:

```bash
# /etc/systemd/system.conf
DefaultMemoryLow=512M
DefaultMemoryMax=2G
DefaultMemoryAccounting=yes
DefaultMemoryOOMKillPolicy=continue
```

**Service-specific limits**:

```ini
# /etc/systemd/system/firefox.service.d/override.conf
[Service]
MemoryMax=1G
MemoryHigh=800M
MemorySwapMax=2G
```

### 1.6 EarlyOOM (Early Out-of-Memory Killer)

**Purpose**: Monitor memory and kill processes before OOM occurs

**Installation**:

```bash
# Install EarlyOOM
sudo apt install earlyoom

# Enable EarlyOOM
sudo systemctl enable earlyoom
sudo systemctl start earlyoom
```

**Configuration**:

```bash
# /etc/default/earlyoom
# Memory threshold (percentage)
EARLYOOM_ARGS="--memory 90 --swap 80"
```

### 1.7 ZRAM Writeback (Advanced)

**Purpose**: Write compressed pages back to storage when memory pressure is high

**Kernel Parameters**:

```
zram.writeback=1
zram.writeback_threshold=2G
```

**Note**: Requires kernel 5.14+ with ZRAM writeback support

### 1.8 Memory Pressure Notifications

**Purpose**: Alert users when memory is running low

**Configuration**:

```bash
# /usr/local/bin/memory-monitor.sh
#!/bin/bash

# Check memory usage every 30 seconds
while true; do
    MEM_USAGE=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
    SWAP_USAGE=$(free | awk '/Swap:/ {printf "%.0f", $3/$2 * 100}')
    
    if [ "$MEM_USAGE" -ge 90 ] || [ "$SWAP_USAGE" -ge 70 ]; then
        notify-send "⚠️ Memory Warning" "Memory usage: ${MEM_USAGE}%, Swap: ${SWAP_USAGE}%"
    fi
    
    sleep 30
done
```

---

## 2. CPU Optimization

### 🎯 Goal: Maximize CPU performance while minimizing power consumption

### 2.1 CPU Governor

**Purpose**: Control CPU frequency scaling

**Available Governors**:
- `performance`: Always run at maximum frequency (best performance, worst power)
- `powersave`: Always run at minimum frequency (worst performance, best power)
- `userspace`: Manual frequency control
- `ondemand`: Scale up when needed, scale down when idle (balanced)
- `conservative`: Scale up/down more gradually
- `schedutil`: Modern governor, integrated with CPU scheduler (recommended)
- `interactive`: Optimized for latency

**Configuration**:

```bash
# /etc/default/cpufrequtils
GOVERNOR="schedutil"
MIN_SPEED="800000"
MAX_SPEED="3600000"
```

**Kernel Boot Parameters**:

```
cpufreq.default_governor=schedutil
```

**Dynamic Governor Switching**:

```bash
# /usr/local/bin/cpu-governor.sh
#!/bin/bash

# Set governor based on power source
if [ -f /sys/class/power_supply/AC/online ]; then
    AC_ONLINE=$(cat /sys/class/power_supply/AC/online)
    if [ "$AC_ONLINE" = "1" ]; then
        # On AC power - use performance
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            echo schedutil > $cpu
        done
    else
        # On battery - use powersave
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            echo powersave > $cpu
        done
    fi
fi
```

### 2.2 CPU Scheduler

**Purpose**: Control how CPU time is allocated to processes

**Available Schedulers**:
- `CFS` (Completely Fair Scheduler): Default, good for general use
- `BFQ` (Budget Fair Queuing): Good for desktops, reduces latency
- `MUQSS` (Multiple Queue Skiplist Scheduler): Good for desktops and servers
- `BMQ` (BitMap Queue Scheduler): Good for high-core-count systems
- `PF` (Process Fair Scheduler): Alternative fair scheduler

**Recommended**: MUQSS for desktops, BFQ for general use

**Installation (MUQSS)**:

```bash
# Install MUQSS kernel
sudo apt install linux-image-muqss

# Or build custom kernel with MUQSS
```

**Kernel Boot Parameters**:

```
# For MUQSS
scheduler=muqss

# For BFQ
scheduler=bfq
```

**CFS Tuning**:

```bash
# /etc/sysctl.d/99-cfs.conf
# CFS tunables
kernel.sched_latency_ns=6000000
kernel.sched_min_granularity_ns=750000
kernel.sched_wakeup_granularity_ns=1000000
kernel.sched_child_runs_first=0
kernel.sched_features=4095
```

### 2.3 CPU Frequency Limits

**Purpose**: Limit CPU frequency to reduce power consumption

**Configuration**:

```bash
# /etc/default/cpufrequtils
GOVERNOR="schedutil"
MIN_SPEED="800000"  # 800 MHz minimum
MAX_SPEED="2400000"  # 2.4 GHz maximum (adjust based on CPU)
```

**Turbo Boost Control**:

```bash
# Disable Turbo Boost (for power saving)
echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo

# Enable Turbo Boost (for performance)
echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo
```

**Make persistent**:

```bash
# /etc/rc.local (before exit 0)
# Disable Turbo Boost on battery
echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
```

### 2.4 CPU Microcode

**Purpose**: Update CPU microcode for better performance and security

**Installation**:

```bash
# Install microcode packages
sudo apt install intel-microcode amd64-microcode

# Update initramfs
sudo update-initramfs -u
```

### 2.5 CPU Isolation

**Purpose**: Reserve CPU cores for specific tasks

**Configuration**:

```bash
# Isolate CPU cores 0 and 1 for real-time tasks
# /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="... isolcpus=0,1"

# Update GRUB
sudo update-grub
```

**Cgroup CPU Pinning**:

```bash
# Create cgroup for performance-critical applications
sudo cgcreate -g cpu:/performance

# Set CPU affinity
sudo cgset -r cpu.cpus=0,1 performance

# Run application in isolated cgroup
cgexec -g cpu:performance application
```

### 2.6 Thermal Management

**Purpose**: Prevent CPU throttling due to overheating

**Configuration**:

```bash
# /etc/thermald/thermald.conf
# Enable thermal daemon
[General]
Enable=1

# Thermal zones
[ThermalZone0]
Type=acpitz
PollingInterval=10
TripPoint_0_temp=55
TripPoint_0_type=passive
TripPoint_1_temp=65
TripPoint_1_type=active
```

**Installation**:

```bash
# Install thermald
sudo apt install thermald

# Enable thermald
sudo systemctl enable thermald
sudo systemctl start thermald
```

### 2.7 CPU Power States (Intel)

**Purpose**: Control Intel CPU power states

**Configuration**:

```bash
# /etc/default/intel-pstate
# Set P-state driver
INTEL_PSTATE=active

# Set energy performance preference
ENERGY_PERF_PREFERENCE=balance_performance
```

**Available Preferences**:
- `performance`: Maximum performance
- `balance_performance`: Balanced with performance bias
- `balance_power`: Balanced with power bias
- `power`: Maximum power saving

**Manual Control**:

```bash
# Set energy performance preference
echo balance_performance > /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference
```

### 2.8 CPU C-States

**Purpose**: Control CPU idle states for power saving

**Configuration**:

```bash
# /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="... intel_idle.max_cstate=2"

# Update GRUB
sudo update-grub
```

**C-State Limits**:
- `max_cstate=0`: No C-states (always active)
- `max_cstate=1`: Only C0 (active) and C1 (halt)
- `max_cstate=2`: Up to C2 (stop-grant)
- `max_cstate=3`: Up to C3 (deep sleep)
- `max_cstate=4`: Up to C4 (deeper sleep)

**Note**: Higher C-states save more power but increase wakeup latency

---

## 3. Storage Optimization

### 🎯 Goal: Reduce storage usage to ≤10GB (compressed)

### 3.1 Filesystem Selection

**Comparison**:

| Filesystem | Pros | Cons | Recommended For |
|------------|------|------|-----------------|
| ext4 | Mature, reliable, good performance | Not the most feature-rich | Default |
| XFS | High performance, scalable | Less flexible for shrinking | Servers |
| Btrfs | Snapshots, compression, subvolumes | Higher overhead | Advanced users |
| F2FS | Optimized for SSDs | Less mature | SSDs |
| ZFS | Advanced features, compression | High memory usage | Servers |

**Recommended**: ext4 for most users, Btrfs for advanced features

### 3.2 ext4 Optimization

**Mount Options**:

```bash
# /etc/fstab
UUID=xxxx-xxxx / ext4 noatime,nodiratime,errors=remount-ro,data=writeback,commit=60 0 1
```

**Option Explanations**:
- `noatime`: Don't update access time (reduces writes)
- `nodiratime`: Don't update directory access time
- `errors=remount-ro`: Remount read-only on errors
- `data=writeback`: Better performance (riskier)
- `commit=60`: Commit changes every 60 seconds (reduces writes)

**Tuning**:

```bash
# /etc/sysctl.d/99-ext4.conf
# Reduce ext4 journal commits
vm.ext4.journal_commit_interval=60

# Reduce ext4 background writes
vm.ext4.background_writes=0
```

### 3.3 Btrfs Optimization

**Mount Options**:

```bash
# /etc/fstab
UUID=xxxx-xxxx / btrfs compress=zstd:1,noatime,nodiratime,space_cache=v2,subvolrootid=256 0 1
```

**Compression**:
- `zstd:1`: Fastest compression level
- `zstd:3`: Good balance
- `zstd:9`: Best compression (slowest)
- `lzo`: Fast but less compression
- `zlib`: Good compression but slower

**Subvolume Structure**:

```bash
# Create subvolumes
sudo btrfs subvolume create /@
sudo btrfs subvolume create /@/home
sudo btrfs subvolume create /@/var
sudo btrfs subvolume create /@/snapshots

# Set default subvolume
sudo btrfs subvolume set-default 256 /
```

**Snapshot Management**:

```bash
# Create snapshot
sudo btrfs subvolume snapshot / /snapshots/$(date +%Y-%m-%d)

# List snapshots
sudo btrfs subvolume list /snapshots

# Delete old snapshots
sudo btrfs subvolume delete /snapshots/old-snapshot
```

### 3.4 SquashFS for Read-Only Filesystem

**Purpose**: Compress the root filesystem to save space

**Build Command**:

```bash
# Create SquashFS image with maximum compression
mksquashfs /source /output/squashfs-root.xz \
  -comp xz \
  -Xdict-size 100% \
  -b 256K \
  -Xbcj x86 \
  -noappend \
  -no-duplicates
```

**Compression Options**:
- `gzip`: Fast, good compression
- `lzo`: Very fast, less compression
- `lz4`: Fast, good compression
- `xz`: Slow, best compression (recommended)
- `zstd`: Fast, good compression

**Mount Options**:

```bash
# Mount SquashFS image
mount -t squashfs -o loop,ro /path/to/squashfs-root.xz /mnt
```

### 3.5 OverlayFS for Persistence

**Purpose**: Allow changes to read-only filesystem

**Configuration**:

```bash
# Create overlay directories
mkdir -p /cow /cow-work

# Mount overlay
mount -t overlay overlay \
  -o lowerdir=/,upperdir=/cow,workdir=/cow-work \
  /mnt/overlay
```

**Persistent Overlay**:

```bash
# /etc/fstab
overlay / overlay overlay lowerdir=/,upperdir=/cow,workdir=/cow-work 0 0
```

### 3.6 APT Cache Management

**Purpose**: Reduce disk space used by package cache

**Configuration**:

```bash
# /etc/apt/apt.conf.d/01-cache
APT::Cache-Limit "100000000";  # 100MB cache limit
APT::Clean-Installed "true";
APT::AutoClean "true";
APT::Periodic::Enable "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
```

**Manual Cache Cleanup**:

```bash
# Clean package cache
sudo apt clean

# Remove old packages
sudo apt autoremove

# Remove old config files
sudo apt purge $(dpkg -l | grep '^rc' | awk '{print $2}')
```

### 3.7 Log Rotation

**Purpose**: Prevent log files from consuming too much space

**Configuration**:

```bash
# /etc/logrotate.conf
# Global settings
weekly
rotate 4
create
compress
missingok
notifempty

# Size-based rotation
size 10M

# Keep 4 weeks of logs
maxage 28
```

**Service-specific rotation**:

```bash
# /etc/logrotate.d/syslog
/var/log/syslog
/var/log/mail.log
/var/log/kern.log
/var/log/auth.log
{
    weekly
    rotate 4
    size 10M
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}
```

### 3.8 Temporary File Cleanup

**Purpose**: Automatically clean up temporary files

**Configuration**:

```bash
# /etc/systemd/system/tmp-cleanup.service
[Unit]
Description=Clean up temporary files
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/tmp-cleanup.sh

[Install]
WantedBy=multi-user.target
```

```bash
# /usr/local/bin/tmp-cleanup.sh
#!/bin/bash

# Clean /tmp (older than 1 day)
find /tmp -type f -atime +1 -delete
find /tmp -type d -empty -atime +1 -delete

# Clean /var/tmp (older than 7 days)
find /var/tmp -type f -atime +7 -delete
find /var/tmp -type d -empty -atime +7 -delete

# Clean cache directories
find /var/cache -type f -atime +7 -delete
find /home/*/.cache -type f -atime +7 -delete 2>/dev/null
```

**Timer**:

```bash
# /etc/systemd/system/tmp-cleanup.timer
[Unit]
Description=Run tmp-cleanup daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

### 3.9 Disk Trim (for SSDs)

**Purpose**: Maintain SSD performance

**Configuration**:

```bash
# /etc/systemd/system/fstrim.service
[Unit]
Description=Discard unused blocks on filesystem
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/sbin/fstrim -a --fstab

[Install]
WantedBy=multi-user.target
```

**Timer**:

```bash
# /etc/systemd/system/fstrim.timer
[Unit]
Description=Run fstrim weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

**Manual Trim**:

```bash
# Trim all mounted filesystems
sudo fstrim -a -v
```

### 3.10 Storage Benchmarking

**Purpose**: Monitor storage performance

**Tools**:

```bash
# Install benchmarking tools
sudo apt install fio bonnie++ iozone3

# Run fio benchmark
fio --name=benchmark --ioengine=libaio --rw=randread --bs=4k --numjobs=4 --size=1G --runtime=60 --time_based --end_fsync=1

# Run bonnie++ benchmark
bonnie++ -d /tmp -s 1G -n 0 -m TEST -f -b
```

---

## 4. I/O Optimization

### 🎯 Goal: Maximize I/O performance and minimize latency

### 4.1 I/O Scheduler

**Purpose**: Control how I/O operations are scheduled

**Available Schedulers**:
- `none`: No scheduler (FIFO)
- `noop`: Simple FIFO queue (good for NVMe)
- `deadline`: Deadline-based scheduling
- `cfq`: Completely Fair Queuing (legacy)
- `bfq`: Budget Fair Queuing (recommended for HDDs)
- `kyber`: Kyber I/O scheduler (good for fast storage)
- `mq-deadline`: Multi-queue deadline
- `blk-mq`: Multi-queue (default for NVMe)

**Recommended**:
- **HDD**: BFQ
- **SSD**: none or noop
- **NVMe**: none or kyber

**Configuration**:

```bash
# Set I/O scheduler for a device
echo bfq > /sys/block/sda/queue/scheduler

# Make persistent
GRUB_CMDLINE_LINUX_DEFAULT="... elevator=bfq"
```

**Per-device configuration**:

```bash
# /etc/udev/rules.d/60-io-scheduler.rules
# Set BFQ for HDDs
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

# Set none for SSDs
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"

# Set kyber for NVMe
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="kyber"
```

### 4.2 I/O Priority (ionice)

**Purpose**: Set I/O priority for processes

**Classes**:
- `0`: Idle (lowest priority)
- `1`: Best effort (default)
- `2`: Real-time (highest priority)

**Usage**:

```bash
# Run process with real-time I/O priority
ionice -c 2 -n 0 command

# Run process with idle I/O priority
ionice -c 3 command

# Set I/O priority for running process
ionice -c 2 -p PID
```

**Systemd Service**:

```ini
# /etc/systemd/system/service.service.d/override.conf
[Service]
IOSchedulingClass=realtime
IOSchedulingPriority=0
```

### 4.3 I/O Limits (cgroups)

**Purpose**: Limit I/O bandwidth for specific processes

**Configuration**:

```bash
# Create I/O cgroup
sudo cgcreate -g blkio:/limit-io

# Set I/O limits
sudo cgset -r blkio.read_bps_device="8:0 10485760" limit-io
sudo cgset -r blkio.write_bps_device="8:0 10485760" limit-io

# Run process with I/O limits
cgexec -g blkio:limit-io command
```

**Systemd Service**:

```ini
# /etc/systemd/system/service.service.d/override.conf
[Service]
IOReadBandwidthMax=/dev/sda 10M
IOWriteBandwidthMax=/dev/sda 10M
```

### 4.4 Read-Ahead

**Purpose**: Optimize read-ahead for storage devices

**Configuration**:

```bash
# Check current read-ahead
cat /sys/block/sda/queue/read_ahead_kb

# Set read-ahead (in 512-byte sectors, so 4096 = 2MB)
echo 4096 > /sys/block/sda/queue/read_ahead_kb

# Make persistent
GRUB_CMDLINE_LINUX_DEFAULT="... root=/dev/sda1 ro readahead=4096"
```

**Recommended Values**:
- **HDD**: 4096-8192 (2-4MB)
- **SSD**: 1024-2048 (512KB-1MB)
- **NVMe**: 512-1024 (256KB-512KB)

### 4.5 Swappiness

**Purpose**: Control how aggressively the kernel swaps

**Configuration**:

```bash
# /etc/sysctl.d/99-swappiness.conf
# Swappiness (0-100, higher = more swap)
vm.swappiness=60

# Watermark scale factor
vm.watermark_scale_factor=200

# Dirty ratio (percentage of RAM that can be filled with dirty pages)
vm.dirty_ratio=10

# Dirty background ratio
vm.dirty_background_ratio=5

# Dirty expire time (in milliseconds)
vm.dirty_expire_centisecs=3000

# Dirty writeback time
vm.dirty_writeback_centisecs=500
```

**Values for different use cases**:
- **Desktop (SSD)**: swappiness=10-30
- **Desktop (HDD)**: swappiness=60-80
- **Server**: swappiness=10-20
- **Low RAM (<2GB)**: swappiness=100

### 4.6 I/O Scheduler Tuning

**BFQ Tuning**:

```bash
# /sys/block/sda/queue/iosched/
# Weight for real-time class
echo 800 > /sys/block/sda/queue/iosched/weight

# Weight for best-effort class
echo 600 > /sys/block/sda/queue/iosched/weight

# Weight for idle class
echo 300 > /sys/block/sda/queue/iosched/weight

# Slice idle time (in nanoseconds)
echo 1000000 > /sys/block/sda/queue/iosched/slice_idle

# Slice sync time
echo 100000 > /sys/block/sda/queue/iosched/slice_sync

# Slice async time
echo 100000 > /sys/block/sda/queue/iosched/slice_async
```

**Kyber Tuning**:

```bash
# /sys/block/nvme0n1/queue/iosched/
# Target latency (in microseconds)
echo 2000 > /sys/block/nvme0n1/queue/iosched/target_latency

# Read latency weight
echo 100 > /sys/block/nvme0n1/queue/iosched/read_latency_weight

# Write latency weight
echo 100 > /sys/block/nvme0n1/queue/iosched/write_latency_weight
```

### 4.7 Disk Readahead

**Purpose**: Optimize disk readahead for better performance

**Configuration**:

```bash
# Check current readahead
cat /sys/block/sda/queue/read_ahead_kb

# Set readahead
echo 4096 > /sys/block/sda/queue/read_ahead_kb
```

**Automatic Readahead Tuning**:

```bash
# /usr/local/bin/tune-readahead.sh
#!/bin/bash

# Detect device type and set appropriate readahead
for device in /sys/block/sd*; do
    rotational=$(cat $device/queue/rotational)
    
    if [ "$rotational" = "1" ]; then
        # HDD - higher readahead
        echo 8192 > $device/queue/read_ahead_kb
    else
        # SSD/NVMe - lower readahead
        echo 1024 > $device/queue/read_ahead_kb
    fi
done
```

### 4.8 I/O Elevator (Legacy)

**Purpose**: Control I/O elevator algorithm (for older kernels)

**Configuration**:

```bash
# Set I/O elevator
echo cfq > /sys/block/sda/queue/scheduler

# Make persistent
GRUB_CMDLINE_LINUX_DEFAULT="... elevator=cfq"
```

---

## 5. Network Optimization

### 🎯 Goal: Maximize network performance and minimize latency

### 5.1 TCP/IP Tuning

**Purpose**: Optimize TCP/IP stack for better performance

**Configuration**:

```bash
# /etc/sysctl.d/99-network.conf
# TCP settings
net.core.somaxconn=65535
net.core.netdev_max_backlog=5000
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=262144
net.core.wmem_default=262144
net.core.optmem_max=65535

# TCP settings
net.ipv4.tcp_mem=147456 1966080 2949120
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_intvl=15

# TCP congestion control
net.ipv4.tcp_congestion_control=cubic

# TCP fast open
net.ipv4.tcp_fastopen=3

# TCP SYN backlog
net.ipv4.tcp_max_syn_backlog=8192

# TCP SYN cookies
net.ipv4.tcp_syncookies=1

# TCP reuse
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15

# IP settings
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.ip_no_pmtu_disc=0
net.ipv4.route.gc_timeout=100

# UDP settings
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192
```

**Congestion Control Algorithms**:
- `cubic`: Default, good for high-speed networks
- `bbr`: Google's BBR, good for high-latency networks
- `htcp`: High-speed TCP
- `vegas`: Vegas congestion control
- `westwood`: Westwood congestion control

**Enable BBR**:

```bash
# /etc/sysctl.d/99-bbr.conf
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
```

### 5.2 Network Interface Tuning

**Purpose**: Optimize network interface settings

**Configuration**:

```bash
# /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
    # Increase TX/RX queue length
    txqueuelen 5000
    
    # Enable offloading
    offload-tso on
    offload-gso on
    offload-gro on
    offload-lro on
    
    # Enable checksum offloading
    offload-tx on
    offload-rx on
```

**Manual Tuning**:

```bash
# Increase TX queue length
sudo ifconfig eth0 txqueuelen 5000

# Enable offloading
sudo ethtool -K eth0 tso on gso on gro on lro on

# Check offloading status
ethtool -k eth0
```

### 5.3 DNS Optimization

**Purpose**: Optimize DNS resolution

**Configuration**:

```bash
# /etc/resolv.conf
# Use Cloudflare DNS
nameserver 1.1.1.1
nameserver 1.0.0.1

# Use Google DNS
# nameserver 8.8.8.8
# nameserver 8.8.4.4

# Use Quad9 DNS
# nameserver 9.9.9.9
# nameserver 149.112.112.112

# Options
options timeout:2
options attempts:2
options rotate
options no-check-names
```

**Systemd-Resolved**:

```bash
# /etc/systemd/resolved.conf
[Resolve]
DNS=1.1.1.1 1.0.0.1
FallbackDNS=8.8.8.8 8.8.4.4
Domains=~.
DNSSEC=allow-downgrade
Cache=yes
DNSStubListener=yes
```

**DNS Caching**:

```bash
# Install dnsmasq for local caching
sudo apt install dnsmasq

# Configure dnsmasq
# /etc/dnsmasq.conf
cache-size=1000
local-service
no-resolv
server=1.1.1.1
server=1.0.0.1
```

### 5.4 Network Manager Tuning

**Purpose**: Optimize NetworkManager for better performance

**Configuration**:

```ini
# /etc/NetworkManager/NetworkManager.conf
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

[connectivity]
uri=http://connectivity-check.ubuntu.com/
response=OK
interval=300
```

### 5.5 QoS (Quality of Service)

**Purpose**: Prioritize network traffic

**Configuration (TC - Traffic Control)**:

```bash
# /usr/local/bin/setup-qos.sh
#!/bin/bash

# Clear existing rules
tc qdisc del dev eth0 root 2>/dev/null

# Create HTB (Hierarchical Token Bucket) qdisc
tc qdisc add dev eth0 root handle 1: htb default 30

# Create classes
tc class add dev eth0 parent 1: classid 1:1 htb rate 100mbit

# High priority class (10% bandwidth)
tc class add dev eth0 parent 1:1 classid 1:10 htb rate 10mbit ceil 100mbit

# Medium priority class (70% bandwidth)
tc class add dev eth0 parent 1:1 classid 1:20 htb rate 70mbit ceil 100mbit

# Low priority class (20% bandwidth)
tc class add dev eth0 parent 1:1 classid 1:30 htb rate 20mbit ceil 100mbit

# Create filters
tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dport 22 0xffff flowid 1:10
tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip sport 22 0xffff flowid 1:10

# SSH traffic
tc filter add dev eth0 protocol ip parent 1:0 prio 2 u32 match ip dport 80 0xffff flowid 1:20
tc filter add dev eth0 protocol ip parent 1:0 prio 2 u32 match ip dport 443 0xffff flowid 1:20

# HTTP/HTTPS traffic
tc filter add dev eth0 protocol ip parent 1:0 prio 3 u32 match ip dport 1 0xffff flowid 1:30

# Everything else
```

### 5.6 Network Buffer Sizes

**Purpose**: Optimize network buffer sizes

**Configuration**:

```bash
# /etc/sysctl.d/99-buffer.conf
# Increase network buffer sizes
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=262144
net.core.wmem_default=262144
net.core.optmem_max=65535

# TCP buffer sizes
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
```

### 5.7 IPv6 Optimization

**Purpose**: Optimize IPv6 performance

**Configuration**:

```bash
# /etc/sysctl.d/99-ipv6.conf
# IPv6 settings
net.ipv6.conf.all.disable_ipv6=0
net.ipv6.conf.default.disable_ipv6=0
net.ipv6.conf.lo.disable_ipv6=0

# IPv6 autoconfiguration
net.ipv6.conf.all.autoconf=1
net.ipv6.conf.default.autoconf=1

# IPv6 privacy extensions
net.ipv6.conf.all.use_tempaddr=2
net.ipv6.conf.default.use_tempaddr=2
net.ipv6.conf.eth0.use_tempaddr=2

# IPv6 router advertisements
net.ipv6.conf.all.accept_ra=1
net.ipv6.conf.default.accept_ra=1
net.ipv6.conf.eth0.accept_ra=1

# IPv6 forwarding
net.ipv6.conf.all.forwarding=0
```

### 5.8 Wireless Optimization

**Purpose**: Optimize wireless network performance

**Configuration**:

```bash
# /etc/wpa_supplicant/wpa_supplicant.conf
ctrl_interface=DIR=/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

# Power save mode
p2p_disabled=1
power_save=0

# Roaming
bgscan="simple:30:-65:300"
roam_experimental=1
```

**iwconfig Settings**:

```bash
# Set wireless power management
iwconfig wlan0 power off

# Set wireless retry limits
iwconfig wlan0 retry short 5

# Set wireless RTS/CTS
iwconfig wlan0 rts 2347
```

---

## 6. Graphics Optimization

### 🎯 Goal: Maximize graphics performance while minimizing resource usage

### 6.1 Graphics Drivers

**Purpose**: Install and configure appropriate graphics drivers

**Driver Selection**:

| GPU | Recommended Driver | Alternative | Notes |
|-----|-------------------|------------|-------|
| Intel (Sandy Bridge+) | intel | modesetting | Open source |
| Intel (Older) | i915 | vesa | Legacy |
| AMD (GCN 1.0+) | amdgpu | radeon | Open source |
| AMD (Older) | radeon | ati | Legacy |
| NVIDIA (New) | nvidia | nouveau | Proprietary |
| NVIDIA (Old) | nvidia-390 | nouveau | Legacy |
| Virtual | virtio | qxl | Virtualization |

**Installation**:

```bash
# Intel
sudo apt install xserver-xorg-video-intel

# AMD
sudo apt install xserver-xorg-video-amdgpu

# NVIDIA (proprietary)
sudo ubuntu-drivers autoinstall

# Virtual
sudo apt install xserver-xorg-video-qxl
```

### 6.2 Xorg Configuration

**Purpose**: Optimize Xorg server for performance

**Configuration**:

```bash
# /etc/X11/xorg.conf.d/10-lightning-linux.conf
Section "ServerLayout"
    Identifier "LightningLinux"
    Screen 0 "Screen0" 0 0
    Option "AllowEmptyInput" "false"
    Option "AutoAddDevices" "false"
    Option "DontVTSwitch" "true"
EndSection

Section "Device"
    Identifier "Card0"
    Driver "modesetting"
    Option "AccelMethod" "glamor"
    Option "TearFree" "true"
    Option "VariableRefresh" "true"
    Option "TripleBuffer" "true"
    Option "EnablePageFlip" "true"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "Card0"
    Monitor "Monitor0"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080_60.00"
    EndSubSection
EndSection

Section "Extensions"
    Option "Composite" "Enable"
    Option "RENDER" "Enable"
    Option "DAMAGE" "Enable"
    Option "DPMS" "Enable"
EndSection
```

### 6.3 Compositing

**Purpose**: Enable/disable compositing based on hardware

**Picom Configuration**:

```bash
# /etc/xdg/picom.conf
# Backend
backend = "glx";

# Performance
vsync = true;
compositing-cache = true;

# Shadows
shadow = true;
shadow-radius = 8;
shadow-opacity = 0.5;

# Fading
fading = true;
fade-delta = 4;
fade-in-step = 0.03;
fade-out-step = 0.03;

# Transparency
opacity-rule = [
  "90:class_g = 'xfce4-terminal'",
  "90:class_g = 'Thunar'",
  "80:class_g = 'firefox'",
];

# Performance tweaks
detect-client-opacity = true;
detect-rounded-corners = true;
use-damage = true;

# VSync
vsync-use-glfinish = true;
```

**Disable Compositing (for low-end hardware)**:

```bash
# Disable compositing in Xfce
xfconf-query -c xfwm4 -p /general/compositor_enable -s false

# Disable compositing in KDE
kwriteconfig5 --file kwinrc --group Compositing --key Enabled false
```

### 6.4 Tear-Free Rendering

**Purpose**: Prevent screen tearing

**Configuration**:

```bash
# Intel
xrandr --output eDP-1 --set "TearFree" on

# AMD
xrandr --output eDP-1 --set "TEAR_FREE" on

# NVIDIA
nvidia-settings --assign CurrentMetaMode="1920x1080_60 +0+0 {ForceFullCompositionPipeline=On}"
```

**Xorg Configuration**:

```bash
# /etc/X11/xorg.conf.d/20-tearfree.conf
Section "Device"
    Identifier "Card0"
    Driver "intel"
    Option "TearFree" "true"
EndSection
```

### 6.5 GPU Power Management

**Purpose**: Control GPU power states

**Intel**:

```bash
# /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="... i915.enable_rc6=1 i915.enable_fbc=1 i915.lvds_downclock=1"

# Update GRUB
sudo update-grub
```

**AMD**:

```bash
# /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="... radeon.dpm=1 amdgpu.dpm=1"

# Update GRUB
sudo update-grub
```

**NVIDIA**:

```bash
# Set power management mode
nvidia-smi -pm 1
nvidia-smi -pl 50  # Power limit in watts

# Set GPU to auto mode
nvidia-smi -i 0 -powerlimit=50
```

### 6.6 VSync and Triple Buffering

**Purpose**: Reduce screen tearing and improve performance

**Configuration**:

```bash
# Enable triple buffering (NVIDIA)
nvidia-settings --assign CurrentMetaMode="1920x1080_60 +0+0 {ForceFullCompositionPipeline=On, AllowGSYNC=On}"

# Enable VSync in games
__GL_SYNC_TO_VBLANK=1
__GL_SWAP_HYBRID=1
```

### 6.7 OpenGL Settings

**Purpose**: Optimize OpenGL performance

**Configuration**:

```bash
# /etc/environment
# Use LLVMpipe for software rendering
LIBGL_ALWAYS_SOFTWARE=1

# Use specific GPU
__GLX_VENDOR_LIBRARY_NAME=nvidia

# Enable VSync
__GL_SYNC_TO_VBLANK=1

# Enable triple buffering
__GL_SYNC_DISPLAY_DEVICE=1
```

**Mesa Settings**:

```bash
# /etc/mesa/driconf.d/99-lightning-linux.conf
<driconf>
  <device screen="0" driver="i965">
    <application name="Default">
      <option name="vblank_mode" value="1" />
      <option name="allow_glsl_extension_directive" value="true" />
      <option name="force_glsl_extensions_warn" value="false" />
      <option name="glsl_zero_init" value="true" />
      <option name="force_s3tc_enable" value="true" />
    </application>
  </device>
</driconf>
```

### 6.8 Vulkan Settings

**Purpose**: Optimize Vulkan performance

**Configuration**:

```bash
# /etc/vulkan/icd.d/99-lightning-linux.json
{
  "ICD": {
    "library_path": "/usr/share/vulkan/icd.d/intel_icd.x86_64.json"
  }
}

# Environment variables
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json
VK_LOADER_DEBUG=all
```

### 6.9 Display Refresh Rate

**Purpose**: Set optimal refresh rate

**Configuration**:

```bash
# List available modes
xrandr

# Set refresh rate
xrandr --output eDP-1 --mode 1920x1080 --rate 60

# Set custom mode
xrandr --newmode "1920x1080_60.00" 173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync
xrandr --addmode eDP-1 "1920x1080_60.00"
xrandr --output eDP-1 --mode "1920x1080_60.00"
```

### 6.10 Color Depth

**Purpose**: Reduce color depth for better performance

**Configuration**:

```bash
# Set 16-bit color depth
xrandr --output eDP-1 --mode 1920x1080 --depth 16

# Set 24-bit color depth (default)
xrandr --output eDP-1 --mode 1920x1080 --depth 24
```

---

## 7. Boot Optimization

### 🎯 Goal: Achieve boot time <10 seconds

### 7.1 Kernel Boot Parameters

**Purpose**: Optimize kernel boot process

**Configuration**:

```bash
# /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=1
GRUB_TIMEOUT_STYLE=hidden
GRUB_DISTRIBUTOR="Lightning Linux"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 systemd.show_status=false systemd.log_level=warning rd.udev.log_level=3"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL="console"
GRUB_GFXMODE="1920x1080"
GRUB_GFXPAYLOAD_LINUX="keep"
GRUB_DISABLE_OS_PROBER=false

# Update GRUB
sudo update-grub
```

**Boot Parameter Explanations**:
- `quiet`: Suppress most kernel messages
- `splash`: Show splash screen
- `loglevel=3`: Kernel log level (0-7, lower = less verbose)
- `systemd.show_status=false`: Hide systemd status messages
- `systemd.log_level=warning`: Systemd log level
- `rd.udev.log_level=3`: udev log level

### 7.2 Initramfs Optimization

**Purpose**: Reduce initramfs size and improve boot speed

**Configuration**:

```bash
# /etc/initramfs-tools/initramfs.conf
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

# Reduce initramfs size
OMIT_FRAMEBUFFER=y
OMIT_DMRAID=y
OMIT_LVM2=y
OMIT_ZFS=y
```

**Manual Initramfs Build**:

```bash
# Update initramfs
sudo update-initramfs -u -k all

# Check initramfs size
ls -lh /boot/initrd.img-$(uname -r)

# Extract and inspect initramfs
mkdir /tmp/initramfs
cd /tmp/initramfs
lz4 -d /boot/initrd.img-$(uname -r) | cpio -idmv
```

### 7.3 Systemd Optimization

**Purpose**: Optimize systemd boot process

**Configuration**:

```bash
# /etc/systemd/system.conf
# Parallel startup
DefaultStartLimitIntervalSec=10s
DefaultStartLimitBurst=5
DefaultCPUAccounting=no
DefaultIOAccounting=no
DefaultIPAccounting=no
DefaultMemoryAccounting=no
DefaultBlockIOAccounting=no
DefaultTasksAccounting=no

# Timeout settings
DefaultTimeoutStartSec=5s
DefaultTimeoutStopSec=5s
DefaultTimeoutAbortSec=10s

# Service timeout
DefaultServiceTimeoutStartSec=10s
DefaultServiceTimeoutStopSec=10s
```

**Disable Unnecessary Services**:

```bash
# List all services
systemctl list-unit-files --type=service

# Disable unnecessary services
sudo systemctl disable avahi-daemon
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable cups-browsed
sudo systemctl disable ModemManager
sudo systemctl disable snapd
sudo systemctl disable rpcbind
sudo systemctl disable nfs-client.target
sudo systemctl disable isc-dhcp-server
sudo systemctl disable isc-dhcp-client
sudo systemctl disable apache2
sudo systemctl disable mysql
sudo systemctl disable postgresql
```

**Mask Unnecessary Services**:

```bash
# Mask services to prevent accidental enabling
sudo systemctl mask avahi-daemon
sudo systemctl mask bluetooth
sudo systemctl mask cups
sudo systemctl mask ModemManager
```

### 7.4 OpenRC Optimization

**Purpose**: Optimize OpenRC boot process

**Configuration**:

```bash
# /etc/rc.conf
rc_sys="lvm dmraid"
rc_parallel="YES"
rc_logger="NO"
rc_depend_strict="NO"
rc_unicode="YES"

# Disabled services
rc_services="devfs sysinit syslog networking sshd local"
```

**Disable Unnecessary Services**:

```bash
# List all services
rc-update show

# Disable unnecessary services
rc-update del avahi-daemon default
rc-update del bluetooth default
rc-update del cups default
rc-update del cups-browsed default
rc-update del dbus default
rc-update del elogind default
rc-update del nfs-client default
rc-update del rpcbind default
rc-update del samba default
rc-update del smartd default
```

### 7.5 Service Optimization

**Purpose**: Optimize individual services for faster startup

**NetworkManager**:

```bash
# /etc/NetworkManager/NetworkManager.conf
[main]
plugins=keyfile
rc-manager=unmanaged

[keyfile]
unmanaged-devices=none

[device]
wifi.scan-rand-mac-address=no

[logging]
level=ERR
domains=ALL
```

**LightDM**:

```ini
# /etc/lightdm/lightdm.conf
[LightDM]
minimum-display-number=0

[Seat:*]
xserver-command=X -background none -nolisten tcp
xserver-layout=LVDS-1
greeter-session=lightdm-greeter
user-session=lightning-linux

[Seat:seat0]
type=xlocal
xserver-command=X

[Logging]
log-level=error
```

**Xorg**:

```bash
# /etc/X11/xorg.conf.d/00-server-args.conf
Section "ServerFlags"
    Option "AutoAddDevices" "false"
    Option "AllowEmptyInput" "false"
    Option "DontVTSwitch" "true"
    Option "HandleSpecialKeys" "Always"
EndSection
```

### 7.6 Boot Process Analysis

**Purpose**: Identify boot bottlenecks

**Tools**:

```bash
# Install boot analysis tools
sudo apt install bootchart systemd-analyze

# Enable bootchart
sudo systemctl enable bootchart
sudo systemctl start bootchart

# Analyze boot time
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain
systemd-analyze plot > boot.svg

# Check boot time breakdown
journalctl -b --no-pager | grep -i "startup finished"
```

**Bootchart**:

```bash
# Install bootchart
sudo apt install bootchart

# Enable bootchart
sudo systemctl enable bootchart
sudo systemctl start bootchart

# View bootchart
# /var/log/bootchart/bootchart.svg
```

### 7.7 Kernel Module Optimization

**Purpose**: Load only necessary kernel modules

**Configuration**:

```bash
# /etc/modules-load.d/lightning-linux.conf
# Essential modules
zram

# Filesystem modules
ext4

# Network modules
8021q

# Input modules
evdev

# Graphics modules
i915
```

**Blacklist unnecessary modules**:

```bash
# /etc/modprobe.d/blacklist.conf
# Blacklist unnecessary modules
blacklist pcspkr
blacklist bluetooth
blacklist btusb
blacklist bnep
blacklist rfcomm
blacklist hci_uart
blacklist btbcm
blacklist btintel
blacklist bluetooth_6lowpan
blacklist nf_conntrack_netlink
blacklist nf_nat
blacklist nf_log
blacklist xt_tcpudp
```

### 7.8 Udev Optimization

**Purpose**: Optimize udev for faster device initialization

**Configuration**:

```bash
# /etc/udev/udev.conf
udev_log="err"

# /etc/systemd/system/udev.service.d/override.conf
[Service]
TimeoutStartSec=5s
```

**Udev Rules Optimization**:

```bash
# /etc/udev/rules.d/99-lightning-linux.rules
# Skip persistent rules for faster boot
ACTION=="add", SUBSYSTEM=="module", RUN+="/bin/sh -c 'echo $kernel > /sys/module/$kernel/refcnt 2>/dev/null'"

# Skip waiting for network
ACTION=="add", SUBSYSTEM=="net", TEST=="[net/ifindex]", RUN+="/bin/sh -c 'echo 1 > /sys/class/net/$name/flags 2>/dev/null'"
```

### 7.9 Filesystem Check Optimization

**Purpose**: Skip filesystem checks for faster boot

**Configuration**:

```bash
# /etc/fstab
UUID=xxxx-xxxx / ext4 noatime,nodiratime,errors=remount-ro,noauto,nofail 0 0

# Disable filesystem checks
tune2fs -c 0 /dev/sda1
tune2fs -i 0 /dev/sda1
```

**Note**: Only disable filesystem checks if you have a journaling filesystem and are confident in your hardware.

### 7.10 Prefetching

**Purpose**: Prefetch frequently used files for faster boot

**Configuration**:

```bash
# Install prefetch tools
sudo apt install preload readahead

# Configure preload
# /etc/preload.conf
# Applications to preload
firefox
libreoffice
thunar
xfce4-terminal

# Configure readahead
sudo readahead-collector
sudo readahead-replay
```

**Systemd Prefetch**:

```bash
# /etc/systemd/system/prefetch.service
[Unit]
Description=Prefetch frequently used files
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/prefetch.sh

[Install]
WantedBy=multi-user.target
```

```bash
# /usr/local/bin/prefetch.sh
#!/bin/bash

# Prefetch common binaries
for binary in /usr/bin/firefox /usr/bin/thunar /usr/bin/xfce4-terminal; do
    if [ -f $binary ]; then
        vmtouch -t $binary
    fi
done

# Prefetch libraries
for lib in /usr/lib/x86_64-linux-gnu/libc.so.6 /usr/lib/x86_64-linux-gnu/libstdc++.so.6; do
    if [ -f $lib ]; then
        vmtouch -t $lib
    fi
done
```

### 7.11 Boot Splash Screen

**Purpose**: Show splash screen during boot

**Configuration**:

```bash
# Install Plymouth
sudo apt install plymouth plymouth-themes

# Set theme
sudo plymouth-set-default-theme lightning-linux

# Enable Plymouth
sudo systemctl enable plymouth-start
sudo systemctl start plymouth-start

# Update initramfs
sudo update-initramfs -u
```

**Custom Theme**:

```bash
# /usr/share/plymouth/themes/lightning-linux/lightning-linux.plymouth
[Plymouth Theme]
Name=Lightning Linux
Description=A theme for Lightning Linux
ModuleName=two-step

[two-step]
ImageDir=/usr/share/plymouth/themes/lightning-linux
AnimationDir=/usr/share/plymouth/themes/lightning-linux

# Create theme directory
mkdir -p /usr/share/plymouth/themes/lightning-linux

# Copy background image
cp /path/to/background.png /usr/share/plymouth/themes/lightning-linux/

# Create animation
# ...
```

---

## 📈 Performance Monitoring

### 8.1 System Monitoring Tools

**Installation**:

```bash
# Install monitoring tools
sudo apt install htop iotop iftop nmon glances netdata
```

**Usage**:

```bash
# htop - Interactive process viewer
htop

# iotop - I/O usage monitor
sudo iotop

# iftop - Network bandwidth monitor
sudo iftop

# nmon - System monitoring tool
nmon

# glances - Comprehensive monitoring
sudo glances

# netdata - Real-time web-based monitoring
sudo systemctl enable netdata
sudo systemctl start netdata
# Access at http://localhost:19999
```

### 8.2 Performance Logging

**Configuration**:

```bash
# /etc/sysstat/sysstat
# Enable sysstat
ENABLED="true"

# Collection interval (in seconds)
SADC_OPTIONS="-S DISK -S IRQ -S XDISK 1 3"

# History
HISTORY=28
```

**Manual Collection**:

```bash
# Collect system activity
sar -A 1 3

# View historical data
sar -u
sar -r
sar -q
```

### 8.3 Benchmarking

**Installation**:

```bash
# Install benchmarking tools
sudo apt install sysbench fio bonnie++ iozone3 geekbench
```

**CPU Benchmark**:

```bash
# sysbench CPU benchmark
sysbench cpu --threads=4 run

# Geekbench
geekbench_x86_64
```

**Memory Benchmark**:

```bash
# sysbench memory benchmark
sysbench memory --memory-block-size=1G run
```

**Disk Benchmark**:

```bash
# fio benchmark
fio --name=benchmark --ioengine=libaio --rw=randread --bs=4k --numjobs=4 --size=1G --runtime=60 --time_based --end_fsync=1

# bonnie++ benchmark
bonnie++ -d /tmp -s 1G -n 0 -m TEST -f -b
```

**Network Benchmark**:

```bash
# iperf3 benchmark
iperf3 -c server-ip

# speedtest
sudo apt install speedtest-cli
speedtest-cli
```

### 8.4 Performance Profiling

**Installation**:

```bash
# Install profiling tools
sudo apt install perf valgrind strace ltrace gprof
```

**Usage**:

```bash
# Profile CPU usage
perf top
perf record -g -p PID
perf report

# Memory profiling
valgrind --tool=massif ./program
ms_print massif.out.*

# System call tracing
strace -p PID
strace -f -o trace.log ./program

# Library call tracing
ltrace -f -o trace.log ./program
```

---

## 🎛️ Power Management

### 9.1 TLP (Advanced Power Management)

**Purpose**: Optimize power consumption for laptops

**Installation**:

```bash
# Install TLP
sudo apt install tlp tlp-rdw

# Enable TLP
sudo systemctl enable tlp
sudo systemctl start tlp
```

**Configuration**:

```ini
# /etc/tlp.conf
# General settings
TLP_ENABLE=1

# CPU settings
CPU_SCALING_GOVERNOR_ON_AC=schedutil
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=50
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# Graphics
INTEL_MAX_PERF_ON_AC=maximum_performance
INTEL_MAX_PERF_ON_BAT=power

# USB
USB_BLACKLIST="0b95:1234"  # Example: disable specific USB device
USB_AUTOSUSPEND=1

# Audio
SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=1

# PCIe
PCIE_ASPM_ON_AC=performance
PCIE_ASPM_ON_BAT=powersave

# Runtime Power Management
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto
RUNTIME_PM_BLACKLIST="01:00.0"  # Example: disable for specific device

# Disk
DISK_DEVICES="sda sdb"
DISK_APM_LEVEL_ON_AC=254
DISK_APM_LEVEL_ON_BAT=128
DISK_SPINDOWN_TIMEOUT_ON_AC=0
DISK_SPINDOWN_TIMEOUT_ON_BAT=60

# AHCI
AHCI_RUNTIME_PM_ON_AC=on
AHCI_RUNTIME_PM_ON_BAT=auto
```

### 9.2 Laptop Mode Tools

**Purpose**: Additional power savings for laptops

**Installation**:

```bash
# Install laptop-mode-tools
sudo apt install laptop-mode-tools

# Enable laptop mode
sudo systemctl enable laptop-mode
sudo systemctl start laptop-mode
```

**Configuration**:

```bash
# /etc/laptop-mode/laptop-mode.conf
# Enable laptop mode
CONTROL_LAPTOP_MODE=1

# Enable when on battery
LM_BATT_ENABLE=1

# Enable when on AC
LM_AC_ENABLE=0

# NMI watchdog
NMI_WATCHDOG=0

# Dirty page settings
LM_DIRTY_PAGE_PERCENT=10
LM_DIRTY_PAGE_AGE_MS=1000

# Readahead
LM_READAHEAD=2048

# HDD power management
BATT_HD_POWERMGMT=1
```

### 9.3 PowerTop

**Purpose**: Identify power consumption issues

**Installation**:

```bash
# Install powertop
sudo apt install powertop
```

**Usage**:

```bash
# Run powertop
sudo powertop

# Auto-tune
sudo powertop --auto-tune

# HTML report
sudo powertop --html=powertop.html
```

### 9.4 CPU Frequency Scaling

**Purpose**: Control CPU frequency for power saving

**Configuration**:

```bash
# /etc/default/cpufrequtils
GOVERNOR="powersave"
MIN_SPEED="800000"
MAX_SPEED="2400000"
```

**Manual Control**:

```bash
# Set governor
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo powersave > $cpu
done

# Set frequency limits
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do
    echo 800000 > $cpu
done

for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
    echo 2400000 > $cpu
done
```

---

## 🔧 Maintenance and Tuning

### 10.1 Regular Maintenance

**Cron Jobs**:

```bash
# /etc/cron.daily/lightning-linux-maintenance
#!/bin/bash

# Clean package cache
apt clean

# Remove old packages
apt autoremove

# Clean temporary files
find /tmp -type f -atime +1 -delete
find /var/tmp -type f -atime +7 -delete

# Clean cache directories
find /var/cache -type f -atime +7 -delete
find /home/*/.cache -type f -atime +7 -delete 2>/dev/null

# Update mlocate database
updatedb

# Clean journal
journalctl --vacuum-time=7d
journalctl --vacuum-size=100M
```

### 10.2 Kernel Tuning

**Sysctl Configuration**:

```bash
# /etc/sysctl.d/99-tuning.conf
# Kernel settings
kernel.sysrq=1
kernel.core_uses_pid=1
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.perf_event_paranoid=3

# Memory settings
vm.swappiness=60
vm.vfs_cache_pressure=50
vm.dirty_ratio=10
vm.dirty_background_ratio=5

# Network settings
net.core.somaxconn=65535
net.core.netdev_max_backlog=5000
net.ipv4.tcp_max_syn_backlog=8192

# Filesystem settings
fs.file-max=2097152
fs.inotify.max_user_watches=524288
```

### 10.3 Service Tuning

**Systemd Service Tuning**:

```bash
# /etc/systemd/system.conf
DefaultLimitNOFILE=65535
DefaultLimitNPROC=65535
DefaultLimitCORE=infinity
DefaultLimitMEMLOCK=64M
DefaultLimitLOCKED=64M
DefaultLimitSIGPENDING=65535
DefaultLimitMSGQUEUE=81920
DefaultLimitNICE=0
DefaultLimitRTPRIO=0
DefaultLimitRTTIME=infinity
```

### 10.4 Process Tuning

**Nice and Renice**:

```bash
# Run process with high priority
nice -n -10 command

# Change priority of running process
renice -n -10 -p PID

# Run process with real-time priority
chrt -f 99 command
```

**Cgroups**:

```bash
# Create cgroup
sudo cgcreate -g cpu,memory:/high-priority

# Set CPU limits
sudo cgset -r cpu.shares=1024 high-priority

# Set memory limits
sudo cgset -r memory.limit_in_bytes=1G high-priority

# Run process in cgroup
cgexec -g cpu,memory:high-priority command
```

---

## 📋 Optimization Checklist

### For 2GB RAM Systems

- [ ] Enable ZRAM with 50-100% of RAM
- [ ] Enable ZSWAP with lz4 compression
- [ ] Set swappiness to 100
- [ ] Use lightweight desktop (Xfce4 or Openbox)
- [ ] Disable unnecessary services
- [ ] Use lightweight applications
- [ ] Enable THP
- [ ] Tune OOM killer
- [ ] Use musl libc (optional)
- [ ] Use BusyBox (optional)

### For 4GB RAM Systems

- [ ] Enable ZRAM with 25-50% of RAM
- [ ] Enable ZSWAP with lz4 compression
- [ ] Set swappiness to 60
- [ ] Use Xfce4 desktop
- [ ] Disable unnecessary services
- [ ] Use lightweight applications
- [ ] Enable THP
- [ ] Tune OOM killer

### For 8GB+ RAM Systems

- [ ] Enable ZRAM with 10-20% of RAM
- [ ] Enable ZSWAP with lz4 compression
- [ ] Set swappiness to 10-30
- [ ] Use any desktop environment
- [ ] Disable unnecessary services
- [ ] Enable THP
- [ ] Tune OOM killer

### For HDD Systems

- [ ] Use BFQ I/O scheduler
- [ ] Set read-ahead to 4096-8192
- [ ] Enable write cache
- [ ] Use ext4 filesystem
- [ ] Set swappiness to 60-80

### For SSD Systems

- [ ] Use none or noop I/O scheduler
- [ ] Set read-ahead to 1024-2048
- [ ] Enable TRIM
- [ ] Use ext4 or Btrfs filesystem
- [ ] Set swappiness to 10-30

### For NVMe Systems

- [ ] Use none or kyber I/O scheduler
- [ ] Set read-ahead to 512-1024
- [ ] Enable TRIM
- [ ] Use ext4 or Btrfs filesystem
- [ ] Set swappiness to 10-20

---

## 🔍 Troubleshooting

### High Memory Usage

**Symptoms**: System is slow, OOM killer is active

**Diagnosis**:

```bash
# Check memory usage
free -h

# Check process memory usage
top
htop

# Check memory usage by process
ps aux --sort=-%mem | head

# Check ZRAM usage
cat /proc/swaps
cat /sys/block/zram0/mem_used_max
```

**Solutions**:

1. **Increase ZRAM size**:
   ```bash
   echo $((4 * 1024 * 1024 * 1024)) > /sys/block/zram0/disksize
   ```

2. **Adjust swappiness**:
   ```bash
   echo 100 > /proc/sys/vm/swappiness
   ```

3. **Kill memory-hungry processes**:
   ```bash
   kill -9 PID
   ```

4. **Disable unnecessary services**:
   ```bash
   sudo systemctl disable service
   ```

### High CPU Usage

**Symptoms**: System is slow, CPU usage is at 100%

**Diagnosis**:

```bash
# Check CPU usage
top
htop

# Check CPU usage by process
ps aux --sort=-%cpu | head

# Check CPU frequency
cat /proc/cpuinfo | grep MHz

# Check CPU temperature
sensors
```

**Solutions**:

1. **Set CPU governor to ondemand**:
   ```bash
   for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
       echo ondemand > $cpu
   done
   ```

2. **Limit process CPU usage**:
   ```bash
   cpulimit -l 50 -p PID
   ```

3. **Kill CPU-hungry processes**:
   ```bash
   kill -9 PID
   ```

### High Disk I/O

**Symptoms**: System is slow, disk LED is constantly on

**Diagnosis**:

```bash
# Check disk I/O
iotop

# Check disk usage
df -h

# Check disk I/O by process
sudo iotop -o

# Check disk queue
cat /proc/diskstats
```

**Solutions**:

1. **Set I/O scheduler to BFQ**:
   ```bash
   echo bfq > /sys/block/sda/queue/scheduler
   ```

2. **Limit process I/O**:
   ```bash
   ionice -c 3 -p PID
   ```

3. **Reduce swappiness**:
   ```bash
   echo 10 > /proc/sys/vm/swappiness
   ```

### Slow Boot

**Symptoms**: Boot time is >10 seconds

**Diagnosis**:

```bash
# Check boot time
systemd-analyze

# Check boot time by service
systemd-analyze blame

# Check critical chain
systemd-analyze critical-chain

# Check boot log
journalctl -b
```

**Solutions**:

1. **Disable unnecessary services**:
   ```bash
   sudo systemctl disable service
   ```

2. **Optimize initramfs**:
   ```bash
   sudo update-initramfs -u
   ```

3. **Reduce GRUB timeout**:
   ```bash
   GRUB_TIMEOUT=1
   sudo update-grub
   ```

4. **Use lighter init system**:
   ```bash
   # Switch to OpenRC
   ```

### Slow Graphics

**Symptoms**: Graphics are laggy, screen tearing

**Diagnosis**:

```bash
# Check GPU usage
glxinfo | grep -i render

# Check GPU driver
lspci -k | grep -A 3 -i vga

# Check Xorg log
cat /var/log/Xorg.0.log | grep -i error
```

**Solutions**:

1. **Install proper GPU drivers**:
   ```bash
   sudo ubuntu-drivers autoinstall
   ```

2. **Disable compositing**:
   ```bash
   xfconf-query -c xfwm4 -p /general/compositor_enable -s false
   ```

3. **Enable TearFree**:
   ```bash
   xrandr --output eDP-1 --set "TearFree" on
   ```

4. **Use lighter desktop**:
   ```bash
   # Switch to Openbox
   ```

---

## 📚 References

### Documentation
- [Kernel Documentation](https://www.kernel.org/doc/html/latest/)
- [Systemd Documentation](https://www.freedesktop.org/software/systemd/man/)
- [OpenRC Documentation](https://wiki.gentoo.org/wiki/OpenRC)
- [ZRAM Documentation](https://www.kernel.org/doc/html/latest/admin-guide/blockdev/zram.html)
- [Btrfs Documentation](https://btrfs.wiki.kernel.org/)

### Tools
- [htop](https://htop.dev/)
- [iotop](https://github.com/Tomas-M/iotop)
- [iftop](https://github.com/paulc/iftop)
- [nmon](https://nmon.sourceforge.net/)
- [glances](https://github.com/nicolargo/glances)
- [netdata](https://github.com/netdata/netdata)
- [sysbench](https://github.com/akopytov/sysbench)
- [fio](https://github.com/axboe/fio)
- [TLP](https://github.com/linrunner/TLP)
- [EarlyOOM](https://github.com/rfjakob/earlyoom)

### Benchmarks
- [Phoronix Test Suite](https://www.phoronix-test-suite.com/)
- [Geekbench](https://www.geekbench.com/)
- [UnixBench](https://github.com/kdlucas/byte-unixbench)
- [Sysbench](https://github.com/akopytov/sysbench)

---

*This document provides comprehensive performance optimization strategies for HarshitOS / Lightning Linux. Implement the optimizations based on your specific hardware and use case.*
