        .section .data
input_string:   .asciz "Hello world!"

        # tohost/fromhost are data locations used by Spike
        .align 8
tohost: .byte 0
        .align 8
fromhost: .byte 0

        
        .section .text
        .globl _start
_start:
        
        la a0, input_string     # Load the address of the input string into a0
        li t1, 97
        li t2, 122

label1:
        lb t0, 0(a0)
        beqz t0, end_program
        blt t0,t1,label2
        bgt t0,t2,label2

        li t3,32
        sub t0,t0,t3
        sb t0, 0(a0)

label2:
        addi a0,a0,1
        j label1
        
end_program:
        # jump here when you're done
        j end_program

