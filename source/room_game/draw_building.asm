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
    INCLUDE "building_info.inc"

;###############################################################################

    SECTION "City Map Draw Building Variables",HRAM

;-------------------------------------------------------------------------------

delete_tile: DS 2 ; Tile that will be drawn on deleted buildings. LSB first

;###############################################################################

    SECTION "City Map Draw Building Functions",ROMX

;-------------------------------------------------------------------------------

; This doesn't refresh the VRAM map

; Arguments:
; e = x, d = width
; b = y, c = height
MapUpdateBuildingSuroundingPowerLines::

    ld      a,d
    ld      d,b
    ld      b,a ; swap d and b

    ; e = x, d = y
    ; b = width, c = height

    ; Top row
    ; -------
    ld      a,d
    and     a,a
    jr      z,.skip_top_row ; skip row if this is the topmost row
    push    bc
    push    de

        dec     d ; dec y
.loop_top:

        push    bc
        push    de
        LONG_CALL_ARGS  MapTileUpdatePowerLines
        pop     de
        pop     bc

        inc     e ; inc x
        dec     b ; dec width
        jr      nz,.loop_top

    pop     de
    pop     bc
.skip_top_row:

    ; Bottom row
    ; ----------

    ld      a,d
    add     a,c ; a = y + height
    cp      a,CITY_MAP_HEIGHT
    jr      nc,.skip_bottom_row ; skip row if this is the last row
    push    bc
    push    de

        ld      d,a
.loop_bottom:

        push    bc
        push    de
        LONG_CALL_ARGS  MapTileUpdatePowerLines
        pop     de
        pop     bc

        inc     e ; inc x
        dec     b ; dec width
        jr      nz,.loop_bottom

    pop     de
    pop     bc
.skip_bottom_row:

    ; Left column
    ; -----------
    ld      a,e
    and     a,a
    jr      z,.skip_left_col ; skip column if this is the leftmost column
    push    bc
    push    de

        dec     e ; dec x
.loop_left:

        push    bc
        push    de
        LONG_CALL_ARGS  MapTileUpdatePowerLines
        pop     de
        pop     bc

        inc     d ; inc y
        dec     c ; dec height
        jr      nz,.loop_left

    pop     de
    pop     bc
.skip_left_col:

    ; Right column
    ; ------------

    ld      a,e
    add     a,b ; a = c + width
    cp      a,CITY_MAP_WIDTH
    jr      nc,.skip_right_col ; skip column  if this is the last column
    push    bc
    push    de

        ld      e,a
.loop_right:

        push    bc
        push    de
        LONG_CALL_ARGS  MapTileUpdatePowerLines
        pop     de
        pop     bc

        inc     d ; inc y
        dec     c ; dec height
        jr      nz,.loop_right

    pop     de
    pop     bc
.skip_right_col:

    ; Done
    ; ----

    ret

;-------------------------------------------------------------------------------

; Doesn't update VRAM map. Clears FLAGS of this tile. Doesn't play SFX.
; de = coordinates, b = B_xxx define
MapDrawBuildingForcedCoords:: ; Puts a building

    push    de
    ld      a,b ; get building index
    ; A = building to check data of. Don't call with B_Delete.
    call    BuildingGetSizeAndBaseTile ; Ret b=width, c=height, hl = base tile
    pop     de
    jr      _MapDrawBuildingForcedInner

; Doesn't update VRAM map. Clears FLAGS of this tile. Doesn't play SFX.
MapDrawBuildingForced:: ; Puts a building at the cursor. No checks.

    ; Get cursor position and building size
    ; -------------------------------------

    call    CursorGetGlobalCoords ; e = x, d = y
    push    de
    call    BuildingCurrentGetSizeAndBaseTile ; b = width, c = height, hl = tile
    pop     de

_MapDrawBuildingForcedInner:

    ld      a,d
    ld      d,b
    ld      b,a ; swap y and width

    ; e = x, d = width
    ; b = y, c = height
    ; hl = tile base index

    push    bc
    push    de ; save info for after drawing building! (***)

    ; Draw tiles and update tile type
    ; -------------------------------

    ; Draw rows

.height_loop:

    push    de ; save width and x
.width_loop:

        ; Draw

        push    bc
        push    de
        push    hl

            ;ld      e,e
            ld      d,b

            ld      c,l
            ld      b,h

            call    CityMapDrawTerrainTile ; bc = tile, e = x, d = y

        pop     hl
        pop     de
        pop     bc

        inc     e ; inc x
        inc     hl ; inc tile

        dec     d ; dec width
        jr      nz,.width_loop

    pop     de ; restore width and x

    ; Next row
    inc     b ; inc y

    dec     c ; dec height
    jr      nz,.height_loop

    ; Update power lines around!
    ; --------------------------

    pop     de
    pop     bc ; restore info (***)

    call    MapUpdateBuildingSuroundingPowerLines

    ret

