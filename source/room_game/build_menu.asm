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
    INCLUDE "tileset_info.inc"
    INCLUDE "building_info.inc"

;###############################################################################

    SECTION "City Map Draw Menu Variables",WRAM0

;-------------------------------------------------------------------------------

menu_selected_group: DS 1
menu_selected_item:  DS 1 ; item inside group
menu_has_changed:    DS 1 ; 1 if menu needs a redraw

menu_cursor_oam_base:  DS 1 ; first oam index, for movement. $FF = disable
menu_cursor_y_base:    DS 1 ; base y
menu_cursor_y_inc:     DS 1 ; increment to the Y coordinate
menu_cursor_countdown: DS 1
MENU_CURSOR_MOVEMENT_RANGE EQU 1
MENU_CURSOR_MOVEMENT_SPEED EQU 10

menu_active:    DS 1

build_overlay_icon_active: DS 1

menu_overlay_sprites_active:: DS 1 ; LCDCF_OBJON or 0

cpu_busy_icon_active: DS 1

;###############################################################################

    SECTION "City Map Draw Menu Functions",ROMX

;-------------------------------------------------------------------------------

BUILD_SELECT_SPRITES_TILESET:
.s:
    INCBIN "data/build_select_sprites.bin"
.e:

NUM_TILES   EQU (.e - .s) / (8*8/4)
NUM_SPRITES EQU NUM_TILES / 2

SPRITE_TILE_BASE    EQU 0 ; 2 VRAM banks, start at 1 and continue at 0

NUM_ROWS_MENU   EQU (144/16) ; scrn height / icon height

OVERLAY_ICON_TILE_BASE EQU 4 ; Sprite base for overlay icon (4 needed)

MENU_BASE_X EQU 8+(4) ; 4 pixels from left
MENU_BASE_Y EQU 16+(-8) ; 8 pixels overflow from top

; Building selection menu arrow icon equates
BUILD_SELECT_CURSOR_TILE    EQU $10
BUILD_SELECT_CURSOR_PALETTE EQU 5

; CPU busy icon equates
CPU_BUSY_ICON_OAM_BASE      EQU 39
CPU_BUSY_ICON_XCOORD        EQU ((160-8)+8)
CPU_BUSY_ICON_YCOORD_TOP    EQU ((0)+16)
CPU_BUSY_ICON_YCOORD_BOTTOM EQU ((144-8)+16)
CPU_BUSY_ICON_TILE          EQU $12 ; Made of 2 8x8 tiles, the second one empty
CPU_BUSY_ICON_PALETTE       EQU 1

;-------------------------------------------------------------------------------

WHITE   EQU (31<<10)|(31<<5)|(31<<0)
BLACK   EQU (0<<10)|(0<<5)|(0<<0)

BUILD_SELECT_SPRITES_PALETTES:
    DW 0, WHITE, (15<<10)|(15<<5)|(15<<0), BLACK
    DW 0, WHITE, (0<<10)|(0<<5)|(31<<0), BLACK
    DW 0, WHITE, (31<<10)|(0<<5)|(0<<0), BLACK
    DW 0, WHITE, (0<<10)|(31<<5)|(0<<0), BLACK
    DW 0, WHITE, (0<<10)|(8<<5)|(15<<0), BLACK
    DW 0, WHITE, (0<<10)|(31<<5)|(31<<0), BLACK

;-------------------------------------------------------------------------------

CURINDEX SET 0

ICON_SET_BUILDING : MACRO ; 1 = Index, 2 = B_xxxxx (or B_None), 3 and 4 = pal
\1  EQU CURINDEX
    DB (\2) ; Add data for this element
    IF CURINDEX < 32
        DB (\3)|OAMF_BANK1,(\4)|OAMF_BANK1 ; Palettes
    ELSE
        DB (\3),(\4) ; Palettes for left half and right half
    ENDC
CURINDEX SET (\1)+1
ENDM

ICON_SET_GROUP_NUMBER : MACRO ; 1 = Equate
\1 EQU CURINDEX
ENDM

; TODO size checks where this is used

