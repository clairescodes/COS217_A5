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
    ldr x0, =iChar              // Load address of iChar
    str w0, [x0]                // Store iChar in memory

    ldr w1, [x0]                // Load iChar into w1
    cmp w1, #-1                 // if (iChar == EOF)
    beq Loop_End                // Break if end of file

    /* lCharCount = lCharCount + 1; */
    ldr x1, =lCharCount         // Load address of lCharCount
    ldr x2, [x1]                // Load current value of lCharCount
    add x2, x2, #1              // lCharCount += 1
    str x2, [x1]                // Store updated lCharCount

    /* if (isspace(iChar)) */
    mov w0, w1                  // Prepare argument for isspace(iChar)
    bl isspace                  // Call isspace()
    cmp w0, #0                  // Compare result with 0
    beq NotSpace                // If zero, character is not whitespace

    /*     if (iInWord) */
    ldr x3, =iInWord            // Load address of iInWord
    ldr w3, [x3]                // Load value of iInWord
    cmp w3, #0
    beq SkipWordCountIncrement  // Skip if iInWord == FALSE

        /* lWordCount = lWordCount + 1; */
        ldr x4, =lWordCount     // Load address of lWordCount
        ldr x5, [x4]            // Load current value of lWordCount
        add x5, x5, #1          // lWordCount += 1
        str x5, [x4]            // Store updated lWordCount

        /* iInWord = FALSE; */
        mov w3, #0              // Set iInWord to FALSE
        str w3, [x3]            // Store updated iInWord

SkipWordCountIncrement:
    b CheckNewline              // Proceed to check newline

NotSpace:
    /* else if (!iInWord) */
    ldr w3, [x3]                // Load value of iInWord
    cmp w3, #0
    bne CheckNewline            // Skip if iInWord == TRUE

        /* iInWord = TRUE; */
        mov w3, #1              // Set iInWord to TRUE
        str w3, [x3]            // Store updated iInWord

CheckNewline:
    /* if (iChar == '\n') */
    cmp w1, #10                 // Compare iChar with newline character
    bne Loop_Next               // Skip if not newline

        /* lLineCount = lLineCount + 1; */
        ldr x6, =lLineCount     // Load address of lLineCount
        ldr x7, [x6]            // Load current value of lLineCount
        add x7, x7, #1          // lLineCount += 1
        str x7, [x6]            // Store updated lLineCount

Loop_Next:
    b Loop_Start                // Repeat loop

Loop_End:
    /* if (iInWord) */
    ldr x3, =iInWord            // Load address of iInWord
    ldr w3, [x3]                // Load value of iInWord
    cmp w3, #0
    beq AfterFinalWordCount     // Skip if iInWord == FALSE

    /* lWordCount = lWordCount + 1; */
    ldr x4, =lWordCount         // Load address of lWordCount
    ldr x5, [x4]                // Load current value of lWordCount
    add x5, x5, #1              // lWordCount += 1
    str x5, [x4]                // Store updated lWordCount

AfterFinalWordCount:
    /* printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount); */
    adrp x0, fmt_string         // Load page address of fmt_string
    add x0, x0, #:lo12:fmt_string // Add low 12 bits of the address
    ldr x1, =lLineCount         // Load address of lLineCount
    ldr x1, [x1]                // Load value of lLineCount
    ldr x2, =lWordCount         // Load address of lWordCount
    ldr x2, [x2]                // Load value of lWordCount
    ldr x3, =lCharCount         // Load address of lCharCount
    ldr x3, [x3]                // Load value of lCharCount
    bl printf                   // Call printf()

    /* return 0; */
    mov w0, #0                  // Prepare return value
    ldp x29, x30, [sp], #16     // Restore frame pointer and return address
    ret                         // Return from main
