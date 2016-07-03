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

;-------------------------------------------------------------------------------

    INCLUDE "text.inc"

;###############################################################################

    SECTION "BCD Math",ROM0

;-------------------------------------------------------------------------------

BCD_NUMBER_LENGHT EQU 5 ; BCD bytes

;-------------------------------------------------------------------------------

BCD_DE_2TILE_HL:: ; [hl] = BCD2TILE [de] | leading zeros = zeros

    ; Convert to tile from BCD
    ; de - LSB first, LSB in lower nibbles
    ld      bc,BCD_NUMBER_LENGHT*2-1
    add     hl,bc
    ld      b,BCD_NUMBER_LENGHT
.loop_decode:
    ld      a,[de]
    inc     de
    ld      c,a

    and     a,$0F
    add     a,O_ZERO
    ld      [hl-],a

    ld      a,c
    swap    a
    and     a,$0F
    add     a,O_ZERO
    ld      [hl-],a

    dec     b
    jr      nz,.loop_decode

    ret

BCD_DE_2TILE_HL_LEADING_SPACES:: ; [hl] = BCD2TILE [de] | leading zeros = spaces

    call    BCD_DE_2TILE_HL

    ld      b,BCD_NUMBER_LENGHT*2-1
    inc     hl
.loop_zero:
    ld      a,[hl]
    cp      a,O_ZERO
    jr      nz,.end
    ld      a,O_SPACE
    ld      [hl+],a
    dec     b
    jr      nz,.loop_zero
.end:
    ret

;-------------------------------------------------------------------------------

; leading zeros are printed as spaces
BCD_SIGNED_DE_2TILE_HL_LEADING_SPACES:: ; [hl] = BCD2TILE [de]

    push    hl
    call    BCD_DE_LW_ZERO ; Returns a = 1 if [de] < 0, preserves de
    pop     hl
    and     a,a
    jr      nz,.negative

        push    hl
        call    BCD_DE_2TILE_HL_LEADING_SPACES
        pop     hl
        ld      [hl],O_SPACE ; space instead of minus sign
        ret

