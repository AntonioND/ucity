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

;###############################################################################

    SECTION "City Map Draw Functions",ROM0

;-------------------------------------------------------------------------------

; Actually called from the user interface!
; Checks selected building type and calls the corresponding function to draw.
CityMapDraw::

    call    bg_scroll_in_tile
    and     a,a
    ret     nz ; Don't draw if cursor is between tiles.

    call    BuildingBuildAtCursor
    ret

;-------------------------------------------------------------------------------

CityMapRefreshTypeMap::

    GLOBAL  TILESET_INFO
    ld      b,BANK(TILESET_INFO)
    call    rom_bank_push_set

    ld      de,CITY_MAP_TILES
    ld      bc,CITY_MAP_WIDTH*CITY_MAP_HEIGHT
.loop:

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a

    ld      a,[de] ; l = LSB tile
    ld      l,a

    ld      a,BANK_CITY_MAP_ATTR
    ld      [rSVBK],a

    ld      a,[de]
    rla
    swap    a ; move bit 3 (tile bank) to 0
    and     a,1
    ld      h,a ; h = MSB tile

    IF TILESET_INFO_ELEMENT_SIZE != 4
        FAIL "draw_city_map.asm: Fix this!"
    ENDC

    add     hl,hl
    add     hl,hl ; tile number * 4

    ld      a,$4000>>8
    or      a,h
    ld      h,a ; TILESET_INFO base is $4000 -> TILESET_INFO + tile * 2
    inc     hl ; first byte is the palette, second one is the type

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

    ld      a,[hl]
    ld      [de],a

    inc     de ; next tile

    dec     bc
    ld      a,b
    or      a,c
    jr      nz,.loop

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

; Expand type of the tile in the border (water or field).

; Internal function called by CityMapGetType and CityMapGetTypeAndTile
; The coordinates passed as arguments should be 1 and only 1 tile away from the
; map (in both X and Y coordinates).
_CityMapFixBorderCoordinates: ; Arguments: e = x , d = y

    ; Correct X
    bit     7,e
    jr      z,.not_negative_x
    ld      e,0
    jr      .end_x
.not_negative_x:
    bit     6,e
    jr      z,.greater_than_64_x
    ld      e,63
.greater_than_64_x:

.end_x:

    ; Correct Y
    bit     7,d
    jr      z,.not_negative_y
    ld      d,0
    jr      .end_y
.not_negative_y:
    bit     6,d
    jr      z,.greater_than_64_y
    ld      d,63
.greater_than_64_y:

.end_y:

    call    GetMapAddress

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

    ld      a,[hl]
    and     a,TYPE_MASK

    cp      a,TYPE_WATER
    jr      z,.is_water

    ld      a,TYPE_FIELD
    ld      de,T_GRASS
    ret

.is_water:

    ld      a,TYPE_WATER
    ld      de,T_WATER
    ret

;-------------------------------------------------------------------------------

; Returns type of the tile + extra flags -> register A
CityMapGetType:: ; Arguments: e = x , d = y

    ld      a,e
    or      a,d
    and     a,128+64 ; ~63
    ; if x or y less than 0 or higher than 63 expand map to sea or field
    jp      nz,_CityMapFixBorderCoordinates ; returns from there

    call    GetMapAddress

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

    ld      a,[hl]

    ret

;-------------------------------------------------------------------------------

; Returns: - Type of the tile + extra flags -> register A
;          - Tile -> Register DE
CityMapGetTypeAndTile:: ; Arguments: e = x , d = y

    ld      a,e
    or      a,d
    and     a,128+64 ; ~63
    ; if x or y less than 0 or higher than 63 expand map to sea or field
    jp      nz,_CityMapFixBorderCoordinates ; returns from there

    call    GetMapAddress

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a

    ld      e,[hl]

    ld      a,BANK_CITY_MAP_ATTR
    ld      [rSVBK],a

    ld      a,[hl]
    rla
    swap    a
    and     a,1 ; get bank bit
    ld      d,a

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

    ld      a,[hl]

    ret

;-------------------------------------------------------------------------------

; Set tile, attributes and type. Things like roads, train and power lines don't
; need to have their type set here, but it doesn't hurt either.

