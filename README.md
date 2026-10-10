English | [中文](README.zh-CN.md)

# STM32F103C8T6 CMSIS-DAP_SWO Debug Probe Firmware

CMSIS-DAP debug probe firmware for the STM32F103C8T6 (Cortex-M3, 64 KB Flash /
20 KB RAM — the "Blue Pill" board). Plug it into USB and host tools (Keil,
OpenOCD, pyOCD, IAR, …) recognise it as a standard CMSIS-DAP probe for SWD /
JTAG debugging, with SWO trace and a USB virtual COM port (CDC) on top.

Derived from [x893/CMSIS-DAP](https://github.com/x893/CMSIS-DAP) and the
improvements by RadioOperator (CMSIS-DAP protocol v2.00, SWO_UART, better CDC,
additional board variants).

> **⚠️ Licensing — please read before redistributing.** The code added by this
> project is Apache-2.0, but **the repository as a whole is not a pure
> Apache-2.0 project.** It bundles code from Arm, STMicroelectronics and Keil
> under their own terms — including four files that carry *no open-source grant*
> at all, and ST code restricted to use with ST microcontrollers. See
> [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) for the full picture, or the
> [License](#license) section below for a summary.

## Features

- **SWD and JTAG** debug modes (SWD by default)
- **SWO trace** via SWO_UART mode (uses USART1) — `printf` from the target
- **CDC virtual COM port** (uses USART2) — an extra serial port over the same USB
  cable, wired to the target's UART
- **Spec-compliant nRESET timing** — nRESET is a plain pin operation, so
  connect-under-reset works (required by STM32H7 / F7 targets)
- USB composite device: HID (CMSIS-DAP channel) + CDC ACM (virtual COM port)

## Pinout

The default CMake build is **BLUEPILL without SWD_REMAP** (macros
`STM32F10X_MD BLUEPILL SWO_PB7`). All pin definitions live in
`src/dap/DAP_config.h`.

### Debug connector (to the target board)

| MCU pin | SWD mode | JTAG mode | Notes |
|---------|----------|-----------|-------|
| **PB9** | SWDIO | JTMS | Data |
| **PB8** | SWCLK | JTCK | Clock |
| **PB7** | SWO | JTDO | SWO trace input / JTAG TDO (remapped USART1_RX internally) |
| **PB6** | nRESET | nRESET | Target reset (output) |
| **PB5** | — | JTDI | JTAG data in (JTAG mode only) |
| — | — | nTRST | Not supported |

> Share a common ground: the probe's GND must be connected to the target's GND.

### Serial port (CDC, to the target's UART)

| MCU pin | Function | Notes |
|---------|----------|-------|
| **PA2** | USART2_TX | To target RX |
| **PA3** | USART2_RX | To target TX |

### USB and indicators

| MCU pin | Function | Notes |
|---------|----------|-------|
| PA11 | USB D− | To the USB connector |
| PA12 | USB D+ | To the USB connector (the Blue Pill has a fixed 1.5 kΩ pull-up) |
| PB15 | USB connect control | Optional, active low. Used when D+ pull-up is switched by an external MOSFET/transistor; leave unconnected if the pull-up is hard-wired |
| PC13 | Status LED | Active low (Blue Pill on-board LED). Slow blink: waiting for connection; fast blink: CDC activity; blinks per state during debug transfers |
| PB12 | Reserved | Configured as floating input at start-up, only for DAPLink wiring compatibility |

### SWD_REMAP vs. unRemap

`src/dap/DAP_config.h` offers two pin schemes for the Blue Pill (see
`docs/Bluepill/`), selected with the CMake `SWD_REMAP` option:

| Signal | unRemap (default) | SWD_REMAP (`cmake -B build_gcc -DSWD_REMAP=ON`) |
|--------|-------------------|------------------------------------------------|
| SWDIO / JTMS | PB9 | PA13 |
| SWCLK / JTCK | PB8 | PA14 |
| Other pins | same (PB7 / PB6 / PB5) | same |

SWD_REMAP puts the outgoing debug signals on the Blue Pill's own 4-pin SWD
header, which is convenient to wire. The cost is that the firmware executes
`AFIO_MAPR_SWJ_CFG_DISABLE` at start-up, disabling the probe's *own* SWJ port —
**to reflash the probe afterwards** you need the serial bootloader (BOOT0 = 1)
or a programmer that connects under reset, before the firmware runs. The default
unRemap build leaves the probe's SWJ port alone (PA13/PA14 stay usable), so it
can always be reflashed directly.

### Full pinout by board

The table below was verified directly against `src/dap/DAP_config.h`, which is
the authoritative source. Only BLUEPILL has been tested on real hardware.

| `BOARD` | SWDIO/TMS | SWCLK/TCK | SWO/TDO | TDI | nRESET | USB pull-up ctrl | Connect LED | Running LED | JTAG |
|---------|-----------|-----------|---------|-----|--------|------------------|-------------|-------------|------|
| `BLUEPILL` | PB9<br>PA13 (remap) | PB8<br>PA14 (remap) | PB7 | PB5 | PB6 | PB15 | PC13 | PC13 | ✅ |
| `BOARD_V1` | PB14 | PB13 | PA5 | PA7 | PB0 | PB15 | PB6 | PA9 | ✅ |
| `BOARD_V2` | PA4 | PA5 | PA6 | PA7 | PB9 | PB15 | PB6 | PA9 | ✅ |
| `STLINK_V20` | PB14 | PB13 | PB7 | — | PB0 | none | PA9 | PA9 | ❌ |
| `STLINK_V21` | PB14 | PB13 | PB7 | — | PB0 | PA15 (open-drain) | PA9 | PA8 | ❌ |
| `STLINK_V2A` | PB14 | PB13 | PA10 | (PB8) | PB6 | none | PA9 | PA9 | ❌ |
| `STLINK_V2B` | PB14 | PB13 | PA10 | PB8 | PB6 | none | PA9 | PA9 | ✅ |
| `BOARD_STM32RF` | PA6 | PA7 | PB7 | — | PB9 | PB5 | PB11 | PB12 | ❌ |

Notes:

- The **CDC virtual COM port** is USART2 on **PA2 (TX) / PA3 (RX)** for every board.
- **SWO** uses USART1 RX: BLUEPILL uses the remapped PB7 (macro `SWO_PB7`), all
  other boards use PA10 (macro `SWO_PA10`).
- TDI is parenthesised for `STLINK_V2A`: PB8 is defined in the code, but that
  board sets `DAP_JTAG` to 0, so JTAG is not compiled in and the pin is unused.
- Boards marked "none" under USB pull-up control have empty
  `PIN_USB_CONNECT_ON/OFF()` macros — the 1.5 kΩ D+ pull-up is hard-wired and
  the firmware performs no soft-disconnect.
- On BLUEPILL both LED macros point at the same pin, PC13 (the on-board LED),
  which is **active low**. The other boards are active high.

## USB device layout

| Interface | Class | Purpose |
|-----------|-------|---------|
| Interface 0 | HID | CMSIS-DAP command channel (auto-detected by Keil/OpenOCD/pyOCD) |
| Interfaces 1/2 | CDC ACM | Virtual COM port (USART2; baud rate and friends are set by the host) |

Driverless on Windows 10 and later, macOS and Linux. Windows 7/8 need the CDC
interface pointed at the in-box `usbser.sys` manually (this repository no longer
ships an .inf — see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)).

The device enumerates as **VID `0xC251` / PID `0xF001`**, the identifiers used by
Arm/Keil's CMSIS-DAP reference firmware. Host tools actually identify the probe
by the string "CMSIS-DAP" in its product descriptor.

## Differences from the upstream RadioOperator version

Upstream defined `PIN_nRESET_OUT` as `vResetTarget()`, so **every nRESET pin
operation also pushed four AIRCR writes over SWD** (the "Cortex-M soft reset"
feature), and `PORT_SWD_SETUP()` / `PORT_JTAG_SETUP()` (`src/main.c`)
unconditionally pulsed nRESET low for 100 ms at the end.

Both violate the CMSIS-DAP specification and break connect-under-reset: the host
asserts nRESET, then sends `DAP_Connect` — at which point the firmware released
nRESET again — and the host's subsequent read-back of the pin fails. With pyOCD
against an STM32H723 this surfaces as:

```
File ".../target/builtin/target_STM32H723xx.py", line 151, in safe_reset_and_halt
    assert self.dp.is_reset_asserted()
AssertionError
```

STM32F1 and most other parts are unaffected, because pyOCD only runs the
connect-under-reset sequence for the STM32H7xx and STM32F767 families.

This repository restores the standard behaviour: nRESET is a pin operation only,
and `DAP_Connect` no longer resets the target on its own. `vResetTarget()` is
still present in `src/main.c` (currently unreferenced, so `--gc-sections`
discards it) in case you want to wire it to a custom command.

## Building

Requirements: CMake ≥ 3.20, Ninja, and the
[GNU Arm Embedded Toolchain](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
(`arm-none-eabi-gcc`). Works on macOS, Linux and Windows; no commercial toolchain
is needed.

```sh
cmake -B build_gcc -G Ninja
cmake --build build_gcc
```

Output: `build_gcc/F103-DAP-SWO-CDC-BLUEPILL.elf / .hex / .bin`.
Implementation notes are in [docs/gcc-port.md](docs/gcc-port.md).

### Build options

| Option | Default | Description |
|--------|---------|-------------|
| `BOARD` | `BLUEPILL` | Target board — see the table below |
| `SWD_REMAP` | `OFF` | `BLUEPILL` only. When `ON`, the outgoing debug port moves to PA13/PA14 |

```sh
cmake -B build_gcc -G Ninja -DBOARD=STLINK_V20 -DSWD_REMAP=OFF
```

### Supported boards

The board list follows the original Keil project's targets; the pin definitions
are in the matching branches of `src/dap/DAP_config.h`.

| `BOARD` | MCU | Flash / RAM | SWO | JTAG | Status |
|---------|-----|-------------|-----|------|--------|
| `BLUEPILL` | STM32F103C8 | 64K / 20K | PB7 | ✅ | **Verified on hardware** |
| `BOARD_V1` | STM32F103CB | 128K / 20K | PA10 | ✅ | Compiles only |
| `BOARD_V2` | STM32F103C8 | 64K / 20K | PA10 | ✅ | Compiles only |
| `BOARD_V2_F102` | STM32F102C8 | 64K / **10K** | PA10 | ✅ | ⚠️ Does not link — not enough RAM |
| `STLINK_V20` | STM32F103C8 | 64K / 20K | PA10 | ❌ | Compiles only |
| `STLINK_V21` | STM32F103C8 | 64K / 20K | PA10 | ❌ | Compiles only |
| `STLINK_V2A` | STM32F103CB | 128K / 20K | PA10 | ❌ | Compiles only |
| `STLINK_V2B` | STM32F103CB | 128K / 20K | PA10 | ✅ | Compiles only |
| `BOARD_STM32RF` | STM32F103C8 | 64K / 20K | PA10 | ❌ | Compiles only |

Notes:

- **"Compiles only"** means the macro combination was carried over from the
  original Keil project and builds and links cleanly, but the author has no such
  hardware and cannot vouch for it. Reports from owners of these boards are welcome.
- `BOARD_V2_F102` needs roughly 18.7 KB of RAM (including a 3.5 KB stack/heap
  reservation) while the STM32F102C8 only has 10 KB, so the link fails with
  `region RAM overflowed`. The original Keil project only fitted by using Arm's
  microlib; GCC + newlib-nano does not. The option is kept so the board list
  matches the original project.
- Boards marked ❌ have JTAG disabled in `src/dap/DAP_config.h` (their hardware
  does not expose the JTAG pins), which makes the firmware about 3 KB smaller.

## Flashing

```sh
# ST-Link
st-flash write build_gcc/F103-DAP-SWO-CDC-BLUEPILL.bin 0x8000000

# or OpenOCD
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg \
        -c "program build_gcc/F103-DAP-SWO-CDC-BLUEPILL.hex verify reset exit"
```

## Repository layout

```
CMakeLists.txt                       Build entry point: BOARD / SWD_REMAP options, board table
cmake/
    arm-none-eabi.cmake              Cross-compilation toolchain file
    stm32f10x.ld.in                  Linker script template (Flash/RAM sizes filled in per board)
src/                                 Code maintained by this project
    main.c                           Main loop, board init, LED and reset logic
    system_stm32f10x.c               System clock configuration
    stm32f10x_conf.h                 Standard peripheral library configuration
    startup_stm32f10x_md.S           Startup file (GNU as syntax)
    dap/                             CMSIS-DAP protocol core
        DAP.c  SW_DP.c  JTAG_DP.c  SWO.c
        DAP_config.h                 ★ per-board pin definitions live here
    usb/                             USB descriptors, F103 USB hardware layer, HID/CDC callbacks
third_party/                         Externally sourced code (licences vary — see below)
    CMSIS/                           Arm CMSIS 5.6.0 core and driver headers
    USBStack/                        Arm RL-USB device stack sources
    STM32F10x_StdPeriph_Driver/      ST standard peripheral library (trimmed)
    STM32F10x_ARM_Driver/            Arm's USART/DMA/GPIO drivers
docs/
    Bluepill/                        Blue Pill wiring photos and pin notes
    gcc-port.md                      GCC port implementation notes
```

Documentation is bilingual: every `*.md` has a `*.zh-CN.md` counterpart with a
language switcher at the top. For the licence documents the English version is
authoritative.

The split is by **maintenance ownership**: `src/` is code this project maintains
and modifies, `third_party/` is code brought in from elsewhere. The point is to
make the licence boundary visible in the directory structure — everything under
`third_party/` is governed by its own original licence, see
[License](#license) below.

This repository contains the **software** only. The original Keil project
(`.uvproj`) has been removed: it requires a commercial Keil licence and the
legacy RL-ARM/RV31 directories from MDK v4.7, contains absolute Windows paths,
and its nine targets cannot be verified or maintained here. Every target's macro
combination was migrated to the `BOARD` option above, and the pin definitions
were always in `src/dap/DAP_config.h`, so nothing was lost. If you need the Keil
flow, use the upstream projects.

## License

Code added or modified by this project is released under the
**Apache License 2.0** — see [LICENSE](LICENSE).

**The repository as a whole is not a pure Apache-2.0 project.** It reuses code
from Arm, STMicroelectronics and Keil, each under its own licence. Two cases
deserve particular attention:

- `third_party/STM32F10x_StdPeriph_Driver/`, `src/system_stm32f10x.c` and
  `src/startup_stm32f10x_md.S` come from ST's standard peripheral library, whose
  licence carries a field-of-use restriction: **for use with STMicroelectronics
  devices only** (not an OSI-approved licence).
- `src/usb/usb_config.c`, `src/usb/usbd_STM32F103.c`, `src/usb/usbreg.h` and
  `third_party/USBStack/inc/RTL.h` come from the Keil RL-USB middleware and are
  headed "All rights reserved" with **no open-source grant**. They are kept
  because they are required to build and no replacement is available; this
  project does not claim they are Apache-2.0 and makes no warranty about the
  right to redistribute them.

The full inventory, the licence of every component, and a record of the
modifications this project made to third-party code are in
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md). Attribution is in
[NOTICE](NOTICE).

Keil's commercial pre-built library `USB_CM3.lib` has never been distributed with
this repository — the CMake build does not need it.

## Acknowledgements

- [x893/CMSIS-DAP](https://github.com/x893/CMSIS-DAP) — the original STM32 port,
  and the source of this project's `third_party/USBStack/`
- RadioOperator — CMSIS-DAP protocol v2.0, SWO_UART, CDC improvements, board variants
- [Arm CMSIS-DAP](https://github.com/ARM-software/CMSIS_5) — the protocol and
  reference implementation
