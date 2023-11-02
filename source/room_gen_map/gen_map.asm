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

    INCLUDE "engine.inc"
    INCLUDE "hardware.inc"

;-------------------------------------------------------------------------------

    INCLUDE "room_game.inc"
    INCLUDE "tileset_info.inc"

;###############################################################################

    SECTION "Genenerate Map Variables HRAM",HRAM

;-------------------------------------------------------------------------------

seedx: DS 1
seedy: DS 1
seedz: DS 1
seedw: DS 1

fix_map_changed: DS 1

;###############################################################################

    SECTION "Genenerate Map Variables",WRAM0

;-------------------------------------------------------------------------------

circlecount: DS 1

    DEF FIELD_DEFAULT_THRESHOLD  EQU 128
    DEF FOREST_DEFAULT_THRESHOLD EQU 128+24

field_threshold:  DS 1
forest_threshold: DS 1

;###############################################################################

    SECTION "Genenerate Map Code Data",ROMX,ALIGN[8]

;-------------------------------------------------------------------------------

; Aligned to $100

MACRO ABS_CLAMP_ARRAY_GEN ; \1 = number to clamp to

abs_clamp_array_\1: ; returns absolute value up to N-1, clamped to N-1
    DEF VAL = 0 ; 0 to 63
    REPT \1
        DB  VAL
        DEF VAL = VAL+1
    ENDR

    REPT 257+(-\1-\1) ; 64 - 191 (64 to 123, -64 to -128
    DB  \1-1
    ENDR

    DEF VAL = \1+(-1) ; -63 to -1
    REPT \1-1
        DB  VAL
        DEF VAL = VAL+(-1) ; WTF, RGBDS, really?
    ENDR

ENDM

    ABS_CLAMP_ARRAY_GEN 64
    ABS_CLAMP_ARRAY_GEN 32
    ABS_CLAMP_ARRAY_GEN 16
    ABS_CLAMP_ARRAY_GEN 8
    ABS_CLAMP_ARRAY_GEN 4

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

    DS 128 ; align next table!

shift_left_five: ; LSB first, MSB second
    DB $00,$00,$20,$00,$40,$00,$60,$00,$80,$00,$A0,$00,$C0,$00,$E0,$00
    DB $00,$01,$20,$01,$40,$01,$60,$01,$80,$01,$A0,$01,$C0,$01,$E0,$01
    DB $00,$02,$20,$02,$40,$02,$60,$02,$80,$02,$A0,$02,$C0,$02,$E0,$02
    DB $00,$03,$20,$03,$40,$03,$60,$03,$80,$03,$A0,$03,$C0,$03,$E0,$03

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

    INCLUDE "gen_map_circle.inc"

;-------------------------------------------------------------------------------

; X and Y are signed 8 bit values
; b = x, a = y
MACRO IS_INSIDE_CIRCLE ; \1 = radius

    ; Get absolute clamped value

    ld      h,(abs_clamp_array_\1)>>8
    ld      l,b
    ld      b,[hl]
    ld      l,a
    ld      l,[hl] ; Y = L. Prepare for next step

    ; Get offset

IF \1 == 64
    ld      h,shift_left_six>>8 ; Y << 6
    sla     l
    ld      a,[hl+] ; LSB
    ld      h,[hl] ; MSB
ENDC
IF \1 == 32
    ld      h,shift_left_five>>8 ; Y << 5
    sla     l
    ld      a,[hl+] ; LSB
    ld      h,[hl] ; MSB
ENDC
IF \1 == 16
    ld      h,0
    ld      a,l
    add     a,a
    add     a,a
    add     a,a
    add     a,a
ENDC
IF \1 == 8
    ld      h,0
    ld      a,l
    add     a,a
    add     a,a
    add     a,a
ENDC
IF \1 == 4
    ld      h,0
    ld      a,l
    add     a,a
    add     a,a
ENDC

    or      a,b ; or X
    ld      l,a
    ; Access array

    ld      de,gen_map_circle_\1
    add     hl,de

    ld      a,[hl]

ENDM

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
    DEF BANK_TEMP1 EQU BANK_CITY_MAP_TYPE
    DEF BANK_TEMP2 EQU BANK_CITY_MAP_TRAFFIC
    DEF BANK_TILES EQU BANK_CITY_MAP_TILES

;-------------------------------------------------------------------------------

MACRO MAP_READ_CLAMPED ; e = x, d = y, returns value in a, preserves bc

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

    ; initialize tile bank to random values

    ld      a,BANK_TEMP1
    ldh     [rSVBK],a

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

    DEF STEP_INCREMENT EQU 16 ; Amount to be added with each circle

MACRO ADD_CIRCLE ; \1 = radius

map_add_circle_\1:

    ; b = x, c = y
    ; coordinates of top left corner of the circle at top left corner of the map

    ld      d,1-\1 ; d = y
.loopy:

        ld      e,1-\1 ; e = x
.loopx:

        push    bc
        push    de ; (*)

        ld      b,e ; x
        ld      a,d ; y
        IS_INSIDE_CIRCLE    \1 ; b = x, a = y

        pop     de ; (*)
        pop     bc

        push    bc

        and     a,a
        jr      z,.dontadd

            push    de ; (***)

            LD_DE_BC
            xor     a,a
            sub     a,d
            ld      d,a
            xor     a,a
            sub     a,e ; e = x, d = y
            ld      e,a ; x = -x, y = -y
            pop     bc ; base coordinates of circle
            push    bc
            ld      a,b
            add     a,e
            add     a,\1
            ld      e,a
            ld      a,c
            add     a,d
            add     a,\1
            ld      d,a ; add coordinates inside circle

            or      a,e ; a = x|y
            and     a,(~63)&$FF ; check if outside the map
            jr      nz,.outsidebounds
                GET_MAP_ADDRESS ; e = x , d = y (0 to 63). preserves de and bc
                ld      a,[circlecount]
                and     a,1
                jr      nz,.negative
                    ld      a,STEP_INCREMENT
                    add     a,[hl]
                    jr      nc,.not_positive_overflow
                    ld      a,255
.not_positive_overflow:
                    ld      [hl],a
                jr      .endsetsign
.negative:
                    ld      a,-STEP_INCREMENT
                    add     a,[hl]
                    jr      c,.not_negative_overflow
                    ld      a,0
.not_negative_overflow:
                    ld      [hl],a
.endsetsign:
.outsidebounds:

            pop     de ; (***)

.dontadd:

        pop     bc

        inc     e
        ld      a,\1
        cp      a,e
        jr      nz,.loopx

    inc     d
    ld      a,\1
    cp      a,d
    jr      nz,.loopy

    ret

ENDM

map_add_circle: ; a = radius, b,c = coordinates of top left corner

    ld      d,a ; d = radius

    xor     a,a
    sub     a,b
    ld      b,a ; x = -x
    xor     a,a
    sub     a,c
    ld      c,a ; y = -y

    ld      a,64
    cp      a,d
    jp      z,map_add_circle_64
    ld      a,32
    cp      a,d
    jp      z,map_add_circle_32
    ld      a,16
    cp      a,d
    jp      z,map_add_circle_16
    ld      a,8
    cp      a,d
    jp      z,map_add_circle_8
    ld      a,4
    cp      a,d
    jp      z,map_add_circle_4

    ld      b,b ; Shouldn't happen!
    ret

    ADD_CIRCLE 64
    ADD_CIRCLE 32
    ADD_CIRCLE 16
    ADD_CIRCLE 8
    ADD_CIRCLE 4

;-------------------------------------------------------------------------------

map_add_circle_all:

    xor     a,a
    ld      [circlecount],a

    ld      a,BANK_TEMP2
    ldh     [rSVBK],a

    ld      hl,.circle_radius_array

.loop:

    ld      a,[hl+]
    and     a,a ; exit if 0
    ret     z

    push    hl

        ; Calculate starting coordinates for the circle
        ; x,y = (rand() & (MAP_W - 1)) + (rand() & (R-1)) - R/2

        push    af ; preserve radius

        call    gen_map_rand ; returns a = random number. Preserves DE
        ld      d,a
        call    gen_map_rand ; returns a = random number. Preserves DE
        ld      e,a
        push    de
        call    gen_map_rand ; returns a = random number. Preserves DE
        ld      d,a
        call    gen_map_rand ; returns a = random number. Preserves DE
        ld      e,a
        pop     bc

        pop     af

        ; a = radius
        ; b,c,d,e = rand()

        ld      h,a ; preserve radius

        ld      a,CITY_MAP_WIDTH-1
        and     a,b
        ld      b,a
        ld      a,CITY_MAP_HEIGHT-1
        and     a,c
        ld      c,a ; b, c = rand() & (MAP_W -1)

        ld      a,h ; get radius
        dec     a

        ld      l,a ; save temp

        ld      a,d
        and     a,l
        ld      d,a
        ld      a,e
        and     a,l
        ld      e,a ; d,e = (rand() & (R-1))

        ld      a,h ; get R
        sra     a ; R/2
        ld      l,a ;save temp

        ld      a,d
        sub     a,l
        ld      d,a
        ld      a,e
        sub     a,l
        ld      e,a ; d,e = (rand() & (R-1)) - R/2

        ld      a,b
        add     a,d
        ld      b,a
        ld      a,c
        add     a,e
        ld      e,a ; b,c = final values

        ld      a,h ; get radius

        ; a = radius
        ; b,c = coordinates

        call    map_add_circle

        ld      hl,circlecount
        inc     [hl]

    pop     hl

    jr      .loop

.circle_radius_array: ; Must be powers of 2 (4 to 64 only)
    DB 64, 64
    DB 32, 32, 32, 32
    DB 16, 16, 16, 16, 16, 16, 16, 16
    DB  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8
    DB  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4
    DB  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4
    DB  0

;-------------------------------------------------------------------------------

map_normalize: ; normalizes bank 2

    ld      a,BANK_TEMP2
    ldh     [rSVBK],a

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

    ; a = average
    cpl
    add     a,1
    ld      c,a
    ld      a,$FF
    adc     a,0
    ld      b,a ; bc = -average

    ; Add 128 to the result so instead of 0 being the average value, use 128
    ld      hl,128

    add     hl,bc
    LD_BC_HL ; BC = value we have to add to all the tiles

    ld      de,CITY_MAP_TILES

    ld      h,0 ; sign expand tile values (they are 0-255)

.loop_normalize:

        ld      a,[de]
        ld      l,a ; hl = tile
        add     hl,bc ; add value

        ; Clamp HL to 0,255

        ; The only possibilities after the addition are negative numbers or
        ; positive values in the range 0-510

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

MACRO MAP_SMOOTH_FN ; \1 = src bank, \2 = dst bank

    ld      hl,CITY_MAP_TILES ; Base address of the map!

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)
        push    hl

            ; Read source data first

            ld      a,\1
            ldh     [rSVBK],a

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

            ld      a,\2 ; set destination bank
            ldh     [rSVBK],a

            ld      a,l

            ; A = result. It can't overflow to H!

        pop     hl
        pop     de ; (*)

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

