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

    ; --- set raw mode --- ;

    mov rax, 16
    mov rdi, 0
    mov rsi, TCGETS
    mov rdx, old_termios
    syscall

    mov rsi, old_termios
    mov rdi, new_termios
    mov rcx, 60
    rep movsb

    mov eax, dword [new_termios + 12]
    and eax, ~(ICANON | ECHO)
    mov dword [new_termios + 12], eax

    mov byte [new_termios + 16 + 6], 1
    mov byte [new_termios + 16 + 5], 0
    
    mov rax, 16
    mov rdi, 0
    mov rsi, TCSETS
    mov rdx, new_termios
    syscall

    ; init
    xor rdx,rdx ; ctx->pointer
    mov r15,-1 ; last
    xor rcx,rcx ; arg
    xor rbx,rbx ; head_pointer
    xor r8b,r8b ; counter
    ; 0 = read_counter
    ; 1 = add_counter
    ; 2 = swap counter
    ; 3 = grow counter
    ; 4 = jmpm counter
    ; 5 = revf coutner
    mov r9b, 0b00011000 ; flag
    ; 0 = zf
    ; 1 = sf
    ; 2 = cf
    ; 3 = if
    ; 4 = of
    ; 5 = trans_ok
loop:
    movzx rcx, byte [r14+rdx] ; get char
    ; digit filter
    sub rcx,'0'
    jb next
    cmp rcx,9
    ja next
loop_exe:
    ; calc arg
    test r15,r15 ; set flag
    js .there ; reduce jmps, generally
    .here:
    mov rax,r15
    sub rax,rcx
    mov r15,rcx
    mov rcx,rax
    jmp [r15*8+jump_table]
    .there:
    mov r15,rcx
    add r15,rcx
    jmp .here
    ;loop end
next:
    inc rdx
    cmp rdx, r13 ; check if reached end
    jnz loop
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
    ; recover to normal mode
    mov rax, 16
    mov rdi, 0
    mov rsi, TCSETS
    mov rdx, old_termios
    syscall
    ; exit
    mov eax, 60 ; sys_exit
    syscall

ins_read:
    push .start ; set return addr
    push rcx
    jmp get_abs
    .start:
    pop rcx ; get the abs
    test r8b, 0b10000000 ; if counter ok
    jz .next ; only one parm
    push .return_here
    push 0
    jmp get_val ; at(0)
    .return_here:
    pop rax
    push [memory+rcx*8]
    pop [memory+rax*8]
    push .finish
    jmp setf
    .next:
        push .finish
        push rcx
        jmp push_in
    .finish:
    xor r8b, 0b10000000
    jmp next
ins_add:
    test r8b,0b01000000
    jz .next
    push .return_here
    push 1
    jmp get_val
    .return_here:
    pop rax
    add [memory+rax*8],rcx
    push .finish
    jmp setf
    .next:
        push .finish
        push rcx
        jmp push_in
    .finish:
    xor r8b,0b01000000
    jmp next
ins_set:
    push .start
    push rcx
    jmp get_abs
    .start:
    pop rcx
    mov [memory+rcx*8],0
    or r9b,0b10000000
    and r9b,0b10111111
    jmp next
ins_push:
    push next
    push rcx
    jmp push_in
ins_print:
    test r9b,0b00001000
    jz next
    push .start
    push rcx
    jmp get_abs
    .start:
    pop rcx
    cmp qword [memory+rcx*8], 0
    jz next
    mov rax, 1
    push rdi
    mov rdi,1
    push rdx
    lea rsi, [memory+rcx*8]
    mov rdx, 1
    syscall
    pop rdx
    pop rdi
    jmp next
ins_swap:
    test r8b,0b00100000
    jz .next
    push .start
    push rcx
    jmp get_abs
    .start:
    pop rcx
    push .return_here
    push 2
    jmp get_val
    .return_here:
    pop rax
    push [memory+rax*8]
    push [memory+rcx*8]
    pop [memory+rax*8]
    pop [memory+rcx*8]
    jmp .finish
    .next:
        push .finish
        push rcx
        jmp push_in
    .finish:
    xor r8b,0b00100000
    jmp next
ins_grow:
    test r8b,0b00010000
    jz .next
    push .start
    push rcx
    jmp get_abs
    .start:
    pop rcx
    push .return_here
    push 3
    jmp get_val
    .return_here:
    pop rax
    push .finish
    push rax
    jmp [rax*8+grow_table]
    .next:
        push .finish
        push rcx
        jmp push_in
    .finish:
    xor r8b,0b00010000
    jmp loop_exe
add_grow:
    pop rax ; pop arg
    add rax,[memory+rcx*8]
    push rdx ; push temp
    xor rdx,rdx
    mov r11,10
    div r11
    pop rdx ; clear temp
    mov rcx,rax
    ; return
    jmp setf ; so now the stack has the return addr on it
sub_grow:
    pop rax
    sub rax,[memory+rcx*8]
    push rdx
    xor rdx,rdx
    mov r11,10
    div r11
    pop rdx
    mov rcx,rax
    ; return
    jmp setf
mul_grow:
    pop rax
    imul rax,[memory+rcx*8]
    push rdx
    xor rdx,rdx
    mov r11,10
    div r11
    pop rdx
    mov rcx,rax
    ; return
    jmp setf
div_grow:
    pop rax
    push rdx
    xor rdx,rdx
    mov r11,10
    div r11
    pop rdx
    mov rcx,rax
    ; return
    jmp setf
