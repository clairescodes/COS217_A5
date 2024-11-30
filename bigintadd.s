/* bigintadd.s */
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
    .equ    ULSUM, 16
    .equ    LINDEX, 24
    .equ    LSUMLENGTH, 32
    .equ    OADDEND1, 40
    .equ    OADDEND2, 48
    .equ    OSUM, 56

    /* Offsets for the structure */
    .equ    LLENGTH, 0
    .equ    AULDIGITS, 8

    .global BigInt_larger
    .global BigInt_add

/*--------------------------------------------------------------------*/
/* BigInt_larger function (returns larger of lLength1 and lLength2)   */
/*--------------------------------------------------------------------*/
BigInt_larger:
    // Prologue
    sub     sp, sp, BIGINTLARGER_STACK_BYTECOUNT  // Allocate stack space
    str     x30, [sp]                            // Save return address
    str     x0, [sp, LLENGTH1]                  // Store lLength1
    str     x1, [sp, LLENGTH2]                  // Store lLength2

    // Compare lLength1 and lLength2
    cmp     x0, x1
    ble     larger2                           // If lLength1 > lLength2, branch to larger1

    str     x0, [sp, LLARGER]                  // Load lLength2 into x0
    b       returnInt                           // Jump to return

larger2:
    // If lLength2 is larger
    str     x1, [sp, LLARGER]                  // Load lLength1 into x0

returnInt:
    // Return the result
    ldr     x0, [sp, LLARGER]
    ldr     x30, [sp]                           // Restore return address
    add     sp, sp, BIGINTLARGER_STACK_BYTECOUNT  // Free stack space
    ret

    .size BigInt_larger, . - BigInt_larger


/*--------------------------------------------------------------------*/
/* BigInt_add function: Adds two BigInt numbers and returns 1 (TRUE)   */
/* if the addition is successful, or 0 (FALSE) if overflow occurs.    */
/*--------------------------------------------------------------------*/
BigInt_add:
    // Prologue
    sub     sp, sp, BIGINTADD_STACK_BYTECOUNT      // Allocate stack space
    str     x30, [sp]                             // Save return address
    str     x0, [sp, OADDEND1]                    // Store oAddend1
    str     x1, [sp, OADDEND2]                    // Store oAddend2
    str     x2, [sp, OSUM]                        // Store oSum

    // Null checks
    ldr     x0, [sp, OADDEND1]                   // Load oAddend1
    cmp     x0, xzr                               // Check if oAddend1 is NULL
    beq     returnFalse                           // If it is NULL, return FALSE

    ldr     x0, [sp, OADDEND2]                   // Load oAddend2
    cmp     x0, xzr                               // Check if oAddend2 is NULL
    beq     returnFalse                           // If it is NULL, return FALSE

    ldr     x0, [sp, OSUM]                       // Load oSum
    cmp     x0, xzr                               // Check if oSum is NULL
    beq     returnFalse                           // If it is NULL, return FALSE

    // Determine the larger length (oAddend1->lLength vs oAddend2->lLength)
    ldr     x2, [sp, OADDEND1]                   // Load oAddend1
    ldr     x3, [x2, LLENGTH]                    // Load oAddend1->lLength
    ldr     x4, [sp, OADDEND2]                   // Load oAddend2
    ldr     x5, [x4, LLENGTH]                    // Load oAddend2->lLength
    cmp     x3, x5                               // Compare oAddend1->lLength with oAddend2->lLength
    csel    x6, x3, x5, gt                       // If oAddend1->lLength > oAddend2->lLength, select oAddend1->lLength, else select oAddend2->lLength
    str     x6, [sp, LSUMLENGTH]                 // Store the larger length in lSumLength

    // Clear oSum's array if necessary.
    ldr     x1, [sp, OSUM]                       // Load oSum
    ldr     x2, [x1, LLENGTH]                    // Load oSum->lLength
    ldr     x3, [sp, LSUMLENGTH]                 // Load lSumLength
    cmp     x2, x3                               // Compare oSum->lLength with lSumLength
    bgt     clearSumDigits                       // If oSum->lLength > lSumLength, clear digits

    b       performAddition                      // Otherwise, proceed with addition

