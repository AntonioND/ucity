=================
Saved Data Format
=================

Even though this game has been designed with 16 SRAM banks in mind, most
flashcarts have less, and some emulators don't support more than 4. For that
reason, the saved the saved data format was designed with scalability in mind.

When the game boots, it runs a routine that detects the number of available
banks. Every city uses a SRAM bank, so the number of cities that can be saved is
the same as the number of available SRAM banks. If it is needed to trim a saved
data file, all the cities contained in the resulting file would still work.
Similarly, it would be easy to manage cities from one save file and move them to
a different one.

The relevant code is located in:

- ``source/sram_utils.asm`` : Functions to handle all SRAM saved data, like
  checksum calculations or verification.

- ``source/save_struct.asm`` : Format of the saved data. It is repeated in all
  SRAM banks.

- ``source/save_struct.inc`` : Helpers to handle saved data.

- ``source/room_game/map_load.asm`` : It uses the available routines to load
  cities from SRAM.

- ``source/room_save_menu/room_save_menu.asm`` : It uses the available routines
  to load and print information about saved cities as well as the ones used to
  save cities to SRAM.

- ``source/room_game/sram_map_handle.asm`` : Functions to load and save cities.

SRAM size check
===============

The function ``SRAM_PowerOnCheck`` in ``source/sram_utils.asm`` checks the real
available memory for saving data.

In short, it saves the first byte of each SRAM bank (up to a max of 16) and then
it writes a number from 15 to 0 to the first byte of them: 15 to SRAM bank 0, 14
to bank 1, and so on until 0 is writen to SRAM bank 15.

If less than 16 banks are available, this will make the cartridge controller to
ignore the top bits of the number and make it wrap. In that case, only the last
numbers will survive. For example, if only 4 banks are available, only values 3
to 0 will remain in SRAM.

Even though this code is really fast, there's still the possibility of the GBC
being turned off during the SRAM manipulation code (running out of batteries,
etc). This remains as something that could be improved in the future.

Format
======

The format consists on a series of fields as specified in
``source/save_struct.asm``. There is some padding between different sections for
future use. That means that, if a new field is needed, it could be placed next
to others that are related to it without moving all the rest in the process.

The first field is a 4-byte magic string: ``BTCY``

Then, the 16-bit checksum for this bank (LSB first). The checksum used is the
BSD checksum because of its simplicity (see ``SRAMCalculateChecksum``):

.. code:: c

    u16 sum = 0;
    u8 * data = &start;
    for (size_t i = 0; i < size; i++)
    {
        sum = (sum >> 1) | (sum << 15);
        sum += data[i];
    }

The rest of the fields are simply the saved version of variables used in-game.

The city map is saved as a tile map. The tile map is saved as-is with a memcopy,
the attribute map is compressed  so that each byte holds the values for 8 tiles.
It is only needed to save the top bit of the tile index because the palette and
other information can be reconstructed from it.

Other interesting information that is saved is the plots that show the evolution
of population, funds, etc, with time.
