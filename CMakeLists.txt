cmake_minimum_required(VERSION 3.20)

set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/arm-none-eabi.cmake"
    CACHE FILEPATH "CMake toolchain file")

project(CMSIS-DAP_SWO C ASM)

set(CMAKE_C_STANDARD 99)

#-------------------------------------------------------------------------------
# 目标板型
#
# 下表对应原 Keil 工程的 9 个 target（该工程已移除，见 README）。各板型的引脚定义
# 都在 src/dap/DAP_config.h 的对应分支里，这里只负责传递正确的宏组合和存储器尺寸。
#
# 注意：只有 BLUEPILL 经过实机验证。其余板型的宏组合照搬原 Keil 工程，可以编译，
#      但没有对应硬件可供测试。
#-------------------------------------------------------------------------------
set(BOARD "BLUEPILL" CACHE STRING "Target board")
set_property(CACHE BOARD PROPERTY STRINGS
    BLUEPILL BOARD_V1 BOARD_V2 BOARD_V2_F102
    STLINK_V20 STLINK_V21 STLINK_V2A STLINK_V2B BOARD_STM32RF)

if(BOARD STREQUAL "BLUEPILL")            # STM32F103C8  <- Keil target STM32F103-BLUEPILL
  set(BOARD_DEFS   BLUEPILL SWO_PB7)
  set(FLASH_SIZE_K 64)
  set(RAM_SIZE_K   20)
elseif(BOARD STREQUAL "BOARD_V1")        # STM32F103CB  <- STM32F103-BOARD_V1
  set(BOARD_DEFS   BOARD_V1 SWO_PA10)
  set(FLASH_SIZE_K 128)
  set(RAM_SIZE_K   20)
elseif(BOARD STREQUAL "BOARD_V2")        # STM32F103C8  <- STM32F103-BOARD_V2
  set(BOARD_DEFS   BOARD_V2 SWO_PA10)
  set(FLASH_SIZE_K 64)
  set(RAM_SIZE_K   20)
elseif(BOARD STREQUAL "BOARD_V2_F102")   # STM32F102C8  <- STM32F102-BOARD_V2 (48MHz)
  set(BOARD_DEFS   BOARD_V2 SWO_PA10 STM32F102C8)
  set(FLASH_SIZE_K 64)
  set(RAM_SIZE_K   10)
elseif(BOARD STREQUAL "STLINK_V20")      # STM32F103C8  <- STM32F103-STLINK_V20 (仅 SWD)
  set(BOARD_DEFS   STLINK_V20 SWO_PA10)
  set(FLASH_SIZE_K 64)
  set(RAM_SIZE_K   20)
elseif(BOARD STREQUAL "STLINK_V21")      # STM32F103C8  <- STM32F103-STLINK_V21 (仅 SWD)
  set(BOARD_DEFS   STLINK_V21 SWO_PA10)
  set(FLASH_SIZE_K 64)
  set(RAM_SIZE_K   20)
elseif(BOARD STREQUAL "STLINK_V2A")      # STM32F103CB  <- STM32F103-STLINK_V2A (仅 SWD)
  set(BOARD_DEFS   STLINK_V2A SWO_PA10)
  set(FLASH_SIZE_K 128)
  set(RAM_SIZE_K   20)
elseif(BOARD STREQUAL "STLINK_V2B")      # STM32F103CB  <- STM32F103-STLINK_V2B
  set(BOARD_DEFS   STLINK_V2B SWO_PA10)
  set(FLASH_SIZE_K 128)
  set(RAM_SIZE_K   20)
elseif(BOARD STREQUAL "BOARD_STM32RF")   # STM32F103C8  <- STM32RF (仅 SWD)
  set(BOARD_DEFS   BOARD_STM32RF SWO_PA10)
  set(FLASH_SIZE_K 64)
  set(RAM_SIZE_K   20)
else()
  message(FATAL_ERROR "未知的 BOARD=\"${BOARD}\"；可选值见上面的 set_property 列表。")
endif()

# SWD_REMAP=ON:  对外调试口走 PA13/PA14 (4 脚 SWD 排针, 但会禁用本机 SWJ 口,
#                重刷本机固件需 BOOT0 或 connect-under-reset)
# SWD_REMAP=OFF: 对外调试口走 PB9/PB8, 本机 PA13/PA14 调试口保持可用, 可随时重烧
option(SWD_REMAP "Use remapped PA13/PA14 as debug-out pins (disables own SWJ port)" OFF)

if(SWD_REMAP)
  if(BOARD STREQUAL "BLUEPILL")
    list(APPEND BOARD_DEFS SWD_REMAP)
  else()
    message(WARNING "SWD_REMAP 仅在 BOARD=BLUEPILL 下生效 "
                    "(src/dap/DAP_config.h 与 src/main.c 均以 BLUEPILL 为前提), 当前 BOARD=${BOARD}, 已忽略。")
  endif()
endif()

if(BOARD STREQUAL "BOARD_V2_F102")
  message(WARNING "STM32F102C8 只有 10K RAM, 而本固件约需 18.7K (含 3.5K 栈/堆预留), "
                  "链接将因 RAM 溢出失败。原 Keil 工程依赖 ARM microlib 才勉强放得下。")
