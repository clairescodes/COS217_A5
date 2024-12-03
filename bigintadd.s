//---------------------------------------------------------------------
// bigintadd.s
// Author: Claire Shin, Emily Qian
//---------------------------------------------------------------------

        .section .rodata

//---------------------------------------------------------------------

        .section .data

//---------------------------------------------------------------------

        .section .bss

//---------------------------------------------------------------------

        .section .text

        .equ FALSE, 0
        .equ TRUE, 1
        .equ MAX_DIGITS, 32768  

        // must be a multiple of 16
        .equ BIGINT_LARGER_STACK_BYTECOUNT, 16
        .equ BIGINT_ADD_STACK_BYTECOUNT, 64

        // local variables and parameter offsets 
        .equ LARGER_LRESULT, 0
        .equ LARGER_L1,      8
        .equ LARGER_L2,      16

        .equ ADD_L1,         8
        .equ ADD_L2,         16
        .equ ADD_SUM,        24
        .equ ADD_CARRY,      32
        .equ ADD_TEMP,       40
        .equ ADD_INDEX,      48
        .equ ADD_SUM_LENGTH, 56

        // Heap struct offsets
        .equ HEAP_LENGTH,    0
        .equ HEAP_DIGITS,    8

//---------------------------------------------------------------------
// Return the larger of lLength1 and lLength2.
// long BigInt_larger(long lLength1, long lLength2)
//---------------------------------------------------------------------
        .global BigInt_larger

BigInt_larger:
        // Prolog
        sub     sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
        str     x30, [sp, 8]

        // long lLarger;
        // Store parameters on stack
        str     x0, [sp, LARGER_L1]
        str     x1, [sp, LARGER_L2]

        // if (lLength1 > lLength2)
        ldr     x0, [sp, LARGER_L1]
        ldr     x1, [sp, LARGER_L2]
        cmp     x0, x1
        blt     else1

        // lLarger = lLength1;
        str     x0, [sp, LARGER_LRESULT]
        b       endif1

else1:
        // lLarger = lLength2;
        str     x1, [sp, LARGER_LRESULT]

endif1:
        // return lLarger;
        ldr     x0, [sp, LARGER_LRESULT]

        // Epilog
        ldr     x30, [sp, 8]
        add     sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
        ret

        .size BigInt_larger, (. - BigInt_larger)

//---------------------------------------------------------------------
// Assign the sum of oAddend1 and oAddend2 to oSum.  
// oSum should be distinct from oAddend1 and oAddend2.  
// Return 0 (FALSE) if an overflow occurred, and 1 (TRUE) otherwise.
// int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, BigInt_T oSum)
//---------------------------------------------------------------------
        .global BigInt_add

BigInt_add:
        // Prolog
        sub     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        str     x30, [sp, 8]

        // Save parameters to stack
        str     x0, [sp, ADD_L1]
        str     x1, [sp, ADD_L2]
        str     x2, [sp, ADD_SUM]

        // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
        ldr     x0, [sp, ADD_L1]
        ldr     x0, [x0, HEAP_LENGTH]
        ldr     x1, [sp, ADD_L2]
        ldr     x1, [x1, HEAP_LENGTH]
        bl      BigInt_larger
        str     x0, [sp, ADD_SUM_LENGTH]

        // if (oSum->lLength > lSumLength)
        ldr     x1, [sp, ADD_SUM]
        ldr     x1, [x1, HEAP_LENGTH]
        ldr     x2, [sp, ADD_SUM_LENGTH]
        cmp     x1, x2
        bls     skip_clear

        // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
        ldr     x1, [sp, ADD_SUM]
        add     x1, x1, HEAP_DIGITS
        mov     x2, 0
        mov     x3, MAX_DIGITS * 8
        bl      memset

skip_clear:
        // ulCarry = 0;
        mov     x9, 0

        // for (lIndex = 0; lIndex < lSumLength; lIndex++)
        mov     x10, 0
loop1:
        ldr     x0, [sp, ADD_SUM_LENGTH]
        cmp     x10, x0
        bge     endloop1

        // ulSum = ulCarry;
        mov     x11, x9
        mov     x9, 0

        // ulSum += oAddend1->aulDigits[lIndex];
        ldr     x0, [sp, ADD_L1]
        ldr     x1, [x0, HEAP_DIGITS]
        ldr     x0, [sp, ADD_INDEX]
        ldr     x2, [x1, x0, lsl 3]
        adds    x11, x11, x2
        bcs     carry1

carry1:
        // if (ulSum < oAddend1->aulDigits[lIndex]) ulCarry = 1;
        mov     x9, 1

        // ulSum += oAddend2->aulDigits[lIndex];
        ldr     x0, [sp, ADD_L2]
        ldr     x1, [x0, HEAP_DIGITS]
        ldr     x2, [x1, x0, lsl 3]
        adds    x11, x11, x2
        bcs     carry2

carry2:
        // if (ulSum < oAddend2->aulDigits[lIndex]) ulCarry = 1;
        mov     x9, 1

        // oSum->aulDigits[lIndex] = ulSum;
        ldr     x0, [sp, ADD_SUM]
        ldr     x1, [x0, HEAP_DIGITS]
        str     x11, [x1, x0, lsl 3]

        // Increment lIndex
        add     x10, x10, 1
        b       loop1

endloop1:
        // if (ulCarry == 1)
        cmp     x9, 1
        bne     no_carry

        // if (lSumLength == MAX_DIGITS) return FALSE;
        ldr     x0, [sp, ADD_SUM_LENGTH]
        cmp     x0, MAX_DIGITS
        bge     overflow

        // oSum->aulDigits[lSumLength] = 1;
        ldr     x1, [sp, ADD_SUM]
        ldr     x2, [x1, HEAP_DIGITS]
        str     x9, [x2, x0, lsl 3]

        // lSumLength++;
        add     x0, x0, 1
        str     x0, [sp, ADD_SUM_LENGTH]

overflow:
        mov     x0, FALSE
        b       exit

no_carry:
        mov     x0, TRUE

exit:
        // Epilog
        ldr     x30, [sp, 8]
        add     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        ret

        .size BigInt_add, (. - BigInt_add)
