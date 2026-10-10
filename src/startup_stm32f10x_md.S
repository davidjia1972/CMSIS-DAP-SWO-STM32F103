/**
 * startup_stm32f10x_md.S  --  GNU assembly startup for STM32F10x Medium Density
 *
 * GCC port of the Keil startup file User/startup_stm32f10x_md.s.
 * Exports the vector table as __Vectors (referenced by User/main.c).
 */
  .syntax unified
  .cpu cortex-m3
  .fpu softvfp
  .thumb

  .global __Vectors
  .global Reset_Handler

/* Linker script symbols */
  .word _sidata   /* start address of .data initializers in FLASH */
  .word _sdata    /* start address of .data in RAM */
  .word _edata    /* end address of .data in RAM */
  .word _sbss     /* start address of .bss */
  .word _ebss     /* end address of .bss */

/*----------------------------------------------------------------------------
  Vector table (STM32F10x Medium Density)
 *----------------------------------------------------------------------------*/
  .section .isr_vector,"a",%progbits
  .type __Vectors, %object
__Vectors:
  .word _estack                     /* Initial Main Stack Pointer */
  .word Reset_Handler
  .word NMI_Handler
  .word HardFault_Handler
  .word MemManage_Handler
  .word BusFault_Handler
  .word UsageFault_Handler
  .word 0
  .word 0
  .word 0
  .word 0
  .word SVC_Handler
  .word DebugMon_Handler
  .word 0
  .word PendSV_Handler
  .word SysTick_Handler
  /* External Interrupts */
  .word WWDG_IRQHandler
  .word PVD_IRQHandler
  .word TAMPER_IRQHandler
  .word RTC_IRQHandler
  .word FLASH_IRQHandler
  .word RCC_IRQHandler
  .word EXTI0_IRQHandler
  .word EXTI1_IRQHandler
  .word EXTI2_IRQHandler
  .word EXTI3_IRQHandler
  .word EXTI4_IRQHandler
  .word DMA1_Channel1_IRQHandler
  .word DMA1_Channel2_IRQHandler
  .word DMA1_Channel3_IRQHandler
  .word DMA1_Channel4_IRQHandler
  .word DMA1_Channel5_IRQHandler
  .word DMA1_Channel6_IRQHandler
  .word DMA1_Channel7_IRQHandler
  .word ADC1_2_IRQHandler
  .word USB_HP_CAN1_TX_IRQHandler
  .word USB_LP_CAN1_RX0_IRQHandler
  .word CAN1_RX1_IRQHandler
  .word CAN1_SCE_IRQHandler
  .word EXTI9_5_IRQHandler
  .word TIM1_BRK_IRQHandler
  .word TIM1_UP_IRQHandler
  .word TIM1_TRG_COM_IRQHandler
  .word TIM1_CC_IRQHandler
  .word TIM2_IRQHandler
  .word TIM3_IRQHandler
  .word TIM4_IRQHandler
  .word I2C1_EV_IRQHandler
  .word I2C1_ER_IRQHandler
  .word I2C2_EV_IRQHandler
  .word I2C2_ER_IRQHandler
  .word SPI1_IRQHandler
  .word SPI2_IRQHandler
  .word USART1_IRQHandler
  .word USART2_IRQHandler
  .word USART3_IRQHandler
  .word EXTI15_10_IRQHandler
  .word RTCAlarm_IRQHandler
  .word USBWakeUp_IRQHandler
  .word 0
  .word 0
  .word 0
  .word 0
  .word 0
  .word 0
  .word 0
  .word 0xF108F85F   /* @0x108: BootRAM workaround, same as Keil startup */
  .size __Vectors, . - __Vectors

/*----------------------------------------------------------------------------
  Reset handler: init .data/.bss, call SystemInit and main
 *----------------------------------------------------------------------------*/
  .section .text.Reset_Handler
  .weak Reset_Handler
  .type Reset_Handler, %function
Reset_Handler:
  ldr   sp, =_estack

/* Copy .data initializers from FLASH to RAM */
  ldr   r0, =_sdata
  ldr   r1, =_edata
  ldr   r2, =_sidata
  movs  r3, #0
  b     LoopCopyDataInit
