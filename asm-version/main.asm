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
    mov eax,2
    syscall
    test rax,rax ; test if success
    js exit_fail_open
    mov rdi,rax ; fd

    ; get file length
    mov eax,8
    xor esi,esi
    mov edx,2
    syscall
    test rax,rax
    je exit_fail_lseek
    mov r13,rax
    ; store size in r13

    ; store it somewhere(mmap)
    mov r8,rdi
    xor edi,edi
    mov rsi,r13
    mov edx,1
    mov r10d,2
    xor r9d,r9d
    mov eax,9
    syscall
    test rax,rax
    js exit_fail_store

    mov rdi, r8 ; recover registries
    mov r14, rax ; base addr
    ; close the file since we no longer need it
    mov eax, 3
    syscall ; file closed

    ; --- set raw mode --- ;
    ; since all the reg edited is not important, so it's fine to not to push them
    mov eax, 16
    xor edi, edi
    mov rsi, TCGETS
    mov rdx, old_termios
    syscall

    mov rsi, old_termios
    mov rdi, new_termios
    mov ecx, 60
    rep movsb

    mov eax, dword [new_termios + 12]
    and eax, ~(ICANON | ECHO)
    mov dword [new_termios + 12], eax

    mov byte [new_termios + 16 + 6], 1
    mov byte [new_termios + 16 + 5], 0
    
    mov eax, 16
    xor edi, edi
    mov rsi, TCSETS
    mov rdx, new_termios
    syscall

    ; init
    xor edx,edx ; ctx->pointer
    mov r15,-1 ; last
    xor ecx,ecx ; arg
    xor ebx,ebx ; head_pointer
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
loop:
    movzx ecx, byte [r14+rdx] ; get char
    ; digit filter
    sub rcx,'0'
    jb next
    cmp rcx,9
    ja next
loop_exe:
    ; calc arg
    test r15,r15 ; set flag
    js .there ; reduce jmps, generally
    sub r15d,ecx
    xchg ecx,r15d
    jmp [r15d*8+jump_table]
    .there:
    mov r15,rcx
    jmp [r15*8+jump_table]
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
    push rdi
    ; recover to normal mode
    mov eax, 16
    xor edi,edi
    mov rsi, TCSETS
    mov rdx, old_termios
    syscall
    ; exit
    pop rdi
    mov eax, 60 ; sys_exit
    syscall

ins_read:
    call get_abs_rcx ; get abs of rcx
    test r8b, 0b10000000 ; if counter ok
    jz .next ; only one parm
    push 0
    call get_val ; at(0)
    push [memory+rcx*8]
    pop [memory+rax*8]
    push .finish
    jmp setf
    .next:
        call push_in
    .finish:
    xor r8b, 0b10000000
    jmp next
ins_add:
    test r8b,0b01000000
    jz .next
    push 1
    call get_val
    add [memory+rax*8],rcx
    push .finish
    jmp setf
    .next:
        call push_in
    .finish:
    xor r8b,0b01000000
    jmp next
ins_set:
    call get_abs_rcx
    mov [memory+rcx*8],0
    or r9b,0b10000000
    and r9b,0b10111111
    jmp next
ins_push:
    call push_in
    jmp next
ins_print:
    test r9b,0b00001000 ; check of
    jz next
    call get_abs_rcx
    cmp qword [memory+rcx*8], 0 ; check if is zero
    jz next ; skip so as not to print null
    mov eax, 1 ; write()
    push rdx ; save rdx
    mov edi,1
    lea rsi, [memory+rcx*8] ; pointer to addr
    mov edx, 1
    syscall
    pop rdx
    jmp next
ins_swap:
    test r8b,0b00100000 ; check if counter enough
    jz .next
    call get_abs_rcx
    push 2
    call get_val
    push [memory+rax*8]
    push [memory+rcx*8]
    pop [memory+rax*8]
    pop [memory+rcx*8]
    jmp .finish
    .next:
        call push_in
    .finish:
    xor r8b,0b00100000
    jmp next
ins_grow:
    test r8b,0b00010000 ; check if counter enough
    jz .next
    call get_abs_rcx
    push 3
    call get_val
    push .finish
    jmp [rax*8+grow_table]
    .next:
        call push_in
    .finish:
    xor r8b,0b00010000
    jmp loop_exe
add_grow:
    add rax,[memory+rcx*8]
    push rdx ; push temp
    xor edx,edx
    mov ecx,10
    div rcx
    mov ecx,edx
    pop rdx
    ; return
    jmp setf ; so now the stack has the return addr on it
