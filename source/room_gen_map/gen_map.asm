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

; Aligned to $100
shift_left_six_lsb:
    DB $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
    DB $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
    DB $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0
    DB $00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0,$00,$40,$80,$C0

; 64 bytes after the first one
shift_left_six_msb:
    DB $00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03
    DB $04,$04,$04,$04,$05,$05,$05,$05,$06,$06,$06,$06,$07,$07,$07,$07
    DB $08,$08,$08,$08,$09,$09,$09,$09,$0A,$0A,$0A,$0A,$0B,$0B,$0B,$0B
    DB $0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D,$0E,$0E,$0E,$0E,$0F,$0F,$0F,$0F

;-------------------------------------------------------------------------------

; The right and bottom bounds should have only 0s as the clamped values to 63
; will read from them.
gen_map_circle:
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

    ld      h,shift_left_six_lsb>>8 ; Y << 6
    ld      a,[hl] ; LSB
    set     6,h ; shift_left_six_msb
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
