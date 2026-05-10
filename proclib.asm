; Anton Razvan-Stefan ; Group 30415

INCLUDE maclib.asm

 ; for the linker so other fiels have access to it
 ;helper comments after each proc so I don't have to scroll this every time I forget the order of args

PUBLIC CHECK_Q              ; Push first_char, push length. Result: AX = 1 if 'Q'/'q', else 0.
PUBLIC MAKE_LOWERCASE       ; Push buffer addr. Result: Modifies buffer in-place.
PUBLIC PRINT_DEC_NUMBER     ; Push integer. Result: Outputs directly to console.
PUBLIC LEV                  ; Push len(b), ptr(b), len(a), ptr(a). Result: DL = Lev dist
PUBLIC WRITE_STRING_FILE    ; Push file handle, buffer addr, length. Result: Writes to file.
PUBLIC READ_WORD_FROM_FILE  ; Push buffer addr, file handle. Result: AX = string length read.
PUBLIC MAX                  ; Push num1, num2. Result: AX = maximum of the two.
PUBLIC CALC_SIMILARITY      ; Push len(b), ptr(b), len(a), ptr(a). Result: AX = similarity percentage (0-100).
PUBLIC INT_TO_STRING        ; Push buffer addr, integer. Result: AX = length of ASCII string.
PUBLIC CLEAR_BUFFER         ; Push buffer addr, length. Result: Memory block zeroed.


CODE SEGMENT PARA PUBLIC 'CODE'
    ASSUME CS:CODE

;push first_char on stack before call (first char ), and length: buffer[1]
CHECK_Q PROC FAR
    PUSH BP
    MOV BP,SP
    PUSH BX

    MOV BL,[BP+8] ; first_char
    MOV BH, [BP+6] ; length


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
        POP BP
        RET 4
CHECK_Q ENDP


;push buffer address before calling
MAKE_LOWERCASE PROC FAR
    PUSH BP
    MOV BP,SP

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI

    MOV BX, [BP+6] ; buffer address

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
    PUSH CX

    ; note: we don't need a loop since the max number of digits is 2

    XOR BX,BX
    MOV BL,10
    DIV BL ; AH will have the remainder ( unit ), AL will have the 'zeci'

    CMP AL,0
    MOV CX,AX
    JE PRINT_UNIT

    ADD AL,30h
    MOV CX,AX
    PRINT_CHAR CL ; to convert to ascii

    PRINT_UNIT:
        ADD CH,30h
        PRINT_CHAR CH

    POP CX
    POP DX
    POP BX
    POP AX
    POP BP
    RET 2
PRINT_DEC_NUMBER ENDP

; push FILE_HANDLE and BUFFER_ADDR before calling
;returns length in AX
READ_WORD_FROM_FILE PROC FAR
    PUSH BP
    MOV BP,SP
    PUSH BX
    PUSH CX
    PUSH SI

    MOV BX,[BP+8] ; move buff addr to BX
    MOV AX,[BP+6]
    XOR SI,SI

    WHILE_READ:
        READ_FILE AX, 1, [BX+SI]
        
        CMP AX,0 ; if there is no CR/LF or nothing left to read
        JE STOP_READ

        ; check if we found CR / LF
        CMP byte PTR [BX+SI],0AH  
        JE STOP_READ
        CMP BYTE PTR [BX+SI],0DH
        JE STOP_READ

        CMP SI,64 ; if input is too long
        JE STOP_READ

        INC SI
        JMP WHILE_READ

    STOP_READ:

    MOV AX,SI

    POP SI
    POP CX
    POP BX
    POP BP
    RET 4
READ_WORD_FROM_FILE ENDP


;before calling, push: File handle, buffer address, length
WRITE_STRING_FILE PROC FAR
    PUSH BP
    MOV BP,SP
    PUSH SI
    PUSH AX
    PUSH BX
    PUSH CX

    ; retrieve parameters
    MOV DX,[BP+6] ; length
    MOV SI,[BP+8]   ; addr
    MOV CX,[BP+10] ; file handle
    WRITE_FILE CX,DX,[SI] ; used [SI] and not SI cuz in the macro we call LEA

    POP CX
    POP BX
    POP AX
    POP SI
    POP BP

    RET 6
WRITE_STRING_FILE ENDP

; AX will have the max
;push two numbers to stack before calling
MAX PROC FAR
    PUSH BP
    MOV BP,SP
    PUSH BX
    MOV AX,[BP+6]
    MOV BX,[BP+8]
    CMP AX,BX
    JG END_PROC_MAX
    MOV AX,BX


    END_PROC_MAX:
    POP BX
    POP BP
    RET 4
MAX ENDP


