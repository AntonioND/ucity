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
    INCLUDE "money.inc"
    INCLUDE "room_game.inc"
    INCLUDE "save_struct.inc"
    INCLUDE "text.inc"
    INCLUDE "text_messages.inc"
    INCLUDE "room_text_input.inc"

;###############################################################################

    SECTION "Map Load Variables",WRAM0

;-------------------------------------------------------------------------------

current_city_name:: DS TEXT_INPUT_LENGTH+1 ; lenght + 0 terminator

selected_map: DS 1

;###############################################################################

; Create a new section in ROMX for each map

MACRO FILE_SECTION ; \1 = label, \2 = file name
    SECTION "\1",ROMX
\1:
    INCBIN  \2
ENDM

    FILE_SECTION SCENARIO_MAP_0_ROCK_RIVER,  "scenario_0_rock_river_map.bin"
    FILE_SECTION SCENARIO_ATTR_0_ROCK_RIVER, "scenario_0_rock_river_attr.bin"
    FILE_SECTION SCENARIO_MAP_1_BORINGTOWN,  "scenario_1_boringtown_map.bin"
    FILE_SECTION SCENARIO_ATTR_1_BORINGTOWN, "scenario_1_boringtown_attr.bin"
    FILE_SECTION SCENARIO_MAP_2_PORTVILLE,  "scenario_2_portville_map.bin"
    FILE_SECTION SCENARIO_ATTR_2_PORTVILLE, "scenario_2_portville_attr.bin"
    FILE_SECTION SCENARIO_MAP_3_NEWDALE,  "scenario_3_newdale_map.bin"
    FILE_SECTION SCENARIO_ATTR_3_NEWDALE, "scenario_3_newdale_attr.bin"

;###############################################################################

    SECTION "Map Load Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

    DATA_MONEY_AMOUNT MONEY_START_20000, 0, 20000
    DATA_MONEY_AMOUNT MONEY_START_9000, 0, 9000

    STR_ADD "Rock River", ROCK_RIVER_NAME
    STR_ADD "Boringtown", BORINGTOWN_NAME
    STR_ADD "Portville", PORTVILLE_NAME
    STR_ADD "Newdale", NEWDALE_NAME

;-------------------------------------------------------------------------------

MACRO SCEN_INFO_1 ; \1 = map, \2 = attr
    DB  BANK(\1)
    DW  \1 ; LSB first
    DB  BANK(\2)
    DW  \2 ; LSB first
ENDM ; 6 bytes in total

MACRO SCEN_INFO_2 ; \1 = start x, \2 = start y
    DB  \1, \2 ; X, Y
ENDM ; 2 bytes in total

; All of the information in this struct should be placed in ROM bank 0
MACRO SCEN_INFO_3 ; \1=Name, \2=Name length, \3=Year, \4=Month, \5=Money
    DW  \1 ; LSB first
    DB  \2
    DW  \3
    DB  \4
    DW  \5
ENDM ; 8 bytes in total

MACRO SCEN_INFO_4 ; \1=Technology level
    DB  \1
ENDM ; 1 byte in total

MACRO SCEN_INFO_5 ; \1=Flags of permanent msg ID to disable, \2=Same
    DB  (\1)>>1
    DB  (\2)>>(8+1)
ENDM ; 2 bytes in total

IF BYTES_SAVE_PERSISTENT_MSG != 2
    FAIL "map_load.asm: Fix this."
ENDC

SCENARIO_MAP_INFO:
    SCEN_INFO_1 SCENARIO_MAP_0_ROCK_RIVER, SCENARIO_ATTR_0_ROCK_RIVER
    SCEN_INFO_2 14, 33
    SCEN_INFO_3 ROCK_RIVER_NAME, ROCK_RIVER_NAME_LEN, $1950,0, MONEY_START_20000
    SCEN_INFO_4 0
    SCEN_INFO_5 0, (1<<ID_MSG_CLASS_TOWN)|(1<<ID_MSG_CLASS_CITY)

    SCEN_INFO_1 SCENARIO_MAP_1_BORINGTOWN, SCENARIO_ATTR_1_BORINGTOWN
    SCEN_INFO_2 24, 24
    SCEN_INFO_3 BORINGTOWN_NAME, BORINGTOWN_NAME_LEN, $1975,3, MONEY_START_9000
    SCEN_INFO_4 10
    SCEN_INFO_5 0, (1<<ID_MSG_CLASS_TOWN)

    SCEN_INFO_1 SCENARIO_MAP_2_PORTVILLE, SCENARIO_ATTR_2_PORTVILLE
    SCEN_INFO_2 7, 26
    SCEN_INFO_3 PORTVILLE_NAME, PORTVILLE_NAME_LEN, $1960,0, MONEY_START_20000
    SCEN_INFO_4 10
    SCEN_INFO_5 0, (1<<ID_MSG_CLASS_TOWN)|(1<<ID_MSG_CLASS_CITY)

    SCEN_INFO_1 SCENARIO_MAP_3_NEWDALE, SCENARIO_ATTR_3_NEWDALE
    SCEN_INFO_2 22, 23
    SCEN_INFO_3 NEWDALE_NAME, NEWDALE_NAME_LEN, $1950,0, MONEY_START_20000
    SCEN_INFO_4 0
    SCEN_INFO_5 0, (1<<ID_MSG_CLASS_TOWN)|(1<<ID_MSG_CLASS_CITY)

;-------------------------------------------------------------------------------

MACRO SCENARIO_MAP_INFO_GET_INDEX ; a = index, returns hl = pointer to info
    ld      l,a
    ld      h,0
    LD_DE_HL
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl ; hl = index * 16
    add     hl,de
    add     hl,de
    add     hl,de ; hl = index * 19

    ld      de,SCENARIO_MAP_INFO
    add     hl,de
