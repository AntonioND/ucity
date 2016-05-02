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

    SECTION "Map_Handling_Vars_HRAM",HRAM

;-------------------------------------------------------------------------------

; IO REGISTERS MIRROR

bg_scx: DS 1 ; updated in VBL
bg_scy: DS 1

;###############################################################################

    SECTION "Map_Handling_Vars",WRAM0

;-------------------------------------------------------------------------------

; STATUS
bg_x::        DS 1 ; x and y in tiles
bg_y::        DS 1
going_x:      DS 1 ; current direction
going_y:      DS 1
bg_x_in_tile: DS 1
bg_y_in_tile: DS 1

; INFORMATION
bg_w:    DS 1 ; width and height in tiles
bg_h:    DS 1
bg_size: DS 2 ; LSB first

bg_struct_bank: DS 1 ; Pointer to BG information.
bg_struct_ptr:  DS 2 ; To be able to reload it.

bg_map_bank:    DS 1 ; Pointer to tile map.
bg_map_ptr:     DS 2 ; LSB first

bg_tiles_struct_bank: DS 1 ; Pointer to tile information struct
bg_tiles_struct_ptr:  DS 2

;###############################################################################

    SECTION "Map_Handling",ROM0

;-------------------------------------------------------------------------------

bg_update_scroll_registers::
    ld      a,[bg_scx]
    ld      [rSCX],a
    ld      a,[bg_scy]
    ld      [rSCY],a
    ret

;-------------------------------------------------------------------------------

__bg_load_tiles: ; hl = tile data struct    b = struct bank

    push    hl
    call    rom_bank_push_set
    pop     hl

    ld      c,[hl]
    inc     hl
    ld      b,[hl] ; bc=number of tiles

    inc     hl ; hl = pointer to tile data

    ld      a,b
    add     a,a ; BIT(1) = 256
    ld      e,a
    ld      a,c
    rla ; BIT(0) = 128
    and     a,$01
    or      a,e
    and     a,$03 ; a = BIT(0) = 128 | BIT(1) = 256

    cp      a,0
    jr      nz,.more_than_128

        ; Less than 128 tiles

        ld      a,0
        ld      [rVBK],a

        ; bc = tiles
        ld      de,256
        call    vram_copy_tiles

        jp      .end

.more_than_128:
    cp      a,1
    jr      nz,.more_than_256

        ; 129 - 256 tiles

        ld      a,0
        ld      [rVBK],a

        push    bc
        ld      bc,128
        ld      de,256
        call    vram_copy_tiles
        pop     bc

        ld      b,0
        ld      a,127
        and     a,c
        ld      c,a ; bc = tiles left
        ld      de,128
        call    vram_copy_tiles

        jp      .end

.more_than_256:
    cp      a,1
    jr      nz,.more_than_384

        ; 257 - 384 tiles

        ld      a,0
        ld      [rVBK],a

        push    bc
        ld      bc,128
        ld      de,256
        call    vram_copy_tiles

        ld      bc,128
        ld      de,128
        call    vram_copy_tiles
        pop     bc

        ld      a,1
        ld      [rVBK],a

        ld      b,0
        ld      a,127
        and     a,c
        ld      c,a ; bc = tiles left
        ld      de,256
        call    vram_copy_tiles

        ld      a,0
        ld      [rVBK],a

        jr      .end

.more_than_384:

        ; 385 - 512 tiles

        ld      a,0
        ld      [rVBK],a

        push    bc
        ld      bc,128
        ld      de,256
        call    vram_copy_tiles

        ld      bc,128
        ld      de,128
        call    vram_copy_tiles

        ld      a,1
        ld      [rVBK],a

        ld      bc,128
        ld      de,256
        call    vram_copy_tiles

        pop     bc

        ld      b,0
        ld      a,127
        and     a,c
        ld      c,a ; bc = tiles left
        ld      de,128
        call    vram_copy_tiles

        jr      .end

.end:

    ld      a,0
    ld      [rVBK],a

    call    rom_bank_pop
    ret

;-------------------------------------------------------------------------------

