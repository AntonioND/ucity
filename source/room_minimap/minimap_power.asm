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

    INCLUDE "hardware.inc"
    INCLUDE "engine.inc"

;-------------------------------------------------------------------------------

    INCLUDE "room_game.inc"
    INCLUDE "text.inc"
    INCLUDE "building_density.inc"

;###############################################################################

    SECTION "Minimap Power Grid Map Functions",ROMX

;-------------------------------------------------------------------------------

C_WHITE EQU 0 ; Other tiles
C_GREEN EQU 1 ; Tile power OK
C_RED   EQU 2 ; Tile with no power. Mix of green and red -> Not all power
C_BLUE  EQU 3 ; Power plants

MINIMAP_POWER_GRID_MAP_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (0<<10)|(31<<5)|(0<<0)
    DW (0<<10)|(0<<5)|(31<<0), (31<<10)|(0<<5)|(0<<0)

MINIMAP_POWER_GRID_MAP_TITLE:
    DB "Power Grid",0

MinimapDrawPowerGridMap::

    ; Simulate and get data!
    ; ----------------------

    LONG_CALL   Simulation_PowerDistribution

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
            ; Returns a = type, hl = address
            call    CityMapGetType ; Arguments: e = x , d = y
            pop     de
            cp      a,TYPE_POWER_PLANT
            jr      nz,.not_power_plant
                ld      a,C_BLUE
                ld      b,a
                ld      c,a
                ld      d,a
                jr      .end_color
.not_power_plant:
            ld      a,BANK_SCRATCH_RAM
            ld      [rSVBK],a

            ld      b,[hl] ; b = current energy
            push    bc
            call    CityMapGetTileAtAddress ; hl=addr, returns tile=de
            call    CityTileDensity ; de = tile, returns d=population, e=energy
            pop     bc
            ; e = energy expected
            ; b = real energy there
            ld      a,e
            and     a,a
            jr      z,.nothing_expected_there

                ; Some energy expected. 3 cases:
                ; 1) No energy at all -> Red
                ; 2) Some energy -> Red/Green
                ; 3) All energy -> Green

                ld      a,b
                and     a,a ; Check real energy on tile
                jr      nz,.not_1
                    ; Case 1
                    ld      a,C_RED
                    ld      b,a
                    ld      c,a
                    ld      d,a
                    jr      .end_color
.not_1:
                ld      a,b
                cp      a,e ; Check if expected = real or not
                jr      z,.case_3
                    ; Case 2
                    ld      a,C_RED
                    ld      b,C_GREEN
                    ld      c,C_GREEN
                    ld      d,C_RED
                    jr      .end_color
.case_3:
                    ; Case 3
                    ld      a,C_GREEN
                    ld      b,a
                    ld      c,a
                    ld      d,a
                    jr      .end_color

.nothing_expected_there:

            ld      a,C_WHITE
            ld      a,b
            ld      a,c
            ld      a,d
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

MINIMAP_TILE_COLORS:
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
    DB "Power Density",0

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

            ld      de,MINIMAP_TILE_COLORS
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
