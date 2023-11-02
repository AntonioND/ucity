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

;-------------------------------------------------------------------------------

    INCLUDE "map_load.inc"
    INCLUDE "text.inc"
    INCLUDE "room_text_input.inc"

;###############################################################################

    SECTION "Room Menu Variables",WRAM0

    DEF MENU_NUMBER_ELEMENTS EQU 4
menu_selection: DS 1
menu_exit:      DS 1

    DEF MENU_CURSOR_BLINK_FRAMES EQU 30
menu_cursor_blink:  DS 1
menu_cursor_frames: DS 1 ; number of frames left before switching blink

;###############################################################################

    SECTION "Room Menu Code Data",ROMX

;-------------------------------------------------------------------------------

MAIN_MENU_BG_MAP::
    INCBIN "main_menu_bg_map.bin"

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

    LONG_CALL_ARGS  RoomTextInput
    and     a,a
    ret     z ; return 0 if text string is empty

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

    ; Scenarios should set the city map to a positive value (or zero) that
    ; corresponds to that map.

    ld      a,[scenario_select_map_selection]
    call    CityMapSet

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

MACRO WRITE_B_TO_HL_VRAM ; Clobbers A and C
    di ; critical section
        xor     a,a
        ldh     [rVBK],a
        WAIT_SCREEN_BLANK ; Clobbers registers A and C
        ld      [hl],b
    ei ; end of critical section
ENDM

;-------------------------------------------------------------------------------

    DEF CURSOR_X EQU 4
MENU_CURSOR_COORDINATE_OFFSET:
    DW 6*32+CURSOR_X+$9800 ; Budget
    DW 8*32+CURSOR_X+$9800 ; Bank
    DW 10*32+CURSOR_X+$9800 ; Minimaps
    DW 12*32+CURSOR_X+$9800 ; Graphs

; A = slot of the screen to get the base coordinates to. The coordinates are
; the ones corresponding to the arrow cursor
MenuGetMapPointer: ; returns hl = pointer to VRAM to selected tile

    ld      a,[menu_selection]
    ld      l,a
    ld      h,0
    add     hl,hl

    ld      de,MENU_CURSOR_COORDINATE_OFFSET
    add     hl,de
    ld      e,[hl]
    inc     hl
    ld      d,[hl]

    LD_HL_DE

    ret

;-------------------------------------------------------------------------------

MenuDrawCursor:

    ld      a,[menu_selection]
    call    MenuGetMapPointer

    di ; critical section

        xor     a,a
        ldh     [rVBK],a

        WAIT_SCREEN_BLANK ; Clobbers registers A and C

        ld      [hl],O_ARROW

    reti ; end of critical section and return

;-------------------------------------------------------------------------------

MenuClearCursor:

    ld      a,[menu_selection]
    call    MenuGetMapPointer

    di ; critical section

        xor     a,a
        ldh     [rVBK],a

        WAIT_SCREEN_BLANK ; Clobbers registers A and C

        ld      [hl],O_SPACE

    reti ; end of critical section and return

;-------------------------------------------------------------------------------

MenuCursorMoveDown:

    call    MenuClearCursor

    ld      a,[menu_selection]
    inc     a
    cp      a,MENU_NUMBER_ELEMENTS
    ret     z

    ld      [menu_selection],a

    ld      a,MENU_CURSOR_BLINK_FRAMES
    ld      [menu_cursor_frames],a
    ld      a,1
    ld      [menu_cursor_blink],a

    call    MenuDrawCursor

    ret

;-------------------------------------------------------------------------------

MenuCursorMoveUp:

    call    MenuClearCursor

    ld      a,[menu_selection]
    dec     a
    cp      a,-1
    ret     z

    ld      [menu_selection],a

    ld      a,MENU_CURSOR_BLINK_FRAMES
    ld      [menu_cursor_frames],a
    ld      a,1
    ld      [menu_cursor_blink],a

    call    MenuDrawCursor

    ret

;-------------------------------------------------------------------------------

MenuCursorBlinkHandle:

    ld      hl,menu_cursor_frames
    dec     [hl]
    jr      nz,.end_cursor_blink

        ld      [hl],MENU_CURSOR_BLINK_FRAMES

        ld      hl,menu_cursor_blink
        ld      a,1
        xor     a,[hl]
        ld      [hl],a

        and     a,a
        jr      z,.cleared_cursor
            call    MenuDrawCursor
            jr      .end_cursor_blink
