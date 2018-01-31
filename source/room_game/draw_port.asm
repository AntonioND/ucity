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

    SECTION "City Map Draw Port Functions",ROMX

;-------------------------------------------------------------------------------

; Arguments:
; e = x, d = y
; b = width, c = height
; Returns a=1 if there is water in any tile surounding this building (defined by
; its coordinates and size), 0 if not.
MapCheckSurroundingWater:

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
        call    CityMapGetType
        pop     de
        pop     bc
        cp      a,TYPE_WATER
        jr      nz,.not_water_top
        add     sp,4
        ld      a,1 ; found water
        ret
.not_water_top:

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
        call    CityMapGetType
        pop     de
        pop     bc
        cp      a,TYPE_WATER
        jr      nz,.not_water_bottom
        add     sp,4
        ld      a,1 ; found water
        ret
.not_water_bottom:

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
        call    CityMapGetType
        pop     de
        pop     bc
        cp      a,TYPE_WATER
        jr      nz,.not_water_left
        add     sp,4
        ld      a,1 ; found water
        ret
.not_water_left:

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
        call    CityMapGetType
        pop     de
        pop     bc
        cp      a,TYPE_WATER
        jr      nz,.not_water_right
        add     sp,4
        ld      a,1 ; found water
        ret
.not_water_right:

        inc     d ; inc y
        dec     c ; dec height
        jr      nz,.loop_right

    pop     de
    pop     bc
.skip_right_col:

    ; Done
    ; ----

    xor     a,a ; not found water, return 0
    ret

;-------------------------------------------------------------------------------

; Checks all tiles surounding a port and builds docks on the water ones.
; It doesn't refresh the VRAM map
; Arguments:
; e = x, d = y
; b = width, c = height
MapBuildDocksSurrounding:

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
        call    CityMapGetType
        pop     de
        push    de
        cp      a,TYPE_WATER
        jr      nz,.not_water_top
            ld      bc,T_PORT_WATER_U
            call    CityMapDrawTerrainTile ; bc = tile, e = x, d = y
.not_water_top:
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
        call    CityMapGetType
        pop     de
        push    de
        cp      a,TYPE_WATER
        jr      nz,.not_water_bottom
            ld      bc,T_PORT_WATER_D
            call    CityMapDrawTerrainTile ; bc = tile, e = x, d = y
.not_water_bottom:
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
        call    CityMapGetType
        pop     de
        push    de
        cp      a,TYPE_WATER
        jr      nz,.not_water_left
            ld      bc,T_PORT_WATER_L
            call    CityMapDrawTerrainTile ; bc = tile, e = x, d = y
.not_water_left:
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
        call    CityMapGetType
        pop     de
        push    de
        cp      a,TYPE_WATER
        jr      nz,.not_water_right
            ld      bc,T_PORT_WATER_R
            call    CityMapDrawTerrainTile ; bc = tile, e = x, d = y
.not_water_right:
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

; It checks the tiles surounding this port. For each dock tile, if it is facing
; this port, it sets it to water. Docks that belong to other ports are left
; unchanged.
; Arguments:
; e = x, d = y
; b = width, c = height
MapConvertDocksIntoWater::

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
        call    CityMapGetTypeAndTile ; returns de = tile
        ld      a,e
        cp      a,T_PORT_WATER_U&$FF
        jr      nz,.not_top
        ld      a,d
        cp      a,(T_PORT_WATER_U>>8)&$FF
        jr      nz,.not_top
        pop     de
        push    de
        ld      bc,T_WATER
        call    CityMapDrawTerrainTile
.not_top:
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
        call    CityMapGetTypeAndTile ; returns de = tile
        ld      a,e
        cp      a,T_PORT_WATER_D&$FF
        jr      nz,.not_bottom
        ld      a,d
        cp      a,(T_PORT_WATER_D>>8)&$FF
        jr      nz,.not_bottom
        pop     de
        push    de
        ld      bc,T_WATER
        call    CityMapDrawTerrainTile
.not_bottom:
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
        call    CityMapGetTypeAndTile ; returns de = tile
        ld      a,e
        cp      a,T_PORT_WATER_L&$FF
        jr      nz,.not_left
        ld      a,d
        cp      a,(T_PORT_WATER_L>>8)&$FF
        jr      nz,.not_left
        pop     de
        push    de
        ld      bc,T_WATER
        call    CityMapDrawTerrainTile
.not_left:
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
        call    CityMapGetTypeAndTile ; returns de = tile
        ld      a,e
        cp      a,T_PORT_WATER_R&$FF
        jr      nz,.not_right
        ld      a,d
        cp      a,(T_PORT_WATER_R>>8)&$FF
        jr      nz,.not_right
        pop     de
        push    de
        ld      bc,T_WATER
        call    CityMapDrawTerrainTile
