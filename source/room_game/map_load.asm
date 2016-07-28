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

    INCLUDE "map_load.inc"
    INCLUDE "money.inc"
    INCLUDE "room_game.inc"
    INCLUDE "save_struct.inc"
    INCLUDE "tileset_info.inc"

;###############################################################################

    SECTION "Map Load Variables",WRAM0

;-------------------------------------------------------------------------------

selected_map: DS 1

;###############################################################################

    SECTION "Predefined Map 0",ROMX

;-------------------------------------------------------------------------------

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

    call    DateReset

    ld      a,10
    ld      [tax_percentage],a

    ret

;-------------------------------------------------------------------------------

    DATA_MONEY_AMOUNT MONEY_AMOUNT_START,20000

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

; Returns de = xy start coordinates
SRAMMapLoad: ; a = index to load from. Doesn't check bank limits

    ; Enable SRAM access
    ; ------------------

    ld      [rRAMB],a ; switch to bank

    ld      a,CART_RAM_ENABLE
    ld      [rRAMG],a

    ; Check save data integrity
    ; -------------------------

    ; TODO - Check SAV_MAGIC_STRING, SAV_CHECKSUM

    ; Load map
    ; --------

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a
    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    ld      hl,SAV_MAP_TILE_BASE
    ld      de,CITY_MAP_TILES
    call    memcopy

    ; Load attributes
    ; ---------------

    ; Unpack bits

    ld      a,BANK_CITY_MAP_ATTR
    ld      [rSVBK],a

    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT/8 ; size/8
    ld      hl,CITY_MAP_ATTR ; dst
    ld      de,SAV_MAP_ATTR_BASE ; src of high bit

.loop_unpack:

        ld      a,[de]
        inc     de

        REPT    8
            ld      [hl+],a ; save all bits, not only the lowest one
            rrca ; it will be masked out in the following loop
        ENDR

    dec     bc
    ld      a,b
    or      a,c
    jr      nz,.loop_unpack

    ; Fix position of unpacked bits and set palettes

    push    hl
    GLOBAL  TILESET_INFO
    ld      b,BANK(TILESET_INFO)
    call    rom_bank_push_set ; (*)
    pop     hl

    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT ; size
    ld      hl,CITY_MAP_TILES ; src of tiles

.loop_fix:

        ld      a,BANK_CITY_MAP_TILES
        ld      [rSVBK],a

        ld      e,[hl]

        ld      a,BANK_CITY_MAP_ATTR
        ld      [rSVBK],a

        ld      a,[hl]
        and     a,1
        ld      d,a

        ; de = tile number up to 512

        push    hl

            ld      hl,TILESET_INFO
            add     hl,de ; Use full 9 bit tile number to access the array.
            add     hl,de ; hl points to the palette + bank1 bit
            add     hl,de ; Tile number * 4
            add     hl,de

            IF TILESET_INFO_ELEMENT_SIZE != 4
                FAIL "draw_city_map.asm: Fix this!"
            ENDC

            ld      d,[hl] ; d holds the palette + bank1 bit

        pop     hl

        ld      a,d
        ld      [hl+],a

    dec     bc
    ld      a,b
    or      a,c
    jr      nz,.loop_fix

    call    rom_bank_pop ; (*)

    ; Load extra information
    ; ----------------------

    ld      de,SAV_MONEY
    call    MoneySet ; de = ptr to the amount of money to set

    ld      a,[SAV_YEAR+0]
    ld      [date_year+0],a
    ld      a,[SAV_YEAR+1]
    ld      [date_year+1],a
    ld      a,[SAV_MONTH]
    ld      [date_month],a

    ld      a,[SAV_TAX_PERCENT]
    ld      [tax_percentage],a

    ; Return start coordinates
    ; ------------------------

    ld      a,[SAV_LAST_SCROLL_X]
    ld      d,a ; X
    ld      a,[SAV_LAST_SCROLL_Y]
    ld      e,a ; Y

    ; Disable SRAM access
    ; -------------------

    ld      a,CART_RAM_DISABLE
    ld      [rRAMG],a

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
    call    ClearWRAMX

    ; Refresh type map from tiles and attributes
    call    CityMapRefreshTypeMap

    pop     de ; (*) get coordinates

    ret

;-------------------------------------------------------------------------------

CityMapSave:: ; a = index to save data to. Doesn't check bank limits

    ; Enable SRAM access
    ; ------------------

    ld      [rRAMB],a ; switch to bank

    ld      a,CART_RAM_ENABLE
    ld      [rRAMG],a

    ; Save map
    ; --------

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a
    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    ld      de,SAV_MAP_TILE_BASE
    ld      hl,CITY_MAP_TILES
    call    memcopy

    ; Save attributes
    ; ---------------

    ; Pack bits

    ld      a,BANK_CITY_MAP_ATTR
    ld      [rSVBK],a

    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT/8 ; size/8
    ld      hl,CITY_MAP_ATTR ; src
    ld      de,SAV_MAP_ATTR_BASE ; dst

.loop_pack:

        push    bc

        ld      b,0
        REPT    8
            ld      a,[hl+]
            and     a,%00001000 ; get only the 9th bit
            rrca
            rrca
            rrca
            or      a,b
            rrca ; prepare for next bit
            ld      b,a
        ENDR

        pop     bc

        ld      [de],a
        inc     de

    dec     bc
    ld      a,b
    or      a,c
    jr      nz,.loop_pack

    ; Save extra information
    ; ----------------------

    ld      de,SAV_MONEY
    call    MoneyGet ; de = ptr to store the current amount of money

    ld      a,[date_year+0]
    ld      [SAV_YEAR+0],a
    ld      a,[date_year+1]
    ld      [SAV_YEAR+1],a
    ld      a,[date_month]
    ld      [SAV_MONTH],a

    ld      a,[tax_percentage]
    ld      [SAV_TAX_PERCENT],a

    ; Return start coordinates
    ; ------------------------

    ld      a,[bg_x]
    ld      [SAV_LAST_SCROLL_X],a
    ld      a,[bg_y]
    ld      [SAV_LAST_SCROLL_Y],a

    ; Save data integrity checks
    ; --------------------------

    ; TODO - Save SAV_MAGIC_STRING, SAV_CHECKSUM

    ; Disable SRAM access
    ; -------------------

    ld      a,CART_RAM_DISABLE
    ld      [rRAMG],a

    ret

;###############################################################################