map_apply_height_threshold:

    ld      a,BANK_TEMP2
    ldh     [rSVBK],a

    ld      hl,CITY_MAP_TILES

    ld      a,[field_threshold]
    ld      b,a
    ld      a,[forest_threshold]
    ld      c,a

.loop:
    ld      a,[hl]

    cp      a,b ; cy = 1 if b > a
    jr      c,.water
    cp      a,c ; cy = 1 if c > a
    jr      c,.field
    ;jr      .forest
.forest:
    ld      a,T_FOREST
    jr      .end_selection
.field:
    ld      a,T_GRASS
    jr      .end_selection
.water:
    ld      a,T_WATER
.end_selection:

    ld      [hl+],a

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

;-------------------------------------------------------------------------------

MACRO FIX_TILE_TYPE ; \1 = T_WATER or T_FOREST

.start:
    xor     a,a
    ld      [fix_map_changed],a

    ld      hl,CITY_MAP_TILES ; Base address of the map!

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        ld      a,[hl]
        cp      a,\1
        jp      nz,.skip_tile

        push    de ; (*)
        push    hl

            ld      b,0

            push    de
            dec     d
            dec     e
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip0
            set     0,b
.skip0:     pop     de

            push    de
            dec     d
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip1
            set     1,b
.skip1:     pop     de

            push    de
            dec     d
            inc     e
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip2
            set     2,b
