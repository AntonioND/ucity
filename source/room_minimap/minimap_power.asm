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

    SECTION "Minimap Power Grid Map Functions",ROMX

;-------------------------------------------------------------------------------

    ; Everything over this value is saturated and will be displayed with the
    ; same color.
    DEF MAX_DISPLAYABLE_POWER_DENSITY      EQU 14

;-------------------------------------------------------------------------------

    DEF C_WHITE EQU 0 ; Other tiles
    DEF C_GREEN EQU 1 ; Tile power OK
    DEF C_RED   EQU 2 ; Tile with not enough power
    DEF C_BLUE  EQU 3 ; Power plants

MINIMAP_POWER_GRID_MAP_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (0<<10)|(31<<5)|(0<<0)
    DW (0<<10)|(0<<5)|(31<<0), (31<<10)|(0<<5)|(0<<0)

MINIMAP_POWER_GRID_MAP_TITLE:
    STR_ADD "Power Grid"

MinimapDrawPowerGridMap::

    ; No need to simulate, get data from CITY_MAP_FLAGS

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
            cp      a,TYPE_POWER_PLANT
            jr      nz,.not_power_plant
                ld      a,C_BLUE
                ld      b,a
                ld      c,a
                ld      d,a
                jr      .end_color
.not_power_plant:

            ; Check if any energy is expected
            push    hl
            call    CityMapGetTileAtAddress ; hl=addr, returns tile=de
            call    CityTileDensity ; de = tile, returns d=population, e=energy
            pop     hl
            ; e = energy expected
            ld      a,e
            and     a,a
            jr      z,.nothing_expected_there

            ; Energy expected!
            ld      a,BANK_CITY_MAP_FLAGS
            ldh     [rSVBK],a

            ld      a,[hl] ; b = current energy
            bit     TILE_OK_POWER_BIT,a
            jr      nz,.enough_power

                ; Not enough power
                ld      a,C_RED
                ld      b,a
                ld      c,a
                ld      d,a
                jr      .end_color
.enough_power:

                ; Enough power
                ld      a,C_GREEN
                ld      b,a
                ld      c,a
                ld      d,a
                jr      .end_color

.nothing_expected_there:

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
    ld      hl,MINIMAP_POWER_GRID_MAP_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_POWER_GRID_MAP_TITLE
    call    RoomMinimapDrawTitle

    ret

;-------------------------------------------------------------------------------

MINIMAP_TILE_COLORS_POWER:
    DB 0,0,0,0
    DB 0,1,1,0
    DB 1,1,1,1
    DB 1,2,2,1
    DB 2,2,2,2
    DB 2,3,3,2
    DB 2,3,3,2
    DB 2,3,3,2

MINIMAP_POWER_DENSITY_MAP_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (0<<10)|(31<<5)|(31<<0)
    DW (0<<10)|(15<<5)|(31<<0), (0<<10)|(0<<5)|(31<<0)

MINIMAP_POWER_DENSITY_MAP_TITLE:
    STR_ADD "Power Density"

MinimapDrawPowerDensityMap::

    ; No need to simulate, this will use the expected power density

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

            push    de
            ; returns type = a, address = hl
            call    CityMapGetType ; Arguments: e = x , d = y
            pop     de
            cp      a,TYPE_POWER_PLANT
            jr      nz,.not_power_plant
                ld      a,3
                ld      b,a
                ld      c,a
                ld      d,a
                jr      .end_color
.not_power_plant:

            call    CityMapGetTileAtAddress ; hl=addr, returns tile=de
            call    CityTileDensity ; de = tile, returns d=population, e=energy
            ld      a,e ; a = energy expected

            cp      a,MAX_DISPLAYABLE_POWER_DENSITY+1 ; Saturate
            jr      c,.not_overflow
            ld      a,MAX_DISPLAYABLE_POWER_DENSITY
.not_overflow:

IF MAX_DISPLAYABLE_POWER_DENSITY != 14
    FAIL "Fix this!"
ENDC
            inc     a ; Round up
            sra     a ; From 4 bits to 3 (15 -> 7)

            ld      de,MINIMAP_TILE_COLORS_POWER
            ld      l,a
            ld      h,0
            add     hl,hl
            add     hl,hl ; a *= 4
            add     hl,de

            ld      a,[hl+]
            ld      b,[hl]
            inc     hl
            ld      c,[hl]
            inc     hl
            ld      d,[hl]

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
    ld      hl,MINIMAP_POWER_DENSITY_MAP_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_POWER_DENSITY_MAP_TITLE
    call    RoomMinimapDrawTitle

    ret

;###############################################################################
