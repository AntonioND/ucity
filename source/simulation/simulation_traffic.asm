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
    INCLUDE "text_messages.inc"

;###############################################################################

    SECTION "Simulation Traffic Variables",WRAM0

;-------------------------------------------------------------------------------

; Amount of tiles with traffic jams. It will stop counting when it reaches 255.
; Traffic is considered high when it reaches TRAFFIC_MAX_LEVEL.
simulation_traffic_jam_num_tiles:: DS 1

TRAFFIC_MAX_LEVEL EQU (256/3) ; Max level of adequate traffic

;###############################################################################

    SECTION "Simulation Traffic Functions",ROMX

;-------------------------------------------------------------------------------

; Checks bounds, returns a=0 if outside the map else a=value
Simulation_TrafficGetMapValue: ; d=y, e=x

    ld      a,e
    or      a,d
    and     a,128+64 ; ~63
    jr      z,.ok
    xor     a,a
    ret

.ok:
    ld      a,BANK_CITY_MAP_TRAFFIC
    ld      [rSVBK],a

    GET_MAP_ADDRESS ; preserves de and bc
    ld      a,[hl]

    ret

;-------------------------------------------------------------------------------

; Output data to WRAMX bank BANK_CITY_MAP_TRAFFIC
Simulation_Traffic::

    ; Final traffic density and building handled flags go to TRAFFIC map,
    ; temporary expansion map goes to SCRATCH RAM, queue goes to SCRATCH RAM 2

    ; Clear. Set map to 0 to flag all residential buildings as not handled
    ; --------------------------------------------------------------------

    ld      a,BANK_CITY_MAP_TRAFFIC
    ld      [rSVBK],a

    call    ClearWRAMX

    ; Initialize each non-residential building
    ; ----------------------------------------

    ; Get density of each non-residential building and save it in the top left
    ; tile of the building. It will be reduced as needed with each call to
    ; Simulation_TrafficHandleSource.

    ld      hl,CITY_MAP_TRAFFIC ; Map base

    ld      d,0 ; y
.loopy_init:
        ld      e,0 ; x
.loopx_init:

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a
        ld      a,[hl] ; Get type
        and     a,TYPE_MASK

        ; Ignored tile types by decreasing frequency order
        cp      a,TYPE_FIELD
        jr      z,.skip_init
        cp      a,TYPE_WATER
        jr      z,.skip_init
        cp      a,TYPE_RESIDENTIAL
        jr      z,.skip_init
        cp      a,TYPE_FOREST
        jr      z,.skip_init
        cp      a,TYPE_DOCK
        jr      z,.skip_init

            ; de = coordinates of one tile
            ; returns a = 1 if it is the origin, 0 if not
            push    de
            push    hl
            call    BuildingIsCoordinateOrigin
            pop     hl
            pop     de
            and     a,a
            jr      z,.skip_init

                push    de

                push    hl
                call    CityMapGetTileAtAddress ; hl=addr, returns tile=de
                call    CityTileDensity ; de = tile, returns d=population
                pop     hl

                ld      a,BANK_CITY_MAP_TRAFFIC
                ld      [rSVBK],a
                ld      [hl],d

                pop     de
.skip_init:

        inc     hl

        inc     e
        bit     6,e ; CITY_MAP_WIDTH = 64
        jr      z,.loopx_init

    inc     d
    bit     6,d ; CITY_MAP_HEIGHT = 64
    jr      z,.loopy_init

    ; For each tile check if it is a residential building
    ; ---------------------------------------------------

    ; When a building is handled the rest of the tiles of it are flagged as
    ; handled, so we will only check the top left tile of each building.
    ; To flag a building as handled it is set to 1 in the TRAFFIC map

    ; After handling a residential building the density of population that
    ; couldn't get to a valid destination will be stored in the top left tile,
    ; and the rest should be flagged as 1 (handled)

    ; The "amount of cars" that leave a residential building is the same as the
    ; TOP LEFT corner tile density. The same thing goes for the "amount of cars"
    ; that can get into another building. However, all tiles of a building
    ; should have the same density so that the density map makes sense.

    ld      hl,CITY_MAP_TRAFFIC ; Map base

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

    ld      d,0 ; y
.loopy:
        ld      e,0 ; x
