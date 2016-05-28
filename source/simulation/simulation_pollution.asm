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

    SECTION "Simulation Pollution Functions",ROMX

;-------------------------------------------------------------------------------

Simulation_PollutionDiffuminate:

    ; Valid pollution values: -128 to 127

    ; TODO

    ret

;-------------------------------------------------------------------------------

; Output data to WRAMX bank BANK_SCRATCH_RAM
Simulation_Pollution::

    ; Clean
    ; -----

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    call    ClearWRAMX

    ; Add to the map the corresponding pollution for each tile
    ; --------------------------------------------------------

    ; Valid pollution values: -128 to 127

    ld      hl,CITY_MAP_TILES

.loop:
    push    hl

        ; Get tile type.
        ; - If road, check traffic. Train doesn't pollute as it is electric.
        ; - If building, check if the building has power and add pollution
        ;   if so. If it is a power plant, add the corresponding pollution
        ;   level.
        ; - If park, forest or water set a negative level of pollution (they
        ;   reduce it)

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

        ld      a,[hl]

        bit     TYPE_HAS_ROAD_BIT,a
        jr      z,.not_road

            ld      a,BANK_CITY_MAP_TRAFFIC
            ld      [rSVBK],a

            ld      b,[hl]

            sra     b ; 0-255 to 0-127
            ; Pollution is the amount of cars going through here

            jr      .save_value

.not_road:

        ; Read pollution level array

        push    hl
        call    CityMapGetTileAtAddress ; hl = address, returns de = tile
        call    CityTilePollution ; de = tile, returns d=pollution
        pop     hl

        ld      b,d

;        jr      .save_value

.save_value:

        ld      a,BANK_SCRATCH_RAM
        ld      [rSVBK],a

        ld      [hl],b

    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ; Smooth map
    ; ----------

    ; Valid pollution values: -128 to 127

    call    Simulation_PollutionDiffuminate
    call    Simulation_PollutionDiffuminate

    ; Set all tiles with negative pollution value to 0
    ; ------------------------------------------------

    ; Valid pollution values: -128 to 127

    ; Also, duplicate the values to go from 0-127 to 0-255

    ld      hl,CITY_MAP_TILES

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

.loop_fix:
        ld      a,[hl]
        bit     7,a
        jr      z,.positive
        xor     a,a ; if negative, 0
.positive:
        sla     a ; 0 to 127 -> 0 to 255

        ld      [hl+],a

    bit     5,h ; Up to E000
    jr      z,.loop_fix

    ; Valid pollution values: 0 to 255

    ret

;###############################################################################
