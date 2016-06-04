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

;###############################################################################

    SECTION "Simulation Calculate Statistics Variables",WRAM0

;-------------------------------------------------------------------------------

city_population:: DS 5 ; LSB first!
city_population_temp: DS 5 ; LSB first!

;###############################################################################

    SECTION "Simulation Calculate Statistics Functions",ROMX[$4000]

;-------------------------------------------------------------------------------

; Must be alligned to a $100 byte boundary
BINARY_TO_BCD: ; 2 bytes per entry. LSB first
    DB 00,00, 01,00, 02,00, 03,00, 04,00, 05,00, 06,00, 07,00
    DB 08,00, 09,00, 10,00, 11,00, 12,00, 13,00, 14,00, 15,00
    DB 16,00, 17,00, 18,00, 19,00, 20,00, 21,00, 22,00, 23,00
    DB 24,00, 25,00, 26,00, 27,00, 28,00, 29,00, 30,00, 31,00
    DB 32,00, 33,00, 34,00, 35,00, 36,00, 37,00, 38,00, 39,00
    DB 40,00, 41,00, 42,00, 43,00, 44,00, 45,00, 46,00, 47,00
    DB 48,00, 49,00, 50,00, 51,00, 52,00, 53,00, 54,00, 55,00
    DB 56,00, 57,00, 58,00, 59,00, 60,00, 61,00, 62,00, 63,00
    DB 64,00, 65,00, 66,00, 67,00, 68,00, 69,00, 70,00, 71,00
    DB 72,00, 73,00, 74,00, 75,00, 76,00, 77,00, 78,00, 79,00
    DB 80,00, 81,00, 82,00, 83,00, 84,00, 85,00, 86,00, 87,00
    DB 88,00, 89,00, 90,00, 91,00, 92,00, 93,00, 94,00, 95,00
    DB 96,00, 97,00, 98,00, 99,00, 00,01, 01,01, 02,01, 03,01
    DB 04,01, 05,01, 06,01, 07,01, 08,01, 09,01, 10,01, 11,01
    DB 12,01, 13,01, 14,01, 15,01, 16,01, 17,01, 18,01, 19,01
    DB 20,01, 21,01, 22,01, 23,01, 24,01, 25,01, 26,01, 27,01
    DB 28,01, 29,01, 30,01, 31,01, 32,01, 33,01, 34,01, 35,01
    DB 36,01, 37,01, 38,01, 39,01, 40,01, 41,01, 42,01, 43,01
    DB 44,01, 45,01, 46,01, 47,01, 48,01, 49,01, 50,01, 51,01
    DB 52,01, 53,01, 54,01, 55,01, 56,01, 57,01, 58,01, 59,01
    DB 60,01, 61,01, 62,01, 63,01, 64,01, 65,01, 66,01, 67,01
    DB 68,01, 69,01, 70,01, 71,01, 72,01, 73,01, 74,01, 75,01
    DB 76,01, 77,01, 78,01, 79,01, 80,01, 81,01, 82,01, 83,01
    DB 84,01, 85,01, 86,01, 87,01, 88,01, 89,01, 90,01, 91,01
    DB 92,01, 93,01, 94,01, 95,01, 96,01, 97,01, 98,01, 99,01
    DB 00,02, 01,02, 02,02, 03,02, 04,02, 05,02, 06,02, 07,02
    DB 08,02, 09,02, 10,02, 11,02, 12,02, 13,02, 14,02, 15,02
    DB 16,02, 17,02, 18,02, 19,02, 20,02, 21,02, 22,02, 23,02
    DB 24,02, 25,02, 26,02, 27,02, 28,02, 29,02, 30,02, 31,02
    DB 32,02, 33,02, 34,02, 35,02, 36,02, 37,02, 38,02, 39,02
    DB 40,02, 41,02, 42,02, 43,02, 44,02, 45,02, 46,02, 47,02
    DB 48,02, 49,02, 50,02, 51,02, 52,02, 53,02, 54,02, 55,02

;-------------------------------------------------------------------------------

Simulation_CalculateStatistics::

    ; Clear variables

    xor     a,a
    ld      hl,city_population_temp
    REPT    5
    ld      [hl+],a
    ENDR

    ; Calculate

    ld      hl,CITY_MAP_TILES

.loop:
    push    hl

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

        ld      a,[hl] ; get type
        and     a,TYPE_MASK ; without flags!

        cp      a,TYPE_FIELD
        jr      z,.skip
        cp      a,TYPE_FOREST
        jr      z,.skip
        cp      a,TYPE_WATER
        jr      z,.skip
        cp      a,TYPE_DOCK
        jr      z,.skip

        ; Returns: Tile -> Register DE
        ; Arguments: hl = address. Preserves BC and HL
        call    CityMapGetTileAtAddress

        push    de
        ; de = tile number, returns a = 1 if it is the origin of a building
        call    BuildingIsTileCoordinateOrigin
        pop     de

        and     a,a
        jr      z,.skip ; not the origin of the building, already handled

        call    CityTileDensity ; de = tile, returns d=population

        ld      l,d
        ld      h,BINARY_TO_BCD>>8 ; 2 bytes per entry. LSB first

        ld      a,[hl+]
        ld      b,[hl]
        ld      c,a ; bc = population in bcd

        ld      hl,city_population_temp
        ld      e,0 ; helper zero register

        ld      a,[hl]
        add     a,c
        daa ; yeah, really!
        ld      [hl+],a

        ld      a,[hl]
        adc     a,b
        daa ; yeah, really!
        ld      [hl+],a

        REPT    3
        ld      a,[hl]
        adc     a,e
        daa ; yeah, really!
        ld      [hl+],a
        ENDR

.skip:
    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ; Save result to final variable!

    ld      de,city_population
    ld      hl,city_population_temp
    REPT    5
    ld      a,[hl+]
    ld      [de],a
    inc     de
    ENDR

    ret

;###############################################################################
