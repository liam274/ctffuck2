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
    dd 7
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
    jb exit_no_arg
    pop rdi ; argv[0]
    pop rdi ; argv[1]
    xor esi,esi
    xor edx,edx
    mov rax,2
    syscall
    test rax,rax ; test if success
    js exit_fail_open
    mov rdi,rax ; fd

    ; get file length
    mov rax,8
    xor rsi,rsi
    mov rdx,2
    syscall
    test rax,rax
    je exit_fail_lseek
    mov r13,rax
    ; store size in r13

    ; store it somewhere(mmap)
    mov r8,rdi
    xor rdi,rdi
    mov rsi,r13
    mov rdx,1
    mov r10,2
    xor r9,r9
    mov rax,9
    syscall
    test rax,rax
    js exit_fail_store

    mov rdi, r8 ; recover registries
    mov r14, rax ; base addr
    ; close the file since we no longer need it
    mov rax, 3
    syscall

    ; init
    xor rdx,rdx ; init pointer
    mov r15,-1 ; last
    xor rcx,rcx ; clear
loop:
    movzx rcx, byte [r14+rdx]
    ; digit filter
    sub rcx,48
    jb loop
    cmp rcx,9
    ja loop
    ; calc arg
    sub r15,rcx
    jmp [rcx*8+jump_table]
    ;loop end
    jmp exit
exit_no_arg:
    mov edi,1
    jmp norm_exit
exit_fail_open:
    mov edi,2
    jmp norm_exit
exit_fail_store:
    mov edi,3
    jmp norm_exit
exit_fail_lseek:
    mov edi,4
    jmp norm_exit
exit:
    xor edi, edi
    jmp norm_exit
norm_exit:
    mov eax, 60 ; sys_exit
    syscall

next:
    inc rdx
    cmp rdx, r13
    jnz loop
    jmp exit
ins_read:
    jmp next
ins_add:
    jmp next
ins_set:
    jmp next
ins_push:
    jmp next
ins_print:
    jmp next
ins_swap:
    jmp next
ins_grow:
    jmp next
ins_inp:
    jmp next
ins_jmpm:
    jmp next
ins_revf:
    jmp next

align 8
jump_table:
    dq ins_read
    dq ins_add
    dq ins_set
    dq ins_push
    dq ins_print
    dq ins_swap
    dq ins_grow
    dq ins_inp
    dq ins_jmpm
    dq ins_revf

memory: times 10 dq 0

filesize equ $ - ehdr