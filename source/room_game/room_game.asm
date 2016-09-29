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
    INCLUDE "tileset_info.inc"

;###############################################################################

    SECTION "Room Game Variables",WRAM0

;-------------------------------------------------------------------------------

game_sprites_8x16:: DS 1

game_state: DS 1

first_simulation_iteration: DS 1 ; 1 for the first simulation iteration

last_frame_x: DS 1
last_frame_y: DS 1 ; in tiles. for autobuild when moving cursor

; Prevent the VBL handler from handling user input two frames in a row, don't
; allow any processing apart from graphic updates.
vbl_handler_working: DS 1

; Set to 0 by the simulation loop when the simulation has finished.
; It can be set by any function to tell the simulation loop to do a step.
simulation_running::  DS 1

; This is set to 1 when in disaster mode
simulation_disaster_mode:: DS 1

ANIMATION_COUNT_FRAMES_NORMAL   EQU 60
ANIMATION_COUNT_FRAMES_DISASTER EQU 15
animation_countdown: DS 1 ; This goes from 0 to the desired value

; If 1 the game is paused, if 0 it is unpaused. Setting it to 1 won't
; immediately pause the simulation, it will wait until the current step ends.
simulation_paused:: DS 1

game_loop_end_requested: DS 1 ; If 1, exit game to main menu.

game_requested_focus_x:  DS 1 ; Coordinates of requested area to scroll to.
game_requested_focus_y:  DS 1 ; $FF if nothing requested.

game_requested_disaster: DS 1 ; Set to a value != 0 to cause a disaster

;###############################################################################

    SECTION "City Map Tiles",WRAMX,BANK[BANK_CITY_MAP_TILES]
CITY_MAP_TILES:: DS CITY_MAP_WIDTH*CITY_MAP_HEIGHT ; Tile number

    SECTION "City Map Attrs",WRAMX,BANK[BANK_CITY_MAP_ATTR]
CITY_MAP_ATTR:: DS CITY_MAP_WIDTH*CITY_MAP_HEIGHT ; Palette, tile bank

    SECTION "City Map Type",WRAMX,BANK[BANK_CITY_MAP_TYPE]
CITY_MAP_TYPE:: DS CITY_MAP_WIDTH*CITY_MAP_HEIGHT ; Residential, road...

    SECTION "City Map Traffic",WRAMX,BANK[BANK_CITY_MAP_TRAFFIC]
CITY_MAP_TRAFFIC:: DS CITY_MAP_WIDTH*CITY_MAP_HEIGHT

    SECTION "City Map Flags",WRAMX,BANK[BANK_CITY_MAP_FLAGS]
CITY_MAP_FLAGS:: DS CITY_MAP_WIDTH*CITY_MAP_HEIGHT

    SECTION "Scratch WRAM Bank",WRAMX,BANK[BANK_SCRATCH_RAM]
SCRATCH_RAM:: DS $1000

    SECTION "Scratch WRAM Bank 2",WRAMX,BANK[BANK_SCRATCH_RAM_2]
SCRATCH_RAM_2:: DS $1000

;###############################################################################

    SECTION "Room Game Code Data",ROM0

;-------------------------------------------------------------------------------

ClearWRAMX:: ; Sets D000 - DFFF to 0 ($1000 bytes)

    xor     a,a ; a = 0
    ld      d,a ; d = $100
    ld      hl,$D000
.loop:
    REPT    $10 ; unroll for speed
    ld      [hl+],a
    ENDR
    dec     d
    jr      nz,.loop

    ret

;-------------------------------------------------------------------------------

GameRequestCoordinateFocus:: ; e = x, d = y

    ld      a,e
    ld      [game_requested_focus_x],a
    ld      a,d
    ld      [game_requested_focus_y],a

    ret

;-------------------------------------------------------------------------------

GameCoordinateFocusApply:

    call    MessageRequestQueueNotEmpty ; returns a = 1 if queue is not empty
    and     a,a
    ret     nz ; wait until there are no more messages left

    call    MessageBoxIsShowing
    and     a,a
    ret     nz ; if there is a message showing, wait

    ld      a,[game_requested_focus_x]
    ld      d,a
    ld      a,[game_requested_focus_y]
    ld      e,a

    ld      a,$FF ; return if disabled
    cp      a,d
    ret     z
    cp      a,e
    ret     z

    ld      [game_requested_focus_x],a ; Disable focus
    ld      [game_requested_focus_y],a

    ; Set scroll and refresh screen
    call    bg_set_scroll_main ; d = up left x    e = y

    ret

