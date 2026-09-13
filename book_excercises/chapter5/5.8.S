@ a1 - char dest[],
@ a2 - char src[],
@ a3 - int count
bytecopy:
          sub  a3, a3, #1
loop:     cmp  a3, #0
          blt  end
          ldrb r3, [a2, a3]
          strb r3, [a1, a3]
          sub  a3, a3, #1
          b    loop
end:      bx   lr
