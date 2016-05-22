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

    SECTION "Simulation Traffic Trip Variables",HRAM

;-------------------------------------------------------------------------------

; Remaining density in the residential building being handled at the moment.
source_building_remaining_density: DS 1

;###############################################################################

    SECTION "Simulation Traffic Trip Functions",ROMX

;-------------------------------------------------------------------------------

TILE_TRANSPORT_INFO_ELEMENT_SIZE EQU 1

CURTILE SET 0

; Tile Set Count
TILE_SET_COUNT : MACRO ; 1 = Tile number
    IF (\1) < CURTILE ; check if going backwards and stop if so
        FAIL "ERROR : building_info.asm : Tile already in use!"
    ENDC
    IF (\1) > CURTILE ; If there's a hole to fill, fill it
        REPT (\1) - CURTILE
            DS TILE_TRANSPORT_INFO_ELEMENT_SIZE ; Empty
        ENDR
    ENDC
CURTILE SET (\1)
ENDM

; Tile Add
T_ADD : MACRO ; 1=Tile name, 2=Transit base cost
    TILE_SET_COUNT (\1)
    DB (\2)
CURTILE SET CURTILE+1 ; Set cursor for next item
ENDM

IF TILE_TRANSPORT_INFO_ELEMENT_SIZE != 1
    FAIL "Fix this!"
ENDC

;-------------------------------------------------------------------------------

; Up to 256 elements (We assume that roads and train tracks are always placed
; in the lowest 256 tiles)

TILE_TRANSPORT_INFO: ; Cost
  TILE_SET_COUNT 0 ; Add padding

  T_ADD T_ROAD_TB,   2
  T_ADD T_ROAD_TB_1, 2
  T_ADD T_ROAD_TB_2, 2
  T_ADD T_ROAD_TB_3, 2

  T_ADD T_ROAD_LR,   2
  T_ADD T_ROAD_LR_1, 2
  T_ADD T_ROAD_LR_2, 2
  T_ADD T_ROAD_LR_3, 2

  T_ADD T_ROAD_RB,   2
  T_ADD T_ROAD_LB,   2
  T_ADD T_ROAD_TR,   2
  T_ADD T_ROAD_TL,   2

  T_ADD T_ROAD_TRB,  2
  T_ADD T_ROAD_LRB,  2
  T_ADD T_ROAD_TLB,  2
  T_ADD T_ROAD_TLR,  2
  T_ADD T_ROAD_TLRB, 2

  T_ADD T_ROAD_TB_POWER_LINES, 2
  T_ADD T_ROAD_LR_POWER_LINES, 2
  T_ADD T_ROAD_TB_BRIDGE, 2
  T_ADD T_ROAD_LR_BRIDGE, 2

  T_ADD T_TRAIN_TB,   1
  T_ADD T_TRAIN_LR,   1
  T_ADD T_TRAIN_RB,   1
  T_ADD T_TRAIN_LB,   1
  T_ADD T_TRAIN_TR,   1
  T_ADD T_TRAIN_TL,   1

  T_ADD T_TRAIN_TRB,  1
  T_ADD T_TRAIN_LRB,  1
  T_ADD T_TRAIN_TLB,  1
  T_ADD T_TRAIN_TLR,  1
  T_ADD T_TRAIN_TLRB, 1

  T_ADD T_TRAIN_LR_ROAD, 3
  T_ADD T_TRAIN_TB_ROAD, 3

  T_ADD T_TRAIN_TB_POWER_LINES, 1
  T_ADD T_TRAIN_LR_POWER_LINES, 1
  T_ADD T_TRAIN_TB_BRIDGE, 1
  T_ADD T_TRAIN_LR_BRIDGE, 1

;-------------------------------------------------------------------------------

; From the specified positions, get the current accumulated cost, calculate the
; cost of this tile and add it. If the top cost is not reached, try to expand
; in all directions. Top cost is 255. If it goes to 256 and overflows, it is
; considered to be too far for the car/train to get there.
TrafficTryExpand: ; d=y, e=x => current position

    ; Arguments: e = x , d = y
    push    de
    call    CityMapGetTileNoBoundCheck ; returns tile = de, address = hl
    LD_BC_DE ; bc = tile
    pop     de ; de = coords
    ; hl = address

    ld      a,BANK_CITY_MAP_TRAFFIC
    ld      [rSVBK],a

    ld      a,[hl] ; get current traffic
    cp      a,255
    ret     z ; this tile is full of traffic, ignore

