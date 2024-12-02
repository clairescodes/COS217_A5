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

    /* Allocate stack space for local variables (none needed here) */

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

    /* Ensure OSUM's aulDigits is cleared */
    ldr     x0, [x29, OSUM]            // Load OSUM
    mov     x1, MAX_DIGITS             // Initialize loop counter
clear_osum_loop:
    add     x2, x0, AULDIGITS          // x2 = address of OSUM->aulDigits
    str     xzr, [x2], #8              // Clear 8 bytes (set to zero)
    subs    x1, x1, #1                 // Decrement counter
    bne     clear_osum_loop            // Repeat if not zero

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
    ldr     x6, [x29, ULCARRY]         // x6 = ulCarry
    mov     x7, 0
    str     x7, [x29, ULCARRY]         // Reset ulCarry to 0

    /* Load oAddend1->aulDigits[lIndex] */
    ldr     x2, [x29, OADDEND1]
    add     x2, x2, AULDIGITS          // x2 = &oAddend1->aulDigits
    ldr     x3, [x29, LINDEX]
    lsl     x3, x3, #3                 // x3 = lIndex * 8
    add     x2, x2, x3                 // x2 = &oAddend1->aulDigits[lIndex]
    ldr     x3, [x2]                   // x3 = oAddend1->aulDigits[lIndex]

    /* Add to ulSum */
    add     x6, x6, x3                 // x6 = ulSum + oAddend1->aulDigits[lIndex]

    /* Check for overflow after adding oAddend1 */
    cmp     x6, x3
    bcs     no_overflow_addend1        // If x6 >= x3, no overflow
    mov     x7, 1                      // Set ulCarry to 1
    str     x7, [x29, ULCARRY]
no_overflow_addend1:

    /* Load oAddend2->aulDigits[lIndex] */
    ldr     x2, [x29, OADDEND2]
    add     x2, x2, AULDIGITS          // x2 = &oAddend2->aulDigits
    ldr     x4, [x29, LINDEX]
    lsl     x4, x4, #3                 // x4 = lIndex * 8
    add     x2, x2, x4                 // x2 = &oAddend2->aulDigits[lIndex]
    ldr     x4, [x2]                   // x4 = oAddend2->aulDigits[lIndex]

    /* Add to ulSum */
    add     x6, x6, x4                 // x6 = ulSum + oAddend2->aulDigits[lIndex]

    /* Check for overflow after adding oAddend2 */
    cmp     x6, x4
    bcs     no_overflow_addend2        // If x6 >= x4, no overflow
    ldr     x7, [x29, ULCARRY]
    mov     x8, 1
    orr     x7, x7, x8                 // ulCarry |= 1
    str     x7, [x29, ULCARRY]
no_overflow_addend2:

    /* Store ulSum in oSum->aulDigits[lIndex] */
    ldr     x9, [x29, OSUM]
    add     x9, x9, AULDIGITS          // x9 = &oSum->aulDigits
    ldr     x10, [x29, LINDEX]
    lsl     x10, x10, #3               // x10 = lIndex * 8
    add     x9, x9, x10                // x9 = &oSum->aulDigits[lIndex]
    str     x6, [x9]                   // oSum->aulDigits[lIndex] = ulSum

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
    ldr     x0, [x29, LSUMLENGTH]
    mov     x1, MAX_DIGITS
    cmp     x0, x1
    beq     returnFalse                // If lSumLength == MAX_DIGITS, return FALSE

    /* oSum->aulDigits[lSumLength] = 1 */
    ldr     x9, [x29, OSUM]
    add     x9, x9, AULDIGITS          // x9 = &oSum->aulDigits
    lsl     x10, x0, #3                // x10 = lSumLength * 8
    add     x9, x9, x10                // x9 = &oSum->aulDigits[lSumLength]
    mov     x6, 1
    str     x6, [x9]                   // oSum->aulDigits[lSumLength] = 1

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