.not_right:
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

; Once the docks have been removed with MapConvertDocksIntoWater, this function
; refreshes the water tiles so that the drawings are the correct ones. It is
; needed to do it after converting all tiles to water to avoid partial updates
; of tiles that have an adjacent tile that hasn't had time to be updated.
; It doesn't refresh the VRAM map.
; Arguments:
; e = x, d = y
; b = width, c = height
MapRemoveDocksSurrounding::

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
        call    CityMapGetTypeAndTile ; returns a = type
        cp      a,TYPE_WATER
        jr      nz,.not_top
        pop     de
        push    de
        LONG_CALL_ARGS  UpdateWater ; e = x, d = y
.not_top:
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
        call    CityMapGetTypeAndTile ; returns a = type
        cp      a,TYPE_WATER
        jr      nz,.not_bottom
        pop     de
        push    de
        LONG_CALL_ARGS  UpdateWater ; e = x, d = y
.not_bottom:
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
        call    CityMapGetTypeAndTile ; returns a = type
        cp      a,TYPE_WATER
        jr      nz,.not_left
        pop     de
        push    de
        LONG_CALL_ARGS  UpdateWater ; e = x, d = y
.not_left:
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
        call    CityMapGetTypeAndTile ; returns a = type
        cp      a,TYPE_WATER
        jr      nz,.not_right
        pop     de
        push    de
        LONG_CALL_ARGS  UpdateWater ; e = x, d = y
.not_right:
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

; Draws a port and as many docks as possible (docks are free).
MapDrawPort::

    ; Check if there is water surrounding the building
    ; ------------------------------------------------

    call    CursorGetGlobalCoords ; e = x, d = y
    push    de
    call    BuildingCurrentGetSizeAndBaseTile
    pop     de ; b = width, c = height

    call    MapCheckSurroundingWater
    and     a,a
    ret     z ; return if no water found

    ; If there is not a single square of sea adyacent, return.

    ; Build building
    ; --------------
    LONG_CALL_ARGS  MapDrawBuilding
    ld      a,b
    and     a,a
    ret     nz ; if b=1, error (not enough money or something), so return.

    ; Build docks if everything went fine before
    ; ------------------------------------------

    ; This is free, don't check money

    call    CursorGetGlobalCoords ; e = x, d = y
    push    de
    call    BuildingCurrentGetSizeAndBaseTile
    pop     de ; b = width, c = height

    call    MapBuildDocksSurrounding

    ; Update map
    ; ----------

    call    bg_refresh_main

    ret

;###############################################################################

    SECTION "City Map Draw Port Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

; d = y, e = x -> Coordinates of one of the port tiles (not the docks!).
MapDeletePort:: ; Deletes a port and its docks. Checks money (docks are free).

    ; Get origin of coordinates of the building
    ; -----------------------------------------

    ; Get the first tile of the group

    push    de ; save x and y for later (***)

    call    CityMapGetTypeAndTile
    ld      b,d
    ld      c,e ; bc = tile number

IF TILESET_INFO_ELEMENT_SIZE != 4
    FAIL "draw_port.asm: Fix this!"
ENDC

    push    bc
    ld      b,BANK(TILESET_INFO)
    call    rom_bank_push_set
    pop     bc

    ld      hl,TILESET_INFO
    add     hl,bc ; Use full 9 bit tile number to access the array.
    add     hl,bc ; hl points to the palette + bank1 bit
    add     hl,bc ; Tile number * 4
    add     hl,bc

    inc     hl
    inc     hl ; point to delta x and delta y

    pop     de ; d = y, e = x (***)

    ld      a,[hl+] ; a = delta x
    add     a,e
    ld      e,a ; e = origin x

    ld      a,[hl] ; a = delta y
    add     a,d
    ld      d,a ; d = origin y

    push    de
    call    rom_bank_pop
    pop     de

    ; de = original coordinates

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

    ld      a,b
    ld      b,d
    ld      d,a

    ld      a,c
    ld      c,e
    ld      e,a ; swap coordinates and size

    ; de = coordinates
    ; bc = size

    ; Remove building
    ; ---------------

    push    de
    push    bc
    LONG_CALL_ARGS  MapDeleteBuilding ; de = coordinates
    ld      a,b
    pop     bc
    pop     de ; preserve size and coordinates for next step
    and     a,a
    ret     nz ; if b=1, error (not enough money or something), so return.

    ; Remove docks (if building could be removed)
    ; -------------------------------------------

    ; This is free, don't check money

    push    bc
    push    de
    LONG_CALL_ARGS  MapConvertDocksIntoWater
    pop     de
    pop     bc
    LONG_CALL_ARGS  MapRemoveDocksSurrounding

    ; Update map
    ; ----------

    call    bg_refresh_main

    ret

;###############################################################################
