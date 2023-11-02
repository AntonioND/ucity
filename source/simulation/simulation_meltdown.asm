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

    SECTION "Nuclear Meltdown Functions",ROMX

;-------------------------------------------------------------------------------

Simulation_Radiation::

    ; Clear
    ; -----

    ;ld      a,BANK_SCRATCH_RAM ; Is this even needed?
    ;ldh     [rSVBK],a

    ;call    ClearWRAMX

    ; Remove radiation
    ; ----------------

    ld      bc,CITY_MAP_TILES ; Map base

    ld      a,BANK_CITY_MAP_TYPE
    ldh     [rSVBK],a

.loop_remove:

        ld      a,[bc] ; Get type

        cp      a,TYPE_RADIATION
        jr      nz,.loop_remove_not_radiation

            call    GetRandom ; bc and de preserved
            and     a,a ; only remove radiation if rand() = 0 (1 / 256 chance)
            jr      nz,.loop_remove_not_radiation

                push    bc

                ; If water, set to water again. If ground, set to ground

                LD_HL_BC
                call    CityMapGetTileAtAddress ; hl = addr. Preserves BC and HL
                ; de = tile

IF T_RADIATION_GROUND ^ T_RADIATION_WATER & 256
    FAIL "The 2 radiation tiles should be in the same 256 tile bank!"
ENDC
                ld      a,T_RADIATION_GROUND >> 8
                cp      a,d ; verify MSB
                jr      nz,.loop_remove_not_radiation

                ld      a,T_RADIATION_WATER & $FF
                cp      a,e
                jr      z,.is_water

                ld      a,T_RADIATION_GROUND & $FF
                cp      a,e
                jr      z,.is_ground

                ld      b,b ; Unknown tile
                jr      nz,.end_replace_tile

.is_water:
                ; address is at BC and HL, get coordinates

                ld      bc,T_WATER
                push    hl
                call    CityMapDrawTerrainTileAddress ; bc = tile, hl = address
                pop     hl
                LD_BC_HL

                ld      a,c
                and     a,CITY_MAP_WIDTH-1

                ld      e,a ; X

                ld      a,c
                and     a,$C0
                ld      l,a
                ld      a,b
                and     a,$0F
                ld      h,a ; HL = Y << 6
                add     hl,hl
                add     hl,hl ; HL = Y << 8, H = Y

                ld      d,h ; Y

                ; d = y, e = x -> Coordinates of one of the tiles.
                LONG_CALL_ARGS  UpdateWater
                jr      .end_replace_tile

.is_ground:

                ld      bc,T_GRASS
                call    CityMapDrawTerrainTileAddress ; bc = tile, hl = address

                ;jr      .end_replace_tile

.end_replace_tile:

                ld      a,BANK_CITY_MAP_TYPE
                ldh     [rSVBK],a

                pop     bc

.loop_remove_not_radiation:

    inc     bc

    bit     5,b ; Up to E000
    jr      z,.loop_remove

    ; Done
    ; ----

    ret

;-------------------------------------------------------------------------------

Simulation_RadiationSpread:: ; d = y, e = x -> Spread radiation around here

    ; Consider e,d to be the top left coordinates of the power plant!

    inc     d
    inc     e ; move to "center"

    ; Radiation can destroy buildings. Consider every tile of radiation added
    ; the same thing as destroying a tile with fire.

    ld      c,16 ; number of tiles of radiation to generate
.loop:
    push    bc
    push    de

        ; Move to a random point surounding the center

        call    GetRandom ; bc and de preserved
        and     a,15
        sub     a,8
        add     a,e
        ld      e,a

        call    GetRandom ; bc and de preserved
        and     a,15
        sub     a,8
        add     a,d
        ld      d,a

        ld      a,d
        or      a,e
        and     a,128|64
        jr      nz,.out_of_map

            ; Make the building in this tile explode and then place a radiation
            ; tile on it.

            push    de

            call    CityMapGetTypeAndTile ; e=x, d=y. returns a=type, de=tile

            cp      a,TYPE_RADIATION ; If there is already radiation here,
            jr      nz,.not_radiation ; skip this tile.
                pop     de
                jr      .out_of_map
.not_radiation:

            call    CityTileFireProbability ; de = tile, returns d = probability
            ld      a,d ; a = probability (it is burnable if != 0)

            pop     de

            and     a,a
            jr      z,.not_burnable
                push    de
                LONG_CALL_ARGS  MapDeleteBuildingFire ; de = coordinates
                pop     de