IF TILE_TRANSPORT_INFO_ELEMENT_SIZE != 1
    FAIL "Fix this!"
ENDC

    ld      hl,TILE_TRANSPORT_INFO
    add     hl,bc ; bc = tile
    ld      c,[hl] ; load cost

    ; a = traffic
    ; c = base cost of moving from this tile
    ; de = coords
    ; hl = address

    swap    a
    rra
    and     a,7
    add     a,c
    ld      c,a ; c = real cost of moving from this tile

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      a,[hl] ; get current accumulated cost

    add     a,c ; new accumulated cost
    ret     c ; if overflow, we can't advance from this tile, return!
    ld      c,a

    ; c = current accumulated cost
    ; de = coords (d = y, e = x)
    ; hl = address

    ; The functions will check inside if the tile has already been handled.

    call    TrafficTryMoveUp ; preserves bc,de,hl

    call    TrafficTryMoveRight ; preserves bc,de,hl

    call    TrafficTryMoveDown ; preserves bc,de,hl

    call    TrafficTryMoveLeft ; preserves bc,de,hl

    ret

;-------------------------------------------------------------------------------

; Try to add a certain tile to the queue. Only non-residential buildings and
; road/train tracks are allowed.

; c = accumulated cost
; de = coordinates of destination, hl = address of destination
; preserves bc and de
TrafficAdd:

    ; Check if it is a building. If so, add to queue immediately.

    ; Only buildings can have density != 0, so check if it is different than
    ; residential and if density != 0, it can't be field or water. If both
    ; conditions are met, ignore direction check and add to queue.

    ; If density == 0 it means it is a road or train (if not, the tile wouldn't
    ; have been added to the queue). Just check directions and add to queue if
    ; the movement is allowed.

    ; In any case, if it is added to the queue, write the accumulated cost up to
    ; this point to the tile as well if it's not a building. If it's a building
    ; it means that we have reached a destination.

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a
    ld      a,[hl]
    and     a,TYPE_MASK

    cp      a,TYPE_RESIDENTIAL
    ret     z ; Ignore residential zones
    cp      a,TYPE_DOCK
    ret     z ; Ignore docks

    cp      a,TYPE_FIELD
    jr      z,.not_a_building
    cp      a,TYPE_FOREST
    jr      z,.not_a_building
    cp      a,TYPE_WATER
    jr      z,.not_a_building

    ; Building, add to queue but don't save accumulated cost.

    call    QueueAdd ; preserves BC and DE
    ret

.not_a_building:
    ; Not a building, add to queue and save accumulated cost

    push    bc ; (*)

    ; add coordinates of destination tile to the queue and write the accumulated
    ; cost to the tile
    call    QueueAdd ; preserves BC and DE

    call    GetMapAddress ; de = tile, hl = address. preserves de
    pop     bc ; (*) c = accumulated cost

    ld      [hl],c ; set cost

    ret

;-------------------------------------------------------------------------------

; c = current accumulated cost
; de = current coordinates (d = y, e = x)
; hl = address of current tile
TrafficTryMoveUp: ; preserves bc,de,hl

    ld      a,d
    and     a,a
    ret     z ; return if top row

    push    hl ; (*)

    push    de
    ld      de,-CITY_MAP_WIDTH ; previous row
    add     hl,de
    pop     de ; hl = pointer to origin

    ; Check if already handled. If so, check if the new cost is lower
    ; than the previous one.

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      a,[hl]
    and     a,a
    jr      nz,.not_handled

    ; This has been handled before. If the cost is lower than the stored one
    ; continue. If not, return.

    cp      a,c
    jr      z,.handled ; same cost, don't repeat

    cp      a,c ; carry flag is set if c > a (current cost > old cost)
    jr      c,.handled ; higher cost, ignore

.not_handled:

        ; c = accumulated cost
        push    bc ; de = original coordinates
        push    de ; hl = pointer to origin

            dec     d ; y--

            call    TrafficAdd ; preserves bc and de

        pop     de
        pop     bc

