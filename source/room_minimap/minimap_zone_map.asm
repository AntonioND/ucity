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

    SECTION "Minimap Zone Map Functions",ROMX

;-------------------------------------------------------------------------------

    DEF C_WHITE  EQU 0
    DEF C_BLUE   EQU 1
    DEF C_GREEN  EQU 2
    DEF C_YELLOW EQU 3

MINIMAP_ZONE_MAP_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (31<<10)|(0<<5)|(0<<0)
    DW (0<<10)|(31<<5)|(0<<0), (0<<10)|(31<<5)|(31<<0)

MINIMAP_ZONE_MAP_TYPE_COLOR_ARRAY:
    DB C_WHITE, C_WHITE, C_WHITE, C_WHITE  ; TYPE_FIELD
    DB C_GREEN, C_WHITE, C_WHITE, C_GREEN  ; TYPE_FOREST
    DB C_BLUE,  C_WHITE, C_WHITE, C_BLUE   ; TYPE_WATER
    DB C_GREEN, C_GREEN, C_GREEN, C_GREEN  ; TYPE_RESIDENTIAL
    DB C_YELLOW,C_YELLOW,C_YELLOW,C_YELLOW ; TYPE_INDUSTRIAL
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE   ; TYPE_COMMERCIAL
    DB C_GREEN, C_YELLOW,C_BLUE,  C_GREEN  ; TYPE_POLICE_DEPT
    DB C_GREEN, C_YELLOW,C_BLUE,  C_GREEN  ; TYPE_FIRE_DEPT
    DB C_GREEN, C_YELLOW,C_BLUE,  C_GREEN  ; TYPE_HOSPITAL
    DB C_GREEN, C_YELLOW,C_BLUE,  C_GREEN  ; TYPE_PARK
    DB C_GREEN, C_YELLOW,C_BLUE,  C_GREEN  ; TYPE_STADIUM
    DB C_GREEN, C_YELLOW,C_BLUE,  C_GREEN  ; TYPE_SCHOOL
    DB C_GREEN, C_YELLOW,C_BLUE,  C_GREEN  ; TYPE_HIGH_SCHOOL
    DB C_GREEN, C_YELLOW,C_BLUE,  C_GREEN  ; TYPE_UNIVERSITY
    DB C_GREEN, C_YELLOW,C_BLUE,  C_GREEN  ; TYPE_MUSEUM
    DB C_GREEN, C_YELLOW,C_BLUE,  C_GREEN  ; TYPE_LIBRARY
    DB C_GREEN, C_YELLOW,C_BLUE,  C_GREEN  ; TYPE_AIRPORT
    DB C_GREEN, C_YELLOW,C_BLUE,  C_GREEN  ; TYPE_PORT
    DB C_BLUE,  C_YELLOW,C_YELLOW,C_BLUE   ; TYPE_DOCK
    DB C_GREEN, C_YELLOW,C_BLUE,  C_GREEN  ; TYPE_POWER_PLANT
    DB C_WHITE, C_WHITE, C_WHITE, C_WHITE  ; TYPE_FIRE - Placeholder, never used
    DB C_WHITE, C_WHITE, C_WHITE, C_WHITE  ; TYPE_RADIATION

MINIMAP_ZONE_MAP_TITLE:
    STR_ADD "Zone Map"

;-------------------------------------------------------------------------------

MinimapDrawZoneMap::

    ; Draw map
    ; --------

    LONG_CALL   APA_PixelStreamStart

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)

            call    CityMapGetType ; Arguments: e = x , d = y

            ; Set color from tile type

            and     a,TYPE_MASK ; Get type without extra flags
            ld      l,a
            ld      h,0
            add     hl,hl
            add     hl,hl
            ld      de,MINIMAP_ZONE_MAP_TYPE_COLOR_ARRAY
            add     hl,de
            ld      a,[hl+]
            ld      b,[hl]
            inc     hl
            ld      c,[hl]
            inc     hl
            ld      d,[hl]

            call    APA_SetColors ; a,b,c,d = color (0 to 3)
            LONG_CALL   APA_PixelStreamPlot2x2

        pop     de ; (*)

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
    ld      hl,MINIMAP_ZONE_MAP_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_ZONE_MAP_TITLE
    call    RoomMinimapDrawTitle

    ret

;###############################################################################
