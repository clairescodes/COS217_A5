/*--------------------------------------------------------------------*/
/* mywc.s                                                             */
/* Author: Emily Qian and Claire Shin                                 */
/*--------------------------------------------------------------------*/
   
    .data
    // long lLineCount = 0;
    .global lLineCount
lLineCount:      .quad 0

    // long lWordCount = 0;
    .global lWordCount
lWordCount:      .quad 0

    // long lCharCount = 0;
    .global lCharCount
lCharCount:      .quad 0

    // int iChar;
    .global iChar
iChar:           .word 0

    // int iInWord = FALSE;
    .global iInWord
iInWord:         .word 0

    // Format string for printf
fmt_string:
    .asciz "%7ld %7ld %7ld\n"

    .text
    .global main
main:
    // Function prologue
    stp x29, x30, [sp, -16]!    // Save frame pointer and return address
    mov x29, sp                 // Set frame pointer

    /* while ((iChar = getchar()) != EOF) */
Loop_Start:
    bl getchar                  // iChar = getchar();
    str w0, [sp, #-4]!          // Store iChar on stack
    ldr w1, [sp], #4            // Load iChar into w1 and adjust stack

    cmp w1, #-1                 // if (iChar == EOF)
    beq Loop_End                // Break if end of file

    /* lCharCount = lCharCount + 1; */
    ldr x2, lCharCount          // Load lCharCount
    add x2, x2, #1              // lCharCount += 1
    str x2, lCharCount          // Store lCharCount

    /* if (isspace(iChar)) */
    mov w0, w1                  // Prepare argument for isspace(iChar)
    bl isspace                  // Call isspace()
    cmp w0, #0                  // Compare result with 0
    beq NotSpace                // If zero, character is not whitespace

    /*     if (iInWord) */
    ldr w3, iInWord             // Load iInWord
    cmp w3, #0
    beq SkipWordCountIncrement  // Skip if iInWord == FALSE

        /* lWordCount = lWordCount + 1; */
        ldr x4, lWordCount      // Load lWordCount
        add x4, x4, #1          // lWordCount += 1
        str x4, lWordCount      // Store lWordCount

        /* iInWord = FALSE; */
        mov w3, #0              // Set iInWord to FALSE
        str w3, iInWord

SkipWordCountIncrement:
    b CheckNewline              // Proceed to check newline

NotSpace:
    /* else if (!iInWord) */
    ldr w3, iInWord
    cmp w3, #0
    bne CheckNewline            // Skip if iInWord == TRUE

        /* iInWord = TRUE; */
        mov w3, #1              // Set iInWord to TRUE
        str w3, iInWord

CheckNewline:
    /* if (iChar == '\n') */
    cmp w1, #10                 // Compare iChar with newline character
    bne Loop_Next               // Skip if not newline

        /* lLineCount = lLineCount + 1; */
        ldr x5, lLineCount      // Load lLineCount
        add x5, x5, #1          // lLineCount += 1
        str x5, lLineCount      // Store lLineCount

Loop_Next:
    b Loop_Start                // Repeat loop

Loop_End:
    /* if (iInWord) */
    ldr w3, iInWord
    cmp w3, #0
    beq AfterFinalWordCount     // Skip if iInWord == FALSE

    /* lWordCount = lWordCount + 1; */
    ldr x4, lWordCount          // Load lWordCount
    add x4, x4, #1              // lWordCount += 1
    str x4, lWordCount          // Store lWordCount

AfterFinalWordCount:
    /* printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount); */
    adrp x0, fmt_string@PAGE    // Load address of format string (Page)
    add x0, x0, fmt_string@PAGEOFF // Add offset within page
    ldr x1, lLineCount          // Load lLineCount
    ldr x2, lWordCount          // Load lWordCount
    ldr x3, lCharCount          // Load lCharCount
    bl printf                   // Call printf()

    /* return 0; */
    mov w0, #0                  // Prepare return value
    ldp x29, x30, [sp], #16     // Restore frame pointer and return address
    ret                         // Return from main
