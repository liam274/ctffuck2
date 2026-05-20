; Since I'm writing asm first time, so I got help from deepseek and gemini...
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
    dq memsize
    dq 0x1000
phdrsize equ $ - phdr

exit_no_arg:
    push 1
    jmp no_recovery
exit_fail_open:
    push 2
    jmp no_recovery
exit_fail_store:
    push 3
    jmp no_recovery
exit_fail_lseek:
    push 4
    jmp no_recovery
exit:
    push 0
    ; recover to normal mode
    push 16
    pop rax
    xor edi,edi
    mov esi, 0x5402
    mov edx, old_termios
    syscall
no_recovery:
    ; exit
    pop rdi
    push 60 ; sys_exit
    pop rax
    syscall

main:
    pop rcx ; argc
    dec rcx
    jz exit_no_arg
    pop rdi ; argv[0]
    pop rdi ; argv[1]
    xor esi,esi
    push 2
    pop rax
    cdq
    syscall
    test rax,rax ; test if success
    js exit_fail_open
    xchg eax, edi ; fd

    ; get file length
    push 8
    pop rax
    xor esi,esi
    push 2
    pop rdx ; emptied rdx high bit 32
    syscall
    test rax,rax
    je exit_fail_lseek
    push rax
    ; store size in r13

    ; store it somewhere(mmap)
    push rdi
    pop r8
    xor edi,edi
    pop rsi
    mov r13,rsi
    mov dl,1
    push 2
    pop r10
    xor r9d,r9d
    push 9
    pop rax
    syscall
    test rax,rax
    js exit_fail_store
    push r8
    pop rdi ; recover registries
    xchg rax,r14 ; base addr
    ; close the file since we no longer need it
    push 3
    pop rax
    syscall ; file closed

    ; --- set raw mode --- ;
    ; since all the reg edited is not important, so it's fine to not to push them
    mov r12d,old_termios
    push 16
    pop rax
    xor edi, edi
    mov esi, 0x5401
    mov edx, r12d
    syscall

    mov esi, r12d
    mov r12d,new_termios
    mov edi, r12d
    push 60
    pop rcx
    rep movsb

    and dword [r12 + 12], ~(2 | 8)
    mov word [r12 + 21], 0x0100
    
    push 16
    pop rax
    xor edi, edi
    mov esi, 0x5402
    mov edx,r12d
    syscall

    ; init
    add r14,r13
    neg r13
    push -1
    pop r15 ; last
    xor ecx,ecx ; arg
    xor ebx,ebx ; ebx head_pointer
    xor r8b,r8b ; counter
    ; 0 = read_counter
    ; 1 = add_counter
    ; 2 = swap counter
    ; 3 = grow counter
    ; 4 = jmpm counter
    mov r9b, 0b00011000 ; flag
    ; 1 = sf
    ; 0 = zf
    ; 2 = cf
    ; 3 = if
    ; 4 = of
    mov ebp,memory
    mov r12d,stack
    jmp loop
    align 16
next:
    inc r13
    jz exit
loop:
    movzx ecx, byte [r14+r13] ; get char
    ; digit filter
    sub rcx,'0'
    cmp rcx,9
    ja next
loop_exe:
    ; calc arg
    test r15,r15 ; set flag
    js .there ; reduce jmps, generally
    sub r15d,ecx
    mov eax,ecx ; xchg ecx,r15d ; mov is faster
    mov ecx,r15d
    mov r15d,eax
    jmp [r15*8+jump_table]
    .there:
    mov r15d,ecx
    jmp [r15*8+jump_table]
    ;loop end
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
push_in:
    inc ebx
    and ebx,7 ; assume that rcx is the arg, already
    mov [r12+rbx*8],ecx ; write abs
    ret
setf:
    lahf
    mov al, ah
    and r9b,0b00111111
    and al, 0b11000000
    or r9b, al
    ret
ins_read:
    call get_abs_rcx ; get abs of rcx
    test r8b, 0b10000000 ; if counter ok
    jz .next ; only one parm
    mov eax,[r12+rbx*8] ; at(0)
    mov r11, [rbp+rcx*8]
    mov [rbp+rax*8], r11
    test r11,r11
    call setf
    jmp .finish
    .next:
        call push_in
    .finish:
    xor r8b, 0b10000000
    jmp next
ins_add:
    test r8b,0b01000000
    jz .next
    lea eax, rbx[1]
    and eax, 7
    mov eax, [r12+rax*8] ; at(1)
    add [rbp+rax*8],rcx
    call setf
    jmp .finish
    .next:
        call get_abs_rcx
        call push_in
    .finish:
    xor r8b,0b01000000
    jmp next
