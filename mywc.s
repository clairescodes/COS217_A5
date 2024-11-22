/*--------------------------------------------------------------------*/
/* mywc.s                                                             */
/* Author: Emily Qian and Claire Shin                                 */
/*--------------------------------------------------------------------*/

#include <stdio.h>
#include <ctype.h>

enum {FALSE, TRUE};

static long lLineCount = 0;
static long lWordCount = 0;
static long lCharCount = 0;
static int iChar;
static int iInWord = FALSE;

int main(void)
    int temp_iChar_eq_EOF;
    int temp_isspace;
    int temp_iInWord;
    int temp_not_iInWord;
    int temp_iChar_eq_newline;

    iChar = getchar();
    temp_iChar_eq_EOF = (iChar == EOF);
    while (!temp_iChar_eq_EOF)
        lCharCount = lCharCount + 1;

        temp_isspace = isspace(iChar);
        if (temp_isspace)
            if (iInWord)
                lWordCount = lWordCount + 1;
                iInWord = FALSE;
        else
            temp_not_iInWord = !iInWord;
            if (temp_not_iInWord)
                iInWord = TRUE;

        temp_iChar_eq_newline = (iChar == '\n');
        if (temp_iChar_eq_newline)
            lLineCount = lLineCount + 1;
        iChar = getchar();
        temp_iChar_eq_EOF = (iChar == EOF);

    if (iInWord)
        lWordCount = lWordCount + 1;

    printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
    return 0;
