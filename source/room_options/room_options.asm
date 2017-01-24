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

    INCLUDE "money.inc"
    INCLUDE "room_game.inc"
    INCLUDE "text.inc"

;###############################################################################

    SECTION "Room Options Variables",WRAM0

;-------------------------------------------------------------------------------

options_menu_old_animation_disabled: DS 1

options_menu_selection: DS 1

options_room_exit:  DS 1 ; set to 1 to exit room

OPTIONS_MENU_BLINK_FRAMES EQU 30
options_menu_blink_status: DS 1
options_menu_blink_frames: DS 1 ; frames left to change status

;###############################################################################

    SECTION "Room Options Data",ROMX

;-------------------------------------------------------------------------------

OPTIONS_MENU_BG_MAP:
    INCBIN "options_menu_bg_map.bin"

OPTIONS_MENU_WIDTH  EQU 20
OPTIONS_MENU_HEIGHT EQU 18

;-------------------------------------------------------------------------------

OPTIONS_MENU_NUMBER_ELEMENTS EQU 5

OPTIONS_DISASTERS_ENABLED         EQU 0
OPTIONS_DISASTER_START_FIRE       EQU 1
OPTIONS_DISASTER_NUCLEAR_MELTDOWN EQU 2
OPTIONS_ANIMATIONS_ENABLED        EQU 3
OPTIONS_MUSIC_ENABLED             EQU 4

;-------------------------------------------------------------------------------

CURSOR_X EQU 1
OPTIONS_MENU_CURSOR_COORDINATE_OFFSET:
    DW 5*32+CURSOR_X+$9800 ; Disasters Enable/Disable
    DW 7*32+CURSOR_X+$9800 ; Start Fire
    DW 8*32+CURSOR_X+$9800 ; Nuclear Meltdown
    DW 12*32+CURSOR_X+$9800 ; Animations Enable/Disable
    DW 16*32+CURSOR_X+$9800 ; Music Enable/Disable

OptionsMenuClearCursor:

    ld      b,O_SPACE
    jr      OptionsMenuPlaceAtCursor

OptionsMenuDrawCursor:

    ld      b,O_ARROW

OptionsMenuPlaceAtCursor: ; b = tile number

    add     sp,-1 ; Create space in the stack for the value to write
    ld      hl,sp+0
    ld      a,b
    ld      [hl],a

    ld      a,[options_menu_selection]
    ld      l,a
    ld      h,0
    add     hl,hl

    ld      de,OPTIONS_MENU_CURSOR_COORDINATE_OFFSET
    add     hl,de
    ld      e,[hl]
    inc     hl
    ld      d,[hl]

    xor     a,a
    ld      [rVBK],a

    ld      b,1
    ld      hl,sp+0
    call    vram_copy_fast
    add     sp,+1

    ret

;-------------------------------------------------------------------------------

OptionsMenuHandle:

    ; Cursor blink
    ; ------------

    ld      hl,options_menu_blink_frames
    dec     [hl]
    jr      nz,.end_blink
        ld      [hl],OPTIONS_MENU_BLINK_FRAMES

        ld      hl,options_menu_blink_status
        ld      a,[hl]
        xor     a,1
        ld      [hl],a
        and     a,a
        jr      z,.clear_cursor
            ; Draw cursor
            call    OptionsMenuDrawCursor
            jr      .end_blink
.clear_cursor:
            call    OptionsMenuClearCursor
.end_blink:

    ; Input
    ; -----

    call    OptionsMenuHandleInput

    ret

;-------------------------------------------------------------------------------

OptionsMenuHandleInput:

    ; Exit if B or START are pressed
    ld      a,[joy_pressed]
    and     a,PAD_B|PAD_START
    jr      z,.end_b_start
        ld      a,1
        ld      [options_room_exit],a
        ret
.end_b_start:

    ; UP
    ld      a,[joy_pressed]
    and     a,PAD_UP
    jr      z,.not_up
        ld      a,[options_menu_selection]
        and     a,a
        jr      z,.not_up
            call    OptionsMenuClearCursor
            ld      hl,options_menu_selection
            dec     [hl]
            call    OptionsMenuDrawCursor
            ld      a,OPTIONS_MENU_BLINK_FRAMES
            ld      [options_menu_blink_frames],a
            ld      a,1
            ld      [options_menu_blink_status],a
            ret
.not_up:

    ; DOWN
    ld      a,[joy_pressed]
    and     a,PAD_DOWN
    jr      z,.not_down
        ld      a,[options_menu_selection]
        cp      a,OPTIONS_MENU_NUMBER_ELEMENTS-1
        jr      z,.not_down
            call    OptionsMenuClearCursor
            ld      hl,options_menu_selection
            inc     [hl]
            call    OptionsMenuDrawCursor
            ld      a,OPTIONS_MENU_BLINK_FRAMES
            ld      [options_menu_blink_frames],a
            ld      a,1
            ld      [options_menu_blink_status],a
            ret
.not_down:

    ; A
    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      z,.not_a
        ld      a,[options_menu_selection]
        call    OptionsMenuHandleOption
        ret
.not_a:

    ret

;-------------------------------------------------------------------------------

; Handle effect of pressing A in an option
OptionsMenuHandleOption: ; a = selected option

    cp      a,OPTIONS_DISASTERS_ENABLED
    jr      nz,.not_disasters_enabled

        ; Disasters : Enable / Disable
        ; ----------------------------

        ld      hl,simulation_disaster_disabled
        ld      a,[hl]
        xor     a,1
        ld      [hl],a
        ld      de,5*32+CURSOR_X+2+$9800
        call    OptionsMenuDrawEnabledStateAt ; hl = flag, de = VRAM ptr
        ret

