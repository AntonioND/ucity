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
;- mul_u8u8u16()    hl = returned value    a,c = initial values                -
;-------------------------------------------------------------------------------

mul_u8u8u16:: ; super fast unrolled multiplication

    ; 4 + 7 * [7/6] + [9/6] = [62/52] Cycles, including return :)

    ld      hl,$0000  ; 3   -> 4
    ld      b,l       ; 1

    rla ; bit 7       ; 1
    jr      nc,.skip0 ; 3/2 -> 7/6
    add     hl,bc     ; 2
.skip0:
    add     hl,hl     ; 2

    rla ; bit 6       ; 1
    jr      nc,.skip1 ; 3/2 -> 7/6
    add     hl,bc     ; 2
.skip1:
    add     hl,hl     ; 2

    rla ; bit 5       ; 1
    jr      nc,.skip2 ; 3/2 -> 7/6
    add     hl,bc     ; 2
.skip2:
    add     hl,hl     ; 2

    rla ; bit 4       ; 1
    jr      nc,.skip3 ; 3/2 -> 7/6
    add     hl,bc     ; 2
.skip3:
    add     hl,hl     ; 2

    rla ; bit 3       ; 1
    jr      nc,.skip4 ; 3/2 -> 7/6
    add     hl,bc     ; 2
.skip4:
    add     hl,hl     ; 2

    rla ; bit 2       ; 1
    jr      nc,.skip5 ; 3/2 -> 7/6
    add     hl,bc     ; 2
.skip5:
    add     hl,hl     ; 2

    rla ; bit 1       ; 1
    jr      nc,.skip6 ; 3/2 -> 7/6
    add     hl,bc     ; 2
.skip6:
    add     hl,hl     ; 2

    rla ; bit 0       ; 1
    ret     nc        ; 5/2 -> 9/6
    add     hl,bc     ; 2
    ret               ; 4

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
    ld      [_joy_old],a   ; current state = old state
    ld      c,a            ; c = old state

    ld      a,$10
    ld      [rP1],a  ; select P14
    ld      a,[rP1]
    ld      a,[rP1]  ; wait a few cycles
    cpl              ; complement A
    and     a,$0F    ; get only first 4 bits
    swap    a        ; swap it
    ld      b,a      ; store A in B
    ld      a,$20
    ld      [rP1],a  ; select P15
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]
    ld      a,[rP1]  ; Wait a few MORE cycles
    cpl
    and     a,$0F
    or      a,b      ; put A and B together

    ld      [joy_held],a

    ld      b,a   ; b = current state
    ld      a,c   ; c = old state
    cpl           ; a = not a
    and     a,b   ; pressed = (NOT old) AND current

    ld      [joy_pressed],a

    ld      a,$00    ; deselect P14 and P15
    ld      [rP1],a  ; RESET Joypad

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

    SECTION "RomHandlerVariables",WRAM0

;-------------------------------------------------------------------------------

rom_stack:      DS $20
rom_position:   DS 1

;###############################################################################

    SECTION "RomHandler",ROM0

;-------------------------------------------------------------------------------
;- rom_handler_init()                                                          -
;-------------------------------------------------------------------------------

rom_handler_init::

    xor     a,a
    ld      [rom_position],a

    ld      b,1
    call    rom_bank_set  ; select rom bank 1

    ret

;-------------------------------------------------------------------------------
;- rom_bank_pop()                                                              -
;-------------------------------------------------------------------------------

rom_bank_pop:: ; should preserve bc

    ld      a,[rIE]
    ld      d,a
    xor     a,a
    ld      [rIE],a

    ld      hl,rom_position
    dec     [hl]

    ld      hl,rom_stack

    ld      a,[rom_position]
    add     a,l
    ld      l,a
    ld      a,0
    adc     a,h ; hl += a
    ld      h,a    ; hl now holds the pointer to the bank we want to change to
    ld      a,[hl] ; and a the bank we want to change to

    ld      [rROMB0],a ; select rom bank

    ld      a,d
    ld      [rIE],a

    ret

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

rom_bank_set::

    ld      a,[rIE]
    ld      c,a
    xor     a,a
    ld      [rIE],a

    ld      hl,rom_stack

    ld      d,$00
    ld      a,[rom_position]
    ld      e,a
    add     hl,de

    ld      a,b               ; hl = pointer to stack, a = bank to change to

    ld      [hl],a
    ld      [rROMB0],a        ; select rom bank

    ld      a,c
    ld      [rIE],a

    ret

;-------------------------------------------------------------------------------
;- rom_bank_push_set()    b = bank to change to                                -
;-------------------------------------------------------------------------------

rom_bank_push_set::

    ld      a,[rIE]
    ld      c,a
    xor     a,a
    ld      [rIE],a

    ld      hl,rom_position
    inc     [hl]

    ld      hl,rom_stack

    ld      d,$00
    ld      a,[rom_position]
    ld      e,a
    add     hl,de

    ld      a,b               ; hl = pointer to stack, a = bank to change to

    ld      [hl],a
    ld      [rROMB0],a        ; select rom bank

    ld      a,c
    ld      [rIE],a

    ret

;-------------------------------------------------------------------------------
;- ___long_call()    hl = function    b = bank where it is located             -
;-------------------------------------------------------------------------------

___long_call::
    push    hl
    call    rom_bank_push_set
    pop     hl
    CALL_HL
    call    rom_bank_pop
    ret

;-------------------------------------------------------------------------------
;- ___long_call_args()    hl = function    a = bank where it is located        -
;-------------------------------------------------------------------------------

; It can use bc and de for passing arguments
; Returned values in any register are preserved through this call
___long_call_args::
    push    bc
    push    de
    push    hl
    ld      b,a
    call    rom_bank_push_set
    pop     hl
    pop     de
    pop     bc
    CALL_HL
    push    af
    push    de
    push    hl
    call    rom_bank_pop ; preserves bc
    pop     hl
    pop     de
    pop     af
    ret

;###############################################################################
