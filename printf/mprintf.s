global _printfept
; global _start
; extern printf

SpecSym     equ '%'     ; Specificator symbol.
DNumSpec    equ 'd'     ; Decimal number specificator.
HNumSpec    equ 'x'     ; Hex number specificator.
ONumSpec    equ 'o'     ; Oct number specificator.
BNumSpec    equ 'b'     ; Bin number specificator.
SymSpec     equ 'c'     ; Character specificator.
StrSpec     equ 's'     ; String specificator.

HexBase equ 10h
DecBase equ 10d
OctBase equ 8d
BinBase equ 2d

StdOut  equ 1
Write64 equ 0x01        ; Write syscall number.
Exit64  equ 0x3C        ; Exit syscall number.

; rdi -> rsi -> rdx -> rcx -> r8 -> r9 - Calling convention.

section .text

; _start:
;
;     push 11011b
;     mov r9, PString
;     mov r8, 300d
;     mov rcx, 228Ah
;     mov rdx, 28d
;     mov rsi, 'A'
;     mov rdi, PrintfStr
;     call _printfept
;
;     mov rax, Exit64
;     xor rdi, rdi
;     syscall

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description: printf() analog.
; Entry:    First 6 arguments located in registers and if
;           there are more than 6, other arguments pushed
;           in stack.
; Returns:  rax = *number of outputed symbols*.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_printfept:
    pop r12         ; Save return address.

    push r9         ; Push registers in stack.
    push r8
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp        ; Save rbp value.

    mov rbp, rsp
    add rbp, 8
    mov rsi, [rbp]
    add rbp, 8

.strproc:
    cmp byte [rsi], 0
    je .exit

    cmp byte [rsi], SpecSym
    je .is_spec

    call PutChar
    inc rsi
    jmp .strproc

.is_spec:
    inc rsi
    call PrintSpec
    inc rsi
    jmp .strproc

.exit:
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop r8
    pop r9

    push r12    ; Push return addres.
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description: Print specificator.
; Entry:    [rsi] = *specificator symbol*.
;           [rbp] = printf argument in stack.
; Returns: nothing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintSpec:
    push rsi                        ; Saving [rsi] position in first printf argument.
    xor rdi, rdi
    movzx rdi, byte [rsi]
    sub rdi, SpecSym
    cmp rdi, 84                     ; Out of table bounds control.
    ja .exit
    jmp [.jmptable + rdi * 8]

.jmptable:
                                    dq .percent
    times (BNumSpec - SpecSym - 1)  dq .exit
                                    dq .bnumber
                                    dq .symbol
                                    dq .dnumber
    times (ONumSpec - DNumSpec - 1) dq .exit
                                    dq .onumber
    times (StrSpec - ONumSpec - 1)  dq .exit
                                    dq .string
    times (HNumSpec - StrSpec - 1)  dq .exit
                                    dq .hnumber

.exit:
    pop rsi
    ret

.dnumber:
    mov rbx, [rbp]
    add rbp, 8
    mov rsi, Buffer
    call PrintDInt
    jmp .exit

.hnumber:
    mov rbx, [rbp]
    add rbp, 8
    mov rsi, Buffer
    call PrintHInt
    jmp .exit

.onumber:
    mov rbx, [rbp]
    add rbp, 8
    mov rsi, Buffer
    call PrintOInt
    jmp .exit

.bnumber:
    mov rbx, [rbp]
    add rbp, 8
    mov rsi, Buffer
    call PrintBInt
    jmp .exit

.symbol:
    mov rbx, [rbp]
    add rbp, 8
    mov rsi, Buffer
    mov byte [rsi], bl
    call PutChar
    jmp .exit

.string:
    mov rsi, [rbp]
    add rbp, 8
    call PrintString
    jmp .exit

.percent:
    call PutChar
    jmp .exit

    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description: Print char to stdout.
; Entry:    [rsi] = *sym*.
; Returns:  nothing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PutChar:
    mov rax, Write64
    mov rdi, StdOut
    ; mov rsi, rsi
    mov rdx, 1
    syscall
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description: Print string to stdout.
; Assumes:  String ending is terminator symbol.
; Entry:    rsi = *string pointer*.
; Returns:  nothing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintString:
    mov rax, Write64
    mov rdi, StdOut
    ; mov rsi, rsi
    mov rdx, 1
    syscall

.PrintIteration:
    inc rsi
    syscall
    cmp byte [rsi], 0
    jne .PrintIteration

    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description: Print decimal value to stdout.
; Entry:    rbx = *val*.
; Returns:  nothing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintDInt:
    push rsi
    xor rcx,  rcx
    mov rax, rbx        ; rax = num
    mov rbx, DecBase