Icon_Number_Icons_Per_Groups EQU 3

ICON_TO_BUILDING_PAL: ; Get palette and building from icon
    ICON_SET_BUILDING Icon_Group_Delete, B_None, 5,5
    ICON_SET_BUILDING Icon_Group_RCI, B_None, 0,0
    ICON_SET_BUILDING Icon_Group_RoadTrainPower, B_None, 0,0
    ICON_SET_BUILDING Icon_Group_PoliceFiremenHospital, B_None, 2,1
    ICON_SET_BUILDING Icon_Group_ParksAndRecreation, B_None, 3,0
    ICON_SET_BUILDING Icon_Group_Education, B_None, 0,0
    ICON_SET_BUILDING Icon_Group_Culture, B_None, 3,3
    ICON_SET_BUILDING Icon_Group_Transport, B_None, 0,0
    ICON_SET_BUILDING Icon_Group_PowerFossil, B_None, 0,5
    ICON_SET_BUILDING Icon_Group_PowerRenewable, B_None, 2,5

    ICON_SET_GROUP_NUMBER Icon_Number_Groups

    ICON_SET_BUILDING Icon_Destroy, B_Delete, 1,1

    ICON_SET_BUILDING Icon_Residential, B_Residential, 3,3
    ICON_SET_BUILDING Icon_Commercial, B_Commercial, 2,2
    ICON_SET_BUILDING Icon_Industrial, B_Industrial, 5,5

    ICON_SET_BUILDING Icon_Road, B_Road, 0,0
    ICON_SET_BUILDING Icon_Train, B_Train, 4,4
    ICON_SET_BUILDING Icon_PowerLines, B_PowerLines, 0,0

    ICON_SET_BUILDING Icon_Police, B_Police, 2,2
    ICON_SET_BUILDING Icon_Firemen, B_Firemen, 1,1
    ICON_SET_BUILDING Icon_Hospital, B_Hospital, 3,3

    ICON_SET_BUILDING Icon_ParkSmall, B_ParkSmall, 3,3
    ICON_SET_BUILDING Icon_ParkBig, B_ParkBig, 3,2
    ICON_SET_BUILDING Icon_Stadium, B_Stadium, 3,3

    ICON_SET_BUILDING Icon_School, B_School, 0,0
    ICON_SET_BUILDING Icon_HighSchool, B_HighSchool, 0,0
    ICON_SET_BUILDING Icon_University, B_University, 0,0

    ICON_SET_BUILDING Icon_Museum, B_Museum, 0,0
    ICON_SET_BUILDING Icon_Library, B_Library, 0,0

    ICON_SET_BUILDING Icon_Port, B_Port, 0,0
    ICON_SET_BUILDING Icon_Airport, B_Airport, 0,0

    ICON_SET_BUILDING Icon_PowerPlantCoal, B_PowerPlantCoal, 0,0
    ICON_SET_BUILDING Icon_PowerPlantOil, B_PowerPlantOil, 0,0
    ICON_SET_BUILDING Icon_PowerPlantNuclear, B_PowerPlantNuclear, 5,5

    ICON_SET_BUILDING Icon_PowerPlantWind, B_PowerPlantWind, 0,0
    ICON_SET_BUILDING Icon_PowerPlantSolar, B_PowerPlantSolar, 5,5
    ICON_SET_BUILDING Icon_PowerPlantFusion, B_PowerPlantFusion, 1,1

    ; For unused spaces on the menu
    ICON_SET_BUILDING Icon_NULL, B_None, 0,0
    ; End list

;-------------------------------------------------------------------------------

