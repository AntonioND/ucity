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

;###############################################################################

    SECTION "Minimap RCI Functions",ROMX

;-------------------------------------------------------------------------------

MINIMAP_RCI_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (31<<10)|(0<<5)|(0<<0)
    DW (0<<10)|(31<<5)|(31<<0), (0<<10)|(0<<5)|(0<<0)

MINIMAP_RCI_TITLE:
    DB O_A_UPPERCASE + "R" - "A"
    DB O_A_UPPERCASE + "C" - "A"
    DB O_A_UPPERCASE + "I" - "A"
    DB O_SPACE
    DB O_A_UPPERCASE + "Z" - "A"
    DB O_A_LOWERCASE + "o" - "a"
    DB O_A_LOWERCASE + "n" - "a"
    DB O_A_LOWERCASE + "e" - "a"
    DB O_A_LOWERCASE + "s" - "a"
    DB 0

MinimapDrawRCI::

    ; Draw title

    ld      hl,MINIMAP_RCI_TITLE
    call    RoomMinimapDrawTitle

    ; Load palette

    ld      hl,MINIMAP_RCI_PALETTE
    call   APA_LoadPalette

    ; Draw map

    LONG_CALL   APA_PixelStreamStart

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)

            LONG_CALL_ARGS  CityMapGetType ; Arguments: e = x , d = y

            ; Set color from tile type

            ; Flags have priority over type. Also, road > train > power

            bit     TYPE_HAS_ROAD_BIT,a
            jr      z,.not_road
                ld      a,3
                ld      b,3
                ld      c,3
                ld      d,3
                jr      .end_compare
.not_road:
            bit     TYPE_HAS_TRAIN_BIT,a
            jr      z,.not_train
                ld      a,0
                ld      b,3
                ld      c,3
                ld      d,0
                jr      .end_compare
.not_train:
            bit     TYPE_HAS_POWER_BIT,a
            jr      z,.not_power
                ld      a,0
                ld      b,2
                ld      c,2
                ld      d,0
                jr      .end_compare
.not_power:

            and     a,TYPE_MASK ; Get type without extra flags

            cp      a,TYPE_RESIDENTIAL
            jr      nz,.not_residential
                ld      a,2
                ld      b,1
                ld      c,1
                ld      d,2
                jr      .end_compare
.not_residential:
            cp      a,TYPE_INDUSTRIAL
            jr      nz,.not_industrial
                ld      a,2
                ld      b,2
                ld      c,2
                ld      d,2
                jr      .end_compare
.not_industrial:
            cp      a,TYPE_COMMERCIAL
            jr      nz,.not_commercial
                ld      a,1
                ld      b,1
                ld      c,1
                ld      d,1
                jr      .end_compare
.not_commercial:
            cp      a,TYPE_WATER
            jr      nz,.not_water
                ld      a,0
                ld      b,1
                ld      c,1
                ld      d,0
                jr      .end_compare
.not_water:
            cp      a,TYPE_DOCK
            jr      nz,.not_dock
                ld      a,0
                ld      b,1
                ld      c,1
                ld      d,0
                jr      .end_compare
.not_dock:
            ; Default
            xor     a,a
            ld      b,a
            ld      c,a
            ld      d,a
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

    ret

;###############################################################################