CopyDataInit:
  ldr   r4, [r2, r3]
  str   r4, [r0, r3]
  adds  r3, r3, #4
LoopCopyDataInit:
  adds  r4, r0, r3
  cmp   r4, r1
  bcc   CopyDataInit

/* Zero fill .bss */
  ldr   r2, =_sbss
  ldr   r4, =_ebss
  movs  r3, #0
  b     LoopFillZerobss
FillZerobss:
  str   r3, [r2]
  adds  r2, r2, #4
LoopFillZerobss:
  cmp   r2, r4
  bcc   FillZerobss

  bl    SystemInit
  bl    __libc_init_array
  bl    main
LoopForever:
  b     LoopForever
  .size Reset_Handler, . - Reset_Handler

/*----------------------------------------------------------------------------
  Default handler: infinite loop, weakly aliased by all handlers
 *----------------------------------------------------------------------------*/
  .section .text.Default_Handler,"ax",%progbits
Default_Handler:
  b  Default_Handler
  .size Default_Handler, . - Default_Handler

  .macro def_irq_handler handler_name
  .weak \handler_name
  .thumb_set \handler_name, Default_Handler
  .endm

  def_irq_handler NMI_Handler
  def_irq_handler HardFault_Handler
  def_irq_handler MemManage_Handler
  def_irq_handler BusFault_Handler
  def_irq_handler UsageFault_Handler
  def_irq_handler SVC_Handler
  def_irq_handler DebugMon_Handler
  def_irq_handler PendSV_Handler
  def_irq_handler SysTick_Handler
  def_irq_handler WWDG_IRQHandler
  def_irq_handler PVD_IRQHandler
  def_irq_handler TAMPER_IRQHandler
  def_irq_handler RTC_IRQHandler
  def_irq_handler FLASH_IRQHandler
  def_irq_handler RCC_IRQHandler
  def_irq_handler EXTI0_IRQHandler
  def_irq_handler EXTI1_IRQHandler
  def_irq_handler EXTI2_IRQHandler
  def_irq_handler EXTI3_IRQHandler
  def_irq_handler EXTI4_IRQHandler
  def_irq_handler DMA1_Channel1_IRQHandler
  def_irq_handler DMA1_Channel2_IRQHandler
  def_irq_handler DMA1_Channel3_IRQHandler
  def_irq_handler DMA1_Channel4_IRQHandler
  def_irq_handler DMA1_Channel5_IRQHandler
  def_irq_handler DMA1_Channel6_IRQHandler
  def_irq_handler DMA1_Channel7_IRQHandler
  def_irq_handler ADC1_2_IRQHandler
  def_irq_handler USB_HP_CAN1_TX_IRQHandler
  def_irq_handler USB_LP_CAN1_RX0_IRQHandler
  def_irq_handler CAN1_RX1_IRQHandler
  def_irq_handler CAN1_SCE_IRQHandler
  def_irq_handler EXTI9_5_IRQHandler
  def_irq_handler TIM1_BRK_IRQHandler
  def_irq_handler TIM1_UP_IRQHandler
  def_irq_handler TIM1_TRG_COM_IRQHandler
  def_irq_handler TIM1_CC_IRQHandler
  def_irq_handler TIM2_IRQHandler
  def_irq_handler TIM3_IRQHandler
  def_irq_handler TIM4_IRQHandler
  def_irq_handler I2C1_EV_IRQHandler
  def_irq_handler I2C1_ER_IRQHandler
  def_irq_handler I2C2_EV_IRQHandler
  def_irq_handler I2C2_ER_IRQHandler
  def_irq_handler SPI1_IRQHandler
  def_irq_handler SPI2_IRQHandler
  def_irq_handler USART1_IRQHandler
  def_irq_handler USART2_IRQHandler
  def_irq_handler USART3_IRQHandler
  def_irq_handler EXTI15_10_IRQHandler
  def_irq_handler RTCAlarm_IRQHandler
  def_irq_handler USBWakeUp_IRQHandler
