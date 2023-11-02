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

    SECTION "Minimap Happiness Map Functions",ROMX[$4000]

;-------------------------------------------------------------------------------

    DEF C_WHITE  EQU 0 ; Not a building
    DEF C_GREEN  EQU 1 ; All desired and needed flags ok
    DEF C_YELLOW EQU 2 ; Needed flags ok, desired flags not ok
    DEF C_RED    EQU 3 ; Not even the needed flags ok

MINIMAP_HAPPINESS_MAP_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (0<<10)|(31<<5)|(0<<0)
    DW (0<<10)|(31<<5)|(31<<0), (0<<10)|(0<<5)|(31<<0)

MINIMAP_HAPPINESS_MAP_TITLE:
    STR_ADD "Happiness"

MinimapDrawHappinessMap::

    ; No need to simulate, get data from CITY_MAP_FLAGS

    ; Draw map
    ; --------

    LONG_CALL   APA_PixelStreamStart

    ld      hl,CITY_MAP_TILES ; Base address of the map!

.loop:

    push    hl

        ld      a,BANK_CITY_MAP_TYPE
        ldh     [rSVBK],a

        ld      a,[hl] ; get type

        ld      d,a
        and     a,TYPE_FLAGS_MASK
        ld      a,d
        jr      z,.no_type_flags

        ; Some type flags. Load the desired flags to register B and the needed
        ; ones to register C

        ld      bc,$0000

        ld      d,a
        and     a,TYPE_HAS_ROAD|TYPE_HAS_TRAIN
        ld      a,d
        jr      z,.no_traffic
            ld      b,TILE_OK_TRAFFIC ; Desired
            ld      c,b ; Needed
.no_traffic:

        ld      d,a
        and     a,TYPE_HAS_POWER
        ld      a,d
        jr      z,.no_power
            ld      a,b
            or      a,TILE_OK_POWER
            ld      b,a ; Desired
            ld      c,b ; Needed
.no_power:

        jr      .check_flags

.no_type_flags:

        ; No type flags. Load desired and needed flags from the array.

        cp      a,TYPE_FIELD ; Not buildings, don't care...
        jr      z,.not_a_building
        cp      a,TYPE_FOREST
        jr      z,.not_a_building
        cp      a,TYPE_WATER
        jr      z,.not_a_building
        jr      .is_a_building
.not_a_building:

            ; Not a building here
            ld      a,C_WHITE
            jr      .paint_tile

.is_a_building

        push    hl

            ld      hl,.needed_flags_info
            ld      e,a
            ld      d,0
            add     hl,de
            add     hl,de
            ld      a,[hl+]
            ld      b,a ; b = desired flags
            ld      c,[hl] ; c = needed flags

        pop     hl

.check_flags:

        ; Register B = desired flags. Register C = needed flags

        ld      a,BANK_CITY_MAP_FLAGS
        ldh     [rSVBK],a

        ld      a,[hl] ; get flags
        and     a,TILE_OK_MASK

        ld      d,a ; save flags in D

        ; Check if we have the needed flags
        and     a,c
        cp      a,c

        ld      a,d ; restore flags

        jr      z,.needed_flags_ok

            ; Needed flags not ok
            ld      a,C_RED
            jr      .paint_tile

.needed_flags_ok:

        ; Check if we have the desired flag
        and     a,b
        cp      a,b
        jr      z,.desired_flags_ok

            ; Desired flags not ok
            ld      a,C_YELLOW
            jr      .paint_tile

.desired_flags_ok:

        ; Desired and needed flags ok
        ld      a,C_GREEN
        ;jr      .paint_tile

.paint_tile:

        ld      b,a
        ld      c,a
        ld      d,a

        call    APA_SetColors ; a,b,c,d = color (0 to 3)
        LONG_CALL   APA_PixelStreamPlot2x2

    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ; Set White
    call    MinimapSetDefaultPalette

    ; Refresh screen with backbuffer data
    call    APA_BufferUpdate

    ; Load palette
    ld      hl,MINIMAP_HAPPINESS_MAP_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_HAPPINESS_MAP_TITLE
    call    RoomMinimapDrawTitle

    ret

; Flags: Power | Services | Education | Pollution | Traffic

    DEF FPOW EQU TILE_OK_POWER
    DEF FSER EQU TILE_OK_SERVICES
    DEF FEDU EQU TILE_OK_EDUCATION
    DEF FPOL EQU TILE_OK_POLLUTION
    DEF FTRA EQU TILE_OK_TRAFFIC

.needed_flags_info: ; Desired flags | Needed flags
; The needed flags must be a subset of the desired ones
    DB  0, 0 ; TYPE_FIELD - Not buildings, don't care...
    DB  0, 0 ; TYPE_FOREST
    DB  0, 0 ; TYPE_WATER
    DB  FPOW|FSER|FEDU|FPOL|FTRA, FPOW|FPOL|FTRA ; TYPE_RESIDENTIAL
    DB  FPOW|FSER|FTRA, FPOW|FTRA ; TYPE_INDUSTRIAL
    DB  FPOW|FSER|FPOL|FTRA, FPOW|FPOL|FTRA ; TYPE_COMMERCIAL
    DB  FPOW|FSER|FPOL|FTRA, FPOW ; TYPE_POLICE_DEPT
    DB  FPOW|FSER|FPOL|FTRA, FPOW ; TYPE_FIRE_DEPT
    DB  FPOW|FSER|FPOL|FTRA, FPOW ; TYPE_HOSPITAL
    DB  FPOW|FSER|FPOL|FTRA, FPOW ; TYPE_PARK
    DB  FPOW|FSER|FPOL|FTRA, FPOW|FPOL ; TYPE_STADIUM
    DB  FPOW|FSER|FPOL|FTRA, FPOW|FPOL ; TYPE_SCHOOL
    DB  FPOW|FSER|FPOL|FTRA, FPOW|FPOL ; TYPE_HIGH_SCHOOL
    DB  FPOW|FSER|FPOL|FTRA, FPOW|FPOL ; TYPE_UNIVERSITY
    DB  FPOW|FSER|FPOL|FTRA, FPOW|FPOL ; TYPE_MUSEUM
    DB  FPOW|FSER|FPOL|FTRA, FPOW|FPOL ; TYPE_LIBRARY
    DB  FPOW|FSER|FTRA, FPOW|FSER ; TYPE_AIRPORT
    DB  FPOW|FSER|FTRA, FPOW|FSER ; TYPE_PORT
    DB  FPOW|FSER, FPOW ; TYPE_DOCK
    DB  FSER|FTRA, 0 ; TYPE_POWER_PLANT
    DB  0, 0 ; TYPE_FIRE - Placeholder, never used.
    DB  0, 0 ; TYPE_RADIATION
    ; End of valid types

;###############################################################################
