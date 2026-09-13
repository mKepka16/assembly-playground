      .data
      .align  2
msg:  .asciz  "Hi!\n"

      .text
      .global main

main:
      stmfd   sp!, {r4-r6, lr}
      mov     r4, #0
      ldr     r5, =msg
loop: mov     r0, r5
      bl      printf
      add     r4, r4, #1
      cmp     r4, #10
      blt     loop

      mov     r0, #0
      ldmfd   sp!, {r4-r6, pc}
