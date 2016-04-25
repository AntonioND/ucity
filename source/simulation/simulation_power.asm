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

    SECTION "Simulation Services Functions",ROMX

;-------------------------------------------------------------------------------

; Flood fill from the power plant on the specified coordinates. This function is
; supposed to receive only the top left corner of a power plant. If not, it will
; fail!
Simulation_PowerPlantFloodFill: ; d = y, e = x

    ; Check if this power plant has been handled
    ; ------------------------------------------

    ld      a,BANK_SCRATCH_RAM ; Get current state
    ld      [rSVBK],a

    ld      a,[hl]
    and     a,a
    ret     nz ; If not 0, this power plant has already been handled

    ; Flag power plant as handled (set to $FF)
    ; ----------------------------------------

    push    de
    call    CityMapGetTileAtAddress ; Returns tile -> Register DE
    LD_BC_DE
    pop     de

    push    bc ; Save base tile to calculate the power in the next step (*)

        push    de ; save coords
        ; bc = base tile
        ; returns: d=height, e=width
        LONG_CALL_ARGS BuildingGetSizeFromBaseTile
        LD_BC_DE ; bc = size
        pop     de ; get coords

        ; d = y, e = x
        ; b = height, c = width

        ld      a,b
        ld      b,e
        ld      e,a

        ; d = y, e = height
        ; b = x, c = width

        ; Fill that square with $FF

        ld      a,BANK_SCRATCH_RAM
        ld      [rSVBK],a

.height_loop:

        push    bc ; save x and w
.width_loop:

            push    bc
            push    de
            ld      e,b ; e=x, d=y
            call    GetMapAddress ; e=x , d=y ret: address=hl
            pop     de
            pop     bc

            ld      [hl],$FF ; flag as used

            inc     b ; x
            dec     c ; width
            jr      nz,.width_loop

        pop     bc ; restore x and w

        inc     d ; y
        dec     e ; height
        jr      nz,.height_loop

    pop     bc ; Restore base tile (*)

    ; Get power plant power
    ; ---------------------



    ; Flood fill
    ; ----------

    ; For each connected tile with scratch RAM value of 0 reduce the fill amount
    ; of the power plant by the energy consumption of that tile (if possible)
    ; and add the energy given to that tile to the scratch RAM. Power lines have
    ; no energetic cost. Beware unconnected power line bridges -> Sometimes they
    ; are not connected to the ground next to them.

    ret

;-------------------------------------------------------------------------------

; Output data to WRAMX bank BANK_SCRATCH_RAM
Simulation_PowerDistribution::

    ; Clear
    ; -----

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      bc,$1000
    ld      d,0
    ld      hl,SCRATCH_RAM
    call    memset

    ; For each tile check if it is type TYPE_POWER_PLANT (power plant)
    ; ----------------------------------------------------------------

    ld      d,0 ; y
.loopy:
        ld      e,0 ; x
.loopx:
        push    de

            ; Returns type = a, address = hl
            call    CityMapGetType ; e = x , d = y

            cp      a,TYPE_POWER_PLANT
            jr      nz,.not_power_plant
                pop     de
                push    de
                ; The coordinates will be the top left corner because of the
                ; order of iteration when searching the map for power plants.
                ; After calling this function the whole power plant will be
                ; flagged as handled.
                call    Simulation_PowerPlantFloodFill ; e=x, d=y, address=hl
.not_power_plant:

        pop     de

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

Simulation_PowerDistributionSetTileOkFlag::

    ; TODO - Fill BANK_CITY_MAP_TILE_OK_FLAGS from BANK_SCRATCH_RAM

    ret

;###############################################################################
