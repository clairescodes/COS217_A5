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
        .equ     ULCARRY, 8
        .equ     ULSUM, 16
        .equ     LINDEX, 24
        .equ     LSUMLENGTH, 32  

        ulCarry         .req x19
        ulSum           .req x20
        lIndex          .req x21 
        lSumLength      .req x22

        .equ     OADDEND1, 40 
        .equ     OADDEND2, 48
        .equ     OSUM, 56

        oAddend1        .req x23
        oAddend2        .req x24
        oSum            .req x25

        .equ     AULDIGITS, 8
        
        .global BigInt_add

BigInt_add:
        // Prolog 
        sub     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        str     x30, [sp]
        str     x19, [sp, ULCARRY]
        str     x20, [sp, ULSUM]
        str     x21, [sp, LINDEX]
        str     x22, [sp, LSUMLENGTH]
        str     x23, [sp, OADDEND1]
        str     x24, [sp, OADDEND2]
        str     x25, [sp, OSUM]

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
        mov     x19, 0
        mov     x21, 0

loop_start:
        cmp     lIndex, lSumLength
        bge     check_carry_out       // Exit loop if lIndex >= lSumLength

        // ulSum = ulCarry;
        mov     ulSum, ulCarry

        //  ulCarry = 0;
        mov     ulCarry, 0

        // ulSum += oAddend1->aulDigits[lIndex];
        mov     x0, ulSum 
        mov     x1, oAddend1
        add     x1, x1, 8
        mov     x2, lIndex
        ldr     x1, [x1, x2, lsl 3]
        add     x0, x0, x1 
        mov     ulSum, x0 

        // if (ulSum < oAddend1->aulDigits[lIndex]) ulCarry = 1;
        cmp     x0, x1 
        bhs     skip_carry_1 
        mov     x19, 1

skip_carry_1:
        // ulSum += oAddend2->aulDigits[lIndex];
        mov     x0, ulSum 
        mov     x1, oAddend2
        add     x1, x1, 8
        mov     x2, lIndex
        ldr     x1, [x1, x2, lsl 3]
        add     x0, x0, x1 
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
        mov     x0, ulCarry 
        cmp     x0, 1 
        bne     end 

        // if (lSumLength == MAX_DIGITS) goto add_carry 
        mov     x0, lSumLength
        cmp     x0, MAX_DIGITS
        bne     add_carry

        // return FALSE
        mov     w0, FALSE
        ldr     x30, [sp]
        ldr     x19, [sp, ULCARRY]
        ldr     x20, [sp, ULSUM]
        ldr     x21, [sp, LINDEX]
        ldr     x22, [sp, LSUMLENGTH]
        ldr     x23, [sp, OADDEND1]
        ldr     x24, [sp, OADDEND2]
        ldr     x25, [sp, OSUM]

        add     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        ret

add_carry:
        // oSum->aulDigits[lSumLength] = 1;
        mov     x0, 1
        mov     x1, oSum 
        add     x1, x1, AULDIGITS 
        mov     x2, lSumLength
        str     x0, [x1, x2, lsl 3]

        // lSumLength++ 
        add     lSumLength, lSumLength, 1 

set_length: 
        // oSum->lLength = lSumLength; 
        mov     x0, oSum 
        mov     x1, lSumLength 
        str     x1, [x0] 

        // return TRUE;
        mov     w0, TRUE
        ldr     x19, [sp, ULCARRY]
        ldr     x20, [sp, ULSUM]
        ldr     x21, [sp, LINDEX]
        ldr     x22, [sp, LSUMLENGTH]
        ldr     x23, [sp, OADDEND1]
        ldr     x24, [sp, OADDEND2]
        ldr     x25, [sp, OSUM]

return_add:
        // Epilog: Restore stack space
        add     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        ret

        .size   BigInt_larger, (. - BigInt_larger)

