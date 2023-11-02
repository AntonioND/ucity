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

    INCLUDE "engine.inc"

;-------------------------------------------------------------------------------

    INCLUDE "building_info.inc"
    INCLUDE "tileset_info.inc"
    INCLUDE "room_game.inc"
    INCLUDE "money.inc"
    INCLUDE "text_messages.inc"

;###############################################################################

    SECTION "Building Information Variables", WRAM0

;-------------------------------------------------------------------------------

building_selected:  DS  1

building_temp_price: DS 5

;###############################################################################

    SECTION "Building Information Functions", ROM0

;-------------------------------------------------------------------------------

; Check technology level and city size to see if a building is available or not.
; Returns b = 1 if available, 0 if not (and shows an error message)
BuildingIsAvailable:: ; b = B_xxxx define

    ; Check technology level

    call    BuildingTypeGet ; returns type in a
    ld      b,a
    LONG_CALL_ARGS  Technology_IsBuildingAvailable
    ld      a,b
    and     a,a
    jr      nz,.enough_technology
        ld      a,ID_MSG_TECH_INSUFFICIENT
        call    MessageRequestAdd
        ld      b,0
        ret
.enough_technology:

    ; Check city size

    call    BuildingTypeGet
    ld      b,a
    LONG_CALL_ARGS  CityStats_IsBuildingAvailable
    ld      a,b
    and     a,a
    and     a,a
    jr      nz,.enough_population
        ld      a,ID_MSG_POPULATION_INSUFFICIENT
        call    MessageRequestAdd
        ld      b,0
        ret
.enough_population:

    ld      b,1 ; return
    ret

;-------------------------------------------------------------------------------

BuildingTypeSelect:: ; a = type. If b != 0, it refreshes cursor as well

    ld      [building_selected],a

    ld      a,b
    and     a,a
    call    nz,BuildingUpdateCursorSize

    ret

BuildingTypeGet:: ; returns type in a

    ld      a,[building_selected]
    ret

;-------------------------------------------------------------------------------

; Input = a (any B_Xxxxx define)
BuildingGetSize:: ; Returns b=width, c=height of selected building. Preserves de

    ld      a,[building_selected]
    cp      a,B_Delete
    ld      bc,$0101
    ; If delete, return (BUILDING_INFO_POINTERS_ARRAY has no entry for it)
    ret     z

    ; Check dimensions of building (including metabuildings)

    ld      b,BANK(BUILDING_INFO_POINTERS_ARRAY)
    call    rom_bank_push_set

    ld      a,[building_selected]
    add     a,a ; * 2
    ld      c,a
    ld      b,0
    ld      hl,BUILDING_INFO_POINTERS_ARRAY
    add     hl,bc

IF BUILDING_INFO_POINTERS_ARRAY_ELEMENT_SIZE != 4
    FAIL "ERROR: Modify this function."
ENDC

    ; Load pointer to data
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ; Load data
    ld      b,[hl]
    inc     hl
    ld      c,[hl]

    call    rom_bank_pop ; preserves bc and de

    ret

;-------------------------------------------------------------------------------

; A = building to check data of. Don't call with B_Delete.
BuildingGetSizeAndBaseTile:: ; Returns b=width, c=height, hl = base tile

    ld      d,a ; (*) preserve A
    ld      b,BANK(BUILDING_INFO_POINTERS_ARRAY)
    call    rom_bank_push_set  ; preserves de
    ld      a,d ; (*) restore A

    jr      building_get_size_base_tile_common

; Return data of currently selected building. Don't call with B_Delete.
BuildingCurrentGetSizeAndBaseTile:: ; Returns b=width, c=height, hl = base tile

    ld      b,BANK(BUILDING_INFO_POINTERS_ARRAY)
    call    rom_bank_push_set

    ld      a,[building_selected]

building_get_size_base_tile_common:
    add     a,a ; * 2
    ld      c,a
    ld      b,0
    ld      hl,BUILDING_INFO_POINTERS_ARRAY
    add     hl,bc

IF BUILDING_INFO_POINTERS_ARRAY_ELEMENT_SIZE != 4
    FAIL "ERROR: Fix this function."
ENDC

    ; Load pointer to data
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ; Load data
    ld      b,[hl]
    inc     hl
    ld      c,[hl]
    inc     hl
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ; return hl and bc

    LD_DE_HL
    call    rom_bank_pop ; preserves bc and de
    LD_HL_DE

    ret

;-------------------------------------------------------------------------------

