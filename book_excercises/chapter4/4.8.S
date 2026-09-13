      .data
      .align  2
a:    .word   19, 15
b:    .word   20, 15

      .text
      .global main

main:
      stmfd   sp!, {r4, lr}
      ldr     r0, =a
      ldmia   r0, {r0, r1, r2, r3}
@ a)
@ cmp     r1, r3
@ cmpeq   r0, r2

@ b)
@ mov     r3, r1, lsl #1
@ add     r3, r0, lsr #31
@ mov     r2, r0, lsl #1
@ or even better
@ adds    r2, r0, r0      @ lo = 2*lo, carry-out = old bit 31
@ adc     r3, r1, r1      @ hi = 2*hi + carry

@ c)
@ adds    r0, r0, r2
@ adc     r1, r1, r3

@ d)
      subs    r0, r0, r2
      sbc     r1, r1, r3


      ldmfd   sp!, {r4, lr}
      bx      lr