____vram_copy_row_wrap: ; b = x, c = y, hl = source address

    ld      a,31 ; limit coordinates to 0-31
    and     a,c
    ld      c,a

    ld      a,31
    and     a,b
    ld      b,a

    push    hl

    ; get addresses

    ld      d,$9C
    ld      e,b ; de = bg base + x

    ld      l,c
    ld      h,0
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl ; hl = y * 32
    add     hl,de ; hl = dest = bg base + y * 32 + x

    pop     de ; de = src

    ; wait until start of HBL or VBL

    ; save 22 tiles to VRAM

    ; b = current x

    ld      c,rSTAT & $FF

    REPT 22
        ld      a,d
        cp      a,$E0 ; prevent reads from ECHO RAM or higher
        jp      nc,.end

        di ; Entering critical section

.wait\@: ; wait until mode 0 or 1
        ld      a,[$FF00+c]
        bit     1,a
        jr      nz,.wait\@

        ld      a,[de]
        ld      [hl+],a

        ei ; End of critical section

        inc     de

        inc     b

        bit     5,b
        jr      z,.not_wrap\@
        push    de
        ld      de,-32
        add     hl,de
        pop     de
        ld      b,0
.not_wrap\@:
    ENDR
.end:

    ret

;--------------------------------------------------------------------------

____vram_copy_column_wrap: ; b = x, c = y, hl = source address

    ld      a,31 ; limit coordinates to 0-31
    and     a,c
    ld      c,a

    ld      a,31
    and     a,b
    ld      b,a

    add     sp,-20 ; use stack as temporary variable space

    push    hl
    ld      hl,sp+2 ; sp = TEMP (skip the hl that has been pushed)
    ld      d,h
    ld      e,l
    pop     hl ; de = TEMP, hl = SRC

    ; read 20 tiles and save to temp space

    push    bc

    ld      a,[bg_w]
    ld      b,0
    ld      c,a
    REPT 20
        ld      a,h
        cp      a,$E0 ; prevent reads from ECHO RAM or higher
        jp      nc,.end

        ld      a,[hl]
        add     hl,bc
        ld      [de],a
        inc     de
    ENDR
.end:

    pop     bc

    ; get addresses

    ld      d,$9C
    ld      e,b ; de = bg base + x

    ld      l,c
    ld      h,0
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl ; hl = y * 32
    add     hl,de ; hl = dest = bg base + y * 32 + x

    push    hl
    ld      hl,sp+2 ; skip hl
    ld      e,l
    ld      d,h
    pop     hl ; de = sp = TEMP

    ; wait until start of HBL or VBL

    ; save 20 tiles to VRAM

    ld      b,c ; b = current y

    ld      c,rSTAT & $FF

    REPT 20
        di ; Entering critical section

.wait\@: ; wait until mode 0 or 1
        ld      a,[$FF00+c]
        bit     1,a
        jr      nz,.wait\@

        ld      a,[de]
        ld      [hl],a

        ei ; End of critical section

        inc     de

        push    bc
        ld      bc,32
        add     hl,bc
        pop     bc

        inc     b

        bit     5,b
        jr      z,.not_wrap\@
        push    de
        ld      de,-(32*32)
        add     hl,de
        pop     de
        ld      b,0
.not_wrap\@:
    ENDR

    add     sp,+20 ; claim back temporary variable space

    ret

;-------------------------------------------------------------------------------

__bg_load_map: ; hl = pointer to data    b = struct bank

    ld      a,b
    ld      [bg_map_bank],a

    ; Change to the bank that contains BG info. B value is useless after this
    push    hl
    call    rom_bank_push_set
    pop     hl

    ; save bg size to bg_w, bg_h and bg_size

    ld      a,[hl+]
    ld      [bg_w],a

    ld      a,[hl+]
    ld      [bg_h],a

    ld      a,[hl+]
    ld      [bg_size+0],a
    ld      a,[hl+]
    ld      [bg_size+1],a

    ; hl points to the tile map and attr map now

    ld      a,l
    ld      [bg_map_ptr+0],a
    ld      a,h
    ld      [bg_map_ptr+1],a

    ; make sure we load the map correctly and it doesn't overflow
    ld      a,[bg_x]
    ld      b,a
    ld      a,[bg_w]
    sub     a,20
    cp      a,b
    jr      c,.width_not_ok ; keep the calculated value
    ld      a,b
