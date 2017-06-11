=======
General
=======

This file talks about some general details about the code that don't really
belong in any other file.

WRAMX banks organisation
========================

While ``WRAM0`` contains the game state (including historical graphs) and is
completely disorganised, most ``WRAMX`` banks have unique uses. There is some
free space in ``WRAM0``, but all ``WRAMX`` banks are full.

The GBC has support for 32x32 background maps. This means that if the game has
to display a bigger background it needs to be placed in a different place and
copied to ``VRAM`` in real time.

A ``VRAM`` bank is 4 KiB in size, which is the same as 64x64. Because of this,
it is really convenient to make the city maps 64x64 as well. This way it is
possible to have different layers of the city in different ``WRAMX`` banks and
access the data corresponding to the same tile by just switching the bank and
using the same address.

File ``source/room_game/room_game.inc`` contains the definitions that are
referenced below.

- Bank 1: City tile map.

  Lower 8 bits of the tile index. This is the same thing as the tile map that is
  stored in ``VRAM``. Done like this to increase the speed when copying it to
  the ``VRAM``.

- Bank 2: City attribute map.

  Top bit of the tile index, palette, etc, in the format that the GBC expects to
  find in the ``VRAM``, because of the same reason it's done in the case of the
  tile map.

- Bank 3: Tile type.

  The lower 5 bits correspond to the actual type of the tile (``TILE_FIELD`` to
  ``TILE_RADIATION``, up to a maximum of ``TYPE_NUMBER - 1``). The top 3 bits
  are flags that indicate whether there are roads, train tracks or power lines
  (``TYPE_HAS_ROAD``, ``TYPE_HAS_TRAIN``, ``TYPE_HAS_POWER``).

  ``TILE_FIELD`` must be 0 always so that ``TYPE_HAS_ROAD``, ``TYPE_HAS_TRAIN``
  and ``TYPE_HAS_POWER`` are always considered to be in ``TYPE_FIELD``. This
  makes it easier to compare in some parts of the code.

  The exceptions are bridges, that are a combination of ``TYPE_WATER`` and the
  corresponding flag.

- Bank 4: Traffic simulation results.

  This simulation is the one that takes the longest to complete. It is then
  useful to keep the results somewhere so that they can be reused easily, for
  example, when showing the traffic minimap, or when calculating the pollution
  of each tile.

- Bank 5: Tile flags.

  Each bit in each tile means something different. Bits ``TILE_OK_POWER_BIT``,
  ``TILE_OK_SERVICES_BIT``, ``TILE_OK_EDUCATION_BIT``, ``TILE_OK_POLLUTION_BIT``
  and ``TILE_OK_TRAFFIC_BIT`` indicate whether a tile has this specific need
  covered or not.

  Bits ``TILE_BUILD_REQUESTED_BIT`` and ``TILE_DEMOLISH_REQUESTED_BIT`` are
  commands set by the module that decides whether to build or demolish buildings
  in residential, commercial and industrial zones.

- Bank 6: Scratch bank 1

  Used for intermediate calculations of the simulation.

- Bank 7: Scratch bank 2

  Used for intermediate calculations of the simulation. Also used for the
  results of the `All Points Addressable module <apa-graphics.rst>`_.

Keypress autorepeat
===================

File ``source/main.asm`` contains some helper functions to simulate keypresses
when the user holds down any of the directions pad keys pressed.

It is needed to ``InitKeyAutorepeat`` to initialize the internal variables, and
``KeyAutorepeatHandle`` must be called after scanning the keys every frame. This
function modifies the internal variables used by the engine (in
``source/engine/utils.asm``).

There is a starting waiting period of ``PAD_AUTOREPEAT_WAIT_INITIAL``. If a key
is hold less than that, no automatic keypress is simulated. After that period is
passed, a keypress is simulated, and it is repeated once every
``PAD_AUTOREPEAT_WAIT_REPEAT`` frames.

Random details
==============

- The city map tileset and palettes used by it is included in file
  ``source/room_game/tileset.asm``. This is used in the title and game rooms.

- Interrupts are enabled at the beginning of ``Main`` and then they remain
  enabled. The code is only allowed to disable them in critical sections (like
  the ROM bank handler or when writing to ``VRAM``).

- There is a default VBL handler (``DefaultVBLHandler``) that can be setup by
  calling ``SetDefaultVBLHandler``. This default handler updates the sprites,
  SFXs and music.
