; Since I'm writing asm first time, so I got help from deepseek...
BITS 64
org 0x400000
default rel
ehdr:
    db 0x7F, "ELF"
    db 2
    db 1
    db 1
    db 0
    dq 0
    dw 2
    dw 0x3E
    dd 1
    dq main
    dq phdr - ehdr
    dq 0
    dd 0
    dw ehdrsize
    dw phdrsize
    dw 1
    dw 0
    dw 0
    dw 0
ehdrsize equ $ - ehdr

phdr:
    dd 1
    dd 5
    dq 0
    dq ehdr
    dq ehdr
    dq filesize
    dq filesize
    dq 0x1000
phdrsize equ $ - phdr

main:
    pop rcx ; argc
    cmp rcx,2
    jb .exit_no_arg
    pop rdi ; argv[0]
    pop rdi ; argv[1]
    xor esi,esi
    xor edx,edx
    mov rax,2
    syscall
    test rax,rax ; test if success
    js .exit_fail_open

    mov rdi,rax
    sub rsp, 144
    mov rsi,rsp
    mov rax,5
    syscall
    mov r13,[rsp+48]
    add rsp,144

    ; store it somewhere

    mov r8,rdi
    xor rdi,rdi
    mov rsi,r13
    mov rdx,1
    mov r10,2
    xor r9,r9
    mov rax,9
    syscall
    test rax,rax
    js .exit_fail_store
    mov rdi, r8
    mov r14, rax;
    ; close the file since we no longer need it
    mov rax, 3
    syscall

    xor rdx,rdx
.loop:
    movzx ecx, byte [r14+rdx]
    inc rdx
    cmp rdx, r13
    jnz .loop

    jmp .exit
.exit_no_arg:
    mov eax,60
    mov edi,1
    syscall
.exit_fail_open:
    mov eax,60
    mov edi,2
    syscall
.exit_fail_store:
    mov eax,60
    mov edi,3
    syscall
.exit:
    mov eax, 60 ; sys_exit
    xor edi, edi
    syscall

filesize equ $ - ehdr