;-------------------------------------------------------------------------------

GameRequestDisaster:: ; a = type, 0 to disable

    ld      b,a
    ld      hl,game_requested_disaster
    ld      [hl],0

    ld      a,[simulation_disaster_mode]
    and     a,a
    ret     nz ; if there is a disaster, ignore this!

    ; For now, there are no types, only fire

    ld      [hl],b

    ret

;-------------------------------------------------------------------------------

GameDisasterApply:

    ld      a,[game_requested_disaster]
    and     a,a
    ret     z ; return if no disasters are requested

    xor     a,a
    ld      [game_requested_disaster],a ; clear request

    ; TODO

    ld      b,1 ; force fire
    LONG_CALL_ARGS   Simulation_FireTryStart ; Returns if any disaster present

    ret

;-------------------------------------------------------------------------------

GameAnimateMap:

    ; Reasons for not animating: Some of the direction pad keys are pressed
    ; or the map is still moving after releasing a key.


    ld      a,[simulation_disaster_mode]
    and     a,a
    jr      nz,.disaster_mode

        ld      hl,animation_countdown
        ld      a,[hl]
        cp      a,ANIMATION_COUNT_FRAMES_NORMAL
        jr      z,.animate_normal
            inc     [hl] ; increment and exit
            ret
.animate_normal:

        xor     a,a
        ld      [animation_countdown],a

        ; This doesn't refresh tile map!
        LONG_CALL   Simulation_TrafficAnimate

        jr      .end_animation

.disaster_mode:

        ld      hl,animation_countdown
        ld      a,[hl]
        cp      a,ANIMATION_COUNT_FRAMES_DISASTER
        jr      z,.animate_disaster
            inc     [hl] ; increment and exit
            ret
.animate_disaster:

        xor     a,a
        ld      [animation_countdown],a

        ; This doesn't refresh tile map!
        LONG_CALL   Simulation_FireAnimate

        ;jr      .end_animation

.end_animation:

    ; Refresh tile map
    call    bg_refresh_main

    ret

;-------------------------------------------------------------------------------

GameStateMachineHandle::

    ld      a,[game_state]

    cp      a,GAME_STATE_WATCH
    jr      nz,.not_watch ; GAME_STATE_WATCH

        call    InputHandleModeWatch

        call    StatusBarUpdate ; Update status bar text

        call    GameAnimateMap

        call    CPUBusyIconHide

        ld      a,1
        ld      [simulation_running],a ; Always simulate in watch mode

        ret

.not_watch:
    cp      a,GAME_STATE_EDIT
    jr      nz,.not_edit ; GAME_STATE_EDIT

        call    InputHandleModeEdit

        call    StatusBarUpdate ; Update status bar text

        ; Not simulating, update busy icon, but show if it isn't showing
        call    CPUBusyIconShowAndHandle

        ret

.not_edit:
    cp      a,GAME_STATE_WATCH_FAST_MOVE
    jr      nz,.not_watch_fast_move ; GAME_STATE_WATCH_FAST_MOVE

        call    InputHandleModeWatchFastMove

        call    GameAnimateMap

        call    CPUBusyIconHide

        ld      a,1
        ld      [simulation_running],a ; Always simulate in fast move mode

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

        ; Not simulating, update busy icon, but show if it isn't showing
        call    CPUBusyIconShowAndHandle

        ret

.not_pause_menu:
    cp      a,GAME_STATE_SHOW_MESSAGE
    jr      nz,.not_show_message ; GAME_STATE_SHOW_MESSAGE

        call    InputHandleModeShowMessage

        ret

.not_show_message:

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

        xor     a,a
        ld      [animation_countdown],a

        call    StatusBarShow
        call    StatusBarUpdate

        call    CursorShow

        call    CPUBusyIconHide

        ret

.not_watch:
    cp      a,GAME_STATE_EDIT
    jr      nz,.not_edit ; GAME_STATE_EDIT

        call    StatusBarShow
        call    StatusBarUpdate
        call    BuildOverlayIconShow

        call    CursorShow

        call    CPUBusyIconShow

        ret

.not_edit:
    cp      a,GAME_STATE_WATCH_FAST_MOVE
    jr      nz,.not_watch_fast_move ; GAME_STATE_WATCH_FAST_MOVE

        call    StatusBarHide
        call    CursorHide

