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

;###############################################################################

    SECTION "Math Utilities Bank 0",ROM0

;-------------------------------------------------------------------------------

; Calculates a aproximate percentage of 2 16-bit values by reducing them to
; 8-bit values and operating on them.
; It returns 255 on error, a value between 0 and 100 or success.
CalculateAproxPercent:: ; a = de * 100 / hl

    ld      a,h
    or      a,l
    jr      nz,.not_div_by_0
        xor     a,a ; return 0
        ret
.not_div_by_0:

    ld      c,16 ; get the top 7 bits of the values to simplify divisions
.loop:
        ld      a,h
        or      a,d
        bit     6,a ; get 7 bits only
        jp      nz,.end_simplify_loop
        add     hl,hl ; hl <<= 1
        sla     e     ; de <<= 1
        rl      d
    dec     c
    jr      nz,.loop
.end_simplify_loop:

    ; D = aprox DE
    ; H = aprox HL

    push    hl

    ld      a,100
    ld      c,d
    call    mul_u8u8u16 ; hl = result    a,c = initial values    de preserved

    pop     de

    ld      c,d

    ; HL = aprox DE * 100
    ; C = aprox HL

    call    div_u16u7u16 ; hl / c -> hl

    ; HL should be less or equal than 100!

    ld      a,h
    and     a,a ; if hl >= 255
    jr      z,.div_lower_256

        ld      b,b
        ld      a,255 ; 255 is considered an invalid value
        ret

.div_lower_256:

    ld      a,l
    cp      a,101 ; cy = 1 if n > a
    jr      c,.div_lower_100

        ld      b,b
        ld      a,255 ; 255 is considered an invalid value
        ret

.div_lower_100:

    ld      a,l ; get result

    ret

;-------------------------------------------------------------------------------

; Calculates a aproximate percentage of 2 16-bit values by reducing them to
; 8-bit values and operating on them. It returns the value converted to BCD.
CalculateAproxPercentBCD:: ; hl = de * 100 / hl, Result in BCD (H=MSB, L=LSB)

    call    CalculateAproxPercent ; a = de * 100 / hl

    jr      Byte2BCD ; return from there

;-------------------------------------------------------------------------------

Byte2BCD:: ; a = byte, returns hl = BCD (H=MSB, L=LSB)

    ld      l,a
    ld      h,0
    add     hl,hl ; hl = a*2
    ld      de,BINARY_TO_BCD ; 2 bytes per entry. LSB first
    add     hl,de

    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ret

;###############################################################################