.skip2:     pop     de

            push    de
            dec     e
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip3
            set     3,b
.skip3:     pop     de

            push    de
            inc     e
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip4
            set     4,b
.skip4:     pop     de

            push    de
            inc     d
            dec     e
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip5
            set     5,b
.skip5:     pop     de

            push    de
            inc     d
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip6
            set     6,b
.skip6:     pop     de

            push    de
            inc     d
            inc     e
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip7
            set     7,b
.skip7:     pop     de

        ; b = data read

        ld      hl,FIX_TILES ; ptr to array
.loop_search:
        ld      a,[hl+] ; mask
        ld      c,a
        ld      a,[hl+] ; expected result
        ld      d,a
        ld      a,[hl+] ; result tile
        ld      e,a

        ld      a,b
        and     a,c
        cp      a,d
        jr      nz,.loop_search

        pop     hl
        push    hl

        ld      a,e ; e = result
        and     a,a
        jr      nz,.leave_tile

            ld      a,T_GRASS
            ld      [hl],a
            ld      a,1
            ld      [fix_map_changed],a

.leave_tile:
.end_tile:

        pop     hl
        pop     de ; (*)

.skip_tile:

        inc     hl

        inc     e
        bit     6,e ; CITY_MAP_WIDTH = 64
        jp      z,.loopx

    inc     d
    bit     6,d ; CITY_MAP_HEIGHT = 64
    jp      z,.loopy

    ld      a,[fix_map_changed]
    and     a,a
    jp      nz,.start

