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
    mov byte [flag], 0b00011000
loop:
    test byte [flag],0b00000100 ; check if has transposus
    jz .main_loop
    and byte [flag],0b11111011
    jmp loop_exe
    .main_loop:
    movzx rcx, byte [r14+rdx]
    ; digit filter
    sub rcx,'0'
    jb next
    cmp rcx,9
    ja next
loop_exe:
    ; calc arg
    add r15,0
    jns .here
    mov r15,rcx
    add r15,rcx
    .here:
    mov rax,r15
    sub rax,rcx
    mov r15,rcx
    mov rcx,rax
    jmp [r15*8+jump_table]
    ;loop end
next:
    inc rdx
    cmp rdx, r13
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
    mov eax, 60 ; sys_exit
    syscall

ins_read:
    push .start
    push rcx
    jmp get_abs
    .start:
    pop rcx
    test byte [counters], 0b10000000
    jz .next
    ; mov memory
    push .return_here
    push 0
    jmp get_val
    .return_here:
    pop rax
    push [memory+rcx]
    pop [memory+rax]
    push .finish
    push [memory+rax]
    jmp setf
    .next:
        push .finish
        push rcx
        jmp push_in
    .finish:
    xor byte [counters], 0b10000000
    jmp next
ins_add:
    test byte [counters],0b01000000
    jz .next
    push .return_here
    push 1
    jmp get_val
    .return_here:
    pop rax
    add [memory+rax],rcx
    push .finish
    push [memory+rax]
    jmp setf
    .next:
        push .finish
        push rcx
        jmp push_in
    .finish:
    xor byte [counters],0b01000000
    jmp next
ins_set:
    push .start
    push rcx
    jmp get_abs
    .start:
    pop rcx
    mov [memory+rcx],0
    or [flag],0b10000000
    and [flag],0b10111111
    jmp next
ins_push:
    push next
    push rcx
    jmp push_in
ins_print:
    test [flag],0b00001000
    jz next
    push .start
    push rcx
    jmp get_abs
    .start:
    pop rcx
    cmp qword [memory+rcx], 0
    jz next
    mov rax, 1
    push rdi
    mov rdi,1
    push rdx
    lea rsi, [memory+rcx]
    mov rdx, 1
    syscall
    pop rdx
    pop rdi
    jmp next
ins_swap:
    test byte [counters],0b00100000
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
    push [memory+rax]
    push [memory+rcx]
    pop [memory+rax]
    pop [memory+rcx]
    jmp .finish
    .next:
        push .finish
        push rcx
        jmp push_in
    .finish:
    xor byte [counters],0b00100000
    jmp next
ins_grow:
    test byte [counters],0b00010000
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
    or byte [flag], 0b00000100
    xor byte [counters],0b00010000
    dec rdx
    jmp next
add_grow:
    pop rax
    add rax,[memory+rcx]
    push rdx
    xor rdx,rdx
    mov r11,10
    div r11
    pop rdx
    mov rcx,rax
    ; return
    push rcx
    jmp setf
sub_grow:
    pop rax
    sub rax,[memory+rcx]
    push rdx
    xor rdx,rdx
    mov r11,10
    div r11
    pop rdx
    mov rcx,rax
    ; return
    push rcx
    jmp setf
mul_grow:
    pop rax
    imul rax,[memory+rcx]
    push rdx
    xor rdx,rdx
    mov r11,10
    div r11
    pop rdx
    mov rcx,rax
    ; return
    push rcx
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
    push rcx
    jmp setf
xchg_grow:
    pop rax
    push [jump_table+rax]
    push [jump_table+rcx]
    pop [jump_table+rax]
    pop [jump_table+rcx]
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
    push .start
    push rcx
    jmp get_abs
    .start:
    pop rcx
    jmp getch
    here:
    movzx rax, byte [char]
    mov [memory+rcx*8],rax
    jmp next
ins_jmpm:
    test byte [counters],0b00001000
    jz .next
    push .start
    push rcx
    jmp get_abs
    .start:
    pop rcx
    push .return_here
    push 4
    jmp get_val
    .return_here:
    pop rax
    push .finish
    push [memory+rcx]
    jmp [rax*8+jmpm_table]
    .next:
        push .finish
        push rcx
        jmp push_in
    .finish:
    xor byte [counters],0b00001000
    jmp next
jmp_z:
    pop rax
    test byte [flag],0b1000000
    jz .return
    add rdx,rax
    ;return
    .return:
    pop rax
    jmp rax
jmp_nz:
    pop rax
    test byte [flag],0b1000000
    jnz .return
    add rdx,rax
    ;return
    .return:
    pop rax
    jmp rax
jmp_s:
    pop rax
    test byte [flag],0b0100000
    jz .return
    add rdx,rax
    ;return
    .return:
    pop rax
    jmp rax
