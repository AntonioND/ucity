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
    INCLUDE "money.inc"
    INCLUDE "map_load.inc"

;###############################################################################

    SECTION "Map Load Variables",WRAM0

;-------------------------------------------------------------------------------

selected_map: DS 1

;###############################################################################

    SECTION "Predefined Map 0",ROMX

PREDEFINED_MAP_0:
    INCBIN  "data/predefined_map_0.bin"

;###############################################################################

    SECTION "Map Load Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

PREDEFINED_MAP_LIST:
    DB  BANK(PREDEFINED_MAP_0)
    DW  PREDEFINED_MAP_0

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

PredefinedMapGetStartCoordinates: ; a = number, returns de = xy

    ld      hl,PREDEFINED_MAP_INFO
    ld      e,a
    ld      d,0
    add     hl,de
    add     hl,de

    ld      d,[hl]
    inc     hl
    ld      e,[hl]

    ret

PredefinedMapSetupGameVariables:

    ld      de,MONEY_AMOUNT_START
    call    MoneySet ; de = ptr to the amount of money to set

    ret

;-------------------------------------------------------------------------------

    DATA_MONEY_AMOUNT MONEY_AMOUNT_START,20000

;-------------------------------------------------------------------------------

PredefinedMapLoad: ; b = bank, hl = tiles

    ; Load city from ROM into WRAM

    push    hl
    call    rom_bank_push_set
    pop     hl

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

; Returns de = xy start coordinates
SRAMMapLoad: ; a = index to load from. Doesn't check bank limits

    ; Load map and attributes
    push    af ; (*) preserve index

    inc     a
    ld      [rRAMB],a

    ld      a,CART_RAM_ENABLE
    ld      [rRAMG],a

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a
    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    ld      hl,_SRAM+0
    ld      de,CITY_MAP_TILES
    call    memcopy

    ld      a,BANK_CITY_MAP_ATTR
    ld      [rSVBK],a
    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    ld      hl,_SRAM+CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    ld      de,CITY_MAP_ATTR
    call    memcopy

    ld      a,CART_RAM_DISABLE
    ld      [rRAMG],a

    pop     af ; (*) restore index

    ; Load extra information

    ld      de,MONEY_AMOUNT_START
    call    MoneySet ; de = ptr to the amount of money to set

    ; TODO

    ; Return start coordinates
    ld      d,(CITY_MAP_WIDTH-20)/2 ; X
    ld      e,(CITY_MAP_HEIGHT-18)/2 ; Y


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

        ld      b,b ; TODO Generate map here

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
        call    SRAMMapLoad ;  returns de = xy

        jr      .end_map_load

.not_sram:

        ; Predefined map
        ; --------------

        ld      a,[selected_map]
        and     a,CITY_MAP_NUMBER_MASK
        push    af
        call    PredefinedMapGetMapPointer ; a = number
        call    PredefinedMapLoad
        pop     af
        push    af
        call    PredefinedMapSetupGameVariables
        pop     af
        call    PredefinedMapGetStartCoordinates ;  returns de = xy

        jr      .end_map_load

.end_map_load:

    push    de ; (*) save coordinates

    ; Update information from loaded data
    ; -----------------------------------

    ; Clear type map
    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a
    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    ld      d,0
    ld      hl,CITY_MAP_TYPE
    call    memset

    ; Refresh type map from tiles and attributes
    call    CityMapRefreshTypeMap

    pop     de ; (*) get coordinates

    ret

;-------------------------------------------------------------------------------

CityMapSave:: ; a = index to save data to. Doesn't check bank limits

    ; Save map and attributes
    push    af ; (*) preserve index

    inc     a
    ld      [rRAMB],a

    ld      a,CART_RAM_ENABLE
    ld      [rRAMG],a

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a
    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    ld      hl,CITY_MAP_TILES
    ld      de,_SRAM+0
    call    memcopy

    ld      a,BANK_CITY_MAP_ATTR
    ld      [rSVBK],a
    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    ld      hl,CITY_MAP_ATTR
    ld      de,_SRAM+CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    call    memcopy

    ld      a,CART_RAM_DISABLE
    ld      [rRAMG],a

    pop     af ; (*) restore index

    ; Save extra information

    ; TODO

    ret

;###############################################################################
