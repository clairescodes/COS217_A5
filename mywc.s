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
    stp x29, x30, [sp, -16]!        // Save frame pointer and return address
    mov x29, sp                     // Set frame pointer

    // Compute addresses of global variables
    adrp x20, iChar                 // Compute base address of iChar
    add x20, x20, :lo12:iChar       // Get full address of iChar

    adrp x21, iInWord               // Compute base address of iInWord
    add x21, x21, :lo12:iInWord     // Get full address of iInWord

    adrp x22, lLineCount            // Compute base address of lLineCount
    add x22, x22, :lo12:lLineCount  // Get full address of lLineCount

    adrp x23, lWordCount            // Compute base address of lWordCount
    add x23, x23, :lo12:lWordCount  // Get full address of lWordCount

    adrp x24, lCharCount            // Compute base address of lCharCount
    add x24, x24, :lo12:lCharCount  // Get full address of lCharCount

    adrp x25, fmt_string            // Compute base address of fmt_string
    add x25, x25, :lo12:fmt_string  // Get full address of fmt_string

    /* while ((iChar = getchar()) != EOF) */
Loop_Start:
    bl getchar                      // Call getchar()
    str w0, [x20]                   // Store iChar in memory

    ldr w1, [x20]                   // Load iChar into w1
    cmp w1, #-1                     // Compare iChar with EOF (-1)
    beq Loop_End                    // If iChar == EOF, exit loop

    /* lCharCount = lCharCount + 1; */
    ldr x2, [x24]                   // Load lCharCount
    add x2, x2, #1                  // Increment lCharCount
    str x2, [x24]                   // Store updated lCharCount

    /* if (isspace(iChar)) */
    mov w0, w1                      // Move iChar into w0 for isspace
    bl isspace                      // Call isspace(iChar)
    cmp w0, #0                      // Compare result with 0
    beq NotSpace                    // If zero, character is not whitespace

        /* if (iInWord) */
        ldr w3, [x21]               // Load iInWord
        cmp w3, #0                  // Compare iInWord with 0
        beq SkipWordCountIncrement  // If iInWord == FALSE, skip

            /* lWordCount = lWordCount + 1; */
            ldr x5, [x23]           // Load lWordCount
            add x5, x5, #1          // Increment lWordCount
            str x5, [x23]           // Store updated lWordCount

            /* iInWord = FALSE; */
            mov w3, #0              // Set iInWord to FALSE
            str w3, [x21]           // Store updated iInWord

SkipWordCountIncrement:
    b CheckNewline                  // Proceed to check newline

NotSpace:
    /* else if (!iInWord) */
    ldr w3, [x21]                   // Load iInWord
    cmp w3, #0                      // Compare iInWord with 0
    bne CheckNewline                // If iInWord != FALSE, skip

        /* iInWord = TRUE; */
        mov w3, #1                  // Set iInWord to TRUE
        str w3, [x21]               // Store updated iInWord

CheckNewline:
    /* if (iChar == '\n') */
    cmp w1, #10                     // Compare iChar with newline character
    bne Loop_Next                   // If not newline, skip

        /* lLineCount = lLineCount + 1; */
        ldr x7, [x22]               // Load lLineCount
        add x7, x7, #1              // Increment lLineCount
        str x7, [x22]               // Store updated lLineCount

Loop_Next:
    b Loop_Start                    // Repeat loop

Loop_End:
    /* if (iInWord) */
    ldr w3, [x21]                   // Load iInWord
    cmp w3, #0                      // Compare iInWord with 0
    beq AfterFinalWordCount         // If iInWord == FALSE, skip

        /* lWordCount = lWordCount + 1; */
        ldr x5, [x23]               // Load lWordCount
        add x5, x5, #1              // Increment lWordCount
        str x5, [x23]               // Store updated lWordCount

AfterFinalWordCount:
    /* printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount); */
    mov x0, x25                     // Move address of fmt_string to x0

    ldr x1, [x22]                   // Load lLineCount
    ldr x2, [x23]                   // Load lWordCount
    ldr x3, [x24]                   // Load lCharCount

    bl printf                       // Call printf()

    /* return 0; */
    mov w0, #0                      // Set return value to 0
    ldp x29, x30, [sp], #16         // Restore frame pointer and return address
    ret                             // Return from main