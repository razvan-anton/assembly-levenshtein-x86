; Anton Razvan-Stefan ; Group 30415

INCLUDE maclib.asm

PUBLIC CHECK_Q ; for the linker so other fiels have access to it
PUBLIC MAKE_LOWERCASE
PUBLIC PRINT_DEC_NUMBER
PUBLIC LEV


CODE SEGMENT PARA PUBLIC 'CODE'
    ASSUME CS:CODE

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
    JNE END_PROC_CHECK_Q

    CMP BL,'q'
    JE FOUND
    CMP BL,'Q'
    JE FOUND

    JMP END_PROC_CHECK_Q ; if we have one character only, but it is not q

    FOUND:
        MOV AX, 0001H

    END_PROC_CHECK_Q:
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
    
    JCXZ END_PROC_MALE_LOWERCASE ; if length==0
    INC SI

    FOR_LOOP:

        OR BYTE PTR [BX+SI], 00100000B ; making the 6th bit 1 makes the number lower
        ; the user can input ONLY letters, so this is safe to do ( and easy )
        INC SI
        LOOP FOR_LOOP

    END_PROC_MALE_LOWERCASE:
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
        PRINT_CHAR AH


    POP DX
    POP BX
    POP AX
    POP BP
    RET 2
PRINT_DEC_NUMBER ENDP


; store res in AX;
;before call: push: len(b),addr(b),len(a),addr(a)
; like a C++ string_view ( pointer and length )
; make AX 0 before this call in main
LEV PROC FAR
    PUSH BP
    MOV BP,SP
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    ; a is at BP + 6,
    ; len(a) is at BP+8
    ; b is at BP + 10;
    ; len(b) is at BP + 12

    ; load len a and len b
    XOR SI,SI
    MOV SI,[BP+8]
    XOR DI,DI
    MOV DI,[BP+12]

    ;check if len(a)==0
    CMP SI,0 
    JNE NOT_END_A_0
    ; we return here; jump too far to JMp to END
    ; in this case the answer is len(b)
    MOV AX,[BP+12]
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP BP

    RET 8

    NOT_END_A_0:

    ;check if len(b)==0
    CMP DI,0
    JNE NOT_END_B_0
    ; ret again, ans is len(a)
    MOV AX,[BP+8]
    JMP END_PROC_LEV

    NOT_END_B_0:
    ;check if head(a)==head(b)
    XOR SI,SI
    MOV SI, [BP+6]
    XOR DI,DI
    MOV DI, [BP+10]
    ;now SI and DI have the ptr(a) and ptr(b)
    
    ; compare head(a) and head(b)
    MOV BL, [SI]
    CMP BL,BYTE PTR [DI]


    JNE SKIP_NOT_EQUAL

    ;if yes: we call the function again, but with len(a)-1, len(b)-1,ptr a+1, ptr B+1 as parameters

    
    ; decrement lengths and move pointer up by 1
    XOR BX,BX
    ;dec len b and push
    MOV BX,[BP+12]
    DEC BX
    PUSH BX

    XOR BX,BX
    ; incr ptr b and push
    LEA BX,[DI+1]
    PUSH BX


    XOR BX,BX
    ;dec len a and push
    MOV BX,[BP+8]
    DEC BX
    PUSH BX

    XOR BX,BX
    ; incr ptr a and push
    LEA BX,[SI+1]
    PUSH BX

    CALL LEV
    ;also end here to 'return' AX
    JMP END_PROC_LEV

    XOR BX,BX

    SKIP_NOT_EQUAL:
    ; here, we have to do the 1+ min(a,b,c) logic
    ; we need: lev(tail(a,b),b)
    ;lev (a,tail(b))
    ; lev(tail(a),tail(b))

    ;workflow: 1: call first lev, push AX to stack
    ; 2: call 2nd lev, pop AX into BX and cmp them; then put the min into AX and push it
    ; 3: call 3rd lev, pop AX into BX, cmp them, store min in AX
    ; inc AX
    ; exit

    ;call lev(tail(a),b)
    ;push len(b), addr b, len(a)-1, addr(a)+1

    ; a is at BP + 6,
    ; len(a) is at BP+8
    ; b is at BP + 10;
    ; len(b) is at BP + 12
    ; SI and DI still have addr a and addr b

    ;push len b
    MOV BX, [BP+12]
    PUSH BX

    ;push addr B
    XOR BX,BX
    PUSH DI

    ;add len(a) - 1 to stack
    MOV BX,[BP+8]
    DEC BX
    PUSH BX

    ;add addr a + 1 to stack
    XOR BX,BX
    LEA BX,[SI+1]
    PUSH BX
    XOR BX,BX

    CALL LEV
    PUSH AX
    ; step 1 completed

    ; now we need to call lev (a,tail(b))
    ; a is at BP + 6,
    ; len(a) is at BP+8
    ; b is at BP + 10;
    ; len(b) is at BP + 12
    ; SI and DI still have addr a and addr b

    ;push len(b)-1
    MOV BX,[BP+12]
    DEC BX
    PUSH BX

    ;push addr(b)+1 to stack
    XOR BX,BX
    LEA BX,[DI+1]
    PUSH BX
    XOR BX,BX

    ;push len(a) to stack
    MOV BX,[BP+8]
    PUSH BX
    XOR BX,BX

    ;push addr(a) to stack
    LEA BX,[SI]
    PUSH BX
    XOR BX,BX

    CALL LEV
    POP BX ; now the val of AX pushed eariler SHOULD be here 
    
    ; push the min(AX,BX)
    CMP AX,BX
    JL SKIP_LESS_1
    MOV AX,BX

    SKIP_LESS_1:
    PUSH AX

    ;step 2 complete
    ;now we have to call lev(tail(a),tail(b))
    ; a is at BP + 6,
    ; len(a) is at BP+8
    ; b is at BP + 10;
    ; len(b) is at BP + 12
    ; SI and DI still have addr a and addr b

    ;push len(b)-1 to stack
    XOR BX,BX
    MOV BX,[BP+12]
    DEC BX
    PUSH BX
    XOR BX,BX

    ;push addr(b) +1 to stack
    LEA BX,[DI+1]
    PUSH BX
    XOR BX,BX

    ;push len(a) - 1 to stack
    MOV BX,[BP+8]
    DEC BX
    PUSH BX
    XOR BX,BX

    ;push addr(a) + 1 to stack
    LEA BX,[SI+1]
    PUSH BX
    XOR BX,BX

    CALL LEV
    POP BX ; put the old min into BX to compare

    ; put min into AX and exit
    CMP AX,BX
    JL SKIP_LESS_2
    MOV AX,BX

    SKIP_LESS_2:

    INC AX


    END_PROC_LEV:
        POP DI
        POP SI
        POP DX
        POP CX
        POP BX
        POP BP

        RET 8

LEV ENDP






CODE ENDS
END