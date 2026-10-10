[English](THIRD-PARTY-NOTICES.md) | 中文

> **以英文版为准。** 本中文版仅供参考；若两者表述不一致，以
> [英文版](THIRD-PARTY-NOTICES.md)为准。

# 第三方代码与许可说明

本仓库是一个 CMSIS-DAP 调试器固件，大量复用了 Arm、STMicroelectronics 以及两个
上游移植项目的代码。本文件逐目录说明来源、版权方与许可，供使用者评估合规性。

> 本文件是对各文件头部实际声明的如实整理，不构成法律意见。若用于商业用途，
> 请自行就下方标注为 ⚠️ 的条目征询专业意见。

## 总览

| 目录 / 文件 | 来源 | 版权方 | 许可 | 可随本仓库分发 |
|---|---|---|---|---|
| `src/dap/` | Arm CMSIS-DAP 参考实现 | Arm Limited 2013–2017 | Apache-2.0 | ✅ |
| `third_party/USBStack/`（除 `inc/RTL.h`） | Arm 作为 CMSIS-DAP Interface Firmware 发布的 RL-USB 设备栈 | Arm Limited 2009–2013 | Apache-2.0 | ✅ |
| `third_party/CMSIS/` | Arm CMSIS 5.6.0 | Arm Limited 2009–2019 | Apache-2.0 | ✅ |
| `third_party/STM32F10x_ARM_Driver/` | Arm 的 STM32F10x CMSIS 驱动层 | ARM Ltd 2013–2016 | zlib | ✅ |
| `third_party/STM32F10x_StdPeriph_Driver/` | ST 标准外设库 | STMicroelectronics 2011 | ST 自有许可 | ⚠️ 见下 |
| `src/system_stm32f10x.c` | ST CMSIS 设备文件 | STMicroelectronics 2011 | ST 自有许可 | ⚠️ 见下 |
| `src/startup_stm32f10x_md.S` | 由 ST 的 armasm 启动文件改写为 GNU as 语法 | STMicroelectronics 2010 + 本项目 | ST 自有许可 | ⚠️ 见下 |
| `src/usb/usb_config.c`、`src/usb/usbd_STM32F103.c`、`src/usb/usbreg.h`、`third_party/USBStack/inc/RTL.h` | Keil RL-ARM / RL-USB 中间件 | Keil – An Arm Company 2004–2014 | **无开源授权** | ⚠️ 见下 |
| `src/usb/usbd_user_hid.c`、`src/usb/usbd_user_cdc_acm.c` | 上游移植的应用层回调 | x893 / RadioOperator | 随上游项目 | ✅ |
| `CMakeLists.txt`、`cmake/`、`README.md` 等 | 本项目原创 | 本项目 | Apache-2.0 | ✅ |

## 本项目自身的许可

本项目新增与修改的部分以 **Apache License 2.0** 发布，见 [LICENSE](LICENSE)。
选择 Apache-2.0 是因为仓库主体（CMSIS-DAP 协议实现与 USB 设备栈）本就是该许可。

**但请注意：整个仓库不是一个纯 Apache-2.0 项目。** 上表中标注 ⚠️ 的部分各自适用
其原始许可，本项目无权为其重新授权。

## ⚠️ Keil RL-USB 文件

以下四个文件来自 Keil 的 RL-ARM / RL-USB 中间件，文件头为
`Copyright (c) 2004-2014 KEIL - An ARM Company. All rights reserved.`，
**不含任何开源授权条款**：

- `src/usb/usb_config.c` — USB 描述符与设备配置
- `src/usb/usbd_STM32F103.c` — STM32F103 USB 硬件层
- `src/usb/usbreg.h` — STM32 USB 寄存器定义
- `third_party/USBStack/inc/RTL.h` — RL-ARM 公共类型与宏定义

**为什么保留**：这四个文件是编译必需的，且本项目没有可用的替代实现。整条上游链路
（Arm 自己的 mbed CMSIS-DAP Interface Firmware、x893、RadioOperator）十余年来都以
相同方式公开分发这些文件。

**如实声明**：本项目**不**主张这些文件属于 Apache-2.0，也不对其分发权利作任何担保。
如果你计划商业使用，应当自行评估，或替换掉它们——其中 `RTL.h`（基本只是整数类型
别名与几个宏）和 `usbreg.h`（寄存器定义）相对容易重写。如版权方提出异议，本项目将
配合移除。

