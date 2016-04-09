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

BCD_DE_2TILE_HL:: ; [hl] = BCD2TILE [de] | leading zeros = zeros

    ; Convert to tile from BCD
    ; de - LSB first, LSB in lower nibbles
    ld      bc,9
    add     hl,bc
    ld      b,5
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

    ld      b,9
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

; returns carry = 1 if overflowed, 0 if not. On overflow, 999999999 is set
BCD_HL_ADD_DE:: ; [hl] = [hl] + [de]

    ; Start adding from LSB

    scf
    ccf ; Set+Invert = Clear carry

    REPT 4
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

    ret     nc ; if not carry, it didn't overflow

    ld      a,$99 ; saturate to 9999999999
    REPT    5
    ld      [hl-],a
    ENDR

    scf ; set carry

    ret

;-------------------------------------------------------------------------------

BCD_HL_SUB_DE:: ; [de] = [de] - [hl]

    ; Start subtracting from LSB

    scf
    ccf ; Set+Invert = Clear carry

    ld      b,5
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

BCD_DE_UMUL_B:: ; [de] = [de] * b

    ld      a,b
    and     a,a
    jr      nz,.not_zero

        ; b is 0, return 0
        xor     a,a
        REPT    5
        ld      [de],a
        inc     de
        ENDR
        ret

.not_zero:

    ; Get space for temporary variable
    add     sp,-5
    ld      hl,sp+0

    xor     a,a ; Clear temp
    REPT    5
    ld      [hl+],a
    ENDR

    ; Multiply
.loop_mul:
        scf
        ccf ; Set+Invert = Clear carry

        push    de
        ld      hl,sp+2

        ld      c,5
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
    REPT    5
    ld      a,[hl+]
    ld      [de],a
    inc     de
    ENDR

    ; Reclaim space
    add     sp,+5

    ret

;-------------------------------------------------------------------------------

BCD_HL_GE_DE:: ; Returns 1 if [hl] >= [de]

    REPT    4
    inc     de
    inc     hl
    ENDR

    ; Start comparing from MSB

    REPT    5
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