BuildingUpdateCursorSize:: ; Updates cursor size to the selected building size.

    call    BuildingGetSize ; returns size in tiles
    call    CursorSetSizeTiles

    ret

;-------------------------------------------------------------------------------

; Top level player function, called from CityMapDraw
BuildingBuildAtCursor:: ; B_Delete will remove instead

    ld      a,[building_selected]
    cp      a,B_Delete
    jp      z,BuildingRemoveAtCursor ; Don't call. It will return from there.

    ; Check which kind of element has to be built
    ; -------------------------------------------

    cp      a,B_BuildingMax
    jr      nc,.meta_building

    ; Regular building
    ; ----------------

    LONG_CALL   MapDrawBuilding
    call    bg_refresh_main
    ret

.meta_building:

    ; Meta building
    ; -------------

    cp      a,B_None
    ret     z ; Return, this is a dummy building type

    cp      a,B_Road
    jr      nz,.not_road
    LONG_CALL   MapDrawRoad
    ret
.not_road:

    cp      a,B_Train
    jr      nz,.not_train
    LONG_CALL   MapDrawTrain
    ret
.not_train:

    cp      a,B_PowerLines
    jr      nz,.not_powerlines
    LONG_CALL   MapDrawPowerLines
    ret
.not_powerlines:

    cp      a,B_Port
    jr      nz,.not_port
    LONG_CALL   MapDrawPort
    ret
.not_port:

    ; Unknown, do nothing!
    ; --------------------

    ld      b,b ; Breakpoint

    ret

;-------------------------------------------------------------------------------

; Roads, train tracks and power lines require special handling because it is
; needed to handle bridges in a different way.
BuildingRemoveRoadTrainPowerLines: ; de = coordinates, a = type

    ; Check if this is a bridge
    ; -------------------------

    ld      b,a ; save a
    and     a,TYPE_MASK
    cp      a,TYPE_WATER
    jr      nz,.not_bridge

    ld      a,1 ; check money!
    call    DrawCityDeleteBridgeWithCheck ; doesn't update map internally
    call    bg_refresh_main
    ret

.not_bridge:
    ld      a,b ; restore a

    ; Delete tile
    ; -----------

    push    af
    push    de
    LONG_CALL_ARGS  MapDeleteRoadTrainPowerlines ; pass coordinates
    pop     de
    pop     af

    ld      c,a ; save type in c (*)

    ; If b is 0, an error happened
    ld      a,b
    and     a,a
    ret     z

    ld      a,c ; restore type to a (*)

    ; Update suroundings according to the elements that it had.
    ; ---------------------------------------------------------

    bit     TYPE_HAS_ROAD_BIT,a
    jr      z,.no_road
    push    af
    push    de
    LONG_CALL_ARGS  MapUpdateNeighboursRoad ; doesn't update map
    pop     de
    pop     af
.no_road:

    bit     TYPE_HAS_TRAIN_BIT,a
    jr      z,.no_train
    push    af
    push    de
    LONG_CALL_ARGS  MapUpdateNeighboursTrain ; doesn't update map
    pop     de
    pop     af
.no_train:

    bit     TYPE_HAS_POWER_BIT,a
    jr      z,.no_power_lines
    LONG_CALL_ARGS  MapUpdateNeighboursPowerLines ; doesn't update map
.no_power_lines:

    ; Reload map
    ; ----------

    call    bg_refresh_main

    ret

;-------------------------------------------------------------------------------

BuildingRemoveAtCursor: ; Internal use, called from BuildingBuildAtCursor

    ; Check which kind of element has to be removed
    ; ---------------------------------------------

    call    CursorGetGlobalCoords

BuildingRemoveAtCoords:: ; d = y, e = x

    push    de
    call    CityMapGetType ; a = type
    pop     de ; save coordinates for the delete functions below.

    ; Check for road, train tracks or power lines - and bridges.
    ld      b,a ; save a
    and     a,TYPE_HAS_ROAD|TYPE_HAS_TRAIN|TYPE_HAS_POWER
    ld      a,b
    jr      z,.not_road_train_power
    call    BuildingRemoveRoadTrainPowerLines ; de = coordinates
    ret
.not_road_train_power:

    ; Check for sea ports
    ld      b,a ; save a
    and     a,TYPE_MASK
    cp      a,TYPE_PORT
    ld      a,b
    jr      nz,.not_port
    LONG_CALL_ARGS  MapDeletePort ; de = coordinates
    ret
