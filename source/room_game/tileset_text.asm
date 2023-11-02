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

    INCLUDE "text.inc"
    INCLUDE "tileset_info.inc"

;###############################################################################

    DEF CURTILE = 0

; Tile Set Count
MACRO TILE_SET_COUNT ; 1 = Tile number
    IF (\1) < CURTILE ; check if going backwards and stop if so
        FAIL "ERROR : tileset_text.asm : Tile already in use!"
    ENDC
    IF (\1) > CURTILE ; If there's a hole to fill, fill it
        REPT (\1) - CURTILE
            DW $0000 ; Empty
        ENDR
    ENDC
    DEF CURTILE = (\1)
ENDM

; Tile Add
MACRO T_ADD ; 1=Name Define, 2=Pointer to name string
    TILE_SET_COUNT (\1)
    DW (\2) ; LSB first
    DEF CURTILE = CURTILE+1 ; Set cursor for next item
ENDM

;###############################################################################

    SECTION "Tileset Name Data",ROMX

;-------------------------------------------------------------------------------

str_forest: STR_ADD "Forest"
str_field:  STR_ADD "Field"
str_water:  STR_ADD "Water"
str_residential: STR_ADD "Residential"
str_commercial:  STR_ADD "Commercial"
str_industrial:  STR_ADD "Industrial"
str_demolished:  STR_ADD "Demolished"
str_road:  STR_ADD "Road"
str_train: STR_ADD "Train"
str_power: STR_ADD "Power Lines"
str_road_train:   STR_ADD "Road. Train"
str_road_power:   STR_ADD "Road. Power Lines"
str_train_power:  STR_ADD "Train. Power Lines"
str_road_bridge:  STR_ADD "Road Bridge"
str_train_bridge: STR_ADD "Train Bridge"
str_power_bridge: STR_ADD "Power Lines Bridge"
str_police:      STR_ADD "Police Dept."
str_firedept:    STR_ADD "Fire Dept."
str_hospital:    STR_ADD "Hospital"
str_park_small:  STR_ADD "Small Park"
str_park_big:    STR_ADD "Big Park"
str_stadium:     STR_ADD "Stadium"
str_school:      STR_ADD "School"
str_high_school: STR_ADD "High School"
str_university:  STR_ADD "University"
str_museum:      STR_ADD "Museum"
str_library:     STR_ADD "Library"
str_ariport: STR_ADD "Airport"
str_port:    STR_ADD "Port"
str_dock:    STR_ADD "Dock"
str_power_coal:    STR_ADD "Coal Power"
str_power_oil:     STR_ADD "Oil Power"
str_power_wind:    STR_ADD "Wind Power"
str_power_solar:   STR_ADD "Solar Power"
str_power_nuclear: STR_ADD "Nuclear Power"
str_power_fusion:  STR_ADD "Fusion Power"
str_residential_1: STR_ADD "Light Residential"
str_residential_2: STR_ADD "Medium Res."
str_residential_3: STR_ADD "Dense Residential"
str_commercial_1: STR_ADD "Light Commercial"
str_commercial_2: STR_ADD "Medium Com."
str_commercial_3: STR_ADD "Dense Commercial"
str_industrial_1: STR_ADD "Light Industrial"
str_industrial_2: STR_ADD "Medium Ind."
str_industrial_3: STR_ADD "Dense Industrial"
str_fire: STR_ADD "Fire"
str_radiation_ground: STR_ADD "Radiation Ground"
str_radiation_water:  STR_ADD "Radiation Water"

;-------------------------------------------------------------------------------

