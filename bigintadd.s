/* bigintadd.s */

/*--------------------------------------------------------------------*/
/* Constants and Offsets                                              */
/*--------------------------------------------------------------------*/

    .equ    MAX_DIGITS, 32768
    .equ    TRUE, 1
    .equ    FALSE, 0

    /* Stack frame byte count for BigInt_larger */
    .equ    BIGINTLARGER_STACK_BYTECOUNT, 32
    .equ    LLENGTH1, 8
    .equ    LLENGTH2, 16
    .equ    LLARGER, 24

    /* Stack frame byte count for BigInt_add */
    .equ    BIGINTADD_STACK_BYTECOUNT, 64
    .equ    ULCARRY, 8
    .equ    LINDEX, 16
    .equ    LSUMLENGTH, 24
    .equ    OADDEND1, 32
    .equ    OADDEND2, 40
    .equ    OSUM, 48

    /* Offsets within the BigInt_T structure */
    .equ    LLENGTH, 0
    .equ    AULDIGITS, 8

    .global BigInt_larger
    .global BigInt_add

/*--------------------------------------------------------------------*/
/* BigInt_larger: Returns the larger of lLength1 and lLength2         */
/*--------------------------------------------------------------------*/
BigInt_larger:
    // Prologue
    sub     sp, sp, BIGINTLARGER_STACK_BYTECOUNT      // Allocate stack space
    str     x30, [sp]                                 // Save return address
    str     x0, [sp, LLENGTH1]                        // Store lLength1
    str     x1, [sp, LLENGTH2]                        // Store lLength2

    // Compare lLength1 and lLength2
    ldr     x0, [sp, LLENGTH1]                        // Load lLength1
    ldr     x1, [sp, LLENGTH2]                        // Load lLength2
    cmp     x0, x1
    bgt     store_lLength1                            // If lLength1 > lLength2, branch

    // lLength2 is larger or equal
    str     x1, [sp, LLARGER]                         // lLarger = lLength2
    b       return_larger

store_lLength1:
    // lLength1 is larger
    str     x0, [sp, LLARGER]                         // lLarger = lLength1

return_larger:
    ldr     x0, [sp, LLARGER]                         // Return value in x0
    ldr     x30, [sp]                                 // Restore return address
    add     sp, sp, BIGINTLARGER_STACK_BYTECOUNT      // Deallocate stack space
    ret                                               // Return from function

    .size BigInt_larger, . - BigInt_larger

/*--------------------------------------------------------------------*/
/* BigInt_add: Adds two BigInt numbers                                */
/* Returns TRUE (1) if addition is successful, FALSE (0) if overflow  */
/*--------------------------------------------------------------------*/
BigInt_add:
    // Prologue
    sub     sp, sp, BIGINTADD_STACK_BYTECOUNT         // Allocate stack space
    str     x30, [sp]                                 // Save return address
    str     x0, [sp, OADDEND1]                        // Store oAddend1
    str     x1, [sp, OADDEND2]                        // Store oAddend2
    str     x2, [sp, OSUM]                            // Store oSum

    // Determine lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength)
    ldr     x0, [sp, OADDEND1]                        // Load oAddend1
    ldr     x0, [x0, LLENGTH]                         // x0 = oAddend1->lLength
    ldr     x1, [sp, OADDEND2]                        // Load oAddend2
    ldr     x1, [x1, LLENGTH]                         // x1 = oAddend2->lLength
    bl      BigInt_larger                             // Call BigInt_larger(x0, x1)
    str     x0, [sp, LSUMLENGTH]                      // Store lSumLength

    // Initialize ulCarry = 0 and lIndex = 0
    mov     x0, 0
    str     x0, [sp, ULCARRY]
    str     x0, [sp, LINDEX]

