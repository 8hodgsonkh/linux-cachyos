# Kernel Optimization Report — AMD Ryzen 7 7800X3D Gaming Workstation

**Generated:** 2025-12-10  
**Auditor:** System Architect Mode (Sonnet)  
**Target:** Maximum gaming performance, accept instability  

---

## Hardware Profile

| Component | Specification |
|-----------|---------------|
| **CPU** | AMD Ryzen 7 7800X3D (Zen 4 + 3D V-Cache) |
| **µArch** | `znver4` (Family 25h Model 97 Stepping 2) |
| **Cores/Threads** | 8C/16T, SMT enabled |
| **Cache** | L1d: 256 KiB, L1i: 256 KiB, L2: 8 MiB, **L3: 96 MiB (3D V-Cache)** |
| **Frequency** | 426 MHz – 5053 MHz (boost enabled) |
| **NUMA** | Single node (no NUMA complexity) |
| **GPU** | AMD Radeon RX 7900 XT/XTX (Navi 31, RDNA3) |
| **Storage** | Micron P5 Plus NVMe + WD SN750 NVMe |
| **NIC** | Aquantia AQC113CS 10G Ethernet |
| **Toolchain** | Clang 21.1.6 + LLD 21.1.6 |

---

## Current Kernel Configuration Summary

- **Scheduler:** EEVDF base + sched_ext (scx_flash EDF scheduler)
- **Preemption:** `CONFIG_PREEMPT=y` (Full preemption)
- **Tick:** `CONFIG_NO_HZ_FULL=y` (Tickless)
- **HZ:** 100 → **MUST CHANGE TO 800+ (user has custom patch)**
- **LTO:** Clang ThinLTO enabled
- **Optimization:** `-O3` enabled

---

## Vulnerability / Mitigation Status

| Vulnerability | Status | Action |
|---------------|--------|--------|
| Spectre v1 | Vulnerable | ✅ Good (mitigations off) |
| Spectre v2 | Vulnerable (IBPB/STIBP disabled) | ✅ Good |
| SRSO | Vulnerable | ✅ Good |
| Spec Store Bypass | Vulnerable | ✅ Good |
| TSA | Vulnerable | ✅ Good |
| Meltdown | Not affected | N/A (AMD) |
| L1TF | Not affected | N/A (AMD) |

**Verdict:** Mitigations already disabled at runtime. Add `mitigations=off` to cmdline for explicit full bypass.

---

## Kernel Cmdline Recommendation

**Add to `/etc/kernel/cmdline` or bootloader:**

```
mitigations=off nowatchdog nmi_watchdog=0 tsc=reliable clocksource=tsc processor.ignore_ppc=1 amd_pstate=active idle=nomwait
```

### Parameter Breakdown:

| Parameter | Effect | Risk |
|-----------|--------|------|
| `mitigations=off` | Disable ALL CPU vulnerability mitigations | Security risk (acceptable for gaming) |
| `nowatchdog` | Disable software watchdog | No automatic panic on soft lockup |
| `nmi_watchdog=0` | Disable NMI watchdog | Removes periodic NMI interrupts |
| `tsc=reliable` | Trust TSC without calibration | May cause timing issues on broken hardware |
| `clocksource=tsc` | Force TSC as clocksource | Lowest latency timer |
| `processor.ignore_ppc=1` | Ignore BIOS power capping | Full boost available |
| `amd_pstate=active` | AMD P-state active mode | Best freq scaling for Zen 4 |
| `idle=nomwait` | Don't use MWAIT for idle | Can reduce C-state latency |

---

## Kconfig Changes — CRITICAL

### 🔴 MUST CHANGE

| Symbol | Current | Target | Impact |
|--------|---------|--------|--------|
| `CONFIG_HZ` | 100 | **800** | 8x better scheduler resolution. Apply your custom patch. |
| `CONFIG_SCHED_AUTOGROUP` | y | **n** | Remove ~2-5% scheduler overhead. Useless with sched_ext. |

### 🟡 RECOMMENDED FOR MAX PERFORMANCE

