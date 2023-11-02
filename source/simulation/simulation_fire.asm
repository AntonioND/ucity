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
    INCLUDE "text_messages.inc"
    INCLUDE "tileset_info.inc"

;###############################################################################

    SECTION "Fire Helper Variables",HRAM

;-------------------------------------------------------------------------------

; For a map created by a sane person this should reasonably be 1-16 (?) but it
; can actually go over 255, so the count saturates to 31-1. The number is always
; increased by 1 to make sure that fires end!
; This is calculated before the fire starts. In case the fire starts in a fire
; department, that department counts when calculating the probabilities of the
; fire going off.
initial_number_fire_stations: DS 1

is_destroying_port: DS 1
is_nuclear_power_plant: DS 1

extinguish_fire_probability: DS 1

;###############################################################################

    SECTION "Simulation Fire Functions",ROMX

;-------------------------------------------------------------------------------

; Doesn't update VRAM map.
; d = y, e = x -> Coordinates of one of the tiles.
MapDeleteBuildingFire:: ; Removes a building and replaces it with fire. Fire SFX

    xor     a,a
    ld      [is_destroying_port],a
    ld      [is_nuclear_power_plant],a

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

    ; Special code for nuclear power plants
    ; -------------------------------------

IF (T_POWER_PLANT_NUCLEAR < 256) && (T_POWER_PLANT_FUSION > 256)
    FAIL "The nuclear power plant shouldn't be split in the tileset!"
ENDC

    ld      a,T_POWER_PLANT_NUCLEAR >> 8
    cp      a,b
    jr      nz,.not_nuclear

    ld      a,(T_POWER_PLANT_FUSION - 1) & $FF ; check if above
    cp      a,c ; cy = 1 if c > a
    jr      c,.not_nuclear

    ld      a,(T_POWER_PLANT_NUCLEAR - 1) & $FF ; check if below
    cp      a,c ; cy = 1 if c > a
    jr      nc,.not_nuclear

    ld      a,1 ; Prepare for spreading radiation afterwards
    ld      [is_nuclear_power_plant],a

.not_nuclear:

    ; Special code for sea ports
    ; --------------------------

    ld      a,T_PORT & $FF
    cp      a,c
    jr      nz,.not_port
    ld      a,T_PORT>>8
    cp      a,b
    jr      nz,.not_port
    ld      a,1
    ld      [is_destroying_port],a
.not_port:

    ; Special code for bridges
    ; ------------------------

    ld      a,T_POWER_LINES_TB_BRIDGE & $FF
    cp      a,c
    jr      nz,.not_bridge_tb
    ld      a,T_POWER_LINES_TB_BRIDGE>>8
    cp      a,b
    jr      z,.bridge_tb

.not_bridge_tb:

    ld      a,T_POWER_LINES_LR_BRIDGE & $FF
    cp      a,c
    jr      nz,.not_bridge_lr
    ld      a,T_POWER_LINES_LR_BRIDGE>>8
    cp      a,b
    jr      nz,.not_bridge_lr

.bridge_tb:

        xor     a,a ; don't check money
        call    DrawCityDeleteBridgeWithCheck ; d=y, e=x

        call    SFX_FireExplosion

        ret

.not_bridge_lr:

    ; Special code for roads and train tracks
    ; ---------------------------------------

    ; They can't burn, but they can be deleted by this function when a nuclear
    ; explosion happens. However, we want radiation to destroy roads and train
    ; tracks in a non-nice way to show that it's actually an explosion. By not
    ; fixing the roads around the destroyed one, the visual effect is better.

    ; Rest of tiles
    ; -------------

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

    push    bc
    push    de ; save for later (***) - note that de=size, bc=coordinates

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

    pop     bc ; note that de=size, bc=coordinates when pushed, so swap order
    pop     de ; restore for next step (***)

    ; Update power lines around!
    ; --------------------------

    ; bc = size, not needed after this
    push    de
    LONG_CALL_ARGS  MapUpdateBuildingSuroundingPowerLines
    pop     de

    ; Handle nuclear power plant radiation
    ; ------------------------------------

    ld      a,[is_nuclear_power_plant]
    and     a,a
    jr      z,.dont_spread_radiation

    ; If the building is a nuclear power plant, spread radiation around it.
    ; This can call recursively to the function we are in right now!
    LONG_CALL_ARGS   Simulation_RadiationSpread ; d = y, e = x

