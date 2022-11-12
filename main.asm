;####################################################
;#                                                  #
;#                  Piotr Kira                      #
;#                                                  #
;####################################################

; TODO
; add explanatory comments
; delete some ifs that are never reachable (?)
; user friendly errors
; interactive mode (rotate and scale using keys)
; depth, perspective, change pos of camera view, rotate camera view
; scale
; change code to comply with the asm x86 conventions, e.g. proper usage of registers

%include "rotations.asm"

ROW equ 200
COL equ 300
MAX_DISPLAY_SIZE equ ROW*COL

SYS_READ equ 0
SYS_WRITE equ 1
SYS_OPEN equ 2
SYS_CLOSE equ 3

O_RDONLY equ 0

section .data
    radian dd 0.01745329252         ; degree/radian
    ; struct represents time to stop program used by _sleep function
    timespec:
        tv_sec dq 0
        tv_nsec dq 14000000

section .bss
    ; array that represents display,
    ; if terminal size (coll*rows) is bigger than declared size program will crash
    display resb MAX_DISPLAY_SIZE
    x resb 8
    y resb 8
    deltax resb 8
    deltay resb 8
    dx1 resb 8
    dy1 resb 8
    px resb 8
    py resb 8
    xe resb 8
    ye resb 8

    theta resb 4
    sintheta resb 4
    costheta resb 4
    object resw 120
    xshift resw 1
    yshift resw 1

    sz resw 4
    display_size resw 1
    coll resw 1

    buff resb 1

section .text
    global _start

%macro exit 0
    jmp _exit
%endmacro

%macro addLineToDisplay 4
    mov r8, %1
    mov r9, %2
    mov r10, %3
    mov r11, %4
    call _addLineToDisplay
%endmacro

_start:
    call _updateTerminalSize
    call _load3dObject
    rotateZ3D 160

    mov rcx, 10000
.loop:
    push rcx

    rotateY3D 1
    rotateX3D 2
    rotateZ3D 1
    call _updateTerminalSize
    call _prepareDisplay
    call _drawObject
    call _printDisplay
    call _sleep

    pop rcx
    dec rcx
    jnz .loop

    exit

; Fill display aray with blank spaces
_prepareDisplay:
    mov r8, display
    mov bx, [display_size]
    mov rcx, rbx
.loop:
    mov rdx, 0
    mov rax, rcx
    div word[coll]
    cmp rdx, 0
    ; if it's enf of line insert newline character to array, if not insert space character
    jne .noEndOfLine
    mov byte[r8], 10
    jmp .skip
.noEndOfLine:
    mov byte[r8], ' '
.skip:
    inc r8
    loop .loop
    ret

; Insert line to dsiplay array
; r8 = x1, r9 = y1, r10 = x2, r11 = y2
_addLineToDisplay:
    ; if x1 is greater than x2 replace p1(x1, y1) with p2(x2, y2)
    cmp r8, r10
    jng .ifend9
    mov rax, r8
    mov r8, r10
    mov r10, rax

    mov rax, r9
    mov r9, r11
    mov r11, rax
.ifend9:

    mov rax, r8                 ; rax = x1
    mov rbx, r10                ; rbx = x2
    sub rbx, rax                ; rbx = deltax = x2 - x1
    mov [deltax], rbx           ; save deltax to memory

    test rbx, rbx               ; is deltax negative
_if_deltax_neg:
    jns .end                    ; if not jump to end, otherwise continue
    neg rbx                     ; rbx = absolute of deltax
.end:
    mov [dx1], rbx              ; save abs(deltax) to memory

    mov rax, r9                 ; rax = y1
    mov rbx, r11                ; rbx = y2
    sub rbx, rax                ; rbx = deltay = y2 - y1
    mov [deltay], rbx           ; save deltay to memory

    test rbx, rbx               ; is deltay negative
_if_deltay_neg:
    jns .end                    ; if not jump to end, otherwise continue
    neg rbx                     ; rbx = abs(deltax)
