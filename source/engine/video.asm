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
;#                                                                             #
;#                                VIDEO GENERAL                                #
;#                                                                             #
;###############################################################################

    SECTION "Video_General",ROM0

;-------------------------------------------------------------------------------
;- wait_ly()    b = ly to wait for                                             -
;-------------------------------------------------------------------------------

wait_ly::

    ld      c,rLY & $FF

.loop:
    ld      a,[$FF00+c]
    cp      a,b
    ret     z
    jr      .loop

;-------------------------------------------------------------------------------
;- wait_frames()    e = frames to wait                                         -
;-------------------------------------------------------------------------------

wait_frames::

    call    wait_vbl
    dec     e
    jr      nz,wait_frames

    ret

;-------------------------------------------------------------------------------
;- screen_off()                                                                -
;-------------------------------------------------------------------------------

screen_off::

    ldh     a,[rLCDC]
    and     a,LCDCF_ON
    ret     z ; LCD already OFF

    di ; Entering critical section

    ld      b,$91
    call    wait_ly

    xor     a,a
    ldh     [rLCDC],a ;Shutdown LCD

    reti ; End of critical section

;-------------------------------------------------------------------------------
;- vram_nitro_copy()    b = size    de = source address    hl = dest address   -
;-------------------------------------------------------------------------------

vram_nitro_copy:: ; use only for data != $FF

.loop:
    ld      a,[de]
    inc     de
.repeat:
    ld      [hl],a ; force write
    cp      a,[hl] ; verify that it was writen
    jr      nz,.repeat ; repeat if not
    inc     hl
    dec     b
    jr      nz,.loop

    ret

;-------------------------------------------------------------------------------
;- vram_copy_fast()    b = size    hl = source address    de = dest address    -
;-------------------------------------------------------------------------------

vram_copy_fast::

    ld      c,rSTAT & $FF

.loop:
    ld      a,[$FF00+c]
    bit     1,a
    jr      nz,.loop ; Not mode 0 or 1

    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.loop

    ret

;-------------------------------------------------------------------------------
;- vram_copy()    bc = size    hl = source address    de = dest address        -
;-------------------------------------------------------------------------------

vram_copy::

    ldh     a,[rSTAT]
    bit     1,a
    jr      nz,vram_copy ; Not mode 0 or 1

    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     bc
    ld      a,b
    or      a,c
    jr      nz,vram_copy

    ret

;-------------------------------------------------------------------------------
;- vram_memset()    bc = size    d = value    hl = dest address                -
;-------------------------------------------------------------------------------

vram_memset::

    ldh     a,[rSTAT]
    bit     1,a
    jr      nz,vram_memset ; Not mode 0 or 1

    ld      [hl],d
    inc     hl
    dec     bc
    ld      a,b
    or      a,c
    jr      nz,vram_memset

    ret

;-------------------------------------------------------------------------------
;- vram_copy_tiles()    bc = tiles    de = start index    hl = source          -
;-------------------------------------------------------------------------------

vram_copy_tiles::

    push    hl

    ld      h,d
    ld      l,e
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl ; index * 16
    ld      de,$8000
    add     hl,de ; dest + base
    ld      d,h
    ld      e,l

    pop     hl

    ; de = dest
    ; hl = src

.copy_tile:

    REPT    16
.vram_wait\@:
        ldh     a,[rSTAT]
        bit     1,a
        jr      nz,.vram_wait\@ ; Not mode 0 or 1
        ld      a,[hl+]
        ld      [de],a
        inc     de
    ENDR

    dec     bc
    ld      a,b
    or      a,c
    jp      nz,.copy_tile

    ret

;###############################################################################
;#                                                                             #
;#                                   SPRITES                                   #
;#                                                                             #
;###############################################################################

    SECTION "OAMCopy",WRAM0,ALIGN[8]

;-------------------------------------------------------------------------------

OAM_Copy: DS $A0 ; DMA will be used to copy this to OAM

;###############################################################################

    SECTION "Video_Sprites",ROM0

;-------------------------------------------------------------------------------
;- sprite_get_base_pointer()    l = sprite    return = hl    destroys de       -
;-------------------------------------------------------------------------------

sprite_get_base_pointer::
    ld      h,$00
    add     hl,hl
    add     hl,hl ; spr number *= 4
    ld      de,OAM_Copy
    add     hl,de

    ret

;-------------------------------------------------------------------------------
;- sprite_set_xy()    b = x    c = y    l = sprite number                      -
;-------------------------------------------------------------------------------

sprite_set_xy::

    call    sprite_get_base_pointer

    ld      [hl],c
    inc     hl
    ld      [hl],b

    ret