.not_port:

    ; Can't delete water!
    cp      a,TYPE_WATER
    ret     z

    cp      a,TYPE_FIRE ; Or fire!
    ret     z

    cp      a,TYPE_RADIATION ; Or radiation!
    ret     z

    cp      a,TYPE_FOREST
    jp      z,MapClearDemolishedTile ; call and return from there

    cp      a,TYPE_FIELD ; If field, check if tile is the demolished one.
    jr      nz,.not_field
    push    de
    call    CityMapGetTypeAndTile ; Arguments: e=x , d=y. Returns tile in de
    ld      a,(T_DEMOLISHED>>8)&$FF
    cp      a,d
    jr      nz,.not_demolished
    ld      a,(T_DEMOLISHED)&$FF
    cp      a,e
    jr      nz,.not_demolished
    pop     de ; get coordinates

    jp      MapClearDemolishedTile ; call and return from there

.not_demolished: ; Normal field, do nothing...
    pop     de ; get coordinates
    ret
.not_field:

; All of the following are buildings

    ; Residential, industrial and commercial can be individual tiles or not
    cp      a,TYPE_RESIDENTIAL
    jr      z,.building
    cp      a,TYPE_INDUSTRIAL
    jr      z,.building
    cp      a,TYPE_COMMERCIAL
    jr      z,.building
    cp      a,TYPE_POLICE_DEPT
    jr      z,.building
    cp      a,TYPE_FIRE_DEPT
    jr      z,.building
    cp      a,TYPE_HOSPITAL
    jr      z,.building
    cp      a,TYPE_SCHOOL
    jr      z,.building
    cp      a,TYPE_HIGH_SCHOOL
    jr      z,.building
    cp      a,TYPE_UNIVERSITY
    jr      z,.building
    cp      a,TYPE_MUSEUM
    jr      z,.building
    cp      a,TYPE_LIBRARY
    jr      z,.building
    cp      a,TYPE_STADIUM
    jr      z,.building
    cp      a,TYPE_AIRPORT
    jr      z,.building
    cp      a,TYPE_PARK
    jr      z,.building
    cp      a,TYPE_POWER_PLANT
    jr      z,.building

    jr      .not_building ; error!
.building:
    ; Building!
    call    MapDeleteBuilding ; de should be set from the begining
    call    bg_refresh_main
    ret
.not_building:

    ; Docks can't be deleted manually
    ; -------------------------------
    cp      a,TYPE_DOCK
    ret     z

    ; Shouldn't be here!
    ; ------------------

    ld  b,b ; Breakpoint

    ret

;###############################################################################

    SECTION "Building Information Arrays", ROMX

;###############################################################################

MACRO BUILDING_ADD ; 1=Name, 2=Width, 3=Height, 4=Base Tile
\1: ; Name = address
    DB  \2,\3 ; Width, Height
    DW  \4 ; Save base tile
ENDM

IF BUILDING_INFO_POINTERS_ARRAY_ELEMENT_SIZE != 4
    FAIL "ERROR: Modify element size at building_info.inc"
ENDC

;-------------------------------------------------------------------------------

    ; This is used when selecting the image that represents a certain element
    ; type (roads, train...), not only used for "building" buildings.

