; Anton Razvan-Stefan ; Group 30415

INCLUDE maclib.asm

DATA SEGMENT PARA PUBLIC 'DATA'
    ; 13 10 are the CRLF, added for better readability in console
    MSG_MENU   DB 13, 10, "Choose operating mode (intr/stat/tri/q): $"
    MSG_INTR   DB 13, 10, "Input two words separated by ENTER or input Q to exit", 13, 10, "$"
    MSG_STAT   DB 13, 10, "Input two file names (Words 2 Check, DICT) separated by space", 13, 10, "$"
    MSG_TRI    DB 13, 10, "Input three words separated by ENTER or input Q to exit", 13, 10, "$"
    MSG_LEV    DB 13, 10, "The Levenshtein distance is: $"
    MSG_SDONE  DB 13, 10, "The similarity matrix is saved in result.csv", 13, 10, "$"
    MSG_EXIT   DB 13, 10, "Exiting...", 13, 10, "$"
    
    COMMA   DB ','
    CRLF    DB 13, 10      
    CRLF_D  DB 13,10, "$"   ; when I need the dollar sign to print to screen
    NF      DB "N/F"   

    MAX_SIZE DW 66  
    
    FILENAME_RES   DB "result.csv", 0  
    ; H stands for Handle
    H_W2C      DW ?                
    H_DICT     DW ?                
    H_RES      DW ?                
    
    IN_MENU     DB 6, ?, 6 DUP(0)   
    IN_WORD_A   DB 66, ?, 66 DUP(0) 
    IN_WORD_B   DB 66, ?, 66 DUP(0)
    IN_WORD_C   DB 66, ?, 66 DUP(0) 
    IN_FILENAME DB 66, ?, 66 DUP(0)

    BUF_W2C    DB 66 DUP(0)        
    BUF_DICT   DB 66 DUP(0)        
    BUF_SCORE  DB 4 DUP(0)         
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
EXTRN CLEAR_BUFFER:FAR, CHECK_Q:FAR, MAKE_LOWERCASE:FAR, LEV:FAR, PRINT_DEC_NUMBER:FAR, GET_FILENAMES:FAR
; your code starts here

START_MENU:
    PRINT_STRING MSG_MENU
    ;clear buffer before any input'

    READ_STRING IN_MENU

    ; using the conditioanl jumps like this to avoid the limited jump length of conditional jumps
    MOV AL,[IN_MENU+2] ; move first letter into AL to check

    ;check only by 1st letter
    CMP AL,"i"
    JNE NOT_INTERACTIVE
    JMP INTERACTIVE

    NOT_INTERACTIVE:
    CMP AL,"s"
    JNE NOT_STAT
    JMP STATISTICS

    NOT_STAT:
    CMP AL,"t"
    JNE NOT_TRI
    JMP TRIANGLE

    NOT_TRI:
    ;check for q or Q
    CMP AL,"q"
    JE FOUND_Q_MENU
    CMP AL,"Q"
    JE FOUND_Q_MENU
    
    ;if not found, jump again to start
    JMP START_MENU
    FOUND_Q_MENU:
        JMP EXIT_Q


    INTERACTIVE:
        PRINT_STRING MSG_INTR

        ; clear buffers before reading ; actaully it is redundant and 
        ; this was also the wrong way to do it so I didn't do it anymore
        ; PUSH OFFSET IN_WORD_A
        ; PUSH 66 
        ; CALL CLEAR_BUFFER
        ; PUSH OFFSET IN_WORD_B
        ; PUSH 66
        ; CALL CLEAR_BUFFER

        READ_STRING IN_WORD_A
        XOR AX,AX
        MOV AL,[IN_WORD_A+2] ; first char
        PUSH AX
        MOV AL,[IN_WORD_A+1]  ; length ( amount read )
        CALL CHECK_Q


        ;check if AX is 0 after CHECK_Q PROC call
        ; if AX is 0, we didn't find Q, so we continue
        TEST AX,AX
        JZ READ_2ND_STRING_INTR
        JMP EXIT_Q
        
        READ_2ND_STRING_INTR:

        PRINT_STRING CRLF_D ; so the cursor moves

        READ_STRING IN_WORD_B
        XOR AX,AX
        MOV AL,[IN_WORD_B+2] ; first char
        PUSH AX
        MOV AL,[IN_WORD_B+1]  ; length ( amount read )
        CALL CHECK_Q


        ;check if AX is 0 after CHECK_Q PROC call
        TEST AX,AX
        JZ START_INTR
        JMP EXIT_Q

        START_INTR:
            ; make all lowercase
            LEA BX,IN_WORD_A
            PUSH BX
            CALL MAKE_LOWERCASE

            LEA BX,IN_WORD_B
            PUSH BX
            CALL MAKE_LOWERCASE

            ; load the 'paramteres' for the LEV procedutre
            LEA BX,[IN_WORD_B+2] ; addr of the starting letter
            XOR AX,AX
            MOV AL,[IN_WORD_B+1] ; length

            PUSH AX
            PUSH BX

            LEA BX,[IN_WORD_A+2] ; addr of the starting letter
            XOR AX,AX
            MOV AL,[IN_WORD_A+1] ; length

            PUSH AX
            PUSH BX

            XOR DX,DX

            CALL LEV

            ; print the result
            PRINT_STRING MSG_LEV
            PUSH DX
            CALL PRINT_DEC_NUMBER
            PRINT_STRING CRLF_D ; to also have newline

            JMP INTERACTIVE ; go back

    STATISTICS:
        ; parse input:
        PRINT_STRING MSG_STAT
        READ_STRING IN_FILENAME
        PUSH OFFSET IN_FILENAME
        CALL GET_FILENAMES
        ; words to check: in BX
        ; dictionary: in AX

        ; open files and store their handles;
        ; handles var names:     H_W2C      H_DICT        H_RES   
        OPEN_FILE AX
        MOV H_DICT,AX
        OPEN_FILE BX
        MOV H_W2C,AX
        CREATE_FILE FILENAME_RES
        MOV H_RES,AX

        STAT_OUTER_LOOP:
            ; 0 out the buffer before every read
            PUSH OFFSET BUF_W2C
            PUSH MAX_SIZE
            CALL CLEAR_BUFFER

            ;read word from file
            PUSH OFFSET BUF_W2C
            PUSH H_W2C
            CALL READ_WORD_FROM_FILE
            TEST AX,AX ; check if AX==0 ( AX being amount read)
            ; if nothing is read, we have reached the end
            JNZ WRITE_TO_FILE

            JMP STAT_CLEANUP

            WRITE_TO_FILE:
                ;write the word and a come ( csv format )
                PUSH H_RES
                PUSH OFFSET BUF_W2C
                PUSH AX ; word size
                CALL WRITE_STRING_FILE
                ; to write the comma
                WRITE_CHAR_FILE H_RES, COMMA

            STAT_INNER_LOOP:






        STAT_CLEANUP:
            ; close files
            CLOSE_FILE H_W2C
            CLOSE_FILE H_DICT
            CLOSE_FILE H_RES
    TRIANGLE:

    EXIT_Q:


; your code ends here
RET
START ENDP

; Near procedures declaration zone

; End of near procedures declaration zone

CODE ENDS
END START