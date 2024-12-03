#include "bigint.h"
#include "bigintprivate.h"
#include <string.h>
#include <assert.h>

/*--------------------------------------------------------------------*/
/* Return the larger of lLength1 and lLength2. */
long BigInt_larger(long lLength1, long lLength2)
{
    long lLarger;

    // Prolog: Initialize stack variables 
    if (lLength1 > lLength2)
        goto larger_set_length1;
    goto larger_set_length2;

larger_set_length1:
    lLarger = lLength1;
    goto larger_return;

larger_set_length2:
    lLarger = lLength2;

larger_return:
    return lLarger;

    // Epilog: Restore stack 
}

/*--------------------------------------------------------------------*/
/* Assign the sum of oAddend1 and oAddend2 to oSum. */
int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, BigInt_T oSum)
{
    unsigned long ulCarry = 0;
    unsigned long ulSum = 0;
    long lIndex = 0;
    long lSumLength = 0;

    // Prolog: Initialize stack variables
    if (oAddend1 == NULL || oAddend2 == NULL || oSum == NULL || 
        oSum == oAddend1 || oSum == oAddend2)
        goto return_false;

    // Call BigInt_larger
    lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);

    // Clear oSum's array if necessary
    if (oSum->lLength > lSumLength)
        goto clear_sum_array;
    goto skip_clear;

clear_sum_array:
    memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));

skip_clear:
    // Initialize carry
    ulCarry = 0;
    lIndex = 0;

loop_start:
    if (lIndex >= lSumLength)
        goto check_carry_out;

    ulSum = ulCarry;
    ulCarry = 0;

    // Add oAddend1 digit
    ulSum += oAddend1->aulDigits[lIndex];
    if (ulSum < oAddend1->aulDigits[lIndex])
        ulCarry = 1;

    // Add oAddend2 digit
    ulSum += oAddend2->aulDigits[lIndex];
    if (ulSum < oAddend2->aulDigits[lIndex])
        ulCarry = 1;

    // Store result in oSum
    oSum->aulDigits[lIndex] = ulSum;

    // Increment index
    lIndex++;
    goto loop_start;

check_carry_out:
    if (ulCarry == 1)
    {
        if (lSumLength == MAX_DIGITS)
            goto return_false;

        oSum->aulDigits[lSumLength] = 1;
        lSumLength++;
    }

set_length:
    // Set length of the sum
    oSum->lLength = lSumLength;
    goto return_true;

return_false:
    return 0; // FALSE

return_true:
    return 1; // TRUE

    // Epilog: Restore stack variables
}
