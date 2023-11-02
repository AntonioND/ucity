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

    SECTION "City Map Draw Train Functions",ROMX

;-------------------------------------------------------------------------------

TRAIN_MASK_TABLE: ; MASK, EXPECTED RESULT, RESULTING TILE

    ; From more restrictive to less restrictive

    DB %01011010,%01011010,T_TRAIN_TLRB

    DB %01011010,%01010010,T_TRAIN_TRB
    DB %01011010,%01011000,T_TRAIN_LRB
    DB %01011010,%01001010,T_TRAIN_TLB
    DB %01011010,%00011010,T_TRAIN_TLR

    DB %01011010,%01010000,T_TRAIN_RB
    DB %01011010,%00010010,T_TRAIN_TR
    DB %01011010,%01001000,T_TRAIN_LB
    DB %01011010,%00001010,T_TRAIN_TL

    DB %01011010,%01000000,T_TRAIN_TB
    DB %01011010,%00000010,T_TRAIN_TB
    DB %01011010,%01000010,T_TRAIN_TB

    DB %01011010,%00010000,T_TRAIN_LR
    DB %01011010,%00001000,T_TRAIN_LR
    DB %01011010,%00011000,T_TRAIN_LR

    DB %00000000,%00000000,T_TRAIN_LR ; Default -> Always valid

MapTileUpdateTrain: ; e = x, d = y

    ld      a,e
    or      a,d
    and     a,128+64 ; ~63
    ret     nz ; return if this is outside the map

    ; Check if this is actually a train line
    ; --------------------------------------
    GET_MAP_ADDRESS ; preserves de and bc

    ld      a,BANK_CITY_MAP_TYPE
    ldh     [rSVBK],a

    ld      a,TYPE_HAS_TRAIN ; not a train, exit
    and     a,[hl]
    ret     z

    ld      a,TYPE_MASK
    and     a,[hl]
    cp      a,TYPE_WATER
    ret     z ; if this is a bridge, don't update

    ld      a,TYPE_HAS_ROAD|TYPE_HAS_POWER
    and     a,[hl]
    cp      a,TYPE_HAS_ROAD|TYPE_HAS_POWER
    ret     z ; If there are road and power lines, train can't be built

    ld      a,TYPE_HAS_ROAD ; if there is road, special update
    and     a,[hl]
    jr      z,.not_road
        ld      a,BANK_CITY_MAP_TILES
        ldh     [rSVBK],a
        ld      a,[hl]
        cp      a,T_ROAD_TB
        jr      z,.is_tb
        cp      a,T_ROAD_TB_1
        jr      z,.is_tb
        cp      a,T_ROAD_TB_2
        jr      z,.is_tb
        cp      a,T_ROAD_TB_3
        jr      z,.is_tb

        jr      .not_tb
.is_tb:
            ld      bc,T_TRAIN_LR_ROAD
            call    CityMapDrawTerrainTile
            ret
.not_tb:
        cp      a,T_ROAD_LR
        jr      z,.is_lr
        cp      a,T_ROAD_LR_1
        jr      z,.is_lr
        cp      a,T_ROAD_LR_2
        jr      z,.is_lr
        cp      a,T_ROAD_LR_3
        jr      z,.is_lr

        jr      .not_lr
.is_lr:
            ld      bc,T_TRAIN_TB_ROAD
            call    CityMapDrawTerrainTile
            ret
.not_lr:
        ret
.not_road:

    ld      a,TYPE_HAS_POWER ; if there are power lines, special update
    and     a,[hl]
    jr      z,.not_electricity
        ld      a,BANK_CITY_MAP_TILES
        ldh     [rSVBK],a
        ld      a,[hl]
        cp      a,T_POWER_LINES_TB
        jr      nz,.not_tb_elec
            ld      bc,T_TRAIN_LR_POWER_LINES
            call    CityMapDrawTerrainTile
            ret
.not_tb_elec:
        cp      a,T_POWER_LINES_LR
        jr      nz,.not_lr_elec
            ld      bc,T_TRAIN_TB_POWER_LINES
            call    CityMapDrawTerrainTile
            ret
.not_lr_elec:
        ret
