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

    SECTION "All Points Addressable Variables",WRAM0

;-------------------------------------------------------------------------------

apa_color: DS 1 ; color being used to draw

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
    ld      d,0
    ld      hl,$8800
    call     memset

    ret

;-------------------------------------------------------------------------------

APA_SetColor:: ; a = color (0 to 3)

    ld      [apa_color],a

    ret

;-------------------------------------------------------------------------------

APA_Plot:: ; b = x, c = y (0-127!)

    ld      a,b
    sra     a
    sra     a
    sra     a
    ld      d,a ; d = tile x
    ld      a,b
    and     a,7
    ld      b,a ; b = x inside tile

    ld      a,c
    sra     a
    sra     a
    sra     a
    ld      e,a ; e = tile y
    ld      a,c
    and     a,7
    ld      c,a ; c = y inside tile

    ld      a,e
    swap    a ; a = tile y * 16
    add     a,d ; a = tile x + tile y * 16

    ld      l,a
    ld      h,0
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl ; multiply tile number * tile size (16)
    ; hl = tile offset

    ; b = x inside tile
    ; c = y inside tile

    ld      e,c
    ld      d,0 ; de = y inside tile
    add     hl,de
    add     hl,de ; hl = tile + y*2

    ld      de,$8800
    add     hl,de ; hl = base tiles + tile + y*2

    ; b = x inside tile
    ; hl = pointer to the 2 bytes that form the row

    ld      c,rSTAT & $FF
.wait_read_loop\@:
    ld      a,[$FF00+c]
    bit     1,a
    jr      nz,.wait_read_loop\@ ; Not mode 0 or 1

    ; b = x inside tile

    ld      a,[apa_color]
    ld      d,a
    and     a,1
    ld      e,a ; e = low color bit

    ld      a,d
    rra
    and     a,1
    ld      d,a ; d = high color bit

    ld      a,7
    sub     a,b
    ld      b,a ; b = b - 7, for the shift loop

    ld      a,(~1) & $FF ; bit mask

    inc     b
.shift_loop:
    dec     b
    jr      z,.shift_end
    rlca ; rotate A not through carry
    sla     e
    sla     d
    jr      .shift_loop
.shift_end:

    ld      b,a

    ; b = bit mask
    ; e = low color bit
    ; d = high color bit
    ; hl = pointer

.loop\@:
    ld      a,[rSTAT]
    bit     1,a
    jr      nz,.loop\@ ; Not mode 0 or 1

    ld      a,[hl+]
    ld      c,a ; c = low byte
    ld      a,[hl-] ; a = high byte

    and     a,b ; high & bit mask
    or      a,d ; high & bit mask | color
    ld      d,a ; d = high final byte

    ld      a,c
    and     a,b ; low & bit mask
    or      a,e ; low & bit mask | color
    ld      e,a ; e = low final byte

.loop2\@:
    ld      a,[rSTAT]
    bit     1,a
    jr      nz,.loop2\@ ; Not mode 0 or 1

    ld      a,e
    ld      [hl+],a
    ld      [hl],d

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

    ld      a,2
    call    APA_SetColor

    ld      b,40
.loop1:
    ld      c,50
    push    bc
    call    APA_Plot ; b = x, c = y (0-127!)
    pop     bc
    dec     b
    jr      nz,.loop1

    ld      a,3
    call    APA_SetColor

    ld      b,10
.loop2:
    push    bc
    call    APA_Plot ; b = x, c = y (0-127!)
    pop     bc
    dec     c
    jr      nz,.loop2


    ld      a,0
.loop:
    push    af

    ld      d,a

    ld      h,(Sine>>8) & $FF
    ld      l,a
    ld      a,[hl] ; x
    sra     a
    sra     a
    add     a,64
    ld      b,a

    ld      a,d

    ld      h,(Cosine>>8) & $FF
    ld      l,a
    ld      a,[hl] ; x
    sra     a
    sra     a
    add     a,64
    ld      c,a

    call    APA_Plot ; b = x, c = y (0-127!)

    pop     af
    inc     a
    jr      nz,.loop

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