ins_set:
    call get_abs_rcx
    mov [rbp+rcx*8],0
    or r9b,0b01000000
    and r9b,0b01111111
    jmp next
ins_push:
    call get_abs_rcx
    call push_in
    jmp next
get_abs_rcx:
    mov eax,ecx
    neg eax
    cmovns ecx,eax
    ret
ins_print:
    test r9b,0b00001000 ; check OF
    jz next
    call get_abs_rcx
    cmp qword [rbp+rcx*8], 0 ; check if is zero
    jz next ; skip so as not to print null
    mov eax, 1 ; write()
    mov edi,eax
    mov edx,eax
    lea esi, [rbp+rcx*8] ; pointer to addr
    syscall
    jmp next
ins_swap:
    test r8b,0b00100000 ; check if counter enough
    jz .next
    call get_abs_rcx
    lea eax, rbx[2]
    and eax,7
    mov eax,[r12+rax*8] ; at(2)
    mov r10, [rbp+rax*8]
    mov r11, [rbp+rcx*8]
    mov [rbp+rax*8], r11
    mov [rbp+rcx*8], r10
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
    lea eax, rbx[3]
    and eax, 7
    mov eax, [r12+rax*8] ; at(3)
    call [rax*8+grow_table]
    jmp .finish
    .next:
        call push_in
    .finish:
    xor r8b,0b00010000
    jmp loop_exe
grow_table:
    dq add_grow
    dq sub_grow
    dq mul_grow
    dq mod_grow
    dq div_grow
    dq xchg_grow
    times 5 dq default_grow
ins_inp:
    test r9b,0b00010000 ; test IF
    jz next ; if not set, bye bye
    call get_abs_rcx
    push rcx ; getch start
    xor eax, eax
    xor edi, edi
    mov esi, char
    mov edx, 1
    syscall
    pop rcx ; getch end
    movzx eax, byte [char] ; get char
    mov [rbp+rcx*8],rax ; mov char
    jmp next ; return

ins_revf:
    call get_abs_rcx
    mov al, 0x80
    shr al, cl
    xor r9b, al
    jmp next
add_grow:
    add rax,[rbp+rcx*8]
    jmp do_mod
sub_grow:
    sub rax,[rbp+rcx*8]
    jmp do_mod
mul_grow:
    imul rax,[rbp+rcx*8]
    jmp do_mod
mod_grow:
    mov r11,[rbp+rcx*8]
    mov cl,1
    test r11,r11
    cmovz eax,ecx
    xor edx,edx
    div rcx
    mov ecx,edx
    ; return
    call setf
    ret
do_mod:
    xor edx,edx
    mov ecx,10
    div rcx
    mov ecx,edx ; ecx = rax % 10
    ; return
    test ecx,ecx
    call setf ; so now the stack has the return addr on top
    ret
div_grow:
    mov rax,[rbp+rcx*8]
    jmp do_mod
xchg_grow:
    push [jump_table+rax*8]
    push [jump_table+rcx*8]
    pop [jump_table+rax*8]
    pop [jump_table+rcx*8]
    ; return
    ret
default_grow:
    ; return
    ret

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
jmp_z:
    test r9b,0b01000000
    jz jmp_default
    ;return
    jmp jmp_
jmp_nz:
    test r9b,0b01000000
    jnz jmp_default
    ;return
    jmp jmp_
jmp_s:
    test r9b,0b10000000
    jz jmp_default
    ;return
    jmp jmp_
jmp_ns:
    test r9b,0b10000000
    jnz jmp_default
    ;return
    jmp jmp_
ins_jmpm:
    test r8b,0b00001000 ; test if counter enough
    jz .next ; counter not enough
    call get_abs_rcx
    lea eax, rbx[4]
    and eax, 7
    mov eax, [r12+rax*8] ; at(4)
    jmp [rax*8+jmpm_table] ; goto get conditions
    .next:
        call push_in
jmp_default:
    inc r13
jmp_finish:
    xor r8b,0b00001000 ; reverse the counter
    test r13,r13
    js loop
    jmp exit
jmp_sz: ; ZF || SF
    test r9b,0b11000000
    jz jmp_default
    ;return
    jmp jmp_
jmp_nsz: ; !ZF && !SF
    test r9b,0b11000000
    jnz jmp_default
    ;return
    jmp jmp_
jmp_:
    add r13,[rbp+rcx*8]
    ;return
    jmp jmp_finish
jmp_c:
    test r9b,0b00100000
    jz jmp_default
    ;return
    jmp jmp_
; --- end --- ;

filesize equ $ - ehdr

ABSOLUTE $ ; Tell NASM: me want virtual address

old_termios resb 60
new_termios resb 60
char resb 1
memory resq 10
stack resq 8

memsize equ $-ehdr