.loopx:

            ld      a,[hl] ; Get type

            cp      a,TYPE_RESIDENTIAL
            jr      nz,.skip_tile ; Not residential, skip

                ; Residential building = Source of traffic

                ; Check if handled (1). If so, skip

                ld      a,BANK_CITY_MAP_TRAFFIC
                ld      [rSVBK],a

                ld      a,[hl]
                and     a,a
                jr      nz,.skip_call ; Handled, skip

                push    de
                push    hl
                    ; de = coordinates of top left corner of building
                    LONG_CALL_ARGS  Simulation_TrafficHandleSource
                pop     hl
                pop     de
.skip_call:

                ld      a,BANK_CITY_MAP_TYPE
                ld      [rSVBK],a

.skip_tile:

        inc     hl

        inc     e
        bit     6,e ; CITY_MAP_WIDTH = 64
        jr      z,.loopx

    inc     d
    bit     6,d ; CITY_MAP_HEIGHT = 64
    jr      z,.loopy

    ; Update tiles of the map to show the traffic level
    ; -------------------------------------------------

    ld      hl,CITY_MAP_TRAFFIC ; Map base

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

.loop_map:

        ld      a,[hl] ; Get type

        and     a,TYPE_HAS_ROAD
        jr      z,.not_road ; Not road, skip

            ld      a,BANK_CITY_MAP_TRAFFIC
            ld      [rSVBK],a

            ld      a,[hl]
            bit     7,a
            jr      z,.not_saturated ; if > 127, saturated
            ld      a,255 ; saturated
            jr      .end_saturated_check
.not_saturated:
            add     a,32 ; offset to add more cars
.end_saturated_check:
            ; 8 bits to 2
            rlca
            rlca ; rotate no carry
            and     a,3
            ld      b,a ; b = traffic level

            ld      a,BANK_CITY_MAP_TILES
            ld      [rSVBK],a

            ; All road tiles are < 256, that's why this works!
            ld      a,[hl]

            cp      a,T_ROAD_TB
            jr      z,.rtb
            cp      a,T_ROAD_TB_1
            jr      z,.rtb
            cp      a,T_ROAD_TB_2
            jr      z,.rtb
            cp      a,T_ROAD_TB_3
            jr      z,.rtb

            cp      a,T_ROAD_LR
            jr      z,.rlr
            cp      a,T_ROAD_LR_1
            jr      z,.rlr
            cp      a,T_ROAD_LR_2
            jr      z,.rlr
            cp      a,T_ROAD_LR_3
            jr      z,.rlr

            jr      .not_valid_road ; crossings, etc
.rlr:
            ; Left-Right
            ld      a,T_ROAD_LR
            add     a,b
            jr      .end_tb_lr
.rtb:
            ; Top-Bottom
            ld      a,T_ROAD_TB
            add     a,b
.end_tb_lr:
            ld      [hl],a ; save tile!
            ; The palette should be the same, no need to update!
.not_valid_road:

            ld      a,BANK_CITY_MAP_TYPE
            ld      [rSVBK],a
.not_road:

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop_map

    ; Update map
    ; ----------

;    call    bg_refresh_main

    ret

;-------------------------------------------------------------------------------

Simulation_TrafficAnimate:: ; This doesn't refresh tile map!

    ; Animate tiles of the map with traffic animation
    ; -----------------------------------------------

    ld      hl,CITY_MAP_TRAFFIC ; Map base

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

.loop:

        ld      a,[hl] ; Get type

        and     a,TYPE_HAS_ROAD
        jr      z,.not_road ; Not road, skip

            ld      a,BANK_CITY_MAP_TRAFFIC
            ld      [rSVBK],a

            ld      a,[hl]
            bit     7,a
            jr      z,.not_saturated ; if > 127, saturated
            ld      a,255 ; saturated
.not_saturated:
            ; 8 bits to 2
            rlca
            rlca ; rotate no carry
            and     a,3
            ld      b,a ; b = traffic level

            ld      a,BANK_CITY_MAP_TILES
            ld      [rSVBK],a

            ; All road tiles are < 256, that's why this works!
            ld      a,[hl]

            ; Ignore tiles with traffic level 0

            cp      a,T_ROAD_TB_1
            jr      z,.rtb
            cp      a,T_ROAD_TB_2
            jr      z,.rtb
            cp      a,T_ROAD_TB_3
            jr      z,.rtb

            cp      a,T_ROAD_LR_1
            jr      z,.rlr
            cp      a,T_ROAD_LR_2
            jr      z,.rlr
            cp      a,T_ROAD_LR_3
            jr      z,.rlr

            jr      .not_valid_road ; crossings, etc

