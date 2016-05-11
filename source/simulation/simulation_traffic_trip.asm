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

    SECTION "Simulation Traffic Trip Functions",ROMX

;-------------------------------------------------------------------------------

TILE_TRANSPORT_INFO_ELEMENT_SIZE EQU 3

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
T_ADD : MACRO ; 1=Tile name, 2=Transit base cost, 3=To, 4=From
    TILE_SET_COUNT (\1)
    DB (\2), (\3), (\4)
CURTILE SET CURTILE+1 ; Set cursor for next item
ENDM

IF TILE_TRANSPORT_INFO_ELEMENT_SIZE != 3
    FAIL "Fix this!"
ENDC

;-------------------------------------------------------------------------------

; Up to 256 elements (We assume that roads and train tracks are always placed
; in the lowest 256 tiles)

; Equates that tell the directions that a train/car can go from this tile or
; the directions that a train/car can come to this tile from
R_U EQU $01
R_R EQU $02
R_D EQU $04
R_L EQU $08
T_U EQU $10
T_R EQU $20
T_D EQU $40
T_L EQU $80

R_U_BIT EQU 0
R_R_BIT EQU 1
R_D_BIT EQU 2
R_L_BIT EQU 3
T_U_BIT EQU 4
T_R_BIT EQU 5
T_D_BIT EQU 6
T_L_BIT EQU 7

TILE_TRANSPORT_INFO: ; Cost, Destinations allowed, Origins allowed
  TILE_SET_COUNT 0 ; Add padding

  T_ADD T_ROAD_TB,   2, R_U|R_D, R_U|R_D
  T_ADD T_ROAD_TB_1, 2, R_U|R_D, R_U|R_D
  T_ADD T_ROAD_TB_2, 2, R_U|R_D, R_U|R_D
  T_ADD T_ROAD_TB_3, 2, R_U|R_D, R_U|R_D

  T_ADD T_ROAD_LR,   2, R_R|R_L, R_R|R_L
  T_ADD T_ROAD_LR_1, 2, R_R|R_L, R_R|R_L
  T_ADD T_ROAD_LR_2, 2, R_R|R_L, R_R|R_L
  T_ADD T_ROAD_LR_3, 2, R_R|R_L, R_R|R_L

  T_ADD T_ROAD_RB,   2, R_R|R_D, R_R|R_D
  T_ADD T_ROAD_LB,   2, R_L|R_D, R_L|R_D
  T_ADD T_ROAD_TR,   2, R_R|R_U, R_R|R_U
  T_ADD T_ROAD_TL,   2, R_U|R_L, R_U|R_L

  T_ADD T_ROAD_TRB,  2, R_U|R_R|R_D, R_U|R_R|R_D
  T_ADD T_ROAD_LRB,  2, R_L|R_R|R_D, R_L|R_R|R_D
  T_ADD T_ROAD_TLB,  2, R_U|R_L|R_D, R_U|R_L|R_D
  T_ADD T_ROAD_TLR,  2, R_U|R_R|R_L, R_U|R_R|R_L
  T_ADD T_ROAD_TLRB, 2, R_U|R_R|R_D|R_L, R_U|R_R|R_D|R_L

  T_ADD T_ROAD_TB_POWER_LINES, 2, R_U|R_D, R_U|R_D
  T_ADD T_ROAD_LR_POWER_LINES, 2, R_R|R_L, R_R|R_L
  T_ADD T_ROAD_TB_BRIDGE, 2, R_U|R_D, R_U|R_D
  T_ADD T_ROAD_LR_BRIDGE, 2, R_R|R_L, R_R|R_L

  T_ADD T_TRAIN_TB,   1, T_U|T_D, T_U|T_D
  T_ADD T_TRAIN_LR,   1, T_R|T_L, T_R|T_L
  T_ADD T_TRAIN_RB,   1, T_R|T_D, T_R|T_D
  T_ADD T_TRAIN_LB,   1, T_L|T_D, T_L|T_D
  T_ADD T_TRAIN_TR,   1, T_R|T_U, T_R|T_U
  T_ADD T_TRAIN_TL,   1, T_U|T_L, T_U|T_L

  T_ADD T_TRAIN_TRB,  1, T_U|T_R|T_D, T_U|T_R|T_D
  T_ADD T_TRAIN_LRB,  1, T_L|T_R|T_D, T_L|T_R|T_D
  T_ADD T_TRAIN_TLB,  1, T_U|T_L|T_D, T_U|T_L|T_D
  T_ADD T_TRAIN_TLR,  1, T_U|T_R|T_L, T_U|T_R|T_L
  T_ADD T_TRAIN_TLRB, 1, T_U|T_R|T_D|T_L, T_U|T_R|T_D|T_L

  T_ADD T_TRAIN_LR_ROAD, 3, T_R|T_L|R_U|R_D, T_R|T_L|R_U|R_D ; Both road and
  T_ADD T_TRAIN_TB_ROAD, 3, T_U|T_D|R_R|R_L, T_U|T_D|R_R|R_L ; train!

  T_ADD T_TRAIN_TB_POWER_LINES, 1, T_U|T_D, T_U|T_D
  T_ADD T_TRAIN_LR_POWER_LINES, 1, T_R|T_L, T_R|T_L
  T_ADD T_TRAIN_TB_BRIDGE, 1, T_U|T_D, T_U|T_D
  T_ADD T_TRAIN_LR_BRIDGE, 1, T_R|T_L, T_R|T_L