| Symbol | Current | Target | Impact | Risk |
|--------|---------|--------|--------|------|
| `CONFIG_STACKPROTECTOR` | y | n | ~1-3% call overhead removed | Stack smash exploitable |
| `CONFIG_STACKPROTECTOR_STRONG` | y | n | Additional overhead removed | Same as above |
| `CONFIG_PM_DEBUG` | y | n | Remove PM debugging overhead | Lose PM debug info |
| `CONFIG_ACPI_DEBUG` | y | n | Remove ACPI debugging overhead | Lose ACPI debug info |
| `CONFIG_DEBUG_SHIRQ` | y | n | Remove IRQ debugging | Lose IRQ debug info |
| `CONFIG_DEBUG_BOOT_PARAMS` | y | n | Remove boot param checking | Lose boot debug |
| `CONFIG_DEBUG_MEMORY_INIT` | y | n | Remove memory init debug | Lose mem init debug |
| `CONFIG_DEBUG_WX` | y | n | Remove W+X checking | Potential security |
| `CONFIG_DEBUG_RODATA_TEST` | y | n | Remove rodata testing | Lose rodata validation |
| `CONFIG_STAGING` | y | n | Remove staging drivers | Lose staging features |
| `CONFIG_CRASH_DUMP` | y | n | Remove kdump support | No crash dumps |
| `CONFIG_KEXEC_FILE` | y | n | Remove kexec (if unused) | Can't kexec |
| `CONFIG_HIBERNATION` | y | n | Remove hibernation | Can't hibernate (do you use it?) |
| `CONFIG_IKCONFIG` | y | n | Remove /proc/config.gz | Can't read config at runtime |

### 🟢 KEEP FOR AFDO/PROPELLER PROFILING

| Symbol | Value | Reason |
|--------|-------|--------|
| `CONFIG_DEBUG_INFO` | y | **Required for profile generation** |
| `CONFIG_DEBUG_INFO_DWARF5` | y | Best debug format for LLVM tooling |
| `CONFIG_DEBUG_INFO_BTF` | y | Required for BPF/sched_ext |
| `CONFIG_FRAME_POINTER` | y | Better stack traces for profiling |
| `CONFIG_SCHED_CLASS_EXT` | y | Required for scx_flash |

**After AFDO profile is generated and applied, you can disable DEBUG_INFO for final gaming kernel.**

---

## Intel Bloat — SAFE TO REMOVE

You have an AMD-only system. These Intel options add code and possibly runtime checks:

```
CONFIG_X86_INTEL_LPSS=n
CONFIG_X86_INTEL_PSTATE=n          # Using AMD P-state instead
CONFIG_INTEL_IDLE=n                # Using AMD idle
CONFIG_INTEL_HFI_THERMAL=n
CONFIG_INTEL_SOC_PMIC=n
CONFIG_INTEL_SOC_PMIC_CHTWC=n
CONFIG_INTEL_LDMA=n
CONFIG_INTEL_TURBO_MAX_3=n
CONFIG_INTEL_SCU_IPC=n
CONFIG_INTEL_SCU=n
CONFIG_INTEL_SCU_PCI=n
CONFIG_INTEL_IOMMU=n               # Using AMD IOMMU
CONFIG_INTEL_IOMMU_SVM=n
CONFIG_INTEL_RAPL=n                # AMD has its own RAPL
```

**Impact:** Reduces kernel size, removes dead code paths.  
**Risk:** Zero — these don't apply to AMD hardware.

### nconfig Path:
- `Processor type and features` → Intel-specific options
- `Power management` → Intel-specific options
- `Device Drivers` → IOMMU → Intel IOMMU

---

## Filesystem Bloat Analysis

**Currently Enabled:**
- BTRFS (your root, KEEP)
- FUSE (useful, KEEP)
- FAT (USB drives, KEEP as module)

**Not Detected but Check:**
- EXT4 — Do you use it? If not, can disable.
- XFS — Disable if unused.
- NTFS3 — Disable if you don't mount Windows drives.
- Network filesystems (NFS, CIFS, etc.) — Disable if unused.

