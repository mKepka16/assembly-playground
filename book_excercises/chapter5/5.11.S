         .data
         .align  2
str_fmt: .asciz  "%d"

         .text
         .global main
main:    stmfd   sp!, {r4, lr}

         ldr     r4, =str_fmt
         sub     sp, sp, #8
@ preparing arugments
         mov     r0, r4
         mov     r1, sp
         bl      scanf

         mov     r0, r4
         add     r1, sp, #4
         bl      scanf

         ldmia   sp, {r0, r1}
         add     r0, r0, r1

         add     sp, sp, #8

         ldmfd   sp!, {r4, pc}