;-------------------------------------------------------------------------------

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

    ld      hl,TILE_TRANSPORT_INFO
    add     hl,bc ; bc = tile
    add     hl,bc
    add     hl,bc
    ld      c,[hl]
    inc     hl
    ld      b,[hl]

    ; a = traffic
    ; b = allowed destinations
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

    ; b = allowed destinations
    ; c = current accumulated cost
    ; de = coords (d = y, e = x)
    ; hl = address

    ; Check road and train individually. At most only one check will be done to
    ; each direction because of the way the tiles are designed.

    ; e = x, d = y (original coordinates)

    bit     R_U_BIT,b ; Road Up
    call    nz,TrafficRoadTryMoveUp ; preserves bc,de,hl

    bit     T_U_BIT,b ; Train Up
    call    nz,TrafficTrainTryMoveUp ; preserves bc,de,hl

    ret

;-------------------------------------------------------------------------------

; de = coordinates of destination, hl = address of destination
TrafficRoadAddUp: ; preserves bc and de

    ; Check if Road Down is valid origin for top tile. If so add to queue.

    push    bc
    push    de
    ; hl = address, returns de = tile
    call    CityMapGetTileAtAddress ; preserves hl
    LD_BC_DE
    pop     de ; de = original coords, bc = tile, hl = address

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      a,[hl]
    ld      hl,TILE_TRANSPORT_INFO+2
    add     hl,bc ; bc = tile
    add     hl,bc
    add     hl,bc
    ld      b,[hl] ; b = allowed origins

    bit     R_D_BIT,b ; check if we can come from the orign
    jr      z,.not_allowed
        ; add coordinates of destination tile to the queue
        call    QueueAdd ; preserves BC and DE
.not_allowed:

    pop     bc

    ret

; c = current accumulated cost
; de = current coordinates (d = y, e = x)
; hl = address of current tile
TrafficRoadTryMoveUp: ; preserves bc,de,hl

    ld      a,d
    and     a,a
    ret     z ; return if top row

    push    hl ; (*)

    push    de
    ld      de,-32 ; previous row
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

        push    bc ; de = original coordinates
        push    de ; hl = pointer to origin

            dec     d ; y--

            call    TrafficRoadAddUp ; preserves bc and de

        pop     de
        pop     bc

.handled:
    pop     hl ; (*)

    ret

;-------------------------------------------------------------------------------

; de = coordinates of destination, hl = address of destination
TrafficTrainAddUp: ; preserves bc and de

    ; Check if Train Down is valid origin for top tile. If so add to queue.

    push    bc
    push    de
    ; hl = address, returns de = tile
    call    CityMapGetTileAtAddress ; preserves hl
    LD_BC_DE
    pop     de ; de = original coords, bc = tile, hl = address

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      a,[hl]
    ld      hl,TILE_TRANSPORT_INFO+2
    add     hl,bc ; bc = tile
    add     hl,bc
    add     hl,bc
    ld      b,[hl] ; b = allowed origins

    bit     T_D_BIT,b ; check if we can come from the orign
    jr      z,.not_allowed
        ; add coordinates of destination tile to the queue
        call    QueueAdd ; preserves BC and DE
.not_allowed:

    pop     bc

    ret

; c = current accumulated cost
; de = current coordinates (d = y, e = x)
; hl = address of current tile
TrafficTrainTryMoveUp: ; preserves bc,de,hl

    ld      a,d
    and     a,a
    ret     z ; return if top row

    push    hl ; (*)

    push    de
    ld      de,-32 ; previous row
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

        push    bc ; de = original coordinates
        push    de ; hl = pointer to origin

            dec     d ; y--

            call    TrafficTrainAddUp ; preserves bc and de

        pop     de
        pop     bc

.handled:
    pop     hl ; (*)

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

        dec     d ; dec y
.loop_top:

        push    bc
            call    GetMapAddress ; preserves de, returns address in hl
            ; de = destination coordinates, hl = destination address
            push    hl
                call    TrafficRoadAddUp ; preserves bc and de
            pop     hl
            call    TrafficTrainAddUp ; preserves bc and de
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
        ; TODO
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
        ; TODO
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
        ; TODO
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

; d = y, e = x, coordinates of top left corner of building
Simulation_TrafficHandleSource::

    ; Get dimensions of this building

    ; TODO

    ; Set as handled

    ; TODO

    ; Get density of this building

    ; TODO

    ; Add neighbours of this building source of traffic to the queue

    ; TODO

    ; While queue is not empty, try expanding from it. If a destination is
    ; reached, handle

    ; TODO

    ; If remaining source density is 0, exit

    ; TODO

    ret

;###############################################################################
