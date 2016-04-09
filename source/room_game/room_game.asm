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
    INCLUDE "building_info.inc"
    INCLUDE "text.inc"
    INCLUDE "money.inc"

;###############################################################################

    SECTION "Room Game Variables",WRAM0

;-------------------------------------------------------------------------------

game_sprites_8x16:: DS 1

game_state: DS 1

last_frame_x: DS 1
last_frame_y: DS 1 ; in tiles. for autobuild when moving cursor

;###############################################################################

    SECTION "City Map Tiles",WRAMX,BANK[BANK_CITY_MAP_TILES]
CITY_MAP_TILES:: DS  CITY_MAP_WIDTH*CITY_MAP_HEIGHT ; Tile number

    SECTION "City Map Attrs",WRAMX,BANK[BANK_CITY_MAP_ATTR]
CITY_MAP_ATTR:: DS  CITY_MAP_WIDTH*CITY_MAP_HEIGHT ; Palette, tile bank

    SECTION "City Map Type",WRAMX,BANK[BANK_CITY_MAP_TYPE]
CITY_MAP_TYPE:: DS  CITY_MAP_WIDTH*CITY_MAP_HEIGHT ; Residential, road...

    SECTION "City Map Electicity",WRAMX,BANK[BANK_CITY_MAP_ELECTRICITY]
CITY_MAP_ELECTRICITY:: DS  CITY_MAP_WIDTH*CITY_MAP_HEIGHT

    SECTION "City Map Services Pollution",WRAMX,BANK[BANK_CITY_MAP_SERVICES]
CITY_MAP_POLICE::    DS  (CITY_MAP_WIDTH/2)*(CITY_MAP_HEIGHT/2)
CITY_MAP_FIREMEN::   DS  (CITY_MAP_WIDTH/2)*(CITY_MAP_HEIGHT/2)
;CITY_MAP_HOSPITALS:: DS  (CITY_MAP_WIDTH/2)*(CITY_MAP_HEIGHT/2)
CITY_MAP_POLLUTION:: DS  (CITY_MAP_WIDTH/2)*(CITY_MAP_HEIGHT/2)
CITY_MAP_SCHOOLS::   DS  (CITY_MAP_WIDTH/2)*(CITY_MAP_HEIGHT/2)
;CITY_MAP_HIGH_SCHOOLS::   DS  (CITY_MAP_WIDTH/2)*(CITY_MAP_HEIGHT/2)
;CITY_MAP_HIGH_UNIVERSITIES::   DS  (CITY_MAP_WIDTH/2)*(CITY_MAP_HEIGHT/2)

    SECTION "City Map Traffic",WRAMX,BANK[BANK_CITY_MAP_TRAFFIC]
CITY_MAP_TRAFFIC:: DS  CITY_MAP_WIDTH*CITY_MAP_HEIGHT

;    SECTION "City Map someting",WRAMX,BANK[BANK_CITY_MAP_something]
;CITY_MAP_something:: DS  CITY_MAP_WIDTH*CITY_MAP_HEIGHT

;###############################################################################

    SECTION "Room Game Code Data",ROM0

;-------------------------------------------------------------------------------

GetMapAddress:: ; e = x , d = y

    ld      bc,CITY_MAP_TILES ; = CITY_MAP_ATTR = CITY_MAP_TYPE ...

    ld      l,d
    ld      h,0
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl ; hl = y * 64

    ld      a,e
    or      a,l
    ld      l,a ; hl = y * 64 + x

    add     hl,bc ; hl = base + y * 64 + x

    ret

;-------------------------------------------------------------------------------

GameStateMachineHandle::

    ld      a,[game_state]

    cp      a,GAME_STATE_WATCH
    jr      nz,.not_watch ; GAME_STATE_WATCH

        call    InputHandleModeWatch

        call    StatusBarUpdate ; Update status bar text

        ret

.not_watch:
    cp      a,GAME_STATE_EDIT
    jr      nz,.not_edit ; GAME_STATE_EDIT

        call    InputHandleModeEdit

        call    StatusBarUpdate ; Update status bar text

        ret