注：`third_party/USBStack/` 下其余文件头部为
`CMSIS-DAP Interface Firmware, Copyright (c) 2009-2013 ARM Limited` + Apache-2.0，
是 Arm 当年随 CMSIS-DAP Interface Firmware 以 Apache-2.0 重新发布的版本，不受此条限制。

另：Keil 的预编译库 `USB_CM3.lib` 属于商业授权内容，**从未、也不会**随本仓库分发。
CMake 构建不需要它（改用 `third_party/USBStack/` 源码）。

### 已移除的 Keil CDC 驱动 .inf

上游仓库曾附带 `Doc/Windows-USB-CDC-Driver/CMSIS-DAP_CDC_Driver.inf`，其文件头为
`Provider=%CMSISDAP%`、`DriverVer=11/22/2011`，是 Keil 随 CMSIS-DAP 发布的驱动
安装文件，同样不含任何开源授权条款。考虑到 Windows 10 及以上已自带 `usbser.sys`
免驱、该文件仅对已停止支持的 Windows 7/8 有意义，本仓库已将其移除。

## ⚠️ USB VID / PID

固件以 **VID `0xC251` / PID `0xF001`** 枚举（见 `src/usb/usb_config.c` 中的
`USBD_DEVDESC_IDVENDOR` / `USBD_DEVDESC_IDPRODUCT`）。

**`0xC251` 是 Keil（Arm）向 USB-IF 注册的厂商 ID**，并非本项目所有。这组 VID/PID
来自 Arm/Keil 的 CMSIS-DAP 参考固件，几乎所有第三方 CMSIS-DAP 实现都沿用它，已成
事实惯例；但严格依照 USB-IF 规则，借用他人的厂商 ID 是不被允许的。

本项目保持与上游及生态一致，不作改动，在此如实说明。需要规避的使用者可以自行修改
上述两个宏——现代上位机（pyOCD、OpenOCD）是通过产品字符串中的 "CMSIS-DAP" 识别探头
的，不依赖特定 VID/PID，因此更换不会影响工具兼容性。若需要正式的标识，
[pid.codes](https://pid.codes/) 为开源硬件项目提供免费的 PID 分配。

## ⚠️ STMicroelectronics 代码

`third_party/STM32F10x_StdPeriph_Driver/`、`src/system_stm32f10x.c` 以及
`src/startup_stm32f10x_md.S` 的原始版本来自 ST 的标准外设库（STSW-STM32054）。
该库按 **MCD-ST Liberty SW License Agreement V2** 发布：允许源码与二进制形式的
再分发，但附带**使用领域限制——仅可用于 STMicroelectronics 的微控制器**。

这一限制使其不符合 OSI 的开源定义。对本项目没有实际影响（固件本身就只跑在 STM32
上），但这意味着仓库整体不能被当作无限制的 Apache-2.0 项目看待。

许可条款全文未随库附带，各文件仅有版权声明；条款可从 ST 官网获取。

## 本项目对第三方代码所做的修改

按 Apache-2.0 第 4(b) 条，以下为对第三方文件的实质性修改记录：

- **`third_party/USBStack/`**：为适配 GCC 所做的移植——`__packed` 属性位置修正、
  `__inline` 改为外部链接、`__swi` / `__task` 在 GCC 下置空、
  移除 armcc 内联汇编块 `$$USBD$$version`、`U8`/`U32` 等类型改用 `<stdint.h>`。
- **`src/dap/DAP_config.h`**：`PIN_nRESET_OUT` 由上游的 `vResetTarget()`
  改回符合 CMSIS-DAP 规范的纯引脚操作（原实现会破坏 connect-under-reset 时序，
  详见 README）。
- **`src/main.c`**：移除 `PORT_SWD_SETUP()` / `PORT_JTAG_SETUP()` 中对 nRESET
  的 100ms 脉冲（同上原因）。
- **`src/startup_stm32f10x_md.S`**：由 ST 的 armasm 启动文件改写为 GNU as 语法。

## 上游项目

| 项目 | 地址 | 贡献 |
|---|---|---|
| x893/CMSIS-DAP | https://github.com/x893/CMSIS-DAP | STM32 平台的原始移植，`third_party/USBStack/` 源码的来源 |
| RadioOperator | — | CMSIS-DAP 协议升级至 V2.0、SWO_UART、CDC 改进、多板型支持 |
| Arm CMSIS-DAP | https://github.com/ARM-software/CMSIS_5 | 协议与参考实现、CMSIS 头文件 |
