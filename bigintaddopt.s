//---------------------------------------------------------------------
// bigintaddopt.s
// Author: Claire Shin and Emily Qian
//---------------------------------------------------------------------
        .section .rodata

//----------------------------------------------------------------------
        .section .data

//----------------------------------------------------------------------
        .section .bss

//----------------------------------------------------------------------
        .section .text

        .equ     FALSE, 0
        .equ     TRUE, 1
        .equ     MAX_DIGITS, 32768

        // always multiple of 16 
        .equ    BIGINT_LARGER_STACK_BYTECOUNT, 32

        // local variables and parameter registers
        .equ     lLarger, 8 
        .equ     lLength1, 16
        .equ     lLength2, 24

        lLarger .req x19 
        lLength1 .req x20 
        lLength2 .req x21 

       //--------------------------------------------------------------
       // Return the larger of lLength1 and lLength2.
       // long BigInt_larger(long lLength1, long lLength2)
       //--------------------------------------------------------------
        .global BigInt_larger

BigInt_larger:
        // Prolog
        sub     sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
        str     x30, [sp]
        str     x19, [sp, lLarger]
        str     x20, [sp, lLength1]
        str     x21, [sp, lLength2]

        // long lLarger;
        mov     lLength1, x0 
        mov     lLength2, x1

        cmp     x0, x1
        ble     else

        // lLarger = lLength1
        mov     lLarger, lLength1
        b       return

else: 
        // lLarger = lLength2
        mov     lLarger, lLength2

return:
        // return lLarger;
        mov     x0, lLarger

        // Epilog
        ldr     x30, [sp]
        ldr     x19, [sp, lLarger]
        ldr     x20, [sp, lLength1]
        ldr     x21, [sp, lLength2] 
        add     sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
        ret

        .size   BigInt_larger, (. - BigInt_larger)

       //--------------------------------------------------------------
       // Assign the sum of oAddend1 and oAddend2 to oSum.  
       // oSum should be distinct from oAddend1 and oAddend2.  
       // Return 0 (FALSE) if an overflow occurred, and 1 (TRUE) 
       // otherwise.
       // int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, 
       // BigInt_T oSum)
       //--------------------------------------------------------------
       
        .equ     BIGINT_ADD_STACK_BYTECOUNT, 64
       
       // local variables and parameter offsets 
        .equ     ulCarry, 8
        .equ     ulSum, 16
        .equ     lIndex, 24
        .equ     lSumLength, 32  

        ulCarry         .req x19
        ulSum           .req x20
        lIndex          .req x21 
        lSumLength      .req x22

        .equ     oAddend1, 40 
        .equ     oAddend2, 48
        .equ     oSum, 56

        oAddend1        .req x23
        oAddend2        .req x24
        oSum            .req x25

        .equ     AULDIGITS, 8
        
        .global BigInt_add

BigInt_add:
        // Prolog 
        sub     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        str     x30, [sp]
        str     x19, [sp, ulCarry]
        str     x20, [sp, ulSum]
        str     x21, [sp, lIndex]
        str     x22, [sp, lSumLength]
        str     x23, [sp, oAddend1]
        str     x24, [sp, oAddend2]
        str     x25, [sp, oSum]

        // Save parameters into callee-saved registers
        mov     oAddend1, x0
        mov     oAddend2, x1
        mov     oSum, x2

        // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength)
        mov     x0, oAddend1        // Load oAddend1->lLength
        ldr     x0, [x0]
        mov     x1, oAddend2        // Load oAddend2->lLength
        ldr     x1, [x1]
        bl      BigInt_larger
        mov     lSumLength, x0

        // Clear oSum memory if needed
        ldr     x0, [oSum]            // Load oSum->lLength
        ldr     x0, [x0]
        cmp     x0, lSumLength
        ble     skip_clear

        ldr     x0, [oSum]
        add     x0, x0, AULDIGITS
        mov     x1, 0
        mov     x2, AULDIGITS
        mov     x3, MAX_DIGITS
        mul     x2, x2, x3
        bl      memset

skip_clear:
        // Initialize ulCarry and lIndex
        mov     ulCarry, xzr
        mov     lIndex, xzr

loop_start:
        cmp     lIndex, lSumLength
        bge     check_carry_out       // Exit loop if lIndex >= lSumLength

        // ulSum = ulCarry
        mov     ulSum, ulCarry

        // Add oAddend1->aulDigits[lIndex]
        ldr     x0, [oAddend1]
        add     x0, x0, AULDIGITS
        add     x0, x0, lIndex, lsl #3 // Index into aulDigits
        ldr     x1, [x0]
        add     ulSum, ulSum, x1

        // Update ulCarry if overflow occurred
        cmp     ulSum, x1
        cset    ulCarry, cc

        // Add oAddend2->aulDigits[lIndex]
        ldr     x0, [oAddend2]
        add     x0, x0, AULDIGITS
        add     x0, x0, lIndex, lsl #3
        ldr     x1, [x0]
        add     ulSum, ulSum, x1

        // Update ulCarry for oAddend2
        cmp     ulSum, x1
        cset    x2, cc
        orr     ulCarry, ulCarry, x2

        // Write ulSum to oSum->aulDigits[lIndex]
        ldr     x0, [oSum]
        add     x0, x0, AULDIGITS
        add     x0, x0, lIndex, lsl #3
        str     ulSum, [x0]

        // Increment lIndex
        add     lIndex, lIndex, #1
        b       loop_start

check_carry_out:
        // Handle final carry
        cbz     ulCarry, set_length

        cmp     lSumLength, MAX_DIGITS
        bge     overflow

        // Add carry to oSum
        ldr     x0, [oSum]
        add     x0, x0, AULDIGITS
        add     x0, x0, lSumLength, lsl #3
        mov     x1, 1
        str     x1, [x0]

        // Increment lSumLength
        add     lSumLength, lSumLength, #1

set_length:
        // Update oSum->lLength
        ldr     x0, [oSum]
        str     lSumLength, [x0]

        // Return TRUE
        mov     w0, TRUE
        b       return_add

overflow:
        // Return FALSE
        mov     w0, FALSE

return_add:
        // Epilog: Restore stack space
        add     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        ret
