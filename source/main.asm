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

    SECTION "Main Vars",WRAM0

;-------------------------------------------------------------------------------

PadUpCount:     DS  1 ; when 0, repeat press
PadDownCount:   DS  1
PadLeftCount:   DS  1
PadRightCount:  DS  1

PAD_AUTOREPEAT_WAIT_INITIAL EQU 10
PAD_AUTOREPEAT_WAIT_REPEAT  EQU 4

;###############################################################################

    SECTION "Main",ROM0

;-------------------------------------------------------------------------------

InitKeyAutorepeat::
    ld      a,PAD_AUTOREPEAT_WAIT_INITIAL
    ld      [PadUpCount],a
    ld      [PadDownCount],a
    ld      [PadLeftCount],a
    ld      [PadRightCount],a
    ret

KeyAutorepeatHandle::

    ; Up

    ld      a,[joy_held]
    and     a,PAD_UP
    jr      z,.not_up

        ld      hl,PadUpCount
        dec     [hl]
        jr      nz,.end_up

        ld      [hl],PAD_AUTOREPEAT_WAIT_REPEAT

        ld      a,[joy_pressed]
        or      a,PAD_UP
        ld      [joy_pressed],a

    jr      .end_up
.not_up:
    ld      a,PAD_AUTOREPEAT_WAIT_INITIAL
    ld      [PadUpCount],a
.end_up:

    ; Down

    ld      a,[joy_held]
    and     a,PAD_DOWN
    jr      z,.not_down

        ld      hl,PadDownCount
        dec     [hl]
        jr      nz,.end_down

        ld      [hl],PAD_AUTOREPEAT_WAIT_REPEAT

        ld      a,[joy_pressed]
        or      a,PAD_DOWN
        ld      [joy_pressed],a

    jr      .end_down
.not_down:
    ld      a,PAD_AUTOREPEAT_WAIT_INITIAL
    ld      [PadDownCount],a
.end_down:

    ; Right

    ld      a,[joy_held]
    and     a,PAD_RIGHT
    jr      z,.not_right

        ld      hl,PadRightCount
        dec     [hl]
        jr      nz,.end_right

        ld      [hl],PAD_AUTOREPEAT_WAIT_REPEAT

        ld      a,[joy_pressed]
        or      a,PAD_RIGHT
        ld      [joy_pressed],a

    jr      .end_right
.not_right:
    ld      a,PAD_AUTOREPEAT_WAIT_INITIAL
    ld      [PadRightCount],a
.end_right:

    ; Left

    ld      a,[joy_held]
    and     a,PAD_LEFT
    jr      z,.not_left

        ld      hl,PadLeftCount
        dec     [hl]
        jr      nz,.end_left

        ld      [hl],PAD_AUTOREPEAT_WAIT_REPEAT

        ld      a,[joy_pressed]
        or      a,PAD_LEFT
        ld      [joy_pressed],a

    jr      .end_left
.not_left:
    ld      a,PAD_AUTOREPEAT_WAIT_INITIAL
    ld      [PadLeftCount],a
.end_left:

    ret

;-------------------------------------------------------------------------------

NotGBC:

    LONG_CALL   RoomOnlyForGBC

    jr  NotGBC

;-------------------------------------------------------------------------------
;- Main()                                                                      -
;-------------------------------------------------------------------------------

Main:

    xor     a,a
    ld      [rIE],a

    LONG_CALL Test_Mult

    ; Enable interrupts forever. No code is allowed to disable them unless it is
    ; a critical section.
    ei

    ld      a,[EnabledGBC]
    and     a,a
    call    z,NotGBC

    call    CPU_fast

    LONG_CALL   SRAM_PowerOnCheck

    call    SFX_InitSystem

    ld      a,LCDCF_ON
    ld      [rLCDC],a

    call    SetDefaultVBLHandler

    ld      hl,rIE
    set     0,[hl] ; IEF_VBLANK

    ; Start game

    LONG_CALL   RoomTitle

.main_loop:

        LONG_CALL   RoomMenu

        LONG_CALL   RoomGame

    jr      .main_loop

;-------------------------------------------------------------------------------

DefaultVBLHandler:

    call    refresh_OAM

    call    SFX_Handler

    call    rom_bank_push
    call    gbt_update
    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

WaitReleasedAllKeys::

    call    wait_vbl

    call    scan_keys

    ld      a,[joy_held]
    ld      b,a
    ld      a,[joy_released]
    or      a,b
    ld      a,[joy_pressed]
    or      a,b
    jr      nz,WaitReleasedAllKeys

    call    InitKeyAutorepeat

    ret

;-------------------------------------------------------------------------------

SetDefaultVBLHandler::

    ld      bc,DefaultVBLHandler
    call    irq_set_VBL

    ret

;-------------------------------------------------------------------------------

SetPalettesAllBlack::

    ld      a,$FF
    ld      [rBGP],a
    ld      a,[EnabledGBC]
    and     a,a
    ret     z

    di ; Entering critical section

    ld      b,144
    call    wait_ly

    ld      a,$80 ; auto increment
    ld      [rBCPS],a
    ld      [rOCPS],a

    ld      hl,rBCPD
    ld      c,rOCPD&$FF
    xor     a,a
    ld      b,8
.loop:
    REPT    4
    ld      [hl],a
    ld      [hl],a

    ld      [$FF00+c],a
    ld      [$FF00+c],a
    ENDR
    dec     b
    jr      nz,.loop

    ei ; End of critical section

    ret

;###############################################################################

    SECTION "Test Mult",ROMX

Test_Mult:
VAL1 SET 0
    REPT 128
    ld b,VAL1 + 32
    ld hl, $4000
    call ___long_call
VAL1 SET VAL1+1
    ENDR
    ret

TEST_MUL : MACRO
    ld a,\1
    ld c,\2
    call mul_u8u8u16
    ld a,h
    cp a,((\1 * \2) >> 8) & $FF
.loop1_\@:
    jr nz,.loop1_\@
    ld a,l
    cp a,(\1 * \2) & $FF
.loop2_\@:
    jr nz,.loop2_\@
ENDM

VAL1START SET 128 ; Set this to 0 or to 128 to test both 0-127 and 128-255

VAL1 SET VAL1START
    REPT 128

    SECTION "Test Mult\@",ROMX[$4000], BANK[VAL1 + 32 - VAL1START]

Test_Mult\@::
VAL2 SET 0
    REPT 256
    TEST_MUL VAL1, VAL2
VAL2 SET VAL2+1
    ENDR
    ret

VAL1 SET VAL1+1
    ENDR