.dont_spread_radiation:

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
        ldh     [rSVBK],a

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
        ldh     [rSVBK],a

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
        ldh     [rSVBK],a

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
        ldh     [rSVBK],a

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
Simulation_Fire:: ; This doesn't refresh the BG

    ; This should only be called during disaster mode!

    ; Clear
    ; -----

    ; Each tile can receive fire from the 4 neighbours. In this bank the code
    ; adds the probabilities of the tile to catch fire as many times as needed
    ; (e.g. 2 neighbours with fire, 2 x probabilities). Afterwards, a random
    ; number is generated for each tile and if it is lower the tile catches
    ; fire or not.

    ld      a,BANK_SCRATCH_RAM
    ldh     [rSVBK],a

    call    ClearWRAMX

    ; For each tile check if it is type TYPE_FIRE and try to expand fire
    ; ------------------------------------------------------------------

    ld      a,BANK_CITY_MAP_TYPE
    ldh     [rSVBK],a

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
        ldh     [rSVBK],a

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

    ; Calculate probability of the fire in a tile being extinguished

    ld      a,[initial_number_fire_stations]
    ld      l,a
    ld      h,0
    inc     hl ; if not, fire would never end with no fire stations
    add     hl,hl ; hl = (num + 1) * 2
    ld      a,h
    and     a,a
    jr      nz,.saturated
        ld      a,l
        jr      .end_probabilities
.saturated:
        ld      a,255
.end_probabilities:
    ld      [extinguish_fire_probability],a

    ; Check every tile...

    ld      bc,CITY_MAP_TILES ; Map base

    ld      a,BANK_CITY_MAP_TYPE
    ldh     [rSVBK],a

.loop_remove:

        ld      a,[bc] ; Get type

        cp      a,TYPE_FIRE
        jr      nz,.loop_remove_not_fire

            ld      a,[extinguish_fire_probability]
            ld      d,a

            call    GetRandom ; bc and de preserved
            cp      a,d ; cy = 1 if d > a | d = threshold
            jr      nc,.loop_remove_not_fire

                push    bc

                LD_HL_BC
                ld      bc,T_DEMOLISHED
                call    CityMapDrawTerrainTileAddress ; bc = tile, hl = address

                ld      a,BANK_CITY_MAP_TYPE
                ldh     [rSVBK],a

                pop     bc

.loop_remove_not_fire:

    inc     bc

    bit     5,b ; Up to E000
    jr      z,.loop_remove

    ; Place fire wherever it was flagged in the previous loop
    ; -------------------------------------------------------

    ld      a,BANK_SCRATCH_RAM
    ldh     [rSVBK],a

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
                ldh     [rSVBK],a

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
    ldh     [rSVBK],a

.loop_extinguish:

        ld      a,[hl+] ; Get type

        cp      a,TYPE_FIRE
        jr      z,.found_fire

    bit     5,h ; Up to E000
    jr      z,.loop_extinguish

    ; If not found fire, go back to normal mode

    xor     a,a
    ld      [simulation_disaster_mode],a

    ; A fire may have destroyed buildings, we need to refresh the counts
    LONG_CALL   Simulation_CountBuildings

    ld      b,1 ; Force reset of all planes to new coordinates
    LONG_CALL   Simulation_TransportAnimsInit
    LONG_CALL   Simulation_TransportAnimsShow

.found_fire:

    ; Done
    ; ----

    ret

;-------------------------------------------------------------------------------

Simulation_FireAnimate:: ; This doesn't refresh tile map!

    ld      hl,CITY_MAP_TILES ; Map base

    ld      a,BANK_CITY_MAP_TYPE
    ldh     [rSVBK],a

.loop:

        ld      a,[hl] ; Get type

        cp      a,TYPE_FIRE
        jr      nz,.not_fire

            ld      a,BANK_CITY_MAP_TILES
            ldh     [rSVBK],a

; Actually, this could check if T_FIRE_1 is greater than 255 or T_FIRE_2 is
; lower than 256.
IF ( (T_FIRE_1 % 2) != 0 ) || ( (T_FIRE_1 + 1) != T_FIRE_2 ) || (T_FIRE_1 < 256)
    FAIL "Invalid tile number for fire tiles."
ENDC

            ld      a,1 ; T_FIRE_1 must be even, T_FIRE_2 must be odd.
            xor     a,[hl] ; They must use the same palette
            ld      [hl],a

            ld      a,BANK_CITY_MAP_TYPE
            ldh     [rSVBK],a

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

    ; Save initial number of fire stations
    ; ------------------------------------

    ld      a,[COUNT_FIRE_STATIONS]
    ld      [initial_number_fire_stations],a

    ; Check if a fire has to start or not
    ; -----------------------------------

    pop     bc ; (*) restore B
    ld      a,b
    and     a,a
    jr      nz,.force_fire

    ; Probabilities depend on the number of fire stations

    ld      a,[initial_number_fire_stations]
    ld      b,4
.shift_loop: ; wait until fire stations is 0 or b is 0
    and     a,a
    jr      z,.end_shift_loop
    dec     a
    dec     b
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

    LONG_CALL   Simulation_TransportAnimsHide

    ; Enable disaster mode
    ; --------------------

    ld      a,1
    ld      [simulation_disaster_mode],a

    ret

;###############################################################################
