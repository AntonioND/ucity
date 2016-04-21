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

    IF !DEF(TILESET_INFO_INC)
TILESET_INFO_INC SET 1

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
T_ROAD_LR               EQU 35 ; Joins left and right (horizontal)
T_ROAD_RB               EQU 36
T_ROAD_LB               EQU 37
T_ROAD_TR               EQU 38
T_ROAD_TL               EQU 39
T_ROAD_TRB              EQU 40
T_ROAD_LRB              EQU 41
T_ROAD_TLB              EQU 42
T_ROAD_TLR              EQU 43
T_ROAD_TLRB             EQU 44 ; 2 roads crossing
T_ROAD_TB_POWER_LINES   EQU 45 ; Road + power lines
T_ROAD_LR_POWER_LINES   EQU 46
T_ROAD_TB_BRIDGE        EQU 47 ; Bridge
T_ROAD_LR_BRIDGE        EQU 48

; Train
T_TRAIN_TB              EQU 49 ; Joins top and bottom (vertical)
T_TRAIN_LR              EQU 50 ; Joins left and right (horizontal)
T_TRAIN_RB              EQU 51
T_TRAIN_LB              EQU 52
T_TRAIN_TR              EQU 53
T_TRAIN_TL              EQU 54
T_TRAIN_TRB             EQU 55
T_TRAIN_LRB             EQU 56
T_TRAIN_TLB             EQU 57
T_TRAIN_TLR             EQU 58
T_TRAIN_TLRB            EQU 59 ; Crossing
T_TRAIN_LR_ROAD         EQU 60 ; Train + road
T_TRAIN_TB_ROAD         EQU 61
T_TRAIN_TB_POWER_LINES  EQU 62 ; Train + power lines
T_TRAIN_LR_POWER_LINES  EQU 63
T_TRAIN_TB_BRIDGE       EQU 64 ; Bridge
T_TRAIN_LR_BRIDGE       EQU 65

; Power lines
T_POWER_LINES_TB        EQU 66 ; Joins top and bottom (vertical)
T_POWER_LINES_LR        EQU 67 ; Joins left and right (horizontal)
T_POWER_LINES_RB        EQU 68
T_POWER_LINES_LB        EQU 69
T_POWER_LINES_TR        EQU 70
T_POWER_LINES_TL        EQU 71
T_POWER_LINES_TRB       EQU 72
T_POWER_LINES_LRB       EQU 73
T_POWER_LINES_TLB       EQU 74
T_POWER_LINES_TLR       EQU 75
T_POWER_LINES_TLRB      EQU 76 ; 2 lines crossing
T_POWER_LINES_TB_BRIDGE EQU 77 ; Bridge
T_POWER_LINES_LR_BRIDGE EQU 78

; Buildings: Services
T_POLICE          EQU 79
T_POLICE_CENTER   EQU T_POLICE+4 ; 4=3+1 (3x3 building)
T_FIREMEN         EQU 88
T_FIREMEN_CENTER  EQU T_FIREMEN+4
T_HOSPITAL        EQU 97
T_HOSPITAL_CENTER EQU T_HOSPITAL+4

T_PARK_SMALL    EQU 106
T_PARK_BIG      EQU 107
T_STADIUM       EQU 116

T_SCHOOL        EQU 136
T_HIGH_SCHOOL   EQU 142
T_UNIVERSITY    EQU 151
T_MUSEUM        EQU 176
T_LIBRARY       EQU 188

T_TRAIN_STATION EQU 194
T_AIRPORT       EQU 198
T_PORT          EQU 213
T_PORT_WATER_L  EQU 222
T_PORT_WATER_R  EQU 223
T_PORT_WATER_D  EQU 224
T_PORT_WATER_U  EQU 225

; Power plants
T_POWER_PLANT_COAL    EQU 226
T_POWER_PLANT_OIL     EQU 242
T_POWER_PLANT_WIND    EQU 258
T_POWER_PLANT_SOLAR   EQU 262
T_POWER_PLANT_NUCLEAR EQU 278
T_POWER_PLANT_FUSION  EQU 294

; Residential
T_RESIDENTIAL_S1_A EQU 310
T_RESIDENTIAL_S1_B EQU 311
T_RESIDENTIAL_S1_C EQU 312
T_RESIDENTIAL_S1_D EQU 313

T_RESIDENTIAL_S2_A EQU 314
T_RESIDENTIAL_S2_B EQU 318
T_RESIDENTIAL_S2_C EQU 322
T_RESIDENTIAL_S2_D EQU 326

T_RESIDENTIAL_S3_A EQU 330
T_RESIDENTIAL_S3_B EQU 339
T_RESIDENTIAL_S3_C EQU 348
T_RESIDENTIAL_S3_D EQU 357

; Commercial
T_COMMERCIAL_S1_A  EQU 366
T_COMMERCIAL_S1_B  EQU 367
T_COMMERCIAL_S1_C  EQU 368
T_COMMERCIAL_S1_D  EQU 369

T_COMMERCIAL_S2_A  EQU 370
T_COMMERCIAL_S2_B  EQU 374
T_COMMERCIAL_S2_C  EQU 378
T_COMMERCIAL_S2_D  EQU 382

T_COMMERCIAL_S3_A  EQU 386
T_COMMERCIAL_S3_B  EQU 395
T_COMMERCIAL_S3_C  EQU 404
T_COMMERCIAL_S3_D  EQU 413

; Industrial
T_INDUSTRIAL_S1_A  EQU 422
T_INDUSTRIAL_S1_B  EQU 423
T_INDUSTRIAL_S1_C  EQU 424
T_INDUSTRIAL_S1_D  EQU 425

T_INDUSTRIAL_S2_A  EQU 426
T_INDUSTRIAL_S2_B  EQU 430
T_INDUSTRIAL_S2_C  EQU 434
T_INDUSTRIAL_S2_D  EQU 438

T_INDUSTRIAL_S3_A  EQU 442
T_INDUSTRIAL_S3_B  EQU 451
T_INDUSTRIAL_S3_C  EQU 460
T_INDUSTRIAL_S3_D  EQU 469

; Unique buildings (only one per map) ?
T_CITY_HALL EQU 478
T_RESEARCH_CENTRE EQU 500
T_LANDMARK EQU 510

;###############################################################################

    ENDC ; TILESET_INFO_INC

;###############################################################################