; Array of structs. Get building size (if any) from tile number. It can't
; be accessed by entering the tile number, only by searching or by getting the
; address Data_XXXX (from BUILDING_INFO_POINTERS_ARRAY).
BUILDING_INFO_STRUCTS_ARRAY::

    ; Dummy element. The only thing that matters here is the size.
    BUILDING_ADD Data_None, 1, 1, T_DEMOLISHED ; Demolished or something...

    BUILDING_ADD Data_Residential, 1, 1, T_RESIDENTIAL
    BUILDING_ADD Data_Commercial, 1, 1, T_COMMERCIAL
    BUILDING_ADD Data_Industrial, 1, 1, T_INDUSTRIAL

    BUILDING_ADD Data_Road, 1, 1, T_ROAD_LR ; Tile doesn't matter
    BUILDING_ADD Data_Train, 1, 1, T_TRAIN_LR ; Tile doesn't matter
    BUILDING_ADD Data_PowerLines, 1, 1, T_POWER_LINES_LR ; Tile doesn't matter

    ; Modify the corresponding file in 'simulation' folder if changing this:
    BUILDING_ADD Data_PoliceDept, 3, 3, T_POLICE_DEPT
    BUILDING_ADD Data_FireDept, 3, 3, T_FIRE_DEPT
    BUILDING_ADD Data_Hospital, 3, 3, T_HOSPITAL

    BUILDING_ADD Data_ParkSmall, 1, 1, T_PARK_SMALL
    BUILDING_ADD Data_ParkBig, 3, 3, T_PARK_BIG
    BUILDING_ADD Data_Stadium, 5, 4, T_STADIUM

    BUILDING_ADD Data_School, 3, 2, T_SCHOOL
    BUILDING_ADD Data_HighSchool, 3, 3, T_HIGH_SCHOOL
    BUILDING_ADD Data_University, 5, 5, T_UNIVERSITY

    BUILDING_ADD Data_Museum, 4, 3, T_MUSEUM
    BUILDING_ADD Data_Library, 3, 2, T_LIBRARY

    BUILDING_ADD Data_Airport, 5, 3, T_AIRPORT
    BUILDING_ADD Data_Port, 3, 3, T_PORT

    BUILDING_ADD Data_PowerPlantCoal, 4, 4, T_POWER_PLANT_COAL
    BUILDING_ADD Data_PowerPlantOil, 4, 4, T_POWER_PLANT_OIL
    BUILDING_ADD Data_PowerPlantWind, 2, 2, T_POWER_PLANT_WIND
    BUILDING_ADD Data_PowerPlantSolar, 4, 4, T_POWER_PLANT_SOLAR
    BUILDING_ADD Data_PowerPlantNuclear, 4, 4, T_POWER_PLANT_NUCLEAR
    BUILDING_ADD Data_PowerPlantFusion, 4, 4, T_POWER_PLANT_FUSION

    BUILDING_ADD Data_ResidentialS1A, 1, 1, T_RESIDENTIAL_S1_A
    BUILDING_ADD Data_ResidentialS1B, 1, 1, T_RESIDENTIAL_S1_B
    BUILDING_ADD Data_ResidentialS1C, 1, 1, T_RESIDENTIAL_S1_C
    BUILDING_ADD Data_ResidentialS1D, 1, 1, T_RESIDENTIAL_S1_D
    BUILDING_ADD Data_ResidentialS2A, 2, 2, T_RESIDENTIAL_S2_A
    BUILDING_ADD Data_ResidentialS2B, 2, 2, T_RESIDENTIAL_S2_B
    BUILDING_ADD Data_ResidentialS2C, 2, 2, T_RESIDENTIAL_S2_C
    BUILDING_ADD Data_ResidentialS2D, 2, 2, T_RESIDENTIAL_S2_D
    BUILDING_ADD Data_ResidentialS3A, 3, 3, T_RESIDENTIAL_S3_A
    BUILDING_ADD Data_ResidentialS3B, 3, 3, T_RESIDENTIAL_S3_B
    BUILDING_ADD Data_ResidentialS3C, 3, 3, T_RESIDENTIAL_S3_C
    BUILDING_ADD Data_ResidentialS3D, 3, 3, T_RESIDENTIAL_S3_D

    BUILDING_ADD Data_CommercialS1A, 1, 1, T_COMMERCIAL_S1_A
    BUILDING_ADD Data_CommercialS1B, 1, 1, T_COMMERCIAL_S1_B
    BUILDING_ADD Data_CommercialS1C, 1, 1, T_COMMERCIAL_S1_C
    BUILDING_ADD Data_CommercialS1D, 1, 1, T_COMMERCIAL_S1_D
    BUILDING_ADD Data_CommercialS2A, 2, 2, T_COMMERCIAL_S2_A
    BUILDING_ADD Data_CommercialS2B, 2, 2, T_COMMERCIAL_S2_B
    BUILDING_ADD Data_CommercialS2C, 2, 2, T_COMMERCIAL_S2_C
    BUILDING_ADD Data_CommercialS2D, 2, 2, T_COMMERCIAL_S2_D
    BUILDING_ADD Data_CommercialS3A, 3, 3, T_COMMERCIAL_S3_A
    BUILDING_ADD Data_CommercialS3B, 3, 3, T_COMMERCIAL_S3_B
    BUILDING_ADD Data_CommercialS3C, 3, 3, T_COMMERCIAL_S3_C
    BUILDING_ADD Data_CommercialS3D, 3, 3, T_COMMERCIAL_S3_D

    BUILDING_ADD Data_IndustrialS1A, 1, 1, T_INDUSTRIAL_S1_A
    BUILDING_ADD Data_IndustrialS1B, 1, 1, T_INDUSTRIAL_S1_B
    BUILDING_ADD Data_IndustrialS1C, 1, 1, T_INDUSTRIAL_S1_C
    BUILDING_ADD Data_IndustrialS1D, 1, 1, T_INDUSTRIAL_S1_D
    BUILDING_ADD Data_IndustrialS2A, 2, 2, T_INDUSTRIAL_S2_A
    BUILDING_ADD Data_IndustrialS2B, 2, 2, T_INDUSTRIAL_S2_B
    BUILDING_ADD Data_IndustrialS2C, 2, 2, T_INDUSTRIAL_S2_C
    BUILDING_ADD Data_IndustrialS2D, 2, 2, T_INDUSTRIAL_S2_D
    BUILDING_ADD Data_IndustrialS3A, 3, 3, T_INDUSTRIAL_S3_A
    BUILDING_ADD Data_IndustrialS3B, 3, 3, T_INDUSTRIAL_S3_B
    BUILDING_ADD Data_IndustrialS3C, 3, 3, T_INDUSTRIAL_S3_C
    BUILDING_ADD Data_IndustrialS3D, 3, 3, T_INDUSTRIAL_S3_D

    BUILDING_ADD Data_RadiationGround, 1, 1, T_RADIATION_GROUND
    BUILDING_ADD Data_RadiationWater,  1, 1, T_RADIATION_WATER

    BUILDING_ADD Data_End, 0, 0, $FFFF ; Empty element -> END

