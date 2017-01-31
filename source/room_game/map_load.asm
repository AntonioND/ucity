;###############################################################################
;
;    uCity - City building game for Game Boy Color.
;    Copyright (C) 2017 Antonio Nino Diaz (AntonioND/SkyLyrac)
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

; Create a new section in ROMX for each map

ADD_SCENARIO_MAP : MACRO ; \1 = label, \2 = file name
    SECTION "\1",ROMX
\1:
    INCBIN  \2
ENDM

    ADD_SCENARIO_MAP    SCENARIO_MAP_0, "predefined_map_0.bin"
    ADD_SCENARIO_MAP    SCENARIO_MAP_1, "predefined_map_1.bin"

;###############################################################################

    SECTION "Map Load Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

    DATA_MONEY_AMOUNT MONEY_AMOUNT_START_20000, 20000
    DATA_MONEY_AMOUNT MONEY_AMOUNT_START_15000,  9000

    STR_ADD "Scenario", SCEN_NAME
    STR_ADD "New Map", NEWMAP_NAME

;-------------------------------------------------------------------------------

SCEN_INFO_1 : MACRO ; \1 = map, \2 = start x, \3 = start y
    DB  \2, \3 ; X, Y
    DB  BANK(\1)
    DW  \1 ; LSB first
ENDM ; 5 bytes in total

; All of the information in this struct should be placed in ROM bank 0
SCEN_INFO_2 : MACRO ; \1=Name, \2=Name length, \3=Year, \4=Month, \5=Money
    DW  \1 ; LSB first
    DB  \2
    DW  \3
    DB  \4
    DW  \5
ENDM ; 8 bytes in total

SCEN_INFO_3 : MACRO ; \1=Technology level
    DB  \1
ENDM ; 1 byte in total

SCENARIO_MAP_INFO:
    SCEN_INFO_1 SCENARIO_MAP_0, (CITY_MAP_WIDTH-20)/2, (CITY_MAP_HEIGHT-18)/2
    SCEN_INFO_2 SCEN_NAME, SCEN_NAME_LEN, $1950,0, MONEY_AMOUNT_START_20000
    SCEN_INFO_3 0

    SCEN_INFO_1 SCENARIO_MAP_1, CITY_MAP_WIDTH-20, CITY_MAP_HEIGHT-18
    SCEN_INFO_2 NEWMAP_NAME, NEWMAP_NAME_LEN, $1975,3, MONEY_AMOUNT_START_15000
    SCEN_INFO_3 10

;-------------------------------------------------------------------------------

SCENARIO_MAP_INFO_GET_INDEX : MACRO ; a = index, returns hl = pointer to info
    ld      l,a
    ld      h,0
    LD_DE_HL
    add     hl,hl
    add     hl,hl
    add     hl,hl ; hl = index * 8

    add     hl,de
    add     hl,de
    add     hl,de
    add     hl,de
    add     hl,de
    add     hl,de ; hl = index * 14

    ld      de,SCENARIO_MAP_INFO
    add     hl,de
ENDM

;-------------------------------------------------------------------------------

; returns de = xy, b = bank of map, hl = pointer to map
ScenarioGetMapPointerAndStartCoordinates:: ; a = number

    SCENARIO_MAP_INFO_GET_INDEX ; a = index, returns hl = pointer to info

    ; Load coordinates

    ld      e,[hl]
    inc     hl
    ld      d,[hl]
    inc     hl

    ; Load pointer and bank

    ld      b,[hl]
    inc     hl

    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ret

;-------------------------------------------------------------------------------

; returns bc = name, a = length (in bank 0)
ScenarioGetMapName:: ; a = number

    SCENARIO_MAP_INFO_GET_INDEX ; a = index, returns hl = pointer to info
    ld      de,5
    add     hl,de ; hl = ptr to info

    ld      c,[hl] ; bc = name
    inc     hl
    ld      b,[hl]
    inc     hl

    ld      a,[hl] ; a = length

    ret

;-------------------------------------------------------------------------------

; returns de = year, a = month, bc = money (in bank 0)
ScenarioGetMapMoneyDate:: ; a = number

    SCENARIO_MAP_INFO_GET_INDEX ; a = index, returns hl = pointer to info
    ld      de,8
    add     hl,de ; hl = ptr to info

    ld      e,[hl] ; de = year
    inc     hl
    ld      d,[hl]
    inc     hl

    ld      a,[hl+] ; a = month

    ld      c,[hl] ; bc = money
    inc     hl
    ld      b,[hl]

    ret

