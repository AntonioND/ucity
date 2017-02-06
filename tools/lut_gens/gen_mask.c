
#include <stdio.h>
#include <math.h>

// gcc gen_mask.c -lm

inline int min(int a, int b)
{
    return a < b ? a : b;
}

// Generate masks used for simulation of services such as police or schools.
int main(int argc, char * argv[])
{
    float radius = 16.0;
    int size = 32;

    FILE * f = fopen("small.txt","wt");

    if (!f)
        return 1;

    int i, j;

    for (j = 0; j < size; j++)
    {
        fprintf(f, "    DB ");

        for (i = 0; i < size; i++)
        {
            int x = size / 2 - i;
            int y = size / 2 - j;
            int val = ( (radius - pow(x*x+y*y,1.0/2.0)) * (256.0+128.0) ) /
                      radius;

            if (val > 255)
                val = 255;
            else if (val < 0)
                val = 0;

            fprintf(f, "$%02X", val);

            if ( (i != (size-1)) && ((i&15) == 15) )
                fprintf(f, "\n    DB ");
            else if (i != (size-1))
                fprintf(f, ",");
        }

        fprintf(f, "\n");
    }

    fclose(f);

    // -----------------------------------

    radius = 32.0;
    size = 64;

    f = fopen("big.txt","wt");
    if (!f)
        return 1;

    for (j = 0; j < size; j++)
    {
        fprintf(f, "    DB ");

        for (i = 0; i < size; i++)
        {
            int x = size / 2 - i;
            int y = size / 2 - j;
            int val = ( (radius - pow(x*x+y*y,1.0/2.0)) * (256.0+128.0)) /
                      radius;

            if (val > 255)
                val = 255;
            else if (val < 0)
                val = 0;

            fprintf(f, "$%02X", val);

            if ( (i != (size-1)) && ((i&15) == 15) )
                fprintf(f, "\n    DB ");
            else if (i != (size-1))
                fprintf(f, ",");
        }

        fprintf(f, "\n");
    }

    fclose(f);

    return 0;
}
