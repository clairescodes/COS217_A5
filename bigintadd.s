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
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    sub     sp, sp, #48

    /* Store parameters on the stack */
    str     x0, [x29, OADDEND1]
    str     x1, [x29, OADDEND2]
    str     x2, [x29, OSUM]

    /* Zero-initialize oSum->aulDigits */
    ldr     x0, [x29, OSUM]            // Load oSum
    add     x0, x0, AULDIGITS          // x0 = &oSum->aulDigits
    mov     x1, MAX_DIGITS             // x1 = MAX_DIGITS
    mov     x2, 0                      // x2 = 0 (value to store)
zero_init_loop:
    cbz     x1, zero_init_done         // If x1 == 0, exit loop
    str     x2, [x0], #8               // Store 0 and increment pointer by 8
    sub     x1, x1, 1                  // Decrement counter
    b       zero_init_loop
zero_init_done:

    /* Determine lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength) */
    ldr     x0, [x29, OADDEND1]
    ldr     x0, [x0, LLENGTH]
    ldr     x1, [x29, OADDEND2]
    ldr     x1, [x1, LLENGTH]
    bl      BigInt_larger
    str     x0, [x29, LSUMLENGTH]

    /* Initialize lIndex = 0 */
    mov     x0, 0
    str     x0, [x29, LINDEX]

addition_loop:
    /* lIndex < lSumLength? */
    ldr     x0, [x29, LINDEX]
    ldr     x1, [x29, LSUMLENGTH]
    cmp     x0, x1
    bge     end_addition_loop

    /* Load ulCarry and reset it to 0 */
    ldr     x2, [x29, ULCARRY]         // x2 = ulCarry
    mov     x7, 0                      // Reset ulCarry to 0
    str     x7, [x29, ULCARRY]

    /* ulSum = ulCarry */
    mov     x6, x2                     // x6 = ulSum = ulCarry

    /* Load oAddend1->aulDigits[lIndex] */
    ldr     x3, [x29, OADDEND1]
    add     x3, x3, AULDIGITS
    ldr     x4, [x29, LINDEX]
    lsl     x4, x4, #3
    add     x3, x3, x4
    ldr     x3, [x3]

    /* Add oAddend1->aulDigits[lIndex] to ulSum */
    adds    x6, x6, x3
    /* Update ulCarry if overflow occurred */
    cset    x7, cs                     // x7 = carry from first addition

    /* Load oAddend2->aulDigits[lIndex] */
    ldr     x5, [x29, OADDEND2]
    add     x5, x5, AULDIGITS
    ldr     x4, [x29, LINDEX]
    lsl     x4, x4, #3
    add     x5, x5, x4
    ldr     x5, [x5]

    /* Add oAddend2->aulDigits[lIndex] to ulSum */
    adds    x6, x6, x5
    /* Update ulCarry if overflow occurred */
    cset    x8, cs                     // x8 = carry from second addition

    /* Combine ulCarry from both additions */
    orr     x7, x7, x8                 // ulCarry |= x8
    str     x7, [x29, ULCARRY]         // Store updated ulCarry

    /* Store ulSum in oSum->aulDigits[lIndex] */
    ldr     x8, [x29, OSUM]
    add     x8, x8, AULDIGITS
    ldr     x9, [x29, LINDEX]
    lsl     x9, x9, #3
    add     x8, x8, x9
    str     x6, [x8]

    /* Increment lIndex */
    ldr     x0, [x29, LINDEX]
    add     x0, x0, 1
    str     x0, [x29, LINDEX]
    b       addition_loop

end_addition_loop:
    /* Check if ulCarry == 1 */
    ldr     x7, [x29, ULCARRY]
    cbz     x7, set_sum_length         // If ulCarry == 0, skip adding extra digit

    /* Handle carry overflow */
    ldr     x0, [x29, LSUMLENGTH]      // x0 = lSumLength
    mov     x1, MAX_DIGITS
    cmp     x0, x1
    bge     returnFalse                // If lSumLength >= MAX_DIGITS, return FALSE

    /* oSum->aulDigits[lSumLength] = 1 */
    ldr     x8, [x29, OSUM]
    add     x8, x8, AULDIGITS
    lsl     x9, x0, #3
    add     x8, x8, x9
    str     x7, [x8]                   // oSum->aulDigits[lSumLength] = 1

    /* Increment lSumLength */
    add     x0, x0, 1
    str     x0, [x29, LSUMLENGTH]

set_sum_length:
    /* Set oSum->lLength = lSumLength */
    ldr     x0, [x29, OSUM]
    ldr     x1, [x29, LSUMLENGTH]
    str     x1, [x0, LLENGTH]

    /* Return TRUE */
    mov     x0, TRUE
    b       end_BigInt_add

returnFalse:
    /* Return FALSE */
    mov     x0, FALSE

end_BigInt_add:
    /* Epilogue */
    add     sp, sp, #48
    ldp     x29, x30, [sp], #16
    ret

.size BigInt_add, . - BigInt_add
