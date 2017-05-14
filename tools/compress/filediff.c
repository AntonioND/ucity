// MIT license:
//
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

#include <stdlib.h>
#include <stdio.h>

int file_load(const char * path, void ** buffer, size_t * size_)
{
    size_t size;
    *buffer = NULL;

    FILE * f = fopen(path, "rb");
    if(f == NULL)
    {
        printf("Couldn't be open: %s\n", path);
        return 1;
    }

    fseek(f, 0, SEEK_END);

    size = ftell(f);
    if(size_) *size_ = size;
    if(size == 0)
    {
        printf("Empty file: %s\n", path);
        fclose(f);
        return 1;
    }

    rewind(f);
    *buffer = calloc(size, 1);
    if(*buffer == NULL)
    {
        printf("Not enought memory to load: %s\n", path);
        fclose(f);
        return 1;
    }

    if(fread(*buffer, size, 1, f) != 1)
    {
        printf("Error while reading: %s\n", path);
        fclose(f);
        return 1;
    }

    fclose(f);

    return 0;
}

void diff(char * buffer, size_t size)
{
    char c = 0;

    while (size--)
    {
        char r = *buffer - c;
        c = * buffer;
        *buffer = r;
        buffer++;
    }
}

int main(int argc, char * argv[])
{
    char * buffer;
    size_t size;

    // Load file

    if (file_load(argv[1], (void**)&buffer, &size))
        return 1;

    // Compress

    diff(buffer, size);

    // Write result

    FILE * f = fopen(argv[2], "wb");

    if (!f)
    {
        printf("Failed to open: %s\n", argv[2]);
        return 1;
    }

    if (fwrite(buffer, sizeof(char), size, f) != size)
    {
        printf("Failed to write: %s\n", argv[2]);
        fclose(f);
        return 1;
    }

    fclose(f);

    free(buffer);

    // End

    return 0;
}