.handled:
    pop     hl ; (*)

    ret

;-------------------------------------------------------------------------------

; c = current accumulated cost
; de = current coordinates (d = y, e = x)
; hl = address of current tile
TrafficTryMoveDown: ; preserves bc,de,hl

    ld      a,CITY_MAP_HEIGHT-1
    cp      a,d
    ret     z ; return if bottom row

    push    hl ; (*)

    push    de
    ld      de,+CITY_MAP_WIDTH ; next row
    add     hl,de
    pop     de ; hl = pointer to origin

    ; Check if already handled. If so, check if the new cost is lower
    ; than the previous one.

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      a,[hl]
    and     a,a
    jr      nz,.not_handled

    ; This has been handled before. If the cost is lower than the stored one
    ; continue. If not, return.

    cp      a,c
    jr      z,.handled ; same cost, don't repeat

    cp      a,c ; carry flag is set if c > a (current cost > old cost)
    jr      c,.handled ; higher cost, ignore

.not_handled:

        ; c = accumulated cost
        push    bc ; de = original coordinates
        push    de ; hl = pointer to origin

            inc     d ; y++

            call    TrafficAdd ; preserves bc and de

        pop     de
        pop     bc

.handled:
    pop     hl ; (*)

    ret

;-------------------------------------------------------------------------------

; c = current accumulated cost
; de = current coordinates (d = y, e = x)
; hl = address of current tile
TrafficTryMoveLeft: ; preserves bc,de,hl

    ld      a,e
    and     a,a
    ret     z ; return if left column

    push    hl ; (*)

    dec     hl ; previous column
    ; hl = pointer to origin

    ; Check if already handled. If so, check if the new cost is lower
    ; than the previous one.

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      a,[hl]
    and     a,a
    jr      nz,.not_handled

    ; This has been handled before. If the cost is lower than the stored one
    ; continue. If not, return.

    cp      a,c
    jr      z,.handled ; same cost, don't repeat

    cp      a,c ; carry flag is set if c > a (current cost > old cost)
    jr      c,.handled ; higher cost, ignore

.not_handled:

        ; c = accumulated cost
        push    bc ; de = original coordinates
        push    de ; hl = pointer to origin

            dec     e ; x--

            call    TrafficAdd ; preserves bc and de

        pop     de
        pop     bc

.handled:
    pop     hl ; (*)

    ret

;-------------------------------------------------------------------------------

; c = current accumulated cost
; de = current coordinates (d = y, e = x)
; hl = address of current tile
TrafficTryMoveRight: ; preserves bc,de,hl

    ld      a,CITY_MAP_WIDTH-1
    cp      a,e
    ret     z ; return if right column

    push    hl ; (*)

    inc     hl ; next column
    ; hl = pointer to origin

    ; Check if already handled. If so, check if the new cost is lower
    ; than the previous one.

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      a,[hl]
    and     a,a
    jr      nz,.not_handled

    ; This has been handled before. If the cost is lower than the stored one
    ; continue. If not, return.

    cp      a,c
    jr      z,.handled ; same cost, don't repeat

    cp      a,c ; carry flag is set if c > a (current cost > old cost)
    jr      c,.handled ; higher cost, ignore

.not_handled:

        ; c = accumulated cost
        push    bc ; de = original coordinates
        push    de ; hl = pointer to origin

            inc     e ; x++

            call    TrafficAdd ; preserves bc and de

        pop     de
        pop     bc

.handled:
    pop     hl ; (*)

    ret

;-------------------------------------------------------------------------------

; Add initial tiles that are next to a residential building. The only allowed
; destinations are road and train tracks tiles.

; de = coordinates of destination
; preserves bc and de
TrafficAddStart:

    push    bc
    call    CityMapGetTypeNoBoundCheck ; returns type in A. Preserves de
    pop     bc ; de = original coords

    and     a,TYPE_HAS_ROAD|TYPE_HAS_TRAIN
    ret     z ; return if there is no road or train

    ; add coordinates of destination tile to the queue
    call    QueueAdd ; preserves BC and DE

    ; set initial cost to 1!

    ld      a,BANK_CITY_MAP_TRAFFIC
    ld      [rSVBK],a

    push    bc
    call    GetMapAddress
    pop     bc
    ld      [hl],1

    ret