;-------------------------------------------------------------------------------

; Returns b=0 if could build building, b=1 if error.
MapDrawBuilding:: ; Puts a building at the cursor. Check money and terrain.

    ; Check if enough money
    ; ---------------------

    ; Exit and "not enough money" sound
    call    BuildingSelectedGetPricePointer ; returns pointer in de
    call    MoneyIsThereEnough
    and     a,a
    jr      nz,.enough_money
        call    SFX_BuildError
        ld      b,1 ; return error
        ret
.enough_money:

    ; Check if we can build here!
    ; ---------------------------

    ; Get cursor position and building size

    call    CursorGetGlobalCoords ; e = x, d = y
    push    de
    call    BuildingCurrentGetSizeAndBaseTile
    pop     de ; b = width, c = height, hl = tile

    ld      a,d
    ld      d,b
    ld      b,a ; swap y and width

    ; e = x, d = width
    ; b = y, c = height

    ; Loop rows

.height_loop:

    push    de ; save width and x
.width_loop:

    ; Loop

    push    bc
    push    de

    ld      d,b ; d = y

    call    CityMapGetType ; e = x, d = y

    pop     de
    pop     bc

    ; Check A. Valid types: Field, forest and power lines. If not, return.
    cp      a,TYPE_FIELD
    jr      z,.ok
    cp      a,TYPE_FOREST
    jr      z,.ok
    cp      a,TYPE_FIELD|TYPE_HAS_POWER
    jr      z,.ok
    ; Forest + power doesn't exist, it becomes field + power.
    ld      a,1 ; error!
    pop     de ; get this or the stack won't be ready to return!
    jr      .exit_check_loop
.ok:

    inc     e ; inc x

    dec     d ; dec width
    jr      nz,.width_loop
    pop     de ; restore width and x

    ; Next row
    inc     b ; inc y

    dec     c ; dec height
    jr      nz,.height_loop

    ; If the execution reached this point, everything went fine!
    ld      a,0 ; no error
.exit_check_loop:
    and     a,a
    jr      z,.noerror ; return if error
    ld      b,1
    ret ; return 1 (error)
.noerror:

    ; Build building
    ; --------------

    call    MapDrawBuildingForced ; Power lines updated inside

    ; Decrease money
    ; --------------

    call    BuildingSelectedGetPricePointer ; returns pointer in de
    call    MoneyReduce
    call    SFX_Build

    ; End
    ; ---

    ld      b,0
    ret ; return 0 (no error)

;###############################################################################

    SECTION "City Map Draw Building Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

MACRO MapDeleteBuildingSetTileDestroyed ; BC = tile

    ld      a,c
    ld      [delete_tile+0],a ; LSB First
    ld      a,b
    ld      [delete_tile+1],a

ENDM

MACRO MapDeleteBuildingGetTileDestroyed ; returns BC = tile, destroys A

    ld      a,[delete_tile+0] ; LSB First
    ld      c,a
    ld      a,[delete_tile+1]
    ld      b,a

ENDM

;-------------------------------------------------------------------------------

; de = coordinates of one tile, returns a = 1 if it is the origin, 0 if not
BuildingIsCoordinateOrigin::

    call    CityMapGetTile ; de = tile number

    ; Get the first tile of the group

; de = tile number, returns a = 1 if it is the origin of a building, 0 if not
BuildingIsTileCoordinateOrigin::

IF TILESET_INFO_ELEMENT_SIZE != 4
    FAIL "draw_city_map_building.asm: Fix this!"
ENDC

    ld      b,BANK(TILESET_INFO)
    call    rom_bank_push_set ; preserves de

    ld      hl,TILESET_INFO+2 ; point to delta x and delta y
    add     hl,de ; Use full 9 bit tile number to access the array.
    add     hl,de ; hl points to the palette + bank1 bit
    add     hl,de ; Tile number * 4
    add     hl,de

    ld      a,[hl+]
    or      a,[hl] ; a = (delta x) or (delta y)

    ld      b,a
    call    rom_bank_pop ; preserves bc and de
    ld      a,b

    and     a,a
    jr      z,.is_origin
    xor     a,a
    ret ; return 0 if not origin of coordinates

.is_origin:
    ld      a,1
    ret ; return 1 if origin of coordinates

;-------------------------------------------------------------------------------

