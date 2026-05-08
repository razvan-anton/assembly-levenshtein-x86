; Anton Razvan-Stefan ; Group 30415


READ_STRING MACRO BUF
    PUSH DX
    PUSH AX
    LEA DX,BUF  ; moves the memory location of the buffer into DX,
    ; which is what this macro requires
    MOV AH, 0AH
    INT 21H
    POP AX
    POP DX
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

; AX will have the filehandle / error code
OPEN_FILE MACRO FILENAME
    PUSH DX

    LEA DX,FILENAME
    XOR AL,AL
    MOV AH,3DH
    INT 21H

    POP DX
ENDM

; AX will have the filehandle / error code
CREATE_FILE MACRO FILENAME
    PUSH DX
    PUSH CX

    LEA DX,FILENAME
    XOR AL,AL
    XOR CX,CX
    MOV AH,3CH
    INT 21H

    POP CX
    POP DX
ENDM

; AX will have bytes read / error code
READ_FILE MACRO FILE_HANDLE, BYTES_TO_READ, BUFFER
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AH,3FH
    MOV BX,FILE_HANDLE
    MOV CX, BYTES_TO_READ
    LEA DX,BUFFER
    INT 21H


    POP DX
    POP CX
    POP BX
ENDM

; AX will have bytes written / error code
WRITE_FILE MACRO FILE_HANDLE, BYTES_TO_WRITE, DATA
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AH,40H
    MOV BX,FILE_HANDLE
    MOV CX, BYTES_TO_WRITE
    LEA DX, DATA
    INT 21H


    POP DX
    POP CX
    POP BX
ENDM 

; AX WILL HAVE ERROR CODE
CLOSE_FILE MACRO FILE_HANDLE
    PUSH BX
    
    MOV AH,3EH
    MOV BX,FILE_HANDLE

    POP BX
ENDM

; AX will have error code / 1 if success
WRITE_CHAR_FILE MACRO FILE_HANDLE, CHAR
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AH,40H
    MOV BX,FILE_HANDLE
    MOV CX,1
    LEA DX,CHAR
    INT 21H

    POP DX
    POP CX
    POP BX
ENDM

; moves the file pointer to the start of the file
SEEK_START MACRO FILE_HANDLE
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AH,42H
    XOR AL,AL
    MOV BX,FILE_HANDLE
    XOR CX,CX
    XOR DX,DX
    INT 21H

    POP DX
    POP CX
    POP BX
    POP AX
ENDM

; moves the file pointer to the END of the file
SEEK_END MACRO FILE_HANDLE
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AH,42H
    MOV AL,02H
    MOV BX,FILE_HANDLE
    XOR CX,CX
    XOR DX,DX
    INT 21H

    POP DX
    POP CX
    POP BX
    POP AX
ENDM