CityMapDrawTerrainTileAddress:: ; bc = tile, hl = address

    push    bc
    jr      _entry_CityMapDrawTerrainTile

CityMapDrawTerrainTile:: ; bc = tile, e = x, d = y

    push    bc
    call    GetMapAddress

_entry_CityMapDrawTerrainTile:

    push    hl
    GLOBAL  TILESET_INFO
    ld      b,BANK(TILESET_INFO)
    call    rom_bank_push_set
    pop     hl

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a

    pop     bc ; bc = tile
    ld      [hl],c ; write low bit

    push    hl ; save write address

    ld      hl,TILESET_INFO
    add     hl,bc ; Use full 9 bit tile number to access the array.
    add     hl,bc ; hl points to the palette + bank1 bit
    add     hl,bc ; Tile number * 4
    add     hl,bc

    IF TILESET_INFO_ELEMENT_SIZE != 4
        FAIL "draw_city_map.asm: Fix this!"
    ENDC

    ld      d,[hl] ; d holds the palette + bank1 bit
    inc     hl
    ld      e,[hl] ; e holds the type

    pop     hl ; restore write address

    ; Save attributes

    ld      a,BANK_CITY_MAP_ATTR
    ld      [rSVBK],a

    ld      [hl],d

    ; Save type

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

    ld      [hl],e

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