;        xor     a,a ; not needed, we can only enter this mode from watch mode,
;        ld      [animation_countdown],a ; that should have done it already.

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

        call    CPUBusyIconShow

        ret

.not_pause_menu:
    cp      a,GAME_STATE_SHOW_MESSAGE
    jr      nz,.not_show_message ; GAME_STATE_SHOW_MESSAGE

        call    StatusBarHide
        call    CursorHide

        call    MessageBoxShow

        ret

.not_show_message:

    ; Panic!
    ld      b,b ; Breakpoint
    ret

;-------------------------------------------------------------------------------

WaitSimulationEnds:
    ld      a,[simulation_running]
    and     a,a
    ret     z
    call    wait_vbl
    jr      WaitSimulationEnds

;-------------------------------------------------------------------------------

    DATA_MONEY_AMOUNT MONEY_AMOUNT_CHEAT,0999999999

PAUSE_MENU_BUDGET    EQU 0
PAUSE_MENU_MINIMAPS  EQU 1
PAUSE_MENU_GRAPHS    EQU 2
PAUSE_MENU_OPTIONS   EQU 3
PAUSE_MENU_PAUSE     EQU 4
PAUSE_MENU_HELP      EQU 5
PAUSE_MENU_SAVE_GAME EQU 6
PAUSE_MENU_MAIN_MENU EQU 7

PauseMenuHandleOption:

    cp      a,PAUSE_MENU_BUDGET
    jr      nz,.not_budget

        ; Budget
        ld      a,[simulation_running]
        and     a,a ; If budget menu room is entered while a simulation is
        jr      z,.continue_budget  ; running, bad things may happen when.
        call    SFX_ErrorUI ; calculating taxes, etc.
        ret

.continue_budget:
        call    RoomBudgetMenu

        ld      a,0 ; load gfx only
        call    RoomGameLoad
        ret

.not_budget:
    cp      a,PAUSE_MENU_MINIMAPS
    jr      nz,.not_minimaps

        ; Minimap
        ld      a,[simulation_running]
        and     a,a ; If minimap room is entered while a simulation is running
        jr      z,.continue_minimaps  ; bad things will happen.
        call    SFX_ErrorUI
        ret

.continue_minimaps:
        call    RoomMinimap

        ld      a,0 ; load gfx only
        call    RoomGameLoad

        ret

.not_minimaps:
    cp      a,PAUSE_MENU_GRAPHS
    jr      nz,.not_graphs

        ; Graphs

        ; TODO

        ret

.not_graphs:
    cp      a,PAUSE_MENU_OPTIONS
    jr      nz,.not_options

        ; Options

        ld      a,1
        call    GameRequestDisaster

        ; TODO : Replace this by a real menu

        ret

.not_options:
    cp      a,PAUSE_MENU_PAUSE
    jr      nz,.not_pause

        ; Pause / Unpause
        ld      hl,simulation_paused
        ld      a,1
        xor     a,[hl]
        ld      [hl],a

        call    StatusBarMenuDrawPauseState

        ret

.not_pause:
    cp      a,PAUSE_MENU_HELP
    jr      nz,.not_help

        ; Help

        ; TODO : Replace this by an actual help menu
        ld      de,MONEY_AMOUNT_CHEAT
        call    MoneySet ; de = ptr to the amount of money to set

        ret

.not_help:
    cp      a,PAUSE_MENU_SAVE_GAME
    jr      nz,.not_save_game

        ld      a,[simulation_disaster_mode]
        and     a,a ; if disaster mode is active, don't allow the player to save
        push    af
        call    NZ,SFX_ErrorUI
        pop     af
        ret     nz

        ; Save Game
        ld      a,[simulation_running]
        and     a,a ; If we save the city while the simulation is running we
        jr      z,.continue_save  ; risk saving in an intermediate state.
        call    SFX_ErrorUI
        ret

.continue_save:
        ld      b,1 ; 1 = save data mode
        LONG_CALL_ARGS    RoomSaveMenu ; returns A = SRAM bank, -1 if error
        cp      a,$FF
        ; if the user pressed -1 or there was an error, don't save
        call    nz,CityMapSave ; if ok, save to the bank selected by the user

        ld      a,0 ; load gfx only
        call    RoomGameLoad

        ret

.not_save_game:
    cp      a,PAUSE_MENU_MAIN_MENU
    jr      nz,.not_main_menu

        ; Main Menu

        ld      a,1
        ld      [game_loop_end_requested],a

        ret

