minsix: stmfd sp!, {r4-r5}
        add   r4, sp, #8  @ load argument 5,6 into regs r4,r5
        ldmfd r4, {r4-r5}

        cmp   r1, r0
        movlt r0, r1

        cmp   r3, r2
        movlt r2, r3

        cmp   r2, r0
        movlt r0, r2

        cmp   r5, r4
        movlt r4, r5

        cmp   r4, r0
        movlt r0, r4

        ldmfd sp!, {r4-r5}
        bx    lr
