;###############################################################################
;
;    µCity - City building game for Game Boy Color.
;    Copyright (C) 2017 Antonio Niño Díaz (AntonioND/SkyLyrac)
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

    INCLUDE "money.inc"

;###############################################################################

    SECTION "Money Variables",WRAM0

;-------------------------------------------------------------------------------

MoneyWRAM:: DS MONEY_AMOUNT_SIZE ; BCD, LSB first, LSB in lower nibbles

;###############################################################################

    SECTION "Money Code",ROM0 ; ROM 0 is needed!

;-------------------------------------------------------------------------------

    DATA_MONEY_AMOUNT MONEY_SATURATE_POSITIVE,0999999999
    DATA_MONEY_AMOUNT MONEY_SATURATE_NEGATIVE,9000000001 ; -0999999999

;-------------------------------------------------------------------------------

MoneySet:: ; de = ptr to the amount of money to set

    ld      hl,MoneyWRAM
    ld      b,MONEY_AMOUNT_SIZE
.loop:
        ld      a,[de]
        inc     de
        ld      [hl+],a
    dec     b
    jr      nz,.loop

    ret

;-------------------------------------------------------------------------------

MoneyGet:: ; de = ptr to store the current amount of money

    ld      hl,MoneyWRAM
    ld      b,MONEY_AMOUNT_SIZE
.loop:
        ld      a,[hl+]
        ld      [de],a
        inc     de
    dec     b
    jr      nz,.loop

    ret

;-------------------------------------------------------------------------------

MoneyIsThereEnough:: ; de = ptr to the amount of money. ret a=1 if enough else 0

    push    de
    push    hl
    ld      de,MoneyWRAM
    call    BCD_DE_LW_ZERO ; Returns a = 1 if [de] < 0, preserves bc, de
    pop     hl
    pop     de
    and     a,a
    jr      z,.not_less_than_zero
        xor     a,a ; negative amount of money!!
        ret
.not_less_than_zero:
    ld      hl,MoneyWRAM
    jp      BCD_HL_GE_DE

;-------------------------------------------------------------------------------

; Returns carry = 1 if overflowed, 0 if not.
; On overflow, MONEY_SATURATE_POSITIVE is set
MoneyReduce:: ; de = ptr to the amout of money.

    LD_HL_DE

    ld      de,MoneyWRAM

    call    BCD_HL_SUB_DE ; DE = DE - HL

    ld      de,MoneyWRAM

    call    BCD_DE_LW_ZERO ; Returns a = 1 if [de] < 0, preserves bc, de
    and     a,a ; if > 0, the subtraction can't have saturated
    ret     z ; return 0

    ld      de,MoneyWRAM
    ld      hl,MONEY_SATURATE_NEGATIVE
    call    BCD_HL_GE_DE ; current >= saturated?
    and     a,a
    ret     z ; return 0
    ld      de,MONEY_SATURATE_NEGATIVE
    call    MoneySet

    ld      a,1
    ret ; return 1

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

; Returns carry = 1 if overflowed, 0 if not.
; On overflow, MONEY_SATURATE_POSITIVE is set
MoneyAdd:: ; de = ptr to the amount of money to add.

    ld      hl,MoneyWRAM
    call    BCD_HL_ADD_DE

    ld      de,MoneyWRAM
    call    BCD_DE_LW_ZERO ; Returns a = 1 if [de] < 0, preserves bc, de
    and     a,a ; if < 0, the addition can't have saturated
    jr      z,.dont_ret_1
    xor     a,a
    ret ; return 0
.dont_ret_1:

    ld      de,MoneyWRAM
    ld      hl,MONEY_SATURATE_POSITIVE
    call    BCD_HL_GE_DE ; current <= saturated?
    and     a,a
    jr      z,.dont_ret_2
    xor     a,a
    ret ; return 0
.dont_ret_2:
    ld      de,MONEY_SATURATE_POSITIVE
    call    MoneySet

    ld      a,1
    ret ; return 1

;###############################################################################
