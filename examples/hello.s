.global _start

.section .text
_start:
    mov r0, #1              @ fd = stdout
    ldr r1, =msg
    ldr r2, =msg_len        @ length
    mov r7, #4              @ syscall: write
    svc #0

    mov r0, #0              @ exit code
    mov r7, #1              @ syscall: exit
    svc #0

.section .data
msg:
    .ascii "Hello, ARM!\n"
msg_len = . - msg
