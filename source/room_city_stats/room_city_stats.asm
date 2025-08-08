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

    INCLUDE "money.inc"
    INCLUDE "room_game.inc"
    INCLUDE "text.inc"

;###############################################################################

    SECTION "Room City Stats Variables",WRAM0

;-------------------------------------------------------------------------------

total_land_area:       DS 2 ; Area that isn't water (in tiles, LSB first)
developed_land_area:   DS 2 ; Area where there is something built in

city_stats_room_exit:  DS 1 ; set to 1 to exit room

;###############################################################################

    SECTION "Room City Stats Data",ROMX

;-------------------------------------------------------------------------------

CITY_STATS_MENU_BG_MAP:
    INCBIN "city_stats_bg_map.bin"

    DEF CITY_STATS_MENU_WIDTH  EQU 20
    DEF CITY_STATS_MENU_HEIGHT EQU 18

;-------------------------------------------------------------------------------

CityStatsMenuHandle:

    ; Exit if B or START are pressed
    ld      a,[joy_pressed]
    and     a,PAD_B|PAD_START
    jr      z,.end_b_start
        ld      a,1
        ld      [city_stats_room_exit],a
        ret
.end_b_start:

    ld      a,[joy_pressed]
    and     a,PAD_SELECT|PAD_UP|PAD_LEFT|PAD_A
    jr      z,.end_cheat ; Skip if none of them were pressed right now
        ld      a,[joy_held]
        and     a,PAD_SELECT|PAD_UP|PAD_LEFT|PAD_A
        cp      a,PAD_SELECT|PAD_UP|PAD_LEFT|PAD_A
        jr      nz,.end_cheat ; Check if all of them are being held
            ld      de,MONEY_AMOUNT_CHEAT
            call    MoneySet ; de = ptr to the amount of money to set
.end_cheat:

    ret

    DATA_MONEY_AMOUNT MONEY_AMOUNT_CHEAT, 09, 99999999

;-------------------------------------------------------------------------------

RoomCityStatsCalculateLand:

    ; Clear variables

    xor     a,a

    ld      hl,total_land_area
    ld      [hl+],a
    ld      [hl],a
    ld      hl,developed_land_area
    ld      [hl+],a
    ld      [hl],a

    ; Calculate areas

    ld      hl,CITY_MAP_TILES

    ld      a,BANK_CITY_MAP_TYPE
    ldh     [rSVBK],a

.loop:
    push    hl

        ld      a,[hl] ; get complete type with flags
        cp      a,TYPE_WATER
        jr      z,.not_field_or_forest

            ; Land
            ld      hl,total_land_area
            inc     [hl]
            jr      nz,.end_increment_land
            inc     hl
            inc     [hl]
.end_increment_land:

            cp      a,TYPE_FIELD
            jr      z,.not_field_or_forest
                cp      a,TYPE_FOREST
                jr      z,.not_field_or_forest

                    ; Developed Land
                    ld      hl,developed_land_area
                    inc     [hl]
                    jr      nz,.end_increment_developed_land
                    inc     hl
                    inc     [hl]
.end_increment_developed_land:

.not_field_or_forest:

    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

;-------------------------------------------------------------------------------

RoomCityStatsPrintInfo:

    xor     a,a
    ldh     [rVBK],a

    add     sp,-10 ; (*)

    ; Print Name
    ; ----------

    ld      de,$9800+32*3+9 ; de = pointer in VRAM to write to
    LONG_CALL_ARGS  StatusBarMenuDrawCityName

    ; Print population
    ; ----------------

    ; Convert to tile from BCD
    ld      de,city_population ; BCD, LSB first, LSB in lower nibbles
    ld      hl,sp+0
    call    BCD_DE_2TILE_HL_LEADING_SPACES

    ld      b,10
    ld      hl,sp+0
    LD_DE_HL
    ld      hl,$9800+32*4+9
    call    vram_nitro_copy

    ; City class
    ; ----------

    ld      de,$9800+32*5+9 ; pointer to VRAM destination
    call    StatusBarMenuDrawCityClass

    ; Print Date
    ; ----------

    ld      a,[date_year+1] ; LSB first in date_year
    ld      b,a
    ld      a,[date_year+0]
    ld      c,a
    ld      a,[date_month]
    ld      hl,sp+0
    LD_DE_HL ; de = pointer to destination of print (8 chars)
    call    DatePrint

    ld      b,8
    ld      hl,sp+0
    LD_DE_HL
    ld      hl,$9800+32*6+11
    call    vram_nitro_copy

    ; Print money
    ; -----------

    ; Convert to tile from BCD
    ld      de,MoneyWRAM ; BCD, LSB first, LSB in lower nibbles
    ld      hl,sp+0
    call    BCD_SIGNED_DE_2TILE_HL_LEADING_SPACES

    ; Copy to VRAM
    ld      b,10
    ld      hl,sp+0
    LD_DE_HL
    ld      hl,$9800+32*7+9
    call    vram_nitro_copy

    ; Print percentage helper

