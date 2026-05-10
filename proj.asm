; Anton Razvan-Stefan ; Group 30415

INCLUDE maclib.asm

DATA SEGMENT PARA PUBLIC 'DATA'
    BUFFER1 DB 67 DUP (0)
    BUFFER2 DB 67 DUP (0)
    TEST1 DB "algorithm"
    TEST2 DB "complexity"
    LENGTH1 DW 9
    FNAME DB "test.csv", 0
    FHANDLE DW ?
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

;MOV AL,65D ; max characters that can be read, included the enter ( so 65 )
;XOR SI,SI
;MOV BUFFER1[SI],AL
;READ_STRING BUFFER1

EXTRN LEV:FAR
EXTRN WRITE_STRING_FILE:FAR

CREATE_FILE FNAME    
MOV FHANDLE, AX         

PUSH FHANDLE         
PUSH OFFSET TEST1
PUSH LENGTH1
CALL WRITE_STRING_FILE

CLOSE_FILE FHANDLE      


; your code ends here
RET
START ENDP

; Near procedures declaration zone

; End of near procedures declaration zone

CODE ENDS
END START