ENDM

;-------------------------------------------------------------------------------

; returns de = xy, b = bank of map, hl = pointer to map
ScenarioGetStartCoordinates:: ; a = number

    SCENARIO_MAP_INFO_GET_INDEX ; a = index, returns hl = pointer to info

    ld      de,6
    add     hl,de

    ; Load coordinates

    ld      d,[hl] ; d = x
    inc     hl
    ld      e,[hl] ; e = y
    inc     hl

    ret

;-------------------------------------------------------------------------------

; returns de = xy, b = bank of map, hl = pointer to map
ScenarioGetMapPointerAndStartCoordinates:: ; a = number

    SCENARIO_MAP_INFO_GET_INDEX ; a = index, returns hl = pointer to info
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

    ld      de,8
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

    ld      de,11
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

    ld      de,16
    add     hl,de ; hl = ptr to info

    ld      a,[hl]

    ret

;-------------------------------------------------------------------------------

; returns a = first byte of flags, b = second byte
ScenarioGetMessageFlags: ; a = number

    SCENARIO_MAP_INFO_GET_INDEX ; a = index, returns hl = pointer to info

    ld      de,17
    add     hl,de ; hl = ptr to info

    ld      a,[hl+]
    ld      b,[hl]

    ret

;-------------------------------------------------------------------------------
; Setup all variables. Coordinates and map must be handled in other functions.
ScenarioSetupGameVariables: ; a = index

    ; Setup map variables for a scenario
    ; ----------------------------------

    ; Load name

    push    af

        ; returns bc = name, a = length (everything in bank 0)
        call    ScenarioGetMapName ; a = number

        LD_HL_BC
        ld      c,a
        ld      b,0
        ld      de,current_city_name
        call    memcopy ; bc = size    hl = source address    de = dest address

    pop     af

    ; Load date and money

    push    af
        ; returns de = year, a = month, bc = money (everything in bank 0)
        call    ScenarioGetMapMoneyDate ; a = number
        push    bc

            ld      c,a
            call    DateSet ; de = year, c = month

        pop     de
        call    MoneySet ; de = ptr to the amount of money to set

    pop     af

    ; Load technology level

    push    af

        call    ScenarioGetTechnology ; a = number
        ld      [technology_level],a

    pop     af

    ; Load persistent message flags

    call    ScenarioGetMessageFlags ; a = number
    ; returns a = first byte of flags, b = second byte
    ld      [persistent_msg_flags+0],a
    ld      a,b
    ld      [persistent_msg_flags+1],a

    ; Non-parametrizable variables
    ; ----------------------------

    ld      a,10
    ld      [tax_percentage],a

    xor     a,a
    ld      [negative_budget_count],a

    xor     a,a
    ld      [LOAN_REMAINING_PAYMENTS],a
    ld      [LOAN_PAYMENTS_AMOUNT+0],a
    ld      [LOAN_PAYMENTS_AMOUNT+1],a

    ; Clear historical data

    LONG_CALL   GraphsClearRecords

    ret

;-------------------------------------------------------------------------------

ScenarioLoadMapData:: ; a = index

    SCENARIO_MAP_INFO_GET_INDEX ; a = index, returns hl = pointer to info

    ld      a,[hl+]
    ld      b,a ; b = map bank
    ld      a,[hl+]
    ld      e,a
    ld      a,[hl+]
    ld      d,a ; de = map ptr

    ld      a,[hl+]
    ld      c,a ; c = attr bank
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a ; hl = attr ptr

    push    bc
    push    hl ; (*)

    call    rom_bank_push_set ; b = bank, preserves de

    ; Load city from ROM into WRAM

    ld      a,BANK_CITY_MAP_TILES
    ldh     [rSVBK],a

    LD_HL_DE
    ld      bc,CITY_MAP_TILES
    call    RLE_Uncompress ; hl = src, bc = dst. Returns de = siz
    ld      hl,CITY_MAP_TILES
    call    Diff_Uncompress ; hl = src = dst, de = size


    pop     de ; (*) pop from hl
    pop     bc

    ld      b,c
    call    rom_bank_set ; b = bank, preserves de

    ld      a,BANK_CITY_MAP_ATTR
    ldh     [rSVBK],a

    LD_HL_DE
    ld      bc,CITY_MAP_ATTR
    call    RLE_Uncompress ; hl = src, bc = dst. Returns the size in DE
    ld      hl,CITY_MAP_ATTR
    call    Diff_Uncompress ; hl = src = dst, de = size

    call    CityMapRefreshAttributeMap

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
    ld      [negative_budget_count],a

    LONG_CALL   GraphsClearRecords

    ; If random map, the name has been specified before, don't change name here
    ; TODO - Allow the player to change it?

    ret

    DATA_MONEY_AMOUNT MONEY_AMOUNT_START_RANDOM_MAP, 0, 20000

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

        ; The value of selected_map is set in the room that selects scenarios so
        ; it is supposed to be within valid bounds

        ld      a,[selected_map]
        call    ScenarioLoadMapData

        ld      a,[selected_map]
        call    ScenarioSetupGameVariables

        call    ScenarioAndRandomGameOptionsDefault

        ld      a,[selected_map]
        call    ScenarioGetStartCoordinates ; de = coordinates

        jr      .end_map_load

.end_map_load:

    push    de ; (*) save coordinates

    ; Update information from loaded data
    ; -----------------------------------

    ; Clear type map
    ld      a,BANK_CITY_MAP_TYPE
    ldh     [rSVBK],a
    call    ClearWRAMX

    ; Refresh type map from tiles and attributes
    call    CityMapRefreshTypeMap

    pop     de ; (*) get coordinates

    ret

;###############################################################################
