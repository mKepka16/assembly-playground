         .data
         .align  2
num1:    .word   1574342
str_fmt: .asciz  "Number of ones in number %d is %d\n"

         .text
         .global main
main:    stmfd   sp!, {r4, lr}

@ r1 - iteration, r2 - num of ones, r3 - num1, r4 - num1 copy
         mov     r1, #0
         mov     r2, #0
         ldr     r3, =num1
         ldr     r3, [r3]
         mov     r4, r3

loop:
         tst     r3, #0x1
         addne   r2, r2, #1
         lsr     r3, r3, #1
         add     r1, r1, #1
         cmp     r1, #32
         bne     loop

         ldr     r0, =str_fmt
         mov     r1, r4
         bl      printf

         mov     r0, #0
         ldmfd   sp!, {r4, pc}
