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

    INCLUDE "map_load.inc"

;###############################################################################

    SECTION "Room Menu Variables",WRAM0

menu_selection: DS 1
menu_exit:      DS 1

;###############################################################################

    SECTION "Room Menu Data",ROMX

;-------------------------------------------------------------------------------

MAIN_MENU_BG_MAP::
    INCBIN "data/main_menu_bg_map.bin"

;###############################################################################

    SECTION "Room Menu Code Data",ROM0

;-------------------------------------------------------------------------------

InputHandleMenu:

    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      z,.not_a

        ld      a,0
        call    CityMapSet

        ld      a,1
        ld      [menu_exit],a
        ret
.not_a:

    ld      a,[joy_pressed]
    and     a,PAD_B
    jr      z,.not_b

        ld      a,0|CITY_MAP_SRAM_FLAG
        call    CityMapSet

        ld      a,1
        ld      [menu_exit],a
        ret
.not_b:

    ret

;-------------------------------------------------------------------------------

RoomMenuVBLHandler:

    call    refresh_OAM

    ret

;-------------------------------------------------------------------------------

RoomMenuLoadBG:

    ld      b,BANK(MAIN_MENU_BG_MAP)
    call    rom_bank_push_set

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

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

RoomMenu::

    call    SetPalettesAllBlack

    ld      bc,RoomMenuVBLHandler
    call    irq_set_VBL

    call    RoomMenuLoadBG

    ld      b,0 ; bank at 8000h
    call    LoadText

    di
    ld      b,144
    call    wait_ly
    call    LoadTextPalette
    ei

    xor     a,a
    ld      [rIF],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8000|LCDCF_ON
    ld      [rLCDC],a

    ei

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