clearSumDigits:
    // Clear the digits in oSum->aulDigits starting from lSumLength
    add     x4, x1, AULDIGITS                     // Load address of oSum->aulDigits
    add     x5, x4, x3, lsl #3                    // Calculate address starting from lSumLength * sizeof(unsigned long)
    ldr     x6, =0                                 // Load 0 to clear memory
    mov     x7, MAX_DIGITS                        // Set max digit count to clear
    sub     x7, x7, x3                             // Calculate how many digits need to be cleared
    lsr     x7, x7, #3                              // Divide x7 by 8 (to get the number of 64-bit digits to clear)
    add     x7, x7, x7                              // Double x7 (equivalent to multiplying by 8)
    bl      memset                                // Call memset to clear the memory

performAddition:
    // Initialize carry to 0
    mov     w8, 0                                  // ulCarry = 0
    str     w8, [sp, ULCARRY]

    // Addition loop
    ldr     x1, [sp, LSUMLENGTH]                 // Load lSumLength
    mov     x2, 0                                // lIndex = 0

whileLoop:
    cmp     x2, x1                               // Compare lIndex with lSumLength
    bge     endWhileLoop                        // If lIndex >= lSumLength, exit loop

    // Load current digits from oAddend1 and oAddend2
    ldr     x3, [sp, OADDEND1]
    add     x3, x3, x2, lsl #3                  // Add lIndex * sizeof(unsigned long)
    ldr     w3, [x3]                             // Load oAddend1->aulDigits[lIndex]
    
    ldr     x4, [sp, OADDEND2]
    add     x4, x4, x2, lsl #3                  // Add lIndex * sizeof(unsigned long)
    ldr     w4, [x4]                             // Load oAddend2->aulDigits[lIndex]

    ldr     w5, [sp, ULCARRY]                    // Load carry (ulCarry)
    add     w3, w3, w5                           // Add carry to sum of digits
    add     w4, w4, w3                           // Add the sum of digits

    // Check for overflow
    cmp     w4, w3                               // Check if overflow occurred
    mov     w5, 0                                // If no overflow, set carry to 0
    mov     w6, 1                                // If overflow, set carry to 1
    cset    w5, lo                               // Set carry accordingly
    str     w5, [sp, ULCARRY]                    // Store carry

    // Store result in oSum->aulDigits[lIndex]
    ldr     x6, [sp, OSUM]
    add     x6, x6, x2, lsl #3                  // Add lIndex * sizeof(unsigned long)
    str     w4, [x6]                             // Store sum in oSum->aulDigits[lIndex]

    add     x2, x2, 1                            // Increment lIndex
    b       whileLoop

endWhileLoop:
    // Final carry check
    ldr     w8, [sp, ULCARRY]
    cmp     w8, 1
    bne     setSumLength

carryOut:
    // Handle carry overflow
    ldr     x1, [sp, LSUMLENGTH]
    cmp     x1, MAX_DIGITS
    beq     returnFalse                          // If lSumLength == MAX_DIGITS, return FALSE
    
    ldr     x2, [sp, OSUM]
    
    // Set carry (1)
    mov     w3, 1                                // Set carry
    add     x3, x2, AULDIGITS                    // Calculate base address of next digit
    add     x3, x3, x1, lsl #3                   // Add lSumLength * sizeof(unsigned long)
    str     w3, [x3]                             // Store carry in the next digit

setSumLength:
    // Finalize the lSumLength in oSum->lLength
    ldr     x1, [sp, OSUM]
    ldr     x2, [sp, LSUMLENGTH]
    str     x2, [x1, LLENGTH]                    // Store lSumLength in oSum->lLength

returnTrue:
    mov     x0, 1
    b       endBigIntAdd

returnFalse:
    mov     x0, 0

endBigIntAdd:
    // Epilogue
    ldr     x30, [sp]                           // Restore return address
    add     sp, sp, BIGINTADD_STACK_BYTECOUNT   // Deallocate stack space
    ret                                          // Return from function
