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
    INCLUDE "room_game.inc"

;###############################################################################

    SECTION "All Points Addressable Variables",WRAM0

;-------------------------------------------------------------------------------

APA_BUFFER_ROWS    EQU 2
APA_BUFFER_COLUMNS EQU 2

; Colors being used to draw (left to right, top to bottom)
apa_colors: DS (APA_BUFFER_ROWS*APA_BUFFER_COLUMNS)

MINIMAP_BACKBUFFER_BASE       EQU $D000
MINIMAP_BACKBUFFER_WRAMX_BANK EQU BANK_CITY_MAP_TILE_OK_FLAGS

MINIMAP_VRAM_BASE EQU $8800

;###############################################################################

    SECTION "All Points Addressable Variables",WRAM0

;-------------------------------------------------------------------------------

pixel_stream_ptr: DS 2 ; LSB first, pointer to part the buffer to be drawn

pixel_stream_cur_y_in_tile: DS 1 ; y inside tile
pixel_stream_cur_x_tile: DS 1 ; x tile
pixel_stream_cur_x_in_tile: DS 1 ; x inside tile

; 8 pixels to be drawn the next 2 rows
pixel_stream_row_buffers: DS (APA_BUFFER_ROWS*2)

;###############################################################################

    SECTION "All Points Addressable Functions",ROMX

;-------------------------------------------------------------------------------

APA_PixelStreamStart::

    xor     a,a
    ld      [pixel_stream_cur_y_in_tile],a
    ld      [pixel_stream_cur_x_in_tile],a
    ld      [pixel_stream_cur_x_tile],a
    ld      [pixel_stream_row_buffers+0],a
    ld      [pixel_stream_row_buffers+1],a
    ld      [pixel_stream_row_buffers+2],a
    ld      [pixel_stream_row_buffers+3],a

    ld      a,MINIMAP_BACKBUFFER_BASE & $FF
    ld      [pixel_stream_ptr+0],a
    ld      a,(MINIMAP_BACKBUFFER_BASE>>8) & $FF
    ld      [pixel_stream_ptr+1],a

    ret

;-------------------------------------------------------------------------------

APA_PixelStreamPlot2x2::

    ld      hl,pixel_stream_row_buffers

    ; Top Left
    ld      a,[apa_colors+0]
    ld      c,a
    ld      a,[hl]
    sla     a ; advance position
    ld      b,a
    ld      a,c
    and     a,1
    or      a,b ; new color
    ld      [hl+],a

    ld      a,[hl]
    sla     a ; advance position
    ld      b,a
    ld      a,c
    and     a,2
    rra
    or      a,b ; new color
    ld      [hl-],a

    ; Top Right
    ld      a,[apa_colors+1]
    ld      c,a
    ld      a,[hl]
    sla     a ; advance position
    ld      b,a
    ld      a,c
    and     a,1
    or      a,b ; new color
    ld      [hl+],a

    ld      a,[hl]
    sla     a ; advance position
    ld      b,a
    ld      a,c
    and     a,2
    rra
    or      a,b ; new color
    ld      [hl+],a

    ; Bottom Left
    ld      a,[apa_colors+2]
    ld      c,a
    ld      a,[hl]
    sla     a ; advance position
    ld      b,a
    ld      a,c
    and     a,1
    or      a,b ; new color
    ld      [hl+],a

    ld      a,[hl]
    sla     a ; advance position
    ld      b,a
    ld      a,c
    and     a,2
    rra
    or      a,b ; new color
    ld      [hl-],a

    ; Bottom Right
    ld      a,[apa_colors+3]
    ld      c,a
    ld      a,[hl]
    sla     a ; advance position
    ld      b,a
    ld      a,c
    and     a,1
    or      a,b ; new color
    ld      [hl+],a

    ld      a,[hl]
    sla     a ; advance position
    ld      b,a
    ld      a,c
    and     a,2
    rra
    or      a,b ; new color
    ld      [hl+],a

    ld      a,[pixel_stream_cur_x_in_tile]
    add     a,2
    ld      [pixel_stream_cur_x_in_tile],a
    cp      a,8
    ret     nz ; nothing else to do for now

    xor     a,a
    ld      [pixel_stream_cur_x_in_tile],a

    ; change map

    ld      a,MINIMAP_BACKBUFFER_WRAMX_BANK
    ld      [rSVBK],a

    ; completed row, draw and advance

    ld      a,[pixel_stream_ptr+0]
    ld      l,a
    ld      a,[pixel_stream_ptr+1]
    ld      h,a

    ld      a,[pixel_stream_row_buffers+0]
    ld      [hl+],a
    ld      a,[pixel_stream_row_buffers+1]
    ld      [hl+],a
    ld      a,[pixel_stream_row_buffers+2]
    ld      [hl+],a
    ld      a,[pixel_stream_row_buffers+3]
    ld      [hl+],a

    ; next horizontal tile

    ld      bc,16-APA_BUFFER_ROWS*2 ; tile size - row size
    add     hl,bc

    ld      a,[pixel_stream_cur_x_tile]
    inc     a
    ld      [pixel_stream_cur_x_tile],a
    cp      a,APA_TILE_WIDTH
    jr      nz,.save_ptr

    xor     a,a
    ld      [pixel_stream_cur_x_tile],a

    ld      bc,(APA_BUFFER_ROWS*2)-(16*APA_TILE_WIDTH) ; + pixel row - map row
    add     hl,bc

    ld      a,[pixel_stream_cur_y_in_tile]
    add     a,2
    ld      [pixel_stream_cur_y_in_tile],a
    cp      a,8
    jr      nz,.save_ptr

    xor     a,a
    ld      [pixel_stream_cur_y_in_tile],a

    ld      bc,16*(APA_TILE_WIDTH-1) ; next tile row
    add     hl,bc