.width_not_ok:
    ld      [bg_x],a

    ld      a,[bg_y]
    ld      b,a
    ld      a,[bg_h]
    sub     a,18
    cp      a,b
    jr      c,.height_not_ok ; keep the calculated value
    ld      a,b
.height_not_ok:
    ld      [bg_y],a

    ld      a,[bg_x]
    add     a,a
    add     a,a
    add     a,a
    ld      [bg_scx],a

    ld      a,[bg_y]
    add     a,a
    add     a,a
    add     a,a
    ld      [bg_scy],a

    ld      a,[bg_x]
    ld      b,a
    ld      a,[bg_y]
    ld      c,a
    push    bc ; save real coordinates ***

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

    ; hl STILL points to the tile map and attr map

    ; Load tile map
    ; -------------

    ld      a,0
    ld      [rVBK],a ; VRAM bank 0

    push    hl

    ld      a,[bg_y]
    ld      c,a
    ld      a,[bg_w]
    call    mul_u8u8u16
    ld      a,[bg_x]
    ld      c,a
    ld      b,0
    add     hl,bc ; hl = width*y + x

    ld      d,h
    ld      e,l

    pop     hl

    add     hl,de ; hl = map_ptr + width*y + x

    push    hl ; this will be useful later for loading attr map

    ld      a,[bg_x]
    ld      b,a
    ld      a,[bg_y]
    ld      c,a

    ld      a,20 ; a = num rows

.loop:

    push    af
    push    bc
    push    hl
    call    ____vram_copy_row_wrap
    pop     hl
    pop     bc
    pop     af

    dec     a
    jr      z,.end

    push    af
    push    bc

    ld      a,[bg_w]

    ld      c,a
    ld      b,0
    add     hl,bc ; increase source by one bg line

    pop     bc
    pop     af

    inc     c ; y++

    jr      .loop

.end:

    ; Load attr map
    ; -------------

    ld      a,1
    ld      [rVBK],a ; VRAM bank 1

    pop     hl ; restore hl = map_ptr + width*y + x, which was saved before

    ld      a,[bg_size+0]
    ld      e,a
    ld      a,[bg_size+1]
    ld      d,a
    add     hl,de ; hl = attr_map_ptr + width*y + x

    ld      a,[bg_x]
    ld      b,a
    ld      a,[bg_y]
    ld      c,a

    ld      a,20 ; a = num rows

.loop2:

    push    af
    push    bc
    push    hl
    call    ____vram_copy_row_wrap
    pop     hl
    pop     bc
    pop     af

    dec     a
    jr      z,.end2

    push    af
    push    bc

    ld      a,[bg_w]

    ld      c,a
    ld      b,0
    add     hl,bc ; increase source by one bg line

    pop     bc
    pop     af

    inc     c ; y++

    jr      .loop2

.end2:

    ; Finished!
    ; ---------

    ld      a,0
    ld      [rVBK],a ; back to VRAM bank 0

    pop     bc ; restore real coordinates ***
    ld      a,b
    ld      [bg_x],a
    ld      a,c
    ld      [bg_y],a

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------
;- bg_reload()                                                                 -
;-------------------------------------------------------------------------------

bg_reload::

    ld      a,[bg_struct_bank]
    ld      b,a

    ld      hl,bg_struct_ptr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ld      a,[bg_x]
    ld      d,a
    ld      a,[bg_y]
    ld      e,a

    call    _bg_load

    ret

;-------------------------------------------------------------------------------
;- bg_scroll_in_tile()    returns 1 in a if scroll is between tiles            -
;-------------------------------------------------------------------------------

bg_scroll_in_tile::

    ld      a,[going_x]
    ld      b,a
    ld      a,[going_y]
    or      a,b ; Set z flag

    ld      a,0 ; Don't change to xor a,a
    ret     z ; Return 0

    inc     a
    ret ; Return 1

