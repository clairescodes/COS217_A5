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
        // Prolog: Ensure proper stack alignment
        sub     sp, sp, #STACK_FRAME_SIZE
        stp     x29, x30, [sp]
        mov     x29, sp

        // Initialize variables
        adr     x1, lLineCount
        mov     x2, #0
        str     x2, [x1]          // lLineCount = 0

        adr     x1, lWordCount
        str     x2, [x1]          // lWordCount = 0

        adr     x1, lCharCount
        str     x2, [x1]          // lCharCount = 0

        adr     x1, iInWord
        mov     w2, #FALSE
        str     w2, [x1]          // iInWord = FALSE

Loop_Start:
        // Read a character: iChar = getchar()
        bl      getchar
        adr     x1, iChar
        str     w0, [x1]          // Store getchar() result in iChar

        // Check for EOF
        adr     x1, iChar
        ldr     w1, [x1]
        cmp     w1, #EOF
        beq     Loop_End          // Exit loop if EOF

        // Increment lCharCount
        adr     x1, lCharCount
        ldr     x2, [x1]
        add     x2, x2, #1
        str     x2, [x1]

        // Mask iChar for isspace
        adr     x1, iChar
        ldr     w1, [x1]
        mov     w0, w1
        and     w0, w0, #0xFF         // Mask to ensure valid range (0-255)
        bl      isspace
        cmp     w0, #0                // Check if iChar is a space
        beq     NotSpace

        // Handle end of word (if iInWord == TRUE)
        adr     x1, iInWord
        ldr     w2, [x1]
        cmp     w2, #TRUE
        beq     EndWord

        b       CheckNewline

EndWord:
        adr     x1, lWordCount
        ldr     x2, [x1]
        add     x2, x2, #1            // Increment word count
        str     x2, [x1]

        adr     x1, iInWord
        mov     w2, #FALSE
        str     w2, [x1]              // Set iInWord = FALSE

        b       CheckNewline

NotSpace:
        // Handle start of a new word (if iInWord == FALSE)
        adr     x1, iInWord
        ldr     w2, [x1]
        cmp     w2, #FALSE
        bne     CheckNewline          // Skip if already in a word

        adr     x1, iInWord
        mov     w2, #TRUE
        str     w2, [x1]              // Set iInWord = TRUE

CheckNewline:
        // Check if iChar is a newline
        adr     x1, iChar
        ldr     w2, [x1]
        cmp     w2, #NEWLINE
        bne     Loop_Start            // Continue if not newline

        adr     x1, lLineCount
        ldr     x2, [x1]
        add     x2, x2, #1            // Increment line count
        str     x2, [x1]

        b       Loop_Start

Loop_End:
        // Handle last word (if iInWord == TRUE)
        adr     x1, iInWord
        ldr     w2, [x1]
        cmp     w2, #TRUE
        beq     FinalWord

        b       PrintResults

FinalWord:
        adr     x1, lWordCount
        ldr     x2, [x1]
        add     x2, x2, #1            // Increment word count
        str     x2, [x1]

PrintResults:
        // Print results
        adr     x0, fmt_string
        ldr     x1, lLineCount
        ldr     x2, lWordCount
        ldr     x3, lCharCount
        bl      printf

        // Exit program
        mov     w0, #0
        ldp     x29, x30, [sp]
        add     sp, sp, #STACK_FRAME_SIZE
        ret