.not_edit:
    cp      a,GAME_STATE_WATCH_FAST_MOVE
    jr      nz,.not_watch_fast_move ; GAME_STATE_WATCH_FAST_MOVE

        call    InputHandleModeWatchFastMove

        ret

.not_watch_fast_move:
    cp      a,GAME_STATE_SELECT_BUILDING
    jr      nz,.not_select_building ; GAME_STATE_SELECT_BUILDING

        ; If this returns a=1, don't refresh GFX
        call    InputHandleModeSelectBuilding
        and     a,a
        jr      nz,.going_to_exit
        LONG_CALL   BuildSelectMenuRefreshSprites

        call    StatusBarUpdate ; Update status bar text
.going_to_exit:

        ret

.not_select_building:
    cp      a,GAME_STATE_PAUSE_MENU
    jr      nz,.not_pause_menu ; GAME_STATE_PAUSE_MENU

        call    InputHandleModePauseMenu

        call    StatusBarMenuHandle
        cp      a,$FF
        call    nz,PauseMenuHandleOption ; $FF = user didn't press A

        ; The menu is an extended status bar, so...
        call    StatusBarUpdate ; Update status bar text

        ret

.not_pause_menu:


    ; Panic!
    ld      b,b ; Breakpoint
    ret

;-------------------------------------------------------------------------------

GameStateMachineStateGet:: ; return a = state

    ld      a,[game_state]

    ret

;-------------------------------------------------------------------------------

GameStateMachineStateSet:: ; a = new state

    ld      [game_state],a

    cp      a,GAME_STATE_WATCH
    jr      nz,.not_watch ; GAME_STATE_WATCH

        ld      a,B_None
        ld      b,1 ; refresh
        call    BuildingTypeSelect

        ld      a,LCDCF_OBJ8
        ld      [game_sprites_8x16],a

        call    StatusBarShow
        call    StatusBarUpdate

        call    CursorShow

        ret

.not_watch:
    cp      a,GAME_STATE_EDIT
    jr      nz,.not_edit ; GAME_STATE_EDIT

        call    StatusBarShow
        call    StatusBarUpdate
        call    BuildOverlayIconShow

        call    CursorShow

        ret

.not_edit:
    cp      a,GAME_STATE_WATCH_FAST_MOVE
    jr      nz,.not_watch_fast_move ; GAME_STATE_WATCH_FAST_MOVE

        call    StatusBarHide
        call    CursorHide

        ret

.not_watch_fast_move:
    cp      a,GAME_STATE_SELECT_BUILDING
    jr      nz,.not_select_building ; GAME_STATE_SELECT_BUILDING

        ; Don't refresh sprites, it will be done the first frame after this one
        LONG_CALL   BuildSelectMenuShow

        call    CursorHide
        call    CursorMoveToOrigin

        ret

.not_select_building:
    cp      a,GAME_STATE_PAUSE_MENU
    jr      nz,.not_pause_menu ; GAME_STATE_PAUSE_MENU

        call    CursorHide
        call    CursorMoveToOrigin

        call    StatusBarHide
        call    StatusBarMenuShow

        ret

.not_pause_menu:

    ; Panic!
    ld      b,b ; Breakpoint
    ret

;-------------------------------------------------------------------------------

    DATA_MONEY_AMOUNT MONEY_AMOUNT_CHEAT,9999999999

PAUSE_MENU_RESUME    EQU 0
PAUSE_MENU_MINIMAP   EQU 1
PAUSE_MENU_BUDGET    EQU 2
PAUSE_MENU_CHEAT     EQU 3
PAUSE_MENU_SAVE_GAME EQU 4
PAUSE_MENU_MAIN_MENU EQU 5

PauseMenuHandleOption:

    cp      a,PAUSE_MENU_RESUME
    jr      nz,.not_resume

        ; Resume

        call    StatusBarMenuHide
        ld      a,GAME_STATE_WATCH
        call    GameStateMachineStateSet

        ret

