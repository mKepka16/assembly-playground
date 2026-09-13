@ Assuming that a is stored in register r0 and b is stored in register r1, show the ARM
@ assembly code that is equivalent to the following C code.
      .data
      .align  2
a:    .word   11
b:    .word   7

      .text
      .global main

main: stmfd   sp!, {lr}

      ldr     r0, =a
      ldmia   r0, {r0, r1}
      tst     r0, #1
      mvnne   r0, r0
      addne   r0, #1
      addeq   r1, r1, #7

      mov     r0, #0
      ldmfd   sp!, {pc}
