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

    SECTION "Queue Variables",HRAM

;-------------------------------------------------------------------------------

; FIFO circular buffer
queue_in_ptr:  DS 2 ; LSB first
queue_out_ptr: DS 2; LSB first

;###############################################################################

    SECTION "Simulation Services Functions",ROMX

;-------------------------------------------------------------------------------

QueueInit: ; Reset pointers
    ld      a,SCRATCH_RAM_2 & $FF ; LSB first
    ldh     [queue_in_ptr+0],a
    ldh     [queue_out_ptr+0],a
    ld      a,(SCRATCH_RAM_2>>8) & $FF
    ldh     [queue_in_ptr+1],a
    ldh     [queue_out_ptr+1],a
    ret

QueueAdd: ; Add register DE to the queue. Preserves DE

    ld      a,BANK_SCRATCH_RAM_2
    ld      [rSVBK],a

    ldh     a,[queue_in_ptr+0] ; Get pointer to next empty space
    ld      l,a
    ldh     a,[queue_in_ptr+1]
    ld      h,a

    ld      [hl],d ; Save and increment pointer
    inc     hl
    ld      [hl],e
    inc     hl

    ld      a,$0F ; Wrap pointer and store
    and     a,h
    or      a,$D0
    ldh     [queue_in_ptr+1],a
    ld      a,l
    ldh     [queue_in_ptr+0],a

    ret

QueueGet: ; Get queue element from DE

    ld      a,BANK_SCRATCH_RAM_2
    ld      [rSVBK],a

    ldh     a,[queue_out_ptr+0] ; Get pointer to next element to get
    ld      l,a
    ldh     a,[queue_out_ptr+1]
    ld      h,a

    ld      d,[hl] ; Read and increment pointer
    inc     hl
    ld      e,[hl]
    inc     hl

    ld      a,$0F ; Wrap pointer and store
    and     a,h
    or      a,$D0
    ldh     [queue_out_ptr+1],a
    ld      a,l
    ldh     [queue_out_ptr+0],a

    ret

QueueIsEmpty: ; Returns a=1 if empty

    ldh     a,[queue_out_ptr+0]
    ld      b,a
    ldh     a,[queue_in_ptr+0]
    cp      a,b
    jr      z,.equal0
    xor     a,a
    ret ; Different, return 0
.equal0:

    ldh     a,[queue_out_ptr+1]
    ld      b,a
    ldh     a,[queue_in_ptr+1]
    cp      a,b
    jr      z,.equal1
    xor     a,a
    ret ; Different, return 0
.equal1:

    ld      a,1
    ret ; Equal, return 1

;-------------------------------------------------------------------------------

TILE_HANDLED          EQU %10000000
TILE_IS_POWER_PLANT   EQU %01000000
TILE_POWER_LEVEL_MASK EQU %00111111 ; Bits used to tell how much power there is

; Flood fill from the power plant on the specified coordinates. This function is
; supposed to receive only the top left corner of a power plant. If not, it will
; fail!
Simulation_PowerPlantFloodFill: ; d = y, e = x

    ; Check if this power plant has been handled
    ; ------------------------------------------

    ld      a,BANK_SCRATCH_RAM ; Get current state
    ld      [rSVBK],a

    push    de
    call    GetMapAddress ; e=x , d=y ret: address=hl
    pop     de
    ld      a,[hl]
    and     a,TILE_IS_POWER_PLANT
    ret     nz ; If not 0, this power plant has already been handled

    ; Reset all TILE_HANDLED flags
    ; ----------------------------

    push    de
    ld      hl,SCRATCH_RAM
    ld      bc,$1000
    ld      d,(~TILE_HANDLED) & $FF
.loop_clear:
    ld      a,[hl]
    and     a,d
    ld      [hl+],a
    dec     bc
    ld      a,b
    or      a,c
    jr      nz,.loop_clear
    pop     de

    ; Flag power plant as handled (set to $FF)
    ; ----------------------------------------

    push    de
    call    CityMapGetTile ; Returns tile -> Register DE
    LD_BC_DE
    pop     de

    push    bc ; Save base tile to calculate the power in the next step (*)
    push    de ; Save coordinates too

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

            ld      [hl],TILE_IS_POWER_PLANT ; flag as used

            inc     b ; x
            dec     c ; width
            jr      nz,.width_loop

        pop     bc ; restore x and w

        inc     d ; y
        dec     e ; height
        jr      nz,.height_loop

    pop     de
    pop     bc ; Restore base tile and coordinates (*)

    ; Get power plant power
    ; ---------------------



    ; Flood fill
    ; ----------

    ; For each connected tile with scratch RAM value of 0 reduce the fill amount
    ; of the power plant by the energy consumption of that tile (if possible)
    ; and add the energy given to that tile to the scratch RAM. Power lines have
    ; no energetic cost. Beware unconnected power line bridges -> Sometimes they
    ; are not connected to the ground next to them.
    push    de
    call    QueueInit
    pop     de
    call    QueueAdd ; Add first element

.loop_fill:

    ; Get Queue element

    call    QueueGet

ld b,b
    ; First, if not already filled, try to fill current coordinates

    push    de
    call    GetMapAddress
    pop     de

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      a,[hl]
    and     a,TILE_HANDLED
    jr      nz,.end_handle

    ld      a,TILE_HANDLED|TILE_POWER_LEVEL_MASK
    or      a,[hl]
    ld      [hl],a
.handled:

    ; Then, add to queue all valid neighbours (power plants, buildings, lines)

    ; TODO Power line bridges aren't connected if the orientation is wrong!

    push    de
    dec     d
    ld      a,e ; Check map border
    or      a,d
    and     a,128+64 ; ~63
    jr      nz,.skip0
    call    CityMapGetTypeNoBoundCheck
    call    TypeHasElectricityExtended ; in: A=type, out: A = TYPE_HAS_POWER / 0
    and     a,TYPE_HAS_POWER
    jr      z,.skip0
    call    QueueAdd
.skip0:
    pop     de

    push    de
    inc     d
    ld      a,e ; Check map border
    or      a,d
    and     a,128+64 ; ~63
    jr      nz,.skip1
    call    CityMapGetTypeNoBoundCheck
    call    TypeHasElectricityExtended ; in: A=type, out: A = TYPE_HAS_POWER / 0
    and     a,TYPE_HAS_POWER
    jr      z,.skip1
    call    QueueAdd
.skip1:
    pop     de

    push    de
    dec     e
    ld      a,e ; Check map border
    or      a,d
    and     a,128+64 ; ~63
    jr      nz,.skip2
    call    CityMapGetTypeNoBoundCheck
    call    TypeHasElectricityExtended ; in: A=type, out: A = TYPE_HAS_POWER / 0
    and     a,TYPE_HAS_POWER
    jr      z,.skip2
    call    QueueAdd
.skip2:
    pop     de

    push    de
    inc     e
    ld      a,e ; Check map border
    or      a,d
    and     a,128+64 ; ~63
    jr      nz,.skip3
    call    CityMapGetTypeNoBoundCheck
    call    TypeHasElectricityExtended ; in: A=type, out: A = TYPE_HAS_POWER / 0
    and     a,TYPE_HAS_POWER
    jr      z,.skip3
    call    QueueAdd
.skip3:
    pop     de

.end_handle:
    ; Last, check if queue is empty. If so, exit loop
    call    QueueIsEmpty
    and     a,a
    jr      z,.loop_fill

    ; Done!
    ; -----

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
