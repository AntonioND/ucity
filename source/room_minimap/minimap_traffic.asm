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

    SECTION "Minimap Traffic Map Functions",ROMX

;-------------------------------------------------------------------------------

    DEF C_WHITE  EQU 0 ; Other tiles (not road nor train)
    DEF C_GREEN  EQU 1 ; Levels of traffic
    DEF C_YELLOW EQU 2
    DEF C_RED    EQU 3

MINIMAP_TRAFFIC_TILE_COLORS:
    DB 1,1,1,1
    DB 1,1,1,1
    DB 1,2,2,1
    DB 2,2,2,2
    DB 2,2,2,2
    DB 2,3,3,2
    DB 3,3,3,3
    DB 3,3,3,3

MINIMAP_TRAFFIC_MAP_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (0<<10)|(31<<5)|(0<<0)
    DW (0<<10)|(15<<5)|(31<<0), (0<<10)|(0<<5)|(31<<0)

MINIMAP_TRAFFIC_MAP_TITLE:
    STR_ADD "Traffic"

MinimapDrawTrafficMap::

    ; Traffic is simulated in real time and stored in BANK_CITY_MAP_TRAFFIC,
    ; so no need to simulate anything here.

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

            ld      a,BANK_CITY_MAP_TYPE
            ldh     [rSVBK],a
            ld      a,[hl] ; Get type

            ld      b,a
            and     a,TYPE_HAS_ROAD|TYPE_HAS_TRAIN
            ld      a,b
            jr      nz,.has_road_or_train

                ; Tile doesn't have road or train

                ; Check if this is a building. If so, draw as a green pattern if
                ; all cars could leave/arrive, otherwise draw it red.

                ld      a,b
                and     a,TYPE_MASK

                cp      a,TYPE_FIELD
                jr      z,.tile_empty
                cp      a,TYPE_FOREST
                jr      z,.tile_empty
                cp      a,TYPE_WATER
                jr      z,.tile_empty
                cp      a,TYPE_DOCK
                jr      z,.tile_empty

                    push    de
                    push    hl
                    ; de = coordinates of one tile, returns de = coordinates of
                    ; the origin
                    call    BuildingGetCoordinateOrigin

                    ; get origin coordinates into hl
                    GET_MAP_ADDRESS ; Preserves DE

                    ld      a,BANK_CITY_MAP_TRAFFIC
                    ldh     [rSVBK],a

                    ld      a,[hl]

                    pop     hl
                    pop     de

                    and     a,a ; If remaining density is 0, building is ok
                    jr      z,.building_ok

                        ; Building not ok
                        ld      a,C_WHITE
                        ld      b,C_RED
                        ld      c,C_RED
                        ld      d,C_WHITE
                        jr      .end_color

.building_ok:
                        ; Building ok
                        ld      a,C_WHITE
                        ld      b,C_GREEN
                        ld      c,C_GREEN
                        ld      d,C_WHITE
                        jr      .end_color

.tile_empty:
                    ld      a,C_WHITE
                    ld      b,a
                    ld      c,a
                    ld      d,a
                    jr      .end_color

.has_road_or_train:

                ; Has road or train
                ld      a,BANK_CITY_MAP_TRAFFIC
                ldh     [rSVBK],a
                ld      a,[hl] ; get traffic density

                swap    a
                and     a,15 ; 8 bits to 4 bits
                bit     3,a
                jr      z,.val_0_to_7
                ld      a,7 ; saturate to 7
.val_0_to_7:

                ld      de,MINIMAP_TRAFFIC_TILE_COLORS
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
    ld      hl,MINIMAP_TRAFFIC_MAP_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_TRAFFIC_MAP_TITLE
    call    RoomMinimapDrawTitle

    ret

;###############################################################################