; before calling, push: len(b), ptr b, len(a), ptr a
CALC_SIMILARITY PROC FAR
    ; this implements the formula:
    ; sim(a,b) = 1 - ( lev(a,b) / max( len(a), len(b) ) ) * 100
    PUSH BP
    MOV BP,SP
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV BX,[BP+6] ; ptr a
    MOV CX,[BP+8] ; len(a)
    MOV DX,[BP+10] ; ptr b
    MOV SI,[BP+12] ; len(b)

    PUSH SI
    PUSH DX
    PUSH CX
    PUSH BX
    CALL FAR PTR LEV

    ; now AX has lev(a,b)
    MOV BX,AX 
    PUSH CX
    PUSH SI
    CALL MAX
    ;now AX has max and BX has lev

    ; we will bring to common denominator and perform:
    ; ( max - lev ) * 100 , then / max
    ; to increase precision

    MOV CX,AX ; for division to keep max
    OR CX,CX

    JNZ CONTINUE_PROC_CALC_SIMILARITY ; if both are of len 0 we can't divide by 0;
    ; in that case similarity would be 100
    MOV AX,100
    JMP END_PROC_CALC_SIMILARITY

    CONTINUE_PROC_CALC_SIMILARITY:
    SUB AX,BX
    MOV BL,100
    MUL BL
    DIV CL
    XOR AH,AH ; to get rid of the remainder



    END_PROC_CALC_SIMILARITY:
    POP SI
    POP DX
    POP CX
    POP BX
    POP BP


    RET 8

CALC_SIMILARITY ENDP

; before calling, push int and buffer addr
;buffer will be in BX, digit count in AX
INT_TO_STRING PROC FAR
    PUSH BP
    MOV BP,SP
    PUSH DX
    PUSH SI
    PUSH CX

    XOR SI,SI ; for indexing
    XOR CX,CX ; to count number of digis
    MOV BX,[BP+8] ; addr to write to
    MOV AX,[BP+6] ; integer
    XOR DX,DX
    MOV DL,10

    OR AX,0 ; check for 0 before entering loop
    JNZ DIV_LOOP
    MOV byte ptr [BX],"0"
    MOV AX,1
    JMP END_PROC_INT_TO_STRING

    DIV_LOOP:

        OR AX,0 ; check for end of loop
        JZ BUILD_NUM

        DIV DL ; AH will have remainder; AL will have the result

        XOR CH,CH
        MOV CL,AH
        PUSH CX ; so we can use the stack's LIFO to get the number in the right order
        XOR AH,AH
        INC SI
        JMP DIV_LOOP

    BUILD_NUM:
    MOV CX,SI
    XOR SI,SI
    XOR DX,DX ; to use it for popping safely

    POP_LOOP:
        POP DX 
        ADD DL,"0"  ; to make string
        MOV byte ptr [BX+SI],DL
        INC SI

        LOOP POP_LOOP

    MOV AX,SI
    END_PROC_INT_TO_STRING:
    POP CX
    POP SI
    POP DX
    POP BP
    RET 4
INT_TO_STRING ENDP

; takes addr and length, makes everything 0
CLEAR_BUFFER PROC FAR
    PUSH BP
    MOV BP,SP
    PUSH CX
    PUSH BX
    PUSH SI 
    PUSH AX

    XOR AX,AX

    MOV CX,[BP+6] ;length
    MOV BX,[BP+8] ; addr 
    XOR SI,SI
    LOOP_CLEAR_BUFFER:   ; loop for the sized of the data and zero it out
        MOV [BX+SI],AL
        INC SI

        LOOP LOOP_CLEAR_BUFFER

    POP AX
    POP SI
    POP BX
    POP CX
    POP BP
    RET 4
CLEAR_BUFFER ENDP






; store res in DL!;
;before call: push: len(b),addr(b),len(a),addr(a)
; like a C++ string_view ( pointer and length )
; make DX 0 before this call in main
LEV PROC FAR
    PUSH BP
    MOV BP,SP
    PUSH BX
    PUSH CX
    PUSH AX
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
    MOV DX,[BP+12]
    POP DI
    POP SI
    POP AX
    POP CX
    POP BX
    POP BP

    RET 8

    NOT_END_A_0:

    ;check if len(b)==0
    CMP DI,0
    JNE NOT_END_B_0
    ; ret again, ans is len(a)
    MOV DX,[BP+8]
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
    ;also end here to 'return' DX
    JMP END_PROC_LEV

    XOR BX,BX

    SKIP_NOT_EQUAL:
    ; here, we have to do the 1+ min(a,b,c) logic
    ; we need: lev(tail(a,b),b)
    ;lev (a,tail(b))
    ; lev(tail(a),tail(b))

    ;workflow: 1: call first lev, push DX to stack
    ; 2: call 2nd lev, pop DX into BX and cmp them; then put the min into DX and push it
    ; 3: call 3rd lev, pop DX into BX, cmp them, store min in DX
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
    PUSH DX
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
    POP BX ; now the val of DX pushed eariler SHOULD be here 
    
    ; push the min(AX,BX)
    CMP DX,BX
    JL SKIP_LESS_1
    MOV DX,BX

    SKIP_LESS_1:
    PUSH DX

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

    ; put min into DX and exit
    CMP DX,BX
    JL SKIP_LESS_2
    MOV DX,BX

    SKIP_LESS_2:

    INC DX


    END_PROC_LEV:
        POP DI
        POP SI
        POP AX
        POP CX
        POP BX
        POP BP

        RET 8
LEV ENDP






CODE ENDS
END