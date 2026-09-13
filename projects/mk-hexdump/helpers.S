                        #include "defs.inc"

                        .equ     ASCII_RANGE_MIN, 32
                        .equ     ASCII_RANGE_MAX, 127
                        .equ     ASCII_UNKNOWN_CODE, 46  @ '.' character

                        .section .rodata
error_msg:              .asciz   "Error ocurred (%s), errno: %d\n"
address_tmpl:           .asciz   "%08zx  "
hex_sec_tmpl:           .asciz   "%02x "
hex_sec_empt_tmpl:      .asciz   "   "
space:                  .asciz   " "
ascii_section_prfx:     .asciz   "|"
ascii_section_sufx:     .asciz   "|\n"
ascii_character:        .asciz   "%c"

                        .text
@ extract_filename
@ r0 - argc
@ r1 - argv
@ returns: argv[1], NULL if r0 < 2
                        .global  extract_filename
                        .type    extract_filename, %function
extract_filename:
                        cmp      r0, #2
                        movlt    r0, #NULL
                        movlt    pc, lr

                        ldr      r0, [r1, #4]
                        mov      pc, lr
                        .size    extract_filename, . - extract_filename



@ print_error
@ r0 - -errno
@ r1 - error message prefix
@ return: -errno
                        .global  print_error
                        .type    print_error, %function
print_error:
                        stmfd    sp!, {r4, lr}
                        mov      r4, r0                  @ store in r3 -errno
                        cmp      r4, #0
                        bge      print_error_exit
                        rsb      r2, r0, #0              @ store in r2 errno
                        ldr      r0, =error_msg
                        bl       printf

print_error_exit:
                        mov      r0, r4
                        ldmfd    sp!, {r4, pc}
                        .size    print_error, . - print_error


@ print_addr_prefix
@ r0 - address
@ return: void
                        .global  print_addr_prefix
                        .type    print_addr_prefix, %function
print_addr_prefix:
                        stmfd    sp!, {r4, lr}
                        mov      r1, r0
                        ldr      r0, =address_tmpl
                        bl       printf
                        mov      r0, #0
                        ldmfd    sp!, {r4, pc}
                        .size    print_addr_prefix, . - print_addr_prefix


@ print_hex_section
@ r0 - data pointer
@ r1 - count
                        .global  print_hex_section
                        .type    print_hex_section, %function
print_hex_section:
                        stmfd    sp!, {r4-r8, lr}
                        ldr      r4, =hex_sec_tmpl
                        ldr      r5, =hex_sec_empt_tmpl
                        mov      r6, #0                  @ loop iterator
                        mov      r7, r0                  @ data pointer
                        mov      r8, r1                  @ count

hex_section_loop:
                        cmp      r6, r8
                        movge    r0, r5
                        bge      hex_print
                        mov      r0, r4
                        mov      r1, #0
                        add      r1, r7, r6
                        ldr      r1, [r1]
                        and      r1, r1, #0xFF
hex_print:              bl       printf
                        add      r6, r6, #1
                        cmp      r6, #8
                        blt      hex_section_loop

                        ldr      r0, =space
                        bl       printf

                        mov      r0, #0
                        ldmfd    sp!, {r4-r8, pc}
                        .size    print_hex_section, . - print_hex_section



@ print_hex_full_section
@ r0 - data pointer
@ r1 - count
                        .global  print_hex_full_section
                        .type    print_hex_full_section, %function
print_hex_full_section:
                        stmfd    sp!, {r4-r6, lr}

                        mov      r4, r0                  @ data pointer
                        mov      r5, r1                  @ count
                        bl       print_hex_section

                        add      r4, r4, #8
                        subs     r5, r5, #8
                        movlt    r5, #0
                        mov      r0, r4
                        mov      r1, r5
                        bl       print_hex_section

                        mov      r0, #0
                        ldmfd    sp!, {r4-r6, pc}
                        .size    print_hex_full_section, . - print_hex_full_section


@ print_ascii_section
@ r0 - data pointer
@ r1 - count
                        .global  print_ascii_section
                        .type    print_ascii_section, %function
print_ascii_section:
                        stmfd    sp!, {r4-r8, lr}
                        mov      r4, r0                  @ save data pointer to r4
                        mov      r5, r1                  @ save count to r5
@ Print prefix
                        ldr      r0, =ascii_section_prfx
                        bl       printf

                        mov      r6, #0                  @ initialize iterator
                        ldr      r7, =ascii_character    @ cache ascii char template address
ascii_section_loop:     cmp      r6, r5
                        bge      ascii_section_end

                        mov      r0, r7
                        ldrb     r1, [r4, r6]

                        cmp      r1, #ASCII_RANGE_MIN
                        movlt    r1, #ASCII_UNKNOWN_CODE
                        cmp      r1, #ASCII_RANGE_MAX
                        movgt    r1, #ASCII_UNKNOWN_CODE

                        bl       printf

                        add      r6, r6, #1
                        b        ascii_section_loop
ascii_section_end:

                        ldr      r0, =ascii_section_sufx
                        bl       printf

                        mov      r0, #0
                        ldmfd    sp!, {r4-r8, pc}
                        .size    print_ascii_section, . - print_ascii_section


                        .section .note.GNU-stack,"",%progbits
