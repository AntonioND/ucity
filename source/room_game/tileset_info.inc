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

TILESET_INFO_ELEMENT_SIZE EQU 4 ; Bytes of each element of TILESET_INFO

;-------------------------------------------------------------------------------

; List of tiles
; -------------

; Note: All bridge tiles should be < 256

; Grass surrounded by forest
T_GRASS__FOREST_TL        EQU 0
T_GRASS__FOREST_TC        EQU 1
T_GRASS__FOREST_TR        EQU 2
T_GRASS__FOREST_CL        EQU 3
T_GRASS                   EQU 4
T_GRASS__FOREST_CR        EQU 5
T_GRASS__FOREST_BL        EQU 6
T_GRASS__FOREST_BC        EQU 7
T_GRASS__FOREST_BR        EQU 8
T_GRASS__FOREST_CORNER_TL EQU 9
T_GRASS__FOREST_CORNER_TR EQU 10
T_GRASS__FOREST_CORNER_BL EQU 11
T_GRASS__FOREST_CORNER_BR EQU 12
T_FOREST                  EQU 13
T_GRASS_EXTRA             EQU 14
T_FOREST_EXTRA            EQU 15

; Water surrounded by grass
T_WATER__GRASS_TL         EQU 16
T_WATER__GRASS_TC         EQU 17
T_WATER__GRASS_TR         EQU 18
T_WATER__GRASS_CL         EQU 19
T_WATER                   EQU 20
T_WATER__GRASS_CR         EQU 21
T_WATER__GRASS_BL         EQU 22
T_WATER__GRASS_BC         EQU 23
T_WATER__GRASS_BR         EQU 24
T_WATER__GRASS_CORNER_TL  EQU 25
T_WATER__GRASS_CORNER_TR  EQU 26
T_WATER__GRASS_CORNER_BL  EQU 27
T_WATER__GRASS_CORNER_BR  EQU 28
T_WATER_EXTRA             EQU 29

; Terrains
T_RESIDENTIAL EQU 30
T_COMMERCIAL  EQU 31
T_INDUSTRIAL  EQU 32 ; <- This must be the highest of the 3 and should be before
T_DEMOLISHED  EQU 33 ;    all the RCI buildings. Also, they must be < 256

; Road
T_ROAD_TB               EQU 34 ; Joins top and bottom (vertical)
T_ROAD_TB_1             EQU 35
T_ROAD_TB_2             EQU 36
T_ROAD_TB_3             EQU 37
T_ROAD_LR               EQU 38 ; Joins left and right (horizontal)
T_ROAD_LR_1             EQU 39
T_ROAD_LR_2             EQU 40
T_ROAD_LR_3             EQU 41
T_ROAD_RB               EQU 42
T_ROAD_LB               EQU 43
T_ROAD_TR               EQU 44
T_ROAD_TL               EQU 45
T_ROAD_TRB              EQU 46
T_ROAD_LRB              EQU 47
T_ROAD_TLB              EQU 48
T_ROAD_TLR              EQU 49
T_ROAD_TLRB             EQU 50 ; 2 roads crossing
T_ROAD_TB_POWER_LINES   EQU 51 ; Road + power lines
T_ROAD_LR_POWER_LINES   EQU 52
T_ROAD_TB_BRIDGE        EQU 53 ; Bridge
T_ROAD_LR_BRIDGE        EQU 54

; Train
T_TRAIN_TB              EQU 55 ; Joins top and bottom (vertical)
T_TRAIN_LR              EQU 56 ; Joins left and right (horizontal)
T_TRAIN_RB              EQU 57
T_TRAIN_LB              EQU 58
T_TRAIN_TR              EQU 59
T_TRAIN_TL              EQU 60
T_TRAIN_TRB             EQU 61
T_TRAIN_LRB             EQU 62
T_TRAIN_TLB             EQU 63
T_TRAIN_TLR             EQU 64
T_TRAIN_TLRB            EQU 65 ; Crossing
T_TRAIN_LR_ROAD         EQU 66 ; Train + road
T_TRAIN_TB_ROAD         EQU 67
T_TRAIN_TB_POWER_LINES  EQU 68 ; Train + power lines
T_TRAIN_LR_POWER_LINES  EQU 69
T_TRAIN_TB_BRIDGE       EQU 70 ; Bridge
T_TRAIN_LR_BRIDGE       EQU 71

; Power lines
T_POWER_LINES_TB        EQU 72 ; Joins top and bottom (vertical)
T_POWER_LINES_LR        EQU 73 ; Joins left and right (horizontal)
T_POWER_LINES_RB        EQU 74
T_POWER_LINES_LB        EQU 75
T_POWER_LINES_TR        EQU 76
T_POWER_LINES_TL        EQU 77
T_POWER_LINES_TRB       EQU 78
T_POWER_LINES_LRB       EQU 79
T_POWER_LINES_TLB       EQU 80
T_POWER_LINES_TLR       EQU 81
T_POWER_LINES_TLRB      EQU 82 ; 2 lines crossing
T_POWER_LINES_TB_BRIDGE EQU 83 ; Bridge
T_POWER_LINES_LR_BRIDGE EQU 84

