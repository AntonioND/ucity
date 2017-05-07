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

;-------------------------------------------------------------------------------

    INCLUDE "map_load.inc"

;###############################################################################

    SECTION "Room Title Variables",WRAM0

title_exit:             DS  1
title_scroll_dir_x:     DS  1
title_scroll_dir_y:     DS  1
title_scroll_countdown: DS  1

SCROLL_COUNTDOWN_TICKS  EQU 2

title_blink_countdown:  DS  1
title_blink_state:      DS  1

TITLE_BLINK_COUNTDOWN_TICKS EQU 45

;###############################################################################

    SECTION "Room Title Code Data",ROMX

;-------------------------------------------------------------------------------

TITLE_SCREEN_TILES:
    INCBIN "title_screen_tiles.bin"

TITLE_SCREEN_MAP:
    INCBIN "tilte_screen_map.bin"

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

    xor     a,a
    ld      [rVBK],a

    ld      bc,40*2 ; 40 sprites * 2 tiles per sprites
    ld      de,0
    ld      hl,TITLE_SCREEN_TILES
    call    vram_copy_tiles ; bc = tiles    de = start index    hl = source

    ld      l,0
    call    sprite_get_base_pointer ; l = sprite    return = hl    destroys de

    ld      de,TITLE_SCREEN_MAP

SPR_X_BASE EQU (160-10*8)/2
SPR_Y_BASE EQU (144-4*16)/2

SPR_Y SET 0
    REPT    4
SPR_X SET 0
        REPT    10
           ld       a,SPR_Y*16 + SPR_Y_BASE + 16
           ld       [hl+],a
           ld       a,SPR_X*8 + SPR_X_BASE + 8
           ld       [hl+],a
           ld       a,( SPR_X + SPR_Y * 10 ) * 2
           ld       [hl+],a
           ld       a,[de]
           inc      de
           ld       [hl+],a
SPR_X SET SPR_X + 1
        ENDR
SPR_Y SET SPR_Y + 1
    ENDR

    ; Load palettes of bg and sprites
    ; -------------------------------

    call    bg_load_main_palettes

    ld      hl,.sprite_palettes
    xor     a,a
    call    spr_set_palette ; a = palette number    hl = pointer to data
    ld      a,1
    call    spr_set_palette
    ld      a,2
    call    spr_set_palette
    ld      a,3
    call    spr_set_palette
    ld      a,4
    call    spr_set_palette

    ; Show screen
    ; -----------

    xor     a,a
    ld      [rIF],a

    ld      a,LCDCF_BG9C00|LCDCF_OBJON|LCDCF_BG8800|LCDCF_OBJ16|LCDCF_ON
    ld      [rLCDC],a

    ret

.sprite_palettes:
    DW  0, (21<<10)|(21<<5)|21, (10<<10)|(10<<5)|10, 0
    DW  0, 31, 15, 0
    DW  0, (25<<10)|15, (13<<10)|8, 0
    DW  0, 31<<10, 15<<10, 0
    DW  0, (15<<5)|25, (8<<5)|13, 0

;-------------------------------------------------------------------------------

TitleBlinkInit:

    ld      a,TITLE_BLINK_COUNTDOWN_TICKS
    ld      [title_blink_countdown],a
    ld      a,1
    ld      [title_blink_state],a

    ret

;-------------------------------------------------------------------------------

TitleBlinkHandle:

    ld      hl,title_blink_countdown
    dec     [hl]
    ret     nz
    ld      [hl],TITLE_BLINK_COUNTDOWN_TICKS

    ld      a,[title_blink_state]
    xor     a,1
    ld      [title_blink_state],a

    ld      l,30
    call    sprite_get_base_pointer ; l = sprite    return = hl    destroys de

    ld      a,[title_blink_state]
    and     a,a
    jp      z,.disable_spr
        ld      a,3*16 + SPR_Y_BASE + 16
        jr      .end_disable_enable_spr
.disable_spr:
        xor     a,a
.end_disable_enable_spr:

    ld      de,4

SPR_X SET 0
    REPT    10
    ld      [hl],a
    add     hl,de
SPR_X SET SPR_X + 1
    ENDR

    ret

;-------------------------------------------------------------------------------

RoomTitleMusicStop::

    call    gbt_stop

    ret

;-------------------------------------------------------------------------------

RoomTitle::

    xor     a,a
    ld      [title_exit],a

    call    TitleScrollInit
    call    TitleBlinkInit

    call    SetPalettesAllBlack

    ld      bc,RoomTitleVBLHandler
    call    irq_set_VBL

    call    RoomTitleLoadGraphics

    call    RoomTitleMusicPlay

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleTitle

    call    TitleScrollHandle
    call    TitleBlinkHandle

    ld      a,[title_exit]
    and     a,a
    jr      z,.loop

    ; Clear sprites

    ld      l,0
    call    sprite_get_base_pointer ; l = sprite    return = hl    destroys de
    xor     a,a
    ld      b,40*4
    call    memset_fast ; a = value    hl = start address    b = size

    call    wait_vbl

    ; Prepare to exit

    call    RoomTitleMusicStop

    call    SetDefaultVBLHandler

    call    SetPalettesAllBlack

    ret

;###############################################################################

    SECTION "Room Title Code ROM0",ROM0

;-------------------------------------------------------------------------------

RoomTitleMusicPlay::

    call    rom_bank_push

    ld      de,song_title_data
    ld      a,7
    ld      bc,BANK(song_title_data)
    call    gbt_play ; This function changes the ROM bank to the one in BC

    ld      a,1
    call    gbt_loop

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

RoomTitleVBLHandler:

    call    bg_update_scroll_registers

    call    refresh_OAM

    call    SFX_Handler

    call    rom_bank_push
    call    gbt_update
    call    rom_bank_pop

    ret

;###############################################################################