ICON_MAP: ; Order of icons is right to left
    DB Icon_Group_Delete
    DB Icon_Destroy, Icon_NULL, Icon_NULL ; Pad with NULL

    DB Icon_Group_RCI
    DB Icon_Residential, Icon_Commercial, Icon_Industrial

    DB Icon_Group_RoadTrainPower
    DB Icon_Road, Icon_Train, Icon_PowerLines

    DB Icon_Group_PoliceFiremenHospital
    DB Icon_Police, Icon_Firemen, Icon_Hospital

    DB Icon_Group_ParksAndRecreation
    DB Icon_ParkSmall, Icon_ParkBig, Icon_Stadium

    DB Icon_Group_Education
    DB Icon_School, Icon_HighSchool, Icon_University

    DB Icon_Group_Culture
    DB Icon_Museum, Icon_Library, Icon_NULL

    DB Icon_Group_Transport
    DB Icon_Port, Icon_Airport, Icon_NULL

    DB Icon_Group_PowerFossil
    DB Icon_PowerPlantCoal, Icon_PowerPlantOil, Icon_PowerPlantNuclear

    DB Icon_Group_PowerRenewable
    DB Icon_PowerPlantWind, Icon_PowerPlantSolar, Icon_PowerPlantFusion

    DB Icon_NULL ; End
    DB Icon_NULL, Icon_NULL, Icon_NULL

;-------------------------------------------------------------------------------

; c is updated when returning
_BuildSelectMenuDrawIcon: ; a = icon (not NULL!), c = spr base, d = x, e = y

    push    bc ; save for moving the sprites later (***)
    push    de

        ; A = Icon
        ; C = Sprite base

        ; Get palettes (tile = icon * 4)

        ld      hl,ICON_TO_BUILDING_PAL ; Get palette and building from icon
        ld      e,a
        ld      d,0
        add     hl,de
        add     hl,de
        add     hl,de

        inc     hl
        ld      d,[hl] ; pal left
        inc     hl
        ld      e,[hl] ; pal right

        add     a,a
        add     a,a
        and     a,$7F ; limit to 128

        ; A = Base tile
        ; D, E = palettes

        ; Set tiles and palettes

        ; Left

        push    af
        push    bc
        push    de

        ld      l,c
        call    sprite_set_tile ; a = tile    l = sprite number

        pop     de
        pop     bc
        push    bc
        push    de

        ld      a,d
        ld      l,c
        call    sprite_set_params ;  a = params    l = sprite number

        pop     de
        pop     bc
        pop     af

        ; Right

        push    bc
        push    de

        add     a,2
        inc     c
        ld      l,c
        call    sprite_set_tile ; a = tile    l = sprite number

        pop     de
        pop     bc

        inc     c
        ld      a,e
        ld      l,c
        call    sprite_set_params ;  a = params    l = sprite number

    pop     de ; restore for moving the sprites (***)
    pop     bc

    ; Move sprites last to prevent glitches

    push    bc

    ld      l,c
    ld      b,d
    ld      c,e
    push    hl
    push    bc
    call    sprite_set_xy ; b = x    c = y    l = sprite number
    pop     bc
    pop     hl
    inc     l
    ld      a,8
    add     a,b
    ld      b,a ; add 8 to X
    call    sprite_set_xy ; b = x    c = y    l = sprite number

    pop     bc

    inc c
    inc c ; increase oam base index for next icon

    ret

;-------------------------------------------------------------------------------

; c is updated when returning
_BuildSelectMenuDrawIconCursor: ; c = spr base, d = x, e = y

    push    bc ; save for moving the sprites later (***)
    push    de

        ; C = Sprite base

        ; Set tiles and palettes

        ; Left

        ld      a,BUILD_SELECT_CURSOR_TILE
        ld      l,c
        push    bc
        call    sprite_set_tile ; a = tile    l = sprite number
        pop     bc

        ld      a,BUILD_SELECT_CURSOR_PALETTE
        ld      l,c
        push    bc
        call    sprite_set_params ;  a = params    l = sprite number
        pop     bc

        ; Right

        inc     c
        ld      a,BUILD_SELECT_CURSOR_TILE
        ld      l,c
        push    bc
        call    sprite_set_tile ; a = tile    l = sprite number
        pop     bc

        ld      a,BUILD_SELECT_CURSOR_PALETTE|OAMF_XFLIP
        ld      l,c
        call    sprite_set_params ;  a = params    l = sprite number

    pop     de ; restore for moving the sprites (***)
    pop     bc

    ; Move sprites last to prevent glitches

    push    bc

    ld      l,c
    ld      b,d
    ld      c,e
    push    hl
    push    bc
    call    sprite_set_xy ; b = x    c = y    l = sprite number
    pop     bc
    pop     hl
    inc     l
    ld      a,8
    add     a,b
    ld      b,a ; add 8 to X
    call    sprite_set_xy ; b = x    c = y    l = sprite number

    pop     bc

    inc c
    inc c ; increase oam base index for next icon

    ret