;-------------------------------------------------------------------------------

IF BUILDING_INFO_POINTERS_ARRAY_ELEMENT_SIZE != 4
    FAIL "ERROR: Modify element size at building_info.inc"
ENDC

MACRO BUILDING_GET_SIZE_FROM_BASE_TILE ; \1 = ignore debug errors if this is 0

    ; Search!
    ld      hl,BUILDING_INFO_STRUCTS_ARRAY+2 ; start from tile info

.loop:
    ld      a,[hl+] ; LSB
    ld      d,[hl] ; MSB
    ld      e,a ; de = array element base tile

    and     a,d
    cp      a,$FF
    jr      nz,.not_end_error ; $FFFF = last element...
IF \1 != 0
        ; Error!
        ld      b,b
ENDC
        ld      de,$0101 ; Try not to delete anything... This shouldn't happen
        ret
.not_end_error:

    ld      a,c
    cp      a,e
    jr      nz,.continue

    ld      a,b
    cp      a,d
    jr      nz,.continue

    ; This is a match!
    ld      de,-3 ; point to start of this element
    add     hl,de
    ld      e,[hl]
    inc     hl
    ld      d,[hl]
    ret ; return e = width, d = heigth

.continue:
    ld      de,3
    add     hl,de ; point to next element

    jr      .loop

ENDM

; bc = base tile. returns size: d=height, e=width
; If it didn't find a building with that base tile, breakpoint and return 1x1.
BuildingGetSizeFromBaseTile::
    BUILDING_GET_SIZE_FROM_BASE_TILE 1

; bc = base tile. returns size: d=height, e=width.
; If it didn't find a building with that base tile, return 1x1
BuildingGetSizeFromBaseTileIgnoreErrors::
    BUILDING_GET_SIZE_FROM_BASE_TILE 0

;###############################################################################

    DEF CURINDEX = 0

MACRO BUILDING_SET_INDEX ; 1 = Index
    IF (\1) < CURINDEX ; check if going backwards and stop if so
        FAIL "ERROR : building_info.asm : Index already in use!"
    ENDC
    IF (\1) > CURINDEX ; If there's a hole to fill, fill it
        REPT (\1) - CURINDEX
            DW $0000
        ENDR
    ENDC
    DEF CURINDEX = (\1)
ENDM

MACRO BUILDING_ADD_ENTRY ; 1=Name, 2=Width, 3=Height
    BUILDING_SET_INDEX \1
    DW  \2
    DEF CURINDEX = CURINDEX + 1
ENDM

;-------------------------------------------------------------------------------

