
#include <stdio.h>

// Generate LUT with all possible results for 8 bit values shifted left by
// 2 to 6.
int main(int argc, char * argv[])
{
    FILE * f = fopen("shift.txt", "wt");

    if (!f)
        return 1;

    int r;

    for (r = 6; r >= 2; r--)
    {
        int i, j;

        for (j = 0; j < 8; j++)
        {
            fprintf(f, "    DB ");

            for (i = 0; i < 8; i++)
            {
                unsigned char val = i + 8 * j;
                fprintf(f, "$%02X,$%02X", (val<<r)&0xFF, (val<<r)>>8);
                if (i < 7)
                    fprintf(f, ",");
            }

            fprintf(f, "\n");
        }

        fprintf(f, "\n");
    }

    fclose(f);

    return 0;
}