ENDM

    ; From more restrictive to less restrictive

    ; 0 1 2
    ; 3 . 4 <- Bit order
    ; 5 6 7

FIX_TILES: ; MASK, EXPECTED RESULT, TILE VALID

    ; 1 = Tile (water or  forest), 0 = No tile

    DB %11111111,%11111111,1

    DB %11111111,%01111111,1
    DB %11111111,%11011111,1
    DB %11111111,%11111011,1
    DB %11111111,%11111110,1

    DB %01011111,%00011111,1
    DB %11111010,%11111000,1
    DB %01111011,%01101011,1
    DB %11011110,%11010110,1

    DB %01011011,%00001011,1
    DB %01011110,%00010110,1
    DB %01111010,%01101000,1
    DB %11011010,%11010000,1

    DB %00000000,%00000000,0 ; Default -> Remove tile


map_fix_water:
    FIX_TILE_TYPE T_WATER
    ret

map_fix_forest:
    FIX_TILE_TYPE T_FOREST
    ret

;-------------------------------------------------------------------------------

map_tilemap_fix: ; fix invalid patterns of tiles

    ld      a,BANK_TEMP2
    ldh     [rSVBK],a

    ; Fix water and forest tiles

    call    map_fix_water
    call    map_fix_forest

    ret

;-------------------------------------------------------------------------------

MACRO COARSE_TILES_TO_TILESET ; \1 = T_WATER/T_FOREST, \2 = array

    ; Switch to bank with original data

    ld      a,BANK_TEMP2
    ldh     [rSVBK],a

    ld      hl,CITY_MAP_TILES ; Base address of the map!

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        ld      a,[hl]
        cp      a,\1
        jp      nz,.skip_tile

        push    de ; (*)
        push    hl

            ld      b,0

            push    de
            dec     d
            dec     e
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip0
            set     0,b
.skip0:     pop     de

            push    de
            dec     d
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip1
            set     1,b
.skip1:     pop     de

            push    de
            dec     d
            inc     e
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip2
            set     2,b
.skip2:     pop     de

            push    de
            dec     e
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip3
            set     3,b
.skip3:     pop     de

            push    de
            inc     e
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip4
            set     4,b
.skip4:     pop     de

            push    de
            inc     d
            dec     e
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip5
            set     5,b
.skip5:     pop     de

            push    de
            inc     d
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip6
            set     6,b
.skip6:     pop     de

            push    de
            inc     d
            inc     e
            MAP_READ_CLAMPED ; e = x, d = y, return = a, preserves bc
            cp      a,\1
            jr      nz,.skip7
            set     7,b
.skip7:     pop     de

        ; b = data read

        ld      hl,\2 ; ptr to array