.end:
    mov [dy1], rbx              ; save abs(deltay) to memory

    mov rax, [dy1]              ; rax = dy1
    mov rdx, 2                  ; rdx = 2
    mul rdx                     ; rax = 2*dy1
    sub rax, [dx1]              ; rax = px = 2*dy1-dx1
    mov [px], rax               ; save px to memory

    mov rax, [dx1]              ; rax = dx1
    mov rdx, 2                  ; rdx = 2
    mul rdx                     ; rax = 2*dx1
    sub rax, [dy1]              ; rax = py = 2*dx1-dy1
    mov [py], rax               ; save py to memory

    mov rax, [dy1]              ; rax = dy1
    mov rbx, [dx1]              ; rax = dx1
    cmp rax, rbx                ; compare dy1 with dx1
_if1:                           ; if dy1 <= dx1 continue
    jg _else1                   ; if false jump to else1

    mov rax, [deltax]           ; rax = deltax
    cmp rax, 0                  ; compare deltax with 0
_if2:                           ; if deltax >= 0 continue
    jl _else2                   ; if false jump to else2

    mov [x], r8                 ; x = x1
    mov [y], r9                 ; y = y1
    mov [xe], r10               ; xe = x2
    jmp _ifend2
_else2:
    mov [x], r10                ; x = x2
    mov [y], r11                ; y = y2
    mov [xe], r9                ; xe = x1
_ifend2:
    mov rcx, [x]
    cmp rcx, 0
    jl .skip
    cmp cx, [coll]
    jge .skip
    mov rax, [y]
    cmp rax, 0
    jl .skip

    add rcx, display
    mul word[coll]
    add rcx, rax                ; select row y
    mov byte[rcx], '#'          ; draw # at (x, y)
    .skip:

    mov rax, [xe]
    mov rdx, [x]
    sub rax, rdx
_loop1:                         ; for(x, x < xe, x++)


    push rax
    inc rdx
    push rdx
    mov rbx, px
    cmp word[rbx], 0            ; compare px with 0
_if3:                           ; if px < 0 continue
    jge _else3                  ; if false jump to else3

    mov rax, [dy1]
    mov rcx, 2
    mul rcx
    add [rbx], rax              ; px = px+2*dy1

    jmp _ifend3
_else3:
    mov rax ,[deltax]
    mov rdx ,[deltay]
    mov rcx, y
    cmp rax, 0
    jge _or4
    cmp rdx, 0
    jge _or4
    jmp _true4
_or4:
    cmp rax, 0
    jle _else4
    cmp rdx, 0
    jle _else4
_true4:                         ; if (dx < 0 && dy < 0) || (dx > 0 && dy > 0))
    inc qword[rcx]              ; y++
    jmp _ifend4
_else4:
    dec qword[rcx]              ; y--
_ifend4:

    mov rax, [dy1]
    sub rax, [dx1]
    mov rcx, 2
    mul rcx
    add [rbx], rax              ; px = px+2*(dy1-dx1)
_ifend3:
    mov rcx, [rsp]
    cmp rcx, 0
    jl .skip
    cmp cx, [coll]
    jge .skip
    mov rax, [y]
    cmp rax, 0
    jl .skip

    add rcx, display
    mov r8w, word[coll]
    mov rbx, r8
    mul rbx
    add rcx, rax
    mov byte[rcx], '#'
    .skip:
    pop rdx
    pop rax

    dec rax
    jnz _loop1

    jmp _ifend1                 ; end if1
_else1:
    mov rax, [deltay]           ; rax = deltay
    cmp rax, 0                  ; compare deltay with 0
_if5:
    jl _else5

    mov [x], r8
    mov [y], r9
    mov [ye], r11
    jmp _ifend5
_else5:
    mov [x], r10
    mov [y], r11
    mov [ye], r9
_ifend5:

    mov rcx, [x]
    cmp rcx, 0
    jl .skip
    cmp cx, [coll]
    jge .skip
    mov rax, [y]
    cmp rax, 0
    jl .skip

    add rcx, display            ; rcx = display
    mov r8w, [coll]
    mov rbx, r8
    mul rbx
    add rcx, rax                ; select row y
    mov byte[rcx], '#'          ; draw # at (x, y)
    .skip:

    mov rax, [ye]
    mov rdx, [y]
    sub rax, rdx
