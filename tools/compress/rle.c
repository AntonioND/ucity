/*----------------------------------------------------------------------------*/
/*--  rle.c - RLE coding for Nintendo GBA/DS                                --*/
/*--  Copyright (C) 2011 CUE                                                --*/
/*--                                                                        --*/
/*--  This program is free software: you can redistribute it and/or modify  --*/
/*--  it under the terms of the GNU General Public License as published by  --*/
/*--  the Free Software Foundation, either version 3 of the License, or     --*/
/*--  (at your option) any later version.                                   --*/
/*--                                                                        --*/
/*--  This program is distributed in the hope that it will be useful,       --*/
/*--  but WITHOUT ANY WARRANTY; without even the implied warranty of        --*/
/*--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the          --*/
/*--  GNU General Public License for more details.                          --*/
/*--                                                                        --*/
/*--  You should have received a copy of the GNU General Public License     --*/
/*--  along with this program. If not, see <http://www.gnu.org/licenses/>.  --*/
/*----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*----------------------------------------------------------------------------*/
#define CMD_DECODE    0x00       // decode
#define CMD_CODE_30   0x30       // RLE magic number

#define RLE_CHECK     1          // bits to check
#define RLE_MASK      0x80       // bits position:
                                 // ((((1 << RLE_CHECK) - 1) << (8 - RLE_CHECK)
#define RLE_LENGTH    0x7F       // length, (0xFF & ~RLE_MASK)

#define RLE_THRESHOLD 2          // max number of bytes to not encode
#define RLE_N         0x80       // max store, (RLE_LENGTH + 1)
#define RLE_F         0x82       // max coded, (RLE_LENGTH + RLE_THRESHOLD + 1)

#define RAW_MINIM     0x00000000 // empty file, 0 bytes
#define RAW_MAXIM     0x00FFFFFF // 3-bytes length, 16MB - 1

#define RLE_MINIM     0x00000004 // header only (empty RAW file)
#define RLE_MAXIM     0x01400000 // 0x01020003, padded to 20MB:
                                 // * header, 4
                                 // * length, RAW_MAXIM
                                 // * flags, (RAW_MAXIM + RLE_N - 1) / RLE_N
                                 // 4 + 0x00FFFFFF + 0x00020000 + padding

/*----------------------------------------------------------------------------*/
#define BREAK(text) { printf(text); return; }
#define EXIT(text)  { printf(text); exit(-1); }

/*----------------------------------------------------------------------------*/
void  Title(void);
void  Usage(void);

char *Load(char *filename, int *length, int min, int max);
void  Save(char *filename, char *buffer, int length);
char *Memory(int length, int size);

void  RLE_Decode(char *filename);
void  RLE_Encode(char *filename);
char *RLE_Code(unsigned char *raw_buffer, int raw_len, int *new_len);

/*----------------------------------------------------------------------------*/
int main(int argc, char **argv) {
  int cmd;
  int arg;

  Title();

  if (argc < 2) Usage();
  if      (!strcmpi(argv[1], "-d")) cmd = CMD_DECODE;
  else if (!strcmpi(argv[1], "-e")) cmd = CMD_CODE_30;
  else                              EXIT("Command not supported\n");
  if (argc < 3) EXIT("Filename not specified\n");

  switch (cmd) {
    case CMD_DECODE:
      for (arg = 2; arg < argc; arg++) RLE_Decode(argv[arg]);
      break;
    case CMD_CODE_30:
      for (arg = 2; arg < argc; arg++) RLE_Encode(argv[arg]);
      break;
    default:
      break;
  }

  printf("\nDone\n");

  return(0);
}

/*----------------------------------------------------------------------------*/
void Title(void) {
  printf(
    "\n"
    "RLE - (c) CUE 2011\n"
    "RLE coding for Nintendo GBA/DS\n"
    "\n"
  ); 
}

/*----------------------------------------------------------------------------*/
void Usage(void) {
  EXIT(
    "Usage: RLE command filename [filename [...]]\n"
    "\n"
    "command:\n"
    "  -d ... decode 'filename'\n"
    "  -e ... encode 'filename'\n"
    "\n"
    "* multiple filenames and wildcards are permitted\n"
    "* the original file is overwritten with the new file\n"
  );
}

/*----------------------------------------------------------------------------*/
char *Load(char *filename, int *length, int min, int max) {
  FILE *fp;
  int   fs;
  char *fb;

  if ((fp = fopen(filename, "rb")) == NULL) EXIT("\nFile open error\n");
  fs = filelength(fileno(fp));
  if ((fs < min) || (fs > max)) EXIT("\nFile size error\n");
  fb = Memory(fs + 3, sizeof(char));
  if (fread(fb, 1, fs, fp) != fs) EXIT("\nFile read error\n");
  if (fclose(fp) == EOF) EXIT("\nFile close error\n");

  *length = fs;

  return(fb);
}

