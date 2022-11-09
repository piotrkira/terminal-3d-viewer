; Rotations

; TODO
; - object addres as parametr (actually it's pretty static, we don't pass object addres, we have just one global object variable in main file)
; - scale transformation, then rename file to transformations
; - correct my grammar, I'm not eng native

%macro rotateX3D 1
    mov rax, %1
    cvtsi2ss xmm0, rax
    call _rotateX3D
%endmacro

%macro rotateY3D 1
    mov rax, %1
    cvtsi2ss xmm0, rax
    call _rotateY3D
%endmacro

%macro rotateZ3D 1
    mov rax, %1
    cvtsi2ss xmm0, rax
    call _rotateZ3D
%endmacro

; calculate thetas from degrees (xmm0)
; load object file
; prepare to execute loop (set rcx to n of nodes, rdx points to last node (x coordinate) inside object file)
_prepareToRotate:
    ; calculate sintheta and costheta
    movss [theta], xmm0
    fld dword[theta]
    fmul dword[radian]
    fld st0
    fsin
    fstp dword[sintheta]                ; sintheta = sin(theta * radian)
    fcos
    fstp dword[costheta]                ; costheta = cos(theta * radian)
    ; read n of nodes
    mov rdx, object
    mov cx, [rdx]
    push rdx
    ; set memory addres to last node, z coordinate
    ; we multiply by 12 because 12 is a sizeof the whole node (x, y,z where each of them is size of 4, dword)
    mov rax, 12
    mul rcx
    pop rdx
    sub rax, 8
    add rdx, rax
    ; rdx points to last node, x coordinate
    ; rcx = n of nodes
    ret

; Rotate objec around x axis, takes xmm0 (degrees) as an argument
_rotateX3D:
    call _prepareToRotate
; for i = n of nodes = rcx; i > 0; i--
.loop:
    ;[rdx] = Xi, [rdx+4] = Yi, [rdx+8] = Zi
    movss xmm0, [rdx+8]            ; Zi
    movss xmm1, [rdx+4]            ; Yi
    ; calculate and set new y value
    movss xmm2, xmm1
    mulss xmm2, [costheta]         ; Yi * costheta
    movss xmm3, xmm0
    mulss xmm3, [sintheta]         ; Zi * sintheta
    subss xmm2, xmm3
    movss [rdx+4], xmm2            ; New Yi = Yi*cosTheta - Zi*sinTheta
    ; calculate and set new z value
    movss xmm2, xmm0
    mulss xmm2, [costheta]         ; Zi * costheta
    movss xmm3, xmm1
    mulss xmm3, [sintheta]         ; Yi * sintheta
    addss xmm2, xmm3
    movss [rdx+8], xmm2            ; New Zi = Zi*cosTheta + Yi*sinTheta, note that Yi is the old one, not one that was calculated just above

    sub rdx, 12                    ; rdx point to Xi-1
    dec rcx
    jnz .loop

    ret

; It works exactly "same" as _rotateX3D
_rotateY3D:
    call _prepareToRotate
.loop:
    movss xmm0, [rdx+8]
    movss xmm1, [rdx]

    movss xmm2, xmm1
    mulss xmm2, [costheta]
    movss xmm3, xmm0
    mulss xmm3, [sintheta]
    subss xmm2, xmm3
    movss [rdx], xmm2

    movss xmm2, xmm0
    mulss xmm2, [costheta]
    movss xmm3, xmm1
    mulss xmm3, [sintheta]
    addss xmm2, xmm3
    movss [rdx+8], xmm2

    sub rdx, 12
    dec rcx
    jnz .loop

    ret

; It works exactly "same" as _rotateX3D
_rotateZ3D:
    call _prepareToRotate
.loop:
    movss xmm0, [rdx+4]
    movss xmm1, [rdx]

    movss xmm2, xmm1
    mulss xmm2, [costheta]
    movss xmm3, xmm0
    mulss xmm3, [sintheta]
    subss xmm2, xmm3
    movss [rdx], xmm2

    movss xmm2, xmm0
    mulss xmm2, [costheta]
    movss xmm3, xmm1
    mulss xmm3, [sintheta]
    addss xmm2, xmm3
    movss [rdx+4], xmm2

    sub rdx, 12
    dec rcx
    jnz .loop

    ret
