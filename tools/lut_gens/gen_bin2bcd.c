
#include <stdio.h>
#include <math.h>

// Output two bytes with the BCD value of a byte
int main(int argc, char * argv[])
{
    FILE * f = fopen("bin2bcd.txt", "wt");

    if (!f)
        return 1;

    int i, j;

    for (j = 0; j < 32; j++)
    {
        fprintf(f,"    DB ");

        for (i = 0; i < 8; i++)
        {
            int val = i + j * 8;

            fprintf(f, "$%02X,$%02X",
                    (val%10) | (((val/10)%10)<<4),
                    ((val/100)%10) );

            if (i != (8-1))
                fprintf(f, ", ");
        }

        fprintf(f, "\n");
    }

    fclose(f);

    return 0;
}

