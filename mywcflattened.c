#include <stdio.h>
#include <ctype.h>

int main(void)
{
    long lineCount = 0;   
    long wordCount = 0; 
    long charCount = 0; 
    int inWord = 0;   
    int ch; 

read:
    ch = getchar();
    if (ch == EOF) goto endloop;

processchar:
    charCount++;
    if (isspace(ch)) goto whitespace;
    goto nonwhitespace;

whitespace:
    if (inWord)
    {
        wordCount++;
        inWord = 0;
    }
    if (ch == '\n') lineCount++;
    goto read;

nonwhitespace:
    if (!inWord) inWord = 1;
    goto read;

endloop:
    if (inWord) wordCount++;
    goto print;

print:
    printf("%7ld %7ld %7ld\n", lineCount, wordCount, charCount);
    goto exit;

exit:
    return 0;
}