.cleared_cursor:
            call    MenuClearCursor
            jr      .end_cursor_blink

.end_cursor_blink:

    ret

;-------------------------------------------------------------------------------

InputHandleMenu:

    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      z,.not_a

        ld      a,[menu_selection]

        ; Load Game
        ; ---------

        cp      a,0
        jr      nz,.not_pressed_load_game

            call    MenuLoadCitySRAM ; returns 1 if loaded correctly, 0 if not
            and     a,a
            jr      z,.not_loaded_game
                ld      a,1
                ld      [menu_exit],a
                ret
.not_loaded_game:
            call    RoomMenuLoadGraphics
            ret

.not_pressed_load_game:

        ; Random Map
        ; ----------

        cp      a,1
        jr      nz,.not_pressed_random_map

            call    MenuNewCity ; returns 1 if loaded correctly, 0 if not
            and     a,a
            jr      z,.not_random_map
                ld      a,1
                ld      [menu_exit],a
                ret
.not_random_map:
            call    RoomMenuLoadGraphics
            ret

.not_pressed_random_map:

        ; Scenario
        ; --------

        cp      a,2
        jr      nz,.not_pressed_scenario

            call    MenuScenario ; returns 1 if loaded correctly, 0 if not
            and     a,a
            jr      z,.not_scenario
                ld      a,1
                ld      [menu_exit],a
                ret
.not_scenario:
            call    RoomMenuLoadGraphics
            ret

.not_pressed_scenario:

        ; Credits
        ; -------

        cp      a,3
        jr      nz,.not_pressed_credits

            LONG_CALL_ARGS    RoomCredits
            call    RoomMenuLoadGraphics
            ret

.not_pressed_credits:

.not_a:

    ; Handle cursor

    ld      a,[joy_pressed]
    and     a,PAD_UP
    jr      z,.not_up
        call    MenuClearCursor
        call    MenuCursorMoveUp
        call    MenuDrawCursor
        jr      .end_up_down
.not_up:
    ld      a,[joy_pressed]
    and     a,PAD_DOWN
    jr      z,.end_up_down
        call    MenuClearCursor
        call    MenuCursorMoveDown
        call    MenuDrawCursor
.end_up_down:

    ret

;-------------------------------------------------------------------------------

RoomMenuLoadBG:

    ; Reset scroll
    ; ------------

    xor     a,a
    ldh     [rSCX],a
    ldh     [rSCY],a

    ; Load graphics
    ; -------------

    ; Tiles

    xor     a,a
    ldh     [rVBK],a

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
    ldh     [rVBK],a

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

MenuCursorReset:

    xor     a,a
    ld      [menu_cursor_blink],a

    ld      a,MENU_CURSOR_BLINK_FRAMES
    ld      [menu_cursor_frames],a

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
    ldh     [rIF],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8000|LCDCF_ON
    ldh     [rLCDC],a

    call    LoadTextPalette

    ei ; End of critical section

    call    MenuCursorReset
    call    MenuDrawCursor

    ret

;-------------------------------------------------------------------------------

RoomMenuMusicStop::

    call    gbt_stop

    ret

;-------------------------------------------------------------------------------

RoomMenu::

    xor     a,a
    ld      [menu_selection],a
    ld      [menu_exit],a

    call    SetPalettesAllBlack

    call    SetDefaultVBLHandler

    call    RoomMenuLoadGraphics

    call    RoomMenuMusicPlay

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleMenu

    call    MenuCursorBlinkHandle

    ld      a,[menu_exit]
    and     a,a
    jr      z,.loop

    call    WaitReleasedAllKeys

    call    SetPalettesAllBlack

    call    RoomMenuMusicStop

    ret

;###############################################################################

    SECTION "Room Menu Code ROM0",ROM0

;-------------------------------------------------------------------------------

RoomMenuMusicPlay::

    call    rom_bank_push

    ld      de,song_menu_data
    ld      a,4
    ld      bc,BANK(song_menu_data)
    call    gbt_play ; This function changes the ROM bank to the one in BC

    ld      a,1
    call    gbt_loop

    call    rom_bank_pop

    ret

;###############################################################################
