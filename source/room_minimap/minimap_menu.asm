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
    INCLUDE "room_minimap.inc"

;###############################################################################

    SECTION "Minimap Menu Variables",WRAM0

;-------------------------------------------------------------------------------

minimap_menu_selection: DS 1 ; selected item
minimap_menu_active: DS 1 ; 0 if not active, 1 if active

;###############################################################################

    SECTION "Minimap Menu Data Functions",ROMX

;-------------------------------------------------------------------------------

MINIMAP_MENU_MAP:
    INCBIN "minimap_menu_map.bin"

MINIMAP_MENU_WIDTH  EQU 32
MINIMAP_MENU_HEIGHT EQU 2

MINIMAP_MENU_TILES:
    INCBIN "minimap_menu_tiles.bin"
.e:

MINIMAP_MENU_NUM_TILES EQU ((.e-MINIMAP_MENU_TILES)/16)

MINIMAP_MENU_BASE_Y EQU (144-16)

MINIMAP_MENU_TILE_BASE EQU (128) ; Tile 128 onwards

MINIMAP_MENU_NUM_ICONS EQU ((160/16)+1)

;-------------------------------------------------------------------------------

WHITE EQU (31<<10)|(31<<5)|(31<<0)
BLACK EQU (0<<10)|(0<<5)|(0<<0)

MINIMAP_MENU_PALETTES:
    DW WHITE, (21<<10)|(21<<5)|(21<<0), (10<<10)|(10<<5)|(10<<0), BLACK
    DW WHITE, (0<<10)|(31<<5)|(31<<0), (0<<10)|(0<<5)|(31<<0), BLACK
    DW WHITE, (0<<10)|(31<<5)|(0<<0), (31<<10)|(0<<5)|(0<<0), BLACK
    DW WHITE, (0<<10)|(15<<5)|(0<<0), (0<<10)|(8<<5)|(15<<0), BLACK

MINIMAP_MENU_SPRITE_PALETTE:
    DW 0, WHITE, (0<<10)|(31<<5)|(31<<0), BLACK

;-------------------------------------------------------------------------------

MinimapMenuRefresh::

    ret

;###############################################################################

    SECTION "Minimap Menu Code Bank 0",ROM0

;-------------------------------------------------------------------------------

MinimapMenuMandleInput::

    ld      a,[minimap_menu_active]
    and     a,a
    jr      nz,.menu_is_active

        ; Menu is inactive, activate it

        ld      a,[joy_pressed]
        and     a,PAD_A|PAD_LEFT|PAD_RIGHT
        ret     z

        call    MinimapMenuShow
        ret


.menu_is_active:

    ; Menu is active, handle

    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      z,.end_a

        ; Deactivate and load next map
        call    MinimapMenuHide
        ld      a,[minimap_menu_selection]
        call    MinimapSelectMap
        LONG_CALL   MinimapDrawSelectedMap
        ret ; return in order not to update anything else

.end_a:

    ld      a,[joy_pressed]
    and     a,PAD_LEFT
    jr      z,.end_left
        ld      a,[minimap_menu_selection]
        and     a,a
        jr      z,.end_left
            dec     a
            ld      [minimap_menu_selection],a
            LONG_CALL   MinimapMenuRefresh
.end_left:

    ld      a,[joy_pressed]
    and     a,PAD_RIGHT
    jr      z,.end_right
        ld      a,[minimap_menu_selection]
        cp      a,MINIMAP_SELECTION_MAX
        jr      z,.end_right
            inc     a
            ld      [minimap_menu_selection],a
            LONG_CALL   MinimapMenuRefresh
.end_right:

    ret

;-------------------------------------------------------------------------------

MinimapMenuShow::

    ld      a,1
    ld      [minimap_menu_active],a

    LONG_CALL   MinimapMenuRefresh

    ld      a,7
    ld      [rWX],a
    ld      a,MINIMAP_MENU_BASE_Y
    ld      [rWY],a ; show window

    ret

;-------------------------------------------------------------------------------

MinimapMenuHide::

    xor     a,a
    ld      [minimap_menu_active],a

    ld      a,7
    ld      [rWX],a
    ld      a,144
    ld      [rWY],a ; hide window

    ret

;-------------------------------------------------------------------------------

MinimapMenuResetLoadGFX::

    ; Reset
    ; -----

    xor     a,a
    ld      [minimap_menu_selection],a

    ; Set interrupt handler
    ; ---------------------

    ld      a,[rLCDC]
    or      a,LCDCF_WINON|LCDCF_WIN9C00
    ld      [rLCDC],a

    call    MinimapMenuHide

    ; Load graphics
    ; -------------

    ld      b,BANK(MINIMAP_MENU_MAP)
    call    rom_bank_push_set

    ; Tile map
    ; --------

    xor     a,a
    ld      [rVBK],a

    ld      hl,MINIMAP_MENU_MAP

    ld      de,$9C00
    ld      b,MINIMAP_MENU_WIDTH*MINIMAP_MENU_HEIGHT
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    ; Attributes

    ld      a,1
    ld      [rVBK],a

    ld      de,$9C00
    ld      b,MINIMAP_MENU_WIDTH*MINIMAP_MENU_HEIGHT
    call    vram_copy_fast ; b = size - hl = source address - de = dest


    ; Load tiles
    ; ----------

    xor     a,a
    ld      [rVBK],a

    ld      bc,MINIMAP_MENU_NUM_TILES
    ld      de,MINIMAP_MENU_TILE_BASE
    ld      hl,MINIMAP_MENU_TILES
    call    vram_copy_tiles

    ; Load palettes
    ; -------------

    ; Wait until VBL
    di

    ld      b,144
    call    wait_ly

    ld      hl,MINIMAP_MENU_PALETTES

    ld      a,0
    call    bg_set_palette ; hl will increase inside
    ld      a,1
    call    bg_set_palette
    ld      a,2
    call    bg_set_palette
    ld      a,3
    call    bg_set_palette

    ld      hl,MINIMAP_MENU_SPRITE_PALETTE

    ld      a,0
    call    spr_set_palette

    ei

    call    rom_bank_pop

    ret

;###############################################################################
