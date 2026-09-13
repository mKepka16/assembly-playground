      .data
      .align  2
x:    .word   7
y:    .word   5
msg:  .asciz  "Maximum value is: %d\n"

      .text
      .global main
main:
      stmfd   sp!, {r4, lr}

      ldr     r0, =x
      ldmia   r0, {r0, r1}
      bl      max
      mov     r1, r0
      ldr     r0, =msg
      bl      printf

      mov     r0, #0
      ldmfd   sp!, {r4, pc}

max:
      cmp     a1, a2
      movlt   a1, a2
      mov     pc, lr
