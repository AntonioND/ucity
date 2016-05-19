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

;###############################################################################

    SECTION "Simulation Traffic Functions",ROMX

;-------------------------------------------------------------------------------

; Checks bounds, returns a=0 if outside the map else a=value
Simulation_TrafficGetMapValue: ; d=y, e=x

    ld      a,e
    or      a,d
    and     a,128+64 ; ~63
    jr      z,.ok
    xor     a,a
    ret

.ok:
    ld      a,BANK_CITY_MAP_TRAFFIC
    ld      [rSVBK],a

    call    GetMapAddress
    ld      a,[hl]

    ret

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

    ; For each tile check if it is a residential building
    ; ---------------------------------------------------

    ; When a building is handled the rest of the tiles of it are flagged as
    ; handled, so we will only check the top left tile of each building.
    ; To flag a building as handled its density is set to 0. That way even R
    ; tiles are flagged as handled indirectly.

    ; The "amount of cars" that leave a residential building is the same as the
    ; TOP LEFT corner tile density. The same thing goes for the "amount of cars"
    ; that can get into another building. However, all tiles of a building
    ; should have the same density so that the density map makes sense.

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

            cp      a,TYPE_RESIDENTIAL
            jr      nz,.not_residential

                ; Residential building = Source of traffic

                ; Check if handled (density = 0). If so, skip

                ld      a,BANK_CITY_MAP_TRAFFIC
                ld      [rSVBK],a

                ld      a,[hl]
                and     a,a
                jr      z,.not_residential

                ; de = coordinates of top left corner of building
                LONG_CALL_ARGS  Simulation_TrafficHandleSource

.not_residential:

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

    ld      hl,CITY_MAP_FLAGS ; Base address of the map!

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)
        push    hl

            ld      a,BANK_CITY_MAP_FLAGS
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
