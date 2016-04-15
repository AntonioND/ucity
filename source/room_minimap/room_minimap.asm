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

drawing_color: DS 4

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

MinimapDrawRCI::

    LONG_CALL   APA_PixelStreamStart

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)

            LONG_CALL_ARGS  CityMapGetType ; Arguments: e = x , d = y

            ; Set color from tile type

            ; Flags have priority over type. Also, road > train > power

            bit     TYPE_HAS_ROAD_BIT,a
            jr      z,.not_road
                ld      a,3
                ld      b,3
                ld      c,3
                ld      d,3
                jr      .end_compare
.not_road:
            bit     TYPE_HAS_TRAIN_BIT,a
            jr      z,.not_train
                ld      a,0
                ld      b,3
                ld      c,3
                ld      d,0
                jr      .end_compare
.not_train:
            bit     TYPE_HAS_POWER_BIT,a
            jr      z,.not_power
                ld      a,0
                ld      b,2
                ld      c,2
                ld      d,0
                jr      .end_compare
.not_power:

            and     a,TYPE_MASK ; Get type without extra flags

            cp      a,TYPE_RESIDENTIAL
            jr      nz,.not_residential
                ld      a,2
                ld      b,1
                ld      c,1
                ld      d,2
                jr      .end_compare
.not_residential:
            cp      a,TYPE_INDUSTRIAL
            jr      nz,.not_industrial
                ld      a,2
                ld      b,2
                ld      c,2
                ld      d,2
                jr      .end_compare
.not_industrial:
            cp      a,TYPE_COMMERCIAL
            jr      nz,.not_commercial
                ld      a,1
                ld      b,1
                ld      c,1
                ld      d,1
                jr      .end_compare
.not_commercial:
            cp      a,TYPE_WATER
            jr      nz,.not_water
                ld      a,0
                ld      b,1
                ld      c,1
                ld      d,0
                jr      .end_compare
.not_water:
            cp      a,TYPE_DOCK
            jr      nz,.not_dock
                ld      a,0
                ld      b,1
                ld      c,1
                ld      d,0
                jr      .end_compare
.not_dock:
            ; Default
            xor     a,a
            ld      b,a
            ld      c,a
            ld      d,a
.end_compare:

            call    APA_SetColors ; a,b,c,d = color (0 to 3)
            LONG_CALL   APA_PixelStreamPlot2x2

        pop     de ; (*)

        inc     e
        bit     6,e
        jp      z,.loopx

    inc     d
    bit     6,d
    jp      z,.loopy

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

APA_PALETTE: ; To be loaded in slot APA_PALETTE_INDEX
    DW (31<<10)|(31<<5)|(31<<0), (31<<10)|(0<<5)|(0<<0)
    DW (0<<10)|(31<<5)|(31<<0), (0<<10)|(0<<5)|(0<<0)

    DW (31<<10)|(31<<5)|(31<<0), (21<<10)|(21<<5)|(21<<0)
    DW (10<<10)|(10<<5)|(10<<0), (0<<10)|(0<<5)|(0<<0)

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

    di
    ld      b,144
    call    wait_ly

    ld      hl,APA_PALETTE
    call   APA_LoadPalette
    ei

    ret

;-------------------------------------------------------------------------------

RoomMinimap::

    ld      bc,RoomMinimapVBLHandler
    call    irq_set_VBL

    call    RoomMinimapLoadBG

    call    LoadText
    ld      b,144
    call    wait_ly
    call    LoadTextPalette

    LONG_CALL   MinimapDrawRCI
    call    APA_BufferUpdate

    ld      hl,rIE
    set     0,[hl] ; IEF_VBLANK

    xor     a,a
    ld      [rIF],a

    ei

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

    ret

;###############################################################################