.DigitsParcing:
    xor rdx, rdx
    idiv ebx
    add rdx, 30h        ; rdx = *ASCII code of digit*.
    push rdx
    inc rcx
    cmp eax, 0
    jne .DigitsParcing

    mov ch, cl          ; Saving count of digits.
.DigitsOutput:
    pop rdx
    mov byte [rsi], dl
    inc rsi
    dec ch
    cmp ch, 0
    ja .DigitsOutput

    pop rsi

    mov rax, Write64
    mov rdi, StdOut
    ; mov rsi, rsi
    mov rdx, rcx
    syscall
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description: Print hex value to stdout.
; Entry:    rbx = *val*.
; Returns:  nothing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintHInt:
    push rsi
    xor rcx,  rcx
    mov rax, rbx        ; rax = num
    mov rbx, HexBase

.DigitsParcing:
    xor rdx, rdx
    idiv ebx
    add rdx, 30h        ; rdx = *ASCII code of digit*.
    cmp rdx, 39h
    jbe .SaveDigit
    add rdx, 27h
.SaveDigit:
    push rdx
    inc rcx
    cmp eax, 0
    jne .DigitsParcing

    mov ch, cl          ; Saving count of digits.
.DigitsOutput:
    pop rdx
    mov byte [rsi], dl
    inc rsi
    dec ch
    cmp ch, 0
    ja .DigitsOutput

    pop rsi

    mov rax, Write64
    mov rdi, StdOut
    ; mov rsi, rsi
    mov rdx, rcx
    syscall

;     xor rcx, rcx
;     mov rax, 0Fh       ; rax = mask.
;
; .DigitsParcing:
;     mov rdx, rbx
;     and rdx, rax
;     mov rdi, HexChar
;     add rdi, rdx
;     mov rdx, [rdi]
;     push rdx
;     shl rax, 4
;     inc rcx
;     cmp rcx, 16
;     jb .DigitsParcing
;
; .SkipZeros:
;     cmp rcx, 0
;     je .its_zero
;     pop rdx
;     dec rcx
;     cmp rdx, 0
;     je .SkipZeros
;     push rsi
;     push rdx
;     inc rcx
;     mov ch, cl
;     jmp .DigitsOutput
;
; .its_zero:
;     inc rcx
;     mov byte [rsi], 30h
;     jmp .print
;
; .DigitsOutput:
;     pop rdx
;     mov byte [rsi], dl
;     inc rsi
;     dec ch
;     cmp ch, 0
;     ja .DigitsOutput
;
;     pop rsi
;
; .print:
;     mov rax, Write64
;     mov rdi, StdOut
;     ; mov rsi, rsi
;     mov rdx, rcx
;     syscall
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description: Print oct value to stdout.
; Entry:    rbx = *val*.
; Returns:  nothing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintOInt:
    push rsi
    xor rcx,  rcx
    mov rax, rbx        ; rax = num
    mov rbx, OctBase

.DigitsParcing:
    xor rdx, rdx
    idiv ebx
    add rdx, 30h        ; rdx = *ASCII code of digit*.
    push rdx
    inc rcx
    cmp eax, 0
    jne .DigitsParcing

    mov ch, cl          ; Saving count of digits.
.DigitsOutput:
    pop rdx
    mov byte [rsi], dl
    inc rsi
    dec ch
    cmp ch, 0
    ja .DigitsOutput

    pop rsi

    mov rax, Write64
    mov rdi, StdOut
    ; mov rsi, rsi
    mov rdx, rcx
    syscall
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description: Print binary value to stdout.
; Entry:    rbx = *val*.
; Returns:  nothing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintBInt:
    push rsi
    xor rcx,  rcx
    mov rax, rbx        ; rax = num
    mov rbx, BinBase

.DigitsParcing:
    xor rdx, rdx
    idiv ebx
    add rdx, 30h        ; rdx = *ASCII code of digit*.
    push rdx
    inc rcx
    cmp eax, 0
    jne .DigitsParcing

    mov ch, cl          ; Saving count of digits.
.DigitsOutput:
    pop rdx
    mov byte [rsi], dl
    inc rsi
    dec ch
    cmp ch, 0
    ja .DigitsOutput

    pop rsi

    mov rax, Write64
    mov rdi, StdOut
    ; mov rsi, rsi
    mov rdx, rcx
    syscall
    ret

section .data

Buffer times 32 db  0
PrintfStr   db "Lol, hehehe! %c %d %x %o %s %b", 0ah, 0
DebugCheck  db " Here ", 0
HexChar     db "0123456789ABCDEF"
PString     db "Abobusi, sosat + lejat", 0