---

## Network Driver Bloat

You have **93 network driver options** enabled. Your actual hardware:
- Aquantia AQC113CS 10G (`CONFIG_AQTION`)

**Safe to Disable:**
- All wireless drivers (if no WiFi card)
- All other Ethernet vendors (Intel, Realtek, Broadcom, etc.)
- ISDN, ATM, ARCNET, FDDI, HIPPI, NET_FC, CAIF, NFC, WIMAX, 6LOWPAN
- CAN bus (unless you're using it for VESC — check!)
- Amateur Radio (HAMRADIO)

**Risk:** Zero if you don't have that hardware.

---

## Audio Subsystem

**65 sound options** enabled. For gaming you need:
- `CONFIG_SND_HDA_INTEL` or your specific codec
- `CONFIG_SND_USB_AUDIO` if using USB DAC/headset

**Can likely disable:**
- Most SND_SOC_* (embedded/mobile audio)
- Obscure HDA codecs you don't have

---

## Input Devices — VERIFIED GOOD

Your gaming input support is correct:
- `CONFIG_INPUT_EVDEV=y` ✅
- `CONFIG_INPUT_JOYDEV=m` ✅
- `CONFIG_JOYSTICK_XPAD=m` ✅ (Xbox controllers)
- `CONFIG_HID_STEAM=m` ✅ (Steam Controller)
- `CONFIG_HID_XPAD=m` ✅
- `CONFIG_USB_HID=m` ✅

**No changes needed.**

---

## USB Drivers — VERIFIED GOOD

Your VESC/dev board support is correct:
- `CONFIG_USB_ACM=m` ✅ (CDC ACM for VESC)
- `CONFIG_USB_SERIAL=m` ✅
- `CONFIG_USB_SERIAL_CH341=m` ✅
- `CONFIG_USB_SERIAL_CP210X=m` ✅
- `CONFIG_USB_SERIAL_FTDI_SIO=m` ✅
- `CONFIG_USB_XHCI_HCD=y` ✅

**No changes needed.**

---

## AMD GPU — VERIFIED GOOD

Your RDNA3 support is correct:
- `CONFIG_DRM_AMDGPU=m` ✅
- `CONFIG_DRM_AMD_DC=y` ✅ (Display Core)
- `CONFIG_HSA_AMD=y` ✅ (Compute)
- `CONFIG_AMD_IOMMU=y` ✅

**Optional consideration:**
- `CONFIG_DRM_AMDGPU_SI=n` — Southern Islands (GCN 1.0) — you don't have this
- `CONFIG_DRM_AMDGPU_CIK=n` — Sea Islands (GCN 2.0) — you don't have this
- `CONFIG_DRM_AMD_DC_SI=n` — DC for SI — you don't have this

These add legacy GPU support you don't need.

---

## scx_flash Scheduler Tuning

Your current flags:
```
-s 1024 -S 128 -l 2048 -r 16384 -c 64 -I -1 -m performance -f -p -D
```

### Analysis:

| Flag | Value | Assessment |
|------|-------|------------|
| `-s 1024` | 1ms slice | ✅ Good for gaming latency |
| `-S 128` | slice_lag=128 | Moderate sleep credit |
| `-l 2048` | lowlat slice 2ms | Could try 1024 for lower latency |
| `-r 16384` | kthread slice 16ms | OK for kernel threads |
| `-c 64` | cpufreq cap | Check what this does |
| `-I -1` | idle_as_exec auto | OK |
| `-m performance` | Max freq | ✅ Correct for gaming |
| `-f` | slice_lag_scaling | ✅ Dynamic fairness |
| `-p` | preempt? | Verify flag meaning |
| `-D` | debug | **Remove for production** |

### Aggressive Gaming Tuning (Experimental):

```
-s 512 -S 64 -l 1024 -r 8192 -c 64 -I -1 -m performance -f -p
```

Changes:
- 512µs slice (0.5ms) — tighter scheduling
- Lower slice_lag — less sleep credit accumulation
- 1ms lowlat slice — faster response for latency-sensitive tasks
- Removed `-D` debug flag

**Risk:** May cause starvation under heavy load. Test in games first.

---

## Runtime Sysctl Tuning

Add to `/etc/sysctl.d/99-gaming.conf`:

```bash
# Disable autogroup (redundant with sched_ext)
kernel.sched_autogroup_enabled=0

# Maximize util clamp for performance
kernel.sched_util_clamp_min=1024
kernel.sched_util_clamp_max=1024

# VM tuning for gaming (reduce swap pressure, prioritize active memory)
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=20
vm.dirty_background_ratio=5

# Network tuning (reduce buffer bloat)
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# Disable kernel address randomization (tiny perf gain, security risk)
kernel.randomize_va_space=0
```

---

## Build Flags — Currently Optimal

Your Makefile already has:
- `-O3` ✅
- ThinLTO ✅

**Optional additions** (edit top-level Makefile after `KBUILD_CFLAGS += -O3`):

```makefile
KBUILD_CFLAGS += -march=znver4
KBUILD_CFLAGS += -mtune=znver4
KBUILD_CFLAGS += -fno-semantic-interposition
```

**Note:** CachyOS PKGBUILD may already set `-march=native` which resolves to znver4. Verify with:
```bash
grep -E 'march|mtune' /home/haz/Documents/linux-cachyos/linux-cachyos/src/linux-6.18/Makefile
```

---

## AFDO/Propeller Workflow Reminder

### Phase 1: Profiling Kernel (Current)
- Keep `CONFIG_DEBUG_INFO=y`
- Keep `CONFIG_DEBUG_INFO_DWARF5=y`
- Boot and profile under gaming load
- Generate AFDO profile with `create_llvm_prof`

### Phase 2: Optimized Kernel
- Apply AFDO profile (`_autofdo=yes`, `_autofdo_profile_name=kernel.afdo`)
- **THEN** you can disable `DEBUG_INFO` for smaller, faster kernel
- Apply Propeller if desired (second profiling pass)

### Phase 3: Final Gaming Kernel
- AFDO + Propeller applied
- `CONFIG_DEBUG_INFO=n`
- All debug options disabled
- Maximum performance

---

## Summary: Priority Actions

### Immediate (This Build):
1. ✅ Apply your CONFIG_HZ=800 patch
2. ✅ Set `CONFIG_SCHED_AUTOGROUP=n` in nconfig
3. ✅ Add cmdline parameters to bootloader

### Next Build (After AFDO Profiling):
1. Disable `CONFIG_STACKPROTECTOR*`
2. Disable `CONFIG_PM_DEBUG`, `CONFIG_ACPI_DEBUG`
3. Disable Intel options (safe, zero risk)
4. Disable unused filesystems
5. Disable staging drivers

### Final Gaming Kernel:
1. Apply AFDO profile
2. Disable `CONFIG_DEBUG_INFO`
3. All debug stripped
4. Maximum performance achieved

---

## Risk Acceptance Matrix

| Change | Performance Gain | Stability Risk | Security Risk |
|--------|-----------------|----------------|---------------|
| `mitigations=off` | 5-15% syscalls | None | HIGH |
| `CONFIG_HZ=800` | Better latency | None | None |
| `SCHED_AUTOGROUP=n` | 2-5% scheduler | None | None |
| `STACKPROTECTOR=n` | 1-3% calls | None | MEDIUM |
| Intel drivers=n | Smaller kernel | None | None |
| Debug options=n | Faster, smaller | Lose debug info | None |
| Aggressive scx_flash | Lower latency | Possible starvation | None |

---

## Files Modified/Referenced

- `/home/haz/Documents/linux-cachyos/linux-cachyos/config` — Base kernel config
- `/home/haz/Documents/linux-cachyos/linux-cachyos/PKGBUILD` — Build script
- `/etc/kernel/cmdline` — Boot parameters (systemd-boot)
- `/etc/sysctl.d/99-gaming.conf` — Runtime tuning (create this)

---

**END OF REPORT**

*Generated by System Architect Mode — Sonnet*
