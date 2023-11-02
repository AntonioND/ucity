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

;###############################################################################
;#                                                                             #
;#                             GENERAL FUNCTIONS                               #
;#                                                                             #
;###############################################################################

    SECTION "Utils",ROM0

;-------------------------------------------------------------------------------
;- memset()    d = value    hl = start address    bc = size                    -
;-------------------------------------------------------------------------------

memset::

    ld      a,d
    ld      [hl+],a
    dec     bc
    ld      a,b
    or      a,c
    jr      nz,memset

    ret

;-------------------------------------------------------------------------------
;- memset_fast()    a = value    hl = start address    b = size                -
;-------------------------------------------------------------------------------

memset_fast::

    ld      [hl+],a
    dec     b
    jr      nz,memset_fast

    ret

;-------------------------------------------------------------------------------
;- memset_rand()    hl = start address    bc = size                            -
;-------------------------------------------------------------------------------

memset_rand::

    push    hl
    call    GetRandom
    pop     hl
    ld      [hl+],a
    dec     bc
    ld      a,b
    or      a,c
    jr      nz,memset_rand

    ret

;-------------------------------------------------------------------------------
;- memcopy()    bc = size    hl = source address    de = dest address          -
;-------------------------------------------------------------------------------

memcopy:: ; hl and de must be incremented at the end of this

    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     bc
    ld      a,b
    or      a,c
    jr      nz,memcopy

    ret

;-------------------------------------------------------------------------------
;- memcopy_fast()    b = size    hl = source address    de = dest address      -
;-------------------------------------------------------------------------------

memcopy_fast:: ; hl and de must be incremented at the end of this

    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,memcopy_fast

    ret

;-------------------------------------------------------------------------------
;- memcopy_inc()    b = size    c = increase_src    hl = src    de = dst       -
;-------------------------------------------------------------------------------

memcopy_inc:: ; hl and de should be incremented at the end of this

    ld      a,[hl]
    ld      [de],a

    inc     de ; increase dest

    ld      a,b ; save b
    ld      b,$00
    add     hl,bc ; increase source
    ld      b,a ; restore b

    dec     b
    jr      nz,memcopy_inc

    ret

;###############################################################################
;#                                                                             #
;#                                    MATH                                     #
;#                                                                             #
;###############################################################################

    SECTION "MathFunctions",ROM0

;-------------------------------------------------------------------------------
;- mul_u8u8u16()    hl = result    a,c = initial values    de preserved        -
;-------------------------------------------------------------------------------

mul_u8u8u16:: ; super fast unrolled multiplication

    ; 4 + 7 * [6/5] + [10/7] = [56/46] Cycles, including return :)

    ld      b,$00      ; 2
    ld      h,a        ; 1  -> 4
    ld      l,b        ; 1

    REPT 7

    add     hl,hl      ; 2            ; bits 7 to 1
    jr      nc,.skip\@ ; 3/2 -> 6/5
    add     hl,bc      ; 2
.skip\@:

    ENDR

    add     hl,hl      ; 2            ; bit 0
    ret     nc         ; 5/2 -> 10/7
    add     hl,bc      ; 2
    ret                ; 4

IF    0 ; Old version

    ld      hl,$0000
    ld      b,h
.nextbit:
    bit     0,a
    jr      z,.no_add
    add     hl,bc
.no_add:
    sla     c
    rl      b ; bc <<= 1
    srl     a ; a >>= 1
    jr      nz,.nextbit

    ret

ENDC

;-------------------------------------------------------------------------------
;- mul_s8u8s16()    hl = returned value    a,c = values (a is signed)          -
;-------------------------------------------------------------------------------

mul_s8u8s16::

    ld      e,a
    bit     7,e
    jr      nz,.negative
    call    mul_u8u8u16
    ret

.negative:
    cpl
    inc     a
    call    mul_u8u8u16
    ld      a,h
    cpl
    ld      h,a
    ld      a,l
    cpl
    ld      l,a
    inc     hl
    ret

;-------------------------------------------------------------------------------
;- div_u8u8u8()     a / b -> c     a % b -> a                                  -
;-------------------------------------------------------------------------------

div_u8u8u8::

    inc     b
    dec     b
    jr      z,.div_by_zero ; check if divisor is 0

    ld      c,$FF ; -1
.continue:
    inc     c
    sub     a,b ; if a > b then a -= b , c ++
    jr      nc,.continue ; if a > b continue

    add     a,b ; fix remainder
    and     a,a ; clear carry
    ret

.div_by_zero
    ld      a,$FF
    ld      c,$00
    scf ; set carry
    ret

;-------------------------------------------------------------------------------
;- div_s8s8s8()     a / b -> c     a % b -> a                                  -
;-------------------------------------------------------------------------------

div_s8s8s8::

    ld      e ,$00 ; bit 0 of e = result sign (0/1 = +/-)

    bit     7,a
    jr      z,.dividend_is_positive
    inc     e
    cpl ; change sign
    inc     a
.dividend_is_positive:

    bit     7,b
    jr      z,.divisor_is_positive
    ld      c,a
    ld      a,b
    cpl
    inc     a
    ld      b,a ; change sign
    inc     e
.divisor_is_positive:

    call    div_u8u8u8
    ret     c ; if division by 0, exit now

    bit     0,e
    ret     z ; exit if both signs are the same

    ld      b,a ; save modulo
    ld      a,c ; change sign
    cpl
    inc     a
    ld      c,a
    ld      a,b ; get modulo

    ret

;-------------------------------------------------------------------------------
;- div_u16u7u16()     hl / c -> hl     hl % c -> a                             -
;-------------------------------------------------------------------------------