; Checks if a bridge of a certain type can be built.
; Returns:
;    a = length of the bridge, 0 if error
;    b = x increment // c = y increment -> build direction
CityMapCheckBuildBridge:: ; e = x, d = y, c = flag type (road, train, electr)

    ; Check if this point is actually water with nothing else built
    ; -------------------------------------------------------------

    push    bc
    push    de
    call    CityMapGetType
    pop     de
    pop     bc

    cp      a,TYPE_WATER ; Plain water
    ld      a,0 ; return 0
    ret     nz

    ; Check if there's an item nearby like the one selected in register C
    ; -------------------------------------------------------------------
    ; Only the border of a river or the sea could have one, so that would
    ; mean that this is actually the border of the water.

    ; Fail if:
    ; - 0 neighbours (don't know how to start)
    ; - 2 neighbours and not in opposite positions
    ; - 3 or 4 neighbours

    ld      b,0 ; Store flags here

    push    bc
    push    de
    dec     e
    call    CityMapGetType ; x-1, y
    pop     de
    pop     bc
    cp      a,c ; TYPE_HAS_xxxx == TYPE_HAS_xxxx | TYPE_FIELD, and we aren't
    jr      nz,.skip0 ; considering bridge tiles here.
        ld      a,PAD_LEFT
        or      a,b
        ld      b,a
.skip0:

    push    bc
    push    de
    inc     e
    call    CityMapGetType ; x+1, y
    pop     de
    pop     bc
    cp      a,c
    jr      nz,.skip1
        ld      a,PAD_RIGHT
        or      a,b
        ld      b,a
.skip1:

    push    bc
    push    de
    dec     d
    call    CityMapGetType ; x, y-1
    pop     de
    pop     bc
    cp      a,c
    jr      nz,.skip2
        ld      a,PAD_UP
        or      a,b
        ld      b,a
.skip2:

    push    bc
    push    de
    inc     d
    call    CityMapGetType ; x, y+1
    pop     de
    pop     bc
    cp      a,c
    jr      nz,.skip3
        ld      a,PAD_DOWN
        or      a,b
        ld      b,a
.skip3:

    ; de = coordinates
    ; c = bridge type flag -> no longer needed
    ; b = direction flags

    ; Loop valid flag lists until flags are 0 (end of valid conditions)
    ld      hl,BRIDGE_CONDITIONS
.loop:
    ld      a,[hl+] ; get condition flags
    and     a,a
    ret     z ; if 0, end of the list, invalid conditions. Return 0
    cp      a,b ; compare with actual flags
    jr      z,.done ; if equal, done
    inc     hl
    inc     hl
    jr      .loop
.done:

    ; hl points now at the increments
    ; b = direction flags -> no longer needed

    ld      b,[hl]
    inc     hl
    ld      c,[hl]

    ; e = x /// d = y
    ; b = x inc /// c = y inc

    ; Start checking the opposite direction
    ; -------------------------------------

    ; If there's anything on the way, fail.

    ld      h,0 ; h = bridge length
.check_loop:
    push    de
    push    bc
    push    hl
    call    CityMapGetType
    pop     hl
    pop     bc
    pop     de

    cp      a,TYPE_WATER
    jr      nz,.final_check ; we found something, check if it's solid ground

    ld      a,d
    add     a,c
    ld      d,a ; y += y increment

    ld      a,e
    add     a,b
    ld      e,a ; x += x increment

    inc     h ; increment lenght

    jr      .check_loop

.final_check:

    ; bc = coordinate increments -> will be returned!
    ; de = final coordinates
    ; h = bridge lenght

    and     a,TYPE_MASK

    ; Return 0 if couldn't build it (found water or docks). If water is found it
    ; means that there is a bridge here.

    cp      a,TYPE_WATER
    jr      z,.return_error
    cp      a,TYPE_DOCK
    jr      z,.return_error

    jr      .not_water
.return_error:
    xor     a,a
    ret

.not_water:

    ; Not water! Check final coordinates to see if we are outside the map

    ld      a,d
    or      a,e
    and     a,128+64
    jr      z,.not_outside ; check if < 0 or > 63
    xor     a,a
    ret ; return 0
.not_outside:

    ; bc = coordinate increments b=x, c=y -> will be returned!
    ; h = bridge lenght -> will be returned!

    ; CHECK IF ENOUGH MONEY -> return 0 and make sound if not

    ; Preserve bc and h

    push    bc
    push    hl

    ld      b,h ; b = lenght
    push    bc
    call    BuildingSelectedGetPricePointer
    call    BuildingPriceTempSet
    pop     bc
    call    BuildingPriceTempMultiply ; b = multiplier, returns [de] = price
    call    MoneyReduceIfEnough ; Reduce money if enough

    pop     hl
    pop     bc
    and     a,a
    jr      nz,.enough_money
        call    SFX_BuildError
        xor     a,a ; return 0 lenght (error)
        ret
.enough_money:

    ; Play sound

    push    hl
    call    SFX_Build
    pop     hl

    ; End inside the map and solid ground. Conditions are met.
    ; Return length in a
    ; Return coordinate increments in bc
    ld      a,h
    ret

BRIDGE_CONDITIONS: ; Flags -> detected positions, x increment, y increment

    DB PAD_UP,     0, +1 ; go down
    DB PAD_DOWN,   0, -1 ; go up
    DB PAD_LEFT,  +1,  0 ; go right
    DB PAD_RIGHT, -1,  0 ; go left

    DB PAD_UP|PAD_DOWN,     0, +1 ; Only 1 step. As of now, this kind of bridge
    DB PAD_RIGHT|PAD_LEFT, +1,  0 ; can't be built because the needed terrain
                                  ; is never generated.

    DB 0 ; The rest are invalid (only the first byte ot this element is used)

;-------------------------------------------------------------------------------

; Builds a bridge until it finds a non TYPE_WATER (exactly) tile.
; Returns the other end of the bridge in DE
; Arguments:
;   e = x, d = y // a = flag type (road, train, electr)
;   b = x increment // c = y increment
CityMapBuildBridge::

    ; First, check which tile to draw
    ; -------------------------------
    push    de
    ld      d,a ; save flag in d

    ld      hl,BRIDGE_NEW_TILE
.loop_check:

    ld      a,[hl+]
    and     a,a
    jr      nz,.dont_exit
        pop     de ; problems found, exit function
        ld      b,b ; Breakpoint
        ret
.dont_exit:

    cp      a,d
    jr      nz,.next_element_3_inc ; different, check next

    ; Analyze element
    ld      a,[hl+]
    cp      a,b ; check x increment
    jr      nz,.next_element_2_inc

    ld      a,[hl+]
    cp      a,c ; check y increment
    jr      nz,.next_element_1_inc

    ; All elements matched, read tile type and exit loop
    ld      h,[hl] ; h = tile type
    jr      .end_check

.next_element_3_inc:
    inc     hl
.next_element_2_inc:
    inc     hl
.next_element_1_inc:
    inc     hl
    jr      .loop_check

.end_check:

    ld      l,d ; get flag -> l = flag
    pop     de

    ; de = start coordinates
    ; bc = coordinate increments
    ; h = tile type
    ; l = flag

    ; Draw bridge and mark tiles as having the new element
    ; ----------------------------------------------------

.build_loop:
    push    bc
    push    de
    push    hl
    call    GetMapAddress

        pop     bc ; pop'ing into a different register, watch out!

        ; hl = address
        ; b = tile type
        ; c = flag

        ; Check if water. If not, exit loop! -> Exit: A=1 // Continue: A=0

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

        ld      a,[hl]
        cp      a,TYPE_WATER
        jr      z,.type_ok
            ld      a,1
            jr      .iteration_end ; exit loop, this is the end of water
.type_ok:

        or      a,c
        ld      [hl],a ; set flag in map

        ; Draw tile and palette

        ld      a,b

        push    bc
        ld      b,0
        ld      c,a
        call    CityMapDrawTerrainTileAddress
        pop     hl ; restore tile and flag to hl, the correct register

        xor     a,a ; continue loop!

.iteration_end:

    pop     de
    pop     bc

    and     a,a ; exit flag
    jr      nz, .exit_build_loop ; exit without incrementing

    ; increment coordinates
    ld      a,d
    add     a,c
    ld      d,a ; y += y increment

    ld      a,e
    add     a,b
    ld      e,a ; x += x increment

    jr      .build_loop

.exit_build_loop:

    ret

BRIDGE_NEW_TILE: ; type, x increment flag, y increment flag, resulting tile
; All bridge tiles should be < 256
    DB TYPE_HAS_ROAD,  0, +1, T_ROAD_TB_BRIDGE
    DB TYPE_HAS_ROAD,  0, -1, T_ROAD_TB_BRIDGE
    DB TYPE_HAS_ROAD, +1,  0, T_ROAD_LR_BRIDGE
    DB TYPE_HAS_ROAD, -1,  0, T_ROAD_LR_BRIDGE

    DB TYPE_HAS_TRAIN,  0, +1, T_TRAIN_TB_BRIDGE
    DB TYPE_HAS_TRAIN,  0, -1, T_TRAIN_TB_BRIDGE
    DB TYPE_HAS_TRAIN, +1,  0, T_TRAIN_LR_BRIDGE
    DB TYPE_HAS_TRAIN, -1,  0, T_TRAIN_LR_BRIDGE

    DB TYPE_HAS_POWER,  0, +1, T_POWER_LINES_TB_BRIDGE
    DB TYPE_HAS_POWER,  0, -1, T_POWER_LINES_TB_BRIDGE
    DB TYPE_HAS_POWER, +1,  0, T_POWER_LINES_LR_BRIDGE
    DB TYPE_HAS_POWER, -1,  0, T_POWER_LINES_LR_BRIDGE

    DB 0 ; End of list

;-------------------------------------------------------------------------------

WATER_MASK_TABLE: ; MASK, EXPECTED RESULT, RESULTING TILE

    ; From more restrictive to less restrictive

    DB %01011010, %01010000, T_WATER__GRASS_TL
    DB %01011010, %01011000, T_WATER__GRASS_TC
    DB %01011010, %01001000, T_WATER__GRASS_TR
    DB %01011010, %01010010, T_WATER__GRASS_CL
    DB %01011010, %01001010, T_WATER__GRASS_CR
    DB %01011010, %00010010, T_WATER__GRASS_BL
    DB %01011010, %00011010, T_WATER__GRASS_BC
    DB %01011010, %00001010, T_WATER__GRASS_BR

    DB %01011011, %01011010, T_WATER__GRASS_CORNER_TL
    DB %01011110, %01011010, T_WATER__GRASS_CORNER_TR
    DB %01111010, %01011010, T_WATER__GRASS_CORNER_BL
    DB %11011010, %01011010, T_WATER__GRASS_CORNER_BR

    DB %00000000, %00000000, T_WATER ; Default -> Always valid

UpdateWater:: ; e = x, d = y

    ld      a,e
    or      a,d
    and     a,128+64 ; ~63
    ret     nz ; return if this is outside the map

    ; Assume that this is water, and that a bridge here (if any) is supposed to
    ; be deleted by this function. If this is a dock, delete it too.

    ; Calculate the needed tile
    ; -------------------------

    ; Create a byte containing the state of the 8 neighbours of this pixel.
    ; 1 = has water, 0 = doesn't have water.
    ; 0 1 2
    ; 3 . 4 <- Bit order
    ; 5 6 7
    ; The byte is stored in register B

    ld      b,0

    push    bc
    push    de
    dec     e
    dec     d
    call    CityMapGetType
    pop     de
    pop     bc
    and     a,TYPE_MASK
    cp      a,TYPE_WATER
    jr      z,.set0
    cp      a,TYPE_DOCK
    jr      z,.set0
    jr      .skip0
.set0:
    set     0,b
.skip0:

    push    bc
    push    de
    dec     d
    call    CityMapGetTypeAndTile ; a = type, de = tile
    pop     de
    pop     bc
    and     a,TYPE_MASK
    cp      a,TYPE_WATER
    jr      z,.set1
    cp      a,TYPE_DOCK
    jr      z,.set1
    jr      .skip1
.set1:
    set     1,b
.skip1:

    push    bc
    push    de
    inc     e
    dec     d
    call    CityMapGetType
    pop     de
    pop     bc
    and     a,TYPE_MASK
    cp      a,TYPE_WATER
    jr      z,.set2
    cp      a,TYPE_DOCK
    jr      z,.set2
    jr      .skip2
.set2:
    set     2,b
.skip2:

    push    bc
    push    de
    dec     e
    call    CityMapGetTypeAndTile ; a = type, de = tile
    pop     de
    pop     bc
    and     a,TYPE_MASK
    cp      a,TYPE_WATER
    jr      z,.set3
    cp      a,TYPE_DOCK
    jr      z,.set3
    jr      .skip3
.set3:
    set     3,b
.skip3:

    push    bc
    push    de
    inc     e
    call    CityMapGetTypeAndTile ; a = type, de = tile
    pop     de
    pop     bc
    and     a,TYPE_MASK
    cp      a,TYPE_WATER
    jr      z,.set4
    cp      a,TYPE_DOCK
    jr      z,.set4
    jr      .skip4
.set4:
    set     4,b
.skip4:

    push    bc
    push    de
    dec     e
    inc     d
    call    CityMapGetType
    pop     de
    pop     bc
    and     a,TYPE_MASK
    cp      a,TYPE_WATER
    jr      z,.set5
    cp      a,TYPE_DOCK
    jr      z,.set5
    jr      .skip5
.set5:
    set     5,b
.skip5:

    push    bc
    push    de
    inc     d
    call    CityMapGetTypeAndTile ; a = type, de = tile
    pop     de
    pop     bc
    and     a,TYPE_MASK
    cp      a,TYPE_WATER
    jr      z,.set6
    cp      a,TYPE_DOCK
    jr      z,.set6
    jr      .skip6
.set6:
    set     6,b
.skip6:

    push    bc
    push    de
    inc     e
    inc     d
    call    CityMapGetType
    pop     de
    pop     bc
    and     a,TYPE_MASK
    cp      a,TYPE_WATER
    jr      z,.set7
    cp      a,TYPE_DOCK
    jr      z,.set7
    jr      .skip7
.set7:
    set     7,b
.skip7:

    ; Compare with table

    ld      hl,WATER_MASK_TABLE

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

; Inputs: top or left bound of the bridge in de, and b=inc y, c=inc x
; It is assumed that at least the tile in de is a bridge.
; It will refresh the tiles at both ends of the bridge and all water tiles
; affected by the demolition.
DrawCityDeleteBridgeForce: ; Reloads map too.

    push    bc
    push    de ; save arguments to update later (***)

    ; Loop until a non-water tile is found
    ; ------------------------------------

.loop:

    push    bc
    push    de

    ; Set water tile according to surroundings
    call    UpdateWater ; e = x, d = y

    pop     de
    pop     bc

    ld      a,e
    add     a,c
    ld      e,a ; inc x

    ld      a,d
    add     a,b
    ld      d,a ; inc y

    push    bc
    push    de
    call    CityMapGetType ; returns type in a
    pop     de
    pop     bc

    ld      h,a ; save type
    and     a,TYPE_MASK
    cp      a,TYPE_WATER ; the next one is water, continue
    ld      a,h ; restore type
    jr      z,.loop

    ; Refresh end of the bridge
    ; -------------------------

    ; Save type for the other end of the bridge

    ; Because of how mixing road, trains and power line works, it's NOT
    ; impossible for them to be together at one of the ends of the bridge,
    ; but in that case there is no point in doing a refresh because it can't
    ; change the tile.

    push    af
    bit     TYPE_HAS_ROAD_BIT,a
    jr      z,.not_road
    LONG_CALL_ARGS  MapUpdateNeighboursRoad
.not_road:
    pop     af

    push    af
    bit     TYPE_HAS_TRAIN_BIT,a
    jr      z,.not_train
    LONG_CALL_ARGS  MapUpdateNeighboursTrain
.not_train:
    pop     af

    push    af
    bit     TYPE_HAS_POWER_BIT,a
    jr      z,.not_power
    LONG_CALL_ARGS  MapUpdateNeighboursPowerLines
.not_power:
    pop     af

    ; Refresh begining of the bridge
    ; ------------------------------

    pop     de
    pop     bc ; restore arguments (***)

    ld      a,e
    sub     a,c
    ld      e,a ; dec x

    ld      a,d
    sub     a,b
    ld      d,a ; dec y

    push    de
    call    CityMapGetType ; returns type in a
    pop     de

    push    af
    bit     TYPE_HAS_ROAD_BIT,a
    jr      z,.not_road_2
    LONG_CALL_ARGS  MapUpdateNeighboursRoad
.not_road_2:
    pop     af

    push    af
    bit     TYPE_HAS_TRAIN_BIT,a
    jr      z,.not_train_2
    LONG_CALL_ARGS  MapUpdateNeighboursTrain
.not_train_2:
    pop     af

    push    af
    bit     TYPE_HAS_POWER_BIT,a
    jr      z,.not_power_2
    LONG_CALL_ARGS  MapUpdateNeighboursPowerLines
.not_power_2:
    pop     af

    ; Reload map
    ; ----------

    call    bg_reload_map_main

    ret

;-------------------------------------------------------------------------------

BRIDGE_TILE_INFO: ; All bridge tile indexes should be < 256
    ; Tile, IsVertical, Type
    DB T_ROAD_TB_BRIDGE, 1, TYPE_HAS_ROAD
    DB T_ROAD_LR_BRIDGE, 0, TYPE_HAS_ROAD

    DB T_TRAIN_TB_BRIDGE, 1, TYPE_HAS_TRAIN
    DB T_TRAIN_LR_BRIDGE, 0, TYPE_HAS_TRAIN

    DB T_POWER_LINES_TB_BRIDGE, 1, TYPE_HAS_POWER
    DB T_POWER_LINES_LR_BRIDGE, 0, TYPE_HAS_POWER

    DB 0,0 ; End

; Checks length of the bridge to see if there is money to delete. If so, it
; calls DrawCityDeleteBridgeForce and reduces the money.
; Input: d=y, e=x.
DrawCityCheckDeleteBridgeCheck:: ; Returns top or left bound in d=y, e=x.

    ; Check tile to see which direction to go (up or left)
    ; ----------------------------------------------------

    push    de
    ; Returns: - Tile -> Register DE
    call    CityMapGetTypeAndTile ; Arguments: e = x , d = y
    ld      b,d
    ld      c,e ; bc = tile
    pop     de

    ld      a,b
    and     a,a
    jr      z,.tile_lower_than_256

        ; Error! This should never happen!
        ld      b,b ; Breakpoint
        ret ; Return doing nothing

.tile_lower_than_256:

    ld      hl,BRIDGE_TILE_INFO
.loop_find_tile:
        ld      a,[hl+]
        and     a,a
        jr      nz,.not_end

            ; End of the tile array! Should never happen.
            ld      b,b ; Breakpoint
            ret ; Return doing nothing

.not_end:
        cp      a,c
        jr      z,.found_it

    inc     hl
    inc     hl ; next element

    jp      .loop_find_tile

.found_it:

    ld      a,[hl] ; a = Is vertical

    ; Go to the top of the bridge or the left depending on orientation
    ; ----------------------------------------------------------------

    push    af ; save orientation (***)

    and     a,a
    jr      z,.loop_search_origin_hor

    ; Vertical
.loop_search_origin_ver:

    push    de ; save current coordinates (**)

    ; Check if next tile is bridge or not. If not, exit loop with last coords.
    dec     d ; dec y

    push    de
    call    CityMapGetType ; returns type in a
    pop     de
    and     a,TYPE_MASK
    cp      a,TYPE_WATER
    jr      z,.still_bridge_ver ; if water, continue searching
        pop     de ; restore last coordinates(**)
        jr      .end_search_origin
.still_bridge_ver:
    add     sp,+2 ; drop last coordinates(**)
    jr      .loop_search_origin_ver

    ; Horizontal
.loop_search_origin_hor:

    push    de ; save current coordinates (**)

    ; Check if next tile is bridge or not. If not, exit loop with last coords.
    dec     e ; dec x

    push    de
    call    CityMapGetType ; returns type in a
    pop     de
    and     a,TYPE_MASK
    cp      a,TYPE_WATER
    jr      z,.still_bridge_hor ; if water, continue searching
        pop     de ; restore last coordinates(**)
        jr      .end_search_origin
.still_bridge_hor:
    add     sp,+2 ; drop last coordinates(**)
    jr      .loop_search_origin_hor

    ; End of vertical / horizontal searches
.end_search_origin:

    pop     af ; restore orientation (***)

    ; Calculate how many tiles long is this bridge
    ; --------------------------------------------

    push    af
    push    de ; save origin and orientation (**)

    ld      b,0 ; len counter starts as 0

    and     a,a
    jr      z,.calc_len_hor

    ; Vertical
.calc_len_ver:
    inc     d ; inc y
    inc     b ; inc len
    push    bc
    push    de
    call    CityMapGetType ; returns type in a
    pop     de
    pop     bc
    and     a,TYPE_MASK
    cp      a,TYPE_WATER
    jr      nz,.calc_len_end
    jr      .calc_len_ver

    ; Horizontal
.calc_len_hor:
    inc     e ; inc x
    inc     b ; inc len
    push    bc
    push    de
    call    CityMapGetType ; returns type in a
    pop     de
    pop     bc
    and     a,TYPE_MASK
    cp      a,TYPE_WATER
    jr      nz,.calc_len_end
    jr      .calc_len_hor

    ; End
.calc_len_end:

    pop     de ; restore origin and orientation (**)
    pop     af

    ; b = length

    ; Check money. Return if not enough.
    ; ----------------------------------

    ; b = lenght
    ; Preserve de, a

    push    af
    push    de
    push    bc
    call    BuildingSelectedGetPricePointer
    call    BuildingPriceTempSet
    pop     bc
    call    BuildingPriceTempMultiply ; b = multiplier, returns [de] = price
    call    MoneyIsThereEnough
    pop     de
    and     a,a
    jr      nz,.enough_money
        call    SFX_BuildError
        pop     af
        ret
.enough_money:
    pop     af

    ; Delete tiles and refresh VRAM map
    ; ---------------------------------

    ; de = origin, a = is vertical
    and     a,a
    jr      z,.inc_hor
        ; Vertical
        ld      bc,$0100
        jr      .end_inc
.inc_hor:
        ; Horizontal
        ld      bc,$0001
.end_inc:
    ; b=inc y, c=inc x
    call    DrawCityDeleteBridgeForce

    ; Reduce money, play sound
    ; ------------------------

    call    BuildingPriceTempGet ; returns pointer in de
    call    MoneyReduce
    call    SFX_Build

    ; Ready!
    ; ------

    ret

;###############################################################################
