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
CursorSizeX::       DS  1 ; Size in pixels
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

    ld      a,8
    ld      [CursorSizeX],a
    ld      [CursorSizeY],a

;    ld      a,1
;    ld      [CursorNeedsRefresh],a

    call    CursorHide

    ret

;-------------------------------------------------------------------------------

CursorRefreshCoordFromTile:

    ld      a,[CursorTileX]
    add     a,a
    add     a,a
    add     a,a ; X * 8
    add     a,4
    ld      [CursorX],a

    ld      a,[CursorTileY]
    add     a,a
    add     a,a
    add     a,a ; Y * 8
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
        add     a,d
        ld      c,a
        ld      b,a

        ld      a,[CursorY]
        add     a,[hl]
        ld      d,a
        ld      a,[CursorSizeY]
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

CursorAnimate::

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
        call    CursorRefreshCoordFromTile
        ld      e,PAD_LEFT
.left_end:

    ld      hl,CursorTileX
    ld      a,[joy_pressed]
    and     a,PAD_RIGHT
    jr      z,.right_end
    ld      b,[hl]
    ld      a,[CursorSizeX]
    sra     a
    sra     a
    sra     a ; to tiles
    add     a,b
    cp      a,BOARD_COLUMNS
    jr      z,.right_end
        inc     [hl]
        ld      a,1
        ld      [CursorNeedsRefresh],a
        call    CursorRefreshCoordFromTile
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
        call    CursorRefreshCoordFromTile
        ld      e,PAD_UP
.up_end:

    ld      hl,CursorTileY
    ld      a,[joy_pressed]
    and     a,PAD_DOWN
    jr      z,.down_end
    ld      b,[hl]
    ld      a,[CursorSizeY]
    sra     a
    sra     a
    sra     a ; to tiles
    add     a,b
    cp      a,BOARD_ROWS
    jr      z,.down_end
        inc     [hl]
        ld      a,1
        ld      [CursorNeedsRefresh],a
        call    CursorRefreshCoordFromTile
        ld      a,e
        or      a,PAD_DOWN
        ld      e,a
.down_end:

    ld      a,e ; return flags if moved

    ret

;-------------------------------------------------------------------------------

CursorSetCoordinates:: ; e = x, d = y, in pixels

    ld      a,e
    ld      [CursorX],a

    ld      a,d
    ld      [CursorY],a

    ret

;-------------------------------------------------------------------------------

CursorSetSizeTiles:: ; b = width, c = height, in tiles

    sla     b
    sla     b
    sla     b

    sla     c
    sla     c
    sla     c

CursorSetSize:: ; b = width, c = height, in pixels

    ld      a,b
    ld      [CursorSizeX],a

    ld      a,c
    ld      [CursorSizeY],a

    ld      a,1
    ld      [CursorNeedsRefresh],a

    ret

;-------------------------------------------------------------------------------

; Returns a = 1 if bg has scrolled, 0 otherwise
CursorCheckDragBg_hor:

    cpl     ; a = ~moved
    ld      b,a ; b = ~moved
    ld      a,[joy_pressed]
    and     a,b ; a = want_to_move & ~moved

        bit     PAD_BIT_RIGHT,a
        jr      z,.not_right

        call    bg_main_scroll_right
        ld      b,a
        push    bc
        call    bg_main_scroll_right
        pop     bc
        or      a,b

        ret

.not_right:

        bit     PAD_BIT_LEFT,a
        jr      z,.not_left

        call    bg_main_scroll_left
        ld      b,a
        push    bc
        call    bg_main_scroll_left
        pop     bc
        or      a,b

        ret

.not_left:

    xor     a,a
    ret

; Returns a = 1 if bg has scrolled, 0 otherwise
CursorCheckDragBg_ver:

    cpl     ; a = ~moved
    ld      b,a ; b = ~moved
    ld      a,[joy_pressed]
    and     a,b ; a = want_to_move & ~moved

        bit     PAD_BIT_UP,a
        jr      z,.not_up

        call    bg_main_scroll_up
        ld      b,a
        push    bc
        call    bg_main_scroll_up
        pop     bc
        or      a,b

        ret

