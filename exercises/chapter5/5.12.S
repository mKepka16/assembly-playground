           .data
           .align  2
p_msg:     .asciz  "Enter x: \n";
s_msg:     .asciz  "%d"
p2_msg:    .asciz  "%d! = %d\n"

           .text
           .global main
main:
           stmfd   sp!, {r4-r8, lr}

           ldr     r4, =p_msg
           ldr     r5, =s_msg
           ldr     r6, =p2_msg
           sub     sp, sp, #4

loop:      mov     r0, r4
           bl      printf

           mov     r0, r5
           mov     r1, sp
           bl      scanf

           cmp     r0, #1
           bne     done
           ldr     r7, [sp]
           mov     r0, r7
           bl      factorial
           mov     r2, r0
           mov     r1, r7
           mov     r0, r6
           bl      printf
           b       loop
done:
           mov     r0, #0
           add     sp, sp, #4
           ldmfd   sp!, {r4-r8, pc}

factorial: cmp     r0, #2
           movlt   r0, #1
           bxlt    lr

           stmfd   sp!, {r4, lr}
           mov     r4, r0
           sub     r0, r0, #1
           bl      factorial
           mul     r0, r0, r4

           ldmfd   sp!, {r4, pc}
