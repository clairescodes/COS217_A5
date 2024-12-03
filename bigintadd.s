//----------------------------------------------------------------------
// bigintadd.s
// Author: Claire Shin and Emily Qian
// Description: Implementation of BigInt_larger and BigInt_add in ARMv8
//----------------------------------------------------------------------

        .section .bss

// Variables for BigInt_larger
lLength1:
        .skip   8
lLength2:
        .skip   8
lLarger:
        .skip   8

// Variables for BigInt_add
ulCarry:
        .skip   8
lSumLength:
        .skip   8
lIndex:
        .skip   8
ulSum:
        .skip   8

//----------------------------------------------------------------------
// Offsets within the BigInt_T structure
//----------------------------------------------------------------------

        .equ    LLENGTH, 0
        .equ    AULDIGITS, 8
        .equ    MAX_DIGITS, 32768
        .equ    TRUE, 1
        .equ    FALSE, 0

//----------------------------------------------------------------------
// BigInt_larger
//----------------------------------------------------------------------

        .global BigInt_larger

BigInt_larger:
        // Prolog
        sub     sp, sp, #16
        str     x30, [sp]

        // Store parameters in bss
        adr     x1, lLength1
        str     x0, [x1]              // lLength1 = x0
        adr     x1, lLength2
        str     x1, [x1]              // lLength2 = x1

        // Compare lLength1 and lLength2
        adr     x0, lLength1
        ldr     x0, [x0]
        adr     x1, lLength2
        ldr     x1, [x1]
        cmp     x0, x1
        adr     x2, lLarger
        csel    x0, x0, x1, gt        // lLarger = max(lLength1, lLength2)
        str     x0, [x2]

        // Return lLarger
        adr     x0, lLarger
        ldr     x0, [x0]

        // Epilog
        ldr     x30, [sp]
        add     sp, sp, #16
        ret

        .size BigInt_larger, (. - BigInt_larger)

//----------------------------------------------------------------------
// BigInt_add
//----------------------------------------------------------------------

        .global BigInt_add

BigInt_add:
        // Prolog
        sub     sp, sp, #64           // Allocate stack frame (multiple of 16)
        str     x30, [sp]             // Save link register

        // Store parameters on the stack
        str     x0, [sp, #8]          // oAddend1
        str     x1, [sp, #16]         // oAddend2
        str     x2, [sp, #24]         // oSum

        // Initialize ulCarry = 0 and lIndex = 0
        mov     x0, 0
        str     x0, [sp, #32]         // ulCarry
        str     x0, [sp, #40]         // lIndex

        // Compute lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength)
        ldr     x0, [sp, #8]          // Load oAddend1
        ldr     x0, [x0, #LLENGTH]    // Load oAddend1->lLength
        ldr     x1, [sp, #16]         // Load oAddend2
        ldr     x1, [x1, #LLENGTH]    // Load oAddend2->lLength
        bl      BigInt_larger         // Call BigInt_larger
        str     x0, [sp, #48]         // Store lSumLength

        // Clear oSum->aulDigits using memset
        ldr     x0, [sp, #24]         // Load oSum
        add     x0, x0, #AULDIGITS    // Address of oSum->aulDigits
        mov     x1, 0                 // Zero value
        mov     x2, MAX_DIGITS        // Count
        bl      memset

addition_loop:
        // Check if lIndex < lSumLength
        ldr     x0, [sp, #40]         // Load lIndex
        ldr     x1, [sp, #48]         // Load lSumLength
        cmp     x0, x1
        bge     end_addition_loop     // Break if lIndex >= lSumLength

        // ulSum = ulCarry
        ldr     x0, [sp, #32]         // Load ulCarry
        str     x0, [sp, #56]         // ulSum = ulCarry

        // Add oAddend1->aulDigits[lIndex] to ulSum
        ldr     x0, [sp, #8]          // Load oAddend1
        add     x0, x0, #AULDIGITS    // Address of oAddend1->aulDigits
        ldr     x1, [sp, #40]         // Load lIndex
        ldr     x2, [x0, x1, lsl #3]  // Load oAddend1->aulDigits[lIndex]
        ldr     x3, [sp, #56]         // Load ulSum
        adds    x3, x3, x2            // Add oAddend1->aulDigits[lIndex]
        str     x3, [sp, #56]         // Update ulSum
        cset    x4, cs                // Carry flag

        // Add oAddend2->aulDigits[lIndex] to ulSum
        ldr     x0, [sp, #16]         // Load oAddend2
        add     x0, x0, #AULDIGITS    // Address of oAddend2->aulDigits
        ldr     x2, [x0, x1, lsl #3]  // Load oAddend2->aulDigits[lIndex]
        ldr     x3, [sp, #56]         // Load ulSum
        adds    x3, x3, x2            // Add oAddend2->aulDigits[lIndex]
        str     x3, [sp, #56]         // Store updated ulSum
        cset    x5, cs                // Update carry flag

        // Combine carry flags
        orr     x4, x4, x5            // Combine previous and current carry
        str     x4, [sp, #32]         // Store updated ulCarry

        // Store ulSum into oSum->aulDigits[lIndex]
        ldr     x0, [sp, #24]         // Load oSum
        add     x0, x0, #AULDIGITS    // Address of oSum->aulDigits
        ldr     x1, [sp, #40]         // Load lIndex
        ldr     x3, [sp, #56]         // Load ulSum
        str     x3, [x0, x1, lsl #3]  // Store ulSum in oSum->aulDigits[lIndex]

        // Increment lIndex
        ldr     x0, [sp, #40]
        add     x0, x0, 1
        str     x0, [sp, #40]         // lIndex++

        b       addition_loop         // Repeat loop

end_addition_loop:
        // Check for final carry
        ldr     x0, [sp, #32]         // Load ulCarry
        cbz     x0, set_sum_length    // If ulCarry == 0, skip to set_sum_length

        // Check if there's room for an additional digit
        ldr     x1, [sp, #48]         // Load lSumLength
        cmp     x1, MAX_DIGITS
        bge     return_false          // If lSumLength == MAX_DIGITS, return FALSE

        // Add carry to oSum->aulDigits[lSumLength]
        ldr     x0, [sp, #24]         // Load oSum
        add     x0, x0, #AULDIGITS    // Address of oSum->aulDigits
        ldr     x2, [sp, #48]         // Load lSumLength
        str     xzr, [x0, x2, lsl #3] // Store 1 at oSum->aulDigits[lSumLength]
        add     x2, x2, 1
        str     x2, [sp, #48]         // Increment lSumLength

set_sum_length:
        // Set oSum->lLength = lSumLength
        ldr     x0, [sp, #24]         // Load oSum
        ldr     x1, [sp, #48]         // Load lSumLength
        str     x1, [x0, #LLENGTH]    // oSum->lLength = lSumLength

        mov     x0, TRUE              // Return TRUE
        b       end_BigInt_add

return_false:
        mov     x0, FALSE             // Return FALSE

end_BigInt_add:
        // Epilog
        ldr     x30, [sp]
        add     sp, sp, #64           // Restore stack frame
        ret

        .size BigInt_add, (. - BigInt_add)
