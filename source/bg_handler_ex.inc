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

; PRIVATE ENGINE FILE!
; To be included in "bg_handler.asm"

;###############################################################################

    INCLUDE "room_game.inc"

;###############################################################################

__bg_load_map_main:

    ; save bg size to bg_w, bg_h and bg_size

    ld      a,CITY_MAP_WIDTH
    ld      [bg_w],a
    ld      a,CITY_MAP_HEIGHT
    ld      [bg_h],a

    ld      a,(CITY_MAP_WIDTH*CITY_MAP_HEIGHT)&$FF
    ld      [bg_size+0],a
    ld      a,((CITY_MAP_WIDTH*CITY_MAP_HEIGHT)>>8)&$FF
    ld      [bg_size+1],a

    ; hl points to the tile map and attr map now

    ; make sure we load the map correctly and it doesn't overflow
    ld      a,[bg_x]
    ld      b,a
    ld      a,CITY_MAP_WIDTH-20
    cp      a,b
    jr      c,.width_not_ok ; keep the calculated value
    ld      a,b
.width_not_ok:
    ld      [bg_x],a

    ld      a,[bg_y]
    ld      b,a
    ld      a,CITY_MAP_HEIGHT-18
    cp      a,b
    jr      c,.height_not_ok ; keep the calculated value
    ld      a,b
.height_not_ok:
    ld      [bg_y],a

    ld      a,[bg_x]
    sla     a
    sla     a
    sla     a
    ld      [bg_scx],a

    ld      a,[bg_y]
    sla     a
    sla     a
    sla     a
    ld      [bg_scy],a

    ld      a,[bg_x]
    ld      b,a
    ld      a,[bg_y]
    ld      c,a
    push    bc ; save real coordinates (***)

    ;----------------------------------------------
    ; Load the previous line and column if possible by modifying the saved
    ; coordinates. They will be corrected at the end of the function.
    ld      a,[bg_x]
    and     a,a
    jr      z,.dont_dec
    dec     a
    ld      [bg_x],a
.dont_dec:

    ld      a,[bg_y]
    and     a,a
    jr      z,.dont_dec2
    dec     a
    ld      [bg_y],a
.dont_dec2:
    ;----------------------------------------------

    ; Load tile and attribute map
    ; ---------------------------

    ld      a,[bg_y]
    ld      c,CITY_MAP_WIDTH
    call    mul_u8u8u16
    ld      a,[bg_x]
    ld      c,a
    ld      b,0
    add     hl,bc ; hl = width*y + x

    ld      de,CITY_MAP_TILES ; hl = map base

    add     hl,de ; hl = map_ptr + width*y + x

    ld      a,[bg_x]
    ld      b,a
    ld      a,[bg_y]
    ld      c,a

    ld      a,20 ; a = num rows

.loop:

    push    af
    push    bc
    push    hl

        ld      a,BANK_CITY_MAP_TILES
        ld      [rSVBK],a ; set correct WRAM bank
        xor     a,a
        ld      [rVBK],a

        push    bc
        push    hl
        call    ____vram_copy_row_wrap
        pop     hl
        pop     bc

        ld      a,BANK_CITY_MAP_ATTR
        ld      [rSVBK],a ; set correct WRAM bank
        ld      a,1
        ld      [rVBK],a

        call    ____vram_copy_row_wrap

    pop     hl
    pop     bc
    pop     af

    dec     a
    jr      z,.end

    push    af
    push    bc

    ld      a,CITY_MAP_WIDTH

    ld      c,a
    ld      b,0
    add     hl,bc ; increase source by one bg line

    pop     bc
    pop     af

    inc     c ; y++

    jr      .loop

.end:

    ; Finished!
    ; ---------

    pop     bc ; restore real coordinates (***)
    ld      a,b
    ld      [bg_x],a
    ld      a,c
    ld      [bg_y],a

    call    bg_update_scroll_registers

    ret

;-------------------------------------------------------------------------------
;- bg_reload_main()                                                            -
;-------------------------------------------------------------------------------

bg_reload_main::

    ld      a,[bg_x]
    ld      d,a
    ld      a,[bg_y]
    ld      e,a

    call    bg_load_main

    ret

;-------------------------------------------------------------------------------
;- bg_reload_map_main()                                                        -
;-------------------------------------------------------------------------------

bg_reload_map_main::

    ld      a,[bg_x]
    ld      d,a
    ld      a,[bg_y]
    ld      e,a

    ; RESET INFORMATION

    xor     a,a
    ld      [going_x],a
    ld      [going_y],a

    ld      a,d
    ld      [bg_x],a
    ld      a,e
    ld      [bg_y],a

    ; LOAD MAP

    call    __bg_load_map_main

    ret

