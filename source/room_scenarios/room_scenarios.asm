;###############################################################################
;
;    µCity - City building game for Game Boy Color.
;    Copyright (c) 2017-2018 Antonio Niño Díaz (AntonioND/SkyLyrac)
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

    INCLUDE "map_load.inc"
    INCLUDE "room_game.inc"
    INCLUDE "room_text_input.inc"
    INCLUDE "text.inc"
    INCLUDE "tileset_info.inc"

;###############################################################################

    SECTION "Room Scenarios Variables",WRAM0

;-------------------------------------------------------------------------------

scenario_select_room_exit: DS 1 ; set to 1 to exit room

scenario_select_map_selection:: DS 1 ; $FF for invalid value

;###############################################################################

    SECTION "Room Scenarios Code Data",ROMX

;-------------------------------------------------------------------------------

SCENARIO_SELECT_BG_MAP:
    INCBIN "map_scenario_select_bg_map.bin"

    DEF SCENARIO_SELECT_WIDTH  EQU 20
    DEF SCENARIO_SELECT_HEIGHT EQU 18

;-------------------------------------------------------------------------------

RoomScenarioSelectRefresh:

    call    RoomScenarioSelectRefreshMinimap
    call    RoomScenarioSelectRefreshText

    ret

;-------------------------------------------------------------------------------

RoomScenarioSelectRefreshText:

    xor     a,a
    ldh     [rVBK],a

    ; Print name of the city
    ; ----------------------

    ; Clear

    ld      bc,TEXT_INPUT_LENGTH
    ld      d,O_SPACE
    ld      hl,$9800+32*3+9
    call    vram_memset ; bc = size    d = value    hl = dest address

    ; Print

    ld      a,[scenario_select_map_selection]
    call    ScenarioGetMapName ; a = number
    ; returns bc = name, a = length (in bank 0)

    push    af
    ld      d,a
    ld      a,TEXT_INPUT_LENGTH+1
    sub     a,d
    ld      e,a
    ld      d,0
    ld      hl,$9800+3*32+9
    add     hl,de
    LD_DE_HL ; dest
    LD_HL_BC ; src
    pop     af
    ld      b,a
    dec     b
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    ; Print money and date
    ; --------------------

    ld      a,[scenario_select_map_selection]
    call    ScenarioGetMapMoneyDate ; a = number
    ; returns de = year, a = month, bc = money (in bank 0)

    add     sp,-10 ; (*) allocate space for the converted string

        push    af
        push    de

            LD_DE_BC
            ld      hl,sp+4
            call    BCD_DE_2TILE_HL_LEADING_SPACES

            ld      b,10
            ld      de,$9800+4*32+9
            ld      hl,sp+4
            call    vram_copy_fast ; b = size - hl = source address - de = dest

        pop     de
        pop     af

        LD_BC_DE
        ld      hl,sp+0
        LD_DE_HL
        call    DatePrint ; bc = year, a = month, de = destination

        ld      b,8
        ld      hl,sp+0
        ld      de,$9800+5*32+11
        call    vram_copy_fast ; b = size - hl = source address - de = dest

    add     sp,+10 ; (*) reclaim space

    ret

;-------------------------------------------------------------------------------

InputHandleScenarioSelect:

    ld      a,[joy_pressed]
    and     a,PAD_RIGHT
    jr      z,.end_right
        ld      a,[scenario_select_map_selection]
        inc     a
        cp      a,SCENARIOS_TOTAL_NUM
        jr      nz,.skip_right_reset
            xor     a,a
.skip_right_reset:
        ld      [scenario_select_map_selection],a

        di ; Entering critical section

        ld      b,$91
        call    wait_ly

        ld      hl,MINIMAP_PALETTE_BLACK
        call    APA_LoadPalette

        ei ; End of critical section

        call    RoomScenarioSelectRefresh
.end_right:

    ld      a,[joy_pressed]
    and     a,PAD_LEFT
    jr      z,.end_left
        ld      a,[scenario_select_map_selection]
        dec     a
        cp      a,-1
        jr      nz,.skip_left_reset
            ld      a,SCENARIOS_TOTAL_NUM-1
.skip_left_reset:
        ld      [scenario_select_map_selection],a

        di ; Entering critical section

        ld      b,$91
        call    wait_ly

        ld      hl,MINIMAP_PALETTE_BLACK
        call    APA_LoadPalette

        ei ; End of critical section

        call    RoomScenarioSelectRefresh
.end_left:

    ld      a,[joy_pressed]
    and     a,PAD_A|PAD_START
    jr      z,.end_a_start

        ld      a,1
        ld      [scenario_select_room_exit],a

        ret
.end_a_start:

    ld      a,[joy_pressed]
    and     a,PAD_B
    jr      z,.end_b

        ld      a,$FF ; set invalid value
        ld      [scenario_select_map_selection],a

        ld      a,1
        ld      [scenario_select_room_exit],a

        ret
.end_b:

    ret

;-------------------------------------------------------------------------------

RoomScenarioSelectLoadBG:

    ; Load border
    ; -----------

    ld      b,BANK(SCENARIO_SELECT_BG_MAP)
    call    rom_bank_push_set

        ; Load map
        ; --------

        ; Tiles
        xor     a,a
        ldh     [rVBK],a

        ld      de,$9800
        ld      hl,SCENARIO_SELECT_BG_MAP

        ld      a,SCENARIO_SELECT_HEIGHT