; de = coordinates of one tile, returns de = coordinates of the origin
BuildingGetCoordinateOrigin::

    push    de ; save x and y for later (***)

    call    CityMapGetTile ; de = tile number

    ; Get the first tile of the group

IF TILESET_INFO_ELEMENT_SIZE != 4
    FAIL "draw_city_map_building.asm: Fix this!"
ENDC

    ld      b,BANK(TILESET_INFO)
    call    rom_bank_push_set ; preserves de

    ld      hl,TILESET_INFO + 2 ; point to delta x and delta y
    add     hl,de ; Use full 9 bit tile number to access the array.
    add     hl,de ; hl points to the palette + bank1 bit
    add     hl,de ; Tile number * 4
    add     hl,de

    pop     de ; d = y, e = x (***)

    ld      a,[hl+] ; a = delta x
    add     a,e
    ld      e,a ; e = origin x

    ld      a,[hl] ; a = delta y
    add     a,d
    ld      d,a ; d = origin y

    call    rom_bank_pop ; preserves bc and de

    ; de = coordinates of the origin

    ret

;-------------------------------------------------------------------------------

; d=y e=x = coordinates of one tile
; returns: de = coordinates of the origin
;          b=width, c=height
BuildingGetCoordinateOriginAndSize::

    ; de = coordinates of one tile, returns de = coordinates of the origin
    call    BuildingGetCoordinateOrigin

    ; Get base tile
    push    de
    call    CityMapGetTile ; returns tile in de
    LD_BC_DE
    ; bc = base tile

    ; bc = base tile. returns size: d=height, e=width
    LONG_CALL_ARGS  BuildingGetSizeFromBaseTile
    LD_BC_DE
    pop     de ; de = coordinates
    ; bc = size (b=height, c=width)

    ret

;-------------------------------------------------------------------------------

; Doesn't update VRAM map. Clears FLAGS of this tile.
; d = y, e = x -> Coordinates of one of the tiles.
; Returns b=0 if could remove building, b=1 if error.
MACRO MAP_DELETE_BUILDING ; \1 = check money and play SFX if != 0

    ; Get building type and set corresponding "destroyed tile"
    ; --------------------------------------------------------

    ; If RCI building destroy to RCI tile, else demolished tile

    push    de ; (*)

    call    CityMapGetTypeAndTile
    ; Type of the tile + extra flags -> register A
    ; Tile -> Register DE

IF (T_INDUSTRIAL <= T_COMMERCIAL) || (T_INDUSTRIAL <= T_RESIDENTIAL)
    FAIL "RCI tiles are in an incorrect order."
ENDC

    ; Check if RCI tile. If so, jump to "set to demolished". If not, the only
    ; way a tile could be type RCI is if it's a building, which has to be set
    ; to tile RCI after destroying it.

    ld      b,a ; save type

    xor     a,a
    cp      a,d
    jr      nz,.not_rci_tile
    ld      a,T_RESIDENTIAL&$FF
    cp      a,e
    jr      z,.set_demolished_tile
    ld      a,T_COMMERCIAL&$FF
    cp      a,e
    jr      z,.set_demolished_tile
    ld      a,T_INDUSTRIAL&$FF
    cp      a,e
    jr      z,.set_demolished_tile

.not_rci_tile:

    ld      a,b ; restore type

    ; Check if RCI type. If so, this is a RCI building. Destroy to RCI tile

    cp      a,TYPE_RESIDENTIAL
    jr      nz,.not_residential
    ld      bc,T_RESIDENTIAL ; Set as a demolished tile!
    MapDeleteBuildingSetTileDestroyed
    jr      .end_destroyed_tile_set
.not_residential:
    cp      a,TYPE_INDUSTRIAL
    jr      nz,.not_industrial
    ld      bc,T_INDUSTRIAL ; Set as a demolished tile!
    MapDeleteBuildingSetTileDestroyed
    jr      .end_destroyed_tile_set
.not_industrial:
    cp      a,TYPE_COMMERCIAL
    jr      nz,.not_commercial
    ld      bc,T_COMMERCIAL ; Set as a demolished tile!
    MapDeleteBuildingSetTileDestroyed
    jr      .end_destroyed_tile_set
.not_commercial:

.set_demolished_tile:

    ; Set default demolished tile

    ld      bc,T_DEMOLISHED ; Set as a demolished tile!
    MapDeleteBuildingSetTileDestroyed

