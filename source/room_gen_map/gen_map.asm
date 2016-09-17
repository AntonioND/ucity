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

;###############################################################################

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

gen_map_rand:: ; returns a = random number. Preserves DE

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

; Allocate banks for the intermediate and final stages of the map generation
BANK_TEMP1 EQU BANK_CITY_MAP_TYPE
BANK_TEMP2 EQU BANK_CITY_MAP_TRAFFIC
BANK_TILES EQU BANK_CITY_MAP_TILES

;-------------------------------------------------------------------------------

MAP_READ_CLAMPED : MACRO ; e = x, d = y, returns value in a, preserves bc

    ld      h,CLAMP_0_63>>8
    ld      l,e
    ld      e,[hl]
    ld      l,d
    ld      d,[hl]

    GET_MAP_ADDRESS ; e = x , d = y (0 to 63). preserves de and bc
    ; returns hl = address

    ld      a,[hl]

ENDM

;-------------------------------------------------------------------------------

map_initialize: ; result saved to bank 1

    ; memset attribute bank to 0. Terrain tiles are always < 256

    ; TODO : Move this to room code, this only needs to be done once in the room
    ld      a,BANK_CITY_MAP_ATTR
    ld      [rSVBK],a
    call    ClearWRAMX ; Sets D000 - DFFF to 0 ($1000 bytes)

    ; initialize tile bank to random values

    ld      a,BANK_TEMP1
    ld      [rSVBK],a

    ld      hl,CITY_MAP_TILES

.loop:
    push    hl
    call    gen_map_rand ; preserves DE
    pop     hl

    and     a,63
    add     a,128-32
    ld      [hl+],a ; tile[i] = 128 + ( (rand() & 63) - 32 )

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

;-------------------------------------------------------------------------------

map_add_circle:

    ; TODO

    ret

;-------------------------------------------------------------------------------

map_add_circle_all:

    ; TODO

    ret

;-------------------------------------------------------------------------------

map_normalize: ; normalizes bank 2. ret A = 1 if ok, 0 if we have to start again

    ld      a,BANK_TEMP2
    ld      [rSVBK],a

    ; Make sure that there is enough variability to make this map interesting
    ; -----------------------------------------------------------------------

    ld      hl,CITY_MAP_TILES

    ld      b,[hl] ; b = min
    ld      c,b ; c = max

.loop_minmax:

        ld      a,[hl+]

        cp      a,b ; cy = 1 if b > a (min > val)
        jr      nc,.skipmin
            ld      b,a
.skipmin:

        cp      a,c ; cy = 1 if b > a (max > val)
        jr      c,.skipmax
            ld      c,a
.skipmax:

    bit     5,h ; Up to E000
    jr      z,.loop_minmax

    ld      a,c
    sub     a,b
    cp      a,$40 ; cy = 1 if $40 > a (threshold > val)
    jr      nc,.map_ok
        xor     a,a ; If not, return and repeat!
        ret
.map_ok:

    ; Calculate average value
    ; -----------------------

    ld      hl,CITY_MAP_TILES

    ld      de,0
    ld      bc,0 ; cde = total value, b = helper zero register

.loop_add:

        ld      a,[hl+]
        add     a,e
        ld      e,a

        ld      a,b
        adc     a,d
        ld      d,a

        ld      a,b
        adc     a,c
        ld      c,a

    bit     5,h ; Up to E000
    jr      z,.loop_add

    ; Divide by 64x64 = >> (6*2) = >> (8 + 4) -> ignore e, shift cd by 4

    swap    d
    ld      a,d
    and     a,$0F ; get MSB 4 bits from D and save them to LSB in A

    swap    c
    or      a,c ; get LSB 4 bits from C and save them to MSB in A

    ; top 4 bits in C can't be different from 0 because 256*64*64 = $100000,
    ; and 256 can't be reached in any case so the total value must be lower

    ; A = average

    ; Subtract average value from all tiles in the map
    ; ------------------------------------------------

    ld      c,a ; C = average
    ld      a,128 ; 128 = middle value
    ; TODO: Add 0x20 to A if we want less water
    sub     a,c ; a = value we have to add to all the tiles
    ; cy = 1 if c > a (c > 128 -> result is negative)
    jr      c,.negative
    ld      b,0
    jr      .end_sign_expand
