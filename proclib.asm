; Anton Razvan-Stefan ; Group 30415

INCLUDE maclib.asm

PUBLIC CHECK_Q ; for the linker so other fiels have access to it
PUBLIC MAKE_LOWERCASE
PUBLIC PRINT_DEC_NUMBER


ASSUME CS:CODE  ; for calculating correct offsets

;push buffer[2] on stack before call (first char ), and length: buffer[1]
CHECK_Q PROC FAR
    PUSH BP
    MOV BP,SP

    MOV BL,[BP+8] ; buffer[1]
    MOV BH, [BP+6] ; length

    PUSH AX
    PUSH BX

    XOR AX,AX


    CMP BH, 1   ; length has to be 1 for the jump
    JNE END

    CMP BL,'q'
    JE FOUND
    CMP BL,'Q'
    JE FOUND

    JMP END ; if we have one character only, but it is not q

    FOUND:
        MOV AX, 0001H

    END:
        ; if AX is 1, we found q; if AX is 0, we didn't
        POP BX
        POP AX
        POP BP
        RET 4
CHECK_Q ENDP


;push buffer address before calling
MAKE_LOWERCASE PROC FAR
    PUSH BP
    MOV BP,SP
    MOV BX, [BP+6] ; buffer address

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI

    MOV SI,1
    XOR CX,CX
    MOV CL, BYTE PTR [BX+SI] ; length
    
    JCXZ END ; if length==0
    INC SI

    FOR_LOOP:

        OR BYTE PTR [BX+SI], 00100000B ; making the 6th bit 1 makes the number lower
        ; the user can input ONLY letters, so this is safe to do ( and easy )
        INC SI
        LOOP FOR_LOOP

    END:
        POP SI
        POP CX
        POP BX
        POP AX
        POP BP
        RET 2
MAKE_LOWERCASE ENDP




; push number to stack before calling
PRINT_DEC_NUMBER PROC FAR ; we will use the PRINT CHAR MACRO for this
    PUSH BP
    MOV BP,SP

    PUSH AX
    XOR AX,AX
    MOV AX,[BP+6]

    PUSH BX
    PUSH DX

    ; note: we don't need a loop since the max number of digits is 2

    XOR BX,BX
    MOV BL,10
    DIV BL ; AH will have the remainder ( unit ), AL will have the 'zeci'

    CMP AL,0
    JE PRINT_UNIT

    ADD AL,30h
    PRINT_CHAR AL ; to convert to ascii

    PRINT_UNIT:
        ADD AH,30h
        PRINCT_CHAR AH


    POP DX
    POP BX
    POP AX
    POP BP
    RET 2
PRINT_DEC_NUMBER ENDP