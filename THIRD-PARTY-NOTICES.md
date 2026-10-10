English | [中文](THIRD-PARTY-NOTICES.zh-CN.md)

> **This English version is authoritative.** A Chinese translation is provided
> for convenience; if the two ever disagree, this document governs.

# Third-Party Code and Licences

This repository is a CMSIS-DAP debug probe firmware that reuses a substantial
amount of code from Arm, STMicroelectronics and two upstream porting projects.
This document lists, directory by directory, where the code came from, who holds
the copyright, and under what licence, so that users can assess compliance.

> This is a faithful summary of what the file headers actually say. It is not
> legal advice. If you intend to use this commercially, seek your own advice on
> the items marked ⚠️ below.

## Overview

| Directory / file | Origin | Copyright holder | Licence | Redistributable with this repo |
|---|---|---|---|---|
| `src/dap/` | Arm CMSIS-DAP reference implementation | Arm Limited 2013–2017 | Apache-2.0 | ✅ |
| `third_party/USBStack/` (except `inc/RTL.h`) | RL-USB device stack as released by Arm with the CMSIS-DAP Interface Firmware | Arm Limited 2009–2013 | Apache-2.0 | ✅ |
| `third_party/CMSIS/` | Arm CMSIS 5.6.0 | Arm Limited 2009–2019 | Apache-2.0 | ✅ |
| `third_party/STM32F10x_ARM_Driver/` | Arm's CMSIS driver layer for STM32F10x | ARM Ltd 2013–2016 | zlib | ✅ |
| `third_party/STM32F10x_StdPeriph_Driver/` | ST standard peripheral library | STMicroelectronics 2011 | ST proprietary | ⚠️ see below |
| `src/system_stm32f10x.c` | ST CMSIS device file | STMicroelectronics 2011 | ST proprietary | ⚠️ see below |
| `src/startup_stm32f10x_md.S` | ST's armasm startup file, rewritten for GNU as | STMicroelectronics 2010 + this project | ST proprietary | ⚠️ see below |
| `src/usb/usb_config.c`, `src/usb/usbd_STM32F103.c`, `src/usb/usbreg.h`, `third_party/USBStack/inc/RTL.h` | Keil RL-ARM / RL-USB middleware | Keil – An Arm Company 2004–2014 | **no open-source grant** | ⚠️ see below |
| `src/usb/usbd_user_hid.c`, `src/usb/usbd_user_cdc_acm.c` | Application callbacks from the upstream port | x893 / RadioOperator | follows the upstream project | ✅ |
| `CMakeLists.txt`, `cmake/`, `README.md`, … | Original to this project | This project | Apache-2.0 | ✅ |

## This project's own licence

Code added or modified by this project is released under the **Apache License
2.0** — see [LICENSE](LICENSE). Apache-2.0 was chosen because the bulk of the
repository (the CMSIS-DAP protocol implementation and the USB device stack) is
already under that licence.

**Note, however, that the repository as a whole is not a pure Apache-2.0
project.** The items marked ⚠️ above are governed by their original licences,
which this project has no authority to change.

## ⚠️ Keil RL-USB files

The following four files come from Keil's RL-ARM / RL-USB middleware and are
headed `Copyright (c) 2004-2014 KEIL - An ARM Company. All rights reserved.`
with **no open-source grant of any kind**:

- `src/usb/usb_config.c` — USB descriptors and device configuration
- `src/usb/usbd_STM32F103.c` — STM32F103 USB hardware layer
- `src/usb/usbreg.h` — STM32 USB register definitions
- `third_party/USBStack/inc/RTL.h` — RL-ARM common types and macros

**Why they are kept**: these four files are required to build, and this project
has no working replacement for them. The entire upstream chain — Arm's own mbed
CMSIS-DAP Interface Firmware, x893, and RadioOperator — has distributed them
publicly in exactly this way for well over a decade.

**Plain statement**: this project does **not** claim these files are
Apache-2.0, and makes no warranty about the right to redistribute them. If you
plan commercial use, evaluate this yourself, or replace them — of the four,
`RTL.h` (essentially integer type aliases and a few macros) and `usbreg.h`
(register definitions) would be the easiest to rewrite. Should the copyright
holder object, this project will cooperate in removing them.

