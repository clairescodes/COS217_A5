//---------------------------------------------------------------------
// mywc.s
// Author: Emily Qian and Claire Shin
//---------------------------------------------------------------------

        .section .rodata

fmt_string:
        .string "%7ld %7ld %7ld\n" // Format string for printf

//---------------------------------------------------------------------

        .section .data

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

//---------------------------------------------------------------------

        .section .text

        // Define constants
        .equ EOF, -1              // End of file
        .equ TRUE, 1              // Boolean true
        .equ FALSE, 0             // Boolean false
        .equ NEWLINE, 10          // ASCII code for '\n'
        .equ STACK_FRAME_SIZE, 16 // Stack frame size (aligned to 16 bytes)

        .global main

main:
        // Prolog
        sub     sp, sp, #STACK_FRAME_SIZE // Allocate stack frame
        str     x30, [sp]                 // Save return address on the stack
        mov     x29, sp                   // Set frame pointer

        // while ((iChar = getchar()) != EOF)
Loop_Start:
        bl      getchar                   // Call getchar()
        adr     x1, iChar                 // Compute address of iChar
        str     w0, [x1]                  // Store iChar = getchar()

        adr     x1, iChar                 // Compute address of iChar
        ldr     w1, [x1]                  // Load iChar
        cmp     w1, #EOF                  // Compare iChar with EOF
        beq     Loop_End                  // Exit loop if iChar == EOF

        // lCharCount++;
        adr     x1, lCharCount            // Compute address of lCharCount
        ldr     x2, [x1]                  // Load lCharCount
        add     x2, x2, #1                // Increment lCharCount
        str     x2, [x1]                  // Store updated lCharCount

        // if (isspace(iChar))
        mov     w0, w1                    // Move iChar into w0 for isspace
        bl      isspace                   // Call isspace(iChar)
        cmp     w0, #0                    // Compare result with FALSE
        beq     NotSpace                  // If not whitespace, skip

        // if (iInWord)
        adr     x1, iInWord               // Compute address of iInWord
        ldr     w2, [x1]                  // Load iInWord
        cmp     w2, #0                    // Compare iInWord with FALSE
        beq     SkipWordCountIncrement    // Skip if iInWord == FALSE

        // lWordCount++;
        adr     x1, lWordCount            // Compute address of lWordCount
        ldr     x2, [x1]                  // Load lWordCount
        add     x2, x2, #1                // Increment lWordCount
        str     x2, [x1]                  // Store updated lWordCount

        // iInWord = FALSE;
        mov     w2, #0                    // Set iInWord to FALSE
        str     w2, [x1]                  // Store updated iInWord

SkipWordCountIncrement:
        b       CheckNewline              // Proceed to newline check

NotSpace:
        // else if (!iInWord)
        adr     x1, iInWord               // Compute address of iInWord
        ldr     w2, [x1]                  // Load iInWord
        cmp     w2, #0                    // Compare iInWord with FALSE
        bne     CheckNewline              // If iInWord != FALSE, skip

        // iInWord = TRUE;
        mov     w2, #1                    // Set iInWord to TRUE
        str     w2, [x1]                  // Store updated iInWord

CheckNewline:
        // if (iChar == '\n')
        adr     x1, iChar                 // Compute address of iChar
        ldr     w2, [x1]                  // Load iChar
        cmp     w2, #NEWLINE              // Compare iChar with newline character
        bne     Loop_Next                 // Skip if not newline

        // lLineCount++;
        adr     x1, lLineCount            // Compute address of lLineCount
        ldr     x2, [x1]                  // Load lLineCount
        add     x2, x2, #1                // Increment lLineCount
        str     x2, [x1]                  // Store updated lLineCount

Loop_Next:
        b       Loop_Start                // Repeat loop

Loop_End:
        // if (iInWord)
        adr     x1, iInWord               // Compute address of iInWord
        ldr     w2, [x1]                  // Load iInWord
        cmp     w2, #0                    // Compare iInWord with FALSE
        beq     AfterFinalWordCount       // Skip if iInWord == FALSE

        // lWordCount++;
        adr     x1, lWordCount            // Compute address of lWordCount
        ldr     x2, [x1]                  // Load lWordCount
        add     x2, x2, #1                // Increment lWordCount
        str     x2, [x1]                  // Store updated lWordCount

AfterFinalWordCount:
        // printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
        adr     x0, fmt_string            // Compute address of format string
        adr     x1, lLineCount            // Compute address of lLineCount
        ldr     x1, [x1]                  // Load lLineCount
        adr     x2, lWordCount            // Compute address of lWordCount
        ldr     x2, [x2]                  // Load lWordCount
        adr     x3, lCharCount            // Compute address of lCharCount
        ldr     x3, [x3]                  // Load lCharCount
        bl      printf                    // Call printf()

        // return 0;
        mov     w0, #0                    // Set return value to 0
        ldr     x30, [sp]                 // Restore return address from stack
        add     sp, sp, #STACK_FRAME_SIZE // Deallocate stack frame
        ret