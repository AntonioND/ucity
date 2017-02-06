#include <stdio.h>
#include <math.h>

// gcc gen_circle.c -lm

int circle(int s, int x, int y)
{
    return ((s-1)*(s-1) > (x*x + y*y)) ? 1 : 0;
}

// Generate a LUT with the shape of a circle
int main(int argc, char * argv[])
{
    FILE * f = fopen("circle.txt", "wt");

    if (!f)
        return 1;

    int r = 64;

    for (r = 64; r > 2; r >>= 1)
    {
        int i, j, b;

        for (j = 0; j < r; j++)
        {
            fprintf(f, "    DB ");

            for (i = 0; i < r; i++)
            {
                unsigned char block = 0;

                int val = circle(r, i, j);

                fprintf(f, "$%02X", val);

                if (i == (r-1))
                    fprintf(f, "\n");
                else if ((i & 15) == 15)
                    fprintf(f, "\n    DB ");
                else
                    fprintf(f, ",");
            }
        }

        fprintf(f, "\n");
    }

    fclose(f);

    return 0;
}

