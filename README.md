# OpenWrt + UniFi Stack for Banana Pi BPI-R4 & BPI-R4 Pro 8X

**[🇬🇧 English](#english)** | **[🇹🇷 Türkçe](#türkçe)**

---

# English

Run **OpenWrt** on Banana Pi BPI-R4 and **BPI-R4 Pro 8X** (MT7988A, Wi-Fi 7) with an optional **UniFi Protect + UniFi Network Application** stack — a cost-effective alternative to the Ubiquiti UNVR + Cloud Gateway combo.

Complete install system that runs entirely on GitHub — no Linux machine needed.

> **Tested hardware:** Banana Pi R4 rev 1.0 (4GB) · Banana Pi R4 rev 1.1 (8GB) · Banana Pi R4 Pro 8X · UniFi G5 Flex camera · UniFi U7-LR WiFi 7 AP

> **This fork** additionally ships built-in support for **Fibocom / Intel XMM7360-based LTE (GSM) modems** — see [Fork additions — Fibocom / Intel LTE modem support](#fork-additions--fibocom--intel-lte-modem-support).

---

## Contents

- [Board variants](#board-variants)
- [DIP switch reference](#dip-switch-reference)
- [Part A — BPI-R4: Install](#part-a--bpi-r4-install)
  - [Step 1 — Flash the SD card](#step-1--flash-the-sd-card)
  - [Step 2 — Write the lean NAND installer](#step-2--write-the-lean-nand-installer)
  - [Step 3 — Install OpenWrt to NVMe](#step-3--install-openwrt-to-nvme)
  - [Step 3 alternative — Install to eMMC](#step-3-alternative--install-to-emmc)
- [Part B — BPI-R4: UniFi stack](#part-b--bpi-r4-unifi-stack)
- [Part C — BPI-R4 Pro 8X: Install](#part-c--bpi-r4-pro-8x-install)
  - [Step 1 — Flash SD card](#step-1--flash-sd-card)
  - [Step 2 — Install NAND system](#step-2--install-nand-system)
  - [Step 3 — Optional: Install to eMMC](#step-3--optional-install-to-emmc)
  - [Step 4 — Install OpenWrt to NVMe](#step-4--install-openwrt-to-nvme)
  - [Switching between NAND and NVMe](#switching-between-nand-and-nvme)
- [Part D — BPI-R4 Pro 8X: UniFi stack](#part-d--bpi-r4-pro-8x-unifi-stack)
- [Part E — Fork and customize](#part-e--fork-and-customize)
- [Fork additions — Fibocom / Intel LTE modem support](#fork-additions--fibocom--intel-lte-modem-support)
- [Architecture](#architecture)
- [NVMe partition layout](#nvme-partition-layout)
- [Hardware notes](#hardware-notes)
- [Known behaviors](#known-behaviors)

---

## Board variants

### BPI-R4

| # | Variant | RAM | WiFi | Notes |
|---|---------|-----|------|-------|
| 1 | 4GB standard | 4 GB | ✅ | Standard board |
| 2 | 4GB wired | 4 GB | ❌ | No WiFi, lower footprint |
| 3 | 4GB PoE | 4 GB | ✅ | BPI-R4 with 2.5GE PoE port |
| 4 | 4GB PoE wired | 4 GB | ❌ | PoE, no WiFi |
| 5 | 8GB standard | 8 GB | ✅ | 8 GB RAM board |
| 6 | 8GB wired | 8 GB | ❌ | 8 GB RAM, no WiFi |
| 7 | 8GB PoE | 8 GB | ✅ | 8 GB RAM, PoE |
| 8 | 8GB PoE wired | 8 GB | ❌ | 8 GB RAM, PoE, no WiFi |
| 9 | 8GB wired UniFi | 8 GB | ❌ | Pre-configured for UniFi Network + Protect |
| 10 | 8GB PoE wired UniFi | 8 GB | ❌ | PoE, pre-configured for UniFi |

> ⚠️ **UniFi variants (9, 10) require 8 GB RAM.** Running UniFi Network + Protect on 4 GB causes memory exhaustion.

### BPI-R4 Pro 8X

| Variant | RAM | WiFi | Notes |
|---------|-----|------|-------|
| Pro 8X WiFi | 8 GB | ✅ | BPI-R4 Pro 8X with WiFi 7 |
| Pro 8X wired | 8 GB | ❌ | BPI-R4 Pro 8X, no WiFi |

---

## DIP switch reference

| Boot medium | A | B |
|-------------|---|---|
| SD card     | 1 | 1 |
| NAND        | 0 | 1 |
| eMMC        | 1 | 0 |

> **NVMe boot** is controlled by U-Boot environment, not DIP switch. After running `install-nvme.sh`, the device boots from NVMe automatically — DIP stays at **NAND** (A=0, B=1) and is never changed again.

> NAND and eMMC are fully functional permanent options. NVMe is recommended for larger storage needs — required for the UniFi stack.

---

## Part A — BPI-R4: Install

The SD card is a **full, self-contained OpenWrt system**. It boots on its own and
ships the `/root/install-dir/` installer scripts. From there you write a small
"lean" installer to NAND, and the NAND system is what installs eMMC and NVMe.

> **Why go through NAND?** eMMC and the SD card share the same MMC controller, so
> eMMC cannot be written while you are booted from SD. Installing eMMC (and, for a
> consistent flow, NVMe) is therefore always done from the NAND system.

### Step 1 — Flash the SD card

1. Go to [Releases](https://github.com/dursuntokgoz/bpi-r4-deploy/releases) and pick the
   release for your **RAM variant**, then download its **SD image**:

   | RAM | Release | SD image |
   |---|---|---|
   | 4 GB | `release-4gb-standard` | `openwrt-mediatek-filogic-bananapi_bpi-r4-sdcard.img.gz` |
   | 8 GB | `release-8gb-standard` | `openwrt-mediatek-filogic-bananapi_bpi-r4-8gb-sdcard.img.gz` |

   > PoE boards use the `release-*-poe` tags and the matching `…-poe-…-sdcard.img.gz` image.

2. Flash it to a microSD card using [Balena Etcher](https://etcher.balena.io/).
3. Insert the SD card, set DIP **A=1, B=1** (SD boot) and power on.
4. Connect via SSH: `ssh root@192.168.1.1` (no password).

---

### Step 2 — Write the lean NAND installer

Run from the SD card:

```
/root/install-dir/install-nand.sh
```

Select your **RAM variant (4 GB or 8 GB)**, then choose the file source — download
from GitHub (default) or a local file in `/tmp` (development/testing).

After the script finishes:

1. Power off.
2. Set DIP **A=0, B=1** (NAND boot) and power on.
3. Connect via SSH: `ssh root@192.168.1.1`.

You are now on the NAND system, which is used to install eMMC and NVMe below.

---

### Step 3 — Install OpenWrt to NVMe

> Run this **from the NAND system** (DIP A=0, B=1).

> ⚠️ **If you want both NVMe and eMMC:** Run `install-emmc.sh` **before** `install-nvme.sh`. After NVMe installation the device always boots from NVMe.

Make sure a WAN cable is connected, then run:

```
/root/install-dir/install-nvme.sh
```

Select your **board variant** from the menu. The script checks NVMe health, downloads images (~150 MB), writes OpenWrt to NVMe and reboots automatically.

> **Updating** — to update OpenWrt on NVMe, boot into NAND (DIP A=0, B=1) and run `install-nvme.sh` again. Data on p3 is never touched.

---

### Step 3 alternative — Install to eMMC

> Must be run **from the NAND system** (DIP A=0, B=1). eMMC shares its controller
> with the SD card, so it cannot be written from the SD system.

```
/root/install-dir/install-emmc.sh
```

After installation set DIP **A=1, B=0** (eMMC boot) and power on.

---

## Part B — BPI-R4: UniFi stack

### What you need

- BPI-R4 **8 GB RAM** (rev 1.2+ recommended)
- NVMe SSD, minimum 500 GB (1 TB recommended for Continuous Recording)
- UniFi camera (G5 Flex tested) · UniFi AP (U7-LR WiFi 7 tested)
- A [Ubiquiti account](https://account.ui.com) (optional — required only for Remote Access)

| Service | Address |
|---------|---------|
| UniFi Protect | `https://192.168.1.1` |
| UniFi Network Application | `https://192.168.1.2:8443` |
| LuCI | `http://192.168.1.1:8081` |

---

### Step 4 — Install NVMe UniFi variant

Follow Steps 1–2 above, then run:

```
/root/install-dir/install-nvme.sh
```

Select variant **9** (8GB wired UniFi) or **10** (8GB PoE wired UniFi).

---

### Step 5 — Run UniFi Protect setup

> ⚠️ **Run from SSH terminal only — not from LuCI terminal (ttyd).** The script modifies the firewall and a ttyd session will be interrupted.

```
cd /mnt/nvme0n1p3
sh unifi-setup.sh
```

> ⚠️ When prompted, **disconnect the WAN cable** before pressing Enter.

---

### Step 6 — First-time Protect configuration

1. Open `https://192.168.1.1`.
2. Accept the SSL warning (self-signed certificate).
3. **Other Configuration Options → Local Network → Set Up Console Offline**.
4. Enter a console name, set a password, click **Finish**.

**Immediately disable auto-updates: Settings → Control Plane → Updates.**

---

### Step 7 — Run UniFi Network Application setup

Reconnect the WAN cable, then:

```
cd /mnt/nvme0n1p3
sh unifi-network-setup.sh
```

---

### Step 8 — First-time Network Application configuration

1. Open `https://192.168.1.2:8443`.
2. Complete the setup wizard.
3. **Settings → System** — disable auto-updates.

---

### Adding a camera

1. Connect the camera to a LAN port and power it on.
2. Hardware reset (hold reset button until LED changes).
3. Protect dashboard → **Devices** — camera appears for adoption.

---

### Adopting an Access Point

After factory reset the AP auto-discovers the Network Application via DNS (`unifi` → `192.168.1.2`). It appears as "Pending adoption" within a minute.

If auto-discovery fails (older firmware):

```
ssh ubnt@<AP_IP> "/usr/bin/syswrapper.sh set-inform http://192.168.1.2:8080/inform"
```

`<AP_IP>` visible in LuCI (`http://192.168.1.1:8081`) → Network → DHCP Leases. Default credentials: `ubnt` / `ubnt`

---

## Part C — BPI-R4 Pro 8X: Install

BPI-R4 Pro 8X uses a different SoC configuration, NAND layout, and device trees than the standard BPI-R4. **Pro 8X images are not compatible with standard BPI-R4 and vice versa.**

### What you need

- BPI-R4 Pro 8X board
- **NVMe SSD in slot CN14 (M-key), minimum 512 GB** — tested with Patriot P300 512 GB. CN15 and CN18 are B-key slots for LTE modems, not NVMe.
- microSD card (temporary, for install only)
- For WAN and LAN connectivity: SFP or SFP copper modules are recommended

---

### Step 1 — Flash SD card

1. Go to [Releases](https://github.com/dursuntokgoz/bpi-r4-deploy/releases) and download the SD card image from **release-pro-8x-wired** or **release-pro-8x-standard**:
   `openwrt-mediatek-filogic-bananapi_bpi-r4-pro-8x-sdcard.img.gz`
2. Flash to a microSD card using [Balena Etcher](https://etcher.balena.io/).
3. Insert SD card, set DIP **A=1, B=1** (SD boot) and power on.
4. Connect via SSH: `ssh root@192.168.1.1` (no password).

---

### Step 2 — Install NAND system

Connect the WAN cable, then run:

```
/root/install-dir/install-nand.sh
```

After the script finishes:

1. Power off.
2. Set DIP **A=0, B=1** (NAND boot) and power on.
3. Connect via SSH: `ssh root@192.168.1.1`.

---

### Step 3 — Optional: Install to eMMC

> ⚠️ **Run this before `install-nvme.sh`.** After NVMe installation the device always boots from NVMe.

```
/root/install-dir/install-emmc.sh
```

Select **1** (Pro 8X WiFi) or **2** (Pro 8X wired).

After installation set DIP **A=1, B=0** (eMMC boot) to use eMMC, or keep DIP at A=0, B=1 and continue with NVMe install.

---

### Step 4 — Install OpenWrt to NVMe

From the NAND system, connect the WAN cable and run:

```
/root/install-dir/install-nvme.sh
```

Select **1** (Pro 8X WiFi) or **2** (Pro 8X wired).

The script checks NVMe health, downloads images (~150 MB), writes OpenWrt to NVMe and reboots automatically.

**After reboot the router boots from NVMe.** DIP stays at A=0, B=1 permanently — this is correct.

---

### Switching between NAND and NVMe

```
boot-nand    # switch to NAND on next reboot
boot-nvme    # switch back to NVMe on next reboot
```

---

## Part D — BPI-R4 Pro 8X: UniFi stack

Pro 8X wired is ideal for running the UniFi stack — 8 GB RAM, NVMe storage, and no onboard WiFi interference.

### What you need

- BPI-R4 Pro 8X (wired variant recommended)
- NVMe SSD in slot CN14, **minimum 512 GB** (1 TB recommended for Continuous Recording)
- UniFi camera (G5 Flex tested) · UniFi AP (U7-LR WiFi 7 tested)
- A [Ubiquiti account](https://account.ui.com) (optional — required only for Remote Access)

| Service | Address |
|---------|---------|
| UniFi Protect | `https://192.168.1.1` |
| UniFi Network Application | `https://192.168.1.1:8443` |
| LuCI | `http://192.168.1.1:8080` |

---

### Step 4 — Install NVMe UniFi variant

Follow Part C Steps 1–2, then run:

```
/root/install-dir/install-nvme-unifi.sh
```

Select **1** (Pro 8X WiFi) or **2** (Pro 8X wired).

---

### Step 5 — Run UniFi Protect setup

> ⚠️ **Run from SSH terminal only — not from LuCI terminal (ttyd).** The script modifies the firewall and a ttyd session will be interrupted.

```
sh /mnt/nvme0n1p3/unifi-setup.sh
```

When asked to download or use a local file — select **[1] Download**. The script downloads the Docker image (~660 MB) and loads it automatically.

> ⚠️ When prompted, **disconnect the WAN cable** before pressing Enter.

---

### Step 6 — First-time Protect configuration

1. Open `https://192.168.1.1`.
2. Accept the SSL warning (self-signed certificate).
3. **Other Configuration Options → Local Network → Set Up Console Offline**.
4. Enter a console name, set a password, click **Finish**.

**Immediately disable auto-updates: Settings → General → Auto Update.**

---

### Step 7 — Run UniFi Network Application setup

Reconnect the WAN cable, then:

```
sh /mnt/nvme0n1p3/unifi-network-setup.sh
```

---

### Step 8 — First-time Network Application configuration

1. Open `https://192.168.1.1:8443`.
2. Complete the setup wizard.
3. **Settings → System** — disable auto-updates.

---

### Adding a camera and Access Point

Same procedure as Part B — see [Adding a camera](#adding-a-camera) and [Adopting an Access Point](#adopting-an-access-point).

---

## Part E — Fork and customize

Fork this repository to build your own customized release.

1. Fork on GitHub. **Do not rename the fork** — it must stay named `bpi-r4-deploy`.
2. Go to **Settings → Actions → General** → set **Workflow permissions** to **Read and write**.
3. Go to **Actions → Build BPI-R4 Pro 8X → Run workflow**, select **Pro-8X-wifi** or **Pro-8X-wired**.
4. After ~2 hours, releases appear in your fork.

To install from your fork, edit `GH_USER` at the top of the install scripts.

---

## Fork additions — Fibocom / Intel LTE modem support

This fork (`dursuntokgoz/bpi-r4-deploy`) extends the upstream project with built-in support for **Intel XMM7360 / XMM7560-based M.2 LTE (GSM) modems**, such as the **Fibocom L850-GL** (XMM7360) and **Fibocom L860-GL** (XMM7560). All build variants (standard, wired, Pro 8X, Pro 8X wired) include the components below out of the box. Install the modem in an M.2 **B-key** slot (CN15/CN18 on Pro 8X) with a SIM inserted.

### What's included

#### `kmod-iosm-custom` — Intel IOSM WWAN driver

Custom build of the Intel IOSM (IPC over Shared Memory) PCIe WWAN driver, kept in sync with the target kernel (6.12.x) and carrying an ARM64 fix (`iowrite64_lo_hi`) that prevents alignment faults on the MT7988A SoC. The module (`iosm.ko`) loads automatically at boot, binds to PCI IDs `8086:7360` and `8086:7560`, and exposes the `/dev/wwan0*` control ports plus the `wwan0` network interface.

#### `xmm7360-daemon-full.py` — connection daemon

Python 3 connection daemon (`/usr/bin/xmm7360-daemon-full.py`) for XMM7360 modems. It speaks the modem's RPC protocol over `/dev/wwan0xmmrpc0` (or `/dev/xmm0/rpc`), configures the APN, brings up `wwan0`, auto-reconnects on failure, and logs to `/var/log/xmm7360-daemon.log`. The images include `python3` / `python3-light` to run it.

#### `xmm2usb` — PCIe → USB mode switch

Helper script (`/usr/bin/xmm2usb`) that switches an XMM7360 modem from PCIe to USB mode: it locates the modem (PCI `8086:7360`), disables the PCIe link via `setpci`, and issues an ACPI `_RST` through the `acpi_call` module. Useful when you prefer to drive the modem over USB instead of the PCIe/IOSM stack.

### Quick start

```
# 1) Verify the modem is detected:
lspci | grep -i 7360        # or: dmesg | grep -i iosm

# 2) Connect with your carrier's APN:
xmm7360-daemon-full.py --apn internet

# Options:
#   --apn <apn>       APN to use
#   --no-reconnect    Disable auto-reconnect
#   --debug           Verbose logging
```

Once connected, the `wwan0` interface gets its IP from the carrier; add it to a WAN firewall zone in LuCI as needed. Logs: `/var/log/xmm7360-daemon.log`.

### Turkish LuCI interface

The standard and wired images also ship the **Turkish (tr) LuCI language packs** (`luci-i18n-*-tr`) for the web interface and all bundled apps that provide a Turkish translation (firewall, statistics, SQM, QoS, ksmbd, ttyd, package manager, mwan3 and more). LuCI follows the browser language automatically; to force it, go to **System → Language and Style → Language → Türkçe**.

---

## Architecture

| Component | Role |
|-----------|------|
| BPI-R4 / Pro 8X | Routing, firewall, Docker runtime, NVMe storage |
| UniFi Protect | Camera management ([dciancu](https://github.com/dciancu/unifi-protect-unvr-docker-arm64) Docker image) |
| UniFi Network Application | WiFi management (linuxserver Docker image) |
| UniFi AP | Professional WiFi (U7-LR WiFi 7 tested) |

---

## NVMe partition layout

| Partition | Size | Purpose |
|-----------|------|---------|
| p1 | 256 MB | Boot (kernel) |
| p2 | 512 MB | Root filesystem |
| p3 | remainder | Data / Docker / UniFi storage |

---

## Hardware notes

### BPI-R4 rev 1.0 known issues

| Issue | Details |
|-------|---------|
| NVMe + SFP conflict | Some NVMe disks pull down the I2C bus, disabling SFP ports |
| Affected disks | Chinese OEM NVMe drives (e.g. generic 128 GB) |
| Not affected | Samsung EVO series |
| Fixed in | Rev 1.2+ |

For new builds, **BPI-R4 8 GB RAM rev 1.2+** is recommended.

---

## Known behaviors

### Boot time

After a cold boot or reboot, allow approximately **4–5 minutes** for the router to become fully operational.

Approximate timeline:
- ~1 min — router reachable via SSH/LuCI
- ~3 min — UniFi Protect available
- ~8–10 min — UniFi Network Application fully initialized

### WAN reconnect

When WAN goes down and comes back up, the installed hotplug handler (`99-docker-nft`) restores Docker nftables rules automatically — no reboot needed.

### NAND first boot — UBI messages

On the very first boot into the NAND system, U-Boot may print messages like:

```
UBI: Bad EC magic in block XXXX
```

This is normal — U-Boot is initializing the NAND flash. The messages disappear on subsequent boots.

### GitHub runner disk space

If a build fails with a disk-related error, re-run the workflow — runners with sufficient space are usually available shortly.

---

# Türkçe

Banana Pi BPI-R4 ve **BPI-R4 Pro 8X** (MT7988A, Wi-Fi 7) üzerinde **OpenWrt** çalıştırın; isteğe bağlı **UniFi Protect + UniFi Network Application** yığını ile — Ubiquiti UNVR + Cloud Gateway ikilisine uygun maliyetli bir alternatif.

Tamamen GitHub üzerinde çalışan eksiksiz kurulum sistemi — Linux makinesine gerek yok.

> **Test edilen donanım:** Banana Pi R4 rev 1.0 (4GB) · Banana Pi R4 rev 1.1 (8GB) · Banana Pi R4 Pro 8X · UniFi G5 Flex kamera · UniFi U7-LR WiFi 7 AP

> **Bu fork**, ayrıca **Fibocom / Intel XMM7360 tabanlı LTE (GSM) modemler** için yerleşik destek içerir — bkz. [Fork eklentileri — Fibocom / Intel LTE modem desteği](#fork-eklentileri--fibocom--intel-lte-modem-desteği).

---

## İçindekiler

- [Kart varyantları](#kart-varyantları)
- [DIP switch referansı](#dip-switch-referansı)
- [Bölüm A — BPI-R4: Kurulum](#bölüm-a--bpi-r4-kurulum)
  - [Adım 1 — SD kartı yazdırma](#adım-1--sd-kartı-yazdırma)
  - [Adım 2 — Hafif NAND kurucusunu yazma](#adım-2--hafif-nand-kurucusunu-yazma)
  - [Adım 3 — OpenWrt'yi NVMe'ye kurma](#adım-3--openwrtyi-nvmeye-kurma)
  - [Adım 3 alternatifi — eMMC'ye kurulum](#adım-3-alternatifi--emmcye-kurulum)
- [Bölüm B — BPI-R4: UniFi yığını](#bölüm-b--bpi-r4-unifi-yığını)
- [Bölüm C — BPI-R4 Pro 8X: Kurulum](#bölüm-c--bpi-r4-pro-8x-kurulum)
  - [Adım 1 — SD kartı yazdırma (Pro 8X)](#adım-1--sd-kartı-yazdırma-pro-8x)
  - [Adım 2 — NAND sistemini kurma](#adım-2--nand-sistemini-kurma)
  - [Adım 3 — Opsiyonel: eMMC'ye kurulum](#adım-3--opsiyonel-emmcye-kurulum)
  - [Adım 4 — OpenWrt'yi NVMe'ye kurma](#adım-4--openwrtyi-nvmeye-kurma)
  - [NAND ile NVMe arasında geçiş](#nand-ile-nvme-arasında-geçiş)
- [Bölüm D — BPI-R4 Pro 8X: UniFi yığını](#bölüm-d--bpi-r4-pro-8x-unifi-yığını)
- [Bölüm E — Fork'lama ve özelleştirme](#bölüm-e--forklama-ve-özelleştirme)
- [Fork eklentileri — Fibocom / Intel LTE modem desteği](#fork-eklentileri--fibocom--intel-lte-modem-desteği)
- [Mimari](#mimari)
- [NVMe bölümleme düzeni](#nvme-bölümleme-düzeni)
- [Donanım notları](#donanım-notları)
- [Bilinen davranışlar](#bilinen-davranışlar)

---

## Kart varyantları

### BPI-R4 varyantları

| # | Varyant | RAM | WiFi | Notlar |
|---|---------|-----|------|--------|
| 1 | 4GB standard | 4 GB | ✅ | Standart kart |
| 2 | 4GB wired | 4 GB | ❌ | WiFi yok, daha düşük kaynak kullanımı |
| 3 | 4GB PoE | 4 GB | ✅ | 2.5GE PoE portlu BPI-R4 |
| 4 | 4GB PoE wired | 4 GB | ❌ | PoE, WiFi yok |
| 5 | 8GB standard | 8 GB | ✅ | 8 GB RAM'li kart |
| 6 | 8GB wired | 8 GB | ❌ | 8 GB RAM, WiFi yok |
| 7 | 8GB PoE | 8 GB | ✅ | 8 GB RAM, PoE |
| 8 | 8GB PoE wired | 8 GB | ❌ | 8 GB RAM, PoE, WiFi yok |
| 9 | 8GB wired UniFi | 8 GB | ❌ | UniFi Network + Protect için önceden yapılandırılmış |
| 10 | 8GB PoE wired UniFi | 8 GB | ❌ | PoE, UniFi için önceden yapılandırılmış |

> ⚠️ **UniFi varyantları (9, 10) 8 GB RAM gerektirir.** UniFi Network + Protect'i 4 GB üzerinde çalıştırmak bellek tükenmesine yol açar.

### BPI-R4 Pro 8X varyantları

| Varyant | RAM | WiFi | Notlar |
|---------|-----|------|--------|
| Pro 8X WiFi | 8 GB | ✅ | WiFi 7'li BPI-R4 Pro 8X |
| Pro 8X wired | 8 GB | ❌ | BPI-R4 Pro 8X, WiFi yok |

---

## DIP switch referansı

| Önyükleme ortamı | A | B |
|------------------|---|---|
| SD kart          | 1 | 1 |
| NAND             | 0 | 1 |
| eMMC             | 1 | 0 |

> **NVMe önyüklemesi** DIP switch ile değil, U-Boot ortam değişkenleriyle kontrol edilir. `install-nvme.sh` çalıştırıldıktan sonra cihaz otomatik olarak NVMe'den açılır — DIP **NAND** konumunda (A=0, B=1) kalır ve bir daha değiştirilmez.

> NAND ve eMMC tam işlevsel kalıcı seçeneklerdir. Daha büyük depolama ihtiyaçları için NVMe önerilir — UniFi yığını için zorunludur.

---

## Bölüm A — BPI-R4: Kurulum

SD kart, **eksiksiz ve kendi kendine yeten bir OpenWrt sistemidir**. Kendi başına açılır ve
`/root/install-dir/` kurulum betiklerini içerir. Buradan NAND'a küçük, "hafif" bir kurucu
yazarsınız; eMMC ve NVMe kurulumlarını yapan da bu NAND sistemidir.

> **Neden NAND üzerinden?** eMMC ile SD kart aynı MMC denetleyicisini paylaşır; bu yüzden
> SD'den açılmışken eMMC'ye yazılamaz. eMMC kurulumu (ve akışın tutarlı olması için NVMe
> kurulumu) bu nedenle her zaman NAND sisteminden yapılır.

### Adım 1 — SD kartı yazdırma

1. [Releases](https://github.com/dursuntokgoz/bpi-r4-deploy/releases) sayfasına gidin,
   **RAM varyantınıza** uygun sürümü seçin ve **SD imajını** indirin:

   | RAM | Sürüm | SD imajı |
   |---|---|---|
   | 4 GB | `release-4gb-standard` | `openwrt-mediatek-filogic-bananapi_bpi-r4-sdcard.img.gz` |
   | 8 GB | `release-8gb-standard` | `openwrt-mediatek-filogic-bananapi_bpi-r4-8gb-sdcard.img.gz` |

   > PoE kartlar `release-*-poe` etiketlerini ve eşleşen `…-poe-…-sdcard.img.gz` imajını kullanır.

2. [Balena Etcher](https://etcher.balena.io/) ile bir microSD karta yazdırın.
3. SD kartı takın, DIP'i **A=1, B=1** (SD önyükleme) yapın ve cihazı açın.
4. SSH ile bağlanın: `ssh root@192.168.1.1` (parola yok).

---

### Adım 2 — Hafif NAND kurucusunu yazma

SD kart üzerinden çalıştırın:

```
/root/install-dir/install-nand.sh
```

**RAM varyantınızı (4 GB veya 8 GB)** seçin, ardından dosya kaynağını belirleyin —
GitHub'dan indirme (varsayılan) veya `/tmp` içindeki yerel dosya (geliştirme/test).

Betik tamamlandıktan sonra:

1. Cihazı kapatın.
2. DIP'i **A=0, B=1** (NAND önyükleme) yapın ve cihazı açın.
3. SSH ile bağlanın: `ssh root@192.168.1.1`.

Artık NAND sistemindesiniz; aşağıdaki eMMC ve NVMe kurulumları bu sistemden yapılır.

---

### Adım 3 — OpenWrt'yi NVMe'ye kurma

> Bunu **NAND sisteminden** çalıştırın (DIP A=0, B=1).

> ⚠️ **Hem NVMe hem eMMC istiyorsanız:** `install-emmc.sh` betiğini `install-nvme.sh`'ten **önce** çalıştırın. NVMe kurulumundan sonra cihaz her zaman NVMe'den açılır.

WAN kablosunun takılı olduğundan emin olun, ardından çalıştırın:

```
/root/install-dir/install-nvme.sh
```

Menüden **kart varyantınızı** seçin. Betik NVMe sağlığını kontrol eder, imajları indirir (~150 MB), OpenWrt'yi NVMe'ye yazar ve otomatik olarak yeniden başlatır.

> **Güncelleme** — NVMe üzerindeki OpenWrt'yi güncellemek için NAND'a önyükleyin (DIP A=0, B=1) ve `install-nvme.sh`'i tekrar çalıştırın. p3 üzerindeki verilere asla dokunulmaz.

---

### Adım 3 alternatifi — eMMC'ye kurulum

> **NAND sisteminden** çalıştırılmalıdır (DIP A=0, B=1). eMMC, denetleyicisini SD kart
> ile paylaştığından SD sisteminden yazılamaz.

```
/root/install-dir/install-emmc.sh
```

Kurulumdan sonra DIP'i **A=1, B=0** (eMMC önyükleme) yapın ve cihazı açın.

---

## Bölüm B — BPI-R4: UniFi yığını

### Gerekenler

- BPI-R4 **8 GB RAM** (rev 1.2+ önerilir)
- NVMe SSD, en az 500 GB (Sürekli Kayıt için 1 TB önerilir)
- UniFi kamera (G5 Flex test edildi) · UniFi AP (U7-LR WiFi 7 test edildi)
- Bir [Ubiquiti hesabı](https://account.ui.com) (opsiyonel — yalnızca Remote Access için gerekli)

| Servis | Adres |
|--------|-------|
| UniFi Protect | `https://192.168.1.1` |
| UniFi Network Application | `https://192.168.1.2:8443` |
| LuCI | `http://192.168.1.1:8081` |

---

### Adım 4 — NVMe UniFi varyantını kurma

Yukarıdaki Adım 1–2'yi izleyin, ardından çalıştırın:

```
/root/install-dir/install-nvme.sh
```

Varyant **9** (8GB wired UniFi) veya **10** (8GB PoE wired UniFi) seçin.

---

### Adım 5 — UniFi Protect kurulumunu çalıştırma

> ⚠️ **Yalnızca SSH terminalinden çalıştırın — LuCI terminalinden (ttyd) değil.** Betik güvenlik duvarını değiştirir ve ttyd oturumu kesintiye uğrar.

```
cd /mnt/nvme0n1p3
sh unifi-setup.sh
```

> ⚠️ İstendiğinde, Enter'a basmadan önce **WAN kablosunu çıkarın**.

---

### Adım 6 — Protect'in ilk yapılandırması

1. `https://192.168.1.1` adresini açın.
2. SSL uyarısını kabul edin (kendinden imzalı sertifika).
3. **Other Configuration Options → Local Network → Set Up Console Offline**.
4. Bir konsol adı girin, parola belirleyin, **Finish**'e tıklayın.

**Otomatik güncellemeleri hemen kapatın: Settings → Control Plane → Updates.**

---

### Adım 7 — UniFi Network Application kurulumunu çalıştırma

WAN kablosunu yeniden takın, ardından:

```
cd /mnt/nvme0n1p3
sh unifi-network-setup.sh
```

---

### Adım 8 — Network Application'ın ilk yapılandırması

1. `https://192.168.1.2:8443` adresini açın.
2. Kurulum sihirbazını tamamlayın.
3. **Settings → System** — otomatik güncellemeleri kapatın.

---

### Kamera ekleme

1. Kamerayı bir LAN portuna bağlayın ve gücünü verin.
2. Donanımsal sıfırlama yapın (LED değişene kadar reset düğmesine basılı tutun).
3. Protect panosu → **Devices** — kamera benimsemeye (adoption) hazır olarak görünür.

---

### Access Point'i benimsetme

Fabrika ayarlarına sıfırlamadan sonra AP, Network Application'ı DNS üzerinden otomatik keşfeder (`unifi` → `192.168.1.2`). Bir dakika içinde "Pending adoption" olarak görünür.

Otomatik keşif başarısız olursa (eski firmware):

```
ssh ubnt@<AP_IP> "/usr/bin/syswrapper.sh set-inform http://192.168.1.2:8080/inform"
```

`<AP_IP>` adresi LuCI'de (`http://192.168.1.1:8081`) → Network → DHCP Leases altında görünür. Varsayılan kimlik bilgileri: `ubnt` / `ubnt`

---

## Bölüm C — BPI-R4 Pro 8X: Kurulum

BPI-R4 Pro 8X, standart BPI-R4'ten farklı bir SoC yapılandırması, NAND düzeni ve device tree kullanır. **Pro 8X imajları standart BPI-R4 ile uyumlu değildir; tersi de geçerlidir.**

### Gerekenler

- BPI-R4 Pro 8X kart
- **CN14 (M-key) yuvasında NVMe SSD, en az 512 GB** — Patriot P300 512 GB ile test edildi. CN15 ve CN18, LTE modemler için B-key yuvalardır, NVMe için değildir.
- microSD kart (geçici, yalnızca kurulum için)
- WAN ve LAN bağlantısı için: SFP veya SFP bakır modüller önerilir

---

### Adım 1 — SD kartı yazdırma (Pro 8X)

1. [Releases](https://github.com/dursuntokgoz/bpi-r4-deploy/releases) sayfasından **release-pro-8x-wired** veya **release-pro-8x-standard** sürümündeki SD kart imajını indirin:
   `openwrt-mediatek-filogic-bananapi_bpi-r4-pro-8x-sdcard.img.gz`
2. [Balena Etcher](https://etcher.balena.io/) ile bir microSD karta yazdırın.
3. SD kartı takın, DIP'i **A=1, B=1** (SD önyükleme) yapın ve cihazı açın.
4. SSH ile bağlanın: `ssh root@192.168.1.1` (parola yok).

---

### Adım 2 — NAND sistemini kurma

WAN kablosunu bağlayın, ardından çalıştırın:

```
/root/install-dir/install-nand.sh
```

Betik tamamlandıktan sonra:

1. Cihazı kapatın.
2. DIP'i **A=0, B=1** (NAND önyükleme) yapın ve cihazı açın.
3. SSH ile bağlanın: `ssh root@192.168.1.1`.

---

### Adım 3 — Opsiyonel: eMMC'ye kurulum

> ⚠️ **Bunu `install-nvme.sh`'ten önce çalıştırın.** NVMe kurulumundan sonra cihaz her zaman NVMe'den açılır.

```
/root/install-dir/install-emmc.sh
```

**1** (Pro 8X WiFi) veya **2** (Pro 8X wired) seçin.

Kurulumdan sonra eMMC kullanmak için DIP'i **A=1, B=0** (eMMC önyükleme) yapın veya DIP'i A=0, B=1'de bırakıp NVMe kurulumuyla devam edin.

---

### Adım 4 — OpenWrt'yi NVMe'ye kurma

NAND sisteminden, WAN kablosunu bağlayın ve çalıştırın:

```
/root/install-dir/install-nvme.sh
```

**1** (Pro 8X WiFi) veya **2** (Pro 8X wired) seçin.

Betik NVMe sağlığını kontrol eder, imajları indirir (~150 MB), OpenWrt'yi NVMe'ye yazar ve otomatik olarak yeniden başlatır.

**Yeniden başlatmadan sonra yönlendirici NVMe'den açılır.** DIP kalıcı olarak A=0, B=1'de kalır — bu doğrudur.

---

### NAND ile NVMe arasında geçiş

```
boot-nand    # bir sonraki açılışta NAND'a geç
boot-nvme    # bir sonraki açılışta NVMe'ye geri dön
```

---

## Bölüm D — BPI-R4 Pro 8X: UniFi yığını

Pro 8X wired, UniFi yığınını çalıştırmak için idealdir — 8 GB RAM, NVMe depolama ve dahili WiFi girişimi yok.

### Gerekenler (Pro 8X)

- BPI-R4 Pro 8X (wired varyantı önerilir)
- CN14 yuvasında NVMe SSD, **en az 512 GB** (Sürekli Kayıt için 1 TB önerilir)
- UniFi kamera (G5 Flex test edildi) · UniFi AP (U7-LR WiFi 7 test edildi)
- Bir [Ubiquiti hesabı](https://account.ui.com) (opsiyonel — yalnızca Remote Access için gerekli)

| Servis | Adres |
|--------|-------|
| UniFi Protect | `https://192.168.1.1` |
| UniFi Network Application | `https://192.168.1.1:8443` |
| LuCI | `http://192.168.1.1:8080` |

---

### Adım 4 — NVMe UniFi varyantını kurma (Pro 8X)

Bölüm C Adım 1–2'yi izleyin, ardından çalıştırın:

```
/root/install-dir/install-nvme-unifi.sh
```

**1** (Pro 8X WiFi) veya **2** (Pro 8X wired) seçin.

---

### Adım 5 — UniFi Protect kurulumunu çalıştırma (Pro 8X)

> ⚠️ **Yalnızca SSH terminalinden çalıştırın — LuCI terminalinden (ttyd) değil.** Betik güvenlik duvarını değiştirir ve ttyd oturumu kesintiye uğrar.

```
sh /mnt/nvme0n1p3/unifi-setup.sh
```

İndirme veya yerel dosya kullanma sorulduğunda — **[1] Download** seçin. Betik Docker imajını (~660 MB) indirir ve otomatik olarak yükler.

> ⚠️ İstendiğinde, Enter'a basmadan önce **WAN kablosunu çıkarın**.

---

### Adım 6 — Protect'in ilk yapılandırması (Pro 8X)

1. `https://192.168.1.1` adresini açın.
2. SSL uyarısını kabul edin (kendinden imzalı sertifika).
3. **Other Configuration Options → Local Network → Set Up Console Offline**.
4. Bir konsol adı girin, parola belirleyin, **Finish**'e tıklayın.

**Otomatik güncellemeleri hemen kapatın: Settings → General → Auto Update.**

---

### Adım 7 — UniFi Network Application kurulumunu çalıştırma (Pro 8X)

WAN kablosunu yeniden takın, ardından:

```
sh /mnt/nvme0n1p3/unifi-network-setup.sh
```

---

### Adım 8 — Network Application'ın ilk yapılandırması (Pro 8X)

1. `https://192.168.1.1:8443` adresini açın.
2. Kurulum sihirbazını tamamlayın.
3. **Settings → System** — otomatik güncellemeleri kapatın.

---

### Kamera ve Access Point ekleme

Bölüm B ile aynı prosedür — bkz. [Kamera ekleme](#kamera-ekleme) ve [Access Point'i benimsetme](#access-pointi-benimsetme).

---

## Bölüm E — Fork'lama ve özelleştirme

Kendi özelleştirilmiş sürümünüzü derlemek için bu depoyu fork'layın.

1. GitHub'da fork'layın. **Fork'un adını değiştirmeyin** — `bpi-r4-deploy` olarak kalmalıdır.
2. **Settings → Actions → General** → **Workflow permissions** ayarını **Read and write** yapın.
3. **Actions → Build BPI-R4 Pro 8X → Run workflow**'a gidin, **Pro-8X-wifi** veya **Pro-8X-wired** seçin.
4. Yaklaşık 2 saat sonra sürümler fork'unuzda görünür.

Kendi fork'unuzdan kurulum yapmak için kurulum betiklerinin en üstündeki `GH_USER` değişkenini düzenleyin.

---

## Fork eklentileri — Fibocom / Intel LTE modem desteği

Bu fork (`dursuntokgoz/bpi-r4-deploy`), upstream projeye **Intel XMM7360 / XMM7560 tabanlı M.2 LTE (GSM) modemler** için yerleşik destek ekler — örneğin **Fibocom L850-GL** (XMM7360) ve **Fibocom L860-GL** (XMM7560). Tüm build varyantları (standard, wired, Pro 8X, Pro 8X wired) aşağıdaki bileşenleri hazır olarak içerir. Modemi, SIM takılı şekilde M.2 **B-key** yuvasına (Pro 8X'te CN15/CN18) takın.

### Neler içerir

#### `kmod-iosm-custom` — Intel IOSM WWAN sürücüsü

Intel IOSM (IPC over Shared Memory) PCIe WWAN sürücüsünün özel derlemesi; hedef kernel (6.12.x) ile senkron tutulur ve MT7988A SoC üzerinde hizalama hatalarını (alignment fault) önleyen ARM64 düzeltmesi (`iowrite64_lo_hi`) içerir. Modül (`iosm.ko`) açılışta otomatik yüklenir, `8086:7360` ve `8086:7560` PCI kimliklerine bağlanır; `/dev/wwan0*` kontrol portlarını ve `wwan0` ağ arayüzünü sağlar.

#### `xmm7360-daemon-full.py` — bağlantı daemon'u

XMM7360 modemler için Python 3 bağlantı daemon'u (`/usr/bin/xmm7360-daemon-full.py`). `/dev/wwan0xmmrpc0` (veya `/dev/xmm0/rpc`) üzerinden modemin RPC protokolüyle konuşur, APN'i yapılandırır, `wwan0` arayüzünü ayağa kaldırır, hata durumunda otomatik yeniden bağlanır ve `/var/log/xmm7360-daemon.log` dosyasına log yazar. İmajlar, daemon'u çalıştırmak için `python3` / `python3-light` paketlerini içerir.

#### `xmm2usb` — PCIe → USB mod geçişi

XMM7360 modemi PCIe modundan USB moduna geçiren yardımcı betik (`/usr/bin/xmm2usb`): modemi bulur (PCI `8086:7360`), `setpci` ile PCIe bağlantısını devre dışı bırakır ve `acpi_call` modülü üzerinden ACPI `_RST` komutu gönderir. Modemi PCIe/IOSM yığını yerine USB üzerinden kullanmak istediğinizde işe yarar.

### Hızlı başlangıç

```
# 1) Modemin algılandığını doğrulayın:
lspci | grep -i 7360        # veya: dmesg | grep -i iosm

# 2) Operatörünüzün APN'i ile bağlanın:
xmm7360-daemon-full.py --apn internet

# Seçenekler:
#   --apn <apn>       Kullanılacak APN
#   --no-reconnect    Otomatik yeniden bağlanmayı kapatır
#   --debug           Ayrıntılı log
```

Bağlantı kurulduğunda `wwan0` arayüzü IP adresini operatörden alır; gerekirse LuCI üzerinden bir WAN firewall bölgesine ekleyin. Loglar: `/var/log/xmm7360-daemon.log`.

### Türkçe LuCI arayüzü

Standard ve wired imajları, web arayüzü ve Türkçe çevirisi bulunan tüm paketler için **Türkçe (tr) LuCI dil paketlerini** (`luci-i18n-*-tr`) de içerir (firewall, statistics, SQM, QoS, ksmbd, ttyd, paket yöneticisi, mwan3 ve daha fazlası). LuCI, tarayıcı dilini otomatik takip eder; elle seçmek için **System → Language and Style → Language → Türkçe** yolunu kullanın.

---

## Mimari

| Bileşen | Rol |
|---------|-----|
| BPI-R4 / Pro 8X | Yönlendirme, güvenlik duvarı, Docker çalışma ortamı, NVMe depolama |
| UniFi Protect | Kamera yönetimi ([dciancu](https://github.com/dciancu/unifi-protect-unvr-docker-arm64) Docker imajı) |
| UniFi Network Application | WiFi yönetimi (linuxserver Docker imajı) |
| UniFi AP | Profesyonel WiFi (U7-LR WiFi 7 test edildi) |

---

## NVMe bölümleme düzeni

| Bölüm | Boyut | Amaç |
|-------|-------|------|
| p1 | 256 MB | Önyükleme (kernel) |
| p2 | 512 MB | Kök dosya sistemi |
| p3 | kalan alan | Veri / Docker / UniFi depolama |

---

## Donanım notları

### BPI-R4 rev 1.0 bilinen sorunlar

| Sorun | Ayrıntılar |
|-------|-----------|
| NVMe + SFP çakışması | Bazı NVMe diskler I2C veri yolunu aşağı çekerek SFP portlarını devre dışı bırakır |
| Etkilenen diskler | Çin menşeli OEM NVMe sürücüler (ör. jenerik 128 GB) |
| Etkilenmeyenler | Samsung EVO serisi |
| Düzeltildiği sürüm | Rev 1.2+ |

Yeni kurulumlar için **BPI-R4 8 GB RAM rev 1.2+** önerilir.

---

## Bilinen davranışlar

### Açılış süresi

Soğuk açılış veya yeniden başlatma sonrasında yönlendiricinin tamamen çalışır hale gelmesi için yaklaşık **4–5 dakika** bekleyin.

Yaklaşık zaman çizelgesi:
- ~1 dk — yönlendiriciye SSH/LuCI ile erişilebilir
- ~3 dk — UniFi Protect kullanılabilir
- ~8–10 dk — UniFi Network Application tamamen başlatılmış olur

### WAN yeniden bağlanması

WAN bağlantısı kesilip geri geldiğinde, kurulu hotplug işleyicisi (`99-docker-nft`) Docker nftables kurallarını otomatik olarak geri yükler — yeniden başlatma gerekmez.

### NAND ilk açılışı — UBI mesajları

NAND sistemine ilk açılışta U-Boot şuna benzer mesajlar yazdırabilir:

```
UBI: Bad EC magic in block XXXX
```

Bu normaldir — U-Boot, NAND flaşı ilklendirmektedir. Mesajlar sonraki açılışlarda kaybolur.

### GitHub runner disk alanı

Bir derleme diskle ilgili bir hatayla başarısız olursa workflow'u yeniden çalıştırın — yeterli alana sahip runner'lar genellikle kısa süre içinde müsait olur.

---

<img width="1264" height="1080" alt="UniFi Protect dashboard" src="https://github.com/user-attachments/assets/1483d00f-839a-4ced-b899-6d688e0483a7" />

<img width="1264" height="1080" alt="UniFi Network Application" src="https://github.com/user-attachments/assets/f912c22e-a31c-42e6-8fc7-34e1632a8bc7" />

<img width="1264" height="1080" alt="LuCI dashboard" src="https://github.com/user-attachments/assets/ae709b45-ad2a-44ff-ab7b-73b9d5f1d6d9" />

<img width="1264" height="1080" alt="UniFi camera view" src="https://github.com/user-attachments/assets/b6ce49af-bd91-4a67-87b2-c77ee121f051" />

---

*This project is not affiliated with Ubiquiti Inc. in any way. / Bu proje hiçbir şekilde Ubiquiti Inc. ile bağlantılı değildir.*

*🍌 TEAM WOZIWRT+CLAUDE*
