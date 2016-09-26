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

    SECTION "Fire Helper Variables",HRAM

;-------------------------------------------------------------------------------

; For a map created by a sane person this should reasonably be 1-16 (?) but it
; can actually go over 255, so the count saturates to 31-1. The number is always
; increased by 1 to make sure that fires end!
initial_number_fire_stations: DS 1

is_destroying_port: DS 1

;###############################################################################

    SECTION "Simulation Fire Functions",ROMX

;-------------------------------------------------------------------------------

; Doesn't update VRAM map.
; d = y, e = x -> Coordinates of one of the tiles.
MapDeleteBuildingFire:: ; Removes a building and replaces it with fire. Fire SFX

    xor     a,a
    ld      [is_destroying_port],a

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

    ld      a,T_PORT & $FF
    cp      a,c
    jr      nz,.not_port
    ld      a,T_PORT>>8
    cp      a,b
    jr      nz,.not_port
    ld      a,1
    ld      [is_destroying_port],a
.not_port:

    push    de
    LONG_CALL_ARGS  BuildingGetSizeFromBaseTileIgnoreErrors
    pop     bc ; bc = coordinates
    ; de = size

    ; Now the demolition can begin!
    ; Size is needed to calculate the money to be spent. Preserve coordinates
    ; and size through the money check!

    ; Delete building and place fire tiles
    ; ------------------------------------

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

    ld      a,[is_destroying_port]
    and     a,a
    jr      z,.skip_port
    push    bc
    push    de

        ld      a,d
        ld      d,b
        ld      b,a

        push    bc
        push    de
        LONG_CALL_ARGS  MapConvertDocksIntoWater
        pop     de
        pop     bc
        ; e = x, d = y
        ; b = width, c = height
        LONG_CALL_ARGS  MapRemoveDocksSurrounding

    pop     de
    pop     bc
.skip_port:

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
            ld      bc,T_FIRE_1
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

    ; bc and de won't be needed after this
    LONG_CALL_ARGS  MapUpdateBuildingSuroundingPowerLines

    ; Sound
    ; -----

    call    SFX_FireExplosion

    ret

;-------------------------------------------------------------------------------

Simulation_FireExpand: ; e = x, d = y, hl = address

    ; Up

    xor     a,a
    cp      a,d
    jr      z,.skip_up
        push    hl
        push    de

        ld      de,-CITY_MAP_WIDTH
        add     hl,de

        ; Returns: - Tile -> Register DE
        call    CityMapGetTileAtAddress ; hl = address. Preserves BC and HL

        push    hl
        call    CityTileFireProbability ; de = tile, returns d = probability
        pop     hl

        ld      a,BANK_SCRATCH_RAM
        ld      [rSVBK],a

        ld      a,d
        add     a,[hl]
        jr      nc,.not_overflowed_up
        ld      a,255
.not_overflowed_up:
        ld      [hl],a

        pop     de
        pop     hl
.skip_up:

    ; Down

    ld      a,CITY_MAP_HEIGHT-1
    cp      a,d
    jr      z,.skip_down
        push    hl
        push    de

        ld      de,+CITY_MAP_WIDTH
        add     hl,de

        ; Returns: - Tile -> Register DE
        call    CityMapGetTileAtAddress ; hl = address. Preserves BC and HL

        push    hl
        call    CityTileFireProbability ; de = tile, returns d = probability
        pop     hl

        ld      a,BANK_SCRATCH_RAM
        ld      [rSVBK],a

        ld      a,d
        add     a,[hl]
        jr      nc,.not_overflowed_down
        ld      a,255
.not_overflowed_down:
        ld      [hl],a

        pop     de
        pop     hl
.skip_down:

    ; Left

    xor     a,a
    cp      a,e
    jr      z,.skip_left
        push    hl
        push    de

        dec     hl

        ; Returns: - Tile -> Register DE
        call    CityMapGetTileAtAddress ; hl = address. Preserves BC and HL

        push    hl
        call    CityTileFireProbability ; de = tile, returns d = probability
        pop     hl

        ld      a,BANK_SCRATCH_RAM
        ld      [rSVBK],a

        ld      a,d
        add     a,[hl]
        jr      nc,.not_overflowed_left
        ld      a,255
.not_overflowed_left:
        ld      [hl],a

        pop     de
        pop     hl
.skip_left:

    ; Right

    ld      a,CITY_MAP_WIDTH-1
    cp      a,e
    jr      z,.skip_right
        push    hl
        push    de

        inc     hl

        ; Returns: - Tile -> Register DE
        call    CityMapGetTileAtAddress ; hl = address. Preserves BC and HL

        push    hl
        call    CityTileFireProbability ; de = tile, returns d = probability
        pop     hl

        ld      a,BANK_SCRATCH_RAM
        ld      [rSVBK],a

        ld      a,d
        add     a,[hl]
        jr      nc,.not_overflowed_right
        ld      a,255
