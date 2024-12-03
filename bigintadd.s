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

//---------------------------------------------------------------------
// BigInt_larger: return the larger of lLength1 and lLength2
//---------------------------------------------------------------------

        .equ FALSE, 0
        .equ TRUE, 1

        .equ STACK_FRAME_SIZE_BIGINT_LARGER, 16
        .equ OFFSET_LARGER, 0
        .equ OFFSET_LENGTH1, 8
        .equ OFFSET_LENGTH2, 16

        .global BigInt_larger

BigInt_larger:
        // Prolog
        sub     sp, sp, STACK_FRAME_SIZE_BIGINT_LARGER
        str     x30, [sp, 8]

        // long lLarger;
        // Store parameters on stack
        str     x0, [sp, OFFSET_LENGTH1]
        str     x1, [sp, OFFSET_LENGTH2]

        // if (lLength1 > lLength2)
        ldr     x0, [sp, OFFSET_LENGTH1]
        ldr     x1, [sp, OFFSET_LENGTH2]
        cmp     x0, x1
        blt     else1

        // lLarger = lLength1;
        str     x0, [sp, OFFSET_LARGER]
        b       endif1

else1:
        // lLarger = lLength2;
        str     x1, [sp, OFFSET_LARGER]

endif1:
        // return lLarger;
        ldr     x0, [sp, OFFSET_LARGER]

        // Epilog
        ldr     x30, [sp, 8]
        add     sp, sp, STACK_FRAME_SIZE_BIGINT_LARGER
        ret

        .size BigInt_larger, (. - BigInt_larger)

//---------------------------------------------------------------------
// BigInt_add
// Assign the sum of oAddend1 and oAddend2 to oSum
//---------------------------------------------------------------------

        .equ STACK_FRAME_SIZE_BIGINT_ADD, 64
        .equ OFFSET_ADDEND1, 8
        .equ OFFSET_ADDEND2, 16
        .equ OFFSET_SUM, 24
        .equ OFFSET_CARRY, 32
        .equ OFFSET_TEMP_SUM, 40
        .equ OFFSET_INDEX, 48
        .equ OFFSET_SUM_LENGTH, 56

        .equ OFFSET_LENGTH, 0
        .equ OFFSET_DIGITS, 8

        .global BigInt_add

BigInt_add:
        // Prolog
        sub     sp, sp, STACK_FRAME_SIZE_BIGINT_ADD
        str     x30, [sp, 8]

        // Save parameters to stack
        str     x0, [sp, OFFSET_ADDEND1]
        str     x1, [sp, OFFSET_ADDEND2]
        str     x2, [sp, OFFSET_SUM]

        // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
        ldr     x0, [sp, OFFSET_ADDEND1]
        ldr     x0, [x0, OFFSET_LENGTH]
        ldr     x1, [sp, OFFSET_ADDEND2]
        ldr     x1, [x1, OFFSET_LENGTH]
        bl      BigInt_larger
        str     x0, [sp, OFFSET_SUM_LENGTH]

        // if (oSum->lLength > lSumLength)
        ldr     x1, [sp, OFFSET_SUM]
        ldr     x1, [x1, OFFSET_LENGTH]
        ldr     x2, [sp, OFFSET_SUM_LENGTH]
        cmp     x1, x2
        bls     skip_clear

        // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
        ldr     x1, [sp, OFFSET_SUM]
        add     x1, x1, OFFSET_DIGITS
        mov     x2, 0
        mov     x3, MAX_DIGITS * 8
        bl      memset

skip_clear:
        // ulCarry = 0;
        mov     x9, 0

        // for (lIndex = 0; lIndex < lSumLength; lIndex++)
        mov     x10, 0
loop1:
        ldr     x0, [sp, OFFSET_SUM_LENGTH]
        cmp     x10, x0
        bge     endloop1

        // ulSum = ulCarry;
        mov     x11, x9
        mov     x9, 0

        // ulSum += oAddend1->aulDigits[lIndex];
        ldr     x0, [sp, OFFSET_ADDEND1]
        ldr     x1, [x0, OFFSET_DIGITS]
        ldr     x0, [sp, OFFSET_INDEX]
        ldr     x2, [x1, x0, lsl 3]
        adds    x11, x11, x2
        bcs     carry1

carry1:
        // if (ulSum < oAddend1->aulDigits[lIndex]) ulCarry = 1;
        mov     x9, 1

        // ulSum += oAddend2->aulDigits[lIndex];
        ldr     x0, [sp, OFFSET_ADDEND2]
        ldr     x1, [x0, OFFSET_DIGITS]
        ldr     x2, [x1, x0, lsl 3]
        adds    x11, x11, x2
        bcs     carry2

carry2:
        // if (ulSum < oAddend2->aulDigits[lIndex]) ulCarry = 1;
        mov     x9, 1

        // oSum->aulDigits[lIndex] = ulSum;
        ldr     x0, [sp, OFFSET_SUM]
        ldr     x1, [x0, OFFSET_DIGITS]
        str     x11, [x1, x0, lsl 3]

        // Increment lIndex
        add     x10, x10, 1
        b       loop1

endloop1:
        // if (ulCarry == 1)
        cmp     x9, 1
        bne     no_carry

        // if (lSumLength == MAX_DIGITS) return FALSE;
        ldr     x0, [sp, OFFSET_SUM_LENGTH]
        cmp     x0, MAX_DIGITS
        bge     overflow

        // oSum->aulDigits[lSumLength] = 1;
        ldr     x1, [sp, OFFSET_SUM]
        ldr     x2, [x1, OFFSET_DIGITS]
        str     x9, [x2, x0, lsl 3]

        // lSumLength++;
        add     x0, x0, 1
        str     x0, [sp, OFFSET_SUM_LENGTH]

overflow:
        mov     x0, FALSE
        b       exit

no_carry:
        mov     x0, TRUE

exit:
        // Epilog
        ldr     x30, [sp, 8]
        add     sp, sp, STACK_FRAME_SIZE_BIGINT_ADD
        ret

        .size BigInt_add, (. - BigInt_add)
