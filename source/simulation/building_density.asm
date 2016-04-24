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

    SECTION "Building Density Data",ROMX

;-------------------------------------------------------------------------------

IF CITY_TILE_DENSITY_ELEMENT_SIZE != 2
    FAIL "Fix this!"
ENDC

CITY_TILE_DENSITY:: ; 512 entries

    T_ADD   0, 0,0 ; Start array (set to 0 density the roads, terrains, etc)

    T_ADD   T_POLICE,   0,0
    T_ADD   T_FIREMEN,  0,0
    T_ADD   T_HOSPITAL, 0,0

    T_ADD   T_PARK_SMALL, 0,1
    T_ADD   T_PARK_BIG,   0,1
    T_ADD   T_STADIUM,    0,20

    T_ADD   T_SCHOOL,      0,5
    T_ADD   T_HIGH_SCHOOL, 0,6
    T_ADD   T_UNIVERSITY,  0,7
    T_ADD   T_MUSEUM,      0,6
    T_ADD   T_LIBRARY,     0,5

    T_ADD   T_TRAIN_STATION, 0,3
    T_ADD   T_AIRPORT,       0,10
    T_ADD   T_PORT,          0,8
    T_ADD   T_PORT_WATER_L,  0,0
    T_ADD   T_PORT_WATER_R,  0,0
    T_ADD   T_PORT_WATER_D,  0,0
    T_ADD   T_PORT_WATER_U,  0,0

    T_ADD   T_POWER_PLANT_COAL,    0,0 ; No energetic cost, they are generators!
    T_ADD   T_POWER_PLANT_OIL,     0,0
    T_ADD   T_POWER_PLANT_WIND,    0,0
    T_ADD   T_POWER_PLANT_SOLAR,   0,0
    T_ADD   T_POWER_PLANT_NUCLEAR, 0,0
    T_ADD   T_POWER_PLANT_FUSION,  0,0

    T_ADD   T_RESIDENTIAL_S1_A, 1,1
    T_ADD   T_RESIDENTIAL_S1_B, 2,1
    T_ADD   T_RESIDENTIAL_S1_C, 2,1
    T_ADD   T_RESIDENTIAL_S1_D, 3,1

    T_ADD   T_RESIDENTIAL_S2_A, 7,3
    T_ADD   T_RESIDENTIAL_S2_B, 7,3
    T_ADD   T_RESIDENTIAL_S2_C, 8,3
    T_ADD   T_RESIDENTIAL_S2_D, 9,3

    T_ADD   T_RESIDENTIAL_S3_A, 12,5
    T_ADD   T_RESIDENTIAL_S3_B, 14,5
    T_ADD   T_RESIDENTIAL_S3_C, 15,5
    T_ADD   T_RESIDENTIAL_S3_D, 15,5

    T_ADD   T_COMMERCIAL_S1_A, 1,1
    T_ADD   T_COMMERCIAL_S1_B, 2,1
    T_ADD   T_COMMERCIAL_S1_C, 2,1
    T_ADD   T_COMMERCIAL_S1_D, 3,1

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
