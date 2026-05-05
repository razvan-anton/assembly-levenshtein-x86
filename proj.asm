; Anton Razvan-Stefan ; Group 30415


INCLUDE maclib.asm

DATA SEGMENT PARA PUBLIC 'DATA'
    BUFFER1 DB 67 DUP (0)
    BUFFER2 DB 67 DUP (0)
DATA ENDS

; Macro declaration zone

; End of macro declaration zone

CODE SEGMENT PARA PUBLIC 'CODE'
ASSUME CS:CODE, DS:DATA
START PROC FAR
PUSH DS
XOR AX, AX
MOV DS, AX
PUSH AX
MOV AX, DATA
MOV DS, AX
; your code starts here

MOV AL,65D ; max characters that can be read, included the enter ( so 65 )
XOR SI,SI
MOV BUFFER1[SI],AL
READSTRING BUFFER1




; your code ends here
RET
START ENDP

; Near procedures declaration zone

; End of near procedures declaration zone

CODE ENDS
END START