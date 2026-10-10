English | [中文](gcc-port.zh-CN.md)

# Building from the command line with CMake + GCC (no Keil required)

## Requirements

- CMake ≥ 3.20
- Ninja (or make — just drop the `-G Ninja`)
- GNU Arm Embedded Toolchain (`arm-none-eabi-gcc`)

## Build

```sh
cmake -B build_gcc -G Ninja
cmake --build build_gcc
```

Artifacts land in `build_gcc/`:

- `F103-DAP-SWO-CDC-BLUEPILL.elf` / `.hex` / `.bin` / `.map`

The default target is the STM32F103C8T6 (64 KB Flash / 20 KB RAM) with the macro
set `STM32F10X_MD BLUEPILL SWO_PB7`. Other boards are selected with
`-DBOARD=...`; see the full list in
[../README.md](../README.md#supported-boards).

The default build is the unRemap variant (outgoing debug port SWDIO = PB9,
SWCLK = PB8, probe's own SWJ port left usable). Add `-DSWD_REMAP=ON` for the
REMAP variant (outgoing debug port on PA13/PA14, easier to wire, but the
firmware disables the probe's own SWJ port at start-up, so reflashing it then
requires BOOT0 or connect-under-reset).

## Flashing

```sh
# ST-Link
st-flash write build_gcc/F103-DAP-SWO-CDC-BLUEPILL.bin 0x8000000
# or OpenOCD
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg \
        -c "program build_gcc/F103-DAP-SWO-CDC-BLUEPILL.hex verify reset exit"
```

## Where these files come from

The original was a Keil uVision project. The main obstacles in porting it to GCC,
and how each was handled:

**USB device stack.** The Keil project linked against `USB_CM3.lib` (the RL-USB
middleware), whose member objects are in Arm's proprietary ORC format (magic
`\xf7ORC`) that GNU ld cannot read. The build therefore uses the RL-USB
**sources** under `third_party/USBStack/` instead — taken from the upstream
x893/CMSIS-DAP repository, which is the version Arm released under Apache-2.0 as
part of the CMSIS-DAP Interface Firmware, with an API identical to the `.lib`.
Licensing details are in
[../THIRD-PARTY-NOTICES.md](../THIRD-PARTY-NOTICES.md).

**GCC adaptation files:**

| File | Purpose |
|------|---------|
| `src/startup_stm32f10x_md.S` | Startup file in GNU as syntax (ST's original is armasm syntax) |
| `cmake/stm32f10x.ld.in` | Linker script template; CMake substitutes the Flash/RAM sizes per board |
| `cmake/arm-none-eabi.cmake` | CMake cross-compilation toolchain file |
| `third_party/CMSIS/` | Arm CMSIS 5.6.0 headers (under Keil these come from its installed Pack) |

**armcc keyword adaptation.** The `third_party/USBStack/` sources were written
for armcc. Porting them required fixing the placement of the `__packed`
attribute, the linkage of `__inline`, the `__swi` / `__task` keywords, an armcc
inline-assembly block, and switching `U8`/`U32` and friends to `<stdint.h>`.

**Compiler options.** `-fshort-wchar` is mandatory: the Keil project enabled
short wchar, and the USB string descriptors initialise `U16` arrays with
`L"..."` literals, which relies on a 2-byte `wchar_t`.
