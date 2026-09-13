shift_left:
@ 0 is not shift allowed value in below instructions
            cmp   r2, #0
            moveq pc, lr

            stmfd sp!, {r4-r6, lr}

@ Capped shift
            mov   r3, r2
            cmp   r3, #32
            movgt r3, #32

@ Shift hi left by capped shift
            lsl   r1, r1, r3

@ Shift lo_cpy accordingly
            mov   r4, r0
            rsble r5, r2, #32  @ uses flags set by cmp above
            lsrle r4, r4, r5
            subgt r5, r2, #32
            lslgt r4, r4, r5

@ sum up hi
            add   r1, r1, r4

@ shift lo
            lsl   r0, r0, r3

            ldmfd sp!, {r4-r6, pc}
