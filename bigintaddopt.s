/* bigintaddopt.s */

/*--------------------------------------------------------------------*/
/* Constants and Offsets                                              */
/*--------------------------------------------------------------------*/

    .equ    MAX_DIGITS, 32768
    .equ    TRUE, 1
    .equ    FALSE, 0
    .equ    LLENGTH, 0            // Offset of lLength in BigInt_T
    .equ    AULDIGITS, 8          // Offset of aulDigits in BigInt_T

    .global BigInt_larger
    .global BigInt_add

/*--------------------------------------------------------------------*/
/* BigInt_larger: Returns the larger of lLength1 and lLength2         */
/*--------------------------------------------------------------------*/

/* Register aliases */
LLENGTH1    .req    x19
LLENGTH2    .req    x20

BigInt_larger:
    /* Prologue */
    stp     x29, x30, [sp, #-16]!      // Save x29 and x30
    stp     LLENGTH1, LLENGTH2, [sp, #-16]! // Save callee-saved registers
    mov     x29, sp                    // Set frame pointer

    /* Move parameters into registers */
    mov     LLENGTH1, x0
    mov     LLENGTH2, x1

    /* Compare lLength1 and lLength2 */
    cmp     LLENGTH1, LLENGTH2
    bgt     larger_lLength1            // If lLength1 > lLength2, branch

    /* lLength2 is larger or equal */
    mov     x0, LLENGTH2               // Return lLength2
    b       return_larger

larger_lLength1:
    mov     x0, LLENGTH1               // Return lLength1

return_larger:
    /* Epilogue */
    ldp     LLENGTH1, LLENGTH2, [sp], #16 // Restore callee-saved registers
    ldp     x29, x30, [sp], #16        // Restore x29 and x30
    ret                                // Return from function

    .size BigInt_larger, . - BigInt_larger

/*--------------------------------------------------------------------*/
/* BigInt_add: Adds two BigInt numbers                                */
/* Returns TRUE (1) if addition is successful, FALSE (0) if overflow  */
/*--------------------------------------------------------------------*/

/* Register aliases */
OADDEND1    .req    x19
OADDEND2    .req    x20
OSUM        .req    x21
ULCARRY     .req    x22
LINDEX      .req    x23
LSUMLENGTH  .req    x24

BigInt_add:
    /* Prologue */
    stp     x29, x30, [sp, #-16]!      // Save x29 and x30
    stp     OADDEND1, OADDEND2, [sp, #-16]! // Save callee-saved registers
    stp     OSUM, ULCARRY, [sp, #-16]!
    stp     LINDEX, LSUMLENGTH, [sp, #-16]!
    mov     x29, sp                    // Set frame pointer

    /* Move parameters into registers */
    mov     OADDEND1, x0
    mov     OADDEND2, x1
    mov     OSUM, x2

    /* Zero-initialize oSum->aulDigits */
    add     x0, OSUM, AULDIGITS        // x0 = &oSum->aulDigits
    mov     x1, MAX_DIGITS             // x1 = MAX_DIGITS
    mov     x2, 0                      // x2 = 0 (value to store)
zero_init_loop:
    cbz     x1, zero_init_done         // If x1 == 0, exit loop
    str     x2, [x0], #8               // Store 0 and increment pointer by 8
    sub     x1, x1, 1                  // Decrement counter
    b       zero_init_loop
zero_init_done:

    /* Determine lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength) */
    ldr     x0, [OADDEND1, LLENGTH]    // x0 = oAddend1->lLength
    ldr     x1, [OADDEND2, LLENGTH]    // x1 = oAddend2->lLength
    bl      BigInt_larger              // Call BigInt_larger(x0, x1)
    mov     LSUMLENGTH, x0             // Store lSumLength

    /* Initialize ulCarry = 0 and lIndex = 0 */
    mov     ULCARRY, 0
    mov     LINDEX, 0

addition_loop:
    /* lIndex < lSumLength? */
    cmp     LINDEX, LSUMLENGTH
    bge     end_addition_loop

    /* Add with carry */
    ldr     x3, [OADDEND1, AULDIGITS + LINDEX, LSL #3] // Load oAddend1->aulDigits[lIndex]
    ldr     x4, [OADDEND2, AULDIGITS + LINDEX, LSL #3] // Load oAddend2->aulDigits[lIndex]
    adds    x6, ULCARRY, x3            // Add ulCarry + oAddend1->aulDigits[lIndex]
    adcs    x6, x6, x4                 // Add oAddend2->aulDigits[lIndex] + carry
    cset    ULCARRY, cs                // Update carry flag

    /* Store ulSum in oSum->aulDigits[lIndex] */
    str     x6, [OSUM, AULDIGITS + LINDEX, LSL #3]

    /* Increment lIndex */
    add     LINDEX, LINDEX, 1
    b       addition_loop

end_addition_loop:
    /* Check if ulCarry == 1 */
    cbz     ULCARRY, set_sum_length    // Skip if ulCarry == 0

    /* Handle carry overflow */
    cmp     LSUMLENGTH, MAX_DIGITS - 1
    bgt     returnFalse                // If lSumLength > MAX_DIGITS - 1, return FALSE

    /* oSum->aulDigits[lSumLength] = 1 */
    add     x8, OSUM, AULDIGITS        // x8 = &oSum->aulDigits
    add     x8, x8, LSUMLENGTH, LSL #3 // x8 = &oSum->aulDigits[lSumLength]
    mov     x6, 1
    str     x6, [x8]                   // oSum->aulDigits[lSumLength] = 1

    /* Increment lSumLength */
    add     LSUMLENGTH, LSUMLENGTH, 1

set_sum_length:
    /* Set oSum->lLength = lSumLength */
    str     LSUMLENGTH, [OSUM, LLENGTH]

    /* Return TRUE */
    mov     x0, TRUE
    b       end_BigInt_add

returnFalse:
    /* Return FALSE */
    mov     x0, FALSE

end_BigInt_add:
    /* Epilogue */
    ldp     LINDEX, LSUMLENGTH, [sp], #16 // Restore callee-saved registers
    ldp     OSUM, ULCARRY, [sp], #16
    ldp     OADDEND1, OADDEND2, [sp], #16
    ldp     x29, x30, [sp], #16        // Restore x29 and x30
    ret                                // Return from function
