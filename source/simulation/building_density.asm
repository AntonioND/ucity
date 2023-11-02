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
    INCLUDE "tileset_info.inc"

;###############################################################################

    SECTION "Building Density Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

    DEF CITY_TILE_DENSITY_ELEMENT_SIZE EQU 4 ; Size of elements of CITY_TILE_DENSITY

;-------------------------------------------------------------------------------

CityTileDensity:: ; de = tile, returns d = population, e = energy

    ld      b,BANK(CITY_TILE_DENSITY)
    call    rom_bank_push_set ; preserves de
    LD_HL_DE

IF CITY_TILE_DENSITY_ELEMENT_SIZE != 4
    FAIL "Fix this!"
ENDC

    add     hl,hl
    add     hl,hl ; index * 4
    ld      de,CITY_TILE_DENSITY
    add     hl,de ; base + index * 4
    ld      a,[hl+]
    ld      d,a
    ld      e,[hl]

    ; Call and return from there
    jp      rom_bank_pop ; preserves bc and de

;-------------------------------------------------------------------------------

CityTilePollution:: ; de = tile, returns d = pollution

    ld      b,BANK(CITY_TILE_DENSITY)
    call    rom_bank_push_set ; preserves de
    LD_HL_DE

IF CITY_TILE_DENSITY_ELEMENT_SIZE != 4
    FAIL "Fix this!"
ENDC

    add     hl,hl
    add     hl,hl ; index * 4
    ld      de,CITY_TILE_DENSITY+2 ; pollution level
    add     hl,de ; base + index * 4
    ld      d,[hl]

    ; Call and return from there
    jp      rom_bank_pop ; preserves bc and de

;-------------------------------------------------------------------------------

CityTileFireProbability:: ; de = tile, returns d = probability

    ld      b,BANK(CITY_TILE_DENSITY)
    call    rom_bank_push_set ; preserves de
    LD_HL_DE

IF CITY_TILE_DENSITY_ELEMENT_SIZE != 4
    FAIL "Fix this!"
ENDC

    add     hl,hl
    add     hl,hl ; index * 4
    ld      de,CITY_TILE_DENSITY+3 ; fire probability
    add     hl,de ; base + index * 4
    ld      d,[hl]

    ; Call and return from there
    jp      rom_bank_pop ; preserves bc and de

;###############################################################################

    DEF CURTILE          = 0
    DEF POPULATION       = 0
    DEF ENERGY_COST      = 0
    DEF POLLUTION        = 0
    DEF FIRE_PROBABILITY = 0 ; 0 = never catches fire, 255 = always catches fire

; Tile Add - Base tile of the building to add information of
;            Will only fill the building when the next one is added!
MACRO T_ADD ; 1=Tile index, 2=Population, 3=Energy Cost, 4=Pollution, 5=Fire %

    IF (\1) < CURTILE ; check if going backwards and stop if so
        FAIL "ERROR : building_density.asm : Tile already in use!"
    ENDC

    ; Fill previous building
    IF (\1) > CURTILE ; In the first call all are 0 and this has to be skipped
        REPT (\1) - CURTILE
            DB POPULATION, ENERGY_COST, POLLUTION, FIRE_PROBABILITY
        ENDR
    ENDC

    ; Set parameters for this building
    DEF CURTILE             = (\1)
    DEF POPULATION          = (\2)
    DEF ENERGY_COST         = (\3)
    DEF POLLUTION           = (\4)
    DEF FIRE_PROBABILITY    = (\5)

ENDM

;###############################################################################

    SECTION "Building Density Data",ROMX

;-------------------------------------------------------------------------------

; Note: Add the following check when using this array:
IF CITY_TILE_DENSITY_ELEMENT_SIZE != 4
    FAIL "Fix this!"
ENDC

; 512 entries - Population, energy cost, pollution level, fire probability
CITY_TILE_DENSITY::

