      .data
      .align  2
x:    .word   1,2,3,4,5,6,7,8,9,10,11

      .text
      .global main
main: stmfd   sp!, {r4, r5, lr}
      ldr     r0, =x
      //      a
      mov     r1, #100
      str     r1, [r0, #32]

      //      b
      ldr     r1, [r0]
      str     r1, [r0, #40]

      //      c
      ldr     r1, [r0, #12]
      str     r1, [r0, #36]

      mov     r0, #0
      ldmfd   sp!, {r4, r5, pc}