.not_up:

        bit     PAD_BIT_DOWN,a
        jr      z,.not_down

        call    bg_main_scroll_down
        ld      b,a
        push    bc
        call    bg_main_scroll_down
        pop     bc
        or      a,b

        ret

.not_down:

    xor     a,a
    ret

;-------------------------------------------------------------------------------

; Returns a = 1 if bg has scrolled, 0 otherwise
CursorHandle::

    call    bg_main_drift_scroll_hor ; If in the middle of a movement, wait
    ld      b,0 ; has scrolled = 0
    and     a,a
    jr      nz,.skip_movement_hor
        call    CursorMovePAD_hor
        call    CursorCheckDragBg_hor
        ld      b,a
.skip_movement_hor:

    push    bc
    call    bg_main_drift_scroll_ver
    pop     bc
    and     a,a
    jr      nz,.skip_movement_ver
        push    bc
        call    CursorMovePAD_ver
        call    CursorCheckDragBg_ver
        pop     bc
        or      a,b
        ld      b,a
.skip_movement_ver:

    push    bc ; (*)
    call    CursorAnimate
    call    CursorRefresh
    pop     af ; (*) load bc into af ( ld b,a )

    ret

;-------------------------------------------------------------------------------

CursorDrift::

    call    bg_main_drift_scroll_hor
    call    bg_main_drift_scroll_ver

    ret

;-------------------------------------------------------------------------------

; Returns a = 1 bg it has scrolled, 0 otherwise
CursorHiddenMove::

    ; Horizontal

    call    bg_main_drift_scroll_hor ; If in the middle of a movement, wait
    ld      b,0 ; has scrolled = 0
    and     a,a
    jr      nz,.skip_movement_hor

        ld      a,[joy_held]
        bit     PAD_BIT_RIGHT,a
        jr      z,.not_right

            call    bg_main_scroll_right
            ld      b,a

            push    bc
            call    bg_main_scroll_right
            pop     bc
            or      a,b
            ld      b,a ; b = 1 if it has scrolled

            jr      .skip_movement_hor
.not_right:

        ld      a,[joy_held]
        bit     PAD_BIT_LEFT,a
        jr      z,.not_left

            push    bc
            call    bg_main_scroll_left
            pop     bc
            or      a,b
            ld      b,a

            push    bc
            call    bg_main_scroll_left
            pop     bc
            or      a,b
            ld      b,a ; b = 1 if it has scrolled

            ;jr      .skip_movement_hor
.not_left:

.skip_movement_hor:

    ; Vertical

    push    bc ; here it is needed to save it
    call    bg_main_drift_scroll_ver ; If in the middle of a movement, wait
    pop     bc
    and     a,a
    jr      nz,.skip_movement_ver

        ld      a,[joy_held]
        bit     PAD_BIT_UP,a
        jr      z,.not_up

            push    bc
            call    bg_main_scroll_up
            pop     bc
            or      a,b
            ld      b,a

            push    bc
            call    bg_main_scroll_up
            pop     bc
            or      a,b
            ld      b,a ; b = 1 if it has scrolled

            jr      .skip_movement_ver
.not_up:

        ld      a,[joy_held]
        bit     PAD_BIT_DOWN,a
        jr      z,.not_down

            push    bc
            call    bg_main_scroll_down
            pop     bc
            or      a,b
            ld      b,a

            push    bc
            call    bg_main_scroll_down
            pop     bc
            or      a,b
            ld      b,a ; b = 1 if it has scrolled

            ;jr      .skip_movement_ver
.not_down:

.skip_movement_ver:

    ld      a,b
    ret

;-------------------------------------------------------------------------------

CursorGetGlobalCoords:: ; returns x in e, y in d (in tiles)

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