.not_main_menu:

    ; Panic!
    ld      b,b

    ret

;-------------------------------------------------------------------------------

InputHandleModeWatch:

    ; First, check if there are messages left to show

    call    MessageRequestGet ; returns a = message ID to show
    and     a,a
    jr      z,.no_messages_left

        call    MessageBoxPrintMessageID ; a = message ID
        ld      a,GAME_STATE_SHOW_MESSAGE
        call    GameStateMachineStateSet

        ret ; Ignore user input for the rest of the frame

.no_messages_left

    ; If not, handle user input

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

    call    CursorHandle ; returns a = 1 if bg has scrolled
    and     a,a
    jr      z,.dont_delay_anim
    xor     a,a ; if bg has scrolled, delay animation
    ld      [animation_countdown],a
.dont_delay_anim:

    call    CursorGetGlobalCoords ; e = x, d = y

    ; Update old coordinates

    ld      hl,last_frame_x
    ld      c,[hl] ; get old x
    ld      [hl],e ; save new x

    ld      hl,last_frame_y
    ld      b,[hl] ; get old y
    ld      [hl],d ; save new y


    ; Check if we have been asked to show the tile information

    ld      a,[joy_pressed]
    and     a,PAD_A
    ret     z ; Not pressed, return

    add     sp,-20 ; Space for name of the tile

    ; Returns tile in DE
    call    CityMapGetTypeAndTile ; Arguments: e = x , d = y

    ld      hl,sp+0
    LD_BC_HL
    LONG_CALL_ARGS  PrintTileNameAt ; de = tile number, bc = destination

    call    MessageBoxClear
    ld      hl,sp+0
    LD_BC_HL

    call    MessageRequestAddCustom ; bc = pointer to message. ret a = 1 if ok

    add     sp,+20

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

    call    CursorHandle ; returns a = 1 if bg has scrolled
    and     a,a
    jr      z,.dont_delay_anim
    xor     a,a ; if bg has scrolled, delay animation
    ld      [animation_countdown],a
.dont_delay_anim:

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
    jr      z,.check_a_new_press ; if there are no difference, check newpress

    ld      a,[joy_held] ; if there are differences, check movement while hold
    and     a,PAD_A
    jr      nz,.end_draw

    jr      .end_no_draw

.check_a_new_press:
    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      nz,.end_draw

.end_no_draw:
    ret

.end_draw:
    ld      a,[simulation_running]
    and     a,a ; If something is built  while a simulation is running bad
    jr      nz,.error_draw ; things will happen

    call    CityMapDraw
    ret

.error_draw:
    call    SFX_ErrorUI
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

    ; First, check if there are messages left to show

    call    MessageRequestGet ; returns a = message ID to show
    and     a,a
    jr      z,.no_messages_left

        call    MessageBoxPrintMessageID ; a = message ID
        ld      a,GAME_STATE_SHOW_MESSAGE
        call    GameStateMachineStateSet

        ret ; Ignore user input for the rest of the frame

.no_messages_left

    ; If not, handle user input

    ld      a,[joy_held]
    and     a,PAD_B
    jr      nz,.not_b
        ld      a,GAME_STATE_WATCH
        call    GameStateMachineStateSet
        ret
.not_b:

    call    CursorHiddenMove ; returns a = 1 if bg has scrolled
    and     a,a
    ret     z
    xor     a,a ; if bg has scrolled, delay animation
    ld      [animation_countdown],a
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

InputHandleModeShowMessage:

    ld      a,[joy_pressed]
    and     a,PAD_B|PAD_START
    jr      z,.not_b_start

        call    MessageBoxHide

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


    ld      a,[vbl_handler_working]
    and     a,a
    ret     nz ; already working

    ld      a,[rSVBK]
    ld      b,a
    ld      a,[rVBK]
    ld      c,a
    push    bc

    ld      a,1
    ld      [vbl_handler_working],a ; flag as working

    ; Allow another VBL (or STAT) interrupt to happen and update graphics. Since
    ; vbl_handler_working is set to 1, they will only update graphics and return
    ; before handling user input.
    ei

    call    GameCoordinateFocusApply

    call    scan_keys
    call    KeyAutorepeatHandle

    call    GameStateMachineHandle

    pop     bc
    ld      a,b
    ld      [rSVBK],a
    ld      a,c
    ld      [rVBK],a

    xor     a,a
    ld      [vbl_handler_working],a ; flag as finished working

    ret

