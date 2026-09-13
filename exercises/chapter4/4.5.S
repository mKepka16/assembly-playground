      //      where you do not know the values of x and y, write a short sequence of ARM assem-
      //      bly instructions to load the two numbers, compare them, and move the largest number
      //      into register r0.
      .data
      .align  2
num1: .word   6
num2: .word   9

      .text
      .global main

main: stmfd   sp!, {lr}

      ldr     r0, =num1
      ldmia   r0, {r0, r1}

      cmp     r0, r1
      movlt   r0, r1

      mov     r0, #0
      ldmfd   sp!, {pc}