.not_resume:
    cp      a,PAUSE_MENU_MINIMAP
    jr      nz,.not_minimap

        ; Minimap

        ret

.not_minimap:
    cp      a,PAUSE_MENU_BUDGET
    jr      nz,.not_budget

        ; Budget

        ret

.not_budget:
    cp      a,PAUSE_MENU_CHEAT
    jr      nz,.not_cheat

        ; Cheat

        ld      de,MONEY_AMOUNT_CHEAT
        call    MoneyAdd ; de = ptr to the amount of money to set

        ret

.not_cheat:
    cp      a,PAUSE_MENU_SAVE_GAME
    jr      nz,.not_save_game

        ; Save Game

        ld      a,0
        call    CityMapSave

        ret

.not_save_game:
    cp      a,PAUSE_MENU_MAIN_MENU
    jr      nz,.not_main_menu

        ; Main Menu

        ret

.not_main_menu:

    ; Panic!
    ld      b,b

    ret

;-------------------------------------------------------------------------------

InputHandleModeWatch:

    ld      a,[joy_pressed]
    and     a,PAD_B
    jr      z,.not_b
        ld      a,GAME_STATE_WATCH_FAST_MOVE
        call    GameStateMachineStateSet
        ret
.not_b:

    ld      a,[joy_pressed]
    and     a,PAD_START
    jr      z,.not_start

        ld      a,GAME_STATE_PAUSE_MENU
        call    GameStateMachineStateSet
        ret
.not_start:

    ld      a,[joy_pressed]
    and     a,PAD_SELECT
    jr      z,.not_select
        ld      a,GAME_STATE_SELECT_BUILDING
        call    GameStateMachineStateSet
        ret
.not_select:

    call    CursorHandle

    call    CursorGetGlobalCoords ; e = x, d = y

    ld      hl,last_frame_x
    ld      c,[hl] ; get old x
    ld      [hl],e ; save new x

    ld      hl,last_frame_y
    ld      b,[hl] ; get old y
    ld      [hl],d ; save new y

IF 0
    ld      a,c
    sub     a,e
    ld      c,a ; c = old x - new x
    ld      a,b
    sub     a,d ; a = old y - new y

    or      a,c ; if there is any difference, a != 0
    jr      z,.check_a_new_press
    ld      a,[joy_held]
    and     a,PAD_A
    jr      z,.check_a_new_press
    call    CityMapDraw ; TODO : NOT BUILD, SHOW INFORMATION
    jr      .end_draw_check
.check_a_new_press:
    ld      a,[joy_pressed]
    and     a,PAD_A
    call    nz,CityMapDraw ; TODO : NOT BUILD, SHOW INFORMATION
.end_draw_check:
ENDC

    ret

;-------------------------------------------------------------------------------

InputHandleModeEdit:

    ld      a,[joy_pressed]
    and     a,PAD_B
    jr      z,.not_b
        LONG_CALL   BuildSelectMenuHide
        call    BuildOverlayIconHide
        ld      a,GAME_STATE_WATCH
        call    GameStateMachineStateSet
        ret
.not_b:

;    ld      a,[joy_pressed]
;    and     a,PAD_START
;    jr      z,.not_start
;        call    BuildOverlayIconHide
;        ld      a,GAME_STATE_PAUSE_MENU
;        call    GameStateMachineStateSet
;        ret
;.not_start:

    ld      a,[joy_pressed]
    and     a,PAD_SELECT
    jr      z,.not_select
        call    BuildOverlayIconHide
        ld      a,GAME_STATE_SELECT_BUILDING
        call    GameStateMachineStateSet
        ret
.not_select:

    call    CursorHandle

    call    CursorGetGlobalCoords ; e = x, d = y

    ld      hl,last_frame_x
    ld      c,[hl] ; get old x
    ld      [hl],e ; save new x

    ld      hl,last_frame_y
    ld      b,[hl] ; get old y
    ld      [hl],d ; save new y

    ld      a,c
    sub     a,e
    ld      c,a ; c = old x - new x
    ld      a,b
    sub     a,d ; a = old y - new y

    or      a,c ; if there is any difference, a != 0
    jr      z,.check_a_new_press
    ld      a,[joy_held]
    and     a,PAD_A
    jr      z,.check_a_new_press
    call    CityMapDraw
    jr      .end_draw_check
