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

        // register alias for optimization 
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

        // if (lLength1 <= lLength2) goto else_section;
        cmp     x0, x1
        ble     else_section

        // lLarger = lLength1;
        // goto return_section;
        mov     lLarger, lLength1
        b       return_section

else_section: 
        // lLarger = lLength2
        mov     lLarger, lLength2

return_section:
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

        // register alias for optimization 
        ulCarry         .req x19
        ulSum           .req x20
        lIndex          .req x21 
        lSumLength      .req x22

        oAddend1        .req x23
        oAddend2        .req x24
        oSum            .req x25

        .equ     AULDIGITS, 8
        
        .global BigInt_add

BigInt_add:
        // Prolog 
        sub     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        str     x30, [sp]
        str     x19, [sp, ULCARRY_OFFSET]
        str     x20, [sp, ULSUM_OFFSET]
        str     x21, [sp, LINDEX_OFFSET]
        str     x22, [sp, LSUMLENGTH_OFFSET]
        str     x23, [sp, OADDEND1_OFFSET]
        str     x24, [sp, OADDEND2_OFFSET]
        str     x25, [sp, OSUM_OFFSET]

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
        // if (oSum->lLength <= lSumLength) goto skip_clear;
        ldr     x0, [oSum, 0] 
        cmp     x0, lSumLength
        ble     skip_clear

        // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
        mov     x0, oSum
        add     x0, x0, AULDIGITS
        mov     w1, 0
        mov     x2, MAX_DIGITS
        lsl     x2, x2, 3
        bl      memset

skip_clear:
        // ulCarry = 0;
        // lIndex = 0;
        mov     ulCarry, 0
        mov     lIndex, 0

loop_start:
        // if (lIndex >= lSumLength) goto check_carry_out;
        cmp     lIndex, lSumLength
        bge     check_carry_out 

        // ulSum = ulCarry;
        //  ulCarry = 0;
        mov     ulSum, ulCarry
        mov     ulCarry, 0

        // ulSum += oAddend1->aulDigits[lIndex];
        add     x0, oAddend1, AULDIGITS
        ldr     x1, [x0, lIndex, lsl 3]
        add     ulSum, ulSum, x1 

        // if (ulSum < oAddend1->aulDigits[lIndex]) goto skip_carry_1;
        // ulCarry = 1;
        cmp     ulSum, x1 
        bhs     skip_carry_1  //ask emily bcs (161) 
        mov     ulCarry, 1

skip_carry_1:
        // ulSum += oAddend2->aulDigits[lIndex];
        add     x0, oAddend2, AULDIGITS
        ldr     x1, [x0, lIndex, lsl 3]
        add     ulSum, ulSum, x1 

        // if (ulSum < oAddend2->aulDigits[lIndex]) goto skip_carry_2;
        // ulCarry = 1;
        cmp     ulSum, x1 
        bhs     skip_carry_2 
        mov     ulCarry, 1

skip_carry_2:
        // oSum->aulDigits[lIndex] = ulSum;
        add     x0, oSum, AULDIGITS
        str     ulSum, [x0, lIndex, lsl 3]

        // lIndex++; 
        // goto loop_start;
        add     lIndex, lIndex, 1 
        b       loop_start

check_carry_out:
        // if (ulCarry != 1) goto set_length;
        cmp     ulCarry, 1 
        bne     set_length 

        // if (lSumLength != MAX_DIGITS) goto add_carry;
        cmp     lSumLength, MAX_DIGITS
        bne     add_carry

        // return FALSE
        mov     w0, FALSE
        ldr     x30, [sp]
        ldr     x19, [sp, ULCARRY_OFFSET]
        ldr     x20, [sp, ULSUM_OFFSET]
        ldr     x21, [sp, LINDEX_OFFSET]
        ldr     x22, [sp, LSUMLENGTH_OFFSET]
        ldr     x23, [sp, OADDEND1_OFFSET]
        ldr     x24, [sp, OADDEND2_OFFSET]
        ldr     x25, [sp, OSUM_OFFSET]

        add     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        ret

add_carry:
        // oSum->aulDigits[lSumLength] = 1;
        add     x0, oSum, AULDIGITS 
        mov     x1, 1
        str     x1, [x0, lSumLength, lsl #3]

        // lSumLength++ 
        // goto set_length;
        add     lSumLength, lSumLength, 1 

set_length: 
        // oSum->lLength = lSumLength; 
        str     lSumLength, [oSum, 0] 

        // return TRUE;
        mov     w0, TRUE
        LDR     x30, [sp]
        ldr     x19, [sp, ULCARRY_OFFSET]
        ldr     x20, [sp, ULSUM_OFFSET]
        ldr     x21, [sp, LINDEX_OFFSET]
        ldr     x22, [sp, LSUMLENGTH_OFFSET]
        ldr     x23, [sp, OADDEND1_OFFSET]
        ldr     x24, [sp, OADDEND2_OFFSET]
        ldr     x25, [sp, OSUM_OFFSET]

return_add:
        // Epilog: Restore stack space
        add     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        ret

        .size   BigInt_add, (. - BigInt_add)