.not_overflowed_right:
        ld      [hl],a

        pop     de
        pop     hl
.skip_right:

    ; End

    ret

;-------------------------------------------------------------------------------

; Output data to WRAMX bank BANK_SCRATCH_RAM
Simulation_Fire::

    ; This should only be called during disaster mode!

    ; Clear
    ; -----

    ; Each tile can receive fire from the 4 neighbours. In this bank the code
    ; adds the probabilities of the tile to catch fire as many times as needed
    ; (e.g. 2 neighbours with fire, 2 x probabilities). Afterwards, a random
    ; number is generated for each tile and if it is lower the tile catches
    ; fire or not.

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    call    ClearWRAMX

    ; For each tile check if it is type TYPE_FIRE and flag to expand fire
    ; -------------------------------------------------------------------

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

    ld      hl,CITY_MAP_TYPE ; Map base

    ld      d,0 ; y
.loopy:
        ld      e,0 ; x
.loopx:

        ld      a,[hl]
        cp      a,TYPE_FIRE
        jr      nz,.skip_tile

        push    de
        push    hl

            call    Simulation_FireExpand ; e = x, d = y, hl = address

        pop     hl
        pop     de

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

.skip_tile:
        inc     hl

        inc     e
        ld      a,CITY_MAP_WIDTH
        cp      a,e
        jr      nz,.loopx

    inc     d
    ld      a,CITY_MAP_HEIGHT
    cp      a,d
    jr      nz,.loopy

    ; Remove fire
    ; -----------

    ld      bc,CITY_MAP_TILES ; Map base

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

.loop_remove:

        ld      a,[bc] ; Get type

        cp      a,TYPE_FIRE
        jr      nz,.loop_remove_not_fire

            ld      a,[initial_number_fire_stations]
            inc     a ; if not, fire would never end with no fire stations
            add     a,a ; sla a
            ld      d,a

            call    GetRandom ; bc and de preserved
            cp      a,d ; cy = 1 if d > a | d = threshold
            jr      nc,.loop_remove_not_fire

                push    bc

                LD_HL_BC
                ld      bc,T_DEMOLISHED
                call    CityMapDrawTerrainTileAddress ; bc = tile, hl = address

                ld      a,BANK_CITY_MAP_TYPE
                ld      [rSVBK],a

                pop     bc

.loop_remove_not_fire:

    inc     bc

    bit     5,b ; Up to E000
    jr      z,.loop_remove

    ; Place fire wherever it was flagged in the previoys loop
    ; -------------------------------------------------------

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      hl,CITY_MAP_TILES ; Map base

    ld      d,0 ; y
.loopy_add:
        ld      e,0 ; x
.loopx_add:

        ld      a,[hl]
        and     a,a
        jr      z,.not_flagged

            push    hl
            ld      b,a
            call    GetRandom ; bc and de preserved
            cp      a,b ; cy = 1 if b > a | d = threshold
            pop     hl
            jr      nc,.over_threshold

                push    hl
                push    de
                ; d = y, e = x -> Coordinates of one of the tiles.
                call    MapDeleteBuildingFire
                pop     de
                pop     hl

                ld      a,BANK_SCRATCH_RAM
                ld      [rSVBK],a

.over_threshold:

.not_flagged:

        inc     hl

        inc     e
        ld      a,CITY_MAP_WIDTH
        cp      a,e
        jr      nz,.loopx_add

    inc     d
    ld      a,CITY_MAP_HEIGHT
    cp      a,d
    jr      nz,.loopy_add

    ; Check if there is fire or not. If not, go back to non-disaster mode
    ; -------------------------------------------------------------------

    ld      hl,CITY_MAP_TILES ; Map base

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

.loop_extinguish:

        ld      a,[hl+] ; Get type

        cp      a,TYPE_FIRE
        jr      z,.found_fire

    bit     5,h ; Up to E000
    jr      z,.loop_extinguish

    ; If not found fire, go back to normal mode

    xor     a,a
    ld      [simulation_disaster_mode],a

.found_fire:

    ; Done
    ; ----

    ret

;-------------------------------------------------------------------------------

Simulation_FireAnimate:: ; This doesn't refresh tile map!

    ld      hl,CITY_MAP_TILES ; Map base

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

.loop:

        ld      a,[hl] ; Get type

        cp      a,TYPE_FIRE
        jr      nz,.not_fire

            ld      a,BANK_CITY_MAP_TILES
            ld      [rSVBK],a

