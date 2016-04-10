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

    INCLUDE "apa.inc"

;###############################################################################

    SECTION "All Points Addressable Data",ROMX

;-------------------------------------------------------------------------------

;###############################################################################

    SECTION "All Points Addressable Functions",ROMX

;-------------------------------------------------------------------------------

APA_BufferClear::

    ld      a,1
    ld      [rVBK],a

    ld      bc,APA_TILE_NUMBER*(8*8/4) ; size to clear
    ld      d,0
    ld      hl,$8800
    call    vram_memset

    ld      bc,APA_TILE_NUMBER*(8*8/4) ; size to clear
    ld      hl,$8800
    call     memset_rand

    ret

;-------------------------------------------------------------------------------

APA_PALETTE:: ; To be loaded in slot 7
    DW (31<<10)|(31<<5)|(31<<0), (21<<10)|(21<<5)|(21<<0)
    DW (10<<10)|(10<<5)|(10<<0), (0<<10)|(0<<5)|(0<<0)

APA_LoadPalette:: ; Load palette to slot APA_PALETTE_INDEX. Do this during VBL!

    ; TODO: Allow different palettes

    ld      a,APA_PALETTE_INDEX
    ld      hl,APA_PALETTE
    call    bg_set_palette

    ret

;-------------------------------------------------------------------------------

APA_LoadGFX::

    ret

;-------------------------------------------------------------------------------

APA_ResetBackgroundMapping:: ; de = bg base pointer

IF APA_TILE_NUMBER != 256
    FAIL "APA_TILE_NUMBER should be 256!"
ENDC

    ld      hl,$9800+32*APA_TILE_OFFSET_Y+APA_TILE_OFFSET_X
     ; hl is the start of the area to modify

    ; Tilemap
    push    hl ; (*)

    xor     a,a
    ld      [rVBK],a

    ld      b,128 ; b = tile counter

    ld      d,APA_TILE_HEIGHT
.loop1_out:
    ld      e,APA_TILE_WIDTH
.loop1_in:
        WAIT_SCREEN_BLANK
        ld      [hl],b
        inc     hl
        inc     b
        dec     e
        jr      nz,.loop1_in

    ld      a,b
    ld      bc,32-APA_TILE_WIDTH
    add     hl,bc
    ld      b,a

    dec     d
    jr      nz,.loop1_out

    pop     hl ; (*)

    ; Attributes - fill with the desired palette
    ld      a,1
    ld      [rVBK],a

    ld      d,APA_TILE_HEIGHT
.loop2_out:
    ld      e,APA_TILE_WIDTH
.loop2_in:
        WAIT_SCREEN_BLANK
        ld      a,APA_PALETTE_INDEX|(1<<3) ; BANK 1
        ld      [hl+],a
        dec     e
        jr      nz,.loop2_in

    ld      bc,32-APA_TILE_WIDTH
    add     hl,bc

    dec     d
    jr      nz,.loop2_out

    ret

;###############################################################################

    SECTION "All Points Addressable Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

;###############################################################################