xchg_grow:
    pop rax ; pop arg
    push [jump_table+rax*8]
    push [jump_table+rcx*8]
    pop [jump_table+rax*8]
    pop [jump_table+rcx*8]
    ; return
    pop rax
    jmp rax
default_grow:
    pop rax
    ; return
    pop rax
    jmp rax
ins_inp:
    test r9b,0b00010000 ; test if
    jz next ; if not set, bye bye
    push .start
    push rcx
    jmp get_abs
    .start:
    pop rcx ; get abs
    jmp getch
    here:
    movzx rax, byte [char] ; get char
    mov [memory+rcx*8],rax ; mov char
    jmp next ; return
ins_jmpm:
    test r8b,0b00001000 ; test if counter enough
    jz .next ; counter not enough
    push .start
    push rcx
    jmp get_abs
    .start:
    pop rcx ; get abs
    push .return_here
    push 4
    jmp get_val
    .return_here:
    pop rax ; at(4)
    push .finish
    jmp [rax*8+jmpm_table] ; goto get conditions
    .next:
        push .finish
        push rcx
        jmp push_in
    .finish:
    xor r8b,0b00001000 ; reverse the counter
    jmp next
jmp_z:
    mov rax,[memory+rcx*8]
    test r9b,0b1000000
    jz .return
    add rdx,rax
    ;return
    .return:
    pop rax
    jmp rax
jmp_nz:
    test r9b,0b1000000
    jnz .return
    add rdx,[memory+rcx*8]
    ;return
    .return:
    pop rax
    jmp rax
jmp_s:
    test r9b,0b0100000
    jz .return
    add rdx,[memory+rcx*8]
    ;return
    .return:
    pop rax
    jmp rax
jmp_ns:
    test r9b,0b0100000
    jnz .return
    add rdx,[memory+rcx*8]
    ;return
    .return:
    pop rax
    jmp rax
jmp_sz:
    test r9b,0b0100000
    jz .return
    test r9b,0b1100000
    jz .return
    add rdx,[memory+rcx*8]
    ;return
    .return:
    pop rax
    jmp rax
jmp_nsz:
    test r9b,0b0100000
    jnz .return
    test r9b,0b1100000
    jnz .return
    add rdx,[memory+rcx*8]
    ;return
    .return:
    pop rax
    jmp rax
jmp_:
    add rdx,[memory+rcx*8]
    ;return
    pop rax
    jmp rax
jmp_c:
    test r9b,0b0010000
    jz .return
    add rdx,[memory+rcx*8]
    ;return
    .return:
    pop rax
    jmp rax
jmp_default:
    ;return
    pop rax
    jmp rax
ins_revf:
    push .start
    push rcx
    jmp get_abs
    .start:
    pop rcx ; get abs
    jmp [revf_table+rcx*8] ; call revf
revzf:
    xor r9b,0b10000000
    ;return
    jmp next
revsf:
    xor r9b,0b01000000
    ;return
    jmp next
revcf:
    xor r9b,0b00100000
    ;return
    jmp next
revif:
    xor r9b,0b00010000
    ;return
    jmp next
revof:
    xor r9b,0b00001000
    ;return
    jmp next
revf_default:
    jmp next

; --- data --- ;

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
align 16
memory: times 10 dq 0
align 8
stack: times 8 dq 0
align 8
grow_table:
    dq add_grow
    dq sub_grow
    dq mul_grow
    dq div_grow
    dq xchg_grow
    times 5 dq default_grow
align 8
jmpm_table:
    dq jmp_z
    dq jmp_nz
    dq jmp_s
    dq jmp_ns
    dq jmp_sz
    dq jmp_nsz
    dq jmp_
    dq jmp_c
    times 2 dq jmp_default
align 8
revf_table:
    dq revzf
    dq revsf
    dq revcf
    dq revif
    dq revof
    times 5 dq revf_default

; --- methods ---

push_in:
    inc rbx
    and rbx,7
    pop rax ; get arg
    push .here
    push rax
    jmp get_abs
    .here:
    pop rax ; get abs
    mov [stack+rbx*8],rax ; write abs
    pop rax ; get addr
    jmp rax
get_val:
    pop rax ; get arg
    add rax,rbx
    and rax,7
    .not_too_big:
    mov r12, [stack+rax*8]
    pop rax ; get addr
    push r12
    jmp rax
setf:
    jz .zero
    js .sign_not_zero
    and r9b,0b00111111 ; not sign not zero
    jmp .exit
    .sign_not_zero:
    and r9b, 0b01111111 ; unset ZF
    or r9b,0b01000000 ; set SF
    jmp .exit
    .zero:
    js .sign_zero
    or r9b,0b01000000 ; set SF
    and r9b,0b01111111 ; unset ZF
    jmp .exit
    .sign_zero:
    or r9b, 0b11000000
    .exit:
    pop rax
    jmp rax
get_abs:
    pop rax ; get arg
    pop r12 ; get return addr
    test rax,rax
    jns .return
    neg rax
    .return:
    push rax
    jmp r12

; the below method is generated by LLM(deepseek), since I'm not familiar with the mode...

TCGETS equ 0x5401
TCSETS equ 0x5402
ICANON equ 2
ECHO equ 8
old_termios resb 60
new_termios resb 60
char resb 1

getch:
    push rdx
    push rcx

    mov rax, 0
    mov rdi, 0
    mov rsi, char
    mov rdx, 1
    syscall

    pop rcx
    pop rdx
    jmp here

; --- end ---
; do never write after it

filesize equ $ - ehdr
