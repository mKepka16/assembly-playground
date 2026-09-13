        //      Write the ARM assembly code to load the numbers stored in num1 and num2, add
        //      them together, and store the result in numsum. Use only r0 and r1.
        .data
        .align  2
num1:   .word   6
num2:   .word   9

        .bss
        .align  2
numsum: .skip   4

        .text
        .global main

main:   stmfd   sp!, {lr}

        ldr     r0, =num1
        ldr     r0, [r0]
        ldr     r1, =num2
        ldr     r1, [r1]
        add     r0, r0, r1
        ldr     r1, =numsum
        str     r0, [r1]

        mov     r0, #0
        ldmfd   sp!, {pc}

        //      It generates unnecessary addresses in literal pool, but works
