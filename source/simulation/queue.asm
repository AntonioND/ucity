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

;-------------------------------------------------------------------------------

    INCLUDE "room_game.inc"

;###############################################################################

    SECTION "Queue Variables",HRAM

;-------------------------------------------------------------------------------

; FIFO circular buffer
queue_in_ptr:  DS 2 ; LSB first
queue_out_ptr: DS 2 ; LSB first

;###############################################################################

    SECTION "Queue Functions",ROM0

;-------------------------------------------------------------------------------

QueueInit:: ; Reset pointers
    ld      a,SCRATCH_RAM_2 & $FF ; LSB first
    ldh     [queue_in_ptr+0],a
    ldh     [queue_out_ptr+0],a
    ld      a,(SCRATCH_RAM_2>>8) & $FF
    ldh     [queue_in_ptr+1],a
    ldh     [queue_out_ptr+1],a
    ret

QueueAdd:: ; Add register DE to the queue. Preserves DE

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

QueueGet:: ; Get queue element from DE

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

QueueIsEmpty:: ; Returns a=1 if empty

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

;###############################################################################
