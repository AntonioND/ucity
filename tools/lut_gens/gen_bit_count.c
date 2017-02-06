
#include <stdio.h>
#include <math.h>

// Number of bits set to 1 in a byte
int main(int argc, char * argv[])
{
    FILE * f = fopen("bit_count.txt", "wt");

    if (!f)
        return 1;

    int i, j;

    for (j = 0; j < 2; j++)
    {
        fprintf(f, "    DB ");

        for (i = 0; i < 16; i++)
        {
            int val = i + j * 16;
            int count = 0;
            int k;
            for (k = 0; k < 8; k++)
                count += (val >> k) & 1;

            fprintf(f, "%d", count);

            if (i != (16-1))
                fprintf(f, ", ");
        }

        fprintf(f, "\n");
    }

    fclose(f);

    return 0;
}

