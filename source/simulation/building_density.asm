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
    INCLUDE "tileset_info.inc"
    INCLUDE "building_density.inc"

;###############################################################################

CURTILE     SET 0
POPULATION  SET 0
ENERGY_COST SET 0

; Tile Add - Base tile of the building to add information of
;            Will only fill the building when the next one is added!
T_ADD : MACRO ; 1=Tile index, 2=Population, 3=Energy Cost

    IF (\1) < CURTILE ; check if going backwards and stop if so
        FAIL "ERROR : building_density.asm : Tile already in use!"
    ENDC

    ; Fill previous building
    IF (\1) > CURTILE ; The first call both are 0 and this has to be skipped
        REPT (\1) - CURTILE
            DB POPULATION, ENERGY_COST
        ENDR
    ENDC

    ; Set parameters for this building
CURTILE     SET (\1)
POPULATION  SET (\2)
ENERGY_COST SET (\3)

ENDM

;###############################################################################

    SECTION "Building Density Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

CityTileDensity:: ; de = tile, returns d=population, e=energy

    push    de
    ld      b,BANK(CITY_TILE_DENSITY)
    call    rom_bank_push_set
    pop     de

IF CITY_TILE_DENSITY_ELEMENT_SIZE != 2
    FAIL "Fix this!"
ENDC

    ld      hl,CITY_TILE_DENSITY
    add     hl,de
    add     hl,de
    ld      a,[hl+]
    ld      d,a
    ld      e,[hl]

    push    de
    call    rom_bank_pop
    pop     de

    ret

;###############################################################################

    SECTION "Building Density Data",ROMX

;-------------------------------------------------------------------------------

IF CITY_TILE_DENSITY_ELEMENT_SIZE != 2
    FAIL "Fix this!"
ENDC

