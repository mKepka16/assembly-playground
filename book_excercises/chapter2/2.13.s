      .data
str:  .asciz "Michał Kępka!\n"  @ Define a null-terminated string

      .text
      .globl main
main: stmfd  sp!,{lr}           @ push return address onto stack
      ldr    r0, =str           @ load pointer to format string
      bl     printf             @ printf("Hello World\n");
      mov    r0, #0             @ move return code into r0
      ldmfd  sp!,{lr}           @ pop return address from stack
      mov    pc, lr             @ return from main