.loop1:
        push    af

        ld      b,SCENARIO_SELECT_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-SCENARIO_SELECT_WIDTH
        add     hl,de
        ld      d,h
        ld      e,l
        pop     hl

        pop     af
        dec     a
        jr      nz,.loop1

        ; Attributes
        ld      a,1
        ldh     [rVBK],a

        ld      de,$9800

        ld      a,SCENARIO_SELECT_HEIGHT
.loop2:
        push    af

        ld      b,SCENARIO_SELECT_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-SCENARIO_SELECT_WIDTH
        add     hl,de
        ld      d,h
        ld      e,l
        pop     hl

        pop     af
        dec     a
        jr      nz,.loop2

    call    rom_bank_pop

    ; Clear minimap

    ld      hl,MINIMAP_PALETTE_BLACK
    call    APA_LoadPalette

    LONG_CALL   APA_BufferClear

    call    APA_BufferUpdate

    ret

;-------------------------------------------------------------------------------

RoomScenarioSelect::

    call    SetPalettesAllBlack

    call    SetDefaultVBLHandler

    xor     a,a
    ld      [scenario_select_map_selection],a

    xor     a,a
    ldh     [rSCX],a
    ldh     [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ldh     [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    call    RoomScenarioSelectLoadBG

    xor     a,a
    ld      [scenario_select_room_exit],a

    call    RoomScenarioSelectRefresh

    call    LoadTextPalette

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleScenarioSelect

    ld      a,[scenario_select_room_exit]
    and     a,a
    jr      z,.loop

    call    WaitReleasedAllKeys

    call    SetPalettesAllBlack

    ld      a,[scenario_select_map_selection]
    cp      a,$FF
    jr      z,.invalid_map

        ld      a,1 ; return valid map
        ret

.invalid_map:

    xor     a,a ; return invalid map
    ret

;###############################################################################

    SECTION "Room Scenarios Code Bank 0",ROM0

;-------------------------------------------------------------------------------

    DEF C_GREY EQU 0
    DEF C_GREEN EQU 1
    DEF C_BLUE  EQU 2
    DEF C_WHITE EQU 3

MINIMAP_PALETTE_BLACK:
    DW  0, 0, 0, 0

MINIMAP_PALETTE_WHITE:
    DW  0, 0, 0, 0

MINIMAP_PALETTE: ; GREY, GREEN, BLUE, WHITE
    DW  (10<<10)|(10<<5)|10, 31<<5, 31<<10, (31<<10)|(31<<5)|31

MINIMAP_TYPE_COLOR_ARRAY:
    DB C_WHITE ; TYPE_FIELD
    DB C_GREEN ; TYPE_FOREST
    DB C_BLUE  ; TYPE_WATER
    DB C_GREY  ; TYPE_RESIDENTIAL
    DB C_GREY  ; TYPE_INDUSTRIAL
    DB C_GREY  ; TYPE_COMMERCIAL
    DB C_GREY  ; TYPE_POLICE_DEPT
    DB C_GREY  ; TYPE_FIRE_DEPT
    DB C_GREY  ; TYPE_HOSPITAL
    DB C_GREEN ; TYPE_PARK
    DB C_GREY  ; TYPE_STADIUM
    DB C_GREY  ; TYPE_SCHOOL
    DB C_GREY  ; TYPE_HIGH_SCHOOL
    DB C_GREY  ; TYPE_UNIVERSITY
    DB C_GREY  ; TYPE_MUSEUM
    DB C_GREY  ; TYPE_LIBRARY
    DB C_GREY  ; TYPE_AIRPORT
    DB C_GREY  ; TYPE_PORT
    DB C_GREY  ; TYPE_DOCK
    DB C_GREY  ; TYPE_POWER_PLANT
    DB C_GREY  ; TYPE_FIRE - Placeholder, never used.
    DB C_GREY  ; TYPE_RADIATION

RoomScenarioSelectRefreshMinimap:

    ; Uncompress map
    ld      a,[scenario_select_map_selection]
    call    ScenarioLoadMapData ; a = index

    ; Prepare bank to get tile type
    ld      b,BANK(TILESET_INFO)
    call    rom_bank_push_set

    LONG_CALL   APA_BufferClear
    LONG_CALL   APA_PixelStreamStart

    ld      de,CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    ld      hl,CITY_MAP_TILES

.loop:

    push    de
    push    hl

        ; Get tile

        ld      a,BANK_CITY_MAP_TILES
        ldh     [rSVBK],a

        ld      d,0
        ld      e,[hl]

        ld      a,BANK_CITY_MAP_ATTR
        ldh     [rSVBK],a

        bit     3,[hl]
        jr      z,.dont_set
        inc     d ; get bank bit
.dont_set:

        ; Get tile type

IF TILESET_INFO_ELEMENT_SIZE != 4
    FAIL "room_scenarios.asm: Fix this!"
ENDC

        ld      hl,TILESET_INFO + 1 ; point to attributes
        add     hl,de ; Use full 9 bit tile number to access the array.
        add     hl,de ; hl points to the palette + bank1 bit
        add     hl,de ; Tile number * 4
        add     hl,de

        ld      a,[hl]
        and     a,TYPE_MASK
        ld      e,a
        ld      d,0 ; de = type

        ; Get color assigned for that type

        ld      hl,MINIMAP_TYPE_COLOR_ARRAY
        add     hl,de

        ld      a,[hl]
        call    APA_SetColor0

        LONG_CALL   APA_64x64PixelStreamPlot

    pop     hl
    pop     de

    inc     hl
    dec     de
    ld      a,d
    or      a,e
    jr      nz,.loop

    call    APA_BufferUpdate

    ld      hl,MINIMAP_PALETTE
    call    APA_LoadPalette

    call    rom_bank_pop ; (*) restore bank

    ret

;###############################################################################
