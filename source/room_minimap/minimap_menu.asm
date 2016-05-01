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

minimap_scroll_x:        DS 1
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
MINIMAP_MENU_NUM_ICONS_BORDER EQU ((160/16)/2)-2 ; Icons to allow to overflow

MINIMAP_SPRITE_TILE_INDEX     EQU 184 ; After the menu icons
MINIMAP_SPRITE_PALETTE_INDEX  EQU 0 ; Palette slot to be used by the cursor
MINIMAP_SPRITE_BASE_Y         EQU (144-16-16)+16
MINIMAP_SPRITE_OAM_INDEX      EQU 0
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

    ld      hl,minimap_menu_selection
    ld      a,[hl]

    cp      a,MINIMAP_MENU_NUM_ICONS_BORDER
    jr      nc,.not_left_border

        ; Left border
        sub     a,MINIMAP_MENU_NUM_ICONS_BORDER+1
        swap    a ; a *= 16

        ld      e,((160-16)/2)+8
        add     a,e
        ld      e,a

        ld      a,MINIMAP_MENU_NUM_ICONS_BORDER
        jr      .end_border_check
.not_left_border:
    cp      a,MINIMAP_SELECTION_MAX-MINIMAP_MENU_NUM_ICONS_BORDER+1
    jr      c,.not_right_border

        ; Right border
        sub     a,MINIMAP_SELECTION_MAX-MINIMAP_MENU_NUM_ICONS_BORDER
        swap    a ; a *= 16

        ld      e,((160-16)/2)+8
        add     a,e
        ld      e,a

        ld      a,MINIMAP_SELECTION_MAX-MINIMAP_MENU_NUM_ICONS_BORDER
        jr      .end_border_check
.not_right_border:

        ; Center

        ld      e,((160-16)/2)+8
        ; Preserve a from before
.end_border_check:

    add     a,a ; sla a
    add     a,a ; sla a
    add     a,a ; sla a
    add     a,a ; sla a

    sub     a,8+(16*4) ; half tile + displacement to the centre
    ld      [minimap_scroll_x],a

    ; Move sprite

    push    de ; e = sprite X

        ld      b,e

        ld      a,[minimap_cursor_y_offset]
        ld      d,a
        ld      a,MINIMAP_SPRITE_BASE_Y
        sub     a,d
        ld      c,a

        ld      l,MINIMAP_SPRITE_OAM_INDEX+0
        call    sprite_set_xy ; b = x    c = y    l = sprite number

    pop     de

        ld      a,8
        add     a,e
        ld      b,a

        ld      a,[minimap_cursor_y_offset]
        ld      d,a
        ld      a,MINIMAP_SPRITE_BASE_Y
        sub     a,d
        ld      c,a

        ld      l,MINIMAP_SPRITE_OAM_INDEX+1
        call    sprite_set_xy ; b = x    c = y    l = sprite number

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
            ret ; return 1
.end_b_start:

        ; Show menu if A, LEFT or RIGHT are pressed
        ld      a,[joy_pressed]
        and     a,PAD_A|PAD_LEFT|PAD_RIGHT
        ret     z ; return 0

        call    MinimapMenuShow
        xor     a,a
        ret ; return 0


.menu_is_active:

    ; Menu is active, handle

    ld      a,[joy_pressed]
    and     a,PAD_B
    jr      z,.end_b
        ; Deactivate
        call    MinimapMenuHide
        xor     a,a
        ret ; return 0
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
        ret ; return 0
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
    ret ; return 0

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

    ld      a,MINIMAP_SPRITE_TILE_INDEX
    ld      l,MINIMAP_SPRITE_OAM_INDEX+0
    call    sprite_set_tile ; a = tile    l = sprite number
    ld      a,MINIMAP_SPRITE_PALETTE_INDEX
    ld      l,MINIMAP_SPRITE_OAM_INDEX+0
    call    sprite_set_params ; a = params    l = sprite number

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

    ; This is a critical section, but inside an interrupt handler, so no need
    ; to use 'di' and 'ei' with WAIT_SCREEN_BLANK.

    WAIT_SCREEN_BLANK

    ld      a,[rLCDC]
    or      a,LCDCF_BG9C00 ; set 9C00h = menu
    ld      [rLCDC],a

    ld      a,[minimap_scroll_x]
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

    ld      hl,MINIMAP_MENU_PALETTES

    ld      a,0
    call    bg_set_palette_safe ; hl will increase inside
    ld      a,1
    call    bg_set_palette_safe
    ld      a,2
    call    bg_set_palette_safe
    ld      a,3
    call    bg_set_palette_safe

    ld      hl,MINIMAP_MENU_SPRITE_PALETTE

    ld      a,MINIMAP_SPRITE_PALETTE_INDEX
    call    spr_set_palette_safe

    ; End
    ; ---

    call    rom_bank_pop

    ret

;###############################################################################
