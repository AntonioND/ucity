========================
Scenario Map Compression
========================

In order to save some memory in ROM, scenarios are compressed before including
them and uncompressed when they are going to be used.

The code for the compression tools is located in ``tools/compression``. It has
the following files:

- ``compile.sh``: Script to compile all tools in Linux.

- ``convert.sh``: Script to convert a single binary file of a map into the two
  output compressed files (tile map and attribute map).

- ``convert-all.sh``: Script used to convert all scenarios to the corresponding
  compressed files.

- ``extractbit3.c``: Sets to 0 all bits but bit 3 of each byte of a file.

- ``filediff.c``: Calculate file formed by the relative increments of each byte
  of the original file.

- ``rle.c``: External RLE compressor licensed under the license GPLv3+ (with a
  few modifications to compile on Linux).

On average, tile maps are compressed to 60-80% of their original size. Attribute
maps are compressed a lot more, to around 5-15% of their size. This is even
better than just packing the bit 3 of the attribute map (the top bit of the tile
index). If 8 bits are packed into each byte, the result is 12.5% of the original
size.

The compression process is the following one:

1. GBMB exports a single file with tile map followed by attribute map.

2. That binary file is split into 2 halves (tile map and attribute map).

3. The attribute map is passed to ``extractbit3`` to remove useless information.
   The palette information can be regenerated ingame when the scenario is
   loaded. The original attribute map is removed.

4. Both files are passed as inputs to ``filediff`` to generate files in which
   each byte holds the difference from the previous one. This isn't a
   compression algorithm, but it helps a lot to compress using RLE. For example,
   a file with data ``05 06 06 07 04`` generates the output ``05 01 00 01 FD``.

   This helps the RLE compressor because the maps used by the game tend to have
   a lot of lines in which the same byte is used (that are transformed to an
   array of zeroes, still easily compressible) but also tiles that increment one
   by one (that are converted to a compressible array of ones instead of a lot
   of different numbers).

5. Both files are passed to ``rle``, which compresses them to the RLE format
   used by the BIOS of the GBA and NDS, chosen by its simplicity. In short, the
   file begins with a ``0x30`` byte followed by 3 bytes containing the raw size
   of the file (LSB first). Then, there are as many blocks as needed. The first
   byte of a block says the size of the block and if it is compressed or not.

   If the bit 7 of this byte is 0, this is an uncompressed block. It is followed
   by N+1 uncompressed bytes that must be copied as they appear in the
   compressed buffer. If the bit 7 is 1, this is a compressed block. It is
   followed by a byte that has to be repeated N+3 times. N is the value of the
   low 7 bits of the header of the block.
