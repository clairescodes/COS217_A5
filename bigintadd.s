BigInt_add:
    /* Prologue */
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    sub     sp, sp, #48

    /* Store parameters on the stack */
    str     x0, [x29, OADDEND1]
    str     x1, [x29, OADDEND2]
    str     x2, [x29, OSUM]

    /* Determine lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength) */
    ldr     x0, [x29, OADDEND1]
    ldr     x0, [x0, LLENGTH]
    ldr     x1, [x29, OADDEND2]
    ldr     x1, [x1, LLENGTH]
    bl      BigInt_larger
    str     x0, [x29, LSUMLENGTH]

    /* Zero-initialize oSum->aulDigits up to lSumLength */
    ldr     x0, [x29, OSUM]
    add     x0, x0, AULDIGITS
    ldr     x1, [x29, LSUMLENGTH]
    mov     x2, 0
zero_init_loop:
    cbz     x1, zero_init_done
    str     x2, [x0], #8
    sub     x1, x1, 1
    b       zero_init_loop
zero_init_done:

    /* Initialize ulCarry = 0 and lIndex = 0 */
    mov     x0, 0
    str     x0, [x29, ULCARRY]
    str     x0, [x29, LINDEX]

addition_loop:
    /* Load lIndex and lSumLength */
    ldr     x0, [x29, LINDEX]
    ldr     x1, [x29, LSUMLENGTH]

    /* Compare lIndex and lSumLength */
    cmp     x0, x1
    bhs     end_addition_loop        // Unsigned comparison

    /* Load ulCarry */
    ldr     x2, [x29, ULCARRY]

    /* Initialize ulAddend1 and ulAddend2 to zero */
    mov     x3, 0
    mov     x5, 0

    /* Load oAddend1->lLength and oAddend2->lLength */
    ldr     x10, [x29, OADDEND1]
    ldr     x11, [x10, LLENGTH]
    ldr     x13, [x29, OADDEND2]
    ldr     x14, [x13, LLENGTH]

    /* Check if lIndex < oAddend1->lLength */
    cmp     x0, x11
    bhs     skip_load_addend1        // Unsigned comparison
    /* Load oAddend1->aulDigits[lIndex] */
    add     x12, x10, AULDIGITS
    lsl     x15, x0, #3
    ldr     x3, [x12, x15]
skip_load_addend1:

    /* Check if lIndex < oAddend2->lLength */
    cmp     x0, x14
    bhs     skip_load_addend2        // Unsigned comparison
    /* Load oAddend2->aulDigits[lIndex] */
    add     x16, x13, AULDIGITS
    lsl     x17, x0, #3
    ldr     x5, [x16, x17]
skip_load_addend2:

    /* Compute ulSum = ulAddend1 + ulAddend2 */
    adds    x6, x3, x5                 // x6 = ulAddend1 + ulAddend2
    /* Add ulCarry */
    adc     x6, x6, x2                 // x6 = x6 + ulCarry + previous carry
    /* Update ulCarry */
    cset    x7, cs                     // x7 = (carry flag is set) ? 1 : 0
    str     x7, [x29, ULCARRY]

    /* Store ulSum in oSum->aulDigits[lIndex] */
    ldr     x8, [x29, OSUM]
    add     x9, x8, AULDIGITS
    lsl     x18, x0, #3
    str     x6, [x9, x18]

    /* Increment lIndex */
    add     x0, x0, 1
    str     x0, [x29, LINDEX]
    b       addition_loop

end_addition_loop:
    /* Load ulCarry */
    ldr     x7, [x29, ULCARRY]
    cbz     x7, set_sum_length        // If ulCarry == 0, skip adding extra digit

    /* Load lSumLength */
    ldr     x0, [x29, LSUMLENGTH]
    mov     x1, MAX_DIGITS
    sub     x1, x1, 1                 // x1 = MAX_DIGITS - 1
    cmp     x0, x1
    bhi     returnFalse               // Unsigned comparison

    /* oSum->aulDigits[lSumLength] = 1 */
    ldr     x8, [x29, OSUM]
    add     x8, x8, AULDIGITS
    lsl     x9, x0, #3
    str     x7, [x8, x9]

    /* Increment lSumLength */
    add     x0, x0, 1
    str     x0, [x29, LSUMLENGTH]

set_sum_length:
    /* oSum->lLength = lSumLength */
    ldr     x0, [x29, OSUM]
    ldr     x1, [x29, LSUMLENGTH]
    str     x1, [x0, LLENGTH]

    /* Return TRUE */
    mov     x0, TRUE

end_BigInt_add:
    /* Epilogue */
    add     sp, sp, #48
    ldp     x29, x30, [sp], #16
    ret

returnFalse:
    /* Return FALSE */
    mov     x0, FALSE
    b       end_BigInt_add
