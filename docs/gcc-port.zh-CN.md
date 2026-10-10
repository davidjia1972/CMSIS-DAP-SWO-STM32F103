[English](gcc-port.md) | 中文

# 用 CMake + GCC 命令行构建（不需要 Keil）

## 依赖

- CMake ≥ 3.20
- Ninja（或 make，把 `-G Ninja` 去掉即可）
- GNU Arm Embedded Toolchain（`arm-none-eabi-gcc`）

## 构建

```sh
cmake -B build_gcc -G Ninja
cmake --build build_gcc
```

产物在 `build_gcc/` 下：

- `F103-DAP-SWO-CDC-BLUEPILL.elf` / `.hex` / `.bin` / `.map`

默认目标为 STM32F103C8T6（64KB Flash / 20KB RAM），宏组合
`STM32F10X_MD BLUEPILL SWO_PB7`。其他板型用 `-DBOARD=...` 选择，
完整列表见 [../README.zh-CN.md](../README.zh-CN.md#支持的板型)。

默认构建 unRemap 版（对外调试口 SWDIO=PB9、SWCLK=PB8，本机 SWJ 调试口保持
可用）。加 `-DSWD_REMAP=ON` 可切换为 REMAP 版（对外调试口 PA13/PA14，接线
更方便，但固件运行后会禁用本机 SWJ 口，重刷本机固件需 BOOT0 或
connect-under-reset）。

## 烧录示例

```sh
# ST-Link
st-flash write build_gcc/F103-DAP-SWO-CDC-BLUEPILL.bin 0x8000000
# 或 OpenOCD
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg \
        -c "program build_gcc/F103-DAP-SWO-CDC-BLUEPILL.hex verify reset exit"
```

## 这些文件是怎么来的

原工程是 Keil uVision 工程，移植到 GCC 时的主要障碍和处理方式：

**USB 设备栈**：Keil 工程链接的 `USB_CM3.lib`（RL-USB 中间件）内部是 Arm 私有的
ORC 对象格式（magic `\xf7ORC`），GNU ld 无法识别。因此改用 `third_party/USBStack/` 下的 RL-USB
**源码版**——取自上游 x893/CMSIS-DAP 仓库，是 Arm 随 CMSIS-DAP Interface Firmware
以 Apache-2.0 发布的那一版，API 与 .lib 完全一致。许可说明见
[../THIRD-PARTY-NOTICES.zh-CN.md](../THIRD-PARTY-NOTICES.zh-CN.md)。

**GCC 适配文件**：

| 文件 | 作用 |
|------|------|
| `src/startup_stm32f10x_md.S` | GNU as 语法启动文件（原 ST 启动文件是 armasm 语法） |
| `cmake/stm32f10x.ld.in` | 链接脚本模板，Flash/RAM 尺寸由 CMake 按板型代入 |
| `cmake/arm-none-eabi.cmake` | CMake 交叉编译工具链文件 |
| `third_party/CMSIS/` | Arm CMSIS 5.6.0 头文件（Keil 下由其安装目录的 Pack 提供） |

**armcc 关键字适配**：`third_party/USBStack/` 的源码为 armcc 编写，移植时处理了
`__packed` 属性位置、`__inline` 的链接性、`__swi` / `__task`、armcc 内联汇编块，
以及 `U8`/`U32` 等类型改用 `<stdint.h>`。

**编译选项**：`-fshort-wchar` 是必需的——Keil 工程启用了 short wchar，USB 字符串
描述符用 `L"..."` 初始化 `U16` 数组，依赖 2 字节 `wchar_t`。
