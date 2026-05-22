; Since I'm writing asm first time, so I got help from deepseek and gemini...
BITS 64
org 0x400000
default rel
; --- defines start --- ;

%define BOX_SIZE dword

; --- defines end --- ;
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
    ; recover to normal mode
    push 16
    pop rax
    xor edi,edi
    mov esi, 0x5402
    mov edx, old_termios
    syscall
    push 0
no_recovery:
    ; exit
    pop rdi
    push 60 ; sys_exit
    pop rax
    syscall

main:
    pop rcx ; argc
    dec ecx
    jz exit_no_arg
    pop rdi ; argv[0]
    pop rdi ; argv[1]
    ; read file
    xor esi,esi
    push 2
    pop rax
    cdq ; empty edx
    syscall
    test rax,rax ; test if success
    js exit_fail_open
    xchg eax, edi ; edi=fd

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
    mov al, 16
    xor edi, edi
    mov esi, 0x5401
    mov edx, old_termios
    syscall

    mov esi, edx
    mov edi, new_termios
    push 60
    pop rcx
    rep movsb

    and dword [rdi + 12-60], ~(2 | 8)
    mov word [rdi + 21-60], 0x0100
    
    push 16
    pop rax
    lea edx, [edi-60]
    mov esi, 0x5402
    xor edi, edi
    syscall

    ; init
    add r14,r13
    neg r13
    xor r15d,r15d ; last
    xor ecx,ecx ; arg
    xor ebx,ebx ; head_pointer
    xor r8d,r8d ; counter
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
next:
    inc r13
    jz exit
loop: ; simply fall through, so as to improve performance
    movzx ecx, byte [r14+r13] ; get char
    ; digit filter
    lea eax, [rcx-'0'] ; Instead of keep relying on ALU, here we used AGU instead
    ; So It can be synced
    cmp al,9
    ja next
loop_exe:
    ; calc arg
    sub ecx,r15d
    add r15d, ecx
    mov eax,ecx
    neg ecx
    cmovs ecx,eax
    jmp [r15*8+jump_table]
    ;loop end

push_in:
    inc ebx
    and ebx,7 ; assume that rcx is the arg, already
    mov [r12+rbx*4],ecx ; write abs
    jmp next
setf:
    lahf
    mov al, ah
    and r9b,0b00111111
    and al, 0b11000000
    or r9b, al
    ret
ins_read:
    btc r8d, 8 ; if counter ok
    jnc push_in ; only one parm
    mov eax, [r12+rbx*4] ; at(0)
    mov r11d, [rbp+rcx*4]
    mov [rbp+rax*4], r11d
    test r11d,r11d
    call setf
    jmp next
ins_add:
    btc r8d,7
    jnc push_in
    lea ecx, [rbx+1]
    and ecx, 7
    mov ecx, [r12+rcx*4] ; at(1)
    add [rbp+rcx*4], eax
    call setf
    jmp next
ins_set:
    xor eax,eax
    mov [rbp+rcx*4],eax
    or r9b,0b01000000 ; these two command cannot be run at the same time QmQ
    and r9b,0b01111111
    jmp next
ins_push:
    jmp push_in
ins_print:
    test r9b,0b00001000 ; check OF
    jz next
    cmp BOX_SIZE [rbp+rcx*4], 0 ; check if is zero
    jz next ; skip so as not to print null
    mov eax, 1 ; write()
    mov edi,eax
    mov edx,eax
    lea esi, [rbp+rcx*4] ; pointer to addr
    syscall
    jmp next
ins_swap:
    btc r8d,6 ; check if counter enough
    jnc push_in
    lea eax, [rbx+2]
    and eax,7
    mov eax,[r12+rax*4] ; at(2)
    mov r10d, [rbp+rax*4]
    mov r11d, [rbp+rcx*4]
    mov [rbp+rax*4], r11d
    mov [rbp+rcx*4], r10d
    jmp next
ins_grow:
    btc r8d,5 ; check if counter enough
    jnc push_in
    lea eax, [rbx+3]
    and eax, 7
    mov eax, [r12+rax*4] ; at(3)
    call [rax*8+grow_table]
    jmp loop_exe
ins_inp:
    test r9b,0b00010000 ; test IF
    jz next ; if not set, bye bye
    push rcx ; getch start
    xor eax, eax
    xor edi, edi
    mov esi, char
    mov edx, 1
    syscall
    pop rcx ; getch end
    movzx eax, byte [char] ; get char
    mov [rbp+rcx*4], eax ; mov char
    jmp next ; return

ins_revf:
    mov al, 0x80
    shr al, cl
    xor r9b, al
    jmp next
add_grow:
    add eax,[rbp+rcx*4]
    jmp do_mod
sub_grow:
    sub eax,[rbp+rcx*4]
    jmp do_mod
mul_grow:
    imul eax,[rbp+rcx*4]
    jmp do_mod
mod_grow:
    mov r11d,[rbp+rcx*4]
    test r11d,r11d
    jnz .ok
    inc r11d
    .ok:
    xor edx,edx
    div r11d
    mov ecx,edx
    ; return
    jmp setf
do_mod:
    xor edx,edx
    mov cl,10
    div ecx
    mov ecx,edx ; ecx = rax % 10
    ; return
    test ecx,ecx
    jmp setf ; so now the stack has the return addr on top
div_grow:
    mov eax,[rbp+rcx*4]
    jmp do_mod
xchg_grow:
    mov r10, [jump_table+rax*8+384]
    mov r11, [jump_table+rcx*8+384]
    mov [jump_table+rax*8+384], r11
    mov [jump_table+rcx*8+384], r10
    ; return
    ret
default_grow:
    ; return
    ret

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
    btc r8d,4 ; test if counter enough
    jnc .next ; counter not enough
    lea eax, [rbx+4]
    and eax, 7
    mov eax, [r12+rax*4] ; at(4)
    jmp [rax*8+jmpm_table] ; goto get conditions
    .next:
    inc ebx
    and ebx,7 ; assume that rcx is the arg, already
    mov [r12+rbx*4],ecx ; write abs
jmp_default:
    inc r13
jmp_finish:
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
    add r13,[rbp+rcx*4]
    ;return
    jmp jmp_finish
jmp_c:
    test r9b,0b00100000
    jz jmp_default
    ;return
    jmp jmp_
align 8
jump_table equ $ - 384
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
grow_table:
    dq add_grow
    dq sub_grow
    dq mul_grow
    dq mod_grow
    dq div_grow
    dq xchg_grow
    times 4 dq default_grow
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
; --- end --- ;

filesize equ $ - ehdr

ABSOLUTE $ ; Tell NASM: me want virtual address

old_termios resb 60
new_termios resb 60
char resb 1
memory resd 10
stack resd 8

memsize equ $-ehdr