;-------------------------------------------------------------------------------

RoomGameLoad:: ; a = 1 -> load data. a = 0 -> only load graphics

    push    af
    call    SetPalettesAllBlack
    pop     af

    and     a,a
    jr      z,.only_gfx

        ; Clear WRAMX

        ld      a,3 ; Do not clear tile and attribute map, they may contain
.clear_wramx_loop:  ; a randomly generated map.
        ld      [rSVBK],a
        push    af
        call    ClearWRAMX
        pop     af
        inc     a
        cp      a,8
        jr      nz,.clear_wramx_loop

        ; Load map and city data. Load GFX

        call    CityMapLoad ; Returns starting coordinates in d = x and e = y
        push    de ; (*) Save coordinates to pass to bg_load_main

        ld      b,0 ; bank at 8000h
        call    LoadText
        LONG_CALL   BuildSelectMenuLoadGfx
        call    BuildSelectMenuReset
        call    StatusBarMenuLoadGfx
        call    CursorLoad

        pop     de ; (*) Restore coordinates to pass to bg_load_main
        call    bg_load_main

        jr      .continue
.only_gfx:

        ; Load GFX

        ld      b,0 ; bank at 8000h
        call    LoadText
        LONG_CALL   BuildSelectMenuLoadGfx
        call    BuildSelectMenuReset
        call    StatusBarMenuLoadGfx
        call    CursorLoad

        call    bg_reload_main ; refresh bg and set correct scroll

.continue:

    ld      a,[game_sprites_8x16]
    or      a,LCDCF_BG9C00|LCDCF_OBJON|LCDCF_WIN9800|LCDCF_WINON|LCDCF_ON
    ld      [rLCDC],a
    ld      a,$FF
    ld      [rWX],a
    ld      [rWY],a

    call    CursorShow

    ld      bc,RoomGameVBLHandler
    call    irq_set_VBL

    xor     a,a
    ld      [rIF],a

    ld      a,GAME_STATE_WATCH
    call    GameStateMachineStateSet ; After loading gfx

    call    CursorGetGlobalCoords
    ld      a,e
    ld      [last_frame_x],a
    ld      a,d
    ld      [last_frame_y],a

    call    InitKeyAutorepeat
    ret

;-------------------------------------------------------------------------------