.not_electricity:

    ; Calculate the needed tile
    ; -------------------------

    ; Create a byte containing the state of the 8 neighbours of this pixel.
    ; 1 = has train, 0 = doesn't have train.
    ; 0 1 2
    ; 3 . 4 <- Bit order
    ; 5 6 7
    ; The byte is stored in register B

    ld      b,0

IF 0
    push    bc
    push    de
    dec     e
    dec     d
    call    CityMapGetType
    pop     de
    pop     bc
    and     a,TYPE_HAS_TRAIN
    jr      z,.skip0
    set     0,b
.skip0:
ENDC

    push    de
    push    bc
    dec     d
    call    CityMapGetTypeAndTile ; a = type, de = tile
    pop     bc
    and     a,TYPE_HAS_TRAIN
    jr      z,.skip1
    ld      a,T_TRAIN_LR_BRIDGE
    cp      a,e
    jr      z,.skip1
    set     1,b
.skip1:
    pop     de

IF 0
    push    bc
    push    de
    inc     e
    dec     d
    call    CityMapGetType
    pop     de
    pop     bc
    and     a,TYPE_HAS_TRAIN
    jr      z,.skip2
    set     2,b
.skip2:
ENDC

    push    de
    push    bc
    dec     e
    call    CityMapGetTypeAndTile ; a = type, de = tile
    pop     bc
    and     a,TYPE_HAS_TRAIN
    jr      z,.skip3
    ld      a,T_TRAIN_TB_BRIDGE
    cp      a,e
    jr      z,.skip3
    set     3,b
.skip3:
    pop     de

    push    de
    push    bc
    inc     e
    call    CityMapGetTypeAndTile ; a = type, de = tile
    pop     bc
    and     a,TYPE_HAS_TRAIN
    jr      z,.skip4
    ld      a,T_TRAIN_TB_BRIDGE
    cp      a,e
    jr      z,.skip4
    set     4,b
.skip4:
    pop     de

IF 0
    push    bc
    push    de
    dec     e
    inc     d
    call    CityMapGetType
    pop     de
    pop     bc
    and     a,TYPE_HAS_TRAIN
    jr      z,.skip5
    set     5,b
ENDC
.skip5:

    push    de
    push    bc
    inc     d
    call    CityMapGetTypeAndTile ; a = type, de = tile
    pop     bc
    and     a,TYPE_HAS_TRAIN
    jr      z,.skip6
    ld      a,T_TRAIN_LR_BRIDGE
    cp      a,e
    jr      z,.skip6
    set     6,b
.skip6:
    pop     de

IF 0
    push    bc
    push    de
    inc     e
    inc     d
    call    CityMapGetType
    pop     de
    pop     bc
    and     a,TYPE_HAS_TRAIN
    jr      z,.skip7
    set     7,b
.skip7:
ENDC

    ; Compare with table

    ld      hl,TRAIN_MASK_TABLE

.search:
    ld      a,[hl+]
    ld      c,[hl]
    inc     hl

    and     a,b
    cp      a,c
    jr      z,.valid

    inc     hl
    jr      .search

.valid:
    ld      c,[hl] ; bc = tile!
    ld      b,0

    ; Draw resulting tile
    ; -------------------
    ; de should still hold the coordinates!
    call    CityMapDrawTerrainTile

    ret

;-------------------------------------------------------------------------------

MapDrawTrain:: ; Adds a train tile where the cursor is. Updates neighbours.

    ; Check if enough money
    ; ---------------------

    ; Exit and "not enough money" sound
    call    BuildingSelectedGetPricePointer ; returns pointer in de
    call    MoneyIsThereEnough
    and     a,a
    jr      nz,.enough_money
    call    SFX_BuildError
    ret
