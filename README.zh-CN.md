[English](README.md) | 中文

# STM32F103C8T6 CMSIS-DAP_SWO 调试器固件

基于 STM32F103C8T6（Cortex-M3，64KB Flash / 20KB RAM，即"Bluepill"最小系统板）的
**CMSIS-DAP 调试器**固件。插上 USB 后，上位机（Keil、OpenOCD、pyOCD、IAR 等）将其
识别为标准 CMSIS-DAP 调试探头，可对目标板进行 SWD / JTAG 调试，同时提供 SWO 跟踪
和一路 USB 虚拟串口（CDC）。

代码基于 [x893/CMSIS-DAP](https://github.com/x893/CMSIS-DAP)，由 RadioOperator 改进
（CMSIS-DAP 协议升级到 V2.00、增加 SWO_UART、改进 CDC、增加 Cortex-M 软复位等）。

> **⚠️ 许可提示 —— 再分发前请先阅读。** 本项目新增的代码以 Apache-2.0 发布，
> 但**整个仓库并不是一个纯 Apache-2.0 项目**。它打包了 Arm、STMicroelectronics
> 和 Keil 的代码，各自适用其原始许可——其中有四个文件**完全不含开源授权条款**，
> 另有 ST 的代码带"仅可用于 ST 微控制器"的使用领域限制。完整说明见
> [THIRD-PARTY-NOTICES.zh-CN.md](THIRD-PARTY-NOTICES.zh-CN.md)，
> 摘要见下方[许可](#许可)一节。

## 功能特性

- **SWD + JTAG** 两种调试模式（默认 SWD）
- **SWO 跟踪**：SWO_UART 模式（占用 USART1），支持目标板 `printf` 输出到 SWO
- **CDC 虚拟串口**：占用 USART2，USB 上多出一个串口，可接目标板 UART
- **标准 nRESET 时序**：nRESET 为纯引脚操作，支持上位机的 connect-under-reset
  （STM32H7 / F7 等型号必需）
- USB 复合设备：HID（CMSIS-DAP 通道）+ CDC ACM（虚拟串口）

## 引脚定义（重要）

本仓库 CMake 默认构建的是 **BLUEPILL 不带 SWD_REMAP** 的配置（编译宏
`STM32F10X_MD BLUEPILL SWO_PB7`），引脚定义见
`src/dap/DAP_config.h`。各引脚用途如下：

### 调试接口（接目标板）

| MCU 引脚 | SWD 模式  | JTAG 模式 | 说明 |
|---------|-----------|-----------|------|
| **PB9**  | SWDIO    | JTMS      | 数据线 |
| **PB8**  | SWCLK    | JTCK      | 时钟线 |
| **PB7**  | SWO      | JTDO      | SWO 跟踪输入 / JTAG TDO（内部为重映射后的 USART1_RX） |
| **PB6**  | nRESET   | nRESET    | 目标复位（输出） |
| **PB5**  | —        | JTDI      | JTAG 数据输入（仅 JTAG 模式使用） |
| —        | —        | nTRST     | 不支持 |

> 接线时注意共地：调试器 GND 必须与目标板 GND 相连。
 
### 串口（CDC 虚拟串口，接目标板 UART）

| MCU 引脚 | 功能 | 说明 |
|---------|------|------|
| **PA2** | USART2_TX | 接目标板 RX |
| **PA3** | USART2_RX | 接目标板 TX |

### USB 与指示灯

| MCU 引脚 | 功能 | 说明 |
|---------|------|------|
| PA11 | USB D− | 接 USB 接口 |
| PA12 | USB D+ | 接 USB 接口（Bluepill 板载 1.5kΩ 上拉） |
| PB15 | USB 连接控制 | 可选，低电平有效；用外部 MOS/三极管控制 D+ 上拉时使用，Bluepill 上拉固定接死则悬空即可 |
| PC13 | 状态 LED | 低电平点亮（Bluepill 板载 LED）。慢闪：等待连接；快闪：CDC 数据活动；调试传输时按状态闪烁 |
| PB12 | 保留 | 上电配置为浮空输入，仅为兼容 DAPLink 接线习惯 |

### SWD_REMAP 与 unRemap 两种版本的区别

`src/dap/DAP_config.h` 为 Bluepill 提供了两种引脚方案（详见 `docs/Bluepill/`），
CMake 构建通过 `SWD_REMAP` 选项切换：

| 信号 | unRemap 版（默认） | SWD_REMAP 版（`cmake -B build_gcc -DSWD_REMAP=ON && cmake --build build_gcc`） |
|------|-------------------|---------------------|
| SWDIO / JTMS | PB9 | PA13 |
| SWCLK / JTCK | PB8 | PA14 |
| 其余引脚 | 相同（PB7 / PB6 / PB5） | 相同 |

SWD_REMAP 版把调试输出信号放在 Bluepill 自身的 4 针 SWD 排针上，接线方便；
代价是固件启动后会执行 `AFIO_MAPR_SWJ_CFG_DISABLE` 关闭本机的 SWJ 调试口——
**烧录后想再刷写本机固件**，需要用串口 ISP（BOOT0=1），或让烧录器在复位
保持（connect under reset）状态下抢在固件运行前连接。默认的 unRemap 版
不禁用本机 SWJ 口（PA13/PA14 始终可用），随时可以直接重烧。

### 全部板型引脚对照

下表由 `src/dap/DAP_config.h` 直接核对生成，是各板型引脚的权威出处。
除 BLUEPILL 外均未经实机验证（作者没有对应硬件）。

| `BOARD` | SWDIO/TMS | SWCLK/TCK | SWO/TDO | TDI | nRESET | USB 上拉控制 | Connect LED | Running LED | JTAG |
|---------|-----------|-----------|---------|-----|--------|-------------|-------------|-------------|------|
| `BLUEPILL` | PB9<br>PA13（remap） | PB8<br>PA14（remap） | PB7 | PB5 | PB6 | PB15 | PC13 | PC13 | ✅ |
| `BOARD_V1` | PB14 | PB13 | PA5 | PA7 | PB0 | PB15 | PB6 | PA9 | ✅ |
| `BOARD_V2` | PA4 | PA5 | PA6 | PA7 | PB9 | PB15 | PB6 | PA9 | ✅ |
| `STLINK_V20` | PB14 | PB13 | PB7 | — | PB0 | 无 | PA9 | PA9 | ❌ |
| `STLINK_V21` | PB14 | PB13 | PB7 | — | PB0 | PA15（开漏） | PA9 | PA8 | ❌ |
| `STLINK_V2A` | PB14 | PB13 | PA10 | (PB8) | PB6 | 无 | PA9 | PA9 | ❌ |
| `STLINK_V2B` | PB14 | PB13 | PA10 | PB8 | PB6 | 无 | PA9 | PA9 | ✅ |
| `BOARD_STM32RF` | PA6 | PA7 | PB7 | — | PB9 | PB5 | PB11 | PB12 | ❌ |

说明：

- **CDC 虚拟串口**在所有板型上都是 USART2 的 **PA2（TX）/ PA3（RX）**。
- **SWO** 走 USART1 的 RX：BLUEPILL 用重映射后的 PB7（宏 `SWO_PB7`），
  其余板型用 PA10（宏 `SWO_PA10`）。
- `STLINK_V2A` 的 TDI 加了括号：代码里定义了 PB8，但该板型的 `DAP_JTAG` 为 0，
  JTAG 未编译进固件，所以这个引脚实际不会被使用。
- **USB 上拉控制**标"无"的板型，其 `PIN_USB_CONNECT_ON/OFF()` 是空宏——
  硬件上 D+ 的 1.5kΩ 上拉是固定接死的，固件不做软件断连。
- BLUEPILL 的两个 LED 宏指向同一个引脚 PC13（板载 LED），**低电平点亮**；
  其余板型为高电平点亮。

## USB 设备构成

| 接口 | 类型 | 用途 |
|------|------|------|
| 接口 0 | HID | CMSIS-DAP 命令通道（Keil/OpenOCD/pyOCD 自动识别） |
| 接口 1/2 | CDC ACM | 虚拟串口（对应 USART2，波特率等参数由上位机设置自动下发） |

Windows 10 及以上、macOS、Linux 均为免驱。Windows 7/8 需要为 CDC 接口手工指定
系统自带的 `usbser.sys` 驱动（本仓库不再附带 .inf，原因见
[THIRD-PARTY-NOTICES.zh-CN.md](THIRD-PARTY-NOTICES.zh-CN.md)）。

设备以 **VID `0xC251` / PID `0xF001`** 枚举，这是 Arm/Keil 的 CMSIS-DAP 参考固件
沿用至今的标识；上位机实际是靠产品字符串中的 "CMSIS-DAP" 识别探头的。

## 与上游 RadioOperator 版本的行为差异

上游把 `PIN_nRESET_OUT` 定义成 `vResetTarget()`，使得**每次操作 nRESET 都会额外
通过 SWD 写 4 次 AIRCR**（即"Cortex-M 软复位"特性），并且在 `PORT_SWD_SETUP()` /
`PORT_JTAG_SETUP()`（`src/main.c`）结尾无条件对 nRESET 打一个 100ms 的低脉冲。

这两处均不符合 CMSIS-DAP 规范，会破坏 connect-under-reset 时序：上位机先拉低
nRESET，再发 `DAP_Connect`，此时固件却把 nRESET 放开了，随后上位机回读引脚发现
不是低电平即报错。表现为 pyOCD 连接 STM32H723 时抛出

```
File ".../target/builtin/target_STM32H723xx.py", line 151, in safe_reset_and_halt
    assert self.dp.is_reset_asserted()
AssertionError
```

STM32F1 等型号不受影响，因为 pyOCD 只对 STM32H7xx / STM32F767 这几个系列启用
connect-under-reset 流程。

本仓库已改为标准行为：nRESET 只做引脚操作，`DAP_Connect` 不再擅自复位目标。
`vResetTarget()` 函数保留在 `src/main.c` 中（当前未被引用，链接时会被
`--gc-sections` 回收），需要时可挂到自定义命令上。

## 构建方法

依赖：CMake ≥ 3.20、Ninja、[GNU Arm Embedded Toolchain](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)（`arm-none-eabi-gcc`）。
macOS / Linux / Windows 均可，不需要任何商业工具链。

```sh
cmake -B build_gcc -G Ninja
cmake --build build_gcc
```

产物：`build_gcc/F103-DAP-SWO-CDC-BLUEPILL.elf / .hex / .bin`。
实现细节见 [docs/gcc-port.zh-CN.md](docs/gcc-port.zh-CN.md)。

### 构建选项

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `BOARD` | `BLUEPILL` | 目标板型，见下表 |
| `SWD_REMAP` | `OFF` | 仅对 `BLUEPILL` 有效。`ON` 时对外调试口改走 PA13/PA14 |

```sh
cmake -B build_gcc -G Ninja -DBOARD=STLINK_V20 -DSWD_REMAP=OFF
```

### 支持的板型

板型沿用原 Keil 工程的划分，引脚定义都在 `src/dap/DAP_config.h` 的对应分支里。

| `BOARD` | 芯片 | Flash / RAM | SWO | JTAG | 状态 |
|---------|------|-------------|-----|------|------|
| `BLUEPILL` | STM32F103C8 | 64K / 20K | PB7 | ✅ | **已实机验证** |
| `BOARD_V1` | STM32F103CB | 128K / 20K | PA10 | ✅ | 仅验证可编译 |
| `BOARD_V2` | STM32F103C8 | 64K / 20K | PA10 | ✅ | 仅验证可编译 |
| `BOARD_V2_F102` | STM32F102C8 | 64K / **10K** | PA10 | ✅ | ⚠️ RAM 不足，无法链接 |
| `STLINK_V20` | STM32F103C8 | 64K / 20K | PA10 | ❌ | 仅验证可编译 |
| `STLINK_V21` | STM32F103C8 | 64K / 20K | PA10 | ❌ | 仅验证可编译 |
| `STLINK_V2A` | STM32F103CB | 128K / 20K | PA10 | ❌ | 仅验证可编译 |
| `STLINK_V2B` | STM32F103CB | 128K / 20K | PA10 | ✅ | 仅验证可编译 |
| `BOARD_STM32RF` | STM32F103C8 | 64K / 20K | PA10 | ❌ | 仅验证可编译 |

说明：

- **"仅验证可编译"** 意味着宏组合照搬原 Keil 工程、能正常编译链接，但作者没有
  对应硬件，无法保证实际可用。欢迎有这些板子的朋友反馈。
- `BOARD_V2_F102` 需要约 18.7KB RAM（含 3.5KB 栈/堆预留），而 STM32F102C8 只有
  10KB，链接会报 `region RAM overflowed`。原 Keil 工程依赖 ARM microlib 才勉强
  放得下，GCC + newlib-nano 放不下。保留此选项是为了与原工程的板型列表对应完整。
- 标 ❌ 的板型是 `src/dap/DAP_config.h` 主动关闭了 JTAG（这些硬件未引出 JTAG 引脚），
  固件会小 3KB 左右。

## 烧录

```sh
# ST-Link
st-flash write build_gcc/F103-DAP-SWO-CDC-BLUEPILL.bin 0x8000000

# 或 OpenOCD
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg \
        -c "program build_gcc/F103-DAP-SWO-CDC-BLUEPILL.hex verify reset exit"
```

## 目录结构

```
CMakeLists.txt                       构建入口：BOARD / SWD_REMAP 选项、板型表
cmake/
    arm-none-eabi.cmake              交叉编译工具链文件
    stm32f10x.ld.in                  链接脚本模板（Flash/RAM 尺寸按板型代入）
src/                                 本项目维护的代码
    main.c                           主循环、板级初始化、LED/复位逻辑
    system_stm32f10x.c               系统时钟配置
    stm32f10x_conf.h                 标准外设库裁剪配置
    startup_stm32f10x_md.S           启动文件（GNU as 语法）
    dap/                             CMSIS-DAP 协议核心
        DAP.c  SW_DP.c  JTAG_DP.c  SWO.c
        DAP_config.h                 ★ 各板型的引脚定义都在这里
    usb/                             USB 描述符配置、F103 USB 硬件层、HID/CDC 回调
third_party/                         外部引入的代码（许可各异，见下节）
    CMSIS/                           Arm CMSIS 5.6.0 核心与驱动头文件
    USBStack/                        Arm RL-USB 设备栈源码
    STM32F10x_StdPeriph_Driver/      ST 标准外设库（按需裁剪）
    STM32F10x_ARM_Driver/            Arm 的 USART/DMA/GPIO 驱动
docs/
    Bluepill/                        Bluepill 接线照片与引脚说明
    gcc-port.md                      GCC 移植实现说明
```

文档为双语：每个 `*.md` 都有对应的 `*.zh-CN.md`，文件顶部可切换语言。
许可类文档以英文版为准。

目录按**维护归属**划分：`src/` 是本项目维护和修改的代码，`third_party/` 是外部引入
的代码。这样做是为了让许可边界在目录结构上就看得出来——`third_party/` 里的内容各自
适用其原始许可，详见[许可](#许可)一节。

本仓库只包含**软件**部分。原 Keil 工程（`.uvproj`）已移除：它依赖 Keil 商业授权
和 MDK v4.7 时代的 legacy RL-ARM/RV31 目录，内含绝对 Windows 路径，且 9 个 target
无法验证维护。各 target 的宏组合已完整迁移为上面的 `BOARD` 选项，引脚定义本来就在
`src/dap/DAP_config.h` 里，没有信息丢失。需要 Keil 流程的话请参考上游项目。

## 许可

本项目新增与修改的部分以 **Apache License 2.0** 发布，见 [LICENSE](LICENSE)。

**但整个仓库不是纯 Apache-2.0 项目。** 它复用了 Arm、STMicroelectronics 和 Keil
的代码，各自适用其原始许可，其中两处需要特别注意：

- `third_party/STM32F10x_StdPeriph_Driver/`、`src/system_stm32f10x.c`、
  `src/startup_stm32f10x_md.S` 源自 ST 标准外设库，其许可带有**仅可用于 ST 微控
  制器**的使用领域限制（非 OSI 许可）。
- `src/usb/usb_config.c`、`src/usb/usbd_STM32F103.c`、`src/usb/usbreg.h`、
  `third_party/USBStack/inc/RTL.h` 源自 Keil RL-USB 中间件，文件头为 "All rights reserved"，
  **不含开源授权条款**。保留是因为编译必需且无替代实现；本项目不主张它们属于
  Apache-2.0，也不对其分发权利作任何担保。

完整清单、各组件许可原文出处、以及本项目对第三方代码所做修改的记录，见
[THIRD-PARTY-NOTICES.zh-CN.md](THIRD-PARTY-NOTICES.zh-CN.md)。归属声明见 [NOTICE](NOTICE)。

Keil 的商业预编译库 `USB_CM3.lib` 从未随本仓库分发——CMake 构建不需要它。

## 致谢

- [x893/CMSIS-DAP](https://github.com/x893/CMSIS-DAP) — STM32 平台的原始移植，
  本项目 `third_party/USBStack/` 源码的来源
- RadioOperator — CMSIS-DAP 协议升级至 V2.0、SWO_UART、CDC 改进、多板型支持
- [Arm CMSIS-DAP](https://github.com/ARM-software/CMSIS_5) — 协议与参考实现
