=========
µCity 1.0
=========

Introduction
============

This is µCity (also spelled 'uCity', pronounced 'micro-city'), the open-source
city-building game for Game Boy Color.

.. image:: screenshot.png

This game is completely free. Just download the ROM, install a Game Boy Color
emulator, and play! The last release of the game should be here:

    https://github.com/AntonioND/ucity/releases

You can also play on real hardware. Even though the game has been developed
using mainly emulators, it has been verified to work on hardware. The game
detects how much available space there is and adjust the maximum number of saved
cities acordingly.

Manual
======

If needed, there is a short manual with instructions for the player
`here <manual.rst>`_.

Documentation
=============

An open-source project is a lot worse without documentation! That's why the code
has a lot of comments and why there is a highly detailed documentation
`here <docs/index.rst>`_. And also because assembly code without comments can't
be understood even by the developer who wrote it originally. :)

Compiling
=========

This game needs a really recent version of ``RGBDS`` to correctly assemble the
code. It is the only real dependency. This toolchain can be found here:

      https://github.com/rednex/rgbds/

Follow the instructions in that link to install it in your system.

Once the ``RGBDS`` binaries are installed in your system, assembling the game is
as simple as typing :code:`make` in a terminal.

If the binaries aren't installed in any system path, the variable ``RGBDS`` of
the Makefile has to point at the path where they are located:

:code:`make RGBDS=path/to/binaries/`

This should work on Linux, MinGW, Cygwin, etc. To remove all files that are
generated during the assembly process, type :code:`make clean`.

Tools
=====

- Open ModPlug Tracker

  This is just a program to edit tracker style music. It has been used to
  compose the music used by GBT Player.

    https://openmpt.org/

  GBT Player is my music player library. It is included in the code, and it can
  be found here if you want to use it for your projects:

    https://github.com/AntonioND/gbt-player

- GBTD (Game Boy Tile Designer) and GBMB (Game Boy Map Builder)

  Graphics edition tools (for Windows, but they run on Wine).

  Note that both of them can be found in this repository in the ``tools`` folder
  in case the following links are broken:

    http://www.devrs.com/gb/hmgd/gbmb.html

    http://www.devrs.com/gb/hmgd/gbtd.html

Credits
=======

Game made by AntonioND/SkyLyrac (Antonio Niño Díaz)

Email:

    antonio_nd@outlook.com

Web:

    https://github.com/AntonioND

    http://antoniond_blog.drunkencoders.com/

    http://antoniond.drunkencoders.com/

Thanks to:

- beware: For the emulator BGB (http://bgb.bircd.org/), extremely useful tool
  used to develop this game.

- Pan of Anthrox, Marat Fayzullin, Pascal Felber, Paul Robson, Martin Korth
  (nocash) and kOOPa for the pandocs.

- Otaku No Zoku (Justin Lloyd) for the Gameboy Crib Sheet.

- Everyone that has contributed to develop ``RGBDS`` over the years, specially
  Carsten Sorensen, Justin Lloyd, Vegard Nossum and Anthony J. Bentley.

License
=======

This game is licensed under the GPLv3+ license. You should have received the
source code of this game along with the ROM file. If not, the source code is
freely available at the following address:

    https://github.com/AntonioND/ucity

Not all source code files are licensed under the GPL v3+, though, only the ones
with the GPL header are. There other source files are licensed under different
terms (for example, GBT Player is licensed under the 2-clause BSD license).

The media files (graphics and music) are licensed under a Creative Commons
license (CC BY-SA 4.0).

GNU General Public License version 3+
=====================================

    µCity - City building game for Game Boy Color.
    Copyright (C) 2017 Antonio Niño Díaz (AntonioND/SkyLyrac)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Contact: antonio_nd@outlook.com

