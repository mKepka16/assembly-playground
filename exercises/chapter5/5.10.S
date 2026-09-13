average:
@ r4 - array pointer
@ r5 - array size
@ r6 - rest accumulator
@ r7 - average
@ r8 - item average
@ r9 - iterator
         stmfd sp!, {r4-r10, lr}

@ Move initial arguments
         mov   r4, r0
         mov   r5, r1
         mov   r6, #0
         mov   r7, #0
         mov   r9, #0

         cmp   r5, #1
         blt   done

loop:
@ load array item
         ldr   r8, [r4, r9, lsl #2]

@ execute division and save result to r8
         mov   r0, r8
         mov   r1, r5
         bl    divide
         mul   r10, r0, r5   @ q * n
         sub   r10, r8, r10  @ remainder = a_i - q*n
         add   r6, r6, r10   @ accumulate remainders
         mov   r8, r0

@ add item average to global average
         add   r7, r7, r8
@ increment iterator
         add   r9, r9, #1
@ if iterator < array size then continue
         cmp   r9, r5
         blt   loop

         mov   r0, r6
         mov   r1, r5
         bl    divide
         add   r7, r7, r0

done:    mov   r0, r7

         ldmfd sp!, {r4-r10, pc}