; Buildings: Services
T_POLICE_DEPT        EQU 85
T_POLICE_DEPT_CENTER EQU T_POLICE_DEPT+4 ; 4=3+1 (3x3 building)
T_FIRE_DEPT          EQU 94
T_FIRE_DEPT_CENTER   EQU T_FIRE_DEPT+4
T_HOSPITAL           EQU 103
T_HOSPITAL_CENTER    EQU T_HOSPITAL+4

T_PARK_SMALL    EQU 112
T_PARK_BIG      EQU 113
T_STADIUM       EQU 122

T_SCHOOL             EQU 142
T_SCHOOL_CENTER      EQU T_SCHOOL+4 ; 4=3+1 (3x2 building)
T_HIGH_SCHOOL        EQU 148
T_HIGH_SCHOOL_CENTER EQU T_HIGH_SCHOOL+4 ; 4=3+1 (3x3 building)
T_UNIVERSITY         EQU 157
T_MUSEUM             EQU 182
T_LIBRARY            EQU 194

T_AIRPORT           EQU 200
T_AIRPORT_RUNWAY    EQU T_AIRPORT+10 ; 10=5+5+0 (5x3 building)
T_PORT              EQU 215
T_PORT_WATER_L      EQU 224 ; Make sure that the docks are all in the same 256
T_PORT_WATER_R      EQU 225 ; tile bank.
T_PORT_WATER_D      EQU 226
T_PORT_WATER_U      EQU 227

; Power plants
T_POWER_PLANT_COAL           EQU 228
T_POWER_PLANT_OIL            EQU 244
T_POWER_PLANT_WIND           EQU 260
T_POWER_PLANT_SOLAR          EQU 264
T_POWER_PLANT_NUCLEAR        EQU 280
T_POWER_PLANT_NUCLEAR_CENTER EQU T_POWER_PLANT_NUCLEAR+5 ; 5=4+1 (4x4 building)
T_POWER_PLANT_FUSION         EQU 296 ; This one should be right after the
                                     ; nuclear one.

; Residential
T_RESIDENTIAL_S1_A EQU 312
T_RESIDENTIAL_S1_B EQU 313
T_RESIDENTIAL_S1_C EQU 314
T_RESIDENTIAL_S1_D EQU 315

T_RESIDENTIAL_S2_A EQU 316
T_RESIDENTIAL_S2_B EQU 320
T_RESIDENTIAL_S2_C EQU 324
T_RESIDENTIAL_S2_D EQU 328

T_RESIDENTIAL_S3_A EQU 332
T_RESIDENTIAL_S3_B EQU 341
T_RESIDENTIAL_S3_C EQU 350
T_RESIDENTIAL_S3_D EQU 359

; Commercial
T_COMMERCIAL_S1_A  EQU 368
T_COMMERCIAL_S1_B  EQU 369
T_COMMERCIAL_S1_C  EQU 370
T_COMMERCIAL_S1_D  EQU 371

T_COMMERCIAL_S2_A  EQU 372
T_COMMERCIAL_S2_B  EQU 376
T_COMMERCIAL_S2_C  EQU 380
T_COMMERCIAL_S2_D  EQU 384

T_COMMERCIAL_S3_A  EQU 388
T_COMMERCIAL_S3_B  EQU 397
T_COMMERCIAL_S3_C  EQU 406
T_COMMERCIAL_S3_D  EQU 415

; Industrial
T_INDUSTRIAL_S1_A  EQU 424
T_INDUSTRIAL_S1_B  EQU 425
T_INDUSTRIAL_S1_C  EQU 426
T_INDUSTRIAL_S1_D  EQU 427

T_INDUSTRIAL_S2_A  EQU 428
T_INDUSTRIAL_S2_B  EQU 432
T_INDUSTRIAL_S2_C  EQU 436
T_INDUSTRIAL_S2_D  EQU 440

T_INDUSTRIAL_S3_A  EQU 444
T_INDUSTRIAL_S3_B  EQU 453
T_INDUSTRIAL_S3_C  EQU 462
T_INDUSTRIAL_S3_D  EQU 471

T_FIRE_1    EQU 480 ; Make sure this one is even and
T_FIRE_2    EQU 481 ; this one is odd

T_RADIATION_GROUND EQU 482
T_RADIATION_WATER  EQU 483

; TODO Unique buildings (only one per map) ?
T_CITY_HALL EQU 484
T_RESEARCH_CENTRE EQU 500
T_LANDMARK EQU 510

;###############################################################################

    ENDC ; TILESET_INFO_INC

;###############################################################################