Note: every *other* file under `third_party/USBStack/` is headed
`CMSIS-DAP Interface Firmware, Copyright (c) 2009-2013 ARM Limited` plus
Apache-2.0. Those are the versions Arm re-released under Apache-2.0 as part of
the CMSIS-DAP Interface Firmware and are not affected by this section.

Also note: Keil's pre-built library `USB_CM3.lib` is commercially licensed and
has **never been, and will not be,** distributed with this repository. The CMake
build does not need it (it uses the `third_party/USBStack/` sources instead).

### The removed Keil CDC driver .inf

The upstream repository shipped `Doc/Windows-USB-CDC-Driver/CMSIS-DAP_CDC_Driver.inf`,
headed `Provider=%CMSISDAP%`, `DriverVer=11/22/2011`. It is Keil's own driver
installation file released alongside CMSIS-DAP and likewise carries no
open-source grant. Since Windows 10 and later are driverless via the in-box
`usbser.sys`, and the file is only of use on the end-of-life Windows 7/8, it has
been removed from this repository.

## ⚠️ USB VID / PID

The firmware enumerates as **VID `0xC251` / PID `0xF001`** (see
`USBD_DEVDESC_IDVENDOR` / `USBD_DEVDESC_IDPRODUCT` in `src/usb/usb_config.c`).

**`0xC251` is the USB vendor ID that Keil (Arm) registered with the USB-IF** and
does not belong to this project. This VID/PID pair comes from Arm/Keil's
CMSIS-DAP reference firmware and is reused by virtually every third-party
CMSIS-DAP implementation, making it a de facto convention — but strictly
speaking, the USB-IF rules do not permit borrowing another party's vendor ID.

This project keeps the values for consistency with upstream and the wider
ecosystem, and states the situation plainly here. If you would rather avoid it,
change those two macros: modern host tools (pyOCD, OpenOCD) identify the probe by
the string "CMSIS-DAP" in its product descriptor rather than by a specific
VID/PID, so changing them does not break tool compatibility. If you need a
legitimate identifier, [pid.codes](https://pid.codes/) issues free PID
allocations to open-source hardware projects.

## ⚠️ STMicroelectronics code

`third_party/STM32F10x_StdPeriph_Driver/`, `src/system_stm32f10x.c` and the
original of `src/startup_stm32f10x_md.S` come from ST's standard peripheral
library (STSW-STM32054), released under the **MCD-ST Liberty SW License
Agreement V2**. That licence permits redistribution in both source and binary
form, but attaches a field-of-use restriction: **for use with STMicroelectronics
microcontrollers only**.

That restriction makes it non-conforming to the OSI definition of open source.
It has no practical consequence for this project (the firmware only ever runs on
an STM32), but it does mean the repository as a whole cannot be treated as an
unrestricted Apache-2.0 project.

The full licence text is not bundled with the library — the files carry only a
copyright notice; the terms are available from ST's website.

## Modifications this project made to third-party code

As required by Apache-2.0 section 4(b), the substantive modifications to
third-party files are:

- **`third_party/USBStack/`** — GCC porting work: corrected placement of the
  `__packed` attribute, changed `__inline` to external linkage, defined `__swi` /
  `__task` away under GCC, removed the armcc inline-assembly block
  `$$USBD$$version`, and switched `U8`/`U32` and friends to `<stdint.h>` types.
- **`src/dap/DAP_config.h`** — `PIN_nRESET_OUT` was changed from upstream's
  `vResetTarget()` back to a plain, spec-compliant pin operation (the original
  broke connect-under-reset timing; see the README).
- **`src/main.c`** — removed the 100 ms nRESET pulse from `PORT_SWD_SETUP()` and
  `PORT_JTAG_SETUP()` (same reason).
- **`src/startup_stm32f10x_md.S`** — rewritten from ST's armasm startup file into
  GNU as syntax.

## Upstream projects

| Project | URL | Contribution |
|---|---|---|
| x893/CMSIS-DAP | https://github.com/x893/CMSIS-DAP | The original STM32 port; source of `third_party/USBStack/` |
| RadioOperator | — | CMSIS-DAP protocol v2.0, SWO_UART, CDC improvements, board variants |
| Arm CMSIS-DAP | https://github.com/ARM-software/CMSIS_5 | The protocol, reference implementation and CMSIS headers |
