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

;###############################################################################

    SECTION "Fire Helper Variables",HRAM

;-------------------------------------------------------------------------------

; For a map created by a sane person this should reasonably be 1-16 (?) but it
; can actually go over 255, so the count saturates to 255.
initial_number_fire_stations: DS 1

;###############################################################################

    SECTION "Simulation Fire Functions",ROMX

;-------------------------------------------------------------------------------

; Output data to WRAMX bank BANK_SCRATCH_RAM
Simulation_Fire::

    ; This should only be called during disaster mode!

    ; Clear
    ; -----

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    call    ClearWRAMX

    ; For each tile check if it is type TYPE_FIRE
    ; -------------------------------------------

    ld      hl,CITY_MAP_TYPE ; Map base

    ld      d,0 ; y
.loopy:
        ld      e,0 ; x
.loopx:
        push    de
        push    hl

            ; TODO

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

Simulation_FireAnimate:: ; This doesn't refresh tile map!

    ld      hl,CITY_MAP_TILES ; Map base

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

.loop:

        ld      a,[hl] ; Get type

        cp      a,TYPE_FIRE
        jr      nz,.not_fire

            ld      a,BANK_CITY_MAP_TILES
            ld      [rSVBK],a

; Actually, this could check if T_FIRE_1 is greater than 255 or T_FIRE_2 is
; lower than 256.
IF ( (T_FIRE_1 % 2) != 0 ) || ( (T_FIRE_1 + 1) != T_FIRE_2 ) || (T_FIRE_1 < 256)
    FAIL "Invalid tile number for fire tiles."
ENDC

            ld      a,1 ; T_FIRE_1 must be even, T_FIRE_2 must be odd.
            xor     a,[hl] ; They must use the same palette
            ld      [hl],a

            ld      a,BANK_CITY_MAP_TYPE
            ld      [rSVBK],a

.not_fire:

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

;-------------------------------------------------------------------------------

Simulation_FireTryStart::

    ld      a,[simulation_disaster_mode]
    and     a,a
    ret     nz ; Don't start a fire if there is already a fire

    ret ; TODO: Remove

    ; Check if a fire has to start or not
    ; -----------------------------------


    ; Count number of fire stations and save it
    ; -----------------------------------------

    ; Remove all traffic tiles from the map, as well as other animations
    ; ------------------------------------------------------------------

    LONG_CALL   Simulation_TrafficRemoveAnimationTiles

    ; TODO : Remove trains, planes, etc

    ; Enable disaster mode
    ; --------------------

    ret

;###############################################################################
