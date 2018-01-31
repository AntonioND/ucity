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

    INCLUDE "room_game.inc"
    INCLUDE "save_struct.inc"
    INCLUDE "tileset_info.inc"
    INCLUDE "room_text_input.inc"

;###############################################################################

    SECTION "Save Magic String Bank 0",ROM0

;-------------------------------------------------------------------------------

; Note that MAGIC_STRING_LEN is 4
MAGIC_STRING: DB 66,84,67,89 ; BTCY - Prevent charmap from modifying it

;###############################################################################

    SECTION "SRAM Map Handle Functions",ROMX

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
SRAMCheckBank:: ; B = bank to check. This doesn't check limits.

    ld      a,b

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

CityMapSave:: ; b = SRAM BANK to save the data to, doesn't check limits

    ld      a,b

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

    ld      a,[LOAN_REMAINING_PAYMENTS]
    ld      [SAV_LOAN_REMAINING_PAYMENTS],a
    ld      a,[LOAN_PAYMENTS_AMOUNT+0]
    ld      [SAV_LOAN_PAYMENTS_AMOUNT+0],a
    ld      a,[LOAN_PAYMENTS_AMOUNT+1]
    ld      [SAV_LOAN_PAYMENTS_AMOUNT+1],a

    ld      a,[technology_level]
    ld      [SAV_TECHNOLOGY_LEVEL],a

    ld      a,[negative_budget_count]
    ld      [SAV_NEGATIVE_BUDGET_COUNT],a

    ; Player-set options
    ; ------------------

    ld      a,[simulation_disaster_disabled]
    ld      [SAV_OPTIONS_DISASTERS_DISABLED],a
    ld      a,[game_animations_disabled]
    ld      [SAV_OPTIONS_ANIMATIONS_DISABLED],a
    ld      a,[game_music_disabled]
    ld      [SAV_OPTIONS_MUSIC_DISABLED],a

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

;-------------------------------------------------------------------------------

; Returns de = xy start coordinates
SRAMMapLoad:: ; b = index to load from. This function doesn't check bank limits.

    ; Check save data integrity
    ; -------------------------

    push    bc

    call    SRAMCheckBank ; B = bank to check. This doesn't check limits.

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

    call    SRAMMapLoadBank0

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

    ld      a,[SAV_LOAN_REMAINING_PAYMENTS]
    ld      [LOAN_REMAINING_PAYMENTS],a
    ld      a,[SAV_LOAN_PAYMENTS_AMOUNT+0]
    ld      [LOAN_PAYMENTS_AMOUNT+0],a
    ld      a,[SAV_LOAN_PAYMENTS_AMOUNT+1]
    ld      [LOAN_PAYMENTS_AMOUNT+1],a

    ld      a,[SAV_TECHNOLOGY_LEVEL]
    ld      [technology_level],a

    ld      a,[SAV_NEGATIVE_BUDGET_COUNT]
    ld      [negative_budget_count],a

    ; Player-set options
    ; ------------------

    ld      a,[SAV_OPTIONS_DISASTERS_DISABLED]
    ld      [simulation_disaster_disabled],a
    ld      a,[SAV_OPTIONS_ANIMATIONS_DISABLED]
    ld      [game_animations_disabled],a
    ld      a,[SAV_OPTIONS_MUSIC_DISABLED]
    ld      [game_music_disabled],a

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

;###############################################################################

    SECTION "SRAM Map Handle Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

; Fix position of unpacked bits and set palettes. Part of SRAMMapLoad.
SRAMMapLoadBank0:

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

    ret

;###############################################################################