; Restoring 16-bit / 8-bit Unsigned
; http://map.grauw.nl/sources/external/z80bits.html
; Actually it only supports 7 bit values in c.

div_u16u7u16:

    xor     a,a

    REPT    16
        add     hl,hl
        rla
        cp      a,c
        jr      c,.skip\@
        sub     a,c
        inc     l
.skip\@:
    ENDR

    ret

;###############################################################################
;#                                                                             #
;#                                JOYPAD HANDLER                               #
;#                                                                             #
;###############################################################################

    SECTION "JoypadHandlerVariables",HRAM

;-------------------------------------------------------------------------------

_joy_old:       DS 1
joy_held::      DS 1
joy_pressed::   DS 1
joy_released::  DS 1

;###############################################################################

    SECTION "JoypadHandler",ROM0

;-------------------------------------------------------------------------------
;- scan_keys()                                                                 -
;-------------------------------------------------------------------------------

scan_keys::

    ld      a,[joy_held]
    ld      [_joy_old],a ; current state = old state
    ld      c,a          ; c = old state

    ld      a,$10
    ldh     [rP1],a ; select P14
    ldh     a,[rP1]
    ldh     a,[rP1] ; wait a few cycles
    cpl             ; complement A
    and     a,$0F   ; get only first 4 bits
    swap    a       ; swap it
    ld      b,a     ; store A in B
    ld      a,$20
    ldh     [rP1],a ; select P15
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1] ; Wait a few MORE cycles
    cpl
    and     a,$0F
    or      a,b     ; put A and B together

    ld      [joy_held],a

    ld      b,a ; b = current state
    ld      a,c ; c = old state
    cpl         ; a = not a
    and     a,b ; pressed = (NOT old) AND current

    ld      [joy_pressed],a

    ld      a,$00   ; deselect P14 and P15
    ldh     [rP1],a ; RESET Joypad

    ld      a,[_joy_old]
    ld      b,a ; b = old state
    ld      a,[joy_held] ; a = current state
    cpl     ; released = old and not current
    and     a,b
    ld      [joy_released],a

    ret

;###############################################################################
;#                                                                             #
;#                                  ROM HANDLER                                #
;#                                                                             #
;###############################################################################

    SECTION "ROM Handler Stack",WRAM0

;-------------------------------------------------------------------------------

rom_stack:      DS $20

;###############################################################################

    SECTION "ROM Handler Variables",HRAM

;-------------------------------------------------------------------------------

rom_position:   DS 1

;###############################################################################

    SECTION "ROM Handler",ROM0

;-------------------------------------------------------------------------------
;- rom_handler_init()                                                          -
;-------------------------------------------------------------------------------

rom_handler_init::

    xor     a,a
    ldh     [rom_position],a

    ld      b,1
    call    rom_bank_set  ; select rom bank 1

    ret

;-------------------------------------------------------------------------------
;- rom_bank_pop()                                                              -
;-------------------------------------------------------------------------------

rom_bank_pop:: ; preserves bc and de

    di

    ld      hl,rom_stack

    ld      hl,rom_position
    dec     [hl]
    ld      a,[hl]

    ld      hl,rom_stack

    add     a,l
    ld      l,a
    ld      a,0 ; don't change to 'xor a,a'!
    adc     a,h ; hl += a
    ld      h,a ; hl now holds the pointer to the bank we want to change to
    ld      a,[hl] ; and a the bank we want to change to

    ld      [rROMB0],a ; select rom bank

    reti

;-------------------------------------------------------------------------------
;- rom_bank_push()                                                             -
;-------------------------------------------------------------------------------

rom_bank_push::

    ld      hl,rom_position
    inc     [hl]

    ret

;-------------------------------------------------------------------------------
;- rom_bank_set()    b = bank to change to                                     -
;-------------------------------------------------------------------------------

rom_bank_set:: ; preserves de

    di

    ld      hl,rom_stack

    ldh     a,[rom_position]
    add     a,l
    ld      l,a
    ld      a,0 ; don't change to 'xor a,a'!
    adc     a,h
    ld      h,a

    ld      a,b ; hl = pointer to stack, a = bank to change to

    ld      [hl],a
    ld      [rROMB0],a ; select rom bank

    reti

;-------------------------------------------------------------------------------
;- rom_bank_push_set()    b = bank to change to                                -
;-------------------------------------------------------------------------------

rom_bank_push_set:: ; preserves de

    di

    ld      hl,rom_position
    inc     [hl]
    ld      a,[hl]

    ld      hl,rom_stack
    add     a,l
    ld      l,a
    ld      a,0 ; don't change to 'xor a,a'!
    adc     a,h
    ld      h,a

    ld      a,b ; hl = pointer to stack, a = bank to change to

    ld      [hl],a
    ld      [rROMB0],a ; select rom bank

    reti

;-------------------------------------------------------------------------------
;- ___long_call()    hl = function    b = bank where it is located             -
;-------------------------------------------------------------------------------

___long_call::
    LD_DE_HL
    call    rom_bank_push_set ; preserves DE
    LD_HL_DE
    CALL_HL
    jr      rom_bank_pop

;-------------------------------------------------------------------------------
;- ___long_call_args()    hl = function    a = bank where it is located        -
;-------------------------------------------------------------------------------

; It can use bc and de for passing arguments
; Returned values in any register are preserved through this call
___long_call_args::
    push    bc ; preserve bc and de, they are arguments
    push    hl
    ld      b,a
    call    rom_bank_push_set ; preserves de
    pop     hl
    pop     bc
    CALL_HL
    push    af ; all returned values are useful in principle
    push    hl
    call    rom_bank_pop ; preserves bc and de
    pop     hl
    pop     af
    ret

;###############################################################################
