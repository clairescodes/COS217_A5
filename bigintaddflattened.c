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
    if (lLength1 <= lLength2)
        goto else_section;
    lLarger = lLength1;
    goto return_section;

else_section:
    lLarger = lLength2;

return_section:
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
        return 0; 

    // Call BigInt_larger
    lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);

    // Clear oSum's array if necessary
    if (oSum->lLength <= lSumLength)
        goto skip_clear;
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
        goto skip_carry_1;
    ulCarry = 1;

skip_carry_1: 
    // Add oAddend2 digit
    ulSum += oAddend2->aulDigits[lIndex];
    if (ulSum < oAddend2->aulDigits[lIndex])
        goto skip_carry_2;
    ulCarry = 1;

skip_carry_2: 
    // Store result in oSum
    oSum->aulDigits[lIndex] = ulSum;

    // Increment index
    lIndex++;
    goto loop_start;

check_carry_out:
    if (ulCarry != 1) goto set_length;
    if (lSumLength != MAX_DIGITS) goto add_carry;    
    return 0; 

add_carry: 
    // Add carry to oSum
    oSum->aulDigits[lSumLength] = 1;
    lSumLength++;
    goto set_length;

set_length:
    // Set length of the sum
    oSum->lLength = lSumLength;
    return 1; 

clear_sum_array:
    // Clear oSum's array
    memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
    goto skip_clear;

}

    // Epilog: Restore stack variables
