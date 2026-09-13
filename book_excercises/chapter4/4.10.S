
           .data
           .align  2
file_name: .asciz  "input.txt"
msg:       .asciz  "File descriptor: %d\n"

           .text
           .global main

main:      stmfd   sp!, {r4, r7, r8, lr}

           ldr     r0, =file_name
           mov     r1, #0  @ read-only flag
           mov     r7, #5
           swi     #0

           mov     r1, r0
           ldr     r0, =msg
           bl      printf

           mov     r0, #0
           ldmfd   sp!, {r4, r7, r8, pc}
