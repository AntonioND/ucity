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

;###############################################################################

    SECTION "Money Variables",WRAM0

;-------------------------------------------------------------------------------

MoneyWRAM:: DS  5 ; BCD, LSB first, LSB in lower nibbles

;###############################################################################

    SECTION "Money Code",ROM0 ; ROM 0 is needed!

;-------------------------------------------------------------------------------

MoneySet:: ; de = ptr to the amount of money to set

    ld      hl,MoneyWRAM
    ld      b,5
.loop:
        ld      a,[de]
        inc     de
        ld      [hl+],a
    dec     b
    jr      nz,.loop

    ret

;-------------------------------------------------------------------------------

MoneyIsThereEnough:: ; de = ptr to the amount of money. ret a=1 if enough else 0

    ld      hl,MoneyWRAM
    jp      BCD_HL_GE_DE

;-------------------------------------------------------------------------------

MoneyReduce:: ; de = ptr to the amout of money.

    ld      h,d
    ld      l,e

    ld      de,MoneyWRAM

    jp  BCD_HL_SUB_DE ; DE = DE - HL

;-------------------------------------------------------------------------------

; Returns a=1 if enough else 0. If enough, that amount will be reduced from the
; total amount.
MoneyReduceIfEnough:: ; de = ptr to amount.

    push    de
    call    MoneyIsThereEnough
    pop     de

    and     a,a
    ret     z ; not enough, return 0

    call    MoneyReduce

    ld      a,1
    ret

;-------------------------------------------------------------------------------

; returns carry = 1 if overflowed, 0 if not. On overflow, 999999999 is set
MoneyAdd:: ; de = ptr to the amount of money to add.

    ld      hl,MoneyWRAM
    jp      BCD_HL_ADD_DE

;###############################################################################