;-------------------------------------------------------------------------------

; Arguments:
; e = x, d = y
; b = width, c = height
Traffic_AddBuildingNeighboursToQueue:

    ; Top row
    ; -------
    ld      a,d
    and     a,a
    jr      z,.skip_top_row ; skip row if this is the topmost row
    push    bc
    push    de

        dec     d ; y - 1
.loop_top:

        call    TrafficAddStart ; de = destination coords. preserves bc and de

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
    cp      a,CITY_MAP_HEIGHT ; this shouldn't overflow!
    jr      nc,.skip_bottom_row ; skip row if this is the last row
    push    bc
    push    de

        ld      d,a ; y + height
.loop_bottom:

        call    TrafficAddStart ; de = destination coords. preserves bc and de

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

        dec     e ; x - 1
.loop_left:

        call    TrafficAddStart ; de = destination coords. preserves bc and de

        inc     d ; inc y
        dec     c ; dec height
        jr      nz,.loop_left

    pop     de
    pop     bc
.skip_left_col:

    ; Right column
    ; ------------

    ld      a,e
    add     a,b ; a = x + width
    cp      a,CITY_MAP_WIDTH ; this shouldn't overflow!
    jr      nc,.skip_right_col ; skip column  if this is the last column
    push    bc
    push    de

        ld      e,a ; x + width
.loop_right:

        call    TrafficAddStart ; de = destination coords. preserves bc and de

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

; de = coordinates of any tile
; returns hl = origin of coordinates address
;         a = building assigned population density
Simulation_TrafficGetBuildingDensityAndPointer:

    ; de = coordinates of one tile, returns de = coordinates of the origin
    call    BuildingGetCoordinateOrigin

    ; get origin coordinates into hl
    call    GetMapAddress ; Preserves DE

    push    hl

    call    CityMapGetTileAtAddress ; hl=addr, returns tile=de

    call    CityTileDensity ; de = tile, returns d=population, e=energy
    ld      a,d

    pop     hl

    ret

;-------------------------------------------------------------------------------

; When calling this function for the first time in the simulation step the
; caller must ensure that every destination building has its max population
; density in its top left tile. This function will reduce them as needed
; so that the next time it is called the previous call would be taken into
; account.

; d = y, e = x, coordinates of top left corner of building
Simulation_TrafficHandleSource::

    ; Get density of this building
    ; ----------------------------

    ; Get the density of this building (source) and save it to a variable
    ; that will be decreased in the queue loop below. This doesn't need to
    ; be saved to the map.

    push    de

    call    GetMapAddress ; Preserves DE

    call    CityMapGetTileAtAddress ; hl=addr, returns tile=de

    call    CityTileDensity ; de = tile, returns d=population, e=eneddrgy
    ld      a,d

    pop     de

    and     a,a
    ret     z ; If density is 0, exit (this is the case for R tiles)

    ; If not, save it to a variable and start!

    ld      [source_building_remaining_density],a

    ; Get dimensions of this building
    ; -------------------------------

    ; Get base tile
    push    de
    call    CityMapGetTile ; returns tile in de
    LD_BC_DE
    ; bc = base tile

    ; bc = base tile. returns size: d=height, e=width
    LONG_CALL_ARGS  BuildingGetSizeFromBaseTile
    LD_BC_DE
    pop     de ; de = coordinates
    ; bc = size

    ; Flag as handled (density 1)
    ; ---------------------------

    ; The top left tile will be overwritten at the end of this function with the
    ; remaining population to travel (or 0 if everyone reached a valid
    ; destination).

    push    bc
    push    de ; (***)

        ; e = x, d = y
        ; b = height, c = width

        ld      a,b ; height
        ld      b,d ; b = y
        ld      d,a ; d = height

        ; e = x, d = height
        ; b = y, c = width

        ld      a,d ; height
        ld      d,c ; d = width
        ld      c,a ; c = height

        ld      a,BANK_CITY_MAP_TRAFFIC
        ld      [rSVBK],a

        ; e = x, d = width
        ; b = y, c = height
