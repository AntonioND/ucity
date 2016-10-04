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
    INCLUDE "text.inc"
    INCLUDE "room_text_input.inc"

;###############################################################################

    SECTION "Map Load Variables",WRAM0

;-------------------------------------------------------------------------------

current_city_name:: DS TEXT_INPUT_LENGTH+1 ; lenght + 0 terminator

selected_map: DS 1

;###############################################################################

    SECTION "Predefined Map 0",ROMX

;-------------------------------------------------------------------------------

PREDEFINED_MAP_0:
    INCBIN  "data/predefined_map_0.bin"

;###############################################################################

    SECTION "Map Load Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

; Note that MAGIC_STRING_LEN is 4
MAGIC_STRING: DB "BTCY"

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

PREDEFINED_STR_CITY_NAME:
    String2Tiles "S","c","e","n","a","r","i","o",0
PREDEFINED_STR_CITY_LEN EQU String2TilesLenght ; includes string terminator!

PredefinedMapSetupGameVariables:

    ; TODO : Divide this into 2 functions, one for scenarios and other one
    ; for random maps.

    ld      de,MONEY_AMOUNT_START
    call    MoneySet ; de = ptr to the amount of money to set

    call    DateReset

    ld      a,10
    ld      [tax_percentage],a

    xor     a,a ; enable disasters by default
    ld      [simulation_disaster_disabled],a

    ; TODO : Allow predefined maps to start with some historical data?
    LONG_CALL   GraphsClearRecords

    ld      a,[selected_map]
    cp      a,CITY_MAP_GENERATE_RANDOM
    ret     z ; if random map, the name has been specified before

    ld      hl,PREDEFINED_STR_CITY_NAME
    ld      de,current_city_name
    ld      bc,PREDEFINED_STR_CITY_LEN
    call    memcopy ; bc = size    hl = source address    de = dest address

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

SRAMCalculateChecksum: ; Returns HL = checksum of currently enabled SRAM bank

    ; The checksum is calculated as follows (BSD checksum):

    ; u16 sum = 0
    ; u8 * data = &start;
    ; for i = 0 to size
    ;    sum = (sum >> 1) | (sum << 15)
    ;    sum += data[i]

    ld      hl,$0000 ; Checksum accumulator
    ld      de,SAV_CHECKSUM+2 ; pointer to start
    ld      bc,$2000-(SAV_CHECKSUM+2-_SRAM) ; size to check

.loop_checksum:

    ld      a,l ; save lowest bit of hl
    srl     h
    rr      l ; HL = (u16)HL >> 1

    rrca    ; A.7 = A.0
    and     a,$80

    or      a,h
    ld      h,a ; HL = ( (u16)HL >> 1 ) | (L.0 << 15)

    ld      a,[de]
    inc     de ; A = read byte

    add     a,l
    ld      l,a
    ld      a,h
    adc     a,0
    ld      h,a ; HL += (u16)A

    dec     bc
    ld      a,b
    or      a,c
    jr      nz,.loop_checksum

    ret

;-------------------------------------------------------------------------------

; Returns A = 1 if bank is ok, 0 if not. If A = 1, HL will hold the calculated
; checksum.
SRAMCheckBank:: ; A = bank to check. This doesn't check limits.

    ld      [rRAMB],a ; switch to bank

    ld      a,CART_RAM_ENABLE
    ld      [rRAMG],a

    ; First, check magic string

    ld      de,SAV_MAGIC_STRING
    ld      hl,MAGIC_STRING
    ld      c,MAGIC_STRING_LEN
.loop_cmp:
    ld      a,[de]
    cp      a,[hl]
    jr      nz,.exit_fail
    inc     hl
    inc     de
    dec     c
    jr      nz,.loop_cmp

    ; Last, check checksum (magic string and checksum not included in checksum!)

    call    SRAMCalculateChecksum ; HL = calculated checksum

    ld      a,[SAV_CHECKSUM+0]
    cp      a,l
    jr      nz,.exit_fail

    ld      a,[SAV_CHECKSUM+1]
    cp      a,h
    jr      nz,.exit_fail

    ; End. HL should still hold the checksum!

    ld      a,CART_RAM_DISABLE
    ld      [rRAMG],a

    ld      a,1 ; return A = 1, HL = calculated checksum
    ret

.exit_fail:

    ld      a,CART_RAM_DISABLE
    ld      [rRAMG],a

    xor     a,a ; return A = 0
    ret

;-------------------------------------------------------------------------------

; Returns de = xy start coordinates
SRAMMapLoad: ; a = index to load from. This function doesn't check bank limits.

    ; Check save data integrity
    ; -------------------------

    ld      b,a
    push    bc

    call    SRAMCheckBank ; A = bank to check. This doesn't check limits.

    pop     bc

    and     a,a
    ret     z ; if 0, just return!

    ld      a,b

    ; Enable SRAM access
    ; ------------------

    ld      [rRAMB],a ; switch to bank

    ld      a,CART_RAM_ENABLE
    ld      [rRAMG],a

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

    ld      hl,SAV_PERSISTENT_MSG
    call    PersistentMessageDataLoadFrom ; hl = src

    ld      bc,TEXT_INPUT_LENGTH
    ld      hl,SAV_CITY_NAME ; src
    ld      de,current_city_name ; dst
    call    memcopy
    xor     a,a ; save 0 terminator!
    ld      [de],a

    ; Player-set options
    ; ------------------

    ld      a,[SAV_OPTIONS_DISASTERS_DISABLED]
    ld      [simulation_disaster_disabled],a

    ; Historical data
    ; ---------------

    LONG_CALL   GraphsLoadRecords

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

        call    PredefinedMapSetupGameVariables

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

    ; Clear bank
    ; ----------

    ld      d,0
    ld      hl,_SRAM
    ld      bc,$2000
    call    memset ; d = value    hl = start address    bc = size

    ; Save map
    ; --------

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a
    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT
    ld      de,SAV_MAP_TILE_BASE
    ld      hl,CITY_MAP_TILES
    call    memcopy ; bc = size    hl = source address    de = dest address

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

    ld      de,SAV_PERSISTENT_MSG
    call    PersistentMessageDataSaveTo ; de = src

    ld      bc,TEXT_INPUT_LENGTH
    ld      de,SAV_CITY_NAME ; dst
    ld      hl,current_city_name ; src
    call    memcopy

    ; Player-set options
    ; ------------------

    ld      a,[simulation_disaster_disabled]
    ld      [SAV_OPTIONS_DISASTERS_DISABLED],a

    ; Historical data
    ; ---------------

    LONG_CALL   GraphsSaveRecords

    ; Save start coordinates
    ; ----------------------

    ld      a,[bg_x]
    ld      [SAV_LAST_SCROLL_X],a
    ld      a,[bg_y]
    ld      [SAV_LAST_SCROLL_Y],a

    ; Save data integrity checks
    ; --------------------------

    call    SRAMCalculateChecksum ; HL = calculated checksum

    ld      a,l
    ld      [SAV_CHECKSUM+0],a
    ld      a,h
    ld      [SAV_CHECKSUM+1],a

    ; Magic string...

    ld      de,SAV_MAGIC_STRING
    ld      hl,MAGIC_STRING
    ld      bc,MAGIC_STRING_LEN
    call    memcopy ; bc = size    hl = source address    de = dest address

    ; Disable SRAM access
    ; -------------------

    ld      a,CART_RAM_DISABLE
    ld      [rRAMG],a

    ret

;###############################################################################
