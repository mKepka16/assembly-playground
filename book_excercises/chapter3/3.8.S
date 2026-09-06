      .data
arr1: .word   2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32

      .bss
arr2: .skip   64

      .text
      .global main
main: stmfd   sp!, {lr, r4, r5}
      ldr     r0, =arr1 // source
      ldr     r1, =arr2 // destination
      ldmia   r0!, {r2,r3,r4,r5}
      stmia   r1!, {r2,r3,r4,r5}

      ldmia   r0!, {r2,r3,r4,r5}
      stmia   r1!, {r2,r3,r4,r5}

      ldmia   r0!, {r2,r3,r4,r5}
      stmia   r1!, {r2,r3,r4,r5}

      ldmia   r0!, {r2,r3,r4,r5}
      stmia   r1!, {r2,r3,r4,r5}

      mov     r0, #0
      ldmfd   sp!, {pc, r4, r5}
