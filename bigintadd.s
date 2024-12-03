//---------------------------------------------------------------------
// bigintadd.s
// Author: Claire Shin and Emily Qian
// Description: Implementation of BigInt_larger and BigInt_add in ARMv8
//---------------------------------------------------------------------

        .section .rodata

AULDIGITS:
        .quad   8

MAX_DIGITS:
        .quad   32768

TRUE:
        .quad   1

FALSE:
        .quad   0

//---------------------------------------------------------------------
// BSS Section: Variables for BigInt_larger and BigInt_add
//---------------------------------------------------------------------
        .section .bss

lLength1:
        .skip   8
lLength2:
        .skip   8
lLarger:
        .skip   8

ulCarry:
        .skip   8
lSumLength:
        .skip   8
lIndex:
        .skip   8
ulSum:
        .skip   8

//---------------------------------------------------------------------
// BigInt_larger
//---------------------------------------------------------------------

        .global BigInt_larger

BigInt_larger:
        // Prolog
        sub     sp, sp, 16
        str     x30, [sp]

        // Store parameters in bss
        adr     x1, lLength1
        str     x0, [x1]               // lLength1 = x0
        adr     x1, lLength2
        str     x1, [x1]               // lLength2 = x1

        // Compare lLength1 and lLength2
        adr     x0, lLength1
        ldr     x0, [x0]
        adr     x1, lLength2
        ldr     x1, [x1]
        cmp     x0, x1
        adr     x2, lLarger
        csel    x0, x0, x1, gt         // lLarger = max(lLength1, lLength2)
        str     x0, [x2]

        // Return lLarger
        adr     x0, lLarger
        ldr     x0, [x0]

        // Epilog
        ldr     x30, [sp]
        add     sp, sp, 16
        ret

        .size BigInt_larger, (. - BigInt_larger)

//---------------------------------------------------------------------
// BigInt_add
//---------------------------------------------------------------------

        .global BigInt_add

BigInt_add:
        // Prolog
        sub     sp, sp, 64             // Allocate stack frame (multiple of 16)
        str     x30, [sp]              // Save link register

        // Initialize ulCarry = 0 and lIndex = 0
        adr     x0, ulCarry
        mov     x1, xzr
        str     x1, [x0]               // ulCarry = 0
        adr     x0, lIndex
        str     x1, [x0]               // lIndex = 0

        // Compute lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength)
        adr     x1, AULDIGITS
        ldr     x2, [x1]               // Load AULDIGITS value
        ldr     x0, [x0, x2]           // Load oAddend1->lLength
        ldr     x1, [x1, x2]           // Load oAddend2->lLength
        bl      BigInt_larger          // Call BigInt_larger
        adr     x2, lSumLength
        str     x0, [x2]               // Store lSumLength

        // Clear oSum->aulDigits using memset
        adr     x0, MAX_DIGITS
        ldr     x1, [x0]               // Load MAX_DIGITS value
        adr     x2, AULDIGITS
        ldr     x3, [x2]               // Load AULDIGITS value
        bl      memset

addition_loop:
        // Check if lIndex < lSumLength
        adr     x0, lIndex
        ldr     x0, [x0]               // Load lIndex
        adr     x1, lSumLength
        ldr     x1, [x1]               // Load lSumLength
        cmp     x0, x1
        bge     end_addition_loop      // Break if lIndex >= lSumLength

        // ulSum = ulCarry
        adr     x0, ulCarry
        ldr     x1, [x0]               // Load ulCarry
        adr     x2, ulSum
        str     x1, [x2]               // Store ulSum = ulCarry

        // Add oAddend1->aulDigits[lIndex] to ulSum
        adr     x1, AULDIGITS
        ldr     x2, [x1]               // Load AULDIGITS value
        lsl     x3, x0, x2             // lIndex * AULDIGITS
        add     x4, x3, x0             // Address of oAddend1->aulDigits[lIndex]
        ldr     x5, [x4]
        adds    x5, x5, x1             // Add value
        str     x5, [x1]

end_addition_loop:
        ldr     x7, x1
        // Check for final carry
        adr     x0, ulCarry
        ldr     x0, [x0]
        cbz     x0, set_sum_length    // If ulCarry == 0, skip to set_sum_length

        // Check if there's room for an additional digit
        adr     x1, lSumLength
        ldr     x1, [x1]
        adr     x2, MAX_DIGITS
        ldr     x2, [x2]
        cmp     x1, x2
        bge     return_false          // If lSumLength == MAX_DIGITS, return FALSE

        // Add carry to oSum->aulDigits[lSumLength]
        adr     x3, AULDIGITS
        ldr     x4, [x3]              // Load AULDIGITS value
        adr     x0, oSum
        add     x0, x0, x4            // Address of oSum->aulDigits
        lsl     x1, x1, x4            // lSumLength * AULDIGITS
        add     x0, x0, x1
        mov     x2, 1
        str     x2, [x0]              // Store carry
        adr     x1, lSumLength
        ldr     x2, [x1]
        add     x2, x2, 1
        str     x2, [x1]              // Increment lSumLength

set_sum_length:
        // Set oSum->lLength = lSumLength
        adr     x0, oSum
        adr     x1, lSumLength
        ldr     x2, [x1]
        adr     x3, AULDIGITS
        ldr     x4, [x3]
        add     x0, x0, x4            // Address of oSum->lLength
        str     x2, [x0]

        mov     x0, xzr               // Return TRUE
        b       end_BigInt_add

return_false:
        mov     x0, xzr               // Return FALSE

end_BigInt_add:
        // Epilog
        ldr     x30, [sp]
        add     sp, sp, 64            // Restore stack frame
        ret

        .size BigInt_add, (. - BigInt_add)
