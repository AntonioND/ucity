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

;###############################################################################

    SECTION "Room Only For GBC Data",ROMX

;-------------------------------------------------------------------------------

ONLY_FOR_GBC_BG_MAP:
    INCBIN "only_for_gbc_bg_map.bin"

ONLY_FOR_GBC_WIDTH  EQU 20
ONLY_FOR_GBC_HEIGHT EQU 18

;-------------------------------------------------------------------------------

OnlyForGBCLoadBG:

    ; Load border
    ; -----------

    ld      b,BANK(ONLY_FOR_GBC_BG_MAP)
    call    rom_bank_push_set

        ld      hl,ONLY_FOR_GBC_BG_MAP

        ; Load map
        ; --------

        ; Tiles

        ld      de,$9800
        ;HL = pointer to map

        ld      a,ONLY_FOR_GBC_HEIGHT
.loop1:
        push    af

        ld      b,ONLY_FOR_GBC_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-ONLY_FOR_GBC_WIDTH
        add     hl,de
        ld      d,h
        ld      e,l
        pop     hl

        pop     af
        dec     a
        jr      nz,.loop1

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

RoomOnlyForGBC::

    xor     a,a ; White screen
    ld      [rBGP],a

    call    SetDefaultVBLHandler

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_BGON|LCDCF_BG8800|LCDCF_ON
    ld      [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    call    OnlyForGBCLoadBG

    ld      a,$1B
    ld      [rBGP],a

.loop:
    halt
    jr      .loop

;###############################################################################
