;###############################################################################
;
;    µCity - City building game for Game Boy Color.
;    Copyright (c) 2017-2018 Antonio Niño Díaz (AntonioND/SkyLyrac)
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

; The functions in this file implement a FIFO circular buffer that is stored in
; WRAMX in BANK_SCRATCH_RAM_2 and uses the whole WRAMX bank ($1000 bytes).

queue_in_ptr:  DS 2 ; LSB first - pointer to the place where to add elements
queue_out_ptr: DS 2 ; LSB first - pointer to the place where to read elements

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

;-------------------------------------------------------------------------------

QueueAdd:: ; Add register DE to the queue. Preserves DE and BC

    ld      a,BANK_SCRATCH_RAM_2
    ldh     [rSVBK],a

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

;-------------------------------------------------------------------------------
IF 0
QueueAddEx:: ; Add registers BC and DE to the queue. Preserves BC and DE

    ld      a,BANK_SCRATCH_RAM_2
    ldh     [rSVBK],a

    ldh     a,[queue_in_ptr+0] ; Get pointer to next empty space
    ld      l,a
    ldh     a,[queue_in_ptr+1]
    ld      h,a

    ld      [hl],d ; Save and increment pointer
    inc     hl
    ld      [hl],e
    inc     hl

    ld      [hl],b
    inc     hl
    ld      [hl],c
    inc     hl

    ld      a,$0F ; Wrap pointer and store
    and     a,h
    or      a,$D0
    ldh     [queue_in_ptr+1],a
    ld      a,l
    ldh     [queue_in_ptr+0],a

    ret
ENDC
;-------------------------------------------------------------------------------

QueueGet:: ; Get value from queue into DE.

    ld      a,BANK_SCRATCH_RAM_2
    ldh     [rSVBK],a

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

;-------------------------------------------------------------------------------
IF 0
QueueGetEx:: ; Get values from queue into BC and DE.

    ld      a,BANK_SCRATCH_RAM_2
    ldh     [rSVBK],a

    ldh     a,[queue_out_ptr+0] ; Get pointer to next element to get
    ld      l,a
    ldh     a,[queue_out_ptr+1]
    ld      h,a

    ld      d,[hl] ; Read and increment pointer
    inc     hl
    ld      e,[hl]
    inc     hl

    ld      b,[hl]
    inc     hl
    ld      c,[hl]
    inc     hl

    ld      a,$0F ; Wrap pointer and store
    and     a,h
    or      a,$D0
    ldh     [queue_out_ptr+1],a
    ld      a,l
    ldh     [queue_out_ptr+0],a

    ret
ENDC
;-------------------------------------------------------------------------------

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
