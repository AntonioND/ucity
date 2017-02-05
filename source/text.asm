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

    INCLUDE "text.inc"

;###############################################################################

    SECTION "Text Data",ROMX

;-------------------------------------------------------------------------------

TextTilesData:
.s:
    INCBIN "text_tiles.bin"
.e:

TextTilesNumber EQU (.e - .s) / (8*8/4)
TEXT_BASE_TILE  EQU (128-TextTilesNumber)

;###############################################################################

    SECTION "Text Functions",ROM0

;-------------------------------------------------------------------------------

TEXT_PALETTE:: ; To be loaded in slot 7
    DW (31<<10)|(31<<5)|(31<<0), (21<<10)|(21<<5)|(21<<0)
    DW (10<<10)|(10<<5)|(10<<0), (0<<10)|(0<<5)|(0<<0)

LoadTextPalette:: ; Load text palette into slot 7

    ld      a,7
    ld      hl,TEXT_PALETTE
    call    bg_set_palette_safe

    ret

LoadText:: ; b = 1 -> load at bank 8800h, b = 0 -> load at bank at 8000h

    xor     a,a
    ld      [rVBK],a

    LD_DE_BC ; (*)

    ld      b,BANK(TextTilesData)
    call    rom_bank_push_set ; preserves de

    LD_BC_DE  ; (*)

    bit     0,b
    jr      nz,.bank_8800

        ld      bc,TextTilesNumber
        ld      de,TEXT_BASE_TILE ; Bank at 8000h
        ld      hl,TextTilesData
        call    vram_copy_tiles

        jr      .end_load
.bank_8800:

        ld      bc,TextTilesNumber
        ld      de,TEXT_BASE_TILE+256 ; Bank at 8800h
        ld      hl,TextTilesData
        call    vram_copy_tiles

.end_load:

    call    rom_bank_pop

    ret

;###############################################################################
