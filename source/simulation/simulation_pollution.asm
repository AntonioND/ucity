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

; Output data to WRAMX bank BANK_SCRATCH_RAM
Simulation_Pollution::
    ret ; TODO delete

    ; Clean
    ; -----

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    call    ClearWRAMX

    ; Add to the map the corresponding pollution for each tile
    ; --------------------------------------------------------

    ; Valid pollution values: -128 to 127

    ld      d,0 ; y
.loopy:
        ld      e,0 ; x
.loopx:
        push    de

        ; Get tile type.
        ; - If road, check traffic.
        ; - If building, check if the building has power and add pollution if
        ;   so. If it is a power plant, add the corresponding pollution level.
        ; - If park, forest or water set a negative level of pollution (they
        ;   reduce it)

        ; TODO

        pop     de

        inc     e
        ld      a,CITY_MAP_WIDTH
        cp      a,e
        jr      nz,.loopx

    inc     d
    ld      a,CITY_MAP_HEIGHT
    cp      a,d
    jr      nz,.loopy

    ; Smooth map
    ; ----------

    ; Valid pollution values: -128 to 127

    ; TODO

    ; Set all tiles with negative pollution value to 0
    ; ------------------------------------------------

    ; Valid pollution values: -128 to 127

    ; Also, duplicate the values to go from 0-127 to 0-255

    ; TODO

    ; Valid pollution values: 0 to 255

    ret

;###############################################################################
