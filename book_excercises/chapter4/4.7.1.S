          .data
          .align  2
constant: .word   575
base:     .word   2

          .text
          .global main

main:     ldr     r2, =constant
          ldmia   r2, {r2, r3}
          mov     r0, #0 // acumulator
          mov     r1, #0 // r1 is iterator
loop:
          add     r0, r3
          add     r1, #1
          cmp     r1, r2
          bne     loop
          bx      lr
