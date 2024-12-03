//---------------------------------------------------------------------
// mywc.s
// Author: Emily Qian and Claire Shin
//---------------------------------------------------------------------
        .section .rodata

format:
        .string "%7ld %7ld %7ld\n" // Format string for printf

//---------------------------------------------------------------------
        .section .data

        // long lLineCount = 0;
lLineCount:      .quad 0

        // long lWordCount = 0;
lWordCount:      .quad 0

        // long lCharCount = 0;
lCharCount:      .quad 0

        // int iChar;
iChar:           .word 0

        // int iInWord = FALSE;
        .global iInWord
iInWord:         .word 0

//---------------------------------------------------------------------
        .section .text

        // Define constants
        .equ     TRUE, 1 
        .equ     FALSE, 0 
        .equ     NEWLINE, 10                    // ASCII code for '\n'
        .equ     MAIN_STACK_BYTECOUNT, 16

        .global main

main:
        // Prolog
        sub     sp, sp, MAIN_STACK_BYTECOUNT
        str     x30, [sp]

read:
        // ch = getchar();
        bl      getchar
        adr     x1, iChar
        str     w0, [x1]

        // if (ch == EOF) goto endloop;
        ldr     w1, [x1]
        cmp     w1, EOF
        beq     endloop

processchar:
        // charCount++;
        adr     x0, lCharCount
        ldr     w2, [x0]
        add     w2, w2, #1
        str     w2, [x0]

        // if (isspace(ch)) goto whitespace;
        adr     x0, iChar
        ldr     w1, [x0]
        mov     w0, w1
        bl      isspace
        cmp     w0, FALSE
        bne     whitespace

        // goto nonwhitespace;
        b       nonwhitespace
whitespace:
        // if (inWord)
        adr     x0, iInWord
        ldr     w1, [x0]
        cmp     w1, FALSE
        beq     checknewline

        // wordCount++;
        adr     x0, lWordCount
        ldr     w1, [x0]
        add     w1, w1, #1
        str     w1, [x0]

        // inWord = FALSE;
        adr     x0, iInWord
        mov     w1, FALSE
        str     w1, [x0]

checknewline:
        // if (ch == '\n') lineCount++;
        adr     x0, iChar
        ldr     w1, [x0]
        cmp     w1, #10
        bne     read
        adr     x0, lLineCount
        ldr     w1, [x0]
        add     w1, w1, #1
        str     w1, [x0]
        b       read

nonwhitespace:
        // if (!inWord) inWord = 1;
        adr     x0, iInWord
        ldr     w1, [x0]
        cmp     w1, FALSE
        bne     read
        mov     w1, TRUE
        str     w1, [x0]
        b       read

endloop:
        // if (inWord) wordCount++;
        adr     x0, iInWord
        ldr     w1, [x0]
        cmp     w1, FALSE
        beq     print
        adr     x0, lWordCount
        ldr     w1, [x0]
        add     w1, w1, #1
        str     w1, [x0]

print:
        // printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
        adr     x0, printFormatStr
        adr     x1, lLineCount
        ldr     x1, [x1]
        adr     x2, lWordCount
        ldr     x2, [x2]
        adr     x3, lCharCount
        ldr     x3, [x3]
        bl      printf

exit:
        // return 0;
        mov     w0, 0
        ldr     x30, [sp]
        add     sp, sp, MAIN_STACK_BYTECOUNT
        ret