; Population is the whole population of the building, the others are per-tile

    T_ADD   T_GRASS__FOREST_TL, 0,0, 0, 12
    T_ADD   T_GRASS__FOREST_TC, 0,0, 0, 12
    T_ADD   T_GRASS__FOREST_TR, 0,0, 0, 12
    T_ADD   T_GRASS__FOREST_CL, 0,0, 0, 12
    T_ADD   T_GRASS,            0,0, 0, 0
    T_ADD   T_GRASS__FOREST_CR, 0,0, 0, 12
    T_ADD   T_GRASS__FOREST_BL, 0,0, 0, 12
    T_ADD   T_GRASS__FOREST_BC, 0,0, 0, 12
    T_ADD   T_GRASS__FOREST_BR, 0,0, 0, 12
    T_ADD   T_GRASS__FOREST_CORNER_TL, 0,0, 0, 12
    T_ADD   T_GRASS__FOREST_CORNER_TR, 0,0, 0, 12
    T_ADD   T_GRASS__FOREST_CORNER_BL, 0,0, 0, 12
    T_ADD   T_GRASS__FOREST_CORNER_BR, 0,0, 0, 12
    T_ADD   T_FOREST,       0,0, 0, 12
    T_ADD   T_GRASS_EXTRA,  0,0, 0, 0
    T_ADD   T_FOREST_EXTRA, 0,0, 0, 12

    T_ADD   T_WATER__GRASS_TL, 0,0, 0, 0
    T_ADD   T_WATER__GRASS_TC, 0,0, 0, 0
    T_ADD   T_WATER__GRASS_TR, 0,0, 0, 0
    T_ADD   T_WATER__GRASS_CL, 0,0, 0, 0
    T_ADD   T_WATER,           0,0, 0, 0
    T_ADD   T_WATER__GRASS_CR, 0,0, 0, 0
    T_ADD   T_WATER__GRASS_BL, 0,0, 0, 0
    T_ADD   T_WATER__GRASS_BC, 0,0, 0, 0
    T_ADD   T_WATER__GRASS_BR, 0,0, 0, 0
    T_ADD   T_WATER__GRASS_CORNER_TL, 0,0, 0, 0
    T_ADD   T_WATER__GRASS_CORNER_TR, 0,0, 0, 0
    T_ADD   T_WATER__GRASS_CORNER_BL, 0,0, 0, 0
    T_ADD   T_WATER__GRASS_CORNER_BR, 0,0, 0, 0
    T_ADD   T_WATER_EXTRA, 0,0, 0, 0

    T_ADD   T_RESIDENTIAL, 0,1, 0, 12
    T_ADD   T_COMMERCIAL,  0,1, 0, 12
    T_ADD   T_INDUSTRIAL,  0,1, 0, 12
    T_ADD   T_DEMOLISHED,  0,0, 0, 0

    T_ADD   T_ROAD_TB,   0,0, 0, 0 ; Road pollution is 0, it is calculated from
    T_ADD   T_ROAD_TB_1, 0,0, 0, 0 ; the traffic level.
    T_ADD   T_ROAD_TB_2, 0,0, 0, 0
    T_ADD   T_ROAD_TB_3, 0,0, 0, 0
    T_ADD   T_ROAD_LR,   0,0, 0, 0
    T_ADD   T_ROAD_LR_1, 0,0, 0, 0
    T_ADD   T_ROAD_LR_2, 0,0, 0, 0
    T_ADD   T_ROAD_LR_3, 0,0, 0, 0
    T_ADD   T_ROAD_RB,   0,0, 0, 0
    T_ADD   T_ROAD_LB,   0,0, 0, 0
    T_ADD   T_ROAD_TR,   0,0, 0, 0
    T_ADD   T_ROAD_TL,   0,0, 0, 0
    T_ADD   T_ROAD_TRB,  0,0, 0, 0
    T_ADD   T_ROAD_LRB,  0,0, 0, 0
    T_ADD   T_ROAD_TLB,  0,0, 0, 0
    T_ADD   T_ROAD_TLR,  0,0, 0, 0
    T_ADD   T_ROAD_TLRB, 0,0, 0, 0
    T_ADD   T_ROAD_TB_POWER_LINES, 0,1, 0, 12
    T_ADD   T_ROAD_LR_POWER_LINES, 0,1, 0, 12
    T_ADD   T_ROAD_TB_BRIDGE, 0,0, 0, 0
    T_ADD   T_ROAD_LR_BRIDGE, 0,0, 0, 0

    T_ADD   T_TRAIN_TB,   0,0, 0, 0
    T_ADD   T_TRAIN_LR,   0,0, 0, 0
    T_ADD   T_TRAIN_RB,   0,0, 0, 0
    T_ADD   T_TRAIN_LB,   0,0, 0, 0
    T_ADD   T_TRAIN_TR,   0,0, 0, 0
    T_ADD   T_TRAIN_TL,   0,0, 0, 0
    T_ADD   T_TRAIN_TRB,  0,0, 0, 0
    T_ADD   T_TRAIN_LRB,  0,0, 0, 0
    T_ADD   T_TRAIN_TLB,  0,0, 0, 0
    T_ADD   T_TRAIN_TLR,  0,0, 0, 0
    T_ADD   T_TRAIN_TLRB, 0,0, 0, 0
    T_ADD   T_TRAIN_LR_ROAD, 0,0, 0, 0
    T_ADD   T_TRAIN_TB_ROAD, 0,0, 0, 0
    T_ADD   T_TRAIN_TB_POWER_LINES, 0,1, 0, 12
    T_ADD   T_TRAIN_LR_POWER_LINES, 0,1, 0, 12
    T_ADD   T_TRAIN_TB_BRIDGE, 0,0, 0, 0
    T_ADD   T_TRAIN_LR_BRIDGE, 0,0, 0, 0

    T_ADD   T_POWER_LINES_TB,   0,1, 0, 12
    T_ADD   T_POWER_LINES_LR,   0,1, 0, 12
    T_ADD   T_POWER_LINES_RB,   0,1, 0, 12
    T_ADD   T_POWER_LINES_LB,   0,1, 0, 12
    T_ADD   T_POWER_LINES_TR,   0,1, 0, 12
    T_ADD   T_POWER_LINES_TL,   0,1, 0, 12
    T_ADD   T_POWER_LINES_TRB,  0,1, 0, 12
    T_ADD   T_POWER_LINES_LRB,  0,1, 0, 12
    T_ADD   T_POWER_LINES_TLB,  0,1, 0, 12
    T_ADD   T_POWER_LINES_TLR,  0,1, 0, 12
    T_ADD   T_POWER_LINES_TLRB, 0,1, 0, 12
    T_ADD   T_POWER_LINES_TB_BRIDGE, 0,1, 0, 12 ; This is the only bridge that
    T_ADD   T_POWER_LINES_LR_BRIDGE, 0,1, 0, 12 ; can burn.

    T_ADD   T_POLICE_DEPT, 1*9,1, 0, 12
    T_ADD   T_FIRE_DEPT,   1*9,1, 0, 6
    T_ADD   T_HOSPITAL,    2*9,1, 0, 12

    T_ADD   T_PARK_SMALL,  2*1, 1, 0, 12
    T_ADD   T_PARK_BIG,    2*9, 1, 0, 12
    T_ADD   T_STADIUM,    3*15,20, 0, 32

    T_ADD   T_SCHOOL,       2*6,5, 0, 12
    T_ADD   T_HIGH_SCHOOL,  2*9,6, 0, 12
    T_ADD   T_UNIVERSITY,  2*25,7, 0, 12
    T_ADD   T_MUSEUM,      1*12,6, 0, 12
    T_ADD   T_LIBRARY,      1*6,5, 0, 12

    T_ADD   T_AIRPORT,   2*15,10, 128, 20
    T_ADD   T_PORT,        1*9,8, 128, 20
    T_ADD   T_PORT_WATER_L,  0,0, 32, 0 ; Don't let this burn, only the main
    T_ADD   T_PORT_WATER_R,  0,0, 32, 0 ; building. If destroyed, the docks
    T_ADD   T_PORT_WATER_D,  0,0, 32, 0 ; will be destroyed as well.
    T_ADD   T_PORT_WATER_U,  0,0, 32, 0

    T_ADD   T_POWER_PLANT_COAL,    1*16,0, 255, 24 ; No energetic cost, power
    T_ADD   T_POWER_PLANT_OIL,     1*16,0, 232, 24 ; plants are generators!
    T_ADD   T_POWER_PLANT_WIND,     1*4,0, 0, 4
    T_ADD   T_POWER_PLANT_SOLAR,   1*16,0, 0, 4
    T_ADD   T_POWER_PLANT_NUCLEAR, 2*16,0, 0, 4
    T_ADD   T_POWER_PLANT_FUSION,  3*16,0, 0, 4

    T_ADD   T_RESIDENTIAL_S1_A, 6*1,2, 0, 6
    T_ADD   T_RESIDENTIAL_S1_B, 7*1,2, 0, 6
    T_ADD   T_RESIDENTIAL_S1_C, 7*1,2, 0, 6
    T_ADD   T_RESIDENTIAL_S1_D, 8*1,2, 0, 6

    T_ADD   T_RESIDENTIAL_S2_A,  9*4,3, 0, 8
    T_ADD   T_RESIDENTIAL_S2_B, 10*4,3, 0, 8
    T_ADD   T_RESIDENTIAL_S2_C, 10*4,3, 0, 8
    T_ADD   T_RESIDENTIAL_S2_D, 10*4,3, 0, 8

    T_ADD   T_RESIDENTIAL_S3_A, 11*9,5, 0, 12
    T_ADD   T_RESIDENTIAL_S3_B, 11*9,5, 0, 12
    T_ADD   T_RESIDENTIAL_S3_C, 11*9,5, 0, 12
    T_ADD   T_RESIDENTIAL_S3_D, 12*9,5, 0, 12

    T_ADD   T_COMMERCIAL_S1_A, 1*1,2, 0, 8
    T_ADD   T_COMMERCIAL_S1_B, 1*1,2, 0, 8
    T_ADD   T_COMMERCIAL_S1_C, 2*1,2, 0, 8
    T_ADD   T_COMMERCIAL_S1_D, 2*1,2, 0, 8

    T_ADD   T_COMMERCIAL_S2_A, 2*4,3, 0, 12
    T_ADD   T_COMMERCIAL_S2_B, 2*4,3, 0, 12
    T_ADD   T_COMMERCIAL_S2_C, 3*4,3, 0, 12
    T_ADD   T_COMMERCIAL_S2_D, 3*4,3, 0, 12

    T_ADD   T_COMMERCIAL_S3_A, 4*9,5, 0, 16
    T_ADD   T_COMMERCIAL_S3_B, 4*9,5, 0, 16
    T_ADD   T_COMMERCIAL_S3_C, 5*9,5, 0, 16
    T_ADD   T_COMMERCIAL_S3_D, 5*9,5, 0, 16

    T_ADD   T_INDUSTRIAL_S1_A, 1*1,2, 128, 12
    T_ADD   T_INDUSTRIAL_S1_B, 2*1,2, 128, 12
    T_ADD   T_INDUSTRIAL_S1_C, 2*1,2, 128, 12
    T_ADD   T_INDUSTRIAL_S1_D, 2*1,2, 128, 12

    T_ADD   T_INDUSTRIAL_S2_A, 3*4,6, 192, 16
    T_ADD   T_INDUSTRIAL_S2_B, 3*4,6, 192, 16
    T_ADD   T_INDUSTRIAL_S2_C, 4*4,6, 192, 16
    T_ADD   T_INDUSTRIAL_S2_D, 4*4,6, 192, 16

    T_ADD   T_INDUSTRIAL_S3_A, 5*9,10, 255, 20
    T_ADD   T_INDUSTRIAL_S3_B, 5*9,10, 255, 20
    T_ADD   T_INDUSTRIAL_S3_C, 5*9,10, 255, 20
    T_ADD   T_INDUSTRIAL_S3_D, 6*9,10, 255, 20

    T_ADD   T_FIRE_1, 0,0, 0, 0 ; 1) Pollution not simulated in disaster mode.
    T_ADD   T_FIRE_2, 0,0, 0, 0 ; 2) Fire can't catch fire!

    T_ADD   T_RADIATION_GROUND, 0,0, 0, 0 ; Radiation can't catch fire!
    T_ADD   T_RADIATION_WATER,  0,0, 0, 0

    T_ADD   512, 0,0,0, 0 ; Fill array

;###############################################################################