MACRO PRINT_PERCENTAGE ; hl = percentage (BCD), \3 = ptr to VRAM

    LD_DE_HL ; de = percentage, BCD

    add     sp,-5

        ld      hl,sp+0
        ld      a,e
        ld      [hl+],a
        ld      a,d
        ld      [hl+],a
        xor     a,a
        ld      [hl+],a
        ld      [hl+],a
        ld      [hl+],a

        ld      hl,sp+0
        LD_DE_HL ; de = source
        ld      hl,sp+5 ; hl = dest
        call    BCD_SIGNED_DE_2TILE_HL_LEADING_SPACES

    add     sp,+5

    ; Copy to VRAM
    ld      b,3
    ld      hl,sp+7
    LD_DE_HL
    ld      hl,\1
    call    vram_nitro_copy
ENDM

    ; Developed land
    ; --------------

    ld      hl,developed_land_area
    ld      a,[hl+]
    ld      d,[hl]
    ld      e,a ; de = developed land

    ld      hl,total_land_area
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a ; hl = total land

    call    CalculateAproxPercentBCD ; hl = de * 100 / hl
    PRINT_PERCENTAGE    $9800+32*9+15

    ; Residential developed land / Total developed land
    ; -------------------------------------------------

    ld      hl,residential_area_empty
    ld      a,[hl+]
    ld      d,[hl]
    ld      e,a

    ld      hl,residential_area_used
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,de
    LD_DE_HL ; de = total residential land

    ld      hl,developed_land_area
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a ; hl = developed land

    call    CalculateAproxPercentBCD ; hl = de * 100 / hl
    PRINT_PERCENTAGE    $9800+32*10+15

    ; Commercial developed land / Total developed land
    ; ------------------------------------------------

    ld      hl,commercial_area_empty
    ld      a,[hl+]
    ld      d,[hl]
    ld      e,a

    ld      hl,commercial_area_used
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,de
    LD_DE_HL ; de = total commercial land

    ld      hl,developed_land_area
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a ; hl = developed land

    call    CalculateAproxPercentBCD ; hl = de * 100 / hl
    PRINT_PERCENTAGE    $9800+32*11+15

    ; Industrial developed land / Total developed land
    ; ------------------------------------------------

    ld      hl,industrial_area_empty
    ld      a,[hl+]
    ld      d,[hl]
    ld      e,a

    ld      hl,industrial_area_used
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,de
    LD_DE_HL ; de = total industrial land

    ld      hl,developed_land_area
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a ; hl = developed land

    call    CalculateAproxPercentBCD ; hl = de * 100 / hl
    PRINT_PERCENTAGE    $9800+32*12+15

    ; Traffic
    ; -------

    ld      a,[simulation_traffic_jam_num_tiles_percent]
    call    Byte2BCD ; a = byte, returns hl = BCD (H=MSB, L=LSB)
    PRINT_PERCENTAGE    $9800+32*14+15

    ; Pollution
    ; ---------

    ld      a,[pollution_total_percent]
    call    Byte2BCD ; a = byte, returns hl = BCD (H=MSB, L=LSB)
    PRINT_PERCENTAGE    $9800+32*16+15

    ; End
    ; ---

    add     sp,+10 ; (*)

    ret

;-------------------------------------------------------------------------------

RoomCityStatsMenuLoadBG:

    ; Load border
    ; -----------

    ld      b,BANK(CITY_STATS_MENU_BG_MAP)
    call    rom_bank_push_set

        ; Load map
        ; --------

        ; Tiles
        xor     a,a
        ldh     [rVBK],a

        ld      de,$9800
        ld      hl,CITY_STATS_MENU_BG_MAP

        ld      a,CITY_STATS_MENU_HEIGHT
.loop1:
        push    af

        ld      b,CITY_STATS_MENU_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-CITY_STATS_MENU_WIDTH
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

        ld      a,CITY_STATS_MENU_HEIGHT
.loop2:
        push    af

        ld      b,CITY_STATS_MENU_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-CITY_STATS_MENU_WIDTH
        add     hl,de
        ld      d,h
        ld      e,l
        pop     hl

        pop     af
        dec     a
        jr      nz,.loop2

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

RoomCityStats::

    call    SetPalettesAllBlack

    call    SetDefaultVBLHandler

    xor     a,a
    ldh     [rSCX],a
    ldh     [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ldh     [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    call    RoomCityStatsMenuLoadBG

    call    RoomCityStatsCalculateLand
    call    RoomCityStatsPrintInfo

    call    LoadTextPalette

    xor     a,a
    ld      [city_stats_room_exit],a

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    CityStatsMenuHandle

    ld      a,[city_stats_room_exit]
    and     a,a
    jr      z,.loop

    call    WaitReleasedAllKeys

    call    SetPalettesAllBlack

    ret

;###############################################################################