.save_ptr:
    ld      a,l
    ld      [pixel_stream_ptr+0],a
    ld      a,h
    ld      [pixel_stream_ptr+1],a

    ret

;-------------------------------------------------------------------------------

APA_PixelStreamPlot::

    ld      a,[apa_colors+0]
    ld      c,a

    ld      a,[pixel_stream_row_buffers+0]
    sla     a ; advance position
    ld      b,a
    ld      a,c
    and     a,1
    or      a,b ; new color
    ld      [pixel_stream_row_buffers+0],a

    ld      a,[pixel_stream_row_buffers+1]
    sla     a ; advance position
    ld      b,a
    ld      a,c
    and     a,2
    rra
    or      a,b ; new color
    ld      [pixel_stream_row_buffers+1],a

    ld      a,[pixel_stream_cur_x_in_tile]
    inc     a
    ld      [pixel_stream_cur_x_in_tile],a
    cp      a,8
    ret     nz ; nothing else to do for now

    xor     a,a
    ld      [pixel_stream_cur_x_in_tile],a

    ; change map

    ld      a,MINIMAP_BACKBUFFER_WRAMX_BANK
    ld      [rSVBK],a

    ; completed row, draw and advance

    ld      a,[pixel_stream_ptr+0]
    ld      l,a
    ld      a,[pixel_stream_ptr+1]
    ld      h,a

    ld      a,[pixel_stream_row_buffers+0]
    ld      [hl+],a
    ld      a,[pixel_stream_row_buffers+1]
    ld      [hl+],a

    ; next horizontal tile

    ld      bc,16-2 ; tile size - row size
    add     hl,bc

    ld      a,[pixel_stream_cur_x_tile]
    inc     a
    ld      [pixel_stream_cur_x_tile],a
    cp      a,APA_TILE_WIDTH
    jr      nz,.save_ptr

    xor     a,a
    ld      [pixel_stream_cur_x_tile],a

    ld      bc,2-(16*APA_TILE_WIDTH) ; + pixel row - map row
    add     hl,bc

    ld      a,[pixel_stream_cur_y_in_tile]
    inc     a
    ld      [pixel_stream_cur_y_in_tile],a
    cp      a,8
    jr      nz,.save_ptr

    xor     a,a
    ld      [pixel_stream_cur_y_in_tile],a

    ld      bc,16*(APA_TILE_WIDTH-1) ; next tile row
    add     hl,bc

.save_ptr:
    ld      a,l
    ld      [pixel_stream_ptr+0],a
    ld      a,h
    ld      [pixel_stream_ptr+1],a

    ret

;-------------------------------------------------------------------------------

APA_Plot:: ; b = x, c = y (0-127!)

    ld      a,MINIMAP_BACKBUFFER_WRAMX_BANK
    ld      [rSVBK],a

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

    ld      de,MINIMAP_BACKBUFFER_BASE
    add     hl,de ; hl = base tiles + tile + y*2

    ; b = x inside tile
    ; hl = pointer to the 2 bytes that form the row

    ld      a,[apa_colors]

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

    ld      a,e
    ld      [hl+],a
    ld      [hl],d

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

APA_BufferClear::

    ld      a,MINIMAP_BACKBUFFER_WRAMX_BANK
    ld      [rSVBK],a

    ld      bc,APA_TILE_NUMBER*(8*8/4) ; size to clear
    ld      d,0
    ld      hl,MINIMAP_BACKBUFFER_BASE
    call    memset

    ret

;-------------------------------------------------------------------------------

APA_BufferUpdate::

    ld      a,1
    ld      [rVBK],a

    ld      a,MINIMAP_BACKBUFFER_WRAMX_BANK
    ld      [rSVBK],a

    ld      bc,APA_TILE_NUMBER ; bc = tiles
    ld      de,128 ; de = start index
    ld      hl,MINIMAP_BACKBUFFER_BASE ; hl = source
    call    vram_copy_tiles

    ret

;-------------------------------------------------------------------------------

APA_LoadPalette:: ; hl = palette to slot APA_PALETTE_INDEX. Do this during VBL!

    ld      a,APA_PALETTE_INDEX
    call    bg_set_palette

    ret

;-------------------------------------------------------------------------------

APA_SetColors:: ; a,b,c,d = color (0 to 3)

    ld      [apa_colors+0],a
    ld      a,b
    ld      [apa_colors+1],a
    ld      a,c
    ld      [apa_colors+2],a
    ld      a,d
    ld      [apa_colors+3],a

    ret

;###############################################################################
