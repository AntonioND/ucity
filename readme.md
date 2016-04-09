BitCity
=======

The open-source city building game for Game Boy Color.

Introduction
------------

This is a very early version of BitCity. As such, most of the functionality is
missing. The only finished part is the editor mode. This is not playable. This
is just the skeleton of the game it may become in a not so far away future.

General to do list:
- Budget screen
- Minimap screen (with different maps)
- Save menus
- Simulation

![](screenshot.png)

Controls
--------

- Start: Open pause menu.
- Select: Open building select menu.
- B: If held, fast scroll.

Credits
-------

Game made by AntonioND/SkyLyrac (Antonio Niño Díaz)

Email:  antonio_nd@outlook.com / antonionidi@gmail.com

Web:    http://antoniond_blog.drunkencoders.com/
        http://antoniond.drunkencoders.com/

GitHub: https://github.com/AntonioND

Dependencies:
- RGBDS: https://github.com/bentley/rgbds/
- GBT Player: https://github.com/AntonioND/gbt-player

Graphic Editors:
- GBMB (Game Boy Map Builder)
- GBTD (Game Boy Tile Designer)

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