.enough_money:

    ; Check if we can build here!
    ; ---------------------------

    call    CursorGetGlobalCoords
    call    CityMapGetType

    ; a = type
    ld      b,a ; save type to register B

    and     a,TYPE_HAS_TRAIN
    ret     nz ; train already here!

    ld      a,b
    and     a,TYPE_HAS_ROAD|TYPE_HAS_POWER
    cp      a,TYPE_HAS_ROAD|TYPE_HAS_POWER
    ret     z ; If there are roads and power lines, train can't be built

    ld      a,b
    and     a,TYPE_HAS_ROAD
    jr      z,.end_road_check
    GET_MAP_ADDRESS ; preserves de and bc
    ld      a,BANK_CITY_MAP_TILES
    ldh     [rSVBK],a
    ld      a,[hl] ; get tile from map

    cp      a,T_ROAD_TB ; valid road tile
    jr      z,.end_road_check
    cp      a,T_ROAD_TB_1 ; valid road tile
    jr      z,.end_road_check
    cp      a,T_ROAD_TB_2 ; valid road tile
    jr      z,.end_road_check
    cp      a,T_ROAD_TB_3 ; valid road tile
    jr      z,.end_road_check

    cp      a,T_ROAD_LR ; valid road tile
    jr      z,.end_road_check
    cp      a,T_ROAD_LR_1 ; valid road tile
    jr      z,.end_road_check
    cp      a,T_ROAD_LR_2 ; valid road tile
    jr      z,.end_road_check
    cp      a,T_ROAD_LR_3 ; valid road tile
    jr      z,.end_road_check

    ret

.end_road_check:

    ld      a,b
    and     a,TYPE_HAS_POWER
    jr      z,.end_electricity_check
    GET_MAP_ADDRESS ; preserves de and bc
    ld      a,BANK_CITY_MAP_TILES
    ldh     [rSVBK],a
    ld      a,[hl] ; get tile from map
    cp      a,T_POWER_LINES_TB ; valid tile
    jr      z,.end_electricity_check
    cp      a,T_POWER_LINES_LR ; valid tile
    ret     nz
.end_electricity_check:

    ld      a,b
    and     a,TYPE_MASK ; get type without flags

    cp      a,TYPE_FIELD
    jr      z,.end_type_check
    cp      a,TYPE_FOREST
    jr      z,.end_type_check
    cp      a,TYPE_WATER
    jr      nz,.end_type_check_water ; If water, bridge! If not, end reached!
        ld      c,TYPE_HAS_TRAIN
        push    de ; de should still hold the cursor coordinates
        call    CityMapCheckBuildBridge ; returns length and build direction
        pop     de
        and     a,a
        ld      a,TYPE_HAS_TRAIN
        call    nz,CityMapBuildBridge ; If ok, build
        call    MapTileUpdateTrain ; update end of the bridge
        jr      .update_tiles ; skip normal marking, go to neighbours update
.end_type_check_water:
    ret ; no more valid terrains

.end_type_check:

    ; Mark tile as having road
    ; ------------------------

    call    CursorGetGlobalCoords
    GET_MAP_ADDRESS ; preserves de and bc

    ld      a,BANK_CITY_MAP_TYPE
    ldh     [rSVBK],a

    ld      a,TYPE_HAS_TRAIN
    or      a,[hl] ; Mark as having train
    and     a,TYPE_FLAGS_MASK ; save flags
    or      a,TYPE_FIELD ; Set as field!! IMPORTANT
    ld      [hl],a ; Water shouldn't be set as field -> special fn for bridges.

    ; Decrease money -> one tile
    ; --------------

    call    BuildingSelectedGetPricePointer ; returns pointer in de
    call    MoneyReduce
    call    SFX_Build

    ; Update this tile and neighbours
    ; -------------------------------

.update_tiles:

    ; All 9 are needed to be updated, maybe one of the corners could change
    ; because of the centre one!

    call    CursorGetGlobalCoords

    call    MapUpdateNeighboursTrain

    ; Update map
    ; ----------

    call    bg_refresh_main

    ret

;-------------------------------------------------------------------------------

; de = coordinates
MapUpdateNeighboursTrain:: ; Updates neighbours and the tile in the center

    push    de
    dec     d
    dec     e
    call    MapTileUpdateTrain
    pop     de

    push    de
    dec     d
    call    MapTileUpdateTrain
    pop     de

    push    de
    dec     d
    inc     e
    call    MapTileUpdateTrain
    pop     de

    push    de
    dec     e
    call    MapTileUpdateTrain
    pop     de

    push    de
    call    MapTileUpdateTrain
    pop     de

    push    de
    inc     e
    call    MapTileUpdateTrain
    pop     de

    push    de
    inc     d
    dec     e
    call    MapTileUpdateTrain
    pop     de

    push    de
    inc     d
    call    MapTileUpdateTrain
    pop     de

    push    de
    inc     d
    inc     e
    call    MapTileUpdateTrain
    pop     de

    ret

;###############################################################################
