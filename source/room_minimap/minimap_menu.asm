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

minimap_menu_selection:  DS 1 ; selected item
minimap_menu_active:     DS 1 ; 0 if not active, 1 if active
minimap_cursor_y_offset: DS 1 ; value to add to base Y
minimap_cursor_y_offset_countdown: DS 1 ; frames to move

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

MINIMAP_MENU_NUM_TILES EQU (.e-MINIMAP_MENU_TILES)/16
MINIMAP_MENU_BASE_Y    EQU 144-16
MINIMAP_MENU_TILE_BASE EQU 128 ; Tile 128 onwards
MINIMAP_MENU_NUM_ICONS EQU (160/16)+1

MINIMAP_SPRITE_TILE_INDEX    EQU 180 ; After the menu icons
MINIMAP_SPRITE_PALETTE_INDEX EQU 0 ; Palette slot to be used by the cursor
MINIMAP_SPRITE_BASE_Y        EQU (144-16-16)+16
MINIMAP_SPRITE_OAM_INDEX     EQU 0
MINIMAP_CURSOR_COUNTDOWN_MOVEMENT EQU 20 ; frames to wait to move

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



    ; Set sprite X
    ld      a,16

    ld      l,MINIMAP_SPRITE_OAM_INDEX+0
    call    sprite_get_base_pointer ; l = sprite / return = hl / destroys de

    inc     hl
    ld      [hl+],a
    add     a,8
    inc     hl
    inc     hl
    inc     hl
    ld      [hl],a

    ret

;###############################################################################

    SECTION "Minimap Menu Code Bank 0",ROM0

;-------------------------------------------------------------------------------

MinimapMenuMandleInput:: ; If it returns 1, exit room. If 0, continue

    ld      a,[minimap_menu_active]
    and     a,a
    jr      nz,.menu_is_active

        ; Menu is inactive

        ; Exit if menu is inactive and B or START are pressed
        ld      a,[joy_pressed]
        and     a,PAD_B|PAD_START
        jr      z,.end_b_start
            ld      a,1
            ret ; return in order not to update anything
.end_b_start:

        ; Show menu if A, LEFT or RIGHT are pressed
        ld      a,[joy_pressed]
        and     a,PAD_A|PAD_LEFT|PAD_RIGHT
        ret     z ; returning 0

        call    MinimapMenuShow
        xor     a,a
        ret


.menu_is_active:

    ; Menu is active, handle

    ld      a,[joy_pressed]
    and     a,PAD_B
    jr      z,.end_b
        ; Deactivate
        call    MinimapMenuHide
        xor     a,a
        ret ; return in order not to update anything else
.end_b:

    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      z,.end_a
        ; Deactivate and load next map
        call    MinimapMenuHide
        ld      a,[minimap_menu_selection]
        call    MinimapSelectMap
        LONG_CALL   MinimapDrawSelectedMap
        xor     a,a
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

    xor     a,a
    ret

;-------------------------------------------------------------------------------

MinimapMenuShow::

    ld      a,1
    ld      [minimap_menu_active],a

    xor     a,a
    ld      [minimap_cursor_y_offset],a

    ld      a,MINIMAP_CURSOR_COUNTDOWN_MOVEMENT
    ld      [minimap_cursor_y_offset_countdown],a

    xor     a,a
    ld      [rIF],a ; clear pending interrupts

    ld      hl,rIE
    set     1,[hl] ; IEF_LCDC

    ld      b,(160-16)/2
    ld      c,MINIMAP_SPRITE_BASE_Y
    ld      l,MINIMAP_SPRITE_OAM_INDEX+0
    call    sprite_set_xy ; b = x    c = y    l = sprite number
    ld      a,MINIMAP_SPRITE_TILE_INDEX
    ld      l,MINIMAP_SPRITE_OAM_INDEX+0
    call    sprite_set_tile ; a = tile    l = sprite number
    ld      a,MINIMAP_SPRITE_PALETTE_INDEX
    ld      l,MINIMAP_SPRITE_OAM_INDEX+0
    call    sprite_set_params ; a = params    l = sprite number

    ld      b,8+((160-16)/2)
    ld      c,MINIMAP_SPRITE_BASE_Y
    ld      l,MINIMAP_SPRITE_OAM_INDEX+1
    call    sprite_set_xy ; b = x    c = y    l = sprite number
    ld      a,MINIMAP_SPRITE_TILE_INDEX+2
    ld      l,MINIMAP_SPRITE_OAM_INDEX+1
    call    sprite_set_tile ; a = tile    l = sprite number
    ld      a,MINIMAP_SPRITE_PALETTE_INDEX
    ld      l,MINIMAP_SPRITE_OAM_INDEX+1
    call    sprite_set_params ; a = params    l = sprite number

    LONG_CALL   MinimapMenuRefresh

    ret