CITY_TILE_DENSITY:: ; 512 entries

    T_ADD   0, 0,0 ; Start array (set to 0 density the roads, terrains, etc)

    T_ADD   T_RESIDENTIAL, 0,1
    T_ADD   T_COMMERCIAL,  0,1
    T_ADD   T_INDUSTRIAL,  0,1

    T_ADD   T_DEMOLISHED,  0,0 ; Fill with 0s...

    T_ADD   T_ROAD_TB_POWER_LINES, 0,1
    T_ADD   T_ROAD_LR_POWER_LINES, 0,1

    T_ADD   T_ROAD_TB_BRIDGE, 0,0 ; Fill with 0s...

    T_ADD   T_TRAIN_TB_POWER_LINES, 0,1
    T_ADD   T_TRAIN_LR_POWER_LINES, 0,1

    T_ADD   T_TRAIN_TB_BRIDGE, 0,0 ; Fill with 0s...

    T_ADD   T_POWER_LINES_TB,   0,1
    T_ADD   T_POWER_LINES_LR,   0,1
    T_ADD   T_POWER_LINES_RB,   0,1
    T_ADD   T_POWER_LINES_LB,   0,1
    T_ADD   T_POWER_LINES_TR,   0,1
    T_ADD   T_POWER_LINES_TL,   0,1
    T_ADD   T_POWER_LINES_TRB,  0,1
    T_ADD   T_POWER_LINES_LRB,  0,1
    T_ADD   T_POWER_LINES_TLB,  0,1
    T_ADD   T_POWER_LINES_TLR,  0,1
    T_ADD   T_POWER_LINES_TLRB, 0,1
    T_ADD   T_POWER_LINES_TB_BRIDGE, 0,1
    T_ADD   T_POWER_LINES_LR_BRIDGE, 0,1

    T_ADD   T_POLICE_DEPT,  7,1
    T_ADD   T_FIRE_DEPT,    5,1
    T_ADD   T_HOSPITAL,    10,1

    T_ADD   T_PARK_SMALL, 1, 1
    T_ADD   T_PARK_BIG,   1, 1
    T_ADD   T_STADIUM,   20,20

    T_ADD   T_SCHOOL,       5,5
    T_ADD   T_HIGH_SCHOOL, 10,6
    T_ADD   T_UNIVERSITY,  20,7 ; TODO - Set central tile (5x5) to 0?
    T_ADD   T_MUSEUM,       5,6
    T_ADD   T_LIBRARY,     10,5

    T_ADD   T_AIRPORT,     30,10
    T_ADD   T_PORT,        10,8
    T_ADD   T_PORT_WATER_L, 0,1
    T_ADD   T_PORT_WATER_R, 0,1
    T_ADD   T_PORT_WATER_D, 0,1
    T_ADD   T_PORT_WATER_U, 0,1

    T_ADD   T_POWER_PLANT_COAL,    5,0 ; They don't have cost, power plants are
    T_ADD   T_POWER_PLANT_OIL,     5,0 ; generators!
    T_ADD   T_POWER_PLANT_WIND,    1,0
    T_ADD   T_POWER_PLANT_SOLAR,   2,0
    T_ADD   T_POWER_PLANT_NUCLEAR, 7,0
    T_ADD   T_POWER_PLANT_FUSION, 10,0

    T_ADD   T_RESIDENTIAL_S1_A, 1,2
    T_ADD   T_RESIDENTIAL_S1_B, 2,2
    T_ADD   T_RESIDENTIAL_S1_C, 2,2
    T_ADD   T_RESIDENTIAL_S1_D, 3,2

    T_ADD   T_RESIDENTIAL_S2_A, 7,3
    T_ADD   T_RESIDENTIAL_S2_B, 7,3
    T_ADD   T_RESIDENTIAL_S2_C, 8,3
    T_ADD   T_RESIDENTIAL_S2_D, 9,3

    T_ADD   T_RESIDENTIAL_S3_A, 12,5
    T_ADD   T_RESIDENTIAL_S3_B, 14,5
    T_ADD   T_RESIDENTIAL_S3_C, 15,5
    T_ADD   T_RESIDENTIAL_S3_D, 15,5

    T_ADD   T_COMMERCIAL_S1_A, 1,2
    T_ADD   T_COMMERCIAL_S1_B, 2,2
    T_ADD   T_COMMERCIAL_S1_C, 2,2
    T_ADD   T_COMMERCIAL_S1_D, 3,2

    T_ADD   T_COMMERCIAL_S2_A, 4,3
    T_ADD   T_COMMERCIAL_S2_B, 5,3
    T_ADD   T_COMMERCIAL_S2_C, 6,3
    T_ADD   T_COMMERCIAL_S2_D, 7,3

    T_ADD   T_COMMERCIAL_S3_A, 10,5
    T_ADD   T_COMMERCIAL_S3_B, 11,5
    T_ADD   T_COMMERCIAL_S3_C, 12,5
    T_ADD   T_COMMERCIAL_S3_D, 13,5

    T_ADD   T_INDUSTRIAL_S1_A, 1,2 ; Industrial zones consume more power than
    T_ADD   T_INDUSTRIAL_S1_B, 2,2 ; the population density
    T_ADD   T_INDUSTRIAL_S1_C, 2,2
    T_ADD   T_INDUSTRIAL_S1_D, 3,2

    T_ADD   T_INDUSTRIAL_S2_A, 6,6
    T_ADD   T_INDUSTRIAL_S2_B, 7,6
    T_ADD   T_INDUSTRIAL_S2_C, 8,6
    T_ADD   T_INDUSTRIAL_S2_D, 9,6

    T_ADD   T_INDUSTRIAL_S3_A, 13,10
    T_ADD   T_INDUSTRIAL_S3_B, 14,10
    T_ADD   T_INDUSTRIAL_S3_C, 15,10
    T_ADD   T_INDUSTRIAL_S3_D, 15,10

    T_ADD   512, 0,0 ; Fill array

;###############################################################################
