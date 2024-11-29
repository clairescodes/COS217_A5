//---------------------------------------------------------------------
// bigintadd.s
// Author: Emily Qian and Claire Shin
//---------------------------------------------------------------------

        .section .rodata

//---------------------------------------------------------------------

        .section .data

        // In lieu of a boolean data type.
        .equ    TRUE, 1
        .equ    FALSE, 0

        // Structure field offsets for BigInt
        .equ    LLENGTH, 0            // Offset for lLength in BigInt
        .equ    AULDIGITS, 8          // Offset of aulDigits[0]

        // Constants
        .equ    MAX_DIGITS, 32768     // Maximum number of digits

//---------------------------------------------------------------------

        .section .bss

//---------------------------------------------------------------------

        .section .text
        //-------------------------------------------------------------
        // int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, 
        //     BigInt_T oSum)
        // Assign the sum of oAddend1 and oAddend2 to oSum.
        //-------------------------------------------------------------

        // Stack frame offsets
        .equ    CARRY, 16             // Carry variable
        .equ    INDEX, 24             // Index for iteration
        .equ    MAX_LENGTH, 32        // Maximum length of digits
        .equ    ADDEND1, 40           // oAddend1 length
        .equ    ADDEND2, 48           // oAddend2 length
        .equ    SUM, 56               // oSum length
        .equ    MAIN_STACK_BYTECOUNT, 64

        .global BigInt_add

BigInt_add:
        // Prolog
        sub     sp, sp, MAIN_STACK_BYTECOUNT
        str     x29, [sp, #48]
        str     x30, [sp, #56]
        mov     x29, sp

        // Initialize carry and index
        mov     x0, 0
        str     x0, [sp, CARRY]

        mov     x0, 0
        str     x0, [sp, INDEX]

        // Load lengths of oAddend1 and oAddend2
        ldr     x1, [x0, LLENGTH]
        str     x1, [sp, ADDEND1]
        ldr     x2, [x0, LLENGTH]
        str     x2, [sp, ADDEND2]

        // Determine maximum length
        ldr     x1, [sp, ADDEND1]
        ldr     x2, [sp, ADDEND2]
        cmp     x1, x2
        bgt     set_max_to_addend1
        mov     x3, x2
        b       set_max_done
set_max_to_addend1:
        mov     x3, x1
set_max_done:
        str     x3, [sp, MAX_LENGTH]

        // Check for overflow if max length > MAX_DIGITS
        ldr     x0, [sp, MAX_LENGTH]
        cmp     x0, MAX_DIGITS
        bge     overflow

addition_loop:
        // Load current index and check against max length
        ldr     x0, [sp, INDEX]
        ldr     x1, [sp, MAX_LENGTH]
        cmp     x0, x1
        bge     end_addition

        // Load digits from oAddend1 and oAddend2
        ldr     x2, [sp, ADDEND1]        // Base address of oAddend1
        add     x2, x2, x0, lsl #3       // Offset to the current digit
        ldr     x3, [x2]                 // Load digit at index
        ldr     x4, [sp, ADDEND2]        // Base address of oAddend2
        add     x4, x4, x0, lsl #3       // Offset to the current digit
        ldr     x5, [x4]                 // Load digit at index

        // Perform addition with carry
        ldr     x6, [sp, CARRY]          // Load current carry
        add     x7, x3, x5               // Add digits
        add     x7, x7, x6               // Add carry
        mov     x6, 0                    // Reset carry

        // Check for overflow and set carry if needed
        cmp     x7, x3
        bcc     no_carry
        mov     x6, TRUE
no_carry:
        str     x6, [sp, CARRY]          // Update carry

        // Store the sum in oSum
        ldr     x8, [sp, SUM]            // Base address of oSum
        add     x8, x8, x0, lsl #3       // Offset to the current digit
        str     x7, [x8]                 // Store result at index

        // Increment index
        ldr     x0, [sp, INDEX]
        add     x0, x0, 1
        str     x0, [sp, INDEX]

        // Repeat addition loop
        b       addition_loop

overflow:
        // Handle overflow case
        mov     w0, FALSE
        b       end_function

end_addition:
        // Set length of oSum
        ldr     x0, [sp, MAX_LENGTH]
        ldr     x1, [sp, SUM]
        str     x0, [x1, LLENGTH]

        // Return success
        mov     w0, TRUE

end_function:
        // Epilog
        ldr     x30, [sp, #56]
        ldr     x29, [sp, #48]
        add     sp, sp, MAIN_STACK_BYTECOUNT
        ret
        