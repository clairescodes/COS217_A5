/----------------------------------------------
// bigintadd.s
// Author: Claire Shin
//----------------------------------------------
.equ FALSE, 0
.equ TRUE, 1
.equ EOF, -1
//----------------------------------------------
    .section .data
//----------------------------------------------
    .section .bss
//-----------------------------------------------
    .section .text

// Must be a multiple of 16
        .equ    BIGINT_LARGER_STACK_BYTECOUNT, 32
        
        // Local variable stack offsets:
        .equ    LLARGER, 8
 
        // Parameter stack offsets:
        .equ    LLENGTH1,   16
        .equ    LLENGTH2,    24

*--------------------------------------------------------------------*/

/* Return the larger of lLength1 and lLength2. */

// static long BigInt_larger(long lLength1, long lLength2)

BigInt_larger:

    //Prolog
    sub sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
    str x30, [sp]
    str x0, [sp, LLENGTH1]
    str x1, [sp, LLENGTH2]

    // if (lLength1 < lLength2) goto else1;
    ldr x1, [sp, LLENGTH1]
    ldr x2, [sp, LLENGTH2]
    cmp x1, x2
    blt else1

    // lLarger = lLength1;
    ldr x1, [sp, LLENGTH1]
    str x1, [sp, LLARGER]
    
    // goto endif1;
    b endif1
    
    // lLarger = lLength2;
else1:
    ldr x1, [sp, LLENGTH2]
    str x1, [sp, LLARGER]

endif1:
    ldr x0, [sp, LLARGER]
    ldr x30, [sp]
    add sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
    ret 

    .size   BigInt_larger, (. - BigInt_larger)

/*--------------------------------------------------------------------*/

// stack local variables and parameters offsets
.equ OADDEND1, 8
.equ OADDEND2, 16
.equ OSUM, 24
.equ ULCARRY, 32
.equ ULSUM, 40
.equ LINDEX, 48
.equ LSUMLENGTH, 56 

// heap struct offsets 
.equ lLength, 0
.equ aulDigits, 8

// stack size
.equ BIGINT_ADD_STACK_BYTECOUNT, 64

/* Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
   distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
   overflow occurred, and 1 (TRUE) otherwise. */

// int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, BigInt_T oSum)

.global BigInt_add

BigInt_add:
    //Prolog
    sub sp, sp, BIGINT_ADD_STACK_BYTECOUNT
    str x30, [sp]
    str x0, [sp, OADDEND1]
    str x1, [sp, OADDEND2]
    str x2, [sp, OSUM]

    /* Determine the larger length. */
    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
    ldr x0, [sp, OADDEND1]
    ldr x0, [x0]
    ldr x1, [sp, OADDEND2]
    ldr x1, [x1]
    bl BigInt_larger
    str x0, [sp, LSUMLENGTH]

    /* Clear oSum's array if necessary. */
    // if (oSum->lLength < lSumLength) goto endif2;
        ldr x1, [sp, OSUM]
        ldr x1, [x1]
        cmp x1, x0
        blt endif2;
        ldr x1, [sp, OSUM]
        ldr x1, [x1, aulDigits]
        ldr x2, 0
        ldr x3, MAX_DIGITS * sizeof(unsigned long)
        bl memset        
    endif2:

    /* Perform the addition. */
    mov ULCARRY, 0
    mov LINDEX, 0
    loop1:
        // if (lIndex > lSumLength) goto endloop1;
    

    // index psuedo code
    ldr x0, [sp, oAddend1] 
    add x0, x0, aulDigits
    ldr x1, [sp, lIndex]
    ldr x2, [x0, x1, lsl 3]


    
    