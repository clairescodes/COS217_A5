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
    sub     sp, sp, BIGINTLARGER_STACK_BYTECOUNT  // Allocate stack space
    stp     x29, x30, [sp, #16]                   // Save frame pointer and return address
    add     x29, sp, #16                          // Set up frame pointer
    str     x0, [sp, LLENGTH1]                    // Store lLength1
    str     x1, [sp, LLENGTH2]                    // Store lLength2

    // Load lLength1 and lLength2
    ldr     x0, [sp, LLENGTH1]
    ldr     x1, [sp, LLENGTH2]

    // Compare lLength1 and lLength2
    cmp     x0, x1
    bgt     larger1                               // If lLength1 > lLength2, branch to larger1

    // lLength2 is larger or equal
    str     x1, [sp, LLARGER]                     // lLarger = lLength2
    b       returnInt

larger1:
    // lLength1 is larger
    str     x0, [sp, LLARGER]                     // lLarger = lLength1

returnInt:
    // Return the result
    ldr     x0, [sp, LLARGER]
    // Epilogue
    ldp     x29, x30, [sp, #16]                   // Restore frame pointer and return address
    add     sp, sp, BIGINTLARGER_STACK_BYTECOUNT  // Deallocate stack space
    ret                                           // Return from function

    .size BigInt_larger, . - BigInt_larger

/*--------------------------------------------------------------------*/
/* BigInt_add: Adds two BigInt numbers                                */
/* Returns TRUE (1) if addition is successful, FALSE (0) if overflow  */
/*--------------------------------------------------------------------*/
BigInt_add:
    // Prologue
    sub     sp, sp, BIGINTADD_STACK_BYTECOUNT      // Allocate stack space
    stp     x29, x30, [sp, #16]                    // Save frame pointer and return address
    add     x29, sp, #16                           // Set up frame pointer
    str     x0, [sp, OADDEND1]                     // Store oAddend1
    str     x1, [sp, OADDEND2]                     // Store oAddend2
    str     x2, [sp, OSUM]                         // Store oSum

    // Determine lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength)
    ldr     x0, [sp, OADDEND1]                     // Load oAddend1
    ldr     x0, [x0, LLENGTH]                      // x0 = oAddend1->lLength
    ldr     x1, [sp, OADDEND2]                     // Load oAddend2
    ldr     x1, [x1, LLENGTH]                      // x1 = oAddend2->lLength
    bl      BigInt_larger                          // Call BigInt_larger(x0, x1)
    str     x0, [sp, LSUMLENGTH]                   // Store lSumLength

    // Initialize ulCarry = 0 and lIndex = 0
    mov     x0, 0
    str     x0, [sp, ULCARRY]
    str     x0, [sp, LINDEX]

additionLoop:
    // lIndex < lSumLength?
    ldr     x0, [sp, LINDEX]
    ldr     x1, [sp, LSUMLENGTH]
    cmp     x0, x1
    bge     endAdditionLoop

    // Load ulCarry
    ldr     x2, [sp, ULCARRY]
    mov     x3, x2                                // ulSum = ulCarry

    // Load oAddend1->aulDigits[lIndex]
    ldr     x4, [sp, OADDEND1]
    add     x4, x4, AULDIGITS                     // x4 = oAddend1->aulDigits
    ldr     x5, [sp, LINDEX]
    lsl     x5, x5, #3                            // x5 = lIndex * sizeof(unsigned long)
    add     x4, x4, x5                            // x4 = &oAddend1->aulDigits[lIndex]
    ldr     x5, [x4]                              // x5 = oAddend1->aulDigits[lIndex]

    // Add oAddend1->aulDigits[lIndex] to ulSum
    adds    x3, x3, x5                            // ulSum += oAddend1->aulDigits[lIndex]; sets flags
    cset    x6, cs                                // x6 = (carry from addition) ? 1 : 0

    // Load oAddend2->aulDigits[lIndex]
    ldr     x4, [sp, OADDEND2]
    add     x4, x4, AULDIGITS                     // x4 = oAddend2->aulDigits
    ldr     x5, [sp, LINDEX]
    lsl     x5, x5, #3                            // x5 = lIndex * sizeof(unsigned long)
    add     x4, x4, x5                            // x4 = &oAddend2->aulDigits[lIndex]
    ldr     x5, [x4]                              // x5 = oAddend2->aulDigits[lIndex]

    // Add oAddend2->aulDigits[lIndex] to ulSum
    adcs    x3, x3, x5                            // ulSum += oAddend2->aulDigits[lIndex]; sets flags
    cset    x7, cs                                // x7 = (carry from addition) ? 1 : 0

    // ulCarry = x6 | x7
    orr     x2, x6, x7
    str     x2, [sp, ULCARRY]                     // Store ulCarry

    // Store ulSum in oSum->aulDigits[lIndex]
    ldr     x4, [sp, OSUM]
    add     x4, x4, AULDIGITS                     // x4 = oSum->aulDigits
    ldr     x5, [sp, LINDEX]
    lsl     x5, x5, #3                            // x5 = lIndex * sizeof(unsigned long)
    add     x4, x4, x5                            // x4 = &oSum->aulDigits[lIndex]
    str     x3, [x4]                              // oSum->aulDigits[lIndex] = ulSum

    // Increment lIndex
    ldr     x0, [sp, LINDEX]
    add     x0, x0, 1
    str     x0, [sp, LINDEX]
    b       additionLoop

endAdditionLoop:
    // Check if ulCarry == 1
    ldr     x2, [sp, ULCARRY]
    cmp     x2, 1
    bne     setSumLength                          // If ulCarry != 1, proceed to setSumLength

    // ulCarry == 1, check for overflow
    ldr     x1, [sp, LSUMLENGTH]
    mov     x0, MAX_DIGITS
    cmp     x1, x0
    beq     returnFalse                           // If lSumLength == MAX_DIGITS, return FALSE

    // oSum->aulDigits[lSumLength] = 1
    ldr     x2, [sp, OSUM]
    add     x2, x2, AULDIGITS                     // x2 = oSum->aulDigits
    lsl     x3, x1, #3                            // x3 = lSumLength * sizeof(unsigned long)
    add     x2, x2, x3                            // x2 = &oSum->aulDigits[lSumLength]
    mov     x4, 1
    str     x4, [x2]                              // oSum->aulDigits[lSumLength] = 1

    // lSumLength++
    add     x1, x1, 1
    str     x1, [sp, LSUMLENGTH]

setSumLength:
    // oSum->lLength = lSumLength
    ldr     x0, [sp, OSUM]
    ldr     x1, [sp, LSUMLENGTH]
    str     x1, [x0, LLENGTH]                     // oSum->lLength = lSumLength

    // Return TRUE
    mov     x0, TRUE
    b       endBigIntAdd

returnFalse:
    // Return FALSE
    mov     x0, FALSE

endBigIntAdd:
    // Epilogue
    ldp     x29, x30, [sp, #16]                   // Restore frame pointer and return address
    add     sp, sp, BIGINTADD_STACK_BYTECOUNT     // Deallocate stack space
    ret                                           // Return from function

    .size BigInt_add, . - BigInt_add
