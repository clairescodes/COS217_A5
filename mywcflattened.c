#include <stdio.h>
#include <ctype.h>

int main(void)
{
    long lLineCount = 0;   
    long lWordCount = 0; 
    long lCharCount = 0; 
    int iInWord = 0;   
    int iChar; 

read:
    iChar = getchar();
    if (iChar == EOF) goto endloop;

processchar:
    lCharCount++;
    if (iChar == '\n') lLineCount++;
    if (isspace(iChar)) goto whitespace;
    goto nonwhitespace; 

whitespace:
    if (iInWord)
    {
        lWordCount++;
        iInWord = 0;
    }
    goto read; 

nonwhitespace:
    if (!iInWord) iInWord = 1;
    goto read;

endloop:
    if (iInWord) lWordCount++;

print:
    printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
    goto exit;

exit:
    return 0;
}
