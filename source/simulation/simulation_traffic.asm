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

    SECTION "Simulation Traffic Functions",ROMX

;###############################################################################

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

;###############################################################################

; Up to 256 elements (We assume that roads and train tracks are always placed
; in the lowest 256 tiles)

ROAD_BASE_COST  EQU 2
TRAIN_BASE_COST EQU 1

; Equates that tell the directions that a train/car can go from this tile
; Road To / Train To
RT_U EQU $01
RT_R EQU $02
RT_D EQU $04
RT_L EQU $08
TT_U EQU $10
TT_R EQU $20
TT_D EQU $40
TT_L EQU $80

; Equates that tell the directions that a train/car can come to this tile
; Road From / Train From
RF_U EQU $04 ; To match the other equates
RF_R EQU $08
RF_D EQU $01
RF_L EQU $02
TF_U EQU $40
TF_R EQU $80
TF_D EQU $10
TF_L EQU $20

TILE_TRANSPORT_INFO:
  TILE_SET_COUNT 0 ; Add padding

  T_ADD T_ROAD_TB,   2, RT_U|RT_D, RF_U|RF_D
  T_ADD T_ROAD_TB_1, 2, RT_U|RT_D, RF_U|RF_D
  T_ADD T_ROAD_TB_2, 2, RT_U|RT_D, RF_U|RF_D
  T_ADD T_ROAD_TB_3, 2, RT_U|RT_D, RF_U|RF_D

  T_ADD T_ROAD_LR,   2, RT_R|RT_L, RF_R|RF_L
  T_ADD T_ROAD_LR_1, 2, RT_R|RT_L, RF_R|RF_L
  T_ADD T_ROAD_LR_2, 2, RT_R|RT_L, RF_R|RF_L
  T_ADD T_ROAD_LR_3, 2, RT_R|RT_L, RF_R|RF_L

  T_ADD T_ROAD_RB,   2, RT_R|RT_D, RF_R|RF_D
  T_ADD T_ROAD_LB,   2, RT_L|RT_D, RF_L|RF_D
  T_ADD T_ROAD_TR,   2, RT_R|RT_U, RF_R|RF_U
  T_ADD T_ROAD_TL,   2, RT_U|RT_L, RF_U|RF_L

  T_ADD T_ROAD_TRB,  2, RT_U|RT_R|RT_D, RF_U|RF_R|RF_D
  T_ADD T_ROAD_LRB,  2, RT_L|RT_R|RT_D, RF_L|RF_R|RF_D
  T_ADD T_ROAD_TLB,  2, RT_U|RT_L|RT_D, RF_U|RF_L|RF_D
  T_ADD T_ROAD_TLR,  2, RT_U|RT_R|RT_L, RF_U|RF_R|RF_L
  T_ADD T_ROAD_TLRB, 2, RT_U|RT_R|RT_D|RT_L, RF_U|RF_R|RF_D|RF_L

  T_ADD T_ROAD_TB_POWER_LINES, 2, RT_U|RT_D, RF_U|RF_D
  T_ADD T_ROAD_LR_POWER_LINES, 2, RT_R|RT_L, RF_R|RF_L
  T_ADD T_ROAD_TB_BRIDGE, 2, RT_U|RT_D, RF_U|RF_D
  T_ADD T_ROAD_LR_BRIDGE, 2, RT_R|RT_L, RF_R|RF_L

  T_ADD T_TRAIN_TB,   1, TT_U|TT_D, TF_U|TF_D
  T_ADD T_TRAIN_LR,   1, TT_R|TT_L, TF_R|TF_L
  T_ADD T_TRAIN_RB,   1, TT_R|TT_D, TF_R|TF_D
  T_ADD T_TRAIN_LB,   1, TT_L|TT_D, TF_L|TF_D
  T_ADD T_TRAIN_TR,   1, TT_R|TT_U, TF_R|TF_U
  T_ADD T_TRAIN_TL,   1, TT_U|TT_L, TF_U|TF_L

  T_ADD T_TRAIN_TRB,  1, TT_U|TT_R|TT_D, TF_U|TF_R|TF_D
  T_ADD T_TRAIN_LRB,  1, TT_L|TT_R|TT_D, TF_L|TF_R|TF_D
  T_ADD T_TRAIN_TLB,  1, TT_U|TT_L|TT_D, TF_U|TF_L|TF_D
  T_ADD T_TRAIN_TLR,  1, TT_U|TT_R|TT_L, TF_U|TF_R|TF_L
  T_ADD T_TRAIN_TLRB, 1, TT_U|TT_R|TT_D|TT_L, TF_U|TF_R|TF_D|TF_L

  T_ADD T_TRAIN_LR_ROAD, 3, TT_R|TT_L|RT_U|RT_D, TF_R|TF_L|RF_U|RF_D ; Both!
  T_ADD T_TRAIN_TB_ROAD, 3, TT_U|TT_D|RT_R|RT_L, TF_U|TF_D|RF_R|RF_L ; Both!

  T_ADD T_TRAIN_TB_POWER_LINES, 1, TT_U|TT_D, TF_U|TF_D
  T_ADD T_TRAIN_LR_POWER_LINES, 1, TT_R|TT_L, TF_R|TF_L
  T_ADD T_TRAIN_TB_BRIDGE, 1, TT_U|TT_D, TF_U|TF_D
  T_ADD T_TRAIN_LR_BRIDGE, 1, TT_R|TT_L, TF_R|TF_L

;###############################################################################

;-------------------------------------------------------------------------------

; Output data to WRAMX bank BANK_CITY_MAP_TRAFFIC
Simulation_Traffic::

    ; Clear
    ; -----

    ld      a,BANK_CITY_MAP_TRAFFIC
    ld      [rSVBK],a

    ld      bc,$1000
    ld      d,0
    ld      hl,CITY_MAP_TRAFFIC
    call    memset

    ; For each tile check if it is a road
    ; -----------------------------------

    ld      hl,CITY_MAP_TRAFFIC ; Map base

    ld      d,0 ; y
.loopy:
        ld      e,0 ; x
.loopx:
        push    de
        push    hl

            ld      a,BANK_CITY_MAP_TYPE
            ld      [rSVBK],a
            ld      a,[hl] ; Get type

            bit     TYPE_HAS_ROAD_BIT,a
            jr      z,.not_road

                ; Road. Handle traffic

.not_road:

        pop     hl
        pop     de

        inc     hl

        inc     e
        ld      a,CITY_MAP_WIDTH
        cp      a,e
        jr      nz,.loopx

    inc     d
    ld      a,CITY_MAP_HEIGHT
    cp      a,d
    jr      nz,.loopy

    ret

;-------------------------------------------------------------------------------

Simulation_TrafficSetTileOkFlag::

    ; NOTE: Don't call when drawing minimaps, this can only be called from the
    ; simulation loop!

    ; - For roads, make sure that the traffic is below a certain threshold.
    ; - For buildings, make sure that all people could get out of residential
    ; zones, and that commercial zones and industrial zones could be reached
    ; by all people.

    ld      hl,CITY_MAP_FLAGS ; Base address of the map!

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)
        push    hl

            ld      a,BANK_CITY_MAP_FLAGS
            ld      [rSVBK],a
            res     TILE_OK_TRAFFIC_BIT,[hl]

        pop     hl
        pop     de ; (*)

        inc     hl

        inc     e
        bit     6,e
        jp      z,.loopx

    inc     d
    bit     6,d
    jp      z,.loopy

    ret

;###############################################################################