RoomGameSimulateStepNormal:

    ; First, get data from last frame and build new buildings or destroy
    ; them (if there haven't been changes since the previous step!)
    ; depending on the tile ok flags map. In the first iteration step the
    ; flags should be 0, so this can be called as well.

    ; NOTE: This function doesn't update the VRAM map after removing or
    ; creating buildings because the animation handler will take care of it.

    LONG_CALL   Simulation_CreateBuildings

    ; Now, simulate this new map. First, power distribution, as it will be
    ; needed for other simulations

    LONG_CALL   Simulation_PowerDistribution
    LONG_CALL   Simulation_PowerDistributionSetTileOkFlag

    ; After knowing the power distribution, the rest of the simulations can
    ; be done.

    LONG_CALL   Simulation_Traffic
    LONG_CALL   Simulation_TrafficSetTileOkFlag

    ; Simulate services, like police and firemen. They depend on the power
    ; simulation, as they can't work without electricity, so handle this
    ; after simulating the power grid.

    ld      bc,T_POLICE_DEPT_CENTER
    LONG_CALL_ARGS  Simulation_Services
    LONG_CALL   Simulation_ServicesSetTileOkFlag

    ld      a,[city_class]
    cp      a,CLASS_VILLAGE
    jr      z,.too_small_for_fire_hospital ; Ignore if the city is too small

        ld      bc,T_FIRE_DEPT_CENTER
        LONG_CALL_ARGS  Simulation_Services
        LONG_CALL   Simulation_ServicesAddTileOkFlag

        ld      bc,T_HOSPITAL_CENTER
        LONG_CALL_ARGS  Simulation_Services
        LONG_CALL   Simulation_ServicesAddTileOkFlag

.too_small_for_fire_hospital:

    ld      bc,T_SCHOOL_CENTER
    LONG_CALL_ARGS  Simulation_Services
    LONG_CALL   Simulation_EducationSetTileOkFlag

    ld      a,[city_class]
    cp      a,CLASS_VILLAGE
    jr      z,.too_small_for_high_school ; Ignore if the city is too small

        ld      bc,T_HIGH_SCHOOL_CENTER
        LONG_CALL_ARGS  Simulation_ServicesBig
        LONG_CALL   Simulation_EducationAddTileOkFlag

.too_small_for_high_school:

    ; After simulating traffic, power, etc, simulate pollution

    LONG_CALL   Simulation_Pollution
    LONG_CALL   Simulation_PollutionSetTileOkFlag

    ; After simulating, flag buildings to be created or demolished.

    LONG_CALL   Simulation_FlagCreateBuildings

    ; Calculate total population and other statistics

    LONG_CALL   Simulation_CalculateStatistics

    ; Calculate RCI graph

    LONG_CALL   Simulation_CalculateRCIDemand

    ; Update date, apply budget, etc.
    ; Note: Only if this is not the first iteration step!

    ld      a,[first_simulation_iteration]
    and     a,a
    jr      z,.not_first_iteration

        xor     a,a ; flag as not first iteration for the next one
        ld      [first_simulation_iteration],a
        jr      .skip_budget

.not_first_iteration:
    call    DateStep

    ld      a,[date_month]
    cp      a,0 ; Check if january
    jr      nz,.skip_budget

        ; Calculate and apply budget when a year starts (Dec -> Jan)
        LONG_CALL   Simulation_CalculateBudgetAndTaxes
        LONG_CALL   Simulation_ApplyBudgetAndTaxes

.skip_budget:

    ; Start disasters

    call    GameDisasterApply

    ld      b,0 ; don't force fire
    LONG_CALL_ARGS   Simulation_FireTryStart ; Returns if any disaster present

    ; End of this simulation step

    ret

;-------------------------------------------------------------------------------

RoomGameSimulateStepDisaster:

    LONG_CALL   Simulation_Fire

    ret

;-------------------------------------------------------------------------------

RoomGameSimulateStep:

    ; NOTE: All VRAM-modifying code inside this loop must be thread-safe as
    ; it can be interrupted by the VBL handler and it can take a long time
    ; to return control to the simulation loop.

    ld      a,[simulation_disaster_mode]
    and     a,a
    jp      z,RoomGameSimulateStepNormal ; Call one of them and return from it.
    jp      RoomGameSimulateStepDisaster

;-------------------------------------------------------------------------------

RoomGame::

    xor     a,a
    ld      [vbl_handler_working],a
    ld      [simulation_paused],a
    ld      [game_loop_end_requested],a

    ld      a,$FF
    ld      [game_requested_focus_x],a ; disable focus request
    ld      [game_requested_focus_y],a

    xor     a,a
    ld      [game_requested_disaster],a ; disable disaster request

    ld      a,1 ; load everything, not only graphics
    call    RoomGameLoad

    ld      a,1
    ld      [first_simulation_iteration],a

    ; This loop only handles simulation, user input goes in the VBL handler.

    ; Simulation loop
    ; ---------------
    ;
    ; There are a few problems related to this pseudo-multithreading:
    ;
    ; - Some functions need to be protected from interrupts, mainly ROM bank
    ;   switching related.
    ;
    ; - The part of the VBL handler that can be re-entered during another VBL
    ;   processing doesn't modify the VRAM, it only uptades a few registers
    ;   and the OAM (with DMA).
    ;
    ; - In the VBL handler the only functions that modify the VRAM are the
    ;   map scrolling functions, that are thread-safe since they disable
    ;   interrupts in critical periods.
    ;
    ; - During the simulation the VRAM can be modified, and that code must
    ;   be thread-safe (disable interrupts between "wait to screen blank" and
    ;   the actual write).

.main_loop:

    ld      a,[game_loop_end_requested]
    and     a,a ; Check if there is a request to exit the game loop
    jr      nz,.end_game_loop

    ld      a,[simulation_running]
    and     a,a ; Check if simulation has been requested
    jr      z,.skip_simulation

    ld      a,[simulation_paused]
    and     a,a ; Check if the simulation is paused
    jr      nz,.end_simulation_clear_flag

        call    RoomGameSimulateStep

.end_simulation_clear_flag:

    xor     a,a
    ld      [simulation_running],a

    call    CPUBusyIconHide

    jr      .end_simulation

.skip_simulation:

    halt

    ;jr      .end_simulation

.end_simulation:

    jr      .main_loop

    ; End of game loop

.end_game_loop:

    call    SetDefaultVBLHandler

    ret

;###############################################################################