;-------------------------------------------------------------------------------
;- _bg_load()    hl = bg data    b = bank    d = up left x    e = y            -
;-------------------------------------------------------------------------------

_bg_load::

    ; RESET INFORMATION

    xor     a,a
    ld      [going_x],a
    ld      [going_y],a

    ld      a,d
    ld      [bg_x],a
    ld      a,e
    ld      [bg_y],a

    ld      a,l
    ld      [bg_struct_ptr],a
    ld      a,h
    ld      [bg_struct_ptr+1],a

    ld      a,b
    ld      [bg_struct_bank],a

    push    hl
    call    rom_bank_push_set ; ***
    pop     hl

    ; LOAD MAP

    ld      e,[hl]
    inc     hl
    ld      d,[hl]
    inc     hl ; de = pointer to map data

    ld      b,[hl] ; b = bank with map data
    inc     hl

    push    hl

    ld      h,d
    ld      l,e
    call    __bg_load_map

    pop     hl

    ; LOAD TILES

    ld      e,[hl]
    inc     hl
    ld      d,[hl]
    inc     hl ; de = pointer to tile data

    ld      a,e
    ld      [bg_tiles_struct_ptr],a
    ld      a,d
    ld      [bg_tiles_struct_ptr+1],a

    ld      b,[hl] ; b = bank with tile data
    inc     hl

    ld      a,b
    ld      [bg_tiles_struct_bank],a ; b = tile data bank

    push    hl

    ld      h,d ; hl = pointer to tile data struct
    ld      l,e

    call    __bg_load_tiles

    pop     hl

    ; LOAD PALETTES

    ; Wait until VBL - Palettes must be loaded at once

    di ; Entering critical section

    ld      b,144
    call    wait_ly

    ld      b,[hl] ; B = number of palettes
    inc     hl ; hl = ptr to color data

    xor     a,a
.pal_loop:

    push    af
    call    bg_set_palette ; hl will increase inside
    pop     af

    inc     a
    cp      a,b
    jr      nz,.pal_loop

    ei ; End of critical section

    ; FINISHED!

    call    rom_bank_pop ; ***

    ret

;-------------------------------------------------------------------------------
;- bg_scroll_right()    returns: a = if moved 1 else 0                         -
;-------------------------------------------------------------------------------

bg_scroll_right::
    ; Check if we can move
    ld      a,[bg_x_in_tile]
    and     a,a
    jr      nz,._dont_exit ; we are already in the middle of a tile, we can move

    ; check right
    ld      a,[bg_x]
    ld      b,a
    ld      a,[bg_w]
    sub     a,20
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
    ld      a,[bg_scx]
    inc     a
    ld      [bg_scx],a

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

    ld      a,[bg_w]
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

    ld      a,[bg_map_ptr]
    ld      e,a
    ld      a,[bg_map_ptr+1]
    ld      d,a
    add     hl,de ; hl = ptr + y*width + x

    ld      a,[bg_map_bank]
    ld      b,a

    push    hl
    call    rom_bank_push_set
    pop     hl ; hl = src

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

    xor     a,a
    ld      [rVBK],a
    push    bc
    push    hl
    call    ____vram_copy_column_wrap ; b = x, c = y, hl = source address
    pop     hl
    pop     bc

    ld      a,1
    ld      [rVBK],a

    ld      a,[bg_size+0]
    ld      e,a
    ld      a,[bg_size+1]
    ld      d,a

    add     hl,de
    call    ____vram_copy_column_wrap ; b = x, c = y, hl = source address

    xor     a,a
    ld      [rVBK],a

    ; --------

    xor     a,a
    ld      [going_x],a

    call    rom_bank_pop

    ld      a,1 ; return 1
    ret

;-------------------------------------------------------------------------------
;- bg_scroll_left()    returns: a = if moved 1 else 0                          -
;-------------------------------------------------------------------------------

