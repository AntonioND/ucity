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

    SECTION "Genenerate Map Variables",HRAM

;-------------------------------------------------------------------------------

seedx: DS 1
seedy: DS 1
seedz: DS 1
seedw: DS 1

;###############################################################################

    SECTION "Genenerate Map Code Data",ROMX[$4000]

;-------------------------------------------------------------------------------

; Aligned to $100
abs_clamp_array_64: ; returns absolute value up to 63, clamped to 63

VAL SET 0 ; 0 to 63
    REPT 64
    DB  VAL
VAL SET VAL+1
    ENDR

    REPT 129 ; 64 - 191 (64 to 123, -64 to -128
    DB  63
    ENDR

VAL SET 63 ; -63 to -1
    REPT 63
    DB  VAL
VAL SET VAL+(-1) ; WTF, RGBDS, really?
    ENDR

;-------------------------------------------------------------------------------

; Returns X<<6 for X between 0 and 63
; Aligned to $100
shift_left_six: ; LSB first, MSB second
    DB $00,$00,$40,$00,$80,$00,$C0,$00,$00,$01,$40,$01,$80,$01,$C0,$01
    DB $00,$02,$40,$02,$80,$02,$C0,$02,$00,$03,$40,$03,$80,$03,$C0,$03
    DB $00,$04,$40,$04,$80,$04,$C0,$04,$00,$05,$40,$05,$80,$05,$C0,$05
    DB $00,$06,$40,$06,$80,$06,$C0,$06,$00,$07,$40,$07,$80,$07,$C0,$07
    DB $00,$08,$40,$08,$80,$08,$C0,$08,$00,$09,$40,$09,$80,$09,$C0,$09
    DB $00,$0A,$40,$0A,$80,$0A,$C0,$0A,$00,$0B,$40,$0B,$80,$0B,$C0,$0B
    DB $00,$0C,$40,$0C,$80,$0C,$C0,$0C,$00,$0D,$40,$0D,$80,$0D,$C0,$0D
    DB $00,$0E,$40,$0E,$80,$0E,$C0,$0E,$00,$0F,$40,$0F,$80,$0F,$C0,$0F

;-------------------------------------------------------------------------------

; The following array is organized like a quarter of a circle:

; (0,0)
; +-----------+
; |.......... |
; |.......... |
; |.........  |
; |........   |
; |.....      |
; |           |
; +-----------+
;        (63,63)

; The right and bottom bounds should have only 0s as the clamped values to 63
; will read from them.

; It doesn't need to be aligned to $100
gen_map_circle: ; 64x64
    INCLUDE "gen_map_circle.inc"

;-------------------------------------------------------------------------------

; X and Y are signed 8 bit values

is_inside_circle_4: ; b = x, a = y

    sla     b
    add     a,a ; sla a

is_inside_circle_8: ; b = x, a = y

    sla     b
    add     a,a ; sla a

is_inside_circle_16: ; b = x, a = y

    sla     b
    add     a,a ; sla a

is_inside_circle_32: ; b = x, a = y

    sla     b
    add     a,a ; sla a

is_inside_circle_64: ; b = x, a = y

    ; Get absolute clamped value

    ld      h,abs_clamp_array_64>>8
    ld      l,b
    ld      b,[hl]
    ld      l,a
    ld      l,[hl] ; Y = L. Prepare for next step

    ; Get offset

    ld      h,shift_left_six>>8 ; Y << 6
    sla     l
    ld      a,[hl+] ; LSB
    ld      h,[hl] ; MSB

    or      a,b ; or X
    ld      l,a

    ; Access array

    ld      de,gen_map_circle
    add     hl,de

    ld      a,[hl]

    ret

;-------------------------------------------------------------------------------

gen_map_srand:: ; a = seed x, b = seed y

    ldh     [seedx],a ; 21
    ld      a,b ; 229
    ldh     [seedy],a
    ld      a,181
    ldh     [seedz],a
    ld      a,51
    ldh     [seedw],a

    ret

;-------------------------------------------------------------------------------

gen_map_rand:: ; returns a = random number

    ; char t = _x ^ (_x << 3);

    ldh     a,[seedx]
    ld      b,a
    rla
    rla
    rla
    and     a,$F8 ; x << 3
    xor     a,b
    ld      c,a ; c = t

    ; _x = _y;

    ldh     a,[seedy]
    ldh     [seedx],a

    ; _y = _z;

    ldh     a,[seedz]
    ldh     [seedy],a

    ; _z = _w;

    ldh     a,[seedw]
    ldh     [seedz],a

    ; _w = _w ^ (_w >> 5) ^ (t ^ (t >> 2));

    ld      a,c ; c = t
    rra
    rra
    and     a,$3F ; t >> 2
    xor     a,c ; t ^ (t >> 2))
    ld      c,a ; save it

    ldh     a,[seedw]
    ld      b,a
    swap    a
    rra
    and     a,$7 ; _w >> 5
    xor     a,b ; _w ^ (_w >> 5)

    xor     a,c
    ldh     [seedw],a

    ; return _w;

    ret

;###############################################################################