BUILDING_INFO_POINTERS_ARRAY:: ; Pointers to structs. Indexes are B_Xxxxxx
    BUILDING_SET_INDEX 0

    BUILDING_ADD_ENTRY B_Residential, Data_Residential
    BUILDING_ADD_ENTRY B_Commercial, Data_Commercial
    BUILDING_ADD_ENTRY B_Industrial, Data_Industrial

    BUILDING_ADD_ENTRY B_PoliceDept, Data_PoliceDept
    BUILDING_ADD_ENTRY B_FireDept, Data_FireDept
    BUILDING_ADD_ENTRY B_Hospital, Data_Hospital

    BUILDING_ADD_ENTRY B_ParkSmall, Data_ParkSmall
    BUILDING_ADD_ENTRY B_ParkBig, Data_ParkBig
    BUILDING_ADD_ENTRY B_Stadium, Data_Stadium

    BUILDING_ADD_ENTRY B_School, Data_School
    BUILDING_ADD_ENTRY B_HighSchool, Data_HighSchool
    BUILDING_ADD_ENTRY B_University, Data_University

    BUILDING_ADD_ENTRY B_Museum, Data_Museum
    BUILDING_ADD_ENTRY B_Library, Data_Library

    BUILDING_ADD_ENTRY B_Airport, Data_Airport

    BUILDING_ADD_ENTRY B_PowerPlantCoal, Data_PowerPlantCoal
    BUILDING_ADD_ENTRY B_PowerPlantOil, Data_PowerPlantOil
    BUILDING_ADD_ENTRY B_PowerPlantWind, Data_PowerPlantWind
    BUILDING_ADD_ENTRY B_PowerPlantSolar, Data_PowerPlantSolar
    BUILDING_ADD_ENTRY B_PowerPlantNuclear, Data_PowerPlantNuclear
    BUILDING_ADD_ENTRY B_PowerPlantFusion, Data_PowerPlantFusion

    BUILDING_ADD_ENTRY B_None, Data_None

    BUILDING_ADD_ENTRY B_Road, Data_Road
    BUILDING_ADD_ENTRY B_Train, Data_Train
    BUILDING_ADD_ENTRY B_PowerLines, Data_PowerLines

    BUILDING_ADD_ENTRY B_Port, Data_Port

    BUILDING_ADD_ENTRY B_ResidentialS1A, Data_ResidentialS1A
    BUILDING_ADD_ENTRY B_ResidentialS1B, Data_ResidentialS1B
    BUILDING_ADD_ENTRY B_ResidentialS1C, Data_ResidentialS1C
    BUILDING_ADD_ENTRY B_ResidentialS1D, Data_ResidentialS1D
    BUILDING_ADD_ENTRY B_ResidentialS2A, Data_ResidentialS2A
    BUILDING_ADD_ENTRY B_ResidentialS2B, Data_ResidentialS2B
    BUILDING_ADD_ENTRY B_ResidentialS2C, Data_ResidentialS2C
    BUILDING_ADD_ENTRY B_ResidentialS2D, Data_ResidentialS2D
    BUILDING_ADD_ENTRY B_ResidentialS3A, Data_ResidentialS3A
    BUILDING_ADD_ENTRY B_ResidentialS3B, Data_ResidentialS3B
    BUILDING_ADD_ENTRY B_ResidentialS3C, Data_ResidentialS3C
    BUILDING_ADD_ENTRY B_ResidentialS3D, Data_ResidentialS3D

    BUILDING_ADD_ENTRY B_CommercialS1A, Data_CommercialS1A
    BUILDING_ADD_ENTRY B_CommercialS1B, Data_CommercialS1B
    BUILDING_ADD_ENTRY B_CommercialS1C, Data_CommercialS1C
    BUILDING_ADD_ENTRY B_CommercialS1D, Data_CommercialS1D
    BUILDING_ADD_ENTRY B_CommercialS2A, Data_CommercialS2A
    BUILDING_ADD_ENTRY B_CommercialS2B, Data_CommercialS2B
    BUILDING_ADD_ENTRY B_CommercialS2C, Data_CommercialS2C
    BUILDING_ADD_ENTRY B_CommercialS2D, Data_CommercialS2D
    BUILDING_ADD_ENTRY B_CommercialS3A, Data_CommercialS3A
    BUILDING_ADD_ENTRY B_CommercialS3B, Data_CommercialS3B
    BUILDING_ADD_ENTRY B_CommercialS3C, Data_CommercialS3C
    BUILDING_ADD_ENTRY B_CommercialS3D, Data_CommercialS3D

    BUILDING_ADD_ENTRY B_IndustrialS1A, Data_IndustrialS1A
    BUILDING_ADD_ENTRY B_IndustrialS1B, Data_IndustrialS1B
    BUILDING_ADD_ENTRY B_IndustrialS1C, Data_IndustrialS1C
    BUILDING_ADD_ENTRY B_IndustrialS1D, Data_IndustrialS1D
    BUILDING_ADD_ENTRY B_IndustrialS2A, Data_IndustrialS2A
    BUILDING_ADD_ENTRY B_IndustrialS2B, Data_IndustrialS2B
    BUILDING_ADD_ENTRY B_IndustrialS2C, Data_IndustrialS2C
    BUILDING_ADD_ENTRY B_IndustrialS2D, Data_IndustrialS2D
    BUILDING_ADD_ENTRY B_IndustrialS3A, Data_IndustrialS3A
    BUILDING_ADD_ENTRY B_IndustrialS3B, Data_IndustrialS3B
    BUILDING_ADD_ENTRY B_IndustrialS3C, Data_IndustrialS3C
    BUILDING_ADD_ENTRY B_IndustrialS3D, Data_IndustrialS3D

    BUILDING_ADD_ENTRY B_RadiationGround, Data_RadiationGround
    BUILDING_ADD_ENTRY B_RadiationWater,  Data_RadiationWater

