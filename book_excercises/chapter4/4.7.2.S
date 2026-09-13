      .data
      .align  2
base: .word   9
txt:  .asciz  "Result of multiplication: %d\n"

      .text
      .global main

main:
      stmfd   sp!, {lr}
      ldr     r2, =base
      ldr     r2, [r2]

@ a) 10
@ lsl     r1, r2, #3
@ add     r1, r1, r2, lsl #1

@ b) 100
@ lsl     r1, r2, #7
@ sub     r1, r2, lsl #5
@ add     r1, r2, lsl #2

@ c) 575
@ lsl     r1, r2, #9
@ add     r1, r2, lsl #6
@ sub     r1, r2

@ d) 123
      lsl     r1, r2, #7
      sub     r1, r2, lsl #2
      sub     r1, r2

      ldr     r0, =txt
      bl      printf

      ldmfd   sp!, {lr}
      bx      lr