.not_burnable:

            ; Now, replace the tile by a radiation tile. Check if water or land
            ; to write the correct radiation tile.

            GET_MAP_ADDRESS ; preserves de and bc

            ld      a,BANK_CITY_MAP_TYPE
            ldh     [rSVBK],a

            ld      a,[hl]
            and     a,TYPE_MASK
            cp      a,TYPE_WATER
            jr      z,.is_water
            cp      a,TYPE_DOCK
            jr      z,.is_water
            ld      bc,T_RADIATION_GROUND
            jr      .end_water_check
.is_water:
            ld      bc,T_RADIATION_WATER
.end_water_check:
            call    CityMapDrawTerrainTile ; bc = tile, e = x, d = y

.out_of_map:

    pop     de
    pop     bc
    dec     c
    jr      nz,.loop

    call    bg_refresh_main

    ret

;-------------------------------------------------------------------------------

; Call with LONG_CALL_ARGS
Simulation_MeltdownTryStart:: ; b = 1 to force disaster, 0 to make it random

    ld      a,[simulation_disaster_mode]
    and     a,a
    ret     nz ; Don't start a disaster if there is already a disaster

    ; If there are no nucler power plants, return

    ld      a,[COUNT_NUCLEAR_POWER_PLANTS]
    and     a,a
    ret     z ; There are no nuclear power plants, return.

    ; For each nucler power plant, check if it explodes. If it does, search the
    ; map for its position and make it explode, force a fire there and start
    ; disaster mode. When a nuclear plant catches fire it spreads radiactive
    ; tiles (it is done in the function that burns buildings, there's a special
    ; case for nuclear fission power plants), so the tiles don't have to be
    ; spread in this function.

    ld      d,a ; d = num of nuclear power plants
    ld      e,0 ; loop counter

    ld      a,b
    and     a,a
    jr      nz,.force_explode ; force explosion at the first plant!

.loop_rand:
    call    GetRandom ; de, bc preserved
    and     a,a
    jr      z,.explode
    inc     e
    ld      a,d
    cp      a,e
    jr      nz,.loop_rand

    ; No explosion!
    ret

.explode:

    call    GetRandom ; de, bc preserved
    and     a,7
    ret     nz ; Return 1/8 times

.force_explode:

    ; e = index of power plant that exploded

    ; Look for the power plant that generated the explosion
    ; -----------------------------------------------------

    ld      bc,CITY_MAP_TILES ; Map base

    ld      a,BANK_CITY_MAP_TILES
    ldh     [rSVBK],a

.loop_check:

        ld      a,[bc] ; Get LSB of tile
        cp      a,T_POWER_PLANT_NUCLEAR_CENTER & $FF
        jr      nz,.skip_check

            ld      a,BANK_CITY_MAP_ATTR
            ldh     [rSVBK],a

            ld      a,[bc] ; Get attrs of tile (MSB)
            bit     3,a ; MSB of tile number
IF T_POWER_PLANT_NUCLEAR_CENTER > 255 ; Different check if tile index > 255
            jr      z,.skip_check_restore
ELSE
            jr      nz,.skip_check_restore
ENDC
                ld      a,e
                and     a,a ; is this the plant to explode?
                jr      z,.explode_plant
                dec     e

.skip_check_restore:

        ld      a,BANK_CITY_MAP_TILES
        ldh     [rSVBK],a

.skip_check:

    inc     bc

    bit     5,b ; Up to E000
    jr      z,.loop_check

    ; If we got to this point, no power plant exploded, but it should have!
    ld      b,b ; Breakpoint

    ret

.explode_plant:

    ; bc = pointer to tile = BASE + Y << 6 + X

    ; Convert pointer to coordinates

    ld      a,c
    and     a,CITY_MAP_WIDTH-1

    ld      e,a ; X

    ld      a,c
    and     a,$C0
    ld      l,a
    ld      a,b
    and     a,$0F
    ld      h,a ; HL = Y << 6
    add     hl,hl
    add     hl,hl ; HL = Y << 8, H = Y

    ld      d,h ; Y

    ; d = y, e = x -> Coordinates of one of the tiles.
    push    de
        ; This will spread radiation around the power plant when it detects
        ; that the building is a nuclear power plant.
        LONG_CALL_ARGS  MapDeleteBuildingFire ; de = coordinates

        ld      a,ID_MSG_NUCLEAR_MELTDOWN
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