;-------------------------------------------------------------------------------

; returns a = tecnology
ScenarioGetTechnology: ; a = number

    SCENARIO_MAP_INFO_GET_INDEX ; a = index, returns hl = pointer to info
    ld      de,13
    add     hl,de ; hl = ptr to info

    ld      a,[hl]

    ret

;-------------------------------------------------------------------------------

; Setup all variables. Coordinates and map must be handled in other functions.
ScenarioSetupGameVariables: ; a = index

    ; Setup map variables for a scenario

    push    af

        ; returns bc = name, a = length (everything in bank 0)
        call    ScenarioGetMapName ; a = number

        LD_HL_BC
        ld      c,a
        ld      b,0
        ld      de,current_city_name
        call    memcopy ; bc = size    hl = source address    de = dest address

    pop     af
    push    af
        ; returns de = year, a = month, bc = money (everything in bank 0)
        call    ScenarioGetMapMoneyDate ; a = number
        push    bc

            ld      c,a
            call    DateSet ; de = year, c = month

        pop     de
        call    MoneySet ; de = ptr to the amount of money to set

    pop     af

    call    ScenarioGetTechnology ; a = number
    ld      [technology_level],a

    ; TODO - Make all of this parametrizable?

    ld      a,10
    ld      [tax_percentage],a

    xor     a,a
    ld      [LOAN_REMAINING_PAYMENTS],a
    ld      [LOAN_PAYMENTS_AMOUNT+0],a
    ld      [LOAN_PAYMENTS_AMOUNT+1],a

    ; TODO : Allow predefined maps to start with some historical data?

    LONG_CALL   GraphsClearRecords

    ret

;-------------------------------------------------------------------------------

ScenarioLoadMapData: ; b = bank, hl = tiles

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

RandomMapSetupGameVariables:

    ; Setup variables of random maps

    ld      de,MONEY_AMOUNT_START_RANDOM_MAP
    call    MoneySet ; de = ptr to the amount of money to set

    call    DateReset ; January 1950

    ld      a,10
    ld      [tax_percentage],a

    xor     a,a
    ld      [LOAN_REMAINING_PAYMENTS],a
    ld      [LOAN_PAYMENTS_AMOUNT+0],a
    ld      [LOAN_PAYMENTS_AMOUNT+1],a

    xor     a,a
    ld      [technology_level],a

    LONG_CALL   GraphsClearRecords

    ; If random map, the name has been specified before, don't change name here
    ; TODO - Allow the player to change it?

    ret

    DATA_MONEY_AMOUNT MONEY_AMOUNT_START_RANDOM_MAP,20000

;-------------------------------------------------------------------------------

ScenarioAndRandomGameOptionsDefault:

    xor     a,a ; enable disasters, animations and music by default
    ld      [simulation_disaster_disabled],a
    ld      [game_animations_disabled],a
    ld      [game_music_disabled],a

    ret

;-------------------------------------------------------------------------------

CityMapSet::

    ld      [selected_map],a

    ret

;-------------------------------------------------------------------------------

; Load all data and variables for a map specified in selected_map
CityMapLoad:: ; returns de = xy start coordinates

    ld      a,[selected_map]
    cp      a,CITY_MAP_GENERATE_RANDOM
    jr      nz,.not_random

        ; Random map
        ; ----------

        call    RandomMapSetupGameVariables

        call    ScenarioAndRandomGameOptionsDefault

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

        ; Scenarios
        ; ---------

        ld      a,[selected_map]
        and     a,CITY_MAP_NUMBER_MASK
        ; TODO - Check if value is within limits (min and max values)
        ld      [selected_map],a

        ; returns de = xy, b = bank of map, hl = pointer to map
        call    ScenarioGetMapPointerAndStartCoordinates
        push    de ; (***) save coordinates
        call    ScenarioLoadMapData

        ld      a,[selected_map]
        call    ScenarioSetupGameVariables

        call    ScenarioAndRandomGameOptionsDefault

        pop     de ; (***) restore coordinates

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