_loop2:                         ; for(y, y < ye, y++)

    push rax
    inc rdx
    push rdx
    mov rbx, py
    cmp word[rbx], 0            ; compare py with 0
_if6:                           ; if py <= 0 continue
    jg _else6                   ; if false jump to else3

    mov rax, [dx1]
    mov rcx, 2
    mul rcx
    add [rbx], rax              ; py = py+2*dx1

    jmp _ifend6
_else6:
    mov rax ,[deltax]
    mov rdx ,[deltay]
    mov rcx, x
    cmp rax, 0
    jge _or7
    cmp rdx, 0
    jge _or7
    jmp _true7
_or7:
    cmp rax, 0
    jle _else7
    cmp rdx, 0
    jle _else7
_true7:                         ; if (dx < 0 && dy < 0) || (dx > 0 && dy > 0))
    inc qword[rcx]               ; x++
    jmp _ifend7
_else7:
    dec qword[rcx]               ; x--
_ifend7:

    mov rax, [dx1]
    sub rax, [dy1]
    mov rcx, 2
    mul rcx
    add [rbx], rax              ; px = px+2*(dx1-dy1)

_ifend6:

    mov rcx, [x]
    cmp rcx, 0
    jl .skip
    cmp cx, [coll]
    jge .skip
    mov rax, [rsp]
    cmp rax, 0
    jl .skip
    add rcx, display
    mov r8w, [coll]
    mov rbx, r8
    mul rbx
    add rcx, rax
    mov byte[rcx], '#'
    .skip:
    pop rdx
    pop rax

    dec rax
    jnz _loop2
_ifend1:
    ret

; load given filename (console 1st argument) to object variable
_load3dObject:
    mov rbx, [rsp + 24]
    mov rax, SYS_OPEN
    mov rdi, rbx
    mov rsi, O_RDONLY
    mov rdx, 0
    syscall

    push rax

    ; read first number, n of nodes
    .loop:
    pop rdi
    push rdi
    mov rax, SYS_READ
    mov rsi, buff
    mov rdx, 1
    syscall

    mov rbx, [buff]
    cmp rbx, 48
    jl .next
    cmp rbx, 57
    jg .next
    sub rbx, 48
    mov rax, r8
    mov rcx, 10
    mul rcx
    add rax, rbx
    mov r8, rax
    jmp .loop
    .next:

    mov r10, object
    mov [r10], r8w
    add r10, 2


    ; read second number, n of connections
    .loop2:
    pop rdi
    push rdi
    mov rax, SYS_READ
    mov rsi, buff
    mov rdx, 1
    syscall

    mov rbx, [buff]
    cmp rbx, 48
    jl .next2
    cmp rbx, 57
    jg .next2
    sub rbx, 48
    mov rax, r9
    mov rcx, 10
    mul rcx
    add rax, rbx
    mov r9, rax
    jmp .loop2
    .next2:

    mov [r10], r9w
    add r10, 2


    mov rax, r8
    mov rbx, 3
    mul rbx
    mov rcx, rax
    pop rbx
    push rcx
    push rbx
    ; this loop will be executed 3*(n of nodes)
    .loop3:
    mov r12, 0               ; true if is negative
    xor r8, r8
    .loop4:
    pop rdi
    push rdi
    mov rax, SYS_READ
    mov rsi, buff
    mov rdx, 1
    syscall

    mov rbx, [buff]
    cmp rbx, '-'
    je .isNegative
    cmp rbx, 48
    jl .next3
    cmp rbx, 57
    jg .next3
    sub rbx, 48
    mov rax, r8
    mov rdx, 10
    mul rdx
    add rax, rbx
    mov r8, rax
    jmp .skip
    .isNegative:
    mov r12, 1
    .skip:
    jmp .loop4
    .next3:
    cmp r12, 1
    jne .notNeg
    neg r8d
    .notNeg:
    cvtsi2ss xmm0, r8d
    movss dword[r10], xmm0
    add r10, 4
    pop rbx
    pop rcx
    dec rcx
    push rcx
    push rbx
    jnz .loop3
    pop rbx
    pop rcx
    push rbx

    mov rax, r9
    mov rbx, 2
    mul rbx
    mov rcx, rax
    pop rbx
    push rcx
    push rbx
    ; this loop will be executed 2*(n of connections)
    .loop5:
    xor r8, r8
    .loop6:
    pop rdi
    push rdi
    mov rax, SYS_READ
    mov rsi, buff
    mov rdx, 1
    syscall

    mov rbx, [buff]
    cmp rbx, 48
    jl .next4
    cmp rbx, 57
    jg .next4
    sub rbx, 48
    mov rax, r8
    mov rdx, 10
    mul rdx
    add rax, rbx
    mov r8, rax
    jmp .loop6
    .next4:
    mov dword[r10], r8d
    add r10, 2
    pop rbx
    pop rcx
    dec rcx
    push rcx
    push rbx
    jnz .loop5
    pop rdi
    pop rcx

    mov rax, SYS_CLOSE
    syscall

    xor rcx, rcx            ; todo delete this, replace lines in drawcube with rax not , dword[rax]
    ret

