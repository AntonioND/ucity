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

    SECTION "Building Density Data",ROMX

;-------------------------------------------------------------------------------

IF CITY_TILE_DENSITY_ELEMENT_SIZE != 2
    FAIL "Fix this!"
ENDC

CITY_TILE_DENSITY:: ; 512 entries - Population, energy cost

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

    T_ADD   T_POLICE_DEPT, 1*9,1
    T_ADD   T_FIRE_DEPT,   1*9,1
    T_ADD   T_HOSPITAL,    2*9,1

    T_ADD   T_PARK_SMALL,  2*1, 1
    T_ADD   T_PARK_BIG,    2*9, 1
    T_ADD   T_STADIUM,    2*15,20

    T_ADD   T_SCHOOL,       2*6,5
    T_ADD   T_HIGH_SCHOOL,  2*9,6
    T_ADD   T_UNIVERSITY,  2*25,7
    T_ADD   T_MUSEUM,      1*12,6
    T_ADD   T_LIBRARY,      1*6,5

    T_ADD   T_AIRPORT,   2*15,10
    T_ADD   T_PORT,        1*9,8
    T_ADD   T_PORT_WATER_L,  0,0
    T_ADD   T_PORT_WATER_R,  0,0
    T_ADD   T_PORT_WATER_D,  0,0
    T_ADD   T_PORT_WATER_U,  0,0

    T_ADD   T_POWER_PLANT_COAL,    1*16,0 ; They don't have cost, power plants
    T_ADD   T_POWER_PLANT_OIL,     1*16,0 ; are generators!
    T_ADD   T_POWER_PLANT_WIND,     1*4,0
    T_ADD   T_POWER_PLANT_SOLAR,   1*16,0
    T_ADD   T_POWER_PLANT_NUCLEAR, 2*16,0
    T_ADD   T_POWER_PLANT_FUSION,  3*16,0

    T_ADD   T_RESIDENTIAL_S1_A, 6*1,2
    T_ADD   T_RESIDENTIAL_S1_B, 7*1,2
    T_ADD   T_RESIDENTIAL_S1_C, 7*1,2
    T_ADD   T_RESIDENTIAL_S1_D, 8*1,2

    T_ADD   T_RESIDENTIAL_S2_A, 8*4,3
    T_ADD   T_RESIDENTIAL_S2_B, 9*4,3
    T_ADD   T_RESIDENTIAL_S2_C, 9*4,3
    T_ADD   T_RESIDENTIAL_S2_D, 10*4,3

    T_ADD   T_RESIDENTIAL_S3_A, 10*9,5
    T_ADD   T_RESIDENTIAL_S3_B, 11*9,5
    T_ADD   T_RESIDENTIAL_S3_C, 11*9,5
    T_ADD   T_RESIDENTIAL_S3_D, 12*9,5

    T_ADD   T_COMMERCIAL_S1_A, 1*1,2
    T_ADD   T_COMMERCIAL_S1_B, 1*1,2
    T_ADD   T_COMMERCIAL_S1_C, 2*1,2
    T_ADD   T_COMMERCIAL_S1_D, 2*1,2

    T_ADD   T_COMMERCIAL_S2_A, 2*4,3
    T_ADD   T_COMMERCIAL_S2_B, 2*4,3
    T_ADD   T_COMMERCIAL_S2_C, 3*4,3
    T_ADD   T_COMMERCIAL_S2_D, 3*4,3

    T_ADD   T_COMMERCIAL_S3_A, 4*9,5
    T_ADD   T_COMMERCIAL_S3_B, 4*9,5
    T_ADD   T_COMMERCIAL_S3_C, 5*9,5
    T_ADD   T_COMMERCIAL_S3_D, 5*9,5

    T_ADD   T_INDUSTRIAL_S1_A, 1*1,2
    T_ADD   T_INDUSTRIAL_S1_B, 2*1,2
    T_ADD   T_INDUSTRIAL_S1_C, 2*1,2
    T_ADD   T_INDUSTRIAL_S1_D, 2*1,2

    T_ADD   T_INDUSTRIAL_S2_A, 3*4,6
    T_ADD   T_INDUSTRIAL_S2_B, 3*4,6
    T_ADD   T_INDUSTRIAL_S2_C, 4*4,6
    T_ADD   T_INDUSTRIAL_S2_D, 4*4,6

    T_ADD   T_INDUSTRIAL_S3_A, 5*9,10
    T_ADD   T_INDUSTRIAL_S3_B, 5*9,10
    T_ADD   T_INDUSTRIAL_S3_C, 5*9,10
    T_ADD   T_INDUSTRIAL_S3_D, 6*9,10

    T_ADD   512, 0,0 ; Fill array

;###############################################################################