;---------------------------------------

; returns b=0 if nothing was drawn, b=1 if it was drawn
; c is updated when returning
_BuildSelectMenuDrawRow: ; a = row number, b = is selected, c = spr base, e = y

    ; Get pointer to array of icons

    push    bc
    add     a,a
    add     a,a ; rows are 4 icons max, padded
    ld      hl,ICON_MAP
    ld      c,a
    ld      b,0
    add     hl,bc ; HL = ptr to array of icons for this row
    pop     bc

    ; Check if first icon is NULL. If so, return B=0
    ld      a,[hl]
    cp      a,Icon_NULL
    jr      nz,.not_null
    ld      b,0
    ret
.not_null:

    ; A is useless now

    ; B = is the selected row
    ld      a,b
    and     a,a
    jr      z,.only_group_icon
    ld      a,4 ; draw 4 icons if possible
    jr      .end_group_check
.only_group_icon:
    ld      a,1 ; draw 1 icon (group)
.end_group_check:

    ; Set X coordinate
    ld      d,MENU_BASE_X ; X

    ; A = number of icons to draw
    ; C = spr base
    ; D = x, E = y
    ; HL = ptr to 4 array of icons

.loop:
    push    af ; save iterations count

    ld      a,[hl+] ; get icon
    cp      a,Icon_NULL
    jr      z,.skip

        push    de
        push    hl

        call    _BuildSelectMenuDrawIcon ; a = icon, c = spr base, d = x, e = y
        ; c is updated when returning from the function

        pop     hl
        pop     de

        ; Now check if this is the selected icon and draw cursor

        pop     af
        push    af

        ld      b,a
        ld      a,3
        sub     a,b ; a = item selected

        push    hl

            ld      hl,menu_selected_item
            cp      a,[hl]
            jr      nz,.not_the_same

                    ; check if left column of the screen (group icon, not an
                    ; actual selection)
                    ld      a,d
                    cp      a,MENU_BASE_X ; X
                    jr      z,.not_the_same
                    ; Draw cursor underneath this icon

                        push    de
                        ld      a,[menu_cursor_y_inc]
                        add     a,e
                        add     a,16 ; y += 16 + inc
                        ld      e,a
                        ld      [menu_cursor_y_base],a ; save Y base

                        ld      a,c
                        ld      [menu_cursor_oam_base],a ; save oam base

                        call    _BuildSelectMenuDrawIconCursor
                        pop     de

.not_the_same:
        pop     hl

.skip:

    ld      a,16
    add     a,d
    ld      d,a ; increase X

    pop     af ; restore iterations count

    dec     a
    jr      nz,.loop

    ld      b,1 ; at least one icon was drawn, return B=1
    ret

;---------------------------------------

BuildSelectMenuRefreshSprites::

    ld      a,[menu_has_changed]
    and     a,a
    ret     z
    xor     a,a
    ld      [menu_has_changed],a

    ; Clear all sprites

    xor     a,a
    ld      hl,OAM_Copy
    ld      b,4*40
    call    memset_fast

    ; Get start Y coordinate

    ld      a,[status_bar_on_top]
    and     a,a
    jr      z,.bar_on_bottom
        ; Bar on top
        ld      e,16+MENU_BASE_Y ; Y
        jr      .end_check_bar
.bar_on_bottom:
        ; Bar on bottom
        ld      e,MENU_BASE_Y ; Y
.end_check_bar:

    ; Get the first row that has to be drawn. Total = NUM_ROWS_MENU

    ld      a,[menu_selected_group]
    sub     a,(NUM_ROWS_MENU/2)
    jr      nc,.not_limit
    ld      a,16
    add     a,e
    ld      e,a ; add 16 to first Y
    xor     a,a ; start in menu row 0
