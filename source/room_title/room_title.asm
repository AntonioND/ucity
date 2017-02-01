;###############################################################################
;
;    uCity - City building game for Game Boy Color.
;    Copyright (C) 2017 Antonio Nino Diaz (AntonioND/SkyLyrac)
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

;###############################################################################

    SECTION "Room Title Variables",WRAM0

title_exit:             DS  1
title_scroll_dir_x:     DS  1
title_scroll_dir_y:     DS  1
title_scroll_countdown: DS  1

SCROLL_COUNTDOWN_TICKS  EQU 2

;###############################################################################

    SECTION "Room Title Code Data",ROMX

;-------------------------------------------------------------------------------

InputHandleTitle:

    ld      a,[joy_pressed]
    and     a,a
    jr      z,.not_any
        ld      a,1
        ld      [title_exit],a
        ret
.not_any:

    ret

;-------------------------------------------------------------------------------

TitleScrollHandle:

    ld      hl,title_scroll_countdown
    dec     [hl]
    ret     nz

    ld      [hl],SCROLL_COUNTDOWN_TICKS

    ; Scroll only once every N frames

    ld      a,[title_scroll_dir_x]
    and     a,a
    jr      z,.right

        call    bg_main_scroll_left ; returns: a = if moved 1 else 0
        and     a,a
        jr      nz,.end_dir_x
            ld      a,0
            ld      [title_scroll_dir_x],a
        jr      .end_dir_x

.right:
        call    bg_main_scroll_right ; returns: a = if moved 1 else 0
        and     a,a
        jr      nz,.end_dir_x
            ld      a,1
            ld      [title_scroll_dir_x],a
        jr      .end_dir_x

.end_dir_x:

    ld      a,[title_scroll_dir_y]
    and     a,a
    jr      z,.down

        call    bg_main_scroll_up ; returns: a = if moved 1 else 0
        and     a,a
        jr      nz,.end_dir_y
            ld      a,0
            ld      [title_scroll_dir_y],a
        jr      .end_dir_y

.down:
        call    bg_main_scroll_down ; returns: a = if moved 1 else 0
        and     a,a
        jr      nz,.end_dir_y
            ld      a,1
            ld      [title_scroll_dir_y],a
        jr      .end_dir_y

.end_dir_y:

    ret

;-------------------------------------------------------------------------------

TitleScrollInit:

    ; Set random directions

    call    GetRandom
    ld      b,a
    and     a,1
    ld      [title_scroll_dir_x],a
    ld      a,b
    rrca
    and     a,1
    ld      [title_scroll_dir_y],a

    ld      a,SCROLL_COUNTDOWN_TICKS
    ld      [title_scroll_countdown],a

    ret

;-------------------------------------------------------------------------------

RoomTitleLoadGraphics:

    ; Select random city
    ; ------------------

    ; TODO - Select cities saved in SRAM too?

    ld      a,CITY_MAP_TOTAL_NUM
    ld      b,a

    ld      d,a
    REPT 7
    sra     d
    or      a,d
    ENDR
    ld      d,a ; d = (first power of 2 greater than the max) - 1

    ; generate num between 0 and b (b not included)
.loop_rand:
    call    GetRandom ; bc, de preserved
    and     a,d ; reduce the number to make this easier
    cp      a,b ; cy = 1 if b > a
    jr      nc,.loop_rand

    call    CityMapSet

    ; Load BG
    ; -------

    call    CityMapLoad ; Returns starting coordinates in d = x and e = y

    call    bg_load_main

    ; Load sprites
    ; ------------

    ; TODO

    ; Load palettes of bg and sprites
    ; -------------------------------

    call    bg_load_main_palettes
    ; TODO - Load sprite palettes

    ; Show screen
    ; -----------

    xor     a,a
    ld      [rIF],a

    ld      a,LCDCF_BG9C00|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ld      [rLCDC],a

    ret

;-------------------------------------------------------------------------------

RoomTitle::

    xor     a,a
    ld      [title_exit],a

    call    TitleScrollInit

    call    SetPalettesAllBlack

    ld      bc,RoomTitleVBLHandler
    call    irq_set_VBL

    call    RoomTitleLoadGraphics

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleTitle

    call    TitleScrollHandle

    ld      a,[title_exit]
    and     a,a
    jr      z,.loop

    call    SetDefaultVBLHandler

    ret

;###############################################################################

    SECTION "Room Title Code ROM0",ROM0

;-------------------------------------------------------------------------------

RoomTitleVBLHandler:

    call    bg_update_scroll_registers

    call    refresh_OAM

    ret

;###############################################################################
