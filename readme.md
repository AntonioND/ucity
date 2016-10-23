BitCity
=======

The open-source city building game for Game Boy Color.

Introduction
------------

This is a beta version of BitCity. As such, some of the functionality is
missing. This is not playable yet, but it's almost there.

It is developed using BGB (http://bgb.bircd.org/), and it's tested on hardware
every once in a while.

NOTE: I'm looking for a good pixel artist to help me with the game graphics. If
you are interested please contact me at my email (antonio_nd@outlook.com).

General to do list:
- Simulation - Most parts are ready
  - Graphical output (trains, planes, boats...)
- Sample cities (compressed)
- Loans
- Music, SFX
- Improve graphics
- Cleanup code and document

![](screenshot.png)

Controls
--------

- Start: Open pause menu.
- Select: Open building select menu.
- B: If held, fast scroll.

Credits
-------

Game made by AntonioND/SkyLyrac (Antonio Niño Díaz)

Email: antonio_nd@outlook.com / antonionidi@gmail.com

Web:
- http://antoniond_blog.drunkencoders.com/
- http://antoniond.drunkencoders.com/

GitHub: https://github.com/AntonioND

Dependencies:
- RGBDS: https://github.com/bentley/rgbds/

It uses GBT Player, my music player library. It is not needed to install it as
it comes with the game code, but it can be found here if you want to use it
for your projects:
- https://github.com/AntonioND/gbt-player

Tools (for Windows, but they run on Wine):
- GBMB (Game Boy Map Builder): http://www.devrs.com/gb/hmgd/gbmb.html
- GBTD (Game Boy Tile Designer): http://www.devrs.com/gb/hmgd/gbtd.html

Compiling
---------

The Makefile has to be edited to point the RGBDS binaries. Then, open the
console and type `make rebuild`. This should work on Linux, MinGW, Cygwin, etc.

License
-------

This game is licensed under the GPL v3 license. You may have received the source
code of this game along with the ROM file. If not, the source code is freely
available at the following address:

    https://github.com/AntonioND/bitcity

Not all source code files are licensed under the GPL v3, though, only the ones
with the GPL header are. There other source files are licensed under different
terms (for example, GBT Player is licensed under the 2-clause BSD license).

The media files (graphics and music) are licensed under a Creative Commons
license (CC BY-SA 4.0).

GPL v3
------

    BitCity - City building game for Game Boy Color.
    Copyright (C) 2016 Antonio Nino Diaz (AntonioND/SkyLyrac)

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

