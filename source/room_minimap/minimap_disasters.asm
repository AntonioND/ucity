;###############################################################################
;
;    µCity - City building game for Game Boy Color.
;    Copyright (c) 2017-2018 Antonio Niño Díaz (AntonioND/SkyLyrac)
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

    INCLUDE "hardware.inc"
    INCLUDE "engine.inc"

;-------------------------------------------------------------------------------

    INCLUDE "room_game.inc"
    INCLUDE "text.inc"

;###############################################################################

    SECTION "Minimap Disasters Map Functions",ROMX

;-------------------------------------------------------------------------------

    DEF C_WHITE EQU 0 ; Other tiles
    DEF C_GREEN EQU 1 ; Vegetation, burnable things...
    DEF C_RED   EQU 2 ; Fire
    DEF C_BLUE  EQU 3 ; Water

MINIMAP_DISASTERS_MAP_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (0<<10)|(31<<5)|(0<<0)
    DW (0<<10)|(0<<5)|(31<<0), (31<<10)|(0<<5)|(0<<0)

MINIMAP_DISASTERS_MAP_TITLE:
    STR_ADD "Disasters"

MinimapDrawDisastersMap::

    ; No need to simulate

    ; Draw map
    ; --------

    LONG_CALL   APA_PixelStreamStart

    ld      hl,CITY_MAP_TILES ; Base address of the map!

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)
        push    hl

            ; Returns a = type, hl = address
            call    CityMapGetType ; Arguments: e = x , d = y
            cp      a,TYPE_FIRE
            jr      nz,.not_fire
                ld      a,C_RED
                ld      b,a
                ld      c,a
                ld      d,a
                jr      .end_color
.not_fire:

            bit     TYPE_HAS_POWER_BIT,a
            jr      nz,.not_water ; Only power line bridges are burnable!

            and     a,TYPE_MASK
            cp      a,TYPE_WATER
            jr      nz,.not_water
                ld      a,C_BLUE
                ld      b,a; C_WHITE
                ld      c,a; C_WHITE
                ld      d,C_BLUE
                jr      .end_color
.not_water:

            ; Check if this is burnable or not
            push    hl
            call    CityMapGetTileAtAddress ; hl=addr, returns tile=de
            call    CityTileFireProbability ; de = tile, ret d = probability
            pop     hl

            ld      a,d
            and     a,a
            jr      z,.not_burnable

                ; Enough power
                ld      a,C_GREEN
                ld      b,a ;C_WHITE
                ld      c,a ; C_WHITE
                ld      d,C_GREEN
                jr      .end_color

.not_burnable:

            ld      a,C_WHITE
            ld      b,a
            ld      c,a
            ld      d,a
.end_color:

            call    APA_SetColors ; a,b,c,d = color (0 to 3)
            LONG_CALL   APA_PixelStreamPlot2x2

        pop     hl
        pop     de ; (*)

        inc     hl

        inc     e
        bit     6,e
        jp      z,.loopx

    inc     d
    bit     6,d
    jp      z,.loopy

    ; Set White
    call    MinimapSetDefaultPalette

    ; Refresh screen with backbuffer data
    call    APA_BufferUpdate

    ; Load palette
    ld      hl,MINIMAP_DISASTERS_MAP_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_DISASTERS_MAP_TITLE
    call    RoomMinimapDrawTitle

    ret

;###############################################################################