.height_loop_set_handled:

        push    de ; (**) save width and x for next row

        push    bc
        push    de
        ; e = x, d = width
        ; b = y, c = height
        ld      d,b
        ; Returns address in HL. Preserves de
        call    GetMapAddress ; e = x , d = y
        pop     de
        pop     bc
        ; hl = pointer to start of building row

        ld      a,1

.width_loop_set_handled:

            ; Loop

            ld      [hl+],a

            inc     e ; inc x

            dec     d ; dec width
            jr      nz,.width_loop_set_handled

        pop     de ; (**) restore width and x

        ; Next row
        inc     b ; inc y

        dec     c ; dec height
        jr      nz,.height_loop_set_handled

    pop     de  ;(***)
    pop     bc

    ; Init queue
    ; ----------

    call    QueueInit

    ; Add neighbours of this building source of traffic to the queue
    ; --------------------------------------------------------------

    ; e = x, d = y
    ; b = width, c = height
    push    de ; (**) preserve top left coordinates

    call    Traffic_AddBuildingNeighboursToQueue
    ; size is not needed from now on, coordinates are needed at the end

    ; While queue is not empty, expand
    ; --------------------------------

pop de
ret
ld b,b

.loop_expand:
        ; In short:
        ; 1) Check that there is population that need to continue traveling.
        ; 2) Check that there are tiles to handle.
        ; 3) Get tile coordinates to handle
        ; 4) Read tile type.
        ;    - If road => expand
        ;    - If building =>
        ;      - Check building remaining density
        ;      - Reduce the source density by that amount or reduce the
        ;        destination amount (depending on which one is higher)

        ; Check if remaining source density is 0. If so, exit.

        ld      a,[source_building_remaining_density]
        and     a,a
        jr      z,.loop_expand_exit

        ; Check if there are tiles left to handle. If not, exit.

        call    QueueIsEmpty
        and     a,a
        jr      nz,.loop_expand_exit

        ; Get tile coordinates and type.

        call    QueueGet ; get coordinates in de

        ; Returns type of the tile + extra flags -> register A
        call    CityMapGetTypeNoBoundCheck ; Args: e = x , d = y. Preserves DE

        and     a,TYPE_HAS_ROAD|TYPE_HAS_TRAIN
        jr      z,.loop_expand_not_road_train

            ; This is a road or train tracks. Expand and continue to next tile.

            call    TrafficTryExpand ; d=y, e=x => current position

            jr      .loop_expand

.loop_expand_not_road_train:
            ; If this is not a road or train tracks, it must be a building, and
            ; not a residential one because the expand functions wouldn't allow
            ; that.

            ; Check if it has enough remaining density to accept more
            ; population. If there is some population left in the tile it means
            ; that it can accept more population. Reduce it as much as possible
            ; and continue in next tile with the remaining population.

            ; de = coordinates of any tile
            ; returns hl = origin of coordinates address
            ;         a = building assigned population density
            call    Simulation_TrafficGetBuildingDensityAndPointer

            ld      b,a
            ld      a,[source_building_remaining_density]
            ; b = destination building desired population
            ; a = source building remaining population

            ; c = min(a,b). That's the amount to reduce in src and dest

            cp      a,b ; cy = 1 if b > a
            jr      c,.b_gt_a
            ld      c,b ; a > b
            jr      .end_min
.b_gt_a:
            ld      c,a ; b > a
.end_min:

            ; Subtract min from both places

            sub     a,c
            ld      d,a ; save a

            ld      a,b
            sub     a,c
            ld      b,a

            ld      a,d ; restore a

            ; b = destination building desired population
            ; a = source building remaining population

            ld      [source_building_remaining_density],a

            ; HL should hold the top left tile of the destination building
            ld      [hl],b

            jr      .loop_expand

.loop_expand_exit:

    ; If there is remaining density, restore it to the source building
    ; ----------------------------------------------------------------

    pop     de ; (**) restore top left coordinates

    ; This means that the people from this building will be unhappy!

    ; The same happens for other buildings, if its final density is not 0 it
    ; means that this building doesn't get all the people it needs for working!

    call    GetMapAddress

    ld      a,BANK_CITY_MAP_TRAFFIC
    ld      [rSVBK],a

    ld      a,[source_building_remaining_density]
    ld      [hl],a

    ; End of this building
    ; --------------------

    ret

;###############################################################################