;-------------------------------------------------------------------------------
;- bg_load_main()    d = up left x    e = y                                    -
;-------------------------------------------------------------------------------

bg_load_main::

    ld      a,d
    ld      [bg_x],a
    ld      a,e
    ld      [bg_y],a

    ; RESET INFORMATION AND LOAD MAP

    call    bg_reload_map_main

    ; LOAD TILES
    ld      b,BANK(CITY_TILESET)
    call    rom_bank_push_set

CITY_TILESET_NUMBER_TILES EQU 512
HALF_TILES_ONE_BANK EQU 128
TILE_SIZE EQU (8*8/4)

    xor     a,a
    ld      [rVBK],a

    ld      bc,HALF_TILES_ONE_BANK
    ld      de,256
    ld      hl,CITY_TILESET
    call    vram_copy_tiles
    ld      bc,HALF_TILES_ONE_BANK
    ld      de,128
    ld      hl,CITY_TILESET+TILE_SIZE*(HALF_TILES_ONE_BANK*1)
    call    vram_copy_tiles

    ld      a,1
    ld      [rVBK],a

    ld      bc,HALF_TILES_ONE_BANK
    ld      de,256
    ld      hl,CITY_TILESET+TILE_SIZE*(HALF_TILES_ONE_BANK*2)
    call    vram_copy_tiles
    ld      bc,HALF_TILES_ONE_BANK
    ld      de,128
    ld      hl,CITY_TILESET+TILE_SIZE*(HALF_TILES_ONE_BANK*3)
    call    vram_copy_tiles

    ; LOAD PALETTES

    ; Wait until VBL
    di

    ld      b,144
    call    wait_ly

    ld      hl,CITY_TILESET_PALETTES

    ld      a,0
    call    bg_set_palette ; hl will increase inside
    ld      a,1
    call    bg_set_palette
    ld      a,2
    call    bg_set_palette
    ld      a,3
    call    bg_set_palette
    ld      a,4
    call    bg_set_palette
    ld      a,5
    call    bg_set_palette
    ld      a,6
    call    bg_set_palette
    ld      a,7
    call    bg_set_palette

    ei

    ; FINISHED!

    call    rom_bank_pop

    ret


;-------------------------------------------------------------------------------
;- bg_main_scroll_right()    returns: a = if moved 1 else 0                    -
;-------------------------------------------------------------------------------

