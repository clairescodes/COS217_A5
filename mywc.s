//---------------------------------------------------------------------
// mywc.s
// Author: Bob Dondero
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
        bl      getchar           // Call getchar()
        str     w0, iChar         // Store iChar = getchar()

        ldr     w1, iChar         // Load iChar
        cmp     w1, #EOF          // Compare iChar with EOF
        beq     Loop_End          // Exit loop if iChar == EOF

        // lCharCount++;
        ldr     x2, lCharCount    // Load lCharCount
        add     x2, x2, TRUE      // Increment lCharCount by TRUE (1)
        str     x2, lCharCount    // Store updated lCharCount

        // if (isspace(iChar))
        mov     w0, w1            // Move iChar into w0 for isspace
        bl      isspace           // Call isspace(iChar)
        cmp     w0, FALSE         // Compare result with FALSE (0)
        beq     NotSpace          // If not whitespace, skip

        // if (iInWord)
        ldr     w3, iInWord       // Load iInWord
        cmp     w3, FALSE         // Compare iInWord with FALSE
        beq     SkipWordCountIncrement // Skip if iInWord == FALSE

        // lWordCount++;
        ldr     x5, lWordCount    // Load lWordCount
        add     x5, x5, TRUE      // Increment lWordCount by TRUE (1)
        str     x5, lWordCount    // Store updated lWordCount

        // iInWord = FALSE;
        mov     w3, FALSE         // Set iInWord to FALSE
        str     w3, iInWord       // Store updated iInWord

SkipWordCountIncrement:
        b       CheckNewline      // Proceed to newline check

NotSpace:
        // else if (!iInWord)
        ldr     w3, iInWord       // Load iInWord
        cmp     w3, FALSE         // Compare iInWord with FALSE
        bne     CheckNewline      // If iInWord != FALSE, skip

        // iInWord = TRUE;
        mov     w3, TRUE          // Set iInWord to TRUE
        str     w3, iInWord       // Store updated iInWord

CheckNewline:
        // if (iChar == '\n')
        cmp     w1, #NEWLINE      // Compare iChar with newline character
        bne     Loop_Next         // Skip if not newline

        // lLineCount++;
        ldr     x7, lLineCount    // Load lLineCount
        add     x7, x7, TRUE      // Increment lLineCount by TRUE (1)
        str     x7, lLineCount    // Store updated lLineCount

Loop_Next:
        b       Loop_Start        // Repeat loop

Loop_End:
        // if (iInWord)
        ldr     w3, iInWord       // Load iInWord
        cmp     w3, FALSE         // Compare iInWord with FALSE
        beq     AfterFinalWordCount // Skip if iInWord == FALSE

        // lWordCount++;
        ldr     x5, lWordCount    // Load lWordCount
        add     x5, x5, TRUE      // Increment lWordCount by TRUE (1)
        str     x5, lWordCount    // Store updated lWordCount

AfterFinalWordCount:
        // printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
        ldr     x0, fmt_string    // Address of format string
        ldr     x1, lLineCount    // Load lLineCount
        ldr     x2, lWordCount    // Load lWordCount
        ldr     x3, lCharCount    // Load lCharCount
        bl      printf            // Call printf()

        // return 0;
        mov     w0, FALSE         // Set return value to FALSE (0)
        ldr     x30, [sp]         // Restore return address from the stack
        add     sp, sp, #STACK_FRAME_SIZE // Deallocate stack frame
        ret                       // Return
