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
    INCLUDE "tileset_info.inc"
    INCLUDE "building_density.inc"

;###############################################################################

    SECTION "Simulation Traffic Functions",ROMX

;-------------------------------------------------------------------------------

; Output data to WRAMX bank BANK_CITY_MAP_TRAFFIC
Simulation_Traffic::

    ; Clear
    ; -----

    ld      a,BANK_CITY_MAP_TRAFFIC
    ld      [rSVBK],a

    ld      bc,$1000
    ld      d,0
    ld      hl,CITY_MAP_TRAFFIC
    call    memset

    ; For each tile check if it is a road
    ; -----------------------------------

    ld      hl,CITY_MAP_TRAFFIC ; Map base

    ld      d,0 ; y
.loopy:
        ld      e,0 ; x
.loopx:
        push    de
        push    hl

            ld      a,BANK_CITY_MAP_TYPE
            ld      [rSVBK],a
            ld      a,[hl] ; Get type

            bit     TYPE_HAS_ROAD_BIT,a
            jr      z,.not_road

                ; Road. Handle traffic

.not_road:

        pop     hl
        pop     de

        inc     hl

        inc     e
        ld      a,CITY_MAP_WIDTH
        cp      a,e
        jr      nz,.loopx

    inc     d
    ld      a,CITY_MAP_HEIGHT
    cp      a,d
    jr      nz,.loopy

    ret

;-------------------------------------------------------------------------------

Simulation_TrafficSetTileOkFlag::

    ; NOTE: Don't call when drawing minimaps, this can only be called from the
    ; simulation loop!

    ; - For roads, make sure that the traffic is below a certain threshold.
    ; - For buildings, make sure that all people could get out of residential
    ; zones, and that commercial zones and industrial zones could be reached
    ; by all people.

    ld      hl,CITY_MAP_TILE_OK_FLAGS ; Base address of the map!

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)
        push    hl

            ld      a,BANK_CITY_MAP_TILE_OK_FLAGS
            ld      [rSVBK],a
            res     TILE_OK_TRAFFIC_BIT,[hl]

        pop     hl
        pop     de ; (*)

        inc     hl

        inc     e
        bit     6,e
        jp      z,.loopx

    inc     d
    bit     6,d
    jp      z,.loopy

    ret

;###############################################################################