.loop_search:
        ld      a,[hl+] ; mask
        ld      c,a
        ld      a,[hl+] ; expected result
        ld      d,a
        ld      a,[hl+] ; result tile
        ld      e,a

        ld      a,b
        and     a,c
        cp      a,d
        jr      nz,.loop_search

        pop     hl
        push    hl

        ; e = resulting tile

        ; Switch to bank with destination data

        ld      a,BANK_TILES
        ldh     [rSVBK],a

        ld      [hl],e

        ; Switch to bank with original data

        ld      a,BANK_TEMP2
        ldh     [rSVBK],a

        pop     hl
        pop     de ; (*)

.skip_tile:

        inc     hl

        inc     e
        bit     6,e ; CITY_MAP_WIDTH = 64
        jp      z,.loopx

    inc     d
    bit     6,d ; CITY_MAP_HEIGHT = 64
    jp      z,.loopy

ENDM

    ; From more restrictive to less restrictive

    ; 0 1 2
    ; 3 . 4 <- Bit order
    ; 5 6 7

WATER_TILES: ; MASK, EXPECTED RESULT, RESULTING TILE

    ; 1 = Water, 0 = Grass or forest

    DB %11111111,%11111111,T_WATER

    DB %11111111,%01111111,T_WATER__GRASS_CORNER_BR
    DB %11111111,%11011111,T_WATER__GRASS_CORNER_BL
    DB %11111111,%11111011,T_WATER__GRASS_CORNER_TR
    DB %11111111,%11111110,T_WATER__GRASS_CORNER_TL

    DB %01011111,%00011111,T_WATER__GRASS_BC
    DB %11111010,%11111000,T_WATER__GRASS_TC
    DB %01111011,%01101011,T_WATER__GRASS_CR
    DB %11011110,%11010110,T_WATER__GRASS_CL

    DB %01011011,%00001011,T_WATER__GRASS_BR
    DB %01011110,%00010110,T_WATER__GRASS_BL
    DB %01111010,%01101000,T_WATER__GRASS_TR
    DB %11011010,%11010000,T_WATER__GRASS_TL

    DB %00000000,%00000000,T_INDUSTRIAL ; Default -> Error!

FOREST_TILES: ; MASK, EXPECTED RESULT, RESULTING TILE

    ; 1 = Forest, 0 = Grass or water

    DB %11111111,%11111111,T_FOREST

    DB %11111111,%01111111,T_GRASS__FOREST_TL
    DB %11111111,%11011111,T_GRASS__FOREST_TR
    DB %11111111,%11111011,T_GRASS__FOREST_BL
    DB %11111111,%11111110,T_GRASS__FOREST_BR

    DB %01011111,%00011111,T_GRASS__FOREST_TC
    DB %11111010,%11111000,T_GRASS__FOREST_BC
    DB %01111011,%01101011,T_GRASS__FOREST_CL
    DB %11011110,%11010110,T_GRASS__FOREST_CR

    DB %01011011,%00001011,T_GRASS__FOREST_CORNER_TL
    DB %01011110,%00010110,T_GRASS__FOREST_CORNER_TR
    DB %01111010,%01101000,T_GRASS__FOREST_CORNER_BL
    DB %11011010,%11010000,T_GRASS__FOREST_CORNER_BR

    DB %00000000,%00000000,T_INDUSTRIAL ; Default -> Error!

fix_water_border_tiles:
    COARSE_TILES_TO_TILESET T_WATER, WATER_TILES
    ret

fix_forest_border_tiles:
    COARSE_TILES_TO_TILESET T_FOREST, FOREST_TILES
    ret

;-------------------------------------------------------------------------------

; Call this when leaving the map generation room, this is only needed for
; graphics, the minimap itself won't change after this. This uses the values
; left in BANK_TEMP2 from the last map generation.

map_tilemap_to_real_tiles::

    ; Copy map to a new bank
    ; ----------------------

    ; First, we copy the map. Then, we read from the original data and overwrite
    ; the tiles that have to change.

    ld      b,BANK_TEMP2
    ld      c,BANK_TILES
    ld      de,CITY_MAP_TILES
    ld      hl,rSVBK
.loop:
    ld      [hl],b ; rSVBK = BANK_TEMP2

    ld      a,[de]

    ld      [hl],c ; rSVBK = BANK_TILES

    ld      [de],a
    inc     de

    bit     5,d ; Up to E000
    jr      z,.loop

    ; Convert to corners, etc, while moving to BANK_TILES
    ; ---------------------------------------------------

    ; T_GRASS will remain unchanged!

    call    fix_water_border_tiles
    call    fix_forest_border_tiles

    ; Randomize some of the tiles to the alternate versions
    ; -----------------------------------------------------

    ld      a,BANK_TILES
    ldh     [rSVBK],a

    ld      de,CITY_MAP_TILES