addition_loop:
    // lIndex < lSumLength?
    ldr     x0, [sp, LINDEX]
    ldr     x1, [sp, LSUMLENGTH]
    cmp     x0, x1
    bge     end_addition_loop

    // Load ulCarry
    ldr     x6, [sp, ULCARRY]                        // x6 = ulCarry
    mov     x7, 0
    str     x7, [sp, ULCARRY]                        // Reset ulCarry to 0

    // Load oAddend1->aulDigits[lIndex]
    ldr     x2, [sp, OADDEND1]
    add     x2, x2, AULDIGITS                        // x2 = &oAddend1->aulDigits
    ldr     x3, [sp, LINDEX]
    lsl     x3, x3, #3                               // x3 = lIndex * 8
    add     x2, x2, x3                               // x2 = &oAddend1->aulDigits[lIndex]
    ldr     x3, [x2]                                 // x3 = oAddend1->aulDigits[lIndex]

    // Add to ulSum
    add     x6, x6, x3                               // x6 = ulSum + oAddend1->aulDigits[lIndex]

    // Check for overflow after adding oAddend1
    cmp     x6, x3
    bge     no_overflow_addend1
    mov     x7, 1                                    // Set ulCarry to 1
    str     x7, [sp, ULCARRY]
no_overflow_addend1:

    // Load oAddend2->aulDigits[lIndex]
    ldr     x2, [sp, OADDEND2]
    add     x2, x2, AULDIGITS                        // x2 = &oAddend2->aulDigits
    ldr     x4, [sp, LINDEX]
    lsl     x4, x4, #3                               // x4 = lIndex * 8
    add     x2, x2, x4                               // x2 = &oAddend2->aulDigits[lIndex]
    ldr     x4, [x2]                                 // x4 = oAddend2->aulDigits[lIndex]

    // Add to ulSum
    add     x6, x6, x4                               // x6 = ulSum + oAddend2->aulDigits[lIndex]

    // Check for overflow after adding oAddend2
    cmp     x6, x4
    bge     no_overflow_addend2
    ldr     x7, [sp, ULCARRY]
    mov     x8, 1
    orr     x7, x7, x8                               // ulCarry |= 1
    str     x7, [sp, ULCARRY]
no_overflow_addend2:

    // Store ulSum in oSum->aulDigits[lIndex]
    ldr     x9, [sp, OSUM]
    add     x9, x9, AULDIGITS                        // x9 = &oSum->aulDigits
    ldr     x10, [sp, LINDEX]
    lsl     x10, x10, #3                             // x10 = lIndex * 8
    add     x9, x9, x10                              // x9 = &oSum->aulDigits[lIndex]
    str     x6, [x9]                                 // oSum->aulDigits[lIndex] = ulSum

    // Increment lIndex
    ldr     x0, [sp, LINDEX]
    add     x0, x0, 1
    str     x0, [sp, LINDEX]
    b       addition_loop

end_addition_loop:
    // Check if ulCarry == 1
    ldr     x7, [sp, ULCARRY]
    cmp     x7, 1
    bne     set_sum_length                            // If ulCarry != 1, skip adding extra digit

    // Handle carry overflow
    ldr     x0, [sp, LSUMLENGTH]
    mov     x1, MAX_DIGITS
    cmp     x0, x1
    beq     returnFalse                               // If lSumLength == MAX_DIGITS, return FALSE

    // oSum->aulDigits[lSumLength] = 1
    ldr     x9, [sp, OSUM]
    add     x9, x9, AULDIGITS                         // x9 = &oSum->aulDigits
    lsl     x10, x0, #3                               // x10 = lSumLength * 8
    add     x9, x9, x10                               // x9 = &oSum->aulDigits[lSumLength]
    mov     x6, 1
    str     x6, [x9]                                  // oSum->aulDigits[lSumLength] = 1

    // Increment lSumLength
    add     x0, x0, 1
    str     x0, [sp, LSUMLENGTH]

set_sum_length:
    // Set oSum->lLength = lSumLength
    ldr     x0, [sp, OSUM]
    ldr     x1, [sp, LSUMLENGTH]
    str     x1, [x0, LLENGTH]                         // oSum->lLength = lSumLength

    // Return TRUE
    mov     x0, TRUE
    b       end_BigInt_add

returnFalse:
    // Return FALSE
    mov     x0, FALSE

end_BigInt_add:
    // Epilogue
    ldr     x30, [sp]                                  // Restore return address
    add     sp, sp, BIGINTADD_STACK_BYTECOUNT          // Deallocate stack space
    ret                                                // Return from function

    .size BigInt_add, . - BigInt_add
