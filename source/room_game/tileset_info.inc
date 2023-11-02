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

    IF !DEF(TILESET_INFO_INC)
    DEF TILESET_INFO_INC = 1

;###############################################################################

    DEF TILESET_INFO_ELEMENT_SIZE EQU 4 ; Bytes of each element of TILESET_INFO

;-------------------------------------------------------------------------------

; List of tiles
; -------------

    ; Note: All bridge tiles should be < 256

    ; Grass surrounded by forest
    DEF T_GRASS__FOREST_TL        EQU 0
    DEF T_GRASS__FOREST_TC        EQU 1
    DEF T_GRASS__FOREST_TR        EQU 2
    DEF T_GRASS__FOREST_CL        EQU 3
    DEF T_GRASS                   EQU 4
    DEF T_GRASS__FOREST_CR        EQU 5
    DEF T_GRASS__FOREST_BL        EQU 6
    DEF T_GRASS__FOREST_BC        EQU 7
    DEF T_GRASS__FOREST_BR        EQU 8
    DEF T_GRASS__FOREST_CORNER_TL EQU 9
    DEF T_GRASS__FOREST_CORNER_TR EQU 10
    DEF T_GRASS__FOREST_CORNER_BL EQU 11
    DEF T_GRASS__FOREST_CORNER_BR EQU 12
    DEF T_FOREST                  EQU 13
    DEF T_GRASS_EXTRA             EQU 14
    DEF T_FOREST_EXTRA            EQU 15

    ; Water surrounded by grass
    DEF T_WATER__GRASS_TL         EQU 16
    DEF T_WATER__GRASS_TC         EQU 17
    DEF T_WATER__GRASS_TR         EQU 18
    DEF T_WATER__GRASS_CL         EQU 19
    DEF T_WATER                   EQU 20
    DEF T_WATER__GRASS_CR         EQU 21
    DEF T_WATER__GRASS_BL         EQU 22
    DEF T_WATER__GRASS_BC         EQU 23
    DEF T_WATER__GRASS_BR         EQU 24
    DEF T_WATER__GRASS_CORNER_TL  EQU 25
    DEF T_WATER__GRASS_CORNER_TR  EQU 26
    DEF T_WATER__GRASS_CORNER_BL  EQU 27
    DEF T_WATER__GRASS_CORNER_BR  EQU 28
    DEF T_WATER_EXTRA             EQU 29

    ; Terrains
    DEF T_RESIDENTIAL EQU 30
    DEF T_COMMERCIAL  EQU 31
    DEF T_INDUSTRIAL  EQU 32 ; <- This must be the highest of the 3 and should be before
    DEF T_DEMOLISHED  EQU 33 ;    all the RCI buildings. Also, they must be < 256

    ; Road
    DEF T_ROAD_TB               EQU 34 ; Joins top and bottom (vertical)
    DEF T_ROAD_TB_1             EQU 35
    DEF T_ROAD_TB_2             EQU 36
    DEF T_ROAD_TB_3             EQU 37
    DEF T_ROAD_LR               EQU 38 ; Joins left and right (horizontal)
    DEF T_ROAD_LR_1             EQU 39
    DEF T_ROAD_LR_2             EQU 40
    DEF T_ROAD_LR_3             EQU 41
    DEF T_ROAD_RB               EQU 42
    DEF T_ROAD_LB               EQU 43
    DEF T_ROAD_TR               EQU 44
    DEF T_ROAD_TL               EQU 45
    DEF T_ROAD_TRB              EQU 46
    DEF T_ROAD_LRB              EQU 47
    DEF T_ROAD_TLB              EQU 48
    DEF T_ROAD_TLR              EQU 49
    DEF T_ROAD_TLRB             EQU 50 ; 2 roads crossing
    DEF T_ROAD_TB_POWER_LINES   EQU 51 ; Road + power lines
    DEF T_ROAD_LR_POWER_LINES   EQU 52
    DEF T_ROAD_TB_BRIDGE        EQU 53 ; Bridge
    DEF T_ROAD_LR_BRIDGE        EQU 54

    ; Train
    DEF T_TRAIN_TB              EQU 55 ; Joins top and bottom (vertical)
    DEF T_TRAIN_LR              EQU 56 ; Joins left and right (horizontal)
    DEF T_TRAIN_RB              EQU 57
    DEF T_TRAIN_LB              EQU 58
    DEF T_TRAIN_TR              EQU 59
    DEF T_TRAIN_TL              EQU 60
    DEF T_TRAIN_TRB             EQU 61
    DEF T_TRAIN_LRB             EQU 62
    DEF T_TRAIN_TLB             EQU 63
    DEF T_TRAIN_TLR             EQU 64
    DEF T_TRAIN_TLRB            EQU 65 ; Crossing
    DEF T_TRAIN_LR_ROAD         EQU 66 ; Train + road
    DEF T_TRAIN_TB_ROAD         EQU 67
    DEF T_TRAIN_TB_POWER_LINES  EQU 68 ; Train + power lines
    DEF T_TRAIN_LR_POWER_LINES  EQU 69
    DEF T_TRAIN_TB_BRIDGE       EQU 70 ; Bridge
    DEF T_TRAIN_LR_BRIDGE       EQU 71

    ; Power lines
    DEF T_POWER_LINES_TB        EQU 72 ; Joins top and bottom (vertical)
    DEF T_POWER_LINES_LR        EQU 73 ; Joins left and right (horizontal)
    DEF T_POWER_LINES_RB        EQU 74
    DEF T_POWER_LINES_LB        EQU 75
    DEF T_POWER_LINES_TR        EQU 76
    DEF T_POWER_LINES_TL        EQU 77
    DEF T_POWER_LINES_TRB       EQU 78
    DEF T_POWER_LINES_LRB       EQU 79
    DEF T_POWER_LINES_TLB       EQU 80
    DEF T_POWER_LINES_TLR       EQU 81
    DEF T_POWER_LINES_TLRB      EQU 82 ; 2 lines crossing
    DEF T_POWER_LINES_TB_BRIDGE EQU 83 ; Bridge
    DEF T_POWER_LINES_LR_BRIDGE EQU 84

    ; Buildings: Services
    DEF T_POLICE_DEPT        EQU 85
    DEF T_POLICE_DEPT_CENTER EQU T_POLICE_DEPT+4 ; 4=3+1 (3x3 building)
    DEF T_FIRE_DEPT          EQU 94
    DEF T_FIRE_DEPT_CENTER   EQU T_FIRE_DEPT+4
    DEF T_HOSPITAL           EQU 103
    DEF T_HOSPITAL_CENTER    EQU T_HOSPITAL+4

    DEF T_PARK_SMALL    EQU 112
    DEF T_PARK_BIG      EQU 113
    DEF T_STADIUM       EQU 122

    DEF T_SCHOOL             EQU 142
    DEF T_SCHOOL_CENTER      EQU T_SCHOOL+4 ; 4=3+1 (3x2 building)
    DEF T_HIGH_SCHOOL        EQU 148
    DEF T_HIGH_SCHOOL_CENTER EQU T_HIGH_SCHOOL+4 ; 4=3+1 (3x3 building)
    DEF T_UNIVERSITY         EQU 157
    DEF T_MUSEUM             EQU 182
    DEF T_LIBRARY            EQU 194

    DEF T_AIRPORT           EQU 200
    DEF T_AIRPORT_RUNWAY    EQU T_AIRPORT+10 ; 10=5+5+0 (5x3 building)
    DEF T_PORT              EQU 215
    DEF T_PORT_WATER_L      EQU 224 ; Make sure that the docks are all in the same 256
    DEF T_PORT_WATER_R      EQU 225 ; tile bank.
    DEF T_PORT_WATER_D      EQU 226
    DEF T_PORT_WATER_U      EQU 227

    ; Power plants
    DEF T_POWER_PLANT_COAL           EQU 228
    DEF T_POWER_PLANT_OIL            EQU 244
    DEF T_POWER_PLANT_WIND           EQU 260
    DEF T_POWER_PLANT_SOLAR          EQU 264
    DEF T_POWER_PLANT_NUCLEAR        EQU 280
    DEF T_POWER_PLANT_NUCLEAR_CENTER EQU T_POWER_PLANT_NUCLEAR+5 ; 5=4+1 (4x4 building)
    DEF T_POWER_PLANT_FUSION         EQU 296 ; This one should be right after the
                                     ; nuclear one.

    ; Residential
    DEF T_RESIDENTIAL_S1_A EQU 312
    DEF T_RESIDENTIAL_S1_B EQU 313
    DEF T_RESIDENTIAL_S1_C EQU 314
    DEF T_RESIDENTIAL_S1_D EQU 315

    DEF T_RESIDENTIAL_S2_A EQU 316
    DEF T_RESIDENTIAL_S2_B EQU 320
    DEF T_RESIDENTIAL_S2_C EQU 324
    DEF T_RESIDENTIAL_S2_D EQU 328

    DEF T_RESIDENTIAL_S3_A EQU 332
    DEF T_RESIDENTIAL_S3_B EQU 341
    DEF T_RESIDENTIAL_S3_C EQU 350
    DEF T_RESIDENTIAL_S3_D EQU 359

    ; Commercial
    DEF T_COMMERCIAL_S1_A  EQU 368
    DEF T_COMMERCIAL_S1_B  EQU 369
    DEF T_COMMERCIAL_S1_C  EQU 370
    DEF T_COMMERCIAL_S1_D  EQU 371

    DEF T_COMMERCIAL_S2_A  EQU 372
    DEF T_COMMERCIAL_S2_B  EQU 376
    DEF T_COMMERCIAL_S2_C  EQU 380
    DEF T_COMMERCIAL_S2_D  EQU 384

    DEF T_COMMERCIAL_S3_A  EQU 388
    DEF T_COMMERCIAL_S3_B  EQU 397
    DEF T_COMMERCIAL_S3_C  EQU 406
    DEF T_COMMERCIAL_S3_D  EQU 415

    ; Industrial
    DEF T_INDUSTRIAL_S1_A  EQU 424
    DEF T_INDUSTRIAL_S1_B  EQU 425
    DEF T_INDUSTRIAL_S1_C  EQU 426
    DEF T_INDUSTRIAL_S1_D  EQU 427

    DEF T_INDUSTRIAL_S2_A  EQU 428
    DEF T_INDUSTRIAL_S2_B  EQU 432
    DEF T_INDUSTRIAL_S2_C  EQU 436
    DEF T_INDUSTRIAL_S2_D  EQU 440

    DEF T_INDUSTRIAL_S3_A  EQU 444
    DEF T_INDUSTRIAL_S3_B  EQU 453
    DEF T_INDUSTRIAL_S3_C  EQU 462
    DEF T_INDUSTRIAL_S3_D  EQU 471

    DEF T_FIRE_1    EQU 480 ; Make sure this one is even and
    DEF T_FIRE_2    EQU 481 ; this one is odd

    DEF T_RADIATION_GROUND EQU 482
    DEF T_RADIATION_WATER  EQU 483

    ; TODO Unique buildings (only one per map) ?
    DEF T_CITY_HALL EQU 484
    DEF T_RESEARCH_CENTRE EQU 500
    DEF T_LANDMARK EQU 510

;###############################################################################

    ENDC ; TILESET_INFO_INC

;###############################################################################