.loop_rand:

    call    gen_map_rand ; returns a = random number. Preserves DE

    and     a,63
    inc     a ; advance between 1 and 64 tiles

    ld      l,a
    ld      h,0
    add     hl,de ; increase pointer by rand()
    LD_DE_HL

    bit     5,d ; Up to E000 (but this will catch small overflows)
    jr      nz,.exit_rand

    ld      a,[de]
    cp      a,T_GRASS
    jr      nz,.not_grass
        ld      a,T_GRASS_EXTRA
        ld      [de],a
        jr      .loop_rand
.not_grass:
    cp      a,T_FOREST
    jr      nz,.not_forest
        ld      a,T_FOREST_EXTRA
        ld      [de],a
        jr      .loop_rand
.not_forest:
    cp      a,T_WATER
    jr      nz,.not_water
        ld      a,T_WATER_EXTRA
        ld      [de],a
        ;jr      .loop_rand
.not_water:

    jr      .loop_rand
.exit_rand:

    ; Clear attribute bank. Terrain tiles are always < 256
    ; ----------------------------------------------------

    ; Unfortunately, we still have to set the palettes...

    ld      hl,CITY_MAP_TILES
.loop_fill_attrs:

    ld      a,BANK_CITY_MAP_TILES
    ldh     [rSVBK],a

    ld      c,[hl]
    ld      b,0

    push    hl
    call    CityMapDrawTerrainTileAddress ; bc = tile, hl = address
    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop_fill_attrs

    ret

;-------------------------------------------------------------------------------

GEN_MAP_PALETTE_BLACK:
    DW  0, 0, 0, 0

GEN_MAP_PALETTE:
    DW  0, 31<<5, 31<<10, (31<<10)|(31<<5)|31 ; BLACK, GREEN, BLUE, WHITE

map_draw:

    ld      hl,GEN_MAP_PALETTE_BLACK
    call    APA_LoadPalette

    LONG_CALL   APA_BufferClear
    LONG_CALL   APA_PixelStreamStart

    ld      hl,CITY_MAP_TILES

.loop:

    ld      a,BANK_TEMP2
    ldh     [rSVBK],a

    ld      a,[hl+]

    push    hl

    cp      a,T_FOREST
    jr      z,.green
    cp      a,T_GRASS
    jr      z,.white
    cp      a,T_WATER
    jr      z,.blue
    ;jr      .black

.black:
        ld      a,0
        call    APA_SetColor0
        jr      .endcolorselect
.green:
        ld      a,1
        call    APA_SetColor0
        jr      .endcolorselect
.blue:
        ld      a,2
        call    APA_SetColor0
        jr      .endcolorselect
.white:
        ld      a,3
        call    APA_SetColor0
.endcolorselect:

    LONG_CALL   APA_64x64PixelStreamPlot

    pop     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    call    APA_BufferUpdate

    ld      hl,GEN_MAP_PALETTE
    call    APA_LoadPalette

    ret

;-------------------------------------------------------------------------------

; b = seed x, c = seed y (229)
; d = offset
map_generate:: ; call this with LONG_CALL_ARGS

    ld      a,FIELD_DEFAULT_THRESHOLD
    add     a,d
    ld      [field_threshold],a

    ld      a,FOREST_DEFAULT_THRESHOLD
    add     a,d
    ld      [forest_threshold],a

    ld      a,b
    ld      b,c
    call    gen_map_srand ; a = seed x, b = seed y

    call    map_initialize ; result is saved to temp bank 1

    call    map_smooth_1_to_2 ; temp bank 1 -> temp bank 2

    call    map_add_circle_all

    call    map_normalize ; bank 2

    call    map_smooth_2_to_1
    call    map_smooth_1_to_2

    call    map_apply_height_threshold ; Bank 2. Convert to water/field/forest

    ; Convert to real tiles, not all forms are allowed by the tileset
    call    map_tilemap_fix ; Bank 2 -> Bank 2

    call    map_draw ; Bank 2

    ret

;###############################################################################
