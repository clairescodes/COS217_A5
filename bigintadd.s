/* bigintadd.s */

/*--------------------------------------------------------------------*/
/* Constants and Offsets                                              */
/*--------------------------------------------------------------------*/

    .equ    MAX_DIGITS, 32768
    .equ    TRUE, 1
    .equ    FALSE, 0

    /* Offsets relative to x29 (frame pointer) */
    /* Local variables and parameters stored at negative offsets */
    .equ    ULCARRY, -8           // unsigned long ulCarry;
    .equ    LINDEX, -16           // long lIndex;
    .equ    LSUMLENGTH, -24       // long lSumLength;
    .equ    OADDEND1, -32         // BigInt_T oAddend1;
    .equ    OADDEND2, -40         // BigInt_T oAddend2;
    .equ    OSUM, -48             // BigInt_T oSum;
    /* Total frame size: 48 bytes (must be multiple of 16) */

    /* Offsets within the BigInt_T structure */
    .equ    LLENGTH, 0            // Offset of lLength in BigInt_T
    .equ    AULDIGITS, 8          // Offset of aulDigits in BigInt_T

    .global BigInt_larger
    .global BigInt_add

/*--------------------------------------------------------------------*/
/* BigInt_larger: Returns the larger of lLength1 and lLength2         */
/*--------------------------------------------------------------------*/
BigInt_larger:
    /* Prologue */
    stp     x29, x30, [sp, #-16]!      // Save x29 and x30, adjust sp
    mov     x29, sp                    // Set frame pointer

    /* Compare lLength1 and lLength2 */
    cmp     x0, x1
    bgt     larger_lLength1            // If lLength1 > lLength2, branch

    /* lLength2 is larger or equal */
    mov     x0, x1                     // Return lLength2
    b       return_larger

larger_lLength1:
    /* lLength1 is larger */
    /* x0 already contains lLength1 */

return_larger:
    /* Epilogue */
    ldp     x29, x30, [sp], #16        // Restore x29 and x30, adjust sp
    ret                                 // Return from function

    .size BigInt_larger, . - BigInt_larger

/*--------------------------------------------------------------------*/
/* BigInt_add: Adds two BigInt numbers                                */
/* Returns TRUE (1) if addition is successful, FALSE (0) if overflow  */
/*--------------------------------------------------------------------*/
BigInt_add:
    /* Prologue */
    stp     x29, x30, [sp, #-16]!      // Save x29 and x30, adjust sp
    mov     x29, sp                    // Set frame pointer
    sub     sp, sp, #48                // Allocate space for local variables (48 bytes)

    /* Store parameters on the stack */
    str     x0, [x29, OADDEND1]        // Store oAddend1
    str     x1, [x29, OADDEND2]        // Store oAddend2
    str     x2, [x29, OSUM]            // Store oSum

    /* Determine lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength) */
    ldr     x0, [x29, OADDEND1]        // Load oAddend1
    ldr     x0, [x0, LLENGTH]          // x0 = oAddend1->lLength
    ldr     x1, [x29, OADDEND2]        // Load oAddend2
    ldr     x1, [x1, LLENGTH]          // x1 = oAddend2->lLength
    bl      BigInt_larger              // Call BigInt_larger(x0, x1)
    str     x0, [x29, LSUMLENGTH]      // Store lSumLength

    /* Initialize ulCarry = 0 and lIndex = 0 */
    mov     x0, 0                      // Reset carry and index
    str     x0, [x29, ULCARRY]
    str     x0, [x29, LINDEX]

addition_loop:
    /* lIndex < lSumLength? */
    ldr     x0, [x29, LINDEX]
    ldr     x1, [x29, LSUMLENGTH]
    cmp     x0, x1
    bge     end_addition_loop

    /* Load ulCarry */
    ldr     x2, [x29, ULCARRY]         // x2 = ulCarry

    /* Prepare x0 = lIndex */
    ldr     x0, [x29, LINDEX]

    /* Initialize x3 and x5 to 0 */
    mov     x3, 0                      // x3 = 0 (oAddend1 digit)
    mov     x5, 0                      // x5 = 0 (oAddend2 digit)

    /* Load oAddend1->lLength */
    ldr     x10, [x29, OADDEND1]
    ldr     x11, [x10, LLENGTH]        // x11 = oAddend1->lLength

    /* Check if lIndex < oAddend1->lLength */
    cmp     x0, x11
    bge     skip_load_addend1
    /* Load oAddend1->aulDigits[lIndex] */
    add     x10, x10, AULDIGITS        // x10 = &oAddend1->aulDigits
    lsl     x12, x0, #3                // x12 = lIndex * 8
    add     x10, x10, x12              // x10 = &oAddend1->aulDigits[lIndex]
    ldr     x3, [x10]                  // x3 = oAddend1->aulDigits[lIndex]
skip_load_addend1:

    /* Add ulCarry and oAddend1->aulDigits[lIndex] */
    adds    x6, x2, x3                 // x6 = ulCarry + oAddend1 digit; updates flags

    /* Load oAddend2->lLength */
    ldr     x13, [x29, OADDEND2]
    ldr     x14, [x13, LLENGTH]        // x14 = oAddend2->lLength

    /* Check if lIndex < oAddend2->lLength */
    cmp     x0, x14
    bge     skip_load_addend2
    /* Load oAddend2->aulDigits[lIndex] */
    add     x13, x13, AULDIGITS        // x13 = &oAddend2->aulDigits
    lsl     x15, x0, #3                // x15 = lIndex * 8
    add     x13, x13, x15              // x13 = &oAddend2->aulDigits[lIndex]
    ldr     x5, [x13]                  // x5 = oAddend2->aulDigits[lIndex]
skip_load_addend2:

    /* Add oAddend2->aulDigits[lIndex] with carry */
    adcs    x6, x6, x5                 // x6 = x6 + oAddend2 digit + carry; updates flags

    /* Update ulCarry based on the carry flag */
    cset    x7, cs                     // x7 = (carry flag is set) ? 1 : 0
    str     x7, [x29, ULCARRY]         // Store updated ulCarry

    /* Store ulSum in oSum->aulDigits[lIndex] */
    ldr     x8, [x29, OSUM]            // x8 = oSum
    add     x8, x8, AULDIGITS          // x8 = &oSum->aulDigits
    lsl     x9, x0, #3                 // x9 = lIndex * 8
    add     x8, x8, x9                 // x8 = &oSum->aulDigits[lIndex]
    str     x6, [x8]                   // oSum->aulDigits[lIndex] = ulSum

    /* Increment lIndex */
    ldr     x0, [x29, LINDEX]
    add     x0, x0, 1
    str     x0, [x29, LINDEX]
    b       addition_loop

end_addition_loop:
    /* Check if ulCarry == 1 */
    ldr     x7, [x29, ULCARRY]
    cmp     x7, 1
    bne     set_sum_length             // If ulCarry != 1, skip adding extra digit

    /* Handle carry overflow */
    ldr     x0, [x29, LSUMLENGTH]      // x0 = lSumLength
    mov     x1, MAX_DIGITS
    cmp     x0, x1
    bge     returnFalse                // If lSumLength >= MAX_DIGITS, return FALSE

    /* oSum->aulDigits[lSumLength] = 1 */
    ldr     x8, [x29, OSUM]            // x8 = oSum
    add     x8, x8, AULDIGITS          // x8 = &oSum->aulDigits
    lsl     x9, x0, #3                 // x9 = lSumLength * 8
    add     x8, x8, x9                 // x8 = &oSum->aulDigits[lSumLength]
    mov     x6, 1
    str     x6, [x8]                   // oSum->aulDigits[lSumLength] = 1

    /* Increment lSumLength */
    add     x0, x0, 1
    str     x0, [x29, LSUMLENGTH]

set_sum_length:
    /* Set oSum->lLength = lSumLength */
    ldr     x0, [x29, OSUM]
    ldr     x1, [x29, LSUMLENGTH]
    str     x1, [x0, LLENGTH]          // oSum->lLength = lSumLength

    /* Return TRUE */
    mov     x0, TRUE
    b       end_BigInt_add

returnFalse:
    /* Return FALSE */
    mov     x0, FALSE

end_BigInt_add:
    /* Epilogue */
    add     sp, sp, #48                // Deallocate local variables
    ldp     x29, x30, [sp], #16        // Restore x29 and x30, adjust sp
    ret                                 // Return from function

    .size BigInt_add, . - BigInt_add
