; Anton Razvan-Stefan ; Group 30415


READ_STRING MACRO BUF
    PUSH DX
    PUSH AX
    LEA DX,BUF  ; moves the memory location of the buffer into DX,
    ; which is what this macro requires
    MOV AH, 0AH
    INT 21H
    POP DX
    POP AX
    ; push and pop registers so as to not overwrite them
ENDM

; before calling this, string HAS to end with $
; or better: 13, 10, '$'  ( CRLF ) ( if I want to start a new line after that )
PRINT_STRING MACRO MESSAGE
    PUSH AX
    PUSH DX
    LEA DX, MESSAGE
    MOV AH, 09H
    ; this means print everything in memory until $ 
    INT 21H
    POP DX
    POP AX

ENDM

PRINT_CHAR MACRO CHAR ; we will use this to print a number
    PUSH AX
    PUSH DX

    MOV AH,02H
    MOV DL, BYTE PTR CHAR
    INT 21H

    POP DX
    POP AX

ENDM

