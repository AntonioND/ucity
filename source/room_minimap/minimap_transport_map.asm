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

    SECTION "Minimap Transport Map Functions",ROMX

;-------------------------------------------------------------------------------

    DEF C_WHITE  EQU 0
    DEF C_BLUE   EQU 1
    DEF C_RED    EQU 2
    DEF C_BLACK  EQU 3

MINIMAP_TRANSPORT_MAP_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (31<<10)|(0<<5)|(0<<0)
    DW (0<<10)|(0<<5)|(31<<0), (0<<10)|(0<<5)|(0<<0)

MINIMAP_TRANSPORT_MAP_TYPE_COLOR_ARRAY:
    DB C_WHITE, C_WHITE, C_WHITE, C_WHITE ; TYPE_FIELD
    DB C_WHITE, C_WHITE, C_WHITE, C_WHITE ; TYPE_FOREST
    DB C_BLUE,  C_WHITE, C_WHITE, C_BLUE  ; TYPE_WATER
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_RESIDENTIAL
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_INDUSTRIAL
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_COMMERCIAL
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_POLICE_DEPT
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_FIRE_DEPT
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_HOSPITAL
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_PARK
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_STADIUM
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_SCHOOL
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_HIGH_SCHOOL
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_UNIVERSITY
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_MUSEUM
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_LIBRARY
    DB C_BLACK, C_RED,   C_RED,   C_BLACK ; TYPE_AIRPORT
    DB C_BLACK, C_RED,   C_RED,   C_BLACK ; TYPE_PORT
    DB C_RED,   C_BLUE,  C_BLUE,  C_RED   ; TYPE_DOCK
    DB C_BLUE,  C_BLUE,  C_BLUE,  C_BLUE  ; TYPE_POWER_PLANT
    DB C_WHITE, C_WHITE, C_WHITE, C_WHITE ; TYPE_FIRE - Placeholder, never used
    DB C_WHITE, C_WHITE, C_WHITE, C_WHITE ; TYPE_RADIATION

MINIMAP_TRANSPORT_MAP_TITLE:
    STR_ADD "Transport"

;-------------------------------------------------------------------------------

MinimapDrawTransportMap::

    ; Draw map
    ; --------

    LONG_CALL   APA_PixelStreamStart

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)

            LONG_CALL_ARGS  CityMapGetType ; Arguments: e = x , d = y

            ; Set color from tile type

            ; Flags have priority over type.

            ld      d,a
            and     a,TYPE_HAS_ROAD|TYPE_HAS_TRAIN
            cp      a,TYPE_HAS_ROAD|TYPE_HAS_TRAIN
            ld      a,d
            jr      nz,.not_rt
                ld      a,C_BLACK
                ld      b,C_RED
                ld      c,C_RED
                ld      d,C_BLACK
                jr      .end_compare
.not_rt:

            bit     TYPE_HAS_ROAD_BIT,a
            jr      z,.not_road
                ld      a,C_BLACK
                ld      b,C_BLACK
                ld      c,C_BLACK
                ld      d,C_BLACK
                jr      .end_compare
.not_road:

            bit     TYPE_HAS_TRAIN_BIT,a
            jr      z,.not_train
                ld      a,C_RED
                ld      b,C_RED
                ld      c,C_RED
                ld      d,C_RED
                jr      .end_compare
.not_train:

            and     a,TYPE_MASK ; Get type without extra flags
            ld      l,a
            ld      h,0
            add     hl,hl
            add     hl,hl
            ld      de,MINIMAP_TRANSPORT_MAP_TYPE_COLOR_ARRAY
            add     hl,de
            ld      a,[hl+]
            ld      b,[hl]
            inc     hl
            ld      c,[hl]
            inc     hl
            ld      d,[hl]
.end_compare:

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
    ld      hl,MINIMAP_TRANSPORT_MAP_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_TRANSPORT_MAP_TITLE
    call    RoomMinimapDrawTitle

    ret

;###############################################################################