jmp_ns:
    pop rax
    test byte [flag],0b0100000
    jnz .return
    add rdx,rax
    ;return
    .return:
    pop rax
    jmp rax
jmp_sz:
    pop rax
    test byte [flag],0b0100000
    jz .return
    test byte [flag],0b1100000
    jz .return
    add rdx,rax
    ;return
    .return:
    pop rax
    jmp rax
jmp_nsz:
    pop rax
    test byte [flag],0b0100000
    jnz .return
    test byte [flag],0b1100000
    jnz .return
    add rdx,rax
    ;return
    .return:
    pop rax
    jmp rax
jmp_:
    pop rax
    add rdx,rax
    ;return
    pop rax
    jmp rax
jmp_c:
    pop rax
    test byte [flag],0b0010000
    jz .return
    add rdx,rax
    ;return
    .return:
    pop rax
    jmp rax
jmp_default:
    pop rax
    ;return
    pop rax
    jmp rax
ins_revf:
    push .start
    push rcx
    jmp get_abs
    .start:
    pop rcx
    push next
    jmp [revf_table+rcx*8]
revzf:
    xor byte [flag],0b10000000
    ;return
    pop rax
    jmp rax
revsf:
    xor byte [flag],0b01000000
    ;return
    pop rax
    jmp rax
revcf:
    xor byte [flag],0b00100000
    ;return
    pop rax
    jmp rax
revif:
    xor byte [flag],0b00010000
    ;return
    pop rax
    jmp rax
revof:
    xor byte [flag],0b00001000
    ;return
    pop rax
    jmp rax
revf_default:
    pop rax
    jmp rax

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
; 5 = trans_ok
align 8
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

; --- methods ---

push_in:
    inc rbx
    cmp rbx,5
    jnz .not_too_big
    xor rbx,rbx
    .not_too_big:
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
    cmp rax,5
    jb .not_too_big
    sub rax,5
    .not_too_big:
    mov r12, [stack+rax*8]
    pop rax ; get addr
    push r12
    jmp rax
setf:
    pop r12
    add r12,0
    pushf
    pop r12
    test r12, 0b1000000
    jnz .is_zero
    and [flag], 0b01111111
    jmp .next
    .is_zero:
    or [flag], 0b10000000
    .next:
    test r12,0b10000000
    jnz .is_sign
    and [flag],0b10111111
    pop rax
    jmp rax
    .is_sign:
    or [flag],0b01000000
    pop rax
    jmp rax
get_abs:
    pop rax ; get arg
    pop r12 ; get return addr
    add rax,0
    jns .return
    neg rax
    .return:
    push rax
    jmp r12

; the below method is generated by LLM(deepseek), since I'm not familiar with the mode...

TCGETS equ 0x5401          ; ioctl 请求：获取终端属性
TCSETS equ 0x5402          ; ioctl 请求：设置终端属性
ICANON equ 2               ; 规范模式z标志
ECHO equ 8               ; 回显标志
old_termios resb 60         ; 保存原始终端属性（termios 结构大小 60）
new_termios resb 60         ; 修改后的终端属性
char resb 1          ; 存放读取的字符

getch:
    push rdx
    push rcx
    push rdx
    push rsi
    mov rax, 16                 ; sys_ioctl
    mov rdi, 0                  ; stdin 文件描述符
    mov rsi, TCGETS
    mov rdx, old_termios
    syscall

    ; ---------- 2. 复制并修改属性（原始模式） ----------
    ; 复制 old_termios 到 new_termios
    mov rsi, old_termios
    mov rdi, new_termios
    mov rcx, 60
    rep movsb

    ; 清除 c_lflag 中的 ICANON 和 ECHO
    mov eax, dword [new_termios + 12]   ; c_lflag 偏移 12
    and eax, ~(ICANON | ECHO)
    mov dword [new_termios + 12], eax

    ; 设置 c_cc[VMIN] = 1, c_cc[VTIME] = 0
    ; VMIN 索引 6，VTIME 索引 5；c_cc 数组从偏移 16 开始
    mov byte [new_termios + 16 + 6], 1
    mov byte [new_termios + 16 + 5], 0

    ; ---------- 3. 应用新属性 ----------
    mov rax, 16
    mov rdi, 0
    mov rsi, TCSETS
    mov rdx, new_termios
    syscall

    ; ---------- 4. 读取一个字符（无需 Enter） ----------
    mov rax, 0                  ; sys_read
    mov rdi, 0                  ; stdin
    mov rsi, char
    mov rdx, 1
    syscall

    ; ---------- 5. 恢复原始终端属性 ----------
    mov rax, 16
    mov rdi, 0
    mov rsi, TCSETS
    mov rdx, old_termios
    syscall

    ; ---------- 6. 强制跳转到标签 here ----------
    pop rsi
    pop rdi
    pop rcx
    pop rdx
    jmp here

; --- end ---
; do never write after it

filesize equ $ - ehdr