endif()

# 输出名沿用原 Keil 工程的命名习惯
if(BOARD STREQUAL "BOARD_V2_F102")
  set(TARGET_NAME F102-DAP-SWO-CDC-BOARD_V2)
else()
  set(TARGET_NAME F103-DAP-SWO-CDC-${BOARD})
endif()

# 按板型生成链接脚本 (存储器尺寸随板型变化)
set(LINKER_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/stm32f10x-${BOARD}.ld")
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/stm32f10x.ld.in" "${LINKER_SCRIPT}" @ONLY)

message(STATUS "Board      : ${BOARD}")
message(STATUS "Board defs : ${BOARD_DEFS}")
message(STATUS "Memory     : ${FLASH_SIZE_K}K Flash / ${RAM_SIZE_K}K RAM")
message(STATUS "Output     : ${TARGET_NAME}")

add_executable(${TARGET_NAME}
    # 应用层
    src/main.c
    src/system_stm32f10x.c
    src/startup_stm32f10x_md.S

    # CMSIS-DAP 协议核心 (引脚定义见 src/dap/DAP_config.h)
    src/dap/DAP.c
    src/dap/JTAG_DP.c
    src/dap/SW_DP.c
    src/dap/SWO.c

    # USB 描述符配置、F103 USB 硬件层、HID/CDC 应用回调
    src/usb/usb_config.c
    src/usb/usbd_STM32F103.c
    src/usb/usbd_user_hid.c
    src/usb/usbd_user_cdc_acm.c

    # 第三方: ST 标准外设库 (按需裁剪)
    third_party/STM32F10x_StdPeriph_Driver/src/misc.c
    third_party/STM32F10x_StdPeriph_Driver/src/stm32f10x_flash.c
    third_party/STM32F10x_StdPeriph_Driver/src/stm32f10x_gpio.c
    third_party/STM32F10x_StdPeriph_Driver/src/stm32f10x_rcc.c

    # 第三方: Arm 的 STM32F10x CMSIS 驱动层 (SWO 走 USART1 + DMA)
    third_party/STM32F10x_ARM_Driver/DMA_STM32F10x.c
    third_party/STM32F10x_ARM_Driver/GPIO_STM32F10x.c
    third_party/STM32F10x_ARM_Driver/USART_STM32F10x.c

    # 第三方: RL-USB 设备栈源码 (替代 Keil 预编译的 USB_CM3.lib)
    third_party/USBStack/src/usbd_core.c
    third_party/USBStack/src/usbd_core_cdc.c
    third_party/USBStack/src/usbd_core_hid.c
    third_party/USBStack/src/usbd_core_msc.c
    third_party/USBStack/src/usbd_cdc_acm.c
    third_party/USBStack/src/usbd_hid.c
    third_party/USBStack/src/usbd_msc.c
)

target_include_directories(${TARGET_NAME} PRIVATE
    src
    src/dap
    src/usb
    third_party/USBStack/inc
    third_party/STM32F10x_ARM_Driver
    third_party/STM32F10x_StdPeriph_Driver/inc
    third_party/CMSIS/Include
    third_party/CMSIS/Driver/Include
)

target_compile_definitions(${TARGET_NAME} PRIVATE
    USE_STDPERIPH_DRIVER
    STM32F10X_MD
    ${BOARD_DEFS}
    # armcc 关键字映射到 GCC (Cortex-M3 硬件支持非对齐访问, __packed 可以为空)
    __weak=__attribute__\(\(weak\)\)
    __forceinline=__attribute__\(\(always_inline\)\)\ inline
    __packed=
)

set(CPU_FLAGS -mcpu=cortex-m3 -mthumb)

target_compile_options(${TARGET_NAME} PRIVATE
    ${CPU_FLAGS}
    -Os
    -ffunction-sections
    -fdata-sections
    -Wall
    -Wno-unknown-pragmas
    # Keil 工程启用了 short wchar (USB 字符串描述符用 L"..." 初始化 U16 数组)
    -fshort-wchar
    $<$<COMPILE_LANGUAGE:C>:-fomit-frame-pointer>
)

target_link_options(${TARGET_NAME} PRIVATE
    ${CPU_FLAGS}
    -T${LINKER_SCRIPT}
    -specs=nano.specs
    -specs=nosys.specs
    -Wl,--gc-sections
    -Wl,--no-wchar-size-warning
    -Wl,-Map=${TARGET_NAME}.map
    -Wl,--print-memory-usage
)

set_target_properties(${TARGET_NAME} PROPERTIES
    OUTPUT_NAME ${TARGET_NAME}
    SUFFIX .elf
    LINK_DEPENDS ${LINKER_SCRIPT}
)

# 生成 hex / bin 并打印段大小
add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ihex   $<TARGET_FILE:${TARGET_NAME}> ${TARGET_NAME}.hex
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${TARGET_NAME}> ${TARGET_NAME}.bin
    COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${TARGET_NAME}>
    COMMENT "Generating ${TARGET_NAME}.hex / .bin"
)
