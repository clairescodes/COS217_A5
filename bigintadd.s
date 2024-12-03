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

        // Initialize ulCarry = 0 and lIndex = 0
        adr     x0, ulCarry
        mov     x1, 0
        str     x1, [x0]              // ulCarry = 0
        adr     x0, lIndex
        str     x1, [x0]              // lIndex = 0

        // Compute lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength)
        ldr     x0, [oAddend1, LLENGTH]  // Load oAddend1->lLength
        ldr     x1, [oAddend2, LLENGTH]  // Load oAddend2->lLength
        bl      BigInt_larger            // Call BigInt_larger
        adr     x2, lSumLength
        str     x0, [x2]                 // Store lSumLength

        // Clear oSum->aulDigits using memset
        ldr     x0, [oSum]
        add     x0, x0, AULDIGITS        // Address of oSum->aulDigits
        mov     x1, 0                    // Zero value
        mov     x2, MAX_DIGITS           // Count
        bl      memset

addition_loop:
        // Check if lIndex < lSumLength
        adr     x0, lIndex
        ldr     x0, [x0]              // Load lIndex
        adr     x1, lSumLength
        ldr     x1, [x1]              // Load lSumLength
        cmp     x0, x1
        bge     end_addition_loop     // Break if lIndex >= lSumLength

        // ulSum = ulCarry
        adr     x0, ulCarry
        ldr     x1, [x0]              // Load ulCarry
        adr     x2, ulSum
        str     x1, [x2]              // Store ulSum = ulCarry

        // Add oAddend1->aulDigits[lIndex] to ulSum
        adr     x0, oAddend1
        add     x0, x0, AULDIGITS     // Address of oAddend1->aulDigits
        adr     x1, lIndex
        ldr     x1, [x1]              // Load lIndex
        ldr     x3, [x0, x1, lsl #3]  // Load oAddend1->aulDigits[lIndex]
        adr     x4, ulSum
        ldr     x4, [x4]              // Load ulSum
        adds    x4, x4, x3            // Add oAddend1->aulDigits[lIndex]
        str     x4, [adr, ulSum]      // Update ulSum
        cset    x5, cs                // Carry flag

        // Add oAddend2->aulDigits[lIndex] to ulSum
        adr     x0, oAddend2
        add     x0, x0, AULDIGITS     // Address of oAddend2->aulDigits
        ldr     x6, [x0, x1, lsl #3]  // Load oAddend2->aulDigits[lIndex]
        ldr     x4, [adr]             // ulSum
        adds    x4, x4, x6            // Add oAddend2->aulDigits[lIndex] to ulSum
        str     x4, [adr, ulSum]      // Store updated ulSum
        cset    x7, cs                // Update carry flag

        // Combine carry flags
        orr     x5, x5, x7            // Combine previous and current carry
        adr     x0, ulCarry
        str     x5, [x0]              // Store updated ulCarry

        // Store ulSum into oSum->aulDigits[lIndex]
        adr     x0, oSum
        add     x0, x0, AULDIGITS     // Address of oSum->aulDigits
        adr     x1, lIndex
        ldr     x1, [x1]              // Load lIndex
        ldr     x4, [adr, ulSum]      // Load ulSum
        str     x4, [x0, x1, lsl #3]  // Store ulSum in oSum->aulDigits[lIndex]

        // Increment lIndex
        adr     x0, lIndex
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]              // lIndex++

        b       addition_loop         // Repeat loop

end_addition_loop:
        // Check for final carry
        adr     x0, ulCarry
        ldr     x0, [x0]
        cbz     x0, set_sum_length    // If ulCarry == 0, skip to set_sum_length

        // Check if there's room for an additional digit
        adr     x1, lSumLength
        ldr     x1, [x1]
        cmp     x1, MAX_DIGITS
        bge     return_false          // If lSumLength == MAX_DIGITS, return FALSE

        // Add carry to oSum->aulDigits[lSumLength]
        adr     x0, oSum
        add     x0, x0, AULDIGITS     // Address of oSum->aulDigits
        ldr     x1, [adr, lSumLength]
        mov     x2, 1
        str     x2, [x0, x1, lsl #3]  // Store 1 at oSum->aulDigits[lSumLength]
        add     x1, x1, 1
        str     x1, [adr, lSumLength] // Increment lSumLength

set_sum_length:
        // Set oSum->lLength = lSumLength
        adr     x0, oSum
        adr     x1, lSumLength
        ldr     x2, [x1]
        str     x2, [x0, LLENGTH]     // oSum->lLength = lSumLength

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