;###############################################################################

    SECTION "Building Information Arrays Bank 0", ROM0

;###############################################################################

    DEF CURINDEX = 0

MACRO BUILDING_SET_PRICE ; 1 = Index, 2=Pointer to price
    IF (\1) < CURINDEX ; check if going backwards and stop if so
        FAIL "ERROR : building_info.asm : Index already in use!"
    ENDC
    IF (\1) > CURINDEX ; If there's a hole to fill, fill it
        REPT (\1) - CURINDEX
            DW $0000
        ENDR
    ENDC
    DW (\2) ; Add data for this element
    DEF CURINDEX = (\1)+1
ENDM

;-------------------------------------------------------------------------------

    DATA_MONEY_AMOUNT MONEY_0, 0
    DATA_MONEY_AMOUNT MONEY_1, 1
    DATA_MONEY_AMOUNT MONEY_2, 2
    DATA_MONEY_AMOUNT MONEY_5, 5
    DATA_MONEY_AMOUNT MONEY_10, 10
    DATA_MONEY_AMOUNT MONEY_12, 12
    DATA_MONEY_AMOUNT MONEY_14, 14
    DATA_MONEY_AMOUNT MONEY_50, 50
    DATA_MONEY_AMOUNT MONEY_100, 100
    DATA_MONEY_AMOUNT MONEY_500, 500
    DATA_MONEY_AMOUNT MONEY_1000, 1000
    DATA_MONEY_AMOUNT MONEY_3000, 3000
    DATA_MONEY_AMOUNT MONEY_5000, 5000
    DATA_MONEY_AMOUNT MONEY_7000, 7000
    DATA_MONEY_AMOUNT MONEY_10000, 10000
    DATA_MONEY_AMOUNT MONEY_20000, 20000

;-------------------------------------------------------------------------------