.not_limit:

    ; a = first row to draw
    ; e = start Y coordinate
    ld      c,0 ; start with sprite 0 - preserved during the loop!

    REPT    NUM_ROWS_MENU ; loop for a max of NUM_ROWS_MENU iterations

    ld      b,0 ; selected = 0
    ld      hl,menu_selected_group
    cp      a,[hl]
    jr      nz,.not_selected\@
    inc     b ; selected = 1
.not_selected\@:

    push    de ; save coordinate Y and counter (*)
    push    af

    ; c = spr base
    call    _BuildSelectMenuDrawRow ; a = row number, b = is selected, e = y
    ; returns b=0 if nothing was drawn, b=1 if it was drawn

    pop     af
    pop     de ; restore coordinate Y and counter (*)

    bit     0,b
    ret     z ; return if this last time nothing was drawn

    ; Increment row
    inc     a

    ld      b,a ; save a (***)

    ; Increment Y
    ld      a,e
    add     a,16
    ld      e,a

    ld      a,b ; restore a (***)

    ENDR

    ret

;-------------------------------------------------------------------------------

BuildSelectMenuShow::

    ld      a,[menu_active]
    and     a,a
    ret     nz ; return if already active

    ld      a,1
    ld      [menu_active],a

    ld      a,1
    ld      [menu_has_changed],a

    ld      a,MENU_CURSOR_MOVEMENT_RANGE
    ld      [menu_cursor_y_inc],a
    ld      a,$FF ; disable
    ld      [menu_cursor_oam_base],a

    ld      a,MENU_CURSOR_MOVEMENT_SPEED
    ld      [menu_cursor_countdown],a

    xor     a,a
    ld      [menu_overlay_sprites_active],a

    ret

;-------------------------------------------------------------------------------

BuildSelectMenuHide::

    ld      a,[menu_active]
    and     a,a
    ret     z ; return if not shown

    ; Clear all sprites

    xor     a,a
    ld      hl,OAM_Copy
    ld      b,4*39 ; Every sprite but the last one (used for cpu busy icon)
    call    memset_fast

    call    wait_vbl

    xor     a,a
    ld      [menu_active],a

    ld      a,LCDCF_OBJON
    ld      [menu_overlay_sprites_active],a

    ret

;-------------------------------------------------------------------------------

KeypadHandle:

    ; UP

    ld      a,[joy_pressed]
    and     a,PAD_UP
    jr      z,.not_up
        ld      hl,menu_selected_group
        ld      a,[hl]
        and     a,a
        jr      z,.not_up
            dec     [hl]
            xor     a,a
            ld      [menu_selected_item],a
            ld      a,1
            ld      [menu_has_changed],a
.not_up:

    ; DOWN

    ld      a,[joy_pressed]
    and     a,PAD_DOWN
    jr      z,.not_down
        ld      hl,menu_selected_group
        ld      a,[hl]
        cp      a,Icon_Number_Groups-1
        jr      z,.not_down
            inc     [hl]
            xor     a,a
            ld      [menu_selected_item],a
            ld      a,1
            ld      [menu_has_changed],a
.not_down:

    ; LEFT

    ld      a,[joy_pressed]
    and     a,PAD_LEFT
    jr      z,.not_left
        ld      hl,menu_selected_item
        ld      a,[hl]
        and     a,a
        jr      z,.not_left
            dec     [hl]
            ld      a,1
            ld      [menu_has_changed],a
.not_left:

    ; RIGHT

    ld      a,[joy_pressed]
    and     a,PAD_RIGHT
    jr      z,.not_right

        ld      hl,menu_selected_item
        ld      a,[hl]
        cp      a,Icon_Number_Icons_Per_Groups-1
        jr      z,.not_right

            ld      a,[menu_selected_item]
            inc     a
            inc     a
            ld      c,a
            ld      b,0
            ld      hl,ICON_MAP
            add     hl,bc

            ld      a,[menu_selected_group]
            add     a,a
            add     a,a
            ld      c,a
            ld      b,0
            add     hl,bc

            ld      a,[hl]
            cp      a,Icon_NULL
            jr      z,.not_right
                ld      hl,menu_selected_item
                inc     [hl]
                ld      a,1
                ld      [menu_has_changed],a
