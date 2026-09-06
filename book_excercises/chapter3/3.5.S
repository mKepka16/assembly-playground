      .data
nums: .word   7,3,21,10

      .text
      .global main
main: str     lr, [sp, #-4]!
      ldr     r0, =nums
      //      ldmia r0, {r3,r5,r6,r9} // a)
      ldr     r3, [r0]
      ldr     r5, [r0, #4]!
      ldr     r6, [r0, #4]
      ldr     r9, [r0, #8]
      ldr     lr, [sp], #4
      mov     r0, #0
      mov     pc, lr