bg_main_scroll_right::
    ; Check if we can move
    ld      a,[bg_x_in_tile]
    and     a,a
    jr      nz,._dont_exit ; we are already in the middle of a tile, we can move

    ; check right
    ld      a,[bg_x]
    ld      b,a
    ld      a,CITY_MAP_WIDTH-20
    cp      a,b
    ld      a,0 ; return 0 (don't change this instruction to "xor a,a")
    ret     z ; return if we are in the limit

._dont_exit:

    ld      hl,going_x
    ld      a,[hl]
    and     a,a
    jr      nz,._inthemiddle
    ld      [hl],1
._inthemiddle:

    ; MOVE
    ld      hl,bg_scx
    inc     [hl]

    ld      hl,bg_x_in_tile
    ld      a,1
    add     a,[hl]
    and     a,7
    ld      [hl],a
    and     a,a
    ld      a,1 ; return 1
    ret     nz ; not needed to add column yet

    ld      a,[going_x]
    cp      a,1
    push    af
    xor     a,a
    ld      [going_x],a
    pop     af
    ld      a,1 ; return 1
    ret     nz ; not needed to add column -> change of direction fix

    ; INCREASE TILE POSITION AND ADD COLUMN
    ld      hl,bg_x
    inc     [hl]

    ld      a,CITY_MAP_WIDTH
    ld      c,a
    ld      a,[bg_y]
    and     a,a
    jr      z,._dontdec1
    dec     a
._dontdec1:
    call    mul_u8u8u16 ; hl = y*width
    ld      a,[bg_x]
    add     a,20
    ld      e,a
    ld      d,0
    add     hl,de ; hl = y*width + x

    ld      de,CITY_MAP_TILES
    add     hl,de ; hl = ptr + y*width + x

    ld      a,[bg_x]
    add     a,20
    ld      b,a ; b = x

    ld      a,[bg_y]
    and     a,a
    jr      z,._dontdec2
    dec     a
._dontdec2:
    ld      c,a

    ; ---------------

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a ; set correct WRAM bank

    xor     a,a
    ld      [rVBK],a

    push    bc
    push    hl
    call    ____vram_copy_column_wrap ; b = x, c = y, hl = source address
    pop     hl
    pop     bc

    ld      a,1
    ld      [rVBK],a

    ld      a,BANK_CITY_MAP_ATTR
    ld      [rSVBK],a ; set correct WRAM bank

    call    ____vram_copy_column_wrap ; b = x, c = y, hl = source address

    ; --------

    xor     a,a
    ld      [going_x],a

    ld      a,1 ; return 1
    ret

;-------------------------------------------------------------------------------
;- bg_main_scroll_left()    returns: a = if moved 1 else 0                     -
;-------------------------------------------------------------------------------

bg_main_scroll_left::
    ; Check if we can move
    ld      a,[bg_x_in_tile]
    and     a,a
    jr      nz,._dont_exit ; we are already in the middle of a tile, we can move

    ; check left
    ld      a,[bg_x]
    and     a,a
    ld      a,0 ; return 0 (don't change this instruction to "xor a,a")
    ret     z ; return if we are in the limit

._dont_exit:

    ld      hl,going_x
    ld      a,[hl]
    and     a,a
    jr      nz,._inthemiddle
    ld      [hl],-1
._inthemiddle:

    ; MOVE
    ld      hl,bg_scx
    dec     [hl]

    ld      hl,bg_x_in_tile
    ld      a,-1
    add     a,[hl]
    and     a,7
    ld      [hl],a
    and     a,a
    ld      a,1 ; return 1
    ret     nz ; not needed to add column yet

    ld      a,[going_x]
    cp      a,-1
    push    af
    xor     a,a
    ld      [going_x],a
    pop     af
    ld      a,1 ; return 1
    ret     nz ; not needed to add column -> change of direction fix

    ; DECREASE TILE POSITION AND ADD COLUMN

    ld      hl,bg_x
    dec     [hl]

    ld      a,CITY_MAP_WIDTH
    ld      c,a
    ld      a,[bg_y]
    and     a,a
    jr      z,._dontdec3
    dec     a
._dontdec3:
    call    mul_u8u8u16 ; hl = y*width
    ld      a,[bg_x]
    dec     a
    ld      e,a
    ld      d,0
    add     hl,de ; hl = y*width + x

    ld      de,CITY_MAP_TILES
    add     hl,de ; hl = ptr + y*width + x

    ld      a,[bg_x]
    dec     a
    ld      b,a ; b = x

    ld      a,[bg_y]
    and     a,a
    jr      z,._dontdec6
    dec     a
._dontdec6:
    ld      c,a

    ; ---------------

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a ; set correct WRAM bank

    xor     a,a
    ld      [rVBK],a

    push    bc
    push    hl
    call    ____vram_copy_column_wrap ; b = x, c = y, hl = source address
    pop     hl
    pop     bc

    ld      a,BANK_CITY_MAP_ATTR
    ld      [rSVBK],a ; set correct WRAM bank

    ld      a,1
    ld      [rVBK],a

    call    ____vram_copy_column_wrap ; b = x, c = y, hl = source address

    ; --------

    xor     a,a
    ld      [going_x],a

    ld      a,1 ; return 1
    ret

;-------------------------------------------------------------------------------
;- bg_main_scroll_down()    returns: a = if moved 1 else 0                     -
;-------------------------------------------------------------------------------

bg_main_scroll_down::
    ; Check if we can move
    ld      a,[bg_y_in_tile]
    and     a,a
    jr      nz,._dont_exit ; we are already in the middle of a tile, we can move

    ; check down
    ld      a,[bg_y]
    ld      b,a
    ld      a,CITY_MAP_HEIGHT
    sub     a,18
    cp      a,b
    ld      a,0 ; return 0 (don't change this instruction to "xor a,a")
    ret     z ; return if we are in the limit

._dont_exit:

    ld      hl,going_y
    ld      a,[hl]
    and     a,a
    jr      nz,._inthemiddle
    ld      [hl],1
._inthemiddle:

    ; MOVE
    ld      hl,bg_scy
    inc     [hl]

    ld      hl,bg_y_in_tile
    ld      a,1
    add     a,[hl]
    and     a,7
    ld      [hl],a
    and     a,a
    ld      a,1 ; return 1
    ret     nz ; not needed to add row yet

    ld      a,[going_y]
    cp      a,1
    push    af
    xor     a,a
    ld      [going_y],a
    pop     af
    ld      a,1 ; return 1
    ret     nz ; not needed to add row -> change of direction fix

    ; INCREASE TILE POSITION AND ADD ROW
    ld      hl,bg_y
    inc     [hl]

    ld      a,CITY_MAP_WIDTH
    ld      c,a
    ld      a,[bg_y]
    add     a,18
    call    mul_u8u8u16 ; hl = y*width
    ld      a,[bg_x]
    and     a,a
    jr      z,._dontdec1
    dec     a
._dontdec1:
    ld      e,a
    ld      d,0
    add     hl,de ; hl = y*width + x

    ld      de,CITY_MAP_TILES
    add     hl,de ; hl = ptr + y*width + x

    ld      a,[bg_x]
    and     a,a
    jr      z,._dontdec2
    dec     a
._dontdec2:
    ld      b,a ; b = x

    ld      a,[bg_y]
    add     a,18
    ld      c,a

    ; ---------------

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a ; set correct WRAM bank

    xor     a,a
    ld      [rVBK],a

    push    bc
    push    hl
    call    ____vram_copy_row_wrap ; b = x, c = y, hl = source address
    pop     hl
    pop     bc

    ld      a,BANK_CITY_MAP_ATTR
    ld      [rSVBK],a ; set correct WRAM bank

    ld      a,1
    ld      [rVBK],a

    call    ____vram_copy_row_wrap ; b = x, c = y, hl = source address

    ; --------

    xor     a,a
    ld      [going_y],a

._end1:
    ld      a,1 ; return 1
    ret

;-------------------------------------------------------------------------------
;- bg_main_scroll_up()    returns: a = if moved 1 else 0                       -
;-------------------------------------------------------------------------------

bg_main_scroll_up::
    ; Check if we can move
    ld      a,[bg_y_in_tile]
    and     a,a
    jr      nz,._dont_exit

    ; check up
    ld      a,[bg_y]
    and     a,a
    ld      a,0 ; return 0 (don't change this instruction to "xor a,a")
    ret     z ; return if we are in the limit

._dont_exit:

    ld      hl,going_y
    ld      a,[hl]
    and     a,a
    jr      nz,._inthemiddle
    ld      [hl],-1
._inthemiddle:

    ; MOVE
    ld      hl,bg_scy
    dec     [hl]

    ld      hl,bg_y_in_tile
    ld      a,-1
    add     a,[hl]
    and     a,7
    ld      [hl],a
    and     a,a
    ld      a,1 ; return 1
    ret     nz ; not needed to add row yet

    ld      a,[going_y]
    cp      a,-1
    push    af
    xor     a,a
    ld      [going_y],a
    pop     af
    ld      a,1 ; return 1
    ret     nz ; not needed to add row -> change of direction fix

    ; DECREASE TILE POSITION AND ADD COLUMN

    ld      hl,bg_y
    dec     [hl]

    ld      a,CITY_MAP_WIDTH
    ld      c,a
    ld      a,[bg_y]
    dec     a
    call    mul_u8u8u16 ; hl = y*width
    ld      a,[bg_x]
    and     a,a
    jr      z,._dontdec3
    dec     a
._dontdec3:
    ld      e,a
    ld      d,0
    add     hl,de ; hl = y*width + x

    ld      de,CITY_MAP_TILES
    add     hl,de ; hl = ptr + y*width + x

    ld      a,[bg_x]
    and     a,a
    jr      z,._dontdec4
    dec     a
._dontdec4:
    ld      b,a ; b = x

    ld      a,[bg_y]
    dec     a
    ld      c,a

    ; ---------------

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a ; set correct WRAM bank

    xor     a,a
    ld      [rVBK],a

    push    bc
    push    hl
    call    ____vram_copy_row_wrap ; b = x, c = y, hl = source address
    pop     hl
    pop     bc

    ld      a,BANK_CITY_MAP_ATTR
    ld      [rSVBK],a ; set correct WRAM bank

    ld      a,1
    ld      [rVBK],a

    call    ____vram_copy_row_wrap ; b = x, c = y, hl = source address

    ; --------

    xor     a,a
    ld      [going_y],a

._end2

    ld      a,1 ; return 1
    ret

;-------------------------------------------------------------------------------

bg_main_drift_scroll_hor::

    ld      e,0

    ld      a,[going_x]
    cp      a,1
    jr      nz,.not_right
    REPT    2
    call    bg_main_scroll_right
    ENDR
    ld      e,1
.not_right:

    ld      a,[going_x]
    cp      a,-1
    jr      nz,.not_left
    REPT    2
    call    bg_main_scroll_left
    ENDR
    ld      e,1
.not_left:

    ld      a,e
    ret

bg_main_drift_scroll_ver::

    ld      e,0

    ld      a,[going_y]
    cp      a,1
    jr      nz,.not_down
    REPT    2
    call    bg_main_scroll_down
    ENDR
    ld      e,1
.not_down:

    ld      a,[going_y]
    cp      a,-1
    jr      nz,.not_up
    REPT    2
    call    bg_main_scroll_up
    ENDR
    ld      e,1
.not_up:

    ld      a,e
    ret

;###############################################################################
