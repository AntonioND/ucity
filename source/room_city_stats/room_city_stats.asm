;###############################################################################
;
;    µCity - City building game for Game Boy Color.
;    Copyright (C) 2017 Antonio Niño Díaz (AntonioND/SkyLyrac)
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

city_stats_room_exit:  DS 1 ; set to 1 to exit room

;###############################################################################

    SECTION "Room City Stats Data",ROMX

;-------------------------------------------------------------------------------

CITY_STATS_MENU_BG_MAP:
    INCBIN "city_stats_bg_map.bin"

CITY_STATS_MENU_WIDTH  EQU 20
CITY_STATS_MENU_HEIGHT EQU 18

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
    and     a,PAD_A
    jr      z,.end_a
        ld      de,MONEY_AMOUNT_CHEAT
        call    MoneySet ; de = ptr to the amount of money to set
.end_a:

    ret

    ; TODO - Remove this cheat!

    DATA_MONEY_AMOUNT MONEY_AMOUNT_CHEAT,0999999999

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
        ld      [rVBK],a

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
        ld      [rVBK],a

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
    ld      [rSCX],a
    ld      [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ld      [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    call    RoomCityStatsMenuLoadBG

    ; Print default values

    ; TODO

    ; End of default values

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
