//---------------------------------------------------------------------
// bigintaddoptopt.s
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

       //--------------------------------------------------------------
       // Assign the sum of oAddend1 and oAddend2 to oSum.  
       // oSum should be distinct from oAddend1 and oAddend2.  
       // Return 0 (FALSE) if an overflow occurred, and 1 (TRUE) 
       // otherwise.
       // int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, 
       // BigInt_T oSum)
       //--------------------------------------------------------------
       
        .equ     BIGINT_ADD_STACK_BYTECOUNT, 32
       
       // local variables and parameter offsets 
        .equ     ULCARRY_OFFSET, 8
        .equ     ULSUM_OFFSET, 16
        .equ     LINDEX_OFFSET, 24
        .equ     LSUMLENGTH_OFFSET, 32  

        ulCarry         .req x19
        ulSum           .req x20
        lIndex          .req x21 
        lSumLength      .req x22

        .equ     OADDEND1_OFFSET, 40 
        .equ     OADDEND2_OFFSET, 48
        .equ     OSUM_OFFSET, 56

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

        // Save parameters to callee saved registers
        mov     oAddend1, x0
        mov     oAddend2, x1
        mov     oSum, x2

        // Inline BigInt_larger
        ldr     x0, [oAddend1, 0]      // Load lLength1
        ldr     x1, [oAddend2, 0]      // Load lLength2
        cmp     x0, x1                 // Compare lengths
        mov     lSumLength, x0
        blt     larger_done // fixed
        mov     lSumLength, x1

larger_done:
        // Clear oSum memory if necessary  
        ldr     x0, [oSum, 0]            // Load oSum->lLength
        cmp     x0, lSumLength
        ble     skip_clear

        mov     x0, oSum
        add     x0, x0, AULDIGITS
        mov     w1, 0
        mov     x2, MAX_DIGITS
        lsl     x2, x2, 3
        bl      memset

skip_clear:
        // Initialize ulCarry and lIndex
        mov     ulCarry, 0
        mov     lIndex, 0

loop_start:
        cmp     lIndex, lSumLength
        bge     check_carry_out       // Exit loop if lIndex >= lSumLength

        // ulSum = ulCarry;
        mov     ulSum, ulCarry

        // ulCarry = 0;
        mov     ulCarry, 0

        // ulSum += oAddend1->aulDigits[lIndex];
        add     x0, oAddend1, AULDIGITS
        ldr     x1, [x0, lIndex, lsl 3]
        add     ulSum, ulSum, x1 

        // if (ulSum < oAddend1->aulDigits[lIndex]) ulCarry = 1;
        cmp     ulSum, x1
        bhs     skip_carry_1
        mov     ulCarry, 1

skip_carry_1:
        // ulSum += oAddend2->aulDigits[lIndex];
        add     x0, oAddend2, AULDIGITS
        ldr     x1, [x0, lIndex, lsl 3]
        add     ulSum, ulSum, x1 

        // if (ulSum < oAddend2->aulDigits[lIndex]) ulCarry = 1;
        cmp     ulSum, x1
        bhs     skip_carry_2
        mov     ulCarry, 1

skip_carry_2:
        // oSum->aulDigits[lIndex] = ulSum;
        add     x0, oSum, AULDIGITS
        str     ulSum, [x0, lIndex, lsl 3]

        // lIndex++;
        add     lIndex, lIndex, 1

        b       loop_start

check_carry_out:
        cmp     ulCarry, 1
        bne     set_length

        cmp     lSumLength, MAX_DIGITS
        bne     add_carry

        mov     w0, FALSE
        b       return

add_carry:
        add     x0, oSum, AULDIGITS
        mov     x1, 1
        str     x1, [x0, lSumLength, lsl 3]
        add     lSumLength, lSumLength, 1

set_length:
        str     lSumLength, [oSum, 0]
        mov     w0, TRUE

return:
        // Epilog: Restore stack space
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
