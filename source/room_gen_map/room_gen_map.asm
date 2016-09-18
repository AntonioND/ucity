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

    INCLUDE "text.inc"

;###############################################################################

    SECTION "Room Gen Map Variables",WRAM0

;-------------------------------------------------------------------------------

gen_map_room_exit:  DS 1 ; set to 1 to exit room

;###############################################################################

    SECTION "Room Gen Map Code Data",ROMX

;-------------------------------------------------------------------------------

GEN_MAP_BG_MAP:
    INCBIN "map_gen_minimap_bg_map.bin"

GEN_MAP_MENU_WIDTH  EQU 20
GEN_MAP_MENU_HEIGHT EQU 18

;-------------------------------------------------------------------------------

GenMapMandleInput: ; If it returns 1, exit room. If 0, continue

    ; Exit if B or START are pressed
    ld      a,[joy_pressed]
    and     a,PAD_B|PAD_START
    jr      z,.end_b_start
        ld      a,1
        ret ; return 1
.end_b_start:

    xor     a,a
    ret ; return 0

;-------------------------------------------------------------------------------

InputHandleGenMap:

    call    GenMapMandleInput ; If it returns 1, exit room. If 0, continue
    and     a,a
    ret     z ; don't exit

    ; Exit
    ld      a,1
    ld      [gen_map_room_exit],a
    ret

;-------------------------------------------------------------------------------

RoomGenMapLoadBG:

    ; Load border
    ; -----------

    ld      b,BANK(GEN_MAP_BG_MAP)
    call    rom_bank_push_set

        ; Load map
        ; --------

        ; Tiles
        xor     a,a
        ld      [rVBK],a

        ld      de,$9800
        ld      hl,GEN_MAP_BG_MAP

        ld      a,GEN_MAP_MENU_HEIGHT
.loop1:
        push    af

        ld      b,GEN_MAP_MENU_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-GEN_MAP_MENU_WIDTH
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

        ld      a,GEN_MAP_MENU_HEIGHT
.loop2:
        push    af

        ld      b,GEN_MAP_MENU_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-GEN_MAP_MENU_WIDTH
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

RoomGenerateMap::

    call    SetPalettesAllBlack

    ld      bc,GenMapMenuVBLHandler
    call    irq_set_VBL

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ld      [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    call    RoomGenMapLoadBG

    call    LoadTextPalette

    LONG_CALL   map_generate

    xor     a,a
    ld      [gen_map_room_exit],a

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleGenMap

    ld      a,[gen_map_room_exit]
    and     a,a
    jr      z,.loop

    call    SetDefaultVBLHandler

    call    SetPalettesAllBlack

    ret

;###############################################################################

    SECTION "Room Minimap Code Bank 0",ROM0

;-------------------------------------------------------------------------------

GenMapMenuVBLHandler:

    call    refresh_OAM

    ret

;###############################################################################
