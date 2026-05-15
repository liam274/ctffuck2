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
    xor rdx,rdx ; ctx->pointer
    mov r15,-1 ; last
    xor rcx,rcx ; arg
    xor rbx,rbx ; head_pointer
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
    test byte [counters], 0b10000000
    jz .next
    ; mov memory
    push [.return_here]
    push 0
    jmp get_val
    .return_here:
    pop rax
    push [memory+rcx]
    pop [memory+rax]
    push [.finish]
    jmp setf
    .next:
        push [.finish]
        push rcx
        jmp push_in
    .finish:
    xor byte [counters], 0b10000000
    jmp next
ins_add:
    test byte [counters],0b01000000
    jz .next
    push [.return_here]
    push 1
    jmp get_val
    .return_here:
    pop rax
    add [memory+rax],rcx
    push [.finish]
    jmp setf
    .next:
        push [.finish]
        push rcx
        jmp push_in
    .finish:
    xor byte [counters],0b01000000
    jmp next
ins_set:
    mov [memory+rcx],0
    or [flag],0b10000000
    and [flag],0b10111111
    jmp next
ins_push:
    push [next]
    push rcx
    jmp get_val
ins_print:
    test [flag],0b00001000
    jz next
    mov rax, 1
    push rdi
    mov rdi,1
    push rdx
    mov rdx, [memory+rcx]
    syscall
    pop rdx
    pop rdi
    jmp next
ins_swap:
    test byte [counters],0b00100000
    jz .next
    push [.return_here]
    push 2
    jmp get_val
    .return_here:
    pop rax
    push [memory+rax]
    push [memory+rcx]
    pop [memory+rax]
    pop [memory+rcx]
    jmp .finish
    .next:
        push [.finish]
        push rcx
        jmp push_in
    .finish:
    xor byte [counters],0b00100000
    jmp next
ins_grow:
    test byte [counters],0b00010000
    jz .next
    push [.return_here]
    push 3
    jmp get_val
    .return_here:
    pop rax
    push [.finish]
    push rax
    jmp [rcx*8+grow_table]
    .next:
        push [.finish]
        push rcx
        jmp push_in
    .finish:
    xor byte [counters],0b00010000
    jmp next
add_grow:
    pop rax
    ; return
    pop rax
    jmp rax
sub_grow:
    pop rax
    ; return
    pop rax
    jmp rax
mul_grow:
    pop rax
    ; return
    pop rax
    jmp rax
div_grow:
    pop rax
    ; return
    pop rax
    jmp rax
xchg_grow:
    pop rax
    ; return
    pop rax
    jmp rax
default_grow:
    pop rax
    pop rax
    jmp rax
ins_inp:
    test [flag],0b00010000
    jz next
    mov [memory+rcx],al
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

counters: db 0
; 0 = read_counter
; 1 = add_counter
; 2 = swap counter
; 3 = grow counter
; 4 = jmpm counter
; 5 = revf coutner
align 8
stack: times 5 dq 0
flag: db 0
; 0 = zf
; 1 = sf
; 2 = cf
; 3 = if
; 4 = of
align 8
termios_buf: times 36 db 0
key_buf: db 0
align 8
grow_table:
    dq add_grow
    dq sub_grow
    dq mul_grow
    dq div_grow
    dq xchg_grow
    times 5 dq default_grow

push_in:
    inc rbx
    cmp rbx,5
    jnz .not_too_big
    xor rbx,rbx
    .not_too_big:
    pop rax
    mov [stack+rbx],rax
    pop rax
    jmp rax
get_val:
    pop rax
    add rax,rbx
    cmp rax,5
    jnz .not_too_big
    sub rax,5
    .not_too_big:
    mov r12, [stack+rax]
    pop rax
    push r12
    jmp rax
setf:
    jz .is_zero
    or [flag], 0b10000000
    jmp .next
    .is_zero:
    and [flag], 0b01111111
    .next:
    js .is_sign
    or [flag],0b01000000
    pop rax
    jmp rax
    .is_sign:
    and [flag],0b10111111
    pop rax
    jmp rax

; the below method is generated by LLM(deepseek), since I'm not familiar with the mode...

getch:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11

    ; 保存原始终端设置
    mov rax, 16
    mov rdi, 0
    mov rsi, 0x5401            ; TCGETS
    lea rdx, [termios_buf]
    syscall
    test rax, rax
    js .error_restore_only

    ; 复制一份并修改（在栈上临时拷贝）
    sub rsp, 36
    mov rsi, rdx               ; termios_buf
    mov rdi, rsp
    mov rcx, 36
    rep movsb
    and dword [rsp+12], ~0x0A  ; 关闭 ICANON 和 ECHO
    ; 应用新设置
    mov rax, 16
    mov rdi, 0
    mov rsi, 0x5402            ; TCSETS
    mov rdx, rsp
    syscall
    add rsp, 36

    ; 读取一个字符
    mov rax, 0
    mov rdi, 0
    lea rsi, [key_buf]
    mov rdx, 1
    syscall
    test rax, rax
    jle .error_restore_only

    ; 恢复原始终端
    mov rax, 16
    mov rdi, 0
    mov rsi, 0x5402
    lea rdx, [termios_buf]
    syscall

    mov al, [key_buf]          ; 字符放入 AL
    jmp .restore_regs

.error_restore_only:
    ; 出错了也尽量恢复终端
    mov rax, 16
    mov rdi, 0
    mov rsi, 0x5402
    lea rdx, [termios_buf]
    syscall
    xor al, al                 ; 返回 0

.restore_regs:
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; --- end ---
; do never write after it

filesize equ $ - ehdr
