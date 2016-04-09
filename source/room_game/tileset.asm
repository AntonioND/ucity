;###############################################################################
;
;    BitCity - City building game for Game Boy Color.
;    Copyright (C) 2016 Antonio Nino Diaz (AntonioND/SkyLyrac)
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
;    Contact: antonio_nd@outlook.com
;
;###############################################################################

    SECTION "City Tileset",ROMX

;-------------------------------------------------------------------------------

CITY_TILESET::
    INCBIN "data/city_tiles.bin"

CITY_TILESET_PALETTES:: ; Same bank as CITY_TILESET!
    DW (31<<10)|(31<<5)|(31<<0), (10<<10)|(31<<5)|(10<<0)
    DW (1<<10)|(16<<5)|(3<<0), (0<<10)|(3<<5)|(6<<0)

    DW (31<<10)|(31<<5)|(31<<0), (31<<10)|(31<<5)|(0<<0)
    DW (31<<10)|(0<<5)|(0<<0), (0<<10)|(0<<5)|(0<<0)

    DW (31<<10)|(31<<5)|(31<<0), (0<<10)|(31<<5)|(31<<0)
    DW (0<<10)|(15<<5)|(31<<0), (0<<10)|(0<<5)|(0<<0)

    DW (31<<10)|(31<<5)|(31<<0), (0<<10)|(31<<5)|(28<<0)
    DW (5<<10)|(20<<5)|(31<<0), (0<<10)|(12<<5)|(17<<0)

    DW (31<<10)|(31<<5)|(31<<0), (10<<10)|(31<<5)|(10<<0)
    DW (5<<10)|(15<<5)|(5<<0), (0<<10)|(0<<5)|(0<<0)

    DW (31<<10)|(31<<5)|(31<<0), (0<<10)|(15<<5)|(31<<0)
    DW (0<<10)|(0<<5)|(31<<0), (0<<10)|(0<<5)|(0<<0)

    DW 0,0,0,0

    DW (31<<10)|(31<<5)|(31<<0), (21<<10)|(21<<5)|(21<<0)
    DW (10<<10)|(10<<5)|(10<<0), (0<<10)|(0<<5)|(0<<0)

;###############################################################################
