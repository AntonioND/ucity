======
Engine
======

This file explains the code in the folder ``source/engine``. It contains a
series of files with helper functions to interact with some parts of the
hardware. It also describes a few other files that interact with them directly.

- ``source/engine/hardware.inc`` : Definitions of registers and other values
  related to the hardware. This file is frequently used by Game Boy projects,
  but the copy available in this repository has been modified with a few
  changes.

- ``source/engine/engine.inc`` : It contains a few useful macros and function
  declarations that are specific to this engine, not so much to the Game Boy.

- ``source/engine/rand.asm`` : Code to generate random numbers in a quick and
  not too reliable way. It should be good enough for this game, though.

- ``source/engine/utils.asm`` : Routines for Memory manipulation, some maths
  operations, joypad handling and ROM stack handling (including routines for
  cross-bank function calls). There are other maths operations in
  ``source/math.asm``, like approximate divisions for stats calculations, when
  the actual result doesn't matter too much.

- ``source/engine/video.asm`` : Helper functions to get the state of the LCD,
  copy data to the VRAM and manipulate backgrounds, sprites and palettes.

- ``source/engine/init.asm`` : Interrupt and restart vectors, ROM header,
  initialization routine, functions to setup interrupt handlers, functions to
  change CPU speed in GBC, stack declaration.

Background handler
==================

As many Game Boy games, this game needs to display backgrounds that are too big
to fit the 32x32 maps that the Game Boy hardware allows. The solution is to load
rows and columns of tiles as the background scrolls.

The only maps with this problem are the cities themselves. The code used to load
them (they can be loaded at any coordinates) and scroll them is in
``source/bg_handler.asm`` and ``source/bg_handler_main.asm``.

Note that the functions in said files update the map in the VRAM, but they don't
update the actual scroll registers, it is needed to call
``bg_update_scroll_registers`` from the VBL handler to do so without graphical
glitches.

Music and SFX
=============

This folder also contains the source code of GBT Player (in files
``source/engine/gbt_player.asm``, ``source/engine/gbt_player.inc`` and
``source/engine/gbt_player_bank1.asm``). It is a separate project that is
maintained in the following repository: https://github.com/AntonioND/gbt-player

The player only supports music, SFXs must be implemented in a per-game basis. In
this game, the code that handles SFX is in ``source/sfx.asm``. This code takes
advantage of the fact that GBT Player allows the code to disable channels so
that they are free to be used by other parts of the program. In this case, the
SFX functions disable the channels they are going to use (and enable them after
playing the SFX).

Note that there is no generic way of calling this code to generate arbitrary
effects, they are all defined in ``source/sfx.asm`` with some helper macros.