.not_disasters_enabled:
    cp      a,OPTIONS_DISASTER_START_FIRE
    jr      nz,.not_disaster_start_fire

        ; Disasters : Start Fire
        ; ----------------------

        ld      a,DISASTER_TYPE_FIRE
        call    GameRequestDisaster

        ret

.not_disaster_start_fire:
    cp      a,OPTIONS_DISASTER_NUCLEAR_MELTDOWN
    jr      nz,.not_disaster_nuclear_meltdown

        ; Disasters : Nuclear Meltdown
        ; ----------------------------

        ld      a,DISASTER_TYPE_MELTDOWN
        call    GameRequestDisaster

        ret

.not_disaster_nuclear_meltdown:
    cp      a,OPTIONS_ANIMATIONS_ENABLED
    jr      nz,.not_animations_enabled

        ; Animations : Enable / Disable
        ; ----------------------------

        ld      hl,game_animations_disabled
        ld      a,[hl]
        xor     a,1
        ld      [hl],a
        ld      de,12*32+CURSOR_X+2+$9800
        call    OptionsMenuDrawEnabledStateAt ; hl = flag, de = VRAM ptr

        ret

.not_animations_enabled:
    cp      a,OPTIONS_MUSIC_ENABLED
    jr      nz,.not_music_enabled

        ; Music : Enable / Disable
        ; ----------------------------

        ld      hl,game_music_disabled
        ld      a,[hl]
        xor     a,1
        ld      [hl],a
        ld      de,16*32+CURSOR_X+2+$9800
        call    OptionsMenuDrawEnabledStateAt ; hl = flag, de = VRAM ptr

        ; TODO - Enable or disable music here

        ret

.not_music_enabled:

    ld      b,b ; Panic!
    ret

;-------------------------------------------------------------------------------

OptionsMenuDrawEnabledStateAt: ; hl = ptr to flag, de = ptr to VRAM destination

    xor     a,a
    ld      [rVBK],a

    ld      a,[hl]
    and     a,a
    jr      nz,.not_enabled
        ; Enabled
        ld      hl,.str_enabled
    jr      .print
.not_enabled:
        ; Disabled
        ld      hl,.str_disabled
.print:
    ld      b,8
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    ret

.str_enabled:
    STR_ADD "Enabled "

.str_disabled:
    STR_ADD "Disabled"

;-------------------------------------------------------------------------------

RoomOptionsMenuLoadBG:

    ; Load border
    ; -----------

    ld      b,BANK(OPTIONS_MENU_BG_MAP)
    call    rom_bank_push_set

        ; Load map
        ; --------

        ; Tiles
        xor     a,a
        ld      [rVBK],a

        ld      de,$9800
        ld      hl,OPTIONS_MENU_BG_MAP

        ld      a,OPTIONS_MENU_HEIGHT
.loop1:
        push    af

        ld      b,OPTIONS_MENU_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-OPTIONS_MENU_WIDTH
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

        ld      a,OPTIONS_MENU_HEIGHT
.loop2:
        push    af

        ld      b,OPTIONS_MENU_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-OPTIONS_MENU_WIDTH
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

RoomOptionsMenu::

    call    SetPalettesAllBlack

    xor     a,a
    ld      [options_menu_selection],a

    ld      a,OPTIONS_MENU_BLINK_FRAMES
    ld      [options_menu_blink_frames],a
    ld      a,1
    ld      [options_menu_blink_status],a

    ld      bc,OptionsMenuVBLHandler
    call    irq_set_VBL

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ld      [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    call    RoomOptionsMenuLoadBG

    ; Print default values

    ld      hl,simulation_disaster_disabled
    ld      de,5*32+CURSOR_X+2+$9800
    call    OptionsMenuDrawEnabledStateAt ; hl = flag, de = VRAM ptr
    ld      hl,game_animations_disabled
    ld      de,12*32+CURSOR_X+2+$9800
    call    OptionsMenuDrawEnabledStateAt
    ld      hl,game_music_disabled
    ld      de,16*32+CURSOR_X+2+$9800
    call    OptionsMenuDrawEnabledStateAt

    ld      a,[game_animations_disabled]
    ld      [options_menu_old_animation_disabled],a

    ; End of default values

    call    LoadTextPalette

    xor     a,a
    ld      [options_room_exit],a

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    OptionsMenuHandle

    ld      a,[options_room_exit]
    and     a,a
    jr      z,.loop

    call    SetDefaultVBLHandler

    call    SetPalettesAllBlack

    ; Update animation state if needed

    ld      a,[options_menu_old_animation_disabled]
    ld      b,a
    ld      a,[game_animations_disabled]
    cp      a,b ; b = old, a = new
    jr      z,.animation_check_end ; if they are the same, skip this

        ; If animations are re-enabled, reset sprites

        and     a,a
        jr      nz,.animation_check_end ; skip if disabled

            ld      b,1 ; force reset
            LONG_CALL_ARGS  Simulation_TransportAnimsInit

.animation_check_end:

    ret

;###############################################################################

    SECTION "Room Options Code Bank 0",ROM0

;-------------------------------------------------------------------------------

OptionsMenuVBLHandler:

    call    refresh_OAM

    ret

;###############################################################################
