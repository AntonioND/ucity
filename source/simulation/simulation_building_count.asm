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
COUNT_PORTS::           DS 1
COUNT_FIRE_STATIONS::   DS 1
COUNT_NUCLEAR_POWER_PLANTS:: DS 1
COUNT_UNIVERSITIES::    DS 1
COUNT_STADIUMS::        DS 1
COUNT_MUSEUMS::         DS 1
COUNT_LIBRARIES::       DS 1

COUNT_TRAIN_TRACKS::    DS 2 ; LSB first

;###############################################################################

    SECTION "Simulation Count Buildings Functions",ROMX

;-------------------------------------------------------------------------------

; Call this function whenever a building is built or demolished. For example, it
; has to be called after exiting edit mode, after a fire is finally extinguished
; or simply when the map is loaded.
Simulation_CountBuildings::

    xor     a,a

    ld      [COUNT_AIRPORTS],a
    ld      [COUNT_PORTS],a
    ld      [COUNT_FIRE_STATIONS],a
    ld      [COUNT_NUCLEAR_POWER_PLANTS],a
    ld      [COUNT_UNIVERSITIES],a
    ld      [COUNT_STADIUMS],a
    ld      [COUNT_MUSEUMS],a
    ld      [COUNT_LIBRARIES],a

    ld      [COUNT_TRAIN_TRACKS+0],a
    ld      [COUNT_TRAIN_TRACKS+1],a

    ; Count the number of airports and fire stations

    ld      hl,CITY_MAP_TILES

.loop1:
    push    hl

        ; Returns: - Tile -> Register DE
        call    CityMapGetTileAtAddress ; Arg: hl = address. Preserves BC, HL

CHECK_TILE : MACRO ; 1 = Tile number, 2 = Variable to increase

        ld      a,(\1)&$FF ; Check low byte first because it changes more often
        cp      a,e
        jr      nz,.end\@
        ld      a,(\1)>>8
        cp      a,d
        jr      nz,.end\@
            ld      a,[\2]
            inc     a
            jr      z,.end\@ ; skip store if it overflows (clamp to 255)
                ld      [\2],a
.end\@:
ENDM

        CHECK_TILE  T_AIRPORT,      COUNT_AIRPORTS
        CHECK_TILE  T_FIRE_DEPT,    COUNT_FIRE_STATIONS
        CHECK_TILE  T_PORT,         COUNT_PORTS
        CHECK_TILE  T_POWER_PLANT_NUCLEAR, COUNT_NUCLEAR_POWER_PLANTS
        CHECK_TILE  T_UNIVERSITY,   COUNT_UNIVERSITIES
        CHECK_TILE  T_STADIUM,      COUNT_STADIUMS
        CHECK_TILE  T_MUSEUM,       COUNT_MUSEUMS
        CHECK_TILE  T_LIBRARY,      COUNT_LIBRARIES

    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jp      z,.loop1

    ; Count the number of train tracks

    ld      de,0 ; Number of train tracks
    ld      hl,CITY_MAP_TILES

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

.loop2:

        ld      a,[hl+]
        and     a,TYPE_HAS_TRAIN
        jr      z,.skip_train
            inc     de
.skip_train:

    bit     5,h ; Up to E000
    jr      z,.loop2

    ld      a,e
    ld      [COUNT_TRAIN_TRACKS+0],a ; LSB first
    ld      a,d
    ld      [COUNT_TRAIN_TRACKS+1],a

    ret

;###############################################################################
