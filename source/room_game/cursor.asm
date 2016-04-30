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

    INCLUDE "text.inc"

;###############################################################################

    SECTION "Cursor Variables",WRAM0

;-------------------------------------------------------------------------------

CursorFrame:        DS  1
CursorAnimCount:    DS  1 ; Starts at 10, at 0 it updates
CursorNeedsRefresh: DS  1

CursorTileX::       DS  1 ; Coordinates relative to the screen (in tiles)
CursorTileY::       DS  1
CursorX::           DS  1 ; Coordinates relative to the screen (in pixels)
CursorY::           DS  1
CursorSizeX::       DS  1 ; Size in tiles
CursorSizeY::       DS  1

CURSOR_ANIMATION_TICKS  EQU 10

;###############################################################################

    SECTION "Cursor Data",ROM0

;-------------------------------------------------------------------------------

CursorTilesData:
    INCBIN  "data/cursor_tiles.bin"

CursorTilesNumber  EQU 1
CURSOR_CORNER_TILE    EQU O_CURSOR

CURSOR_SPR_PAL     EQU 0
CURSOR_OAM_BASE    EQU 0

;-------------------------------------------------------------------------------
; Don't modify any constant of this group!

BOARD_COLUMNS   EQU 20
BOARD_ROWS      EQU 18

cursor_palette:
    DW  $0000,$7FFF,$3DEF,$0000

CursorLoad::

    ; Load palette

    ld      a,CURSOR_SPR_PAL
    ld      hl,cursor_palette
    call    spr_set_palette_safe

    ; Load tiles - Not needed, loaded with text tiles

;    xor     a,a
;    ld      [rVBK],a

;    ld      bc,CursorTilesNumber
;    ld      de,CURSOR_CORNER_TILE
;    ld      hl,CursorTilesData
;    call    vram_copy_tiles

    call    CursorMoveToOrigin

    ld      a,10
    ld      [CursorAnimCount],a
    ld      a,0
    ld      [CursorFrame],a

    ld      a,1
    ld      [CursorSizeX],a
    ld      [CursorSizeY],a

;    ld      a,1
;    ld      [CursorNeedsRefresh],a

    call    CursorHide

    ret

;-------------------------------------------------------------------------------

CursorRefreshCoordFromTile:

    ld      a,[CursorTileX]
    sla     a
    sla     a
    sla     a ; X * 8
    add     a,4
    ld      [CursorX],a

    ld      a,[CursorTileY]
    sla     a
    sla     a
    sla     a ; Y * 8
    add     a,12
    ld      [CursorY],a

    ret

;-------------------------------------------------------------------------------

CursorMoveToOrigin::

    ld      a,(BOARD_COLUMNS-1) / 2
    ld      [CursorTileX],a
    ld      a,(BOARD_ROWS-1) / 2
    ld      [CursorTileY],a

    call    CursorRefreshCoordFromTile

    ret

;-------------------------------------------------------------------------------

CursorHide::

    ld      l,CURSOR_OAM_BASE
    call    sprite_get_base_pointer ; hl = dst

    ld      bc,4*4 ; 4 sprites used for cursor
    ld      d,0
    call    memset

    ret

CursorShow::
    ld      a,1
    ld      [CursorNeedsRefresh],a
    call    CursorRefresh
    ret

;-------------------------------------------------------------------------------