bg_scroll_left::
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
    ld      a,[bg_scx]
    dec     a
    ld      [bg_scx],a

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

    ld      a,[bg_w]
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

    ld      a,[bg_map_ptr]
    ld      e,a
    ld      a,[bg_map_ptr+1]
    ld      d,a
    add     hl,de ; hl = ptr + y*width + x

    ld      a,[bg_map_bank]
    ld      b,a

    push    hl
    call    rom_bank_push_set
    pop     hl ; hl = src

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

    xor     a,a
    ld      [rVBK],a
    push    bc
    push    hl
    call    ____vram_copy_column_wrap ; b = x, c = y, hl = source address
    pop     hl
    pop     bc

    ld      a,1
    ld      [rVBK],a

    ld      a,[bg_size+0]
    ld      e,a
    ld      a,[bg_size+1]
    ld      d,a

    add     hl,de
    call    ____vram_copy_column_wrap ; b = x, c = y, hl = source address

    xor     a,a
    ld      [rVBK],a

    ; --------

    xor     a,a
    ld      [going_x],a

    call    rom_bank_pop

    ld      a,1 ; return 1
    ret

;-------------------------------------------------------------------------------
;- bg_scroll_down()    returns: a = if moved 1 else 0                          -
;-------------------------------------------------------------------------------

bg_scroll_down::
    ; Check if we can move
    ld      a,[bg_y_in_tile]
    and     a,a
    jr      nz,._dont_exit ; we are already in the middle of a tile, we can move

    ; check down
    ld      a,[bg_y]
    ld      b,a
    ld      a,[bg_h]
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
    ld      a,[bg_scy]
    inc     a
    ld      [bg_scy],a

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

    ld      a,[bg_w]
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

    ld      a,[bg_map_ptr]
    ld      e,a
    ld      a,[bg_map_ptr+1]
    ld      d,a
    add     hl,de ; hl = ptr + y*width + x

    ld      a,[bg_map_bank]
    ld      b,a

    push    hl
    call    rom_bank_push_set
    pop     hl ; hl = src

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

    xor     a,a
    ld      [rVBK],a
    push    bc
    push    hl
    call    ____vram_copy_row_wrap ; b = x, c = y, hl = source address
    pop     hl
    pop     bc

    ld      a,1
    ld      [rVBK],a

    ld      a,[bg_size+0]
    ld      e,a
    ld      a,[bg_size+1]
    ld      d,a

    add     hl,de
    call    ____vram_copy_row_wrap ; b = x, c = y, hl = source address

    xor     a,a
    ld      [rVBK],a

    ; --------

    xor     a,a
    ld      [going_y],a

    call    rom_bank_pop

._end1:
    ld      a,1 ; return 1
    ret

;-------------------------------------------------------------------------------
;- bg_scroll_up()    returns: a = if moved 1 else 0                            -
;-------------------------------------------------------------------------------

bg_scroll_up::
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
    ld      a,[bg_scy]
    dec     a
    ld      [bg_scy],a

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

    ld      a,[bg_w]
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

    ld      a,[bg_map_ptr]
    ld      e,a
    ld      a,[bg_map_ptr+1]
    ld      d,a
    add     hl,de ; hl = ptr + y*width + x

    ld      a,[bg_map_bank]
    ld      b,a

    push    hl
    call    rom_bank_push_set
    pop     hl ; hl = src

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

    xor     a,a
    ld      [rVBK],a
    push    bc
    push    hl
    call    ____vram_copy_row_wrap ; b = x, c = y, hl = source address
    pop     hl
    pop     bc

    ld      a,1
    ld      [rVBK],a

    ld      a,[bg_size+0]
    ld      e,a
    ld      a,[bg_size+1]
    ld      d,a

    add     hl,de
    call    ____vram_copy_row_wrap ; b = x, c = y, hl = source address

    xor     a,a
    ld      [rVBK],a

    ; --------

    xor     a,a
    ld      [going_y],a

    call    rom_bank_pop

._end2

    ld      a,1 ; return 1
    ret

;###############################################################################

    INCLUDE "bg_handler_ex.inc"

;###############################################################################