.end_destroyed_tile_set:

    pop     de ; (*)

    ; Check origin of coordinates of the building
    ; -------------------------------------------

    ; de = coordinates of one tile, returns de = coordinates of the origin
    call    BuildingGetCoordinateOrigin

    ; All there's left to calculate is the building type! Save coordinates for
    ; later, we'll need them together with the building type.

    ; Get base tile
    push    de
    call    CityMapGetTypeAndTile ; returns tile in de
    ld      b,d
    ld      c,e
    pop     de
    ; bc = base tile
    ; de = coordinates

    push    de
    LONG_CALL_ARGS  BuildingGetSizeFromBaseTile
    pop     bc ; bc = coordinates
    ; de = size

    ; Now the demolition can begin!
    ; Size is needed to calculate the money to be spent. Preserve coordinates
    ; and size through the money check!

    ; Check if enough money
    ; ---------------------

IF \1 != 0

    ; Exit and play sound of "not enough money" if not
    ; Preserve coordinates and size
    ; Return b=1 if error

    push    bc
    push    de ; (*)

    call    BuildingSelectedGetPricePointer
    call    BuildingPriceTempSet
    pop     de
    push    de
    ld      b,d
    call    BuildingPriceTempMultiply ; b = multiplier, returns [de] = price
    pop     de
    push    de
    ld      b,e
    call    BuildingPriceTempMultiply ; b = multiplier, returns [de] = price
    call    MoneyIsThereEnough ; Check if enough money

    pop     de ; (*)
    pop     bc

    and     a,a
    jr      nz,.enough_money
        call    SFX_BuildError
        xor     a,a ; return 0 length (error)
        ret
.enough_money:

ENDC

    ; Delete building and place demolished tiles
    ; ------------------------------------------

    ; The coordinates and size come from the calculations above!

    ; bc = coordinates (b = y, c = x)
    ; de = size (d = height, e = width)

    ; Swap some registers (b remains unchanged)

    ld      a,c ; x
    ld      c,d ; c = height
    ld      d,a ; d = x

    ; bc is ready

    ld      a,e ; width
    ld      e,d ; e = x
    ld      d,a ; d = width

    ; e = x, d = width
    ; b = y, c = height

    push    bc
    push    de ; save for later (***)

    ; Loop rows

.height_loop:

    push    de ; save width and x
.width_loop:

        ; Loop

        push    bc
        push    de

            ld      d,b ; d = y
            MapDeleteBuildingGetTileDestroyed
            call    CityMapDrawTerrainTile ; bc = tile, e = x, d = y

        pop     de
        pop     bc

        inc     e ; inc x

        dec     d ; dec width
        jr      nz,.width_loop

    pop     de ; restore width and x

    ; Next row
    inc     b ; inc y

    dec     c ; dec height
    jr      nz,.height_loop

    pop     de
    pop     bc ; restore for next step (***)

    ; Update power lines around!
    ; --------------------------

    ; No need to preserve de or bc for the next steps
    LONG_CALL_ARGS  MapUpdateBuildingSuroundingPowerLines

    ; Decrease money
    ; --------------

IF \1 != 0
    call    BuildingPriceTempGet ; returns pointer in de
    call    MoneyReduce
    call    SFX_Demolish
ENDC

    ld      b,0
    ret ; return 0 (success)

ENDM

; Doesn't update VRAM map. Clears FLAGS of this tile.
; d = y, e = x -> Coordinates of one of the tiles.
; Returns b=0 if could remove building, b=1 if error.
MapDeleteBuildingForced:: ; Removes a building. No checks. No SFX.
    MAP_DELETE_BUILDING 0

; Doesn't update VRAM map. Clears FLAGS of this tile.
; d = y, e = x -> Coordinates of one of the tiles.
; Returns b=0 if could remove building, b=1 if error.
MapDeleteBuilding:: ; Deletes a building. Checks money. Plays SFX.
    MAP_DELETE_BUILDING 1

;-------------------------------------------------------------------------------

; d = y, e = x -> Coordinates of the tile.
MapClearDemolishedTile:: ; Transform demolished into field. Checks money.

    ; Check if enough money
    ; ---------------------

    ; Exit and "not enough money" sound
    push    de
    call    BuildingSelectedGetPricePointer ; returns pointer in de
    call    MoneyIsThereEnough
    pop     de
    and     a,a
    jr      nz,.enough_money
        call    SFX_BuildError
        ret
.enough_money:

    ; Delete
    ; ------

    ld      bc,T_GRASS ; Set as a field tile
    call    CityMapDrawTerrainTile ; bc = tile, e = x, d = y

    ; Decrease money
    ; --------------

    call    BuildingSelectedGetPricePointer ; returns pointer in de
    call    MoneyReduce
    call    SFX_Clear

    ; Update map
    ; ----------

    call    bg_refresh_main

    ret

;###############################################################################