.not_right:

    ret

;-------------------------------------------------------------------------------

BuildSelectMenuHandleCursorMovement::

    ld      hl,menu_cursor_countdown
    dec     [hl]
    ret     nz ; return if not needed to move
    ld      a,MENU_CURSOR_MOVEMENT_SPEED
    ld      [hl],a ; reset countdown

    ld      a,[menu_cursor_y_inc]
    xor     a,1 ; move between 1 and 0
    ld      [menu_cursor_y_inc],a

    ld      a,[menu_cursor_oam_base]
    cp      a,$FF ; check if disabled
    ret     z

    ld      l,a
    call    sprite_get_base_pointer ; return = hl
    ld      a,[menu_cursor_y_base]
    ld      b,a
    ld      a,[menu_cursor_y_inc]
    add     a,b
    ld      [hl],a

    inc     hl
    inc     hl
    inc     hl
    inc     hl
    ld      a,[menu_cursor_y_base]
    ld      b,a
    ld      a,[menu_cursor_y_inc]
    add     a,b
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------

BuildSelectMenuHandle::

    ld      a,[menu_active]
    and     a,a
    ret     z ; return if not shown

    call    KeypadHandle

    call    BuildSelectMenuSelectBuilding

    call    BuildSelectMenuHandleCursorMovement

    ret

;-------------------------------------------------------------------------------

; Get menu selection and select that building, update cursor
BuildSelectMenuSelectBuildingUpdateCursor::
    ld      b,1
    jr      _build_select_menu_entrypoint

; Get menu selection and select that building, don't update cursor
BuildSelectMenuSelectBuilding::

    ld      b,0
_build_select_menu_entrypoint:

    push    bc

    ; Set building type to the element selected right now
    ; ---------------------------------------------------

    ld      a,[menu_selected_group]
    add     a,a
    add     a,a
    ld      c,a
    ld      b,0
    ld      hl,ICON_MAP
    add     hl,bc

    ld      a,[menu_selected_item]
    inc     a
    ld      c,a
    add     hl,bc

    ld      a,[hl]

    ; A = Icon. Now, get the B_XXXX define

    ld      hl,ICON_TO_BUILDING_PAL
    ld      c,a
    add     hl,bc
    add     hl,bc
    add     hl,bc
    ld      a,[hl]

    pop     bc ; refresh / don't refresh cursor
    call    BuildingTypeSelect

    ret

;-------------------------------------------------------------------------------

BuildOverlayIconDraw:

    ; Get icon

    call    BuildingTypeGet ; a = type
    ld      b,a ; b = building

    ld      c,Icon_Number_Groups ; Loop until Icon_NULL
    ld      hl,ICON_TO_BUILDING_PAL+Icon_Number_Groups*3
.loop:
    ld      a,[hl+]
    cp      a,b
    jr      z,.end_loop

    inc     c
    ld      a,Icon_NULL
    cp      a,c
    jr      nz,.not_null
        ; Panic!
        ld      b,b
        ret
.not_null:
    inc     hl
    inc     hl
    jr      .loop

