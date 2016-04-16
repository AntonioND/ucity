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

    INCLUDE "room_game.inc"

;###############################################################################

    SECTION "Room Minimap Variables",WRAM0

;-------------------------------------------------------------------------------

minimap_room_exit: DS 1 ; set to 1 to exit room

minimap_selected_map: DS 1
MINIMAP_SELECTION_RCI EQU 0

;###############################################################################

    SECTION "Room Minimap Data",ROMX

;-------------------------------------------------------------------------------

MINIMAP_PALETTES:
    DW (31<<10)|(31<<5)|(31<<0), (21<<10)|(21<<5)|(21<<0)
    DW (10<<10)|(10<<5)|(10<<0), (0<<10)|(0<<5)|(0<<0)
MINIMAP_PALETTE_NUM EQU 1

MINIMAP_BG_MAP:
    INCBIN "minimap_bg_map.bin"

MINIMAP_WIDTH  EQU 20
MINIMAP_HEIGHT EQU 18

MINIMAP_TILES:
    INCBIN "minimap_tiles.bin"
.e:

MINIMAP_TILE_NUM EQU ((.e-MINIMAP_TILES)/16)

;###############################################################################

    SECTION "Room Minimap Functions",ROMX

;-------------------------------------------------------------------------------

MinimapDrawSelectedMap:

    ld      a,[minimap_selected_map]

    cp      a,MINIMAP_SELECTION_RCI
    jr      nz,.not_rci
        LONG_CALL   MinimapDrawRCI
        jr      .end
.not_rci:


    ; Default - Clear
    call    APA_BufferClear
.end:
    call    APA_BufferUpdate

    ret

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

    call    SetPalettesAllBlack

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ld      [rLCDC],a

    ld      b,BANK(MINIMAP_TILES)
    call    rom_bank_push_set

        ; Load tiles
        ; ----------

        ld      bc,MINIMAP_TILE_NUM
        ld      de,256
        ld      hl,MINIMAP_TILES
        call    vram_copy_tiles

        ; Load map
        ; --------

        ; Tiles
        xor     a,a
        ld      [rVBK],a

        ld      de,$9800
        ld      hl,MINIMAP_BG_MAP

        ld      a,MINIMAP_HEIGHT
.loop1:
        push    af

        ld      b,MINIMAP_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-MINIMAP_WIDTH
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

        ld      a,MINIMAP_HEIGHT
.loop2:
        push    af

        ld      b,MINIMAP_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-MINIMAP_WIDTH
        add     hl,de
        ld      d,h
        ld      e,l
        pop     hl

        pop     af
        dec     a
        jr      nz,.loop2

        ; Load palettes
        ; -------------

        di
        ld      b,144
        call    wait_ly

        xor     a,a
        ld      hl,MINIMAP_PALETTES
.loop_pal:
        push    af
        call    bg_set_palette ; a = palette number - hl = pointer to data
        pop     af
        inc     a
        cp      a,MINIMAP_PALETTE_NUM
        jr      nz,.loop_pal

        ei

    call    rom_bank_pop

    ; Prepare APA buffer
    ; ------------------

    call    APA_BufferClear
    LONG_CALL   APA_ResetBackgroundMapping
    call    APA_BufferUpdate

    ld      hl,APA_PALETTE_DEFAULT
    call    APA_LoadPalette

    ret

APA_PALETTE_DEFAULT:
    DW (31<<10)|(31<<5)|(31<<0), (21<<10)|(21<<5)|(21<<0)
    DW (10<<10)|(10<<5)|(10<<0), (0<<10)|(0<<5)|(0<<0)

;-------------------------------------------------------------------------------

RoomMinimapDrawTitle:: ; hl = ptr to text string

    xor     a,a
    ld      [rVBK],a

    ; Calculate length and store in b

    push    hl

    ld      b,0
.count_loop:
    ld      a,[hl+]
    and     a,a
    jr      z,.count_end
    inc     b
    jr      .count_loop
.count_end:

    pop     hl

    ; Calculate starting point of text string

    ld      a,20 ; Screen tile width
    sub     a,b
    sra     a ; a = (20-length)/2

    push    hl

    ld      l,a
    ld      h,0
    ld      de,$9800
    add     hl,de
    LD_DE_HL

    pop     hl

    ; Draw

.loop:
    ld      a,[hl+]
    and     a,a
    ret     z ; return from function from here!

    ld      b,a
    WAIT_SCREEN_BLANK ; Clobbers A and C
    ld      a,b

    ld      [de],a
    inc     de

    jr      .loop

;-------------------------------------------------------------------------------

RoomMinimap::

    ld      bc,RoomMinimapVBLHandler
    call    irq_set_VBL

    ld      b,1 ; bank at 8800h
    call    LoadText

    call    RoomMinimapLoadBG

    di

    ld      b,144
    call    wait_ly
    call    LoadTextPalette

    ei

    ld      a,MINIMAP_SELECTION_RCI
    ld      [minimap_selected_map],a
    LONG_CALL   MinimapDrawSelectedMap

    xor     a,a
    ld      [minimap_room_exit],a

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleMinimap

    ld      a,[minimap_room_exit]
    and     a,a
    jr      z,.loop

    call    SetDefaultVBLHandler

    ret

;###############################################################################