; draw object from given variable, actually it's static and draws object from "object" variable but it can work with any object variable
_drawObject:
    mov bx, [object]        ; number of nodes
    mov cx, [object+2]      ; number of connectins

.loop:
    push rbx
    push rcx

    mov rax, rbx
    mov rdx, 12
    mul rdx
    mov rbx, rax
    mov rax, rcx
    mov rdx, 4
    mul rdx
    add rax, rbx
    mov r10, object
    add r10, rax

    mov ax, [r10]

    mov rbx, 12
    mul rbx
    mov rdx, object
    add rdx, rax
    add rdx, 4
    cvtss2si r8, [rdx]
    add rdx, 4
    cvtss2si r9, [rdx]
    add rdx, 4


    add r10, 2
    mov ax, [r10]
    mov rbx, 12
    mul rbx
    mov rdx, object
    add rdx, rax
    add rdx, 4
    cvtss2si r10, [rdx]
    add rdx, 4
    cvtss2si r11, [rdx]

    mov bx, [xshift]
    add r8, rbx
    add r10, rbx

    mov bx, [yshift]
    add r9, rbx
    add r11, rbx

    cmp r8, r10
    je .and
    jmp .do
.and:
    cmp r9, r11
    je .skip1
.do:
    call _addLineToDisplay
.skip1:
    pop rcx
    pop rbx

    dec rcx
    jnz .loop
    ret

; pause program for time specyfied in timespec's structure
_sleep:
    mov rax, 35
    mov rdi, timespec
    xor rsi, rsi
    syscall
    ret

; print display variable to terminal
_printDisplay:
    mov rax, SYS_WRITE          ; set syscall
    mov rdi, 1                  ; set stdout as output
    mov rsi, display            ; set variable to print
    mov dx, [display_size]      ; set size of buffer to print
    syscall
    ret

; updates terminal size, set display_size, number of collumns, xshift and yshift
_updateTerminalSize:
    mov rax, 16
    mov rdi, 1
    mov rsi, 0x5413
    mov rdx, sz
    syscall
    ; word[sz+0] = rows
    ; word[sz+2] = collumns
    ; load adn set collumns size
    mov ax, [sz+2]
    add ax, 1
    mov [coll], ax
    ; calculate xshift value
    mov dx, 0
    mov cx, 2
    div cx
    mov [xshift], ax
    ; calculate yshift value
    mov dx, 0
    mov ax, [sz]
    div cx
    mov [yshift], ax
    ; calculate display size, multiple rows and colummns
    mov ax, [sz+2]
    add ax, 1
    mul word[sz]
    mov [display_size], ax

    ret

_exit:
    mov rbx, -1
    mov rax, 60
    mov rdi, 0
    syscall