;-------------------------------------------------------------------------------

MinimapMenuHide::

    xor     a,a
    ld      [minimap_menu_active],a

    ld      hl,rIE
    res     1,[hl] ; IEF_LCDC

    ld      bc,$0000
    ld      l,MINIMAP_SPRITE_OAM_INDEX+0
    call    sprite_set_xy ; b = x    c = y    l = sprite number
    ld      bc,$0000
    ld      l,MINIMAP_SPRITE_OAM_INDEX+1
    call    sprite_set_xy ; b = x    c = y    l = sprite number

    ret

;-------------------------------------------------------------------------------

MinimapMenuLCDHandler:: ; Only called when it is active, no need to check

    call    wait_screen_blank

    ld      a,[rLCDC]
    or      a,LCDCF_BG9C00 ; set 9C00h = menu
    ld      [rLCDC],a

    xor     a,a
    ld      [rSCX],a
    ld      a,MINIMAP_MENU_BASE_Y
    ld      [rSCY],a

    ret

;-------------------------------------------------------------------------------

MinimapMenuVBLHandler::

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ld      a,[minimap_menu_active]
    and     a,a
    ret     z

    ; It is active, handle bg base swaps

    ld      a,[rLCDC]
    and     a,(~LCDCF_BG9C00) & $FF ; set 9800h = minimap
    ld      [rLCDC],a

    ; Update sprites if needed

    ld      a,[minimap_cursor_y_offset_countdown]
    dec     a
    ld      [minimap_cursor_y_offset_countdown],a
    ret     nz

    ld      a,MINIMAP_CURSOR_COUNTDOWN_MOVEMENT
    ld      [minimap_cursor_y_offset_countdown],a

    ld      a,[minimap_cursor_y_offset]
    xor     a,1
    ld      [minimap_cursor_y_offset],a

    ld      l,MINIMAP_SPRITE_OAM_INDEX+0
    call    sprite_get_base_pointer ; l = sprite / return = hl / destroys de

    ld      a,[minimap_cursor_y_offset]
    ld      b,a ; b = increment
    ld      a,MINIMAP_SPRITE_BASE_Y
    sub     a,b

    ld      [hl+],a
    inc     hl
    inc     hl
    inc     hl
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------

MinimapMenuReset::

    xor     a,a
    ld      [minimap_menu_selection],a
    ld      [minimap_menu_active],a

    ld      bc,MinimapMenuLCDHandler
    call    irq_set_LCD

    ld      a,STATF_LYC
    ld      [rSTAT],a
    ld      a,MINIMAP_MENU_BASE_Y-1
    ld      [rLYC],a

    ret

;-------------------------------------------------------------------------------

MinimapMenuLoadGFX::

    ld      a,[rLCDC]
    or      a,LCDCF_OBJON|LCDCF_OBJ16
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

    ld      a,MINIMAP_SPRITE_PALETTE_INDEX
    call    spr_set_palette

    ei

    call    rom_bank_pop

    ret

;###############################################################################
