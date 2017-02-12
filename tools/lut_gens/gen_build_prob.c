
#include <stdio.h>
#include <math.h>

// gcc gen_build_prob.c -lm

// Generate array of probabilites to create/demolish buildings
int main(int argc, char * argv[])
{
    FILE * f = fopen("probability.txt", "wt");

    if (!f)
        return 1;

    int i;

    fprintf(f, "; Create\n");
    fprintf(f, "    DB ");

    for (i = 0; i < 21; i++) // 0% to 20% of taxes
    {
        int val = 255 - pow(i / 2, 1.75);

        if (val > 255)
            val = 255;
        else if (val < 0)
            val = 0;

        fprintf(f, "$%02X", val);

        if ( (i == 0) || (i == 10))
            fprintf(f, "\n    DB ");
        else if (i != 20)
            fprintf(f, ",");
    }

    fprintf(f, "\n");
    fprintf(f, "\n");

    fprintf(f, "; Demolish\n");
    fprintf(f, "    DB ");

    for (i = 0; i < 21; i++) // 0% to 20% of taxes
    {
        int val = 4 + pow(i / 2, 1.75);

        if (val > 255)
            val = 255;
        else if (val < 0)
            val = 0;

        fprintf(f, "$%02X", val);

        if ( (i == 0) || (i == 10))
            fprintf(f, "\n    DB ");
        else if (i != 20)
            fprintf(f, ",");
    }

    fprintf(f, "\n");
    fclose(f);

    return 0;
}