; Actually, this could check if T_FIRE_1 is greater than 255 or T_FIRE_2 is
; lower than 256.
IF ( (T_FIRE_1 % 2) != 0 ) || ( (T_FIRE_1 + 1) != T_FIRE_2 ) || (T_FIRE_1 < 256)
    FAIL "Invalid tile number for fire tiles."
ENDC

            ld      a,1 ; T_FIRE_1 must be even, T_FIRE_2 must be odd.
            xor     a,[hl] ; They must use the same palette
            ld      [hl],a

            ld      a,BANK_CITY_MAP_TYPE
            ld      [rSVBK],a

.not_fire:

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

;-------------------------------------------------------------------------------

; Call with LONG_CALL_ARGS
Simulation_FireTryStart:: ; b = 1 to force fire, 0 to make it random

    ld      a,[simulation_disaster_mode]
    and     a,a
    ret     nz ; Don't start a fire if there is already a fire

    push    bc ; (*) preserve B

    ; Count number of fire stations and save it
    ; -----------------------------------------

    ld      hl,CITY_MAP_TILES ; Map base

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a

.loop_count:

        ld      a,[hl] ; Get LSB of tile
        cp      a,T_FIRE_DEPT & $FF
        jr      nz,.skip_count

            ld      a,BANK_CITY_MAP_ATTR
            ld      [rSVBK],a

            ld      a,[hl] ; Get attrs of tile (MSB)
            bit     3,a ; MSB of tile number
IF T_FIRE_DEPT > 255
            jr      z,.skip_count_restore
ELSE
            jr      nz,.skip_count_restore
ENDC

                ld      a,[initial_number_fire_stations]
                cp      a,30 ; saturate to 30
                jr      z,.skip_count_restore
                    inc     a
                    ld      [initial_number_fire_stations],a

.skip_count_restore:

        ld      a,BANK_CITY_MAP_TILES
        ld      [rSVBK],a

.skip_count:

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop_count

    ; Check if a fire has to start or not
    ; -----------------------------------

    pop     bc ; (*) restore B
    ld      a,b
    and     a,a
    jr      nz,.force_fire

    ; Probabilities depend on the number of fire stations

    ld      a,[initial_number_fire_stations]
    ld      b,16
.shift_loop:
    and     a,a
    jr      z,.end_shift_loop
    sra     b
    jr      nz,.shift_loop
.end_shift_loop:
    inc     b ; leave at least a 1/256 chance of fire!

    call    GetRandom ; bc and de preserved

    cp      a,b ; cy = 1 if b > a
    ret     nc

.force_fire:

    ; If so, try to start it!
    ; -----------------------

    ; Try to get valid starting coordinates a few times, there must be a valid
    ; burnable tile there.

    ld      a,10 ; try ten times
.loop_coordinates:
    push    af

        call    GetRandom ; bc and de preserved
        ld      b,a
        call    GetRandom ; bc and de preserved
        and     a,CITY_MAP_WIDTH-1
        ld      e,a ; e = X
        ld      a,CITY_MAP_HEIGHT-1
        and     a,b
        ld      d,a ; d = Y

        push    de

            call    CityMapGetTile ; Arguments: e = x , d = y

            push    hl
            call    CityTileFireProbability ; de = tile, returns d = probability
            pop     hl

            ld      a,d ; a = probability (it is burnable if != 0)

        pop     de

        and     a,a
        jr      z,.continue_coordinates

            pop     af ; restore stack pointer
            jr      .valid_coordinates

.continue_coordinates:
    pop     af
    dec     a
    jr      nz,.loop_coordinates

    ; Well, it seems that we couldn't find a valid starting point. Someone has
    ; been lucky... :)

    ret

.valid_coordinates:

    ; d = y, e = x -> Coordinates of one of the tiles.
    push    de
        call    MapDeleteBuildingFire

        ld      a,ID_MSG_FIRE_INITED
        call    MessageRequestAdd
    pop     de

    ld      a,d
    sub     a,18/2 ; Vertical size of the screen in tiles
    bit     7,a
    jr      z,.not_negative_y
    xor     a,a
.not_negative_y:
    ld      d,a

    ld      a,e
    sub     a,20/2 ; Horizontal size of the screen in tiles
    bit     7,a
    jr      z,.not_negative_x
    xor     a,a
.not_negative_x:
    ld      e,a

    call    GameRequestCoordinateFocus ; e = x, d = y

    ; Remove all traffic tiles from the map, as well as other animations
    ; ------------------------------------------------------------------

    LONG_CALL   Simulation_TrafficRemoveAnimationTiles

    ; TODO : Remove trains, planes, etc

    ; Enable disaster mode
    ; --------------------

    ld      a,1
    ld      [simulation_disaster_mode],a

    ret

;###############################################################################
