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
    INCLUDE "engine.inc"

;-------------------------------------------------------------------------------

    INCLUDE "text.inc"

;###############################################################################

    SECTION "Date Variables",WRAM0

;-------------------------------------------------------------------------------

date_year::  DS 2 ; BCD, LSB first, LSB in lower nibble
date_month:: DS 1 ; 0 (Jan) - 11 (Dec)

    DEF MONTHS_IN_YEAR EQU 12

;###############################################################################

    SECTION "Date Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

; a = month
; bc = year (B = MSB, C = LSB)
; de = pointer to destination of print (8 chars)
DatePrint::

    ; Month

    push    bc ; (*) save year

    ld      hl,.date_month_name
    ; a = month
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc
    add     hl,bc

    REPT    3
        ld      a,[hl+]
        ld      [de],a
        inc     de
    ENDR

    ; Separator

    ld      a,O_SPACE
    ld      [de],a
    inc     de

    ; Year

    pop     bc ; (*) get year

    ld      h,c ; save LSB in H

    ld      a,b ; MSB
    ld      b,a
    swap    a
    and     a,$0F
    BCD2Tile
    ld      [de],a
    inc     de
    ld      a,b
    and     a,$0F
    BCD2Tile
    ld      [de],a
    inc     de

    ld      a,h ; get LSB
    ld      b,a
    swap    a
    and     a,$0F
    BCD2Tile
    ld      [de],a
    inc     de
    ld      a,b
    and     a,$0F
    BCD2Tile
    ld      [de],a
    inc     de
    ret

.date_month_name:
    STR_ADD "JanFebMarAprMayJunJulAugSepOctNovDec"

;-------------------------------------------------------------------------------

DateReset::

    ld      c,0 ; January
    ld      de,$1950

DateSet:: ; de = year, c = month

    ld      a,c
    ld      [date_month],a

    ld      a,e ; LSB first
    ld      [date_year+0],a
    ld      a,d
    ld      [date_year+1],a

    ret

;-------------------------------------------------------------------------------

DateStep::

    ; Month

    ld      a,[date_month]
    inc     a
    cp      a,MONTHS_IN_YEAR
    jr      z,.inc_year
        ld      [date_month],a
        ret
.inc_year:
    xor     a,a ; January
    ld      [date_month],a

    ; Reset yearly messages

    call    PersistentYearlyMessagesReset

    ; Year

    ; If year 9999 is reached, stay there!
    ; Months will continue to increment
    ld      a,[date_year+0]
    cp      a,$99
    jr      nz,.year_not_maxed
    ld      a,[date_year+1]
    cp      a,$99
    ret     z
.year_not_maxed:

    ld      a,[date_year+0]
    add     a,1 ; inc doesn't set carry flag
    daa
    ld      [date_year+0],a

    ld      a,[date_year+1]
    adc     a,0 ; carry from previous inc
    daa
    ld      [date_year+1],a

    ret

;###############################################################################
