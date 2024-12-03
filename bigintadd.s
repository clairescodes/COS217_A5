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

        .equ     FALSE, 0
        .equ     TRUE, 1
        .equ     MAX_DIGITS, 32768  

        // always multiple of 16 
        .equ     BIGINT_LARGER_STACK_BYTECOUNT, 32

        // local variables and parameter offsets 
        .equ     lLarger, 8 
        .equ     lLength1, 16
        .equ     lLength2, 24

       //--------------------------------------------------------------
       // Return the larger of lLength1 and lLength2.
       // long BigInt_larger(long lLength1, long lLength2)
       //--------------------------------------------------------------
        .global BigInt_larger

BigInt_larger:
        // Prolog
        sub     sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
        str     x30, [sp]

        // long lLarger;
        // Store parameters on stack
        str     x0, [sp, lLength1]
        str     x1, [sp, lLength2]

        cmp     x0, x1
        ble     else

        ldr     x0, [sp, lLength1]
        str     x0, [sp, lLarger]

        b       return

else: 
        // lLarger = lLength2;
        str     x1, [sp, lLarger]

return:
        // return lLarger;
        ldr     x0, [sp, lLarger]

        // Epilog
        ldr     x30, [sp]
        add     sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
        ret

        .size BigInt_larger, (. - BigInt_larger)

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
        .equ     oAddend1, 40 
        .equ     oAddend2, 48
        .equ     oSum, 56

        .equ     AULDIGITS, 8
        
        .global BigInt_add

BigInt_add:
        // Prolog
        sub     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        str     x30, [sp]

        // Save parameters to stack
        str     x0, [sp, oAddend1]
        str     x1, [sp, oAddend2]
        str     x2, [sp, oSum]

        // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
        ldr     x0, [sp, oAddend1]
        ldr     x0, [x0]
        ldr     x1, [sp, oAddend2]
        ldr     x1, [x1] 
        bl      BigInt_larger
        str     x0, [sp, lSumLength]

        // if (oSum->lLength > lSumLength)
        ldr     x0, [sp, oSum]
        ldr     x0, [x0]
        ldr     x1, [sp, lSumLength]
        cmp     x0, x1
        ble     skip_clear

        // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
        ldr     x0, [sp, oSum]
        add     x0, x0, AULDIGITS
        mov     w1, 0
        mov     x2, MAX_DIGITS
        mov     x3, 8
        mul     x2, x2, x3 
        bl      memset

skip_clear:
        // ulCarry = 0;
        mov     x0, xzr
        str     x0, [sp, ulCarry]

        // for (lIndex = 0; lIndex < lSumLength; lIndex++)
        mov     x0, xzr              // lIndex = 0
        str     x0, [sp, lIndex]

loop_start:
        ldr     x0, [sp, lIndex]
        ldr     x1, [sp, lSumLength]
        cmp     x0, x1
        bge     check_carry_out      // Exit loop if lIndex >= lSumLength

        // ulSum = ulCarry;
        ldr     x0, [sp, ulCarry]
        str     x0, [sp, ulSum]

        // ulCarry = 0;
        mov     x0, xzr
        str     x0, [sp, ulCarry]

        // ulSum += oAddend1->aulDigits[lIndex];
        ldr     x0, [sp, oAddend1]
        add     x0, x0, AULDIGITS
        ldr     x1, [sp, lIndex]
        lsl     x1, x1, 3            // Multiply index by sizeof(unsigned long)
        add     x0, x0, x1
        ldr     x1, [x0]
        ldr     x2, [sp, ulSum]
        add     x2, x2, x1
        str     x2, [sp, ulSum]

        // if (ulSum < oAddend1->aulDigits[lIndex]) ulCarry = 1;
        cmp     x2, x1
        bcs     skip_carry_1
        mov     x0, 1
        str     x0, [sp, ulCarry]

skip_carry_1:
        // ulSum += oAddend2->aulDigits[lIndex];
        ldr     x0, [sp, oAddend2]
        add     x0, x0, AULDIGITS
        ldr     x1, [sp, lIndex]
        lsl     x1, x1, 3
        add     x0, x0, x1
        ldr     x1, [x0]
        ldr     x2, [sp, ulSum]
        add     x2, x2, x1
        str     x2, [sp, ulSum]

        // if (ulSum < oAddend2->aulDigits[lIndex]) ulCarry = 1;
        cmp     x2, x1
        bcs     skip_carry_2
        mov     x0, 1
        str     x0, [sp, ulCarry]

skip_carry_2:
        // oSum->aulDigits[lIndex] = ulSum;
        ldr     x0, [sp, oSum]
        add     x0, x0, AULDIGITS            // Point to aulDigits
        ldr     x1, [sp, lIndex]
        lsl     x1, x1, 3
        add     x0, x0, x1
        ldr     x2, [sp, ulSum]
        str     x2, [x0]

        // lIndex++;
        ldr     x0, [sp, lIndex]
        add     x0, x0, 1
        str     x0, [sp, lIndex]

        b       loop_start

check_carry_out:
        // if (ulCarry == 1)
        ldr     x0, [sp, ulCarry]
        cbz     x0, set_length       // Skip if ulCarry == 0

        // if (lSumLength == MAX_DIGITS)
        ldr     x0, [sp, lSumLength]
        mov     x1, MAX_DIGITS
        cmp     x0, x1
        bne     add_carry

        // return FALSE
        mov     w0, FALSE
        b       return_add

add_carry:
        // oSum->aulDigits[lSumLength] = 1;
        ldr     x0, [sp, oSum]
        add     x0, x0, AULDIGITS
        ldr     x1, [sp, lSumLength]
        lsl     x1, x1, 3
        add     x0, x0, x1
        mov     x2, 1
        str     x2, [x0]

        // lSumLength++;
        ldr     x0, [sp, lSumLength]
        add     x0, x0, 1
        str     x0, [sp, lSumLength]

set_length:
        // oSum->lLength = lSumLength;
        ldr     x0, [sp, oSum]
        ldr     x1, [sp, lSumLength]
        str     x1, [x0]

        // return TRUE;
        mov     w0, TRUE

return_add:
        // Epilog
        ldr     x30, [sp]
        add     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
        ret