sub_grow:
    sub rax,[memory+rcx*8]
    push rdx
    xor edx,edx
    mov ecx,10
    div rcx
    mov ecx,edx
    pop rdx
    ; return
    jmp setf
mul_grow:
    imul rax,[memory+rcx*8]
    push rdx
    xor edx,edx
    mov ecx,10
    div rcx
    mov ecx,edx
    pop rdx
    ; return
    jmp setf
div_grow:
    push rdx
    xor edx,edx
    mov ecx,10
    div rcx
    mov ecx,edx
    pop rdx
    ; return
    jmp setf
xchg_grow:
    push [jump_table+rax*8]
    push [jump_table+rcx*8]
    pop [jump_table+rax*8]
    pop [jump_table+rcx*8]
    ; return
    pop rax
    jmp rax
default_grow:
    ; return
    pop rax
    jmp rax
ins_inp:
    test r9b,0b00010000 ; test if
    jz next ; if not set, bye bye
    call get_abs_rcx
    jmp getch
    here:
    movzx rax, byte [char] ; get char
    mov [memory+rcx*8],rax ; mov char
    jmp next ; return
ins_jmpm:
    test r8b,0b00001000 ; test if counter enough
    jz .next ; counter not enough
    call get_abs_rcx
    push 4
    call get_val ; at(4)
    jmp [rax*8+jmpm_table] ; goto get conditions
    .next:
        call push_in
    jmp_finish:
    xor r8b,0b00001000 ; reverse the counter
    cmp rdx, r13
    jnz loop
    jmp exit
jmp_z:
    mov rax,[memory+rcx*8]
    test r9b,0b1000000
    jz jmp_finish
    add rdx,rax
    ;return
    jmp jmp_finish
jmp_nz:
    test r9b,0b1000000
    jnz jmp_finish
    add rdx,[memory+rcx*8]
    ;return
    jmp jmp_finish
jmp_s:
    test r9b,0b0100000
    jz jmp_finish
    add rdx,[memory+rcx*8]
    ;return
    jmp jmp_finish
jmp_ns:
    test r9b,0b0100000
    jnz jmp_finish
    add rdx,[memory+rcx*8]
    ;return
    jmp jmp_finish
jmp_sz:
    test r9b,0b0100000
    jnz .good
    test r9b,0b1100000
    jnz .good
    ;return
    jmp jmp_finish
    .good:
    add rdx,[memory+rcx*8]
jmp_nsz:
    test r9b,0b0100000
    jnz jmp_finish
    test r9b,0b1100000
    jnz jmp_finish
    add rdx,[memory+rcx*8]
    ;return
    jmp jmp_finish
jmp_:
    add rdx,[memory+rcx*8]
    ;return
    jmp jmp_finish
jmp_c:
    test r9b,0b0010000
    jz jmp_finish
    add rdx,[memory+rcx*8]
    ;return
    jmp jmp_finish
jmp_default:
    ;return
    inc rdx
    jmp jmp_finish
ins_revf:
    call get_abs_rcx
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

; --- methods ---

push_in:
    inc ebx
    and ebx,7
    test rcx,rcx ; assume that rcx is the arg, already
    jns .here
    neg rcx
    .here:
    mov [stack+rbx*8],ecx ; write abs
    ret
get_val:
    pop r12
    pop rax ; get arg
    push r12
    add eax,ebx
    and eax,7
    .not_too_big:
    mov rax, [stack+rax*8]
    ret
setf: ; don't optimize its return, since some other performance improvement depends on it
    jz .zero
    ;not zero
    js .sign_not_zero
    ;not zero && not sign
    and r9b,0b00111111 ; not sign not zero
    jmp .exit
    .sign_not_zero:
    and r9b, 0b01111111 ; unset ZF
    or r9b,0b01000000 ; set SF
    jmp .exit
    .zero:
    js .sign_zero
    or r9b,0b10000000 ; set ZF
    and r9b,0b10111111 ; unset SF
    jmp .exit
    .sign_zero:
    or r9b, 0b11000000
    .exit:
    pop rax
    jmp rax
get_abs_rcx:
    test rcx,rcx
    jns .return
    neg rcx
    .return:
    ret

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

    xor eax, eax
    xor edi, edi
    mov rsi, char
    mov edx, 1
    syscall
    pop rcx
    pop rdx
    jmp here

; --- end ---

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
memory: times 10 dq 0
stack: times 8 dq 0
grow_table:
    dq add_grow
    dq sub_grow
    dq mul_grow
    dq div_grow
    dq xchg_grow
    times 5 dq default_grow
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
revf_table:
    dq revzf
    dq revsf
    dq revcf
    dq revif
    dq revof
    times 5 dq revf_default

; do never write after it

filesize equ $ - ehdr
