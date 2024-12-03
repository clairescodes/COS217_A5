#include <stdio.h>
#include <stdlib.h>
#include <time.h>

/* Modify randomtext.c to accept command-line arguments? */
/* specify number of characters and lines? */ 

int main(void) {
    const int MAX_CHARACTERS = 50000;
    const int MAX_LINES = 1000; 
    int count = 0;
    int line_count = 0;
    unsigned int random_value;
    char c;

    srand((unsigned int)time(NULL)); /* seed */

    while (count < MAX_CHARACTERS && line_count < MAX_LINES) {
        random_value = rand() % 0x7F; /* random between 0 and 0x7E */

        /* discard if character is not in allowed set */
        if (random_value == 0x09 || random_value == 0x0A ||
            (random_value >= 0x20 && random_value <= 0x7E)) {

            c = (char)random_value;

            /* shouldn't exceed MAX_LINES */
            if (c == '\n') line_count++; {
                if (line_count >= MAX_LINES) continue;
            }
            putchar(c);
            count++;
        }
    }
    return 0;
}