.negative:
    ld      b,$FF
.end_sign_expand:
    ; bc = value to add

    ld      de,CITY_MAP_TILES

    ld      h,0 ; sign expand tile values (they are 0-255)

.loop_normalize:

        ld      a,[de]

        ld      l,a ; hl = tile
        add     hl,bc ; add value

        ; Clamp HL to 0,255

        ; The only possibilities are negative numbers or 0-510

        bit     7,h
        jr      z,.not_negative
            ld      l,0
        jr      .end_overflow_check
.not_negative:
        bit     0,h
        jr      z,.not_positive_overflow
            ld      l,255
.not_positive_overflow:
.end_overflow_check:

        ld      a,l

        ld      [de],a
        inc     de

    bit     5,d ; Up to E000
    jr      z,.loop_normalize

    ret

;-------------------------------------------------------------------------------

MAP_SMOOTH_FN : MACRO ; \1 = src bank, \2 = dst bank

    ld      hl,$D000 ; Base address of the map!

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)
        push    hl

            ; Read source data first

            ld      a,\1
            ld      [rSVBK],a

            ld      bc,0 ; bc = accumulator

            push    hl
                push    de
                dec     d
                MAP_READ_CLAMPED ; e = x, d = y, returns a = tile, preserves bc
                pop     de
                add     a,c
                ld      c,a
                ld      a,0
                adc     a,b
                ld      b,a ; bc += tile

                push    de
                inc     d
                MAP_READ_CLAMPED
                pop     de
                add     a,c
                ld      c,a
                ld      a,0
                adc     a,b
                ld      b,a

                push    de
                dec     e
                MAP_READ_CLAMPED
                pop     de
                add     a,c
                ld      c,a
                ld      a,0
                adc     a,b
                ld      b,a

                push    de
                inc     e
                MAP_READ_CLAMPED
                pop     de
                add     a,c
                ld      c,a
                ld      a,0
                adc     a,b
                ld      b,a
            pop     hl

            srl     b
            rr      c
            srl     b
            rr      c ; divide by 4

            ld      l,[hl]
            ld      h,0
            add     hl,bc ; hl = C + (L+R+U+D)/4

            srl     h
            rr      l ; divide by 2

            ld      a,l

            ; A = result. It can't overflow to H!

        pop     hl
        pop     de ; (*)

        ld      a,\2 ; set destination bank
        ld      [rSVBK],a

        ld      [hl+],a ; save value, inc hl

        inc     e
        bit     6,e ; CITY_MAP_WIDTH = 64
        jp      z,.loopx

    inc     d
    bit     6,d ; CITY_MAP_HEIGHT = 64
    jp      z,.loopy

    ret

ENDM

map_smooth_1_to_2:
    MAP_SMOOTH_FN   BANK_TEMP1, BANK_TEMP2
map_smooth_2_to_1:
    MAP_SMOOTH_FN   BANK_TEMP2, BANK_TEMP1

;-------------------------------------------------------------------------------

map_generate::

    call    map_initialize ; result is saved to temp bank 1

    call    map_smooth_1_to_2 ; temp bank 1 -> temp bank 2

    call    map_add_circle_all

    call    map_normalize ; bank 2.  ret A = 1 if ok, 0 = start again
    and     a,a
    jr      z,map_generate ; TODO: Check if infinite loop?

    call    map_smooth_2_to_1
    call    map_smooth_1_to_2

    ; TODO : Thresholds to convert to water, field and forest

    ; TODO : Convert to real tiles

    ; TODO : Draw minimap

    ret

;###############################################################################
