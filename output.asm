section .data
    fmt_num db "%ld", 10, 0

section .text
    global _start
    extern printf
    extern exit

_start:
    push rbp
    mov rbp, rsp
    ; let x
    mov rax, 10
    mov [rbp-8], rax
    ; let y
    mov rax, 20
    mov [rbp-16], rax
    ; let result
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    push rax
    mov rax, 3
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-24], rax
    ; let z
    mov rax, 0
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    sub rax, rbx
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    imul rax, rbx
    mov rbx, rax
    pop rax
    add rax, rbx
    mov [rbp-32], rax

    ; Exit
    mov rsp, rbp
    pop rbp
    xor rdi, rdi
    call exit