/*----------------------------------------------------------------------------*/
void Save(char *filename, char *buffer, int length) {
  FILE *fp;

  if ((fp = fopen(filename, "wb")) == NULL) EXIT("\nFile create error\n");
  if (fwrite(buffer, 1, length, fp) != length) EXIT("\nFile write error\n");
  if (fclose(fp) == EOF) EXIT("\nFile close error\n");
}

/*----------------------------------------------------------------------------*/
char *Memory(int length, int size) {
  char *fb;

  fb = (char *) calloc(length * size, size);
  if (fb == NULL) EXIT("\nMemory error\n");

  return(fb);
}

/*----------------------------------------------------------------------------*/
void RLE_Decode(char *filename) {
  unsigned char *pak_buffer, *raw_buffer, *pak, *raw, *pak_end, *raw_end;
  unsigned int   pak_len, raw_len, header, len;

  printf("- decoding '%s'", filename);

  pak_buffer = Load(filename, &pak_len, RLE_MINIM, RLE_MAXIM);

  header = *pak_buffer;
  if (header != CMD_CODE_30) {
    free(pak_buffer);
    BREAK(", WARNING: file is not RLE encoded!\n");
  }

  raw_len = *(unsigned int *)pak_buffer >> 8;
  raw_buffer = (unsigned char *) Memory(raw_len, sizeof(char));

  pak = pak_buffer + 4;
  raw = raw_buffer;
  pak_end = pak_buffer + pak_len;
  raw_end = raw_buffer + raw_len;

  while (raw < raw_end) {
    len = *pak++;
    if (pak == pak_end) break;
    if (!(len & RLE_MASK)) {
      len = (len & RLE_LENGTH) + 1;
      if (raw + len > raw_end) {
        printf(", WARNING: wrong decoded length!");
        len = raw_end - raw;
      }
      if (pak + len > pak_end) {
        len = pak_end - pak;
      }
      while (len--) *raw++ = *pak++;
    } else {
      len = (len & RLE_LENGTH) + RLE_THRESHOLD + 1;
      if (raw + len > raw_end) {
        printf(", WARNING: wrong decoded length!");
        len = raw_end - raw;
      }
      while (len--) *raw++ = *pak;
      pak++;
    }
    if (pak == pak_end) break;
  }

  raw_len = raw - raw_buffer;

  if (raw != raw_end) printf(", WARNING: unexpected end of encoded file!");

  Save(filename, raw_buffer, raw_len);

  free(raw_buffer);
  free(pak_buffer);

  printf("\n");
}

/*----------------------------------------------------------------------------*/
void RLE_Encode(char *filename) {
  unsigned char *raw_buffer, *pak_buffer, *new_buffer;
  unsigned int   raw_len, pak_len, new_len;

  printf("- encoding '%s'", filename);

  raw_buffer = Load(filename, &raw_len, RAW_MINIM, RAW_MAXIM);

  pak_buffer = NULL;
  pak_len = RLE_MAXIM + 1;

  new_buffer = RLE_Code(raw_buffer, raw_len, &new_len);
  if (new_len < pak_len) {
    if (pak_buffer != NULL) free(pak_buffer);
    pak_buffer = new_buffer;
    pak_len = new_len;
  }

  Save(filename, pak_buffer, pak_len);

  free(pak_buffer);
  free(raw_buffer);

  printf("\n");
}

/*----------------------------------------------------------------------------*/
char *RLE_Code(unsigned char *raw_buffer, int raw_len, int *new_len) {
  unsigned char *pak_buffer, *pak, *raw, *raw_end, store[RLE_N];
  unsigned int   pak_len, len, store_len, count;

  pak_len = 4 + raw_len + ((raw_len + RLE_N - 1) / RLE_N);
  pak_buffer = (unsigned char *) Memory(pak_len, sizeof(char));

  *(unsigned int *)pak_buffer = CMD_CODE_30 | (raw_len << 8);

  pak = pak_buffer + 4;
  raw = raw_buffer;
  raw_end = raw_buffer + raw_len;

  store_len = 0;
  while (raw < raw_end) {
    for (len = 1; len < RLE_F; len++) {
      if (raw + len == raw_end) break;
      if (*(raw + len) != *raw) break;
    }

    if (len <= RLE_THRESHOLD) store[store_len++] = *raw++;

    if ((store_len == RLE_N) || (store_len && (len > RLE_THRESHOLD))) {
      *pak++ = store_len - 1;
      for (count = 0; count < store_len; count++) *pak++ = store[count];
      store_len = 0;
    }

    if (len > RLE_THRESHOLD) {
      *pak++ = RLE_MASK | (len - (RLE_THRESHOLD + 1));
      *pak++ = *raw;
      raw += len;
    }
  }
  if (store_len) {
    *pak++ = store_len - 1;
    for (count = 0; count < store_len; count++) *pak++ = store[count];
  }

  *new_len = pak - pak_buffer;

  return(pak_buffer);
}

/*----------------------------------------------------------------------------*/
/*--  EOF                                           Copyright (C) 2011 CUE  --*/
/*----------------------------------------------------------------------------*/
