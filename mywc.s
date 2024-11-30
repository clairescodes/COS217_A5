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
        .equ STACK_FRAME_SIZE, 64 // Stack frame size (aligned to 16 bytes)

        .global main

main:
        // Prologue: Adjust stack and save registers
        sub     sp, sp, #STACK_FRAME_SIZE
        stp     x29, x30, [sp, #STACK_FRAME_SIZE - 16]  // Save x29 (fp) and x30 (lr)
        stp     x19, x20, [sp, #STACK_FRAME_SIZE - 32]  // Save x19 and x20
        stp     x21, x22, [sp, #STACK_FRAME_SIZE - 48]  // Save x21 and x22
        str     x23, [sp, #STACK_FRAME_SIZE - 56]       // Save x23
        mov     x29, sp

        // Load addresses of global variables into non-volatile registers
        adr     x19, iChar          // x19 = &iChar
        adr     x20, iInWord        // x20 = &iInWord
        adr     x21, lCharCount     // x21 = &lCharCount
        adr     x22, lLineCount     // x22 = &lLineCount
        adr     x23, lWordCount     // x23 = &lWordCount

        // Initialize lLineCount, lWordCount, lCharCount to 0
        mov     x2, #0
        str     x2, [x22]           // lLineCount = 0
        str     x2, [x23]           // lWordCount = 0
        str     x2, [x21]           // lCharCount = 0

        // Initialize iInWord to FALSE
        mov     w2, #FALSE
        str     w2, [x20]           // iInWord = FALSE

Loop_Start:
        // Read a character: iChar = getchar()
        bl      getchar
        str     w0, [x19]          // Store getchar() result in iChar

        // Check for EOF
        ldr     w1, [x19]          // Load iChar into w1
        cmp     w1, #EOF
        beq     Loop_End           // Exit loop if EOF

        // Increment lCharCount
        ldr     x2, [x21]          // Load lCharCount into x2
        add     x2, x2, #1
        str     x2, [x21]

        // Prepare argument for isspace
        ldr     w1, [x19]          // Load iChar into w1
        and     w1, w1, #0xFF      // Mask to lower 8 bits
        uxtb    w0, w1             // Zero-extend byte to w0
        bl      isspace
        cmp     w0, #0             // Check if result is zero
        beq     NotSpace

        // Handle end of word (if iInWord == TRUE)
        ldr     w2, [x20]          // Load iInWord
        cmp     w2, #TRUE
        beq     EndWord

        b       CheckNewline

EndWord:
        // Increment word count
        ldr     x2, [x23]          // Load lWordCount
        add     x2, x2, #1
        str     x2, [x23]          // Store back

        // Set iInWord to FALSE
        mov     w2, #FALSE
        str     w2, [x20]
        b       CheckNewline

NotSpace:
        // Check if not already in a word
        ldr     w2, [x20]          // Load iInWord
        cmp     w2, #FALSE
        bne     CheckNewline

        // Set iInWord to TRUE
        mov     w2, #TRUE
        str     w2, [x20]

CheckNewline:
        // Check for newline character
        ldr     w2, [x19]          // Load iChar
        cmp     w2, #NEWLINE
        bne     Loop_Start

        // Increment line count
        ldr     x2, [x22]          // Load lLineCount
        add     x2, x2, #1
        str     x2, [x22]

        b       Loop_Start

Loop_End:
        // Check if still in a word at EOF
        ldr     w2, [x20]          // Load iInWord
        cmp     w2, #TRUE
        beq     FinalWord

        b       PrintResults

FinalWord:
        // Increment word count for the last word
        ldr     x2, [x23]          // Load lWordCount
        add     x2, x2, #1
        str     x2, [x23]

PrintResults:
        // Prepare arguments for printf
        adr     x0, fmt_string     // Format string
        ldr     x1, [x22]          // lLineCount
        ldr     x2, [x23]          // lWordCount
        ldr     x3, [x21]          // lCharCount
        bl      printf

        // Return from main
        mov     w0, #0

        // Epilogue: Restore registers and stack
        ldr     x23, [sp, #STACK_FRAME_SIZE - 56]       // Restore x23
        ldp     x21, x22, [sp, #STACK_FRAME_SIZE - 48]  // Restore x21 and x22
        ldp     x19, x20, [sp, #STACK_FRAME_SIZE - 32]  // Restore x19 and x20
        ldp     x29, x30, [sp, #STACK_FRAME_SIZE - 16]  // Restore x29 and x30
        add     sp, sp, #STACK_FRAME_SIZE
        ret