CITY_TILE_NAME:: ; 512 entries. LSB first

    T_ADD   T_GRASS__FOREST_TL, str_forest
    T_ADD   T_GRASS__FOREST_TC, str_forest
    T_ADD   T_GRASS__FOREST_TR, str_forest
    T_ADD   T_GRASS__FOREST_CL, str_forest
    T_ADD   T_GRASS,            str_field
    T_ADD   T_GRASS__FOREST_CR, str_forest
    T_ADD   T_GRASS__FOREST_BL, str_forest
    T_ADD   T_GRASS__FOREST_BC, str_forest
    T_ADD   T_GRASS__FOREST_BR, str_forest
    T_ADD   T_GRASS__FOREST_CORNER_TL, str_field
    T_ADD   T_GRASS__FOREST_CORNER_TR, str_field
    T_ADD   T_GRASS__FOREST_CORNER_BL, str_field
    T_ADD   T_GRASS__FOREST_CORNER_BR, str_field
    T_ADD   T_FOREST,       str_forest
    T_ADD   T_GRASS_EXTRA,  str_field
    T_ADD   T_FOREST_EXTRA, str_forest

    T_ADD   T_WATER__GRASS_TL, str_water
    T_ADD   T_WATER__GRASS_TC, str_water
    T_ADD   T_WATER__GRASS_TR, str_water
    T_ADD   T_WATER__GRASS_CL, str_water
    T_ADD   T_WATER,           str_water
    T_ADD   T_WATER__GRASS_CR, str_water
    T_ADD   T_WATER__GRASS_BL, str_water
    T_ADD   T_WATER__GRASS_BC, str_water
    T_ADD   T_WATER__GRASS_BR, str_water
    T_ADD   T_WATER__GRASS_CORNER_TL, str_water
    T_ADD   T_WATER__GRASS_CORNER_TR, str_water
    T_ADD   T_WATER__GRASS_CORNER_BL, str_water
    T_ADD   T_WATER__GRASS_CORNER_BR, str_water
    T_ADD   T_WATER_EXTRA, str_water

    T_ADD   T_RESIDENTIAL, str_residential
    T_ADD   T_COMMERCIAL,  str_commercial
    T_ADD   T_INDUSTRIAL,  str_industrial
    T_ADD   T_DEMOLISHED,  str_demolished

    T_ADD   T_ROAD_TB,   str_road
    T_ADD   T_ROAD_TB_1, str_road
    T_ADD   T_ROAD_TB_2, str_road
    T_ADD   T_ROAD_TB_3, str_road
    T_ADD   T_ROAD_LR,   str_road
    T_ADD   T_ROAD_LR_1, str_road
    T_ADD   T_ROAD_LR_2, str_road
    T_ADD   T_ROAD_LR_3, str_road
    T_ADD   T_ROAD_RB,   str_road
    T_ADD   T_ROAD_LB,   str_road
    T_ADD   T_ROAD_TR,   str_road
    T_ADD   T_ROAD_TL,   str_road
    T_ADD   T_ROAD_TRB,  str_road
    T_ADD   T_ROAD_LRB,  str_road
    T_ADD   T_ROAD_TLB,  str_road
    T_ADD   T_ROAD_TLR,  str_road
    T_ADD   T_ROAD_TLRB, str_road
    T_ADD   T_ROAD_TB_POWER_LINES, str_road_power
    T_ADD   T_ROAD_LR_POWER_LINES, str_road_power
    T_ADD   T_ROAD_TB_BRIDGE, str_road_bridge
    T_ADD   T_ROAD_LR_BRIDGE, str_road_bridge

    T_ADD   T_TRAIN_TB,   str_train
    T_ADD   T_TRAIN_LR,   str_train
    T_ADD   T_TRAIN_RB,   str_train
    T_ADD   T_TRAIN_LB,   str_train
    T_ADD   T_TRAIN_TR,   str_train
    T_ADD   T_TRAIN_TL,   str_train
    T_ADD   T_TRAIN_TRB,  str_train
    T_ADD   T_TRAIN_LRB,  str_train
    T_ADD   T_TRAIN_TLB,  str_train
    T_ADD   T_TRAIN_TLR,  str_train
    T_ADD   T_TRAIN_TLRB, str_train
    T_ADD   T_TRAIN_LR_ROAD, str_road_train
    T_ADD   T_TRAIN_TB_ROAD, str_road_train
    T_ADD   T_TRAIN_TB_POWER_LINES, str_train_power
    T_ADD   T_TRAIN_LR_POWER_LINES, str_train_power
    T_ADD   T_TRAIN_TB_BRIDGE, str_train_bridge
    T_ADD   T_TRAIN_LR_BRIDGE, str_train_bridge

    T_ADD   T_POWER_LINES_TB,   str_power
    T_ADD   T_POWER_LINES_LR,   str_power
    T_ADD   T_POWER_LINES_RB,   str_power
    T_ADD   T_POWER_LINES_LB,   str_power
    T_ADD   T_POWER_LINES_TR,   str_power
    T_ADD   T_POWER_LINES_TL,   str_power
    T_ADD   T_POWER_LINES_TRB,  str_power
    T_ADD   T_POWER_LINES_LRB,  str_power
    T_ADD   T_POWER_LINES_TLB,  str_power
    T_ADD   T_POWER_LINES_TLR,  str_power
    T_ADD   T_POWER_LINES_TLRB, str_power
    T_ADD   T_POWER_LINES_TB_BRIDGE, str_power_bridge
    T_ADD   T_POWER_LINES_LR_BRIDGE, str_power_bridge

    T_ADD   T_POLICE_DEPT+0, str_police
    T_ADD   T_POLICE_DEPT+1, str_police
    T_ADD   T_POLICE_DEPT+2, str_police
    T_ADD   T_POLICE_DEPT+3, str_police
    T_ADD   T_POLICE_DEPT+4, str_police
    T_ADD   T_POLICE_DEPT+5, str_police
    T_ADD   T_POLICE_DEPT+6, str_police
    T_ADD   T_POLICE_DEPT+7, str_police
    T_ADD   T_POLICE_DEPT+8, str_police

    T_ADD   T_FIRE_DEPT+0, str_firedept
    T_ADD   T_FIRE_DEPT+1, str_firedept
    T_ADD   T_FIRE_DEPT+2, str_firedept
    T_ADD   T_FIRE_DEPT+3, str_firedept
    T_ADD   T_FIRE_DEPT+4, str_firedept
    T_ADD   T_FIRE_DEPT+5, str_firedept
    T_ADD   T_FIRE_DEPT+6, str_firedept
    T_ADD   T_FIRE_DEPT+7, str_firedept
    T_ADD   T_FIRE_DEPT+8, str_firedept

    T_ADD   T_HOSPITAL+0, str_hospital
    T_ADD   T_HOSPITAL+1, str_hospital
    T_ADD   T_HOSPITAL+2, str_hospital
    T_ADD   T_HOSPITAL+3, str_hospital
    T_ADD   T_HOSPITAL+4, str_hospital
    T_ADD   T_HOSPITAL+5, str_hospital
    T_ADD   T_HOSPITAL+6, str_hospital
    T_ADD   T_HOSPITAL+7, str_hospital
    T_ADD   T_HOSPITAL+8, str_hospital

    T_ADD   T_PARK_SMALL+0, str_park_small

    T_ADD   T_PARK_BIG+0, str_park_big
    T_ADD   T_PARK_BIG+1, str_park_big
    T_ADD   T_PARK_BIG+2, str_park_big
    T_ADD   T_PARK_BIG+3, str_park_big
    T_ADD   T_PARK_BIG+4, str_park_big
    T_ADD   T_PARK_BIG+5, str_park_big
    T_ADD   T_PARK_BIG+6, str_park_big
    T_ADD   T_PARK_BIG+7, str_park_big
    T_ADD   T_PARK_BIG+8, str_park_big

    T_ADD   T_STADIUM+0,  str_stadium
    T_ADD   T_STADIUM+1,  str_stadium
    T_ADD   T_STADIUM+2,  str_stadium
    T_ADD   T_STADIUM+3,  str_stadium
    T_ADD   T_STADIUM+4,  str_stadium
    T_ADD   T_STADIUM+5,  str_stadium
    T_ADD   T_STADIUM+6,  str_stadium
    T_ADD   T_STADIUM+7,  str_stadium
    T_ADD   T_STADIUM+8,  str_stadium
    T_ADD   T_STADIUM+9,  str_stadium
    T_ADD   T_STADIUM+10, str_stadium
    T_ADD   T_STADIUM+11, str_stadium
    T_ADD   T_STADIUM+12, str_stadium
    T_ADD   T_STADIUM+13, str_stadium
    T_ADD   T_STADIUM+14, str_stadium
    T_ADD   T_STADIUM+15, str_stadium
    T_ADD   T_STADIUM+16, str_stadium
    T_ADD   T_STADIUM+17, str_stadium
    T_ADD   T_STADIUM+18, str_stadium
    T_ADD   T_STADIUM+19, str_stadium

    T_ADD   T_SCHOOL+0, str_school
    T_ADD   T_SCHOOL+1, str_school
    T_ADD   T_SCHOOL+2, str_school
    T_ADD   T_SCHOOL+3, str_school
    T_ADD   T_SCHOOL+4, str_school
    T_ADD   T_SCHOOL+5, str_school

    T_ADD   T_HIGH_SCHOOL+0, str_high_school
    T_ADD   T_HIGH_SCHOOL+1, str_high_school
    T_ADD   T_HIGH_SCHOOL+2, str_high_school
    T_ADD   T_HIGH_SCHOOL+3, str_high_school
    T_ADD   T_HIGH_SCHOOL+4, str_high_school
    T_ADD   T_HIGH_SCHOOL+5, str_high_school
    T_ADD   T_HIGH_SCHOOL+6, str_high_school
    T_ADD   T_HIGH_SCHOOL+7, str_high_school
    T_ADD   T_HIGH_SCHOOL+8, str_high_school

    T_ADD   T_UNIVERSITY+0,  str_university
    T_ADD   T_UNIVERSITY+1,  str_university
    T_ADD   T_UNIVERSITY+2,  str_university
    T_ADD   T_UNIVERSITY+3,  str_university
    T_ADD   T_UNIVERSITY+4,  str_university
    T_ADD   T_UNIVERSITY+5,  str_university
    T_ADD   T_UNIVERSITY+6,  str_university
    T_ADD   T_UNIVERSITY+7,  str_university
    T_ADD   T_UNIVERSITY+8,  str_university
    T_ADD   T_UNIVERSITY+9,  str_university
    T_ADD   T_UNIVERSITY+10, str_university
    T_ADD   T_UNIVERSITY+11, str_university
    T_ADD   T_UNIVERSITY+12, str_university
    T_ADD   T_UNIVERSITY+13, str_university
    T_ADD   T_UNIVERSITY+14, str_university
    T_ADD   T_UNIVERSITY+15, str_university
    T_ADD   T_UNIVERSITY+16, str_university
    T_ADD   T_UNIVERSITY+17, str_university
    T_ADD   T_UNIVERSITY+18, str_university
    T_ADD   T_UNIVERSITY+19, str_university
    T_ADD   T_UNIVERSITY+20, str_university
    T_ADD   T_UNIVERSITY+21, str_university
    T_ADD   T_UNIVERSITY+22, str_university
    T_ADD   T_UNIVERSITY+23, str_university
    T_ADD   T_UNIVERSITY+24, str_university

    T_ADD   T_MUSEUM+0,  str_museum
    T_ADD   T_MUSEUM+1,  str_museum
    T_ADD   T_MUSEUM+2,  str_museum
    T_ADD   T_MUSEUM+3,  str_museum
    T_ADD   T_MUSEUM+4,  str_museum
    T_ADD   T_MUSEUM+5,  str_museum
    T_ADD   T_MUSEUM+6,  str_museum
    T_ADD   T_MUSEUM+7,  str_museum
    T_ADD   T_MUSEUM+8,  str_museum
    T_ADD   T_MUSEUM+9,  str_museum
    T_ADD   T_MUSEUM+10, str_museum
    T_ADD   T_MUSEUM+11, str_museum

    T_ADD   T_LIBRARY+0, str_library
    T_ADD   T_LIBRARY+1, str_library
    T_ADD   T_LIBRARY+2, str_library
    T_ADD   T_LIBRARY+3, str_library
    T_ADD   T_LIBRARY+4, str_library
    T_ADD   T_LIBRARY+5, str_library

    T_ADD   T_AIRPORT+0,  str_ariport
    T_ADD   T_AIRPORT+1,  str_ariport
    T_ADD   T_AIRPORT+2,  str_ariport
    T_ADD   T_AIRPORT+3,  str_ariport
    T_ADD   T_AIRPORT+4,  str_ariport
    T_ADD   T_AIRPORT+5,  str_ariport
    T_ADD   T_AIRPORT+6,  str_ariport
    T_ADD   T_AIRPORT+7,  str_ariport
    T_ADD   T_AIRPORT+8,  str_ariport
    T_ADD   T_AIRPORT+9,  str_ariport
    T_ADD   T_AIRPORT+10, str_ariport
    T_ADD   T_AIRPORT+11, str_ariport
    T_ADD   T_AIRPORT+12, str_ariport
    T_ADD   T_AIRPORT+13, str_ariport
    T_ADD   T_AIRPORT+14, str_ariport

    T_ADD   T_PORT+0, str_port
    T_ADD   T_PORT+1, str_port
    T_ADD   T_PORT+2, str_port
    T_ADD   T_PORT+3, str_port
    T_ADD   T_PORT+4, str_port
    T_ADD   T_PORT+5, str_port
    T_ADD   T_PORT+6, str_port
    T_ADD   T_PORT+7, str_port
    T_ADD   T_PORT+8, str_port

    T_ADD   T_PORT_WATER_L, str_dock
    T_ADD   T_PORT_WATER_R, str_dock
    T_ADD   T_PORT_WATER_D, str_dock
    T_ADD   T_PORT_WATER_U, str_dock

    T_ADD   T_POWER_PLANT_COAL+0,  str_power_coal
    T_ADD   T_POWER_PLANT_COAL+1,  str_power_coal
    T_ADD   T_POWER_PLANT_COAL+2,  str_power_coal
    T_ADD   T_POWER_PLANT_COAL+3,  str_power_coal
    T_ADD   T_POWER_PLANT_COAL+4,  str_power_coal
    T_ADD   T_POWER_PLANT_COAL+5,  str_power_coal
    T_ADD   T_POWER_PLANT_COAL+6,  str_power_coal
    T_ADD   T_POWER_PLANT_COAL+7,  str_power_coal
    T_ADD   T_POWER_PLANT_COAL+8,  str_power_coal
    T_ADD   T_POWER_PLANT_COAL+9,  str_power_coal
    T_ADD   T_POWER_PLANT_COAL+10, str_power_coal
    T_ADD   T_POWER_PLANT_COAL+11, str_power_coal
    T_ADD   T_POWER_PLANT_COAL+12, str_power_coal
    T_ADD   T_POWER_PLANT_COAL+13, str_power_coal
    T_ADD   T_POWER_PLANT_COAL+14, str_power_coal
    T_ADD   T_POWER_PLANT_COAL+15, str_power_coal

    T_ADD   T_POWER_PLANT_OIL+0,  str_power_oil
    T_ADD   T_POWER_PLANT_OIL+1,  str_power_oil
    T_ADD   T_POWER_PLANT_OIL+2,  str_power_oil
    T_ADD   T_POWER_PLANT_OIL+3,  str_power_oil
    T_ADD   T_POWER_PLANT_OIL+4,  str_power_oil
    T_ADD   T_POWER_PLANT_OIL+5,  str_power_oil
    T_ADD   T_POWER_PLANT_OIL+6,  str_power_oil
    T_ADD   T_POWER_PLANT_OIL+7,  str_power_oil
    T_ADD   T_POWER_PLANT_OIL+8,  str_power_oil
    T_ADD   T_POWER_PLANT_OIL+9,  str_power_oil
    T_ADD   T_POWER_PLANT_OIL+10, str_power_oil
    T_ADD   T_POWER_PLANT_OIL+11, str_power_oil
    T_ADD   T_POWER_PLANT_OIL+12, str_power_oil
    T_ADD   T_POWER_PLANT_OIL+13, str_power_oil
    T_ADD   T_POWER_PLANT_OIL+14, str_power_oil
    T_ADD   T_POWER_PLANT_OIL+15, str_power_oil

    T_ADD   T_POWER_PLANT_WIND+0, str_power_wind
    T_ADD   T_POWER_PLANT_WIND+1, str_power_wind
    T_ADD   T_POWER_PLANT_WIND+2, str_power_wind
    T_ADD   T_POWER_PLANT_WIND+3, str_power_wind

    T_ADD   T_POWER_PLANT_SOLAR+0,  str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+1,  str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+2,  str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+3,  str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+4,  str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+5,  str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+6,  str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+7,  str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+8,  str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+9,  str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+10, str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+11, str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+12, str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+13, str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+14, str_power_solar
    T_ADD   T_POWER_PLANT_SOLAR+15, str_power_solar

    T_ADD   T_POWER_PLANT_NUCLEAR+0,  str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+1,  str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+2,  str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+3,  str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+4,  str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+5,  str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+6,  str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+7,  str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+8,  str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+9,  str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+10, str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+11, str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+12, str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+13, str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+14, str_power_nuclear
    T_ADD   T_POWER_PLANT_NUCLEAR+15, str_power_nuclear

    T_ADD   T_POWER_PLANT_FUSION+0,  str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+1,  str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+2,  str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+3,  str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+4,  str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+5,  str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+6,  str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+7,  str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+8,  str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+9,  str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+10, str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+11, str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+12, str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+13, str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+14, str_power_fusion
    T_ADD   T_POWER_PLANT_FUSION+15, str_power_fusion

    T_ADD   T_RESIDENTIAL_S1_A, str_residential_1
    T_ADD   T_RESIDENTIAL_S1_B, str_residential_1
    T_ADD   T_RESIDENTIAL_S1_C, str_residential_1
    T_ADD   T_RESIDENTIAL_S1_D, str_residential_1

    T_ADD   T_RESIDENTIAL_S2_A+0, str_residential_2
    T_ADD   T_RESIDENTIAL_S2_A+1, str_residential_2
    T_ADD   T_RESIDENTIAL_S2_A+2, str_residential_2
    T_ADD   T_RESIDENTIAL_S2_A+3, str_residential_2

    T_ADD   T_RESIDENTIAL_S2_B+0, str_residential_2
    T_ADD   T_RESIDENTIAL_S2_B+1, str_residential_2
    T_ADD   T_RESIDENTIAL_S2_B+2, str_residential_2
    T_ADD   T_RESIDENTIAL_S2_B+3, str_residential_2

    T_ADD   T_RESIDENTIAL_S2_C+0, str_residential_2
    T_ADD   T_RESIDENTIAL_S2_C+1, str_residential_2
    T_ADD   T_RESIDENTIAL_S2_C+2, str_residential_2
    T_ADD   T_RESIDENTIAL_S2_C+3, str_residential_2

    T_ADD   T_RESIDENTIAL_S2_D+0, str_residential_2
    T_ADD   T_RESIDENTIAL_S2_D+1, str_residential_2
    T_ADD   T_RESIDENTIAL_S2_D+2, str_residential_2
    T_ADD   T_RESIDENTIAL_S2_D+3, str_residential_2

    T_ADD   T_RESIDENTIAL_S3_A+0, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_A+1, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_A+2, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_A+3, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_A+4, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_A+5, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_A+6, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_A+7, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_A+8, str_residential_3

    T_ADD   T_RESIDENTIAL_S3_B+0, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_B+1, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_B+2, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_B+3, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_B+4, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_B+5, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_B+6, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_B+7, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_B+8, str_residential_3

    T_ADD   T_RESIDENTIAL_S3_C+0, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_C+1, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_C+2, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_C+3, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_C+4, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_C+5, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_C+6, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_C+7, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_C+8, str_residential_3

    T_ADD   T_RESIDENTIAL_S3_D+0, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_D+1, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_D+2, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_D+3, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_D+4, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_D+5, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_D+6, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_D+7, str_residential_3
    T_ADD   T_RESIDENTIAL_S3_D+8, str_residential_3

    T_ADD   T_COMMERCIAL_S1_A, str_commercial_1
    T_ADD   T_COMMERCIAL_S1_B, str_commercial_1
    T_ADD   T_COMMERCIAL_S1_C, str_commercial_1
    T_ADD   T_COMMERCIAL_S1_D, str_commercial_1

    T_ADD   T_COMMERCIAL_S2_A+0, str_commercial_2
    T_ADD   T_COMMERCIAL_S2_A+1, str_commercial_2
    T_ADD   T_COMMERCIAL_S2_A+2, str_commercial_2
    T_ADD   T_COMMERCIAL_S2_A+3, str_commercial_2

    T_ADD   T_COMMERCIAL_S2_B+0, str_commercial_2
    T_ADD   T_COMMERCIAL_S2_B+1, str_commercial_2
    T_ADD   T_COMMERCIAL_S2_B+2, str_commercial_2
    T_ADD   T_COMMERCIAL_S2_B+3, str_commercial_2

    T_ADD   T_COMMERCIAL_S2_C+0, str_commercial_2
    T_ADD   T_COMMERCIAL_S2_C+1, str_commercial_2
    T_ADD   T_COMMERCIAL_S2_C+2, str_commercial_2
    T_ADD   T_COMMERCIAL_S2_C+3, str_commercial_2

    T_ADD   T_COMMERCIAL_S2_D+0, str_commercial_2
    T_ADD   T_COMMERCIAL_S2_D+1, str_commercial_2
    T_ADD   T_COMMERCIAL_S2_D+2, str_commercial_2
    T_ADD   T_COMMERCIAL_S2_D+3, str_commercial_2

    T_ADD   T_COMMERCIAL_S3_A+0, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_A+1, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_A+2, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_A+3, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_A+4, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_A+5, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_A+6, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_A+7, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_A+8, str_commercial_3

    T_ADD   T_COMMERCIAL_S3_B+0, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_B+1, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_B+2, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_B+3, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_B+4, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_B+5, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_B+6, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_B+7, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_B+8, str_commercial_3

    T_ADD   T_COMMERCIAL_S3_C+0, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_C+1, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_C+2, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_C+3, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_C+4, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_C+5, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_C+6, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_C+7, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_C+8, str_commercial_3

    T_ADD   T_COMMERCIAL_S3_D+0, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_D+1, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_D+2, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_D+3, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_D+4, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_D+5, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_D+6, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_D+7, str_commercial_3
    T_ADD   T_COMMERCIAL_S3_D+8, str_commercial_3

    T_ADD   T_INDUSTRIAL_S1_A, str_industrial_1
    T_ADD   T_INDUSTRIAL_S1_B, str_industrial_1
    T_ADD   T_INDUSTRIAL_S1_C, str_industrial_1
    T_ADD   T_INDUSTRIAL_S1_D, str_industrial_1

    T_ADD   T_INDUSTRIAL_S2_A+0, str_industrial_2
    T_ADD   T_INDUSTRIAL_S2_A+1, str_industrial_2
    T_ADD   T_INDUSTRIAL_S2_A+2, str_industrial_2
    T_ADD   T_INDUSTRIAL_S2_A+3, str_industrial_2

    T_ADD   T_INDUSTRIAL_S2_B+0, str_industrial_2
    T_ADD   T_INDUSTRIAL_S2_B+1, str_industrial_2
    T_ADD   T_INDUSTRIAL_S2_B+2, str_industrial_2
    T_ADD   T_INDUSTRIAL_S2_B+3, str_industrial_2

    T_ADD   T_INDUSTRIAL_S2_C+0, str_industrial_2
    T_ADD   T_INDUSTRIAL_S2_C+1, str_industrial_2
    T_ADD   T_INDUSTRIAL_S2_C+2, str_industrial_2
    T_ADD   T_INDUSTRIAL_S2_C+3, str_industrial_2

    T_ADD   T_INDUSTRIAL_S2_D+0, str_industrial_2
    T_ADD   T_INDUSTRIAL_S2_D+1, str_industrial_2
    T_ADD   T_INDUSTRIAL_S2_D+2, str_industrial_2
    T_ADD   T_INDUSTRIAL_S2_D+3, str_industrial_2

    T_ADD   T_INDUSTRIAL_S3_A+0, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_A+1, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_A+2, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_A+3, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_A+4, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_A+5, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_A+6, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_A+7, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_A+8, str_industrial_3

    T_ADD   T_INDUSTRIAL_S3_B+0, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_B+1, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_B+2, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_B+3, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_B+4, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_B+5, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_B+6, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_B+7, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_B+8, str_industrial_3

    T_ADD   T_INDUSTRIAL_S3_C+0, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_C+1, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_C+2, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_C+3, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_C+4, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_C+5, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_C+6, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_C+7, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_C+8, str_industrial_3

    T_ADD   T_INDUSTRIAL_S3_D+0, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_D+1, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_D+2, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_D+3, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_D+4, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_D+5, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_D+6, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_D+7, str_industrial_3
    T_ADD   T_INDUSTRIAL_S3_D+8, str_industrial_3

    T_ADD   T_FIRE_1, str_fire
    T_ADD   T_FIRE_2, str_fire

    T_ADD   T_RADIATION_GROUND, str_radiation_ground
    T_ADD   T_RADIATION_WATER,  str_radiation_water

    TILE_SET_COUNT 512 ; Fill array

;-------------------------------------------------------------------------------

PrintTileNameAt:: ; de = tile number, bc = destination

    ld      hl,CITY_TILE_NAME
    add     hl,de
    add     hl,de
    ld      a,[hl+] ; LSB first
    ld      h,[hl]
    ld      l,a ; Pointer to string

.loop:
    ld      a,[hl+]
    ld      [bc],a ; Write string terminator!
    and     a,a
    ret     z
    inc     bc
    jr      .loop

;###############################################################################
