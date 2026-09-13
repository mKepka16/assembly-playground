                      #include "defs.inc"

                      .section .rodata
filename_err:         .asciz   "Required argument: filename.\n"
open_file:            .asciz   "open file"
read_file:            .asciz   "read file"
newline:              .asciz   "\n"

                      .text
                      .global  main
                      .type    main, %function
main:                 stmfd    sp!, {r4-r6, lr}

@ Retreving filename
                      bl       extract_filename
                      cmp      r0, #NULL
                      bne      extract_filename_suc
                      ldr      r0, =filename_err
                      bl       printf
                      mov      r0, #1
                      b        exit
extract_filename_suc:
@ Opening file
                      mov      r0, r0
                      mov      r1, #O_RDONLY
                      mov      r7, #SC_OPEN
                      svc      #0

                      cmp      r0, #0
                      bgt      open_suc
                      ldr      r1, =open_file
                      bl       print_error
                      mov      r0, #1
                      b        exit
open_suc:
@ Reading section
                      mov      r4, r0       @ save file descriptor to r4
                      sub      sp, sp, #16  @ 16B of stack for each hexdump line
                      mov      r6, #0       @ address counter

read_loop:            mov      r0, r4
                      mov      r1, sp
                      mov      r2, #16
                      mov      r7, #SC_READ
                      svc      #0

                      cmp      r0, #0
                      beq      read_finished
                      bgt      read_success
                      ldr      r1, =read_file
                      bl       print_error
                      b        read_exit
read_success:
                      mov      r5, r0       @ backup read bytes to r5

                      mov      r0, r6
                      bl       print_addr_prefix
                      add      r6, r6, r5   @ update address counter

                      mov      r0, sp
                      mov      r1, r5
                      bl       print_hex_full_section

                      mov      r0, sp
                      mov      r1, r5
                      bl       print_ascii_section

                      b        read_loop




                      mov      r1, #0
read_finished:
                      mov      r0, r6
                      bl       print_addr_prefix

                      ldr      r0, =newline
                      bl       printf

                      mov      r0, #0
read_exit:            add      sp, sp, #16
exit:
                      ldmfd    sp!, {r4-r6, pc}

                      .section .note.GNU-stack,"",%progbits