.rlr:
            ; Left-Right
            ld      a,BANK_CITY_MAP_ATTR
            ld      [rSVBK],a
            ld      a,1<<5 ; X flip
            xor     a,[hl]
            ld      [hl],a

            jr      .end_tb_lr
.rtb:
            ; Top-Bottom
            ld      a,BANK_CITY_MAP_ATTR
            ld      [rSVBK],a
            ld      a,1<<6 ; Y flip
            xor     a,[hl]
            ld      [hl],a
.end_tb_lr:
.not_valid_road:

            ld      a,BANK_CITY_MAP_TYPE
            ld      [rSVBK],a
.not_road:

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

;###############################################################################

Simulation_TrafficSetTileOkFlag::

    ; NOTE: Don't call when drawing minimaps, this can only be called from the
    ; simulation loop!

    ; - For roads and train, make sure that the traffic is below a certain
    ;   threshold.
    ; - For buildings, make sure that all people could get out of residential
    ;   zones, and that commercial zones and industrial zones could be reached
    ;   by all people.

    xor     a,a
    ld      [simulation_traffic_jam_num_tiles],a

    ld      hl,CITY_MAP_FLAGS ; Base address of the map!

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)
        push    hl

            ld      a,BANK_CITY_MAP_TYPE
            ld      [rSVBK],a

            ld      a,[hl]
            ld      b,a
            and     a,TYPE_HAS_ROAD|TYPE_HAS_TRAIN
            jr      z,.not_road_or_train

                ; Road or train

                ld      a,BANK_CITY_MAP_TRAFFIC
                ld      [rSVBK],a
                ld      a,[hl] ; get traffic level
                cp      a,TRAFFIC_MAX_LEVEL ; carry flag is set if n > a
                jr      c,.tile_set_flag ; set flag to ok

                ; Count the number of road/train tiles that have too much
                ; traffic to show warning messages to the player.

                ld      de,simulation_traffic_jam_num_tiles
                ld      a,[de]
                inc     a
                jr      nz,.not_overflowed ; check if overflow from 255
                dec     a ; if overflowed from 255, return to 255
.not_overflowed:
                ld      [de],a
                jr      .tile_res_flag ; set flag to not ok

.not_road_or_train:

            ld      a,b
            and     a,TYPE_MASK

            ; Check if this is a building or not. If not, set tile as ok
            cp      a,TYPE_FIELD
            jr      z,.tile_set_flag
            cp      a,TYPE_FOREST
            jr      z,.tile_set_flag
            cp      a,TYPE_WATER
            jr      z,.tile_set_flag
            cp      a,TYPE_DOCK
            jr      z,.tile_set_flag ; Ignore docks

            ; This is a building, check it

            push    hl ; save current tile address

            ; de = coordinates of one tile, returns de = origin coordinates
            call    BuildingGetCoordinateOrigin

            ; get origin coordinates into hl
            GET_MAP_ADDRESS ; preserves de and bc

            ld      a,BANK_CITY_MAP_TRAFFIC
            ld      [rSVBK],a
            ld      a,[hl] ; get remaining population of this building

            pop     hl ; restore current tile address

            and     a,a ; If 0, all people could leave / arrive
            jr      z,.tile_set_flag
            ;jr      .tile_res_flag

.tile_res_flag:
            ld      a,BANK_CITY_MAP_FLAGS
            ld      [rSVBK],a
            res     TILE_OK_TRAFFIC_BIT,[hl]
            jr      .tile_end
.tile_set_flag:
            ld      a,BANK_CITY_MAP_FLAGS
            ld      [rSVBK],a
            set     TILE_OK_TRAFFIC_BIT,[hl]
            ;jr      .tile_end
.tile_end:
        pop     hl
        pop     de ; (*)

        inc     hl

        inc     e
        bit     6,e ; CITY_MAP_WIDTH = 64
        jr      z,.loopx

    inc     d
    bit     6,d ; CITY_MAP_HEIGHT = 64
    jr      z,.loopy


    ; Check if traffic is too high
    ; ----------------------------

    ; Complain if more than 64 tiles have high traffic
    ld      a,[simulation_traffic_jam_num_tiles]
    cp      a,64 ; cy = 1 if n > a (threshold > current value)
    ret     c

    ; TODO - Use this for total city score or to make people not want to come
    ; here?

    ; This message is shown only once per year
    ld      a,ID_MSG_TRAFFIC_HIGH
    call    PersistentMessageShow

    ret

;###############################################################################
