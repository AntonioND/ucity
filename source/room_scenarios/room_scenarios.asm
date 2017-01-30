;###############################################################################
;
;    BitCity - City building game for Game Boy Color.
;    Copyright (C) 2016-2017 Antonio Nino Diaz (AntonioND/SkyLyrac)
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

    INCLUDE "room_text_input.inc"
    INCLUDE "text.inc"

;###############################################################################

    SECTION "Room Scenarios Variables",WRAM0

;-------------------------------------------------------------------------------

scenario_select_room_exit: DS 1 ; set to 1 to exit room

SCENARIO_NUMBER EQU 2

scenario_select_map_selection: DS 1 ; $FF for invalid value

;###############################################################################

    SECTION "Room Scenarios Code Data",ROMX

;-------------------------------------------------------------------------------

SCENARIO_SELECT_BG_MAP:
    INCBIN "map_scenario_select_bg_map.bin"

SCENARIO_SELECT_WIDTH  EQU 20
SCENARIO_SELECT_HEIGHT EQU 18

;-------------------------------------------------------------------------------

RoomScenarioSelectRefreshText:

    xor     a,a
    ld      [rVBK],a

    ; Print name of the city
    ; ----------------------

    ; Clear

    ld      bc,TEXT_INPUT_LENGTH
    ld      d,O_SPACE
    ld      hl,$9800+32*3+9
    call    vram_memset ; bc = size    d = value    hl = dest address

    ; Print

    ld      a,[scenario_select_map_selection]
    call    ScenarioGetMapName ; a = number
    ; returns bc = name, a = length (in bank 0)

    push    af
    ld      d,a
    ld      a,TEXT_INPUT_LENGTH+1
    sub     a,d
    ld      e,a
    ld      d,0
    ld      hl,$9800+3*32+9
    add     hl,de
    LD_DE_HL ; dest
    LD_HL_BC ; src
    pop     af
    ld      b,a
    dec     b
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    ; Print money and date
    ; --------------------

    ld      a,[scenario_select_map_selection]
    call    ScenarioGetMapMoneyDate ; a = number
    ; returns de = year, a = month, bc = money (in bank 0)

    add     sp,-10 ; (*) allocate space for the converted string

        push    af
        push    de

            LD_DE_BC
            ld      hl,sp+4
            call    BCD_DE_2TILE_HL_LEADING_SPACES

            ld      b,10
            ld      de,$9800+4*32+9
            ld      hl,sp+4
            call    vram_copy_fast ; b = size - hl = source address - de = dest

        pop     de
        pop     af

        LD_BC_DE
        ld      hl,sp+0
        LD_DE_HL
        call    DatePrint ; bc = year, a = month, de = destination

        ld      b,8
        ld      hl,sp+0
        ld      de,$9800+5*32+11
        call    vram_copy_fast ; b = size - hl = source address - de = dest

    add     sp,+10 ; (*) reclaim space

    ret

;-------------------------------------------------------------------------------

InputHandleScenarioSelect:

    ld      a,[joy_pressed]
    and     a,PAD_RIGHT
    jr      z,.end_right
        ld      a,[scenario_select_map_selection]
        inc     a
        cp      a,SCENARIO_NUMBER
        jr      nz,.skip_right_reset
            xor     a,a
.skip_right_reset:
        ld      [scenario_select_map_selection],a
        call    RoomScenarioSelectRefreshText
.end_right:

    ld      a,[joy_pressed]
    and     a,PAD_LEFT
    jr      z,.end_left
        ld      a,[scenario_select_map_selection]
        dec     a
        cp      a,-1
        jr      nz,.skip_left_reset
            ld      a,SCENARIO_NUMBER-1
.skip_left_reset:
        ld      [scenario_select_map_selection],a
        call    RoomScenarioSelectRefreshText
.end_left:

    ld      a,[joy_pressed]
    and     a,PAD_A|PAD_START
    jr      z,.end_a_start

        ld      a,1
        ld      [scenario_select_room_exit],a

        ret
.end_a_start:

    ld      a,[joy_pressed]
    and     a,PAD_B
    jr      z,.end_b

        ld      a,$FF ; set invalid value
        ld      [scenario_select_map_selection],a

        ld      a,1
        ld      [scenario_select_room_exit],a

        ret
.end_b:

    ret

;-------------------------------------------------------------------------------

RoomScenarioSelectLoadBG:

    ; Load border
    ; -----------

    ld      b,BANK(SCENARIO_SELECT_BG_MAP)
    call    rom_bank_push_set

        ; Load map
        ; --------

        ; Tiles
        xor     a,a
        ld      [rVBK],a

        ld      de,$9800
        ld      hl,SCENARIO_SELECT_BG_MAP

        ld      a,SCENARIO_SELECT_HEIGHT
.loop1:
        push    af

        ld      b,SCENARIO_SELECT_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-SCENARIO_SELECT_WIDTH
        add     hl,de
        ld      d,h
        ld      e,l
        pop     hl

        pop     af
        dec     a
        jr      nz,.loop1

        ; Attributes
        ld      a,1
        ld      [rVBK],a

        ld      de,$9800

        ld      a,SCENARIO_SELECT_HEIGHT
.loop2:
        push    af

        ld      b,SCENARIO_SELECT_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-SCENARIO_SELECT_WIDTH
        add     hl,de
        ld      d,h
        ld      e,l
        pop     hl

        pop     af
        dec     a
        jr      nz,.loop2

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

RoomScenarioSelect::

    call    SetPalettesAllBlack

    ld      bc,ScenarioSelectMenuVBLHandler
    call    irq_set_VBL

    xor     a,a
    ld      [scenario_select_map_selection],a

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ld      [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    call    RoomScenarioSelectLoadBG

    xor     a,a
    ld      [scenario_select_room_exit],a

    call    RoomScenarioSelectRefreshText

    call    LoadTextPalette

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleScenarioSelect

    ld      a,[scenario_select_room_exit]
    and     a,a
    jr      z,.loop

    call    SetDefaultVBLHandler

    call    SetPalettesAllBlack

    ld      a,[scenario_select_map_selection]
    cp      a,$FF
    jr      z,.invalid_map

        ld      a,1 ; return valid map
        ret

.invalid_map:

    xor     a,a ; return invalid map
    ret

;###############################################################################

    SECTION "Room Scenarios Code Bank 0",ROM0

;-------------------------------------------------------------------------------

ScenarioSelectMenuVBLHandler:

    call    refresh_OAM

    ret

;###############################################################################
