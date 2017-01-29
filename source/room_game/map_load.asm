;###############################################################################
;
;    BitCity - City building game for Game Boy Color.
;    Copyright (C) 2016-2017 Antonio Nino Diaz (AntonioND/SkyLyrac)
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
    INCLUDE "money.inc"
    INCLUDE "room_game.inc"
    INCLUDE "save_struct.inc"
    INCLUDE "text.inc"
    INCLUDE "room_text_input.inc"

;###############################################################################

    SECTION "Map Load Variables",WRAM0

;-------------------------------------------------------------------------------

current_city_name:: DS TEXT_INPUT_LENGTH+1 ; lenght + 0 terminator

selected_map: DS 1

;###############################################################################

    SECTION "Predefined Map 0",ROMX

PREDEFINED_MAP_0:
    INCBIN  "predefined_map_0.bin"

;-------------------------------------------------------------------------------

    SECTION "Predefined Map 1",ROMX

PREDEFINED_MAP_1:
    INCBIN  "predefined_map_1.bin"

;###############################################################################

    SECTION "Map Load Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

; Note that MAGIC_STRING_LEN is 4
MAGIC_STRING: DB 66,84,67,89 ; BTCY - Prevent charmap from modifying it

;-------------------------------------------------------------------------------

PREDEFINED_MAP_LIST:
    DB  BANK(PREDEFINED_MAP_0)
    DW  PREDEFINED_MAP_0
    DB  BANK(PREDEFINED_MAP_1)
    DW  PREDEFINED_MAP_1

PredefinedMapGetMapPointer: ; a = number

    ld      hl,PREDEFINED_MAP_LIST
    ld      e,a
    ld      d,0
    add     hl,de
    add     hl,de
    add     hl,de

    ld      b,[hl]
    inc     hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ret

;-------------------------------------------------------------------------------

PREDEFINED_MAP_INFO:
    DB  (CITY_MAP_WIDTH-20)/2, (CITY_MAP_HEIGHT-18)/2
    DB  CITY_MAP_WIDTH-20, CITY_MAP_HEIGHT-18

PredefinedMapGetStartCoordinates: ; a = number, returns de = xy

    ; This function returns the start coordinates of scenarios, random maps are
    ; always shown at the centre of the screen, it is not done here.

    ld      hl,PREDEFINED_MAP_INFO
    ld      e,a
    ld      d,0
    add     hl,de
    add     hl,de

    ld      d,[hl]
    inc     hl
    ld      e,[hl]

    ret

;-------------------------------------------------------------------------------

    ; TODO - Different amounts of money and names per city

    STR_ADD "Scenario", PREDEFINED_STR_CITY_NAME
    DATA_MONEY_AMOUNT MONEY_AMOUNT_START_SCENARIO,20000

; Setup all variables. Coordinates and map must be handled in other functions.
PredefinedMapSetupGameVariables:

    ; Setup map variables for a scenario

    ld      de,MONEY_AMOUNT_START_SCENARIO
    call    MoneySet ; de = ptr to the amount of money to set

    call    DateReset

    ld      a,10
    ld      [tax_percentage],a

    xor     a,a
    ld      [LOAN_REMAINING_PAYMENTS],a
    ld      [LOAN_PAYMENTS_AMOUNT+0],a
    ld      [LOAN_PAYMENTS_AMOUNT+1],a

    xor     a,a
    ld      [technology_level],a

    xor     a,a ; enable disasters, animations and music by default
    ld      [simulation_disaster_disabled],a
    ld      [game_animations_disabled],a
    ld      [game_music_disabled],a

    ; TODO : Allow predefined maps to start with some historical data?
    LONG_CALL   GraphsClearRecords

    ; TODO - Allow to change the name instead of using the default one?

    ld      hl,PREDEFINED_STR_CITY_NAME
    ld      de,current_city_name
    ld      bc,PREDEFINED_STR_CITY_NAME_LEN
    call    memcopy ; bc = size    hl = source address    de = dest address

    ret

;-------------------------------------------------------------------------------

    DATA_MONEY_AMOUNT MONEY_AMOUNT_START_RANDOM_MAP,20000

RandomMapSetupGameVariables:

    ; Setup variables of random maps

    ld      de,MONEY_AMOUNT_START_RANDOM_MAP
    call    MoneySet ; de = ptr to the amount of money to set

    call    DateReset

    ld      a,10
    ld      [tax_percentage],a

    xor     a,a
    ld      [LOAN_REMAINING_PAYMENTS],a
    ld      [LOAN_PAYMENTS_AMOUNT+0],a
    ld      [LOAN_PAYMENTS_AMOUNT+1],a

    xor     a,a
    ld      [technology_level],a

    xor     a,a ; enable disasters, animations and music by default
    ld      [simulation_disaster_disabled],a
    ld      [game_animations_disabled],a
    ld      [game_music_disabled],a

    LONG_CALL   GraphsClearRecords

    ; If random map, the name has been specified before, don't change name here

    ret

;-------------------------------------------------------------------------------

PredefinedMapLoad: ; b = bank, hl = tiles

    ; Load city from ROM into WRAM

    LD_DE_HL
    call    rom_bank_push_set ; preserves de
    LD_HL_DE

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a
    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    ;ld      hl,MAP
    ld      de,CITY_MAP_TILES
    call    memcopy

    ld      a,BANK_CITY_MAP_ATTR
    ld      [rSVBK],a
    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    ;ld      hl,MAP+CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    ld      de,CITY_MAP_ATTR
    call    memcopy

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

CityMapSet::

    ld      [selected_map],a

    ret

;-------------------------------------------------------------------------------

CityMapLoad:: ; returns de = xy start coordinates

    ld      a,[selected_map]
    cp      a,CITY_MAP_GENERATE_RANDOM
    jr      nz,.not_random

        ; Random map
        ; ----------

        call    RandomMapSetupGameVariables

        ld      d,(CITY_MAP_WIDTH-20)/2 ; X
        ld      e,(CITY_MAP_HEIGHT-18)/2 ; Y

        jr      .end_map_load

.not_random:

    and     a,CITY_MAP_SRAM_FLAG
    jr      z,.not_sram

        ; SRAM map
        ; --------

        ld      a,[selected_map]
        and     a,CITY_MAP_NUMBER_MASK
        ld      b,a ; b = bank to load
        LONG_CALL_ARGS  SRAMMapLoad ;  returns de = xy

        jr      .end_map_load

.not_sram:

        ; Predefined map
        ; --------------

        ld      a,[selected_map]
        and     a,CITY_MAP_NUMBER_MASK
        ; TODO - Check if value is within limits (min and max values)
        ld      [selected_map],a

        call    PredefinedMapGetMapPointer ; a = number
        call    PredefinedMapLoad

        ld      a,[selected_map]
        call    PredefinedMapSetupGameVariables

        ld      a,[selected_map]
        call    PredefinedMapGetStartCoordinates ;  returns de = xy

        jr      .end_map_load

.end_map_load:

    push    de ; (*) save coordinates

    ; Update information from loaded data
    ; -----------------------------------

    ; Clear type map
    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a
    call    ClearWRAMX

    ; Refresh type map from tiles and attributes
    call    CityMapRefreshTypeMap

    pop     de ; (*) get coordinates

    ret

;###############################################################################
