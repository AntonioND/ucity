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

    INCLUDE "map_load.inc"
    INCLUDE "text.inc"
    INCLUDE "room_text_input.inc"

;###############################################################################

    SECTION "Room Menu Variables",WRAM0

menu_selection: DS 1
menu_exit:      DS 1

;###############################################################################

    SECTION "Room Menu Code Data",ROMX

;-------------------------------------------------------------------------------

MAIN_MENU_BG_MAP::
    INCBIN "data/main_menu_bg_map.bin"

;-------------------------------------------------------------------------------

    STR_ADD "City Name:", STR_CITY_NAME

MenuNewCity: ; returns 1 if loaded correctly, 0 if not

    ld      a,CITY_MAP_GENERATE_RANDOM
    call    CityMapSet

    add     sp,-STR_CITY_NAME_LEN

        ; Save string to the stack so that any bank can see the data!
        ld      bc,STR_CITY_NAME_LEN ; bc = size
        ld      hl,sp+0
        LD_DE_HL ; de = dest
        ld      hl,STR_CITY_NAME ; hl = src
        call    memcopy

        ld      hl,sp+0
        LD_DE_HL
        LONG_CALL_ARGS  RoomTextInputSetPrompt ; de = pointer to string

    add     sp,+STR_CITY_NAME_LEN

    LONG_CALL   RoomTextInput

    ld      hl,text_input_buffer
    ld      de,current_city_name
    ld      bc,TEXT_INPUT_LENGTH
    call    memcopy ; bc = size    hl = source address    de = dest address

    LONG_CALL   RoomGenerateMap

    ld      a,1
    ret

;-------------------------------------------------------------------------------

MenuScenario: ; returns 1 if loaded correctly, 0 if not

    LONG_CALL_ARGS   RoomScenarioSelect ; Rets A = 1 if loaded correctly else 0
    and     a,a
    ret     z ; return 0 if not loaded and do nothing else

;   ld      a,[scenario_select_map_selection]

    ; TODO : Scenarios should set the city map to a positive value instead of
    ; just 0!

    ld      a,0
    call    CityMapSet

    ; TODO : Actually load something!

    ld      a,1
    ret

;-------------------------------------------------------------------------------

MenuLoadCitySRAM: ; returns 1 if loaded correctly, 0 if not

    ld      b,0 ; 0 = load data mode
    LONG_CALL_ARGS    RoomSaveMenu ; returns A = SRAM bank, -1 if error
    ld      b,a ; (*) save bank to b

    cp      a,$FF
    jr      z,.error ; no banks or user pressed cancel

    ld      hl,sram_bank_status
    ld      e,a
    ld      d,0
    add     hl,de
    ld      a,[hl] ; get bank status

    cp      a,1
    jr      nz,.error ; bank is empty or corrupted

    ld      a,b ; (*) get bank
    or      a,CITY_MAP_SRAM_FLAG
    call    CityMapSet

    ld      a,1 ; return ok
    ret

.error:

    xor     a,a ; return error
    ret

;-------------------------------------------------------------------------------

InputHandleMenu:

    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      z,.not_a

        call    MenuNewCity ; returns 1 if loaded correctly, 0 if not
        and     a,a
        jr      z,.not_loaded_a
            ld      a,1
            ld      [menu_exit],a
            ret
.not_loaded_a:
        call    RoomMenuLoadGraphics
        ret
.not_a:

    ld      a,[joy_pressed]
    and     a,PAD_START
    jr      z,.not_start

        call    MenuScenario ; returns 1 if loaded correctly, 0 if not
        and     a,a
        jr      z,.not_loaded_start
            ld      a,1
            ld      [menu_exit],a
            ret
.not_loaded_start:
        call    RoomMenuLoadGraphics
        ret
.not_start:

    ld      a,[joy_pressed]
    and     a,PAD_B
    jr      z,.not_b

        call    MenuLoadCitySRAM ; returns 1 if loaded correctly, 0 if not
        and     a,a
        jr      z,.not_loaded_b
            ld      a,1
            ld      [menu_exit],a
            ret
.not_loaded_b:
        call    RoomMenuLoadGraphics
        ret
.not_b:

    ret

;-------------------------------------------------------------------------------

RoomMenuLoadBG:

    ; Reset scroll
    ; ------------

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ; Load graphics
    ; -------------

    ; Tiles

    xor     a,a
    ld      [rVBK],a

    ld      de,$9800
    ld      hl,MAIN_MENU_BG_MAP

    ld      a,18
.loop1:
    push    af

    ld      b,20
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    push    hl
    ld      hl,32-20
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

    ld      a,18
.loop2:
    push    af

    ld      b,20
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    push    hl
    ld      hl,32-20
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl

    pop     af
    dec     a
    jr      nz,.loop2

    ret

;-------------------------------------------------------------------------------

RoomMenuLoadGraphics:

    call    RoomMenuLoadBG

    ld      b,0 ; bank at 8000h
    call    LoadText

    di ; Entering critical section

    ld      b,144
    call    wait_ly

    xor     a,a
    ld      [rIF],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8000|LCDCF_ON
    ld      [rLCDC],a

    call    LoadTextPalette

    ei ; End of critical section

    ret

;-------------------------------------------------------------------------------

RoomMenu::

    xor     a,a
    ld      [menu_selection],a
    ld      [menu_exit],a

    call    SetPalettesAllBlack

    ld      bc,RoomMenuVBLHandler
    call    irq_set_VBL

    call    RoomMenuLoadGraphics

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleMenu

    ld      a,[menu_exit]
    and     a,a
    jr      z,.loop

    call    SetDefaultVBLHandler

    ret

;###############################################################################

    SECTION "Room Menu Code ROM0",ROM0

;-------------------------------------------------------------------------------

RoomMenuVBLHandler:

    call    refresh_OAM

    ret

;###############################################################################