.end_loop:

    ld      a,c ; A = icon

    ; Get palettes and tile (tile = icon * 4)

    ld      hl,ICON_TO_BUILDING_PAL ; Get palette and building from icon
    ld      e,a
    ld      d,0
    add     hl,de
    add     hl,de
    add     hl,de

    inc     hl
    ld      d,[hl] ; pal left
    inc     hl
    ld      e,[hl] ; pal right

    add     a,a
    add     a,a
    and     a,$7F ; limit to 128

    ; A = Base tile
    ; D, E = palettes

    ; Set tiles

    push    de

        push    af
        ld      l,OVERLAY_ICON_TILE_BASE+0
        call    sprite_set_tile ; a = tile    l = sprite number
        pop     af
        inc     a
        push    af
        ld      l,OVERLAY_ICON_TILE_BASE+1
        call    sprite_set_tile ; a = tile    l = sprite number
        pop     af
        inc     a
        push    af
        ld      l,OVERLAY_ICON_TILE_BASE+2
        call    sprite_set_tile ; a = tile    l = sprite number
        pop     af
        inc     a
        push    af
        ld      l,OVERLAY_ICON_TILE_BASE+3
        call    sprite_set_tile ; a = tile    l = sprite number
        pop     af

    pop     de

    ; Set attributes

    push    de
    ld      a,d
    ld      l,OVERLAY_ICON_TILE_BASE+0
    call    sprite_set_params ;  a = params    l = sprite number
    pop     de
    push    de
    ld      a,d
    ld      l,OVERLAY_ICON_TILE_BASE+1
    call    sprite_set_params ;  a = params    l = sprite number
    pop     de
    push    de
    ld      a,e
    ld      l,OVERLAY_ICON_TILE_BASE+2
    call    sprite_set_params ;  a = params    l = sprite number
    pop     de
    push    de
    ld      a,e
    ld      l,OVERLAY_ICON_TILE_BASE+3
    call    sprite_set_params ;  a = params    l = sprite number
    pop     de

    ; Move sprites last to prevent glitches

    call    BuildOverlayIconRefreshPosition

    ret

;-------------------------------------------------------------------------------

BuildOverlayIconRefreshPosition:

    ; Load coordinates according to bar position

    ld      a,[status_bar_on_top]
    and     a,a
    jr      z,.on_bottom
        ; On top
        ld      b,160-16+8
        ld      c,0+16
        jr      .end_position_check
.on_bottom:
        ; On bottom
        ld      b,160-16+8
        ld      c,144-16+16
.end_position_check:

    push    bc
    ld      l,OVERLAY_ICON_TILE_BASE+0
    call    sprite_set_xy ; b = x    c = y    l = sprite number
    pop     bc
    push    bc
    ld      a,8
    add     a,c
    ld      c,a ; add 8 to Y
    ld      l,OVERLAY_ICON_TILE_BASE+1
    call    sprite_set_xy ; b = x    c = y    l = sprite number
    pop     bc
    ld      a,8
    add     a,b
    ld      b,a ; add 8 to X
    push    bc
    ld      l,OVERLAY_ICON_TILE_BASE+2
    call    sprite_set_xy ; b = x    c = y    l = sprite number
    pop     bc
    push    bc
    ld      a,8
    add     a,c
    ld      c,a ; add 8 to Y
    ld      l,OVERLAY_ICON_TILE_BASE+3
    call    sprite_set_xy ; b = x    c = y    l = sprite number
    pop     bc

    ret

;###############################################################################

    SECTION "City Map Draw Menu Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

BuildSelectMenuReset::

    xor     a,a
    ld      [menu_selected_group],a
    ld      [menu_selected_item],a
    ld      [build_overlay_icon_active],a
    ld      [menu_active],a

    ret

;-------------------------------------------------------------------------------

BuildSelectMenuLoadGfx::

    ld      b,BANK(BUILD_SELECT_SPRITES_TILESET)
    call    rom_bank_push_set

IF NUM_TILES > 128

    ld      a,1
    ld      [rVBK],a

    ld      bc,128
    ld      de,SPRITE_TILE_BASE ; Bank at 8000h
    ld      hl,BUILD_SELECT_SPRITES_TILESET
    call    vram_copy_tiles

    xor     a,a
    ld      [rVBK],a

    ld      bc,NUM_TILES-128
    ld      de,SPRITE_TILE_BASE ; Bank at 8000h
    ;ld      hl,BUILD_SELECT_SPRITES_TILESET ; Continue previous copy
    call    vram_copy_tiles

ELSE

    ld      a,1
    ld      [rVBK],a

    ld      bc,NUM_TILES
    ld      de,SPRITE_TILE_BASE ; Bank at 8000h
    ld      hl,BUILD_SELECT_SPRITES_TILESET
    call    vram_copy_tiles

