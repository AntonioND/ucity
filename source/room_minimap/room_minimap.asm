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

    SECTION "Room Minimap Variables",WRAM0

;-------------------------------------------------------------------------------

minimap_room_exit: DS 1 ; set to 1 to exit room

;###############################################################################

    SECTION "Room Minimap Data",ROMX

;-------------------------------------------------------------------------------

;###############################################################################

    SECTION "Room Minimap Code Bank 0",ROM0

;-------------------------------------------------------------------------------

InputHandleMinimap:

    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      z,.not_a



        ld      a,1
        ld      [minimap_room_exit],a
        ret
.not_a:

    ld      a,[joy_pressed]
    and     a,PAD_B
    jr      z,.not_b



        ld      a,1
        ld      [minimap_room_exit],a
        ret
.not_b:

    ret

;-------------------------------------------------------------------------------

RoomMinimapVBLHandler:

    call    refresh_OAM

    ret

;-------------------------------------------------------------------------------

RoomMinimapLoadBG:

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    LONG_CALL   APA_BufferClear
    LONG_CALL   APA_ResetBackgroundMapping

    LONG_CALL   APA_LoadGFX
    di
    ld      b,144
    call    wait_ly
    LONG_CALL   APA_LoadPalette
    ei

IF 0
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
    ld      hl,12
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
    ld      hl,12
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl

    pop     af
    dec     a
    jr      nz,.loop2

    call    rom_bank_pop
ENDC

    ret

;-------------------------------------------------------------------------------

RoomMinimap::

    call    SetPalettesAllBlack

    ld      bc,RoomMinimapVBLHandler
    call    irq_set_VBL

    call    RoomMinimapLoadBG

    call    LoadText
    ld      b,144
    call    wait_ly
    call    LoadTextPalette

    ld      hl,rIE
    set     0,[hl] ; IEF_VBLANK

    xor     a,a
    ld      [rIF],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ld      [rLCDC],a

    ei

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleMinimap

    ld      a,[minimap_room_exit]
    and     a,a
    jr      z,.loop

    ret

;###############################################################################
