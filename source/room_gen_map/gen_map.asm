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

;###############################################################################

    SECTION "Genenerate Map Variables",WRAM0

;-------------------------------------------------------------------------------

circlecount: DS 1

;###############################################################################

    SECTION "Genenerate Map Code Data",ROMX[$4000]

;-------------------------------------------------------------------------------

; Aligned to $100

ABS_CLAMP_ARRAY_GEN : MACRO ; \1 = number to clamp to

abs_clamp_array_\1: ; returns absolute value up to N-1, clamped to N-1
VAL SET 0 ; 0 to 63
    REPT \1
    DB  VAL
VAL SET VAL+1
    ENDR

    REPT 257+(-\1-\1) ; 64 - 191 (64 to 123, -64 to -128
    DB  \1-1
    ENDR

VAL SET \1+(-1) ; -63 to -1
    REPT \1-1
    DB  VAL
VAL SET VAL+(-1) ; WTF, RGBDS, really?
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
IS_INSIDE_CIRCLE : MACRO ; \1 = radius

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

STEP_INCREMENT EQU 16 ; Amount to be added with each circle

ADD_CIRCLE : MACRO ; \1 = radius

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
    ld      [rSVBK],a

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

    ; a = average
    cpl
    add     a,1
    ld      c,a
    ld      a,$FF
    adc     a,0
    ld      b,a ; bc = -average

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

            ld      a,\2 ; set destination bank
            ld      [rSVBK],a

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

    ; TODO: Add 0x20 to HL if we want less water

    ld      a,BANK_TEMP2
    ld      [rSVBK],a

    ld      hl,CITY_MAP_TILES

FIELD_THRESHOLD  EQU 128
FOREST_THRESHOLD EQU 128+24

.loop:
    ld      a,[hl]

    cp      a,FIELD_THRESHOLD ; cy = 1 if n > a
    jr      c,.water
    cp      a,FOREST_THRESHOLD ; cy = 1 if n > a
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
    ld      [rSVBK],a

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

map_generate::

    ld      a,21
    ld      b,229
    call    gen_map_srand ; a = seed x, b = seed y

    call    map_initialize ; result is saved to temp bank 1

    call    map_smooth_1_to_2 ; temp bank 1 -> temp bank 2

    call    map_add_circle_all

    call    map_normalize ; bank 2.  ret A = 1 if ok, 0 = start again
    and     a,a
    jr      nz,.map_ok
        ld      b,b ; Not the end of the world, but nice to know as developer...
        jr      map_generate ; TODO: Check if infinite loop?
.map_ok:

    call    map_smooth_2_to_1
    call    map_smooth_1_to_2

    call    map_apply_height_threshold ; Convert to water, field and forest

    ; TODO : Convert to real tiles, not all forms are allowed by the tileset

    call    map_draw

    ret

;###############################################################################