;-------------------------------------------------------------------------------
;- sprite_set_tile()    a = tile    l = sprite number                          -
;-------------------------------------------------------------------------------

sprite_set_tile::

    call    sprite_get_base_pointer
    inc     hl
    inc     hl
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------
;- sprite_set_params()    a = params    l = sprite number                      -
;-------------------------------------------------------------------------------

sprite_set_params::

    call    sprite_get_base_pointer
    inc     hl
    inc     hl
    inc     hl
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------
;- spr_set_palette()    a = palette number    hl = pointer to data             -
;-------------------------------------------------------------------------------

spr_set_palette::

    swap    a
    rra ; multiply palette by 8
    set     7,a ; auto increment
    ldh     [rOCPS],a

    REPT 8
        ld      a,[hl+]
        ldh     [rOCPD],a
    ENDR

    ret

;-------------------------------------------------------------------------------
;- spr_set_palette_safe()    a = palette number    hl = pointer to data        -
;-------------------------------------------------------------------------------

spr_set_palette_safe::

    swap    a ; \  multiply
    rrca      ; /  palette by 8

    set     7,a ; auto increment
    ldh     [rOCPS],a

    ld      b,8
.loop:

    di ; Entering critical section
    WAIT_SCREEN_BLANK
    ld      a,[hl+]
    ldh     [rOCPD],a
    ei ; End of critical section

    dec b
    jr  nz,.loop

    ret

;-------------------------------------------------------------------------------
;- init_OAM()                                                                  -
;-------------------------------------------------------------------------------

init_OAM::

    ld      b,__refresh_OAM_end - __refresh_OAM
    ld      hl,__refresh_OAM
    ld      de,refresh_OAM_HRAM
    call    memcopy_fast

    ret

__refresh_OAM:

    ldh     [rDMA],a
    ld      a,$28      ;delay 200ms
.delay:
    dec     a
    jr      nz,.delay

    ret

__refresh_OAM_end:

;-------------------------------------------------------------------------------
;- refresh_OAM()                                                               -
;-------------------------------------------------------------------------------

refresh_OAM::

    ld      a,OAM_Copy >> 8
    jp      refresh_OAM_HRAM

;-------------------------------------------------------------------------------
;- refresh_custom_OAM()                                                        -
;-------------------------------------------------------------------------------

refresh_custom_OAM::
    jp      refresh_OAM_HRAM

;###############################################################################

    SECTION "OAMRefreshFn",HRAM[$FF80]

;-------------------------------------------------------------------------------

refresh_OAM_HRAM: DS (__refresh_OAM_end - __refresh_OAM)

;###############################################################################
;#                                                                             #
;#                                  BACKGROUND                                 #
;#                                                                             #
;###############################################################################

    SECTION "Video_Background",ROM0

;-------------------------------------------------------------------------------
;- bg_set_palette()    a = palette number    hl = pointer to data              -
;-------------------------------------------------------------------------------

bg_set_palette::

    swap    a ; \  multiply
    rrca      ; /  palette by 8

    set     7,a ; auto increment
    ldh     [rBCPS],a

    REPT 8
        ld      a,[hl+]
        ldh     [rBCPD],a
    ENDR

    ret

;-------------------------------------------------------------------------------
;- bg_set_palette_safe()    a = palette number    hl = pointer to data         -
;-------------------------------------------------------------------------------

bg_set_palette_safe::

    swap    a ; \  multiply
    rrca      ; /  palette by 8

    set     7,a ; auto increment
    ldh     [rBCPS],a

    ld      b,8
.loop:

    di ; Entering critical section
    WAIT_SCREEN_BLANK
    ld      a,[hl+]
    ldh     [rBCPD],a
    ei ; End of critical section

    dec b
    jr  nz,.loop

    ret

;-------------------------------------------------------------------------------
;- bg_set_tile_wrap()    b = x    c = y    a = tile index                      -
;-------------------------------------------------------------------------------

bg_set_tile_wrap::

    ld      l,a

    ld      h,31

    ld      a,b
    and     a,h
    ld      b,a

    ld      a,c
    and     a,h
    ld      c,a

    ld      a,l

    ; Fall through

;-------------------------------------------------------------------------------
;- bg_set_tile()    b = x    c = y    a = tile index                           -
;-------------------------------------------------------------------------------

bg_set_tile::

;    ld      de,$9800
    ld      d,$98
    ld      e,b ; de = base + x

    ld      l,c
    ld      h,$00 ; hl = y

    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl ; y *  32

    add     hl,de ; hl = base + x + (y * 32)

    ld      [hl],a

    ret

;###############################################################################