CursorRefresh::

    ld      a,[CursorNeedsRefresh]
    and     a,a
    ret     z ; need to update?

    xor     a,a
    ld      [CursorNeedsRefresh],a ; flag as updated

    call    CursorRefreshCoordFromTile

    ; Top Left
        ld      hl,CursorFrame

        ld      a,[CursorX]
        sub     a,[hl]
        ld      b,a

        ld      a,[CursorY]
        sub     a,[hl]
        ld      c,a

        ld      l,CURSOR_OAM_BASE+0
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_CORNER_TILE
        ld      [hl+],a ; Tile
        ld      a,CURSOR_SPR_PAL
        ld      [hl+],a ; Params

    ; Down Left
        ld      hl,CursorFrame

        ld      a,[CursorX]
        sub     a,[hl]
        ld      b,a

        ld      a,[CursorY]
        add     a,[hl]
        ld      d,a
        ld      a,[CursorSizeY]
        sla     a
        sla     a
        sla     a ; * 8
        add     a,d
        ld      c,a

        ld      l,CURSOR_OAM_BASE+1
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_CORNER_TILE
        ld      [hl+],a ; Tile
        ld      a,CURSOR_SPR_PAL|OAMF_YFLIP
        ld      [hl+],a ; Params

    ; Top Right
        ld      hl,CursorFrame

        ld      a,[CursorX]
        add     a,[hl]
        ld      d,a
        ld      a,[CursorSizeX]
        sla     a
        sla     a
        sla     a ; * 8
        add     a,d
        ld      c,a
        ld      b,a

        ld      a,[CursorY]
        sub     a,[hl]
        ld      c,a

        ld      l,CURSOR_OAM_BASE+2
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_CORNER_TILE
        ld      [hl+],a ; Tile
        ld      a,CURSOR_SPR_PAL|OAMF_XFLIP
        ld      [hl+],a ; Params

    ; Down Left
        ld      hl,CursorFrame

        ld      a,[CursorX]
        add     a,[hl]
        ld      d,a
        ld      a,[CursorSizeX]
        sla     a
        sla     a
        sla     a ; * 8
        add     a,d
        ld      c,a
        ld      b,a

        ld      a,[CursorY]
        add     a,[hl]
        ld      d,a
        ld      a,[CursorSizeY]
        sla     a
        sla     a
        sla     a ; * 8
        add     a,d
        ld      c,a

        ld      l,CURSOR_OAM_BASE+3
        call    sprite_get_base_pointer ; destroys de
        ld      [hl],c ; Y
        inc     hl
        ld      [hl],b ; X
        inc     hl
        ld      a,CURSOR_CORNER_TILE
        ld      [hl+],a ; Tile
        ld      a,CURSOR_SPR_PAL|OAMF_XFLIP|OAMF_YFLIP
        ld      [hl+],a ; Params

    ret

;-------------------------------------------------------------------------------

CursorAnimate:

    ld      hl,CursorAnimCount
    ld      a,[hl]
    dec     a
    ld      [hl],a
    ret     nz

    ld      a,CURSOR_ANIMATION_TICKS
    ld      [hl],a

    ld      a,[CursorFrame]
    xor     a,1
    ld      [CursorFrame],a

    ld      a,1
    ld      [CursorNeedsRefresh],a

    ret

;-------------------------------------------------------------------------------

CursorMovePAD_hor: ; returns PAD_RIGHT and similar flags ORed if it has moved

    ld      e,0 ; set flags here

    ; Move

    ld      hl,CursorTileX
    ld      a,[joy_pressed]
    and     a,PAD_LEFT
    jr      z,.left_end
    ld      a,[hl]
    and     a,a
    jr      z,.left_end
        dec     [hl]
        ld      a,1
        ld      [CursorNeedsRefresh],a
        ld      e,PAD_LEFT
.left_end:

    ld      hl,CursorTileX
    ld      a,[joy_pressed]
    and     a,PAD_RIGHT
    jr      z,.right_end
    ld      b,[hl]
    ld      a,[CursorSizeX]
    add     a,b
    cp      a,BOARD_COLUMNS
    jr      z,.right_end
        inc     [hl]
        ld      a,1
        ld      [CursorNeedsRefresh],a
        ld      a,e
        or      a,PAD_RIGHT
        ld      e,a
.right_end:

    ld      a,e ; return flags if moved

    ret

CursorMovePAD_ver: ; returns PAD_RIGHT and similar flags ORed if it has moved

    ld      e,0 ; set flags here

    ; Move

    ld      hl,CursorTileY
    ld      a,[joy_pressed]
    and     a,PAD_UP
    jr      z,.up_end
    ld      a,[hl]
    and     a,a
    jr      z,.up_end
        dec     [hl]
        ld      a,1
        ld      [CursorNeedsRefresh],a
        ld      e,PAD_UP
