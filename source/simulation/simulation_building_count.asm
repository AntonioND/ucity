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

    SECTION "Simulation Count Buildings Variables",WRAM0

;-------------------------------------------------------------------------------

; The values are clamped to 255

COUNT_AIRPORTS::        DS 1
COUNT_FIRE_STATIONS::   DS 1

;###############################################################################

    SECTION "Simulation Count Buildings Functions",ROMX

;-------------------------------------------------------------------------------

; Call this function whenever a building is built or demolished. For example, it
; has to be called after exiting edit mode, after a fire is finally extinguished
    ; or simply when the map is loaded.
Simulation_CountBuildings::

    xor     a,a
    ld      [COUNT_AIRPORTS],a
    ld      [COUNT_FIRE_STATIONS],a

    ; Count the number of airports. The total number of planes is equal to the
    ; number of airports * 2 up to a max of SIMULATION_MAX_PLANES.

    ld      c,0 ; number of airports

    ld      hl,CITY_MAP_TILES

.loop:
    push    hl

        ; Returns: - Tile -> Register DE
        call    CityMapGetTileAtAddress ; Arg: hl = address. Preserves BC, HL

CHECK_TILE : MACRO ; 1 = Tile number, 2 = Variable to increase

        ld      a,(\1)&$FF
        cp      a,e
        jr      nz,.end\@
        ld      a,(\1)>>8
        cp      a,d
        jr      nz,.end\@
            ld      a,[\2]
            inc     a
            jr      z,.end\@ ; skip store if it overflows
                ld      [\2],a
.end\@:

ENDM

        CHECK_TILE  T_AIRPORT, COUNT_AIRPORTS
        CHECK_TILE  T_FIRE_DEPT, COUNT_FIRE_STATIONS

        ; TODO - Count train tracks

    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

;###############################################################################