.negative:

    ; Negative number

    ; Change sign  number and save it to stack. DE won't be needed after this

    add     sp,-BCD_NUMBER_LENGHT ; (*)

    push    hl

    ld      hl,sp+2 ; because of the push hl

    ld      a,h
    ld      h,d
    ld      d,a
    ld      a,l
    ld      l,e
    ld      e,a ; swap de and hl

    push    de
    call    BCD_DE_NEG_HL ; [de] = 0 - [hl]
    pop     de
    pop     hl

    ; de = negated number
    ; hl = destination

    push    hl
    call    BCD_DE_2TILE_HL_LEADING_SPACES
    pop     hl

    ; Check where the first digit is printed
    ld      b,9 ; Limit loop to 10-1 digits (don't overwrite the last digit!)
.search_dash_loop:
    inc     hl
    ld      a,[hl]
    cp      a,O_SPACE
    jr      z,.space
        dec     hl
        jr      .end_loop
.space:
    dec     b
    jr      nz,.search_dash_loop

.end_loop:
    ld      [hl],O_DASH ; replace first digit by minus sign

    add     sp,+BCD_NUMBER_LENGHT ; (*)

    ret

;-------------------------------------------------------------------------------

BCD_HL_ADD_DE:: ; [hl] = [hl] + [de]

    ; Start adding from LSB

    scf
    ccf ; Set+Invert = Clear carry

    REPT    BCD_NUMBER_LENGHT+-1 ; The +- is a fix for rgbasm
    ld      a,[de]
    adc     a,[hl]
    daa ; yeah, really
    ld      [hl+],a
    inc     de
    ENDR
    ld      a,[de]
    adc     a,[hl]
    daa
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------

BCD_HL_SUB_DE:: ; [de] = [de] - [hl]

    ; Start subtracting from LSB

    scf
    ccf ; Set+Invert = Clear carry

    ld      b,BCD_NUMBER_LENGHT
.loop:
        ld      a,[de]
        sbc     a,[hl]
        daa ; yeah, really
        ld      [de],a
        inc     de
        inc     hl
    dec     b
    jr      nz,.loop

    ret

;-------------------------------------------------------------------------------

BCD_DE_NEG_HL:: ; [de] = 0 - [hl]

    ; Start subtracting from LSB

    scf
    ccf ; Set+Invert = Clear carry

    ld      c,0
    ld      b,BCD_NUMBER_LENGHT
.loop:
        ld      a,c ; zero
        sbc     a,[hl]
        daa ; yeah, really
        ld      [de],a
        inc     de
        inc     hl
    dec     b
    jr      nz,.loop

    ret

;-------------------------------------------------------------------------------

BCD_DE_UMUL_B:: ; [de] = [de] * b

    ld      a,b
    and     a,a
    jr      nz,.not_zero

        ; b is 0, return 0
        xor     a,a
        REPT    BCD_NUMBER_LENGHT
        ld      [de],a
        inc     de
        ENDR
        ret

.not_zero:

    ; Get space for temporary variable
    add     sp,-BCD_NUMBER_LENGHT
    ld      hl,sp+0

    xor     a,a ; Clear temp
    REPT    BCD_NUMBER_LENGHT
    ld      [hl+],a
    ENDR

    ; Multiply
.loop_mul:
        scf
        ccf ; Set+Invert = Clear carry

        push    de
        ld      hl,sp+2

        ld      c,BCD_NUMBER_LENGHT
.loop:
            ; Start adding from LSB
            ld      a,[de]
            adc     a,[hl]
            daa ; yeah, really
            ld      [hl+],a
            inc     de
        dec     c
        jr      nz,.loop

        pop     de

    dec     b
    jr      nz,.loop_mul

    ; Save result in [de]
    ld      hl,sp+0
    REPT    BCD_NUMBER_LENGHT
    ld      a,[hl+]
    ld      [de],a
    inc     de
    ENDR

    ; Reclaim space
    add     sp,+BCD_NUMBER_LENGHT

    ret

;-------------------------------------------------------------------------------

BCD_DE_LW_ZERO:: ; Returns a = 1 if [de] < 0, preserves de

    ld      hl,BCD_NUMBER_LENGHT-1 ; last byte
    add     hl,de
    ld      a,[hl] ; get MSB
    cp      a,$50 ; carry flag is set if $50 > a (a has a positive number)
    jr      nc,.negative

    xor     a,a
    ret

.negative:
    ld      a,1
    ret

;-------------------------------------------------------------------------------

BCD_HL_GE_DE:: ; Returns 1 if [hl] >= [de]

    REPT    BCD_NUMBER_LENGHT+-1 ; The +- is a fix for rgbasm
    inc     de
    inc     hl
    ENDR

    ; Start comparing from MSB

    REPT    BCD_NUMBER_LENGHT
    ld      a,[de]
    cp      a,[hl]
    jr      z,.dont_exit\@
    jr      c,.enough
    xor     a,a
    ret
.dont_exit\@:
    dec     de
    dec     hl
    ENDR ; If this loop is exited here it's because we have the exact amount.

.enough:
    ld      a,1
    ret

;###############################################################################

    SECTION "Binary to BCD Array",ROM0[$3D00]

;-------------------------------------------------------------------------------

BINARY_TO_BCD:: ; 2 bytes per entry. LSB first
    DB 00,00, 01,00, 02,00, 03,00, 04,00, 05,00, 06,00, 07,00
    DB 08,00, 09,00, 10,00, 11,00, 12,00, 13,00, 14,00, 15,00
    DB 16,00, 17,00, 18,00, 19,00, 20,00, 21,00, 22,00, 23,00
    DB 24,00, 25,00, 26,00, 27,00, 28,00, 29,00, 30,00, 31,00
    DB 32,00, 33,00, 34,00, 35,00, 36,00, 37,00, 38,00, 39,00
    DB 40,00, 41,00, 42,00, 43,00, 44,00, 45,00, 46,00, 47,00
    DB 48,00, 49,00, 50,00, 51,00, 52,00, 53,00, 54,00, 55,00
    DB 56,00, 57,00, 58,00, 59,00, 60,00, 61,00, 62,00, 63,00
    DB 64,00, 65,00, 66,00, 67,00, 68,00, 69,00, 70,00, 71,00
    DB 72,00, 73,00, 74,00, 75,00, 76,00, 77,00, 78,00, 79,00
    DB 80,00, 81,00, 82,00, 83,00, 84,00, 85,00, 86,00, 87,00
    DB 88,00, 89,00, 90,00, 91,00, 92,00, 93,00, 94,00, 95,00
    DB 96,00, 97,00, 98,00, 99,00, 00,01, 01,01, 02,01, 03,01
    DB 04,01, 05,01, 06,01, 07,01, 08,01, 09,01, 10,01, 11,01
    DB 12,01, 13,01, 14,01, 15,01, 16,01, 17,01, 18,01, 19,01
    DB 20,01, 21,01, 22,01, 23,01, 24,01, 25,01, 26,01, 27,01
    DB 28,01, 29,01, 30,01, 31,01, 32,01, 33,01, 34,01, 35,01
    DB 36,01, 37,01, 38,01, 39,01, 40,01, 41,01, 42,01, 43,01
    DB 44,01, 45,01, 46,01, 47,01, 48,01, 49,01, 50,01, 51,01
    DB 52,01, 53,01, 54,01, 55,01, 56,01, 57,01, 58,01, 59,01
    DB 60,01, 61,01, 62,01, 63,01, 64,01, 65,01, 66,01, 67,01
    DB 68,01, 69,01, 70,01, 71,01, 72,01, 73,01, 74,01, 75,01
    DB 76,01, 77,01, 78,01, 79,01, 80,01, 81,01, 82,01, 83,01
    DB 84,01, 85,01, 86,01, 87,01, 88,01, 89,01, 90,01, 91,01
    DB 92,01, 93,01, 94,01, 95,01, 96,01, 97,01, 98,01, 99,01
    DB 00,02, 01,02, 02,02, 03,02, 04,02, 05,02, 06,02, 07,02
    DB 08,02, 09,02, 10,02, 11,02, 12,02, 13,02, 14,02, 15,02
    DB 16,02, 17,02, 18,02, 19,02, 20,02, 21,02, 22,02, 23,02
    DB 24,02, 25,02, 26,02, 27,02, 28,02, 29,02, 30,02, 31,02
    DB 32,02, 33,02, 34,02, 35,02, 36,02, 37,02, 38,02, 39,02
    DB 40,02, 41,02, 42,02, 43,02, 44,02, 45,02, 46,02, 47,02
    DB 48,02, 49,02, 50,02, 51,02, 52,02, 53,02, 54,02, 55,02

;###############################################################################