.up_end:

    ld      hl,CursorTileY
    ld      a,[joy_pressed]
    and     a,PAD_DOWN
    jr      z,.down_end
    ld      b,[hl]
    ld      a,[CursorSizeY]
    add     a,b
    cp      a,BOARD_ROWS
    jr      z,.down_end
        inc     [hl]
        ld      a,1
        ld      [CursorNeedsRefresh],a
        ld      a,e
        or      a,PAD_DOWN
        ld      e,a
.down_end:

    ld      a,e ; return flags if moved

    ret

;-------------------------------------------------------------------------------

CursorSetSize:: ; b = width, c = height

    ld      a,b
    ld      [CursorSizeX],a

    ld      a,c
    ld      [CursorSizeY],a

    ld      a,1
    ld      [CursorNeedsRefresh],a

    ret

;-------------------------------------------------------------------------------

CursorCheckDragBg_hor:

    cpl     ; a = ~moved
    ld      b,a ; b = ~moved
    ld      a,[joy_pressed]
    and     a,b ; a = want_to_move & ~moved

        bit     PAD_BIT_RIGHT,a
        jr      z,.not_right
        push    af
        REPT    2
        call    bg_main_scroll_right
        ENDR
        pop     af
.not_right:

        bit     PAD_BIT_LEFT,a
        jr      z,.not_left
        push    af
        REPT    2
        call    bg_main_scroll_left
        ENDR
        pop     af
.not_left:

    ret

CursorCheckDragBg_ver:

    cpl     ; a = ~moved
    ld      b,a ; b = ~moved
    ld      a,[joy_pressed]
    and     a,b ; a = want_to_move & ~moved

        bit     PAD_BIT_UP,a
        jr      z,.not_up
        push    af
        REPT    2
        call    bg_main_scroll_up
        ENDR
        pop     af
.not_up:

        bit     PAD_BIT_DOWN,a
        jr      z,.not_down
        push    af
        REPT    2
        call    bg_main_scroll_down
        ENDR
        pop     af
.not_down:

    ret

;-------------------------------------------------------------------------------

CursorHandle::

    call    bg_main_drift_scroll_hor ; If in the middle of a movement, wait
    and     a,a
    jr      nz,.skip_movement_hor
        call    CursorMovePAD_hor
        call    CursorCheckDragBg_hor
.skip_movement_hor:

    call    bg_main_drift_scroll_ver
    and     a,a
    jr      nz,.skip_movement_ver
        call    CursorMovePAD_ver
        call    CursorCheckDragBg_ver
.skip_movement_ver:

    call    CursorAnimate
    call    CursorRefresh

    ret

;-------------------------------------------------------------------------------

CursorHiddenMove::

    ; Horizontal

    call    bg_main_drift_scroll_hor ; If in the middle of a movement, wait
    and     a,a
    jr      nz,.skip_movement_hor

        ld      a,[joy_held]

        bit     PAD_BIT_RIGHT,a
        jr      z,.not_right
            push    af
            REPT    2
            call    bg_main_scroll_right
            ENDR
            pop     af
.not_right:

        bit     PAD_BIT_LEFT,a
        jr      z,.not_left
            push    af
            REPT    2
            call    bg_main_scroll_left
            ENDR
            pop     af
.not_left:

.skip_movement_hor:

    ; Vertical

    call    bg_main_drift_scroll_ver ; If in the middle of a movement, wait
    and     a,a
    jr      nz,.skip_movement_ver

        ld      a,[joy_held]

        bit     PAD_BIT_UP,a
        jr      z,.not_up
            push    af
            REPT    2
            call    bg_main_scroll_up
            ENDR
            pop     af
.not_up:

        bit     PAD_BIT_DOWN,a
        jr      z,.not_down
            push    af
            REPT    2
            call    bg_main_scroll_down
            ENDR
            pop     af
.not_down:

.skip_movement_ver:

    ret

;-------------------------------------------------------------------------------

CursorGetGlobalCoords:: ; returns x in e, y in d

    ld      a,[CursorTileX]
    ld      b,a
    ld      a,[bg_x]
    add     a,b
    ld      e,a

    ld      a,[CursorTileY]
    ld      b,a
    ld      a,[bg_y]
    add     a,b
    ld      d,a

    ret

;###############################################################################
