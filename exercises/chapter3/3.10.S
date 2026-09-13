      .data
      .align  2
x:    .word   1,2,3,4,5,6,7,8,9,10,11
i:    .word   2
j:    .word   4

      .text
      .global main
main: stmfd   sp!, {r4, lr}
      ldr     r0, =x
      ldr     r1, =i
      ldr     r1, [r1]
      ldr     r2, =j
      ldr     r2, [r2]
      //      a
      str     r2, [r0, r1, lsl #2]

      //      b
      ldr     r4, [r0, r1, lsl #2]
      str     r4, [r0, r2, lsl #2]

      //      c
      ldr     r4, [r0, r2, lsl #3]
      str     r4, [r0, r1, lsl #2]

      mov     r0, #0
      ldmfd   sp!, {r4, pc}