BUILDING_PRICE_ARRAY:
    BUILDING_SET_PRICE B_Residential, MONEY_10
    BUILDING_SET_PRICE B_Commercial, MONEY_12
    BUILDING_SET_PRICE B_Industrial, MONEY_14

    BUILDING_SET_PRICE B_PoliceDept, MONEY_500
    BUILDING_SET_PRICE B_FireDept, MONEY_500
    BUILDING_SET_PRICE B_Hospital, MONEY_500

    BUILDING_SET_PRICE B_ParkSmall, MONEY_10
    BUILDING_SET_PRICE B_ParkBig, MONEY_100
    BUILDING_SET_PRICE B_Stadium, MONEY_5000

    BUILDING_SET_PRICE B_School, MONEY_100
    BUILDING_SET_PRICE B_HighSchool, MONEY_1000
    BUILDING_SET_PRICE B_University, MONEY_7000

    BUILDING_SET_PRICE B_Museum, MONEY_3000
    BUILDING_SET_PRICE B_Library, MONEY_500

    BUILDING_SET_PRICE B_Airport, MONEY_10000

    BUILDING_SET_PRICE B_PowerPlantCoal, MONEY_3000
    BUILDING_SET_PRICE B_PowerPlantOil, MONEY_5000
    BUILDING_SET_PRICE B_PowerPlantWind, MONEY_1000
    BUILDING_SET_PRICE B_PowerPlantSolar, MONEY_5000
    BUILDING_SET_PRICE B_PowerPlantNuclear, MONEY_10000
    BUILDING_SET_PRICE B_PowerPlantFusion, MONEY_20000

    BUILDING_SET_PRICE B_Road, MONEY_5
    BUILDING_SET_PRICE B_Train, MONEY_10
    BUILDING_SET_PRICE B_PowerLines, MONEY_2
    BUILDING_SET_PRICE B_Port, MONEY_1000

    BUILDING_SET_PRICE B_ResidentialS1A, MONEY_0
    BUILDING_SET_PRICE B_ResidentialS1B, MONEY_0
    BUILDING_SET_PRICE B_ResidentialS1C, MONEY_0
    BUILDING_SET_PRICE B_ResidentialS1D, MONEY_0
    BUILDING_SET_PRICE B_ResidentialS2A, MONEY_0
    BUILDING_SET_PRICE B_ResidentialS2B, MONEY_0
    BUILDING_SET_PRICE B_ResidentialS2C, MONEY_0
    BUILDING_SET_PRICE B_ResidentialS2D, MONEY_0
    BUILDING_SET_PRICE B_ResidentialS3A, MONEY_0
    BUILDING_SET_PRICE B_ResidentialS3B, MONEY_0
    BUILDING_SET_PRICE B_ResidentialS3C, MONEY_0
    BUILDING_SET_PRICE B_ResidentialS3D, MONEY_0

    BUILDING_SET_PRICE B_CommercialS1A, MONEY_0
    BUILDING_SET_PRICE B_CommercialS1B, MONEY_0
    BUILDING_SET_PRICE B_CommercialS1C, MONEY_0
    BUILDING_SET_PRICE B_CommercialS1D, MONEY_0
    BUILDING_SET_PRICE B_CommercialS2A, MONEY_0
    BUILDING_SET_PRICE B_CommercialS2B, MONEY_0
    BUILDING_SET_PRICE B_CommercialS2C, MONEY_0
    BUILDING_SET_PRICE B_CommercialS2D, MONEY_0
    BUILDING_SET_PRICE B_CommercialS3A, MONEY_0
    BUILDING_SET_PRICE B_CommercialS3B, MONEY_0
    BUILDING_SET_PRICE B_CommercialS3C, MONEY_0
    BUILDING_SET_PRICE B_CommercialS3D, MONEY_0

    BUILDING_SET_PRICE B_IndustrialS1A, MONEY_0
    BUILDING_SET_PRICE B_IndustrialS1B, MONEY_0
    BUILDING_SET_PRICE B_IndustrialS1C, MONEY_0
    BUILDING_SET_PRICE B_IndustrialS1D, MONEY_0
    BUILDING_SET_PRICE B_IndustrialS2A, MONEY_0
    BUILDING_SET_PRICE B_IndustrialS2B, MONEY_0
    BUILDING_SET_PRICE B_IndustrialS2C, MONEY_0
    BUILDING_SET_PRICE B_IndustrialS2D, MONEY_0
    BUILDING_SET_PRICE B_IndustrialS3A, MONEY_0
    BUILDING_SET_PRICE B_IndustrialS3B, MONEY_0
    BUILDING_SET_PRICE B_IndustrialS3C, MONEY_0
    BUILDING_SET_PRICE B_IndustrialS3D, MONEY_0

    BUILDING_SET_PRICE B_RadiationGround, MONEY_0
    BUILDING_SET_PRICE B_RadiationWater,  MONEY_0

    ; BUILDING_SET_PRICE B_Delete defined on BuildingSelectedGetPricePointer

BuildingSelectedGetPricePointer:: ; returns pointer in de

    ld      a,[building_selected]
    cp      a,B_Delete
    jr      nz,.not_delete

    ld      de,MONEY_5
    ret

.not_delete:

    cp      a,B_MetabuildingMax+1
    jr      c,.valid_building

    ld      b,b ; Breakpoint
    ld      de,MONEY_1
    ret

.valid_building:

    ld      hl, BUILDING_PRICE_ARRAY
    ld      e,a
    ld      d,0
    add     hl,de
    add     hl,de ; hl = &(((u16*)BUILDING_PRICE_ARRAY)[building_selected])

    ld      a,[hl+]
    ld      d,[hl]
    ld      e,a

    ret

;-------------------------------------------------------------------------------

; Not thread-safe
BuildingPriceTempSet:: ; [de] = price

    ld      hl,building_temp_price
    REPT 4
    ld      a,[de]
    inc     de
    ld      [hl+],a
    ENDR
    ld      a,[de]
    ld      [hl],a

    ret

; Not thread-safe
BuildingPriceTempMultiply:: ; b = multiplier, returns temp price in [de]

    ld      de,building_temp_price
    call    BCD_DE_UMUL_B ; [de] = [de] * b
    ld      de,building_temp_price
    ret

; Not thread-safe
BuildingPriceTempGet:: ; returns [de] = price

    ld      de,building_temp_price
    ret

;###############################################################################