ENDC

    ld      b,BANK(BUILD_SELECT_SPRITES_PALETTES)
    call    rom_bank_set

    ; Load palettes - Not critical, the menu isn't shown right away

    ld      hl,BUILD_SELECT_SPRITES_PALETTES

    ld      a,0
    call    spr_set_palette_safe ; hl will increase inside
    ld      a,1
    call    spr_set_palette_safe
    ld      a,2
    call    spr_set_palette_safe
    ld      a,3
    call    spr_set_palette_safe
    ld      a,4
    call    spr_set_palette_safe
    ld      a,5
    call    spr_set_palette_safe

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

BuildOverlayIconRefresh::

    ld      a,[build_overlay_icon_active]
    and     a,a
    ret     z ; return if hidden

    LONG_CALL   BuildOverlayIconRefreshPosition ; ret a = building

    ret

;-------------------------------------------------------------------------------

; The icon is set in this function and won't be updated until it is hidden and
; shown again.
BuildOverlayIconShow::

    ld      a,[build_overlay_icon_active]
    and     a,a
    ret     nz ; return if already active

    ld      a,1
    ld      [build_overlay_icon_active],a

    xor     a,a
    ld      [menu_cursor_y_inc],a
    ld      a,$FF ; disable
    ld      [menu_cursor_oam_base],a

    LONG_CALL   BuildOverlayIconDraw

    ret

;-------------------------------------------------------------------------------

BuildOverlayIconHide::

    ld      a,[build_overlay_icon_active]
    and     a,a
    ret     z ; return if already hidden

    xor     a,a
    ld      [build_overlay_icon_active],a

    ld      bc,$0000
    ld      l,OVERLAY_ICON_TILE_BASE+0
    call    sprite_set_xy ; b = x    c = y    l = sprite number
    ld      bc,$0000
    ld      l,OVERLAY_ICON_TILE_BASE+1
    call    sprite_set_xy ; b = x    c = y    l = sprite number
    ld      bc,$0000
    ld      l,OVERLAY_ICON_TILE_BASE+2
    call    sprite_set_xy ; b = x    c = y    l = sprite number
    ld      bc,$0000
    ld      l,OVERLAY_ICON_TILE_BASE+3
    call    sprite_set_xy ; b = x    c = y    l = sprite number

    ret

;-------------------------------------------------------------------------------

CPUBusyIconHandle::

    ld      a,[cpu_busy_icon_active]
    and     a,a
    ret     z

    ld      a,[status_menu_active]
    and     a,a
    jr      nz,.sprite_down

    ld      a,[status_bar_on_top]
    and     a,a
    jr      nz,.sprite_down

    ; Sprite Up

    ld      bc,(CPU_BUSY_ICON_XCOORD<<8)|CPU_BUSY_ICON_YCOORD_TOP
    ld      l,CPU_BUSY_ICON_OAM_BASE
    call    sprite_set_xy ; b = x    c = y    l = sprite number

    ret

.sprite_down:

    ; Sprite down

    ld      bc,(CPU_BUSY_ICON_XCOORD<<8)|CPU_BUSY_ICON_YCOORD_BOTTOM
    ld      l,CPU_BUSY_ICON_OAM_BASE
    call    sprite_set_xy ; b = x    c = y    l = sprite number

    ret

;-------------------------------------------------------------------------------

CPUBusyIconShow::

    ld      a,CPU_BUSY_ICON_TILE
    ld      l,CPU_BUSY_ICON_OAM_BASE
    call    sprite_set_tile ; a = tile    l = sprite number

    ld      a,CPU_BUSY_ICON_PALETTE
    ld      l,CPU_BUSY_ICON_OAM_BASE
    call    sprite_set_params ;  a = params    l = sprite number

    ld      a,1
    ld      [cpu_busy_icon_active],a

    call    CPUBusyIconHandle

    ret

;-------------------------------------------------------------------------------

CPUBusyIconHide::

    ld      bc,$0000
    ld      l,CPU_BUSY_ICON_OAM_BASE
    call    sprite_set_xy ; b = x    c = y    l = sprite number

    xor     a,a
    ld      [cpu_busy_icon_active],a

    ret

;###############################################################################