.check_a_new_press:
    ld      a,[joy_pressed]
    and     a,PAD_A
    call    nz,CityMapDraw
.end_draw_check:

    ret

;-------------------------------------------------------------------------------

; Returns 1 if going to exit (don't refresh gfx) else 0
InputHandleModeSelectBuilding:

    ld      a,[joy_released]
    and     a,PAD_A
    jr      z,.not_a
        LONG_CALL   BuildSelectMenuHide
        LONG_CALL   BuildSelectMenuSelectBuildingUpdateCursor
        ld      a,GAME_STATE_EDIT
        call    GameStateMachineStateSet
        ld      a,1
        ret
.not_a:

    ld      a,[joy_pressed]
    and     a,PAD_B|PAD_SELECT
    jr      z,.not_b_or_select
        LONG_CALL   BuildSelectMenuHide
        ld      a,GAME_STATE_WATCH
        call    GameStateMachineStateSet
        ld      a,1
        ret
.not_b_or_select:

    LONG_CALL   BuildSelectMenuHandle

    ld      a,0
    ret

;-------------------------------------------------------------------------------

InputHandleModeWatchFastMove:

    ld      a,[joy_held]
    and     a,PAD_B
    jr      nz,.not_b
        ld      a,GAME_STATE_WATCH
        call    GameStateMachineStateSet
        ret
.not_b:

    call    CursorHiddenMove

    ret

;-------------------------------------------------------------------------------

InputHandleModePauseMenu:

    ld      a,[joy_pressed]
    and     a,PAD_B|PAD_START
    jr      z,.not_b_start
        call    StatusBarMenuHide
        ld      a,GAME_STATE_WATCH
        call    GameStateMachineStateSet
        ret
.not_b_start:

    ret

;-------------------------------------------------------------------------------

RoomGameVBLHandler:

    call    StatusBarHandlerVBL ; Update position and registers (bg+spr)
    call    refresh_OAM ; update OAM after moving sprites
    call    bg_update_scroll_registers

    ; Set 8x16 or 8x8 sprites
    ld      b,LCDCF_OBJ8
    ld      a,[game_state]
    cp      a,GAME_STATE_SELECT_BUILDING
    jr      nz,.not_16
    ld      b,LCDCF_OBJ16
.not_16:
    ld      a,b
    ld      [game_sprites_8x16],a

    ret

;-------------------------------------------------------------------------------

RoomGame::

    call    SetPalettesAllBlack

    ; Load map and city data.
    call    CityMapLoad ; Returns starting coordinates in d = x and e = y
    push    de ; (*) Save coordinates to pass to bg_load_main

    call    LoadText
    LONG_CALL   BuildSelectMenuLoadGfx
    call    BuildSelectMenuReset
    call    StatusBarMenuLoadGfx
    call    CursorLoad

    pop     de ; (*) Restore coordinates to pass to bg_load_main
    call    bg_load_main

    ld      a,[game_sprites_8x16]
    or      a,LCDCF_BG9C00|LCDCF_OBJON|LCDCF_WIN9800|LCDCF_WINON|LCDCF_ON
    ld      [rLCDC],a
    ld      a,$FF
    ld      [rWX],a
    ld      [rWY],a

    call    CursorShow

    ld      bc,RoomGameVBLHandler
    call    irq_set_VBL

    ld      hl,rIE
    set     0,[hl] ; IEF_VBLANK

    ld      a,GAME_STATE_WATCH
    call    GameStateMachineStateSet ; After loading gfx

    xor     a,a
    ld      [rIF],a

    ei

    call    CursorGetGlobalCoords
    ld      a,e
    ld      [last_frame_x],a
    ld      a,d
    ld      [last_frame_y],a

    call    InitKeyAutorepeat

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    GameStateMachineHandle

    jr      .loop

    ret

;###############################################################################
