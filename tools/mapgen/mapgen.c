
// Test code to generate maps. Used to prototype the code used by uCity. Code
// licensed under the terms of the MIT license.

// Copyright 2017 Antonio Nino Diaz (AntonioND/SkyLyrac)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <stdio.h>
#include <time.h>

// Size of the map
#define SZ 64

int endmap[SZ][SZ];
int tempmap[SZ][SZ];

int low_water = 0;

unsigned char _x, _y, _z, _w;

//-----------------------------------------------------------------------------

// Adapted from https://en.wikipedia.org/wiki/Xorshift

void srand(int s)
{
    _x = s; // 21
    _y = 229;
    _z = 181;
    _w = 51;
}

int rand(void)
{
    unsigned char t = _x ^ (_x << 3);
    _x = _y;
    _y = _z;
    _z = _w;
    _w = _w ^ (_w >> 5) ^ (t ^ (t >> 2));
    return _w;
}

//-----------------------------------------------------------------------------

int circle(int s, int x, int y)
{
    return (s*s <= (x*x + y*y)) ? 1 : 0;
}

int clamp(int min, int val, int max)
{
    if (val < min)
        return min;
    else if (val > max)
        return max;
    return val;
}

void normalize_map(void)
{
    int total = 0;
    int min_ = endmap[0][0];
    int max_ = endmap[0][0];

    int i, j;
    for (j = 0; j < SZ; j++) for (i = 0; i < SZ; i++)
    {
        int c = endmap[i][j];

        if (min_ > c) min_ = c;
        if (max_ < c) max_ = c;

        total += c;
    }

    int mean = total / (SZ*SZ);

    if ((max_- min_) < 0x40)
    {
        printf("***** Low variability! *****\n");
    }

    for (j = 0; j < SZ; j++) for (i = 0; i < SZ; i++)
    {
        int c = endmap[i][j];
        int diff = c - mean;
        diff += low_water ? 32 : 0;
        endmap[i][j] = clamp(-128,diff,127);
    }
}

int read_map_clamp_coords(int x, int y)
{
    if (x < 0) x = 0;
    else if (x >= SZ) x = SZ -1;
    if (y < 0) y = 0;
    else if (y >= SZ) y = SZ -1;
    return endmap[x][y];
}

void smooth_map(void)
{
    int i,j;
    for (j = 0; j < SZ; j++) for (i = 0; i < SZ; i++)
    {
        int t = read_map_clamp_coords(i-1, j) +
                read_map_clamp_coords(i+1, j) +
                read_map_clamp_coords(i, j-1) +
                read_map_clamp_coords(i, j+1);

        int c = t / 4 + read_map_clamp_coords(i, j);
        tempmap[i][j] = c / 2;
    }

    for (j = 0; j < SZ; j++) for (i = 0; i < SZ; i++)
        endmap[i][j] = tempmap[i][j];
}

void print_map(void)
{
#define KNRM  "\x1B[0m"

#define KBLK  "\x1B[40m"
#define KRED  "\x1B[41m"
#define KGRN  "\x1B[42m"
#define KYEL  "\x1B[43m"
#define KBLU  "\x1B[44m"
#define KMAG  "\x1B[45m"
#define KCYN  "\x1B[46m"
#define KWHT  "\x1B[47m"

    int i,j;
    for (j = 0; j < SZ; j++)
    {
        for (i = 0; i < SZ; i++)
        {
            char c = endmap[i][j];

            //char * arr[6] = { KBLK, KBLU, KCYN, KGRN, KYEL, KRED };
            //char * arr[12] = { KBLK, KBLK, KBLU, KBLU, KCYN, KCYN, KGRN, KYEL,
            //    KYEL, KYEL, KRED, KRED };
            char * arr[12] = { KCYN, KCYN, KCYN, KCYN, KCYN, KCYN, KGRN, KYEL,
                KYEL, KYEL, KYEL, KYEL };

            int num = 128 + (int)c;
            printf("%s%02d",arr[num * 12 / 256],num*12/256);
        }

        printf(KNRM "\n");
    }
}

// First argument in the command line can be a seed from 0 to 255. If that
// argument isn't passed, it will generate a seed with time().
int main(int argc, char * argv[])
{
    int i, j, s;

    for (j = 0; j < SZ; j++) for (i = 0; i < SZ; i++)
        endmap[i][j] = 128;

    int seed = time(NULL) & 0xFF;

    if (argc == 2)
    {
        if (sscanf(argv[1], "%d", &seed) == 1)
            seed &= 0xFF;
    }

    srand(seed);

    for (j = 0; j < SZ; j++) for (i = 0; i < SZ; i++)
        endmap[i][j] += (rand() & 63) - 32;

    smooth_map(); // 1 -> 2

    // List of radius of circles that are going to be drawn
    char rarr[] = {
        64,
        64,
        32, 32,
        32, 32,
        16, 16, 16, 16,
        16, 16, 16, 16,
         8,  8,  8,  8,  8,  8,  8,  8,
         8,  8,  8,  8,  8,  8,  8,  8,
         4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
         4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4
    };

    for (s = 0; s < sizeof(rarr); s ++)
    {
        int c = 16;
        //int c = rand() & (s-1);
        if (!(s & 1)) c = -c;
        //if (!(rand() & 1)) c = -c;

        int r = rarr[s];

        int range = SZ - 1;
        int range_small = r/2 - 1;
        int x = (rand() & range);
            x += (rand() & range_small) - (r*3)/4;
        int y = (rand() & range);
            y += (rand() & range_small) - (r*3)/4;

        for (j = 0; j < SZ; j++) for (i = 0; i < SZ; i++)
        {
            int t = endmap[i][j];

            if (circle(r, i-x, j-y))
                endmap[i][j] = clamp(0,t+c,255);
        }
    }

    normalize_map(); // 2 -> 2

    //printf("Original\n");
    //print_map();

    //printf("Pass 1\n");
    smooth_map(); // 2 -> 1
    //print_map();

    //printf("Pass 2\n");
    smooth_map(); // 1 -> 2
    print_map(); // 2 --(convert to tiles)--> Tile

    return 0;
}

