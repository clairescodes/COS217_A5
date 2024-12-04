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
        .equ     LLARGER_OFFSET, 8 
        .equ     LLENGTH1_OFFSET, 16
        .equ     LLENGTH2_OFFSET, 24

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
        str     x19, [sp, LLARGER_OFFSET]
        str     x20, [sp, LLENGTH1_OFFSET]
        str     x21, [sp, LLENGTH2_OFFSET]

        // long lLarger;
        mov     lLength1, x0 
        mov     lLength2, x1

        cmp     x0, x1
        blt     else

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
        ldr     x19, [sp, LLARGER_OFFSET]
        ldr     x20, [sp, LLENGTH1_OFFSET]
        ldr     x21, [sp, LLENGTH2_OFFSET]
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
        .equ     ULCARRY_OFFSET, 8
        .equ     ULSUM_OFFSET, 16
        .equ     LINDEX_OFFSET, 24
        .equ     LSUMLENGTH_OFFSET, 32  
        .equ     OADDEND1_OFFSET, 40 
        .equ     OADDEND2_OFFSET, 48
        .equ     OSUM_OFFSET, 56

        ulCarry         .req x22
        ulSum           .req x23
        lIndex          .req x24 
        lSumLength      .req x25
        oAddend1        .req x26
        oAddend2        .req x27
        oSum            .req x28

        .equ     AULDIGITS, 8
        
        .global BigInt_add

BigInt_add:
        // Prolog 
        sub     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        str     x30, [sp]
        str     x22, [sp, ULCARRY_OFFSET]
        str     x23, [sp, ULSUM_OFFSET]
        str     x24, [sp, LINDEX_OFFSET]
        str     x25, [sp, LSUMLENGTH_OFFSET]
        str     x26, [sp, OADDEND1_OFFSET]
        str     x27, [sp, OADDEND2_OFFSET]
        str     x28, [sp, OSUM_OFFSET]

        // save parameters to callee saved registers
        mov     oAddend1, x0
        mov     oAddend2, x1
        mov     oSum, x2

        // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength)
        ldr     x0, [oAddend1, 0]
        ldr     x1, [oAddend2, 0]
        bl      BigInt_larger
        mov     lSumLength, x0

        // clear oSum memory if necessary  
        ldr     x0, [oSum, 0]            // Load oSum->lLength
        cmp     x0, lSumLength
        ble     skip_clear

        mov     x0, oSum
        add     x0, x0, AULDIGITS
        mov     w1, 0
        mov     x2, MAX_DIGITS
        mov     x3, AULDIGITS
        mul     x2, x2, x3
        bl      memset

skip_clear:
        // Initialize ulCarry and lIndex
        mov     ulCarry, xzr
        mov     lIndex, xzr

loop_start:
        cmp     lIndex, lSumLength
        bge     check_carry_out       // Exit loop if lIndex >= lSumLength

        // ulSum = ulCarry;
        mov     ulSum, ulCarry

        //  ulCarry = 0;
        mov     ulCarry, xzr

        // ulSum += oAddend1->aulDigits[lIndex];
        add     x1, oAddend1, 8
        ldr     x1, [x1, lIndex, lsl 3]
        add     ulSum, ulSum, x1 
        mov     ulSum, x0  

        // if (ulSum < oAddend1->aulDigits[lIndex]) ulCarry = 1;
        cmp     x0, x1 
        bhs     skip_carry_1  //ask emily bcs (161) 
        mov     ulCarry, 1

skip_carry_1:
        // ulSum += oAddend2->aulDigits[lIndex];
        add     x1, oAddend2, 8
        mov     x2, lIndex
        ldr     x1, [x1, x2, lsl 3]
        add     ulSum, ulSum, x1 
        mov     ulSum, x0 

        // if (ulSum < oAddend2->aulDigits[lIndex]) ulCarry = 1;
        cmp     x0, x1 
        bhs     skip_carry_2 
        mov     ulCarry, 1

skip_carry_2:
        // oSum->aulDigits[lIndex] = ulSum;
        mov     x0, ulSum 
        mov     x1, oSum 
        add     x1, x1, AULDIGITS
        mov     x2, lIndex 
        str     x0, [x1, x2, lsl 3]

        // lIndex++; 
        add     lIndex, lIndex, 1 
        b       loop_start

check_carry_out:
        // if (ulCarry == 1) goto end 
        cmp     ulCarry, 1 
        bne     set_length 

        // if (lSumLength == MAX_DIGITS) goto add_carry 
        cmp     lSumLength, MAX_DIGITS
        bne     add_carry

        // return FALSE
        mov     w0, FALSE
        b       epilogue 

add_carry:
        // oSum->aulDigits[lSumLength] = 1;
        add     x1, oSum, AULDIGITS 
        mov     x0, 1
        str     x0, [x1, lSumLength, lsl 3] // labta careful!!

        // lSumLength++ 
        add     lSumLength, lSumLength, 1 

set_length: 
        // oSum->lLength = lSumLength; 
        mov     x0, oSum 
        mov     x1, lSumLength 
        str     x1, [x0] 

epilogue: 
        // return TRUE;
        mov     w0, TRUE
        ldr     x30, [sp]
        ldr     x22, [sp, ULCARRY_OFFSET]
        ldr     x23, [sp, ULSUM_OFFSET]
        ldr     x24, [sp, LINDEX_OFFSET]
        ldr     x25, [sp, LSUMLENGTH_OFFSET]
        ldr     x26, [sp, OADDEND1_OFFSET]
        ldr     x27, [sp, OADDEND2_OFFSET]
        ldr     x28, [sp, OSUM_OFFSET]
        add     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        ret

        .size   BigInt_add, (. - BigInt_add)

