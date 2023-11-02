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

; NOTE: To be included in "simulation_anims_transport.asm"

;###############################################################################

    ; Max distance to travel at one go
    DEF BOAT_MAX_CONTINUOUS_DISTANCE EQU 5

;-------------------------------------------------------------------------------

; Generic function to check if the tile at given coordinates is T_WATER or
; T_WATER_EXTRA. It has nothing to do with boats, but it is only used in this
; file so it is called like the rest of the functions in it.
BoatIsWaterTile: ; Arguments: e = x , d = y, returns a = 1 if water

    call    CityMapGetTile ; Arguments: e = x , d = y, returns de = tile

    ; Make sure that both tiles are in the same 256-tile bank
IF (T_WATER >> 8) != (T_WATER_EXTRA >> 8)
    FAIL "Fix this!"
ENDC

    ; T_WATER and T_WATER_EXTRA should be on the same 256-tile boundary
    ld      a,T_WATER >> 8
    cp      a,d
    jr      nz,.not_water

    ld      a,T_WATER & $FF
    cp      a,e
    jr      z,.water

    ld      a,T_WATER_EXTRA & $FF
    cp      a,e
    jr      z,.water

.not_water:
    xor     a,a
    ret

.water:
    ld      a,1
    ret

;-------------------------------------------------------------------------------

BoatSetValidRandomDirection: ; sets valid direction of this boat

    ld      hl,BOAT_X_TILE
    add     hl,bc
    ld      e,[hl]
    dec     e ; extra column

    ld      hl,BOAT_Y_TILE
    add     hl,bc
    ld      d,[hl]
    dec     d ; extra row

    push    bc ; (**12) preserve index

    ; Check all 8 directions until one of them is valid
    ; -------------------------------------------------

    ; If none of them are valid, stand still (set the remaining steps to 0).

    add     sp,-1 ; (***)

    ld      hl,sp+0
    ld      [hl],0

    ; Each bit in register [sp+0] represents one neighbour tile (1 = water)

    ; Direction
    ;   7 0 1
    ;   6   2
    ;   5 4 3

    push    de
    dec     d
    call    BoatIsWaterTile ; Arguments: e = x , d = y, returns a = 1 if water
    pop     de
    and     a,a
    jr      z,.not_0
        ld      hl,sp+0
        set     0,[hl]
.not_0:

    push    de
    dec     d
    inc     e
    call    BoatIsWaterTile
    pop     de
    and     a,a
    jr      z,.not_1
        ld      hl,sp+0
        set     1,[hl]
.not_1:

    push    de
    inc     e
    call    BoatIsWaterTile
    pop     de
    and     a,a
    jr      z,.not_2
        ld      hl,sp+0
        set     2,[hl]
.not_2:

    push    de
    inc     e
    inc     d
    call    BoatIsWaterTile
    pop     de
    and     a,a
    jr      z,.not_3
        ld      hl,sp+0
        set     3,[hl]
.not_3:

    push    de
    inc     d
    call    BoatIsWaterTile
    pop     de
    and     a,a
    jr      z,.not_4
        ld      hl,sp+0
        set     4,[hl]
.not_4:

    push    de
    inc     d
    dec     e
    call    BoatIsWaterTile
    pop     de
    and     a,a
    jr      z,.not_5
        ld      hl,sp+0
        set     5,[hl]
.not_5:

    push    de
    dec     e
    call    BoatIsWaterTile
    pop     de
    and     a,a
    jr      z,.not_6
        ld      hl,sp+0
        set     6,[hl]
.not_6:

    push    de
    dec     d
    dec     e
    call    BoatIsWaterTile
    pop     de
    and     a,a
    jr      z,.not_7
        ld      hl,sp+0
        set     7,[hl]
.not_7:

    ld      hl,sp+0
    ld      b,[hl] ; b = flags

    add     sp,+1 ; (***)

    ; de = coordinates of this tile

    ; All possible directions in register b, chose one of them.
    ; ---------------------------------------------------------

    ld      a,b
    and     a,a
    jp      z,.movement_failed ; Exit if there are no valid directions

    ; b = allowed directions

.loop_rand:

        call    GetRandom ; bc, de preserved

        and     a,b ; remove a few random directions

MACRO CHECK_DIR ; \1 = dir
    cp      a,1 << (\1)
    jr      nz,.skip_this\@
        ld      a,\1
        jp      .loop_rand_end
.skip_this\@:
ENDM

        CHECK_DIR   0
        CHECK_DIR   1
        CHECK_DIR   2
        CHECK_DIR   3
        CHECK_DIR   4
        CHECK_DIR   5
        CHECK_DIR   6
        CHECK_DIR   7

        ; There were too many directions allowed so it couldn't only get one,
        ; set the remaining directions as the allowed ones to speed up the next
        ; iteration.

        ; However, it may have happened that the result after and'ing the random
        ; value and the allowed directions is 0. In that case, skip this step.
        and     a,a
        jr      .loop_rand

        ld      b,a

    jr      .loop_rand

.loop_rand_end:

    ; a = direction to move to!
    ; de = coordinates of this tile

    ; Now that the direction is decided, decide how many tiles to move
    ; ----------------------------------------------------------------

    push    af ; (*) preserve dir

    add     a,a ; sla a
    ld      c,a
    ld      b,0
    ld      hl,.dir_increment
    add     hl,bc

    ld      a,[hl+]
    ld      b,a
    ld      c,[hl]

    ; b = delta x, c = delta y
    ; de = coordinates of this tile (d = y, e = x)

    ld      h,0 ; h = counter

.loop_count_tiles:

        ld      a,e
        add     a,b
        ld      e,a ; e = new x

        ld      a,d
        add     a,c
        ld      d,a ; d = new y

        push    bc
        push    de
        push    hl
        call    BoatIsWaterTile
        pop     hl
        pop     de
        pop     bc

        and     a,a
        jr      z,.end_loop_count_tiles

        inc     h

        ; Stop randomly 1/4 of times

        push    hl
        call    GetRandom ; bc, de preserved
        pop     hl

        cp      a,$C0 ; cy = 1 if n > a
        jr      nc,.end_loop_count_tiles

    jr      .loop_count_tiles

.end_loop_count_tiles:

    ld      a,h ; a = num of tiles to move
    cp      a,BOAT_MAX_CONTINUOUS_DISTANCE ; cy = 1 if n > a
    jr      c,.dont_clamp_tiles
    ld      a,BOAT_MAX_CONTINUOUS_DISTANCE
.dont_clamp_tiles
    add     a,a ; sla a
    add     a,a ; sla a
    add     a,a ; sla a
    ; a = num of steps to do = tiles * 8

    ld      d,a ; d = num of steps

    pop     af ; (*) restore dir
    pop     bc ; (**1) restore index

    ld      hl,BOAT_DIRECTION
    add     hl,bc
    ld      [hl],a ; Set direction and enable

    ; Stand still by setting the remaining steps to 0.
    ld      hl,BOAT_DIRECTION_STEPS_LEFT
    add     hl,bc
    ld      [hl],d

    ret

.movement_failed:

    pop     bc ; (**2) restore index

    ld      a,2 ; Right = default direction in case the boat stays still
    ld      hl,BOAT_DIRECTION
    add     hl,bc
    ld      [hl],a ; Set direction and enable

    ; Stand still by setting the remaining steps to 0.
    ld      hl,BOAT_DIRECTION_STEPS_LEFT
    add     hl,bc
    ld      [hl],0

    ret

.dir_increment: ; x inc, y inc
    DB  0, -1 ; 0 - Top
    DB  1, -1 ; 1 - Top Right
    DB  1,  0 ; 2 - Right
    DB  1,  1 ; 3 - Right Down
    DB  0,  1 ; 4 - Down
    DB -1,  1 ; 5 - Down Left
    DB -1,  0 ; 6 - Left
    DB -1, -1 ; 7 - Left Top

;-------------------------------------------------------------------------------

BoatIsCenteredInTile: ; bc = boat index, returns a=1 if centered, 0 if not

    ld      hl,BOAT_X_IN_TILE
    add     hl,bc
    ld      a,[hl]

    ld      hl,BOAT_Y_IN_TILE
    add     hl,bc
    ld      b,[hl]

    or      a,b
    jr      z,.centered
    xor     a,a
    ret

.centered:
    ld      a,1
    ret

;-------------------------------------------------------------------------------

BoatIsInWater: ; bc = boat index, ret a = 1 if there is water under it else 0

    ld      hl,BOAT_X_TILE
    add     hl,bc
    ld      e,[hl]

    ld      hl,BOAT_Y_TILE
    add     hl,bc
    ld      d,[hl]

    dec     e ; extra row and column
    dec     d
    jp      BoatIsWaterTile ; Arguments: e = x , d = y, returns a = 1 if water

;-------------------------------------------------------------------------------

; Spawn one boat in the border of the map or next to the dock (right after
; another boat disappears)
BoatSpawnDock: ; c = index of the boat

    ; Generate a random number between 0 and the number of docks (which is
    ; clamped to 255).

    ld      a,[COUNT_DOCKS]
    and     a,a
    ret     z ; return if there are no docks

    push    bc ; (*1234) preserve index

    ld      b,a ; b = number of docks

    ld      d,a
    REPT 7
    sra     d
    or      a,d
    ENDR
    ld      d,a ; d = (first power of 2 greater than number of docks) - 1

    ; generate num between 0 and b (b not included)
.loop_rand:
    call    GetRandom ; bc, de preserved
    and     a,d ; reduce the number to make this easier
    cp      a,b ; cy = 1 if b > a
    jr      nc,.loop_rand

    ld      c,a
    ; c = number of the dock to spawn the boat at

    ; Look for the correct dock

    ld      a,BANK_CITY_MAP_TYPE
    ldh     [rSVBK],a

    ld      hl,CITY_MAP_TILES

.loop:
        ld      a,[hl]
        cp      a,TYPE_DOCK
        jr      nz,.end
            ld      a,c
            and     a,a
            jr      z,.spawn
            dec     c
.end:

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ; Dock not found! This means that the number of docks in the cached count
    ; variable is outdated...
    ld      b,b
    pop     bc ; (*1) restore index
    ret

.spawn:

    push    hl
    call    CityMapAddrToCoords ; address = hl, returns d = y, e = x
    pop     hl

    ; Now, de holds the coordinates of the dock and hl the address. Move the
    ; coordinates to the tile of water in front of the dock.

    push    de
    ; Returns: - Tile -> Register DE
    call    CityMapGetTileAtAddress ; Arg: hl = address. Preserves BC, HL
    LD_BC_DE   ; bc = tile number
    pop     de ; de = coordinates

    ; All dock tiles should be in the same 256-tile page
    ld      a,T_PORT_WATER_L >> 8
    cp      a,b
    jr      nz,.dock_panic

    ld      a,T_PORT_WATER_L & $FF
    cp      a,c
    jr      nz,.not_dock_l
        dec     e ; x--
        jr      .dock_check_end
.not_dock_l:
    ld      a,T_PORT_WATER_R & $FF
    cp      a,c
    jr      nz,.not_dock_r
        inc     e ; x++
        jr      .dock_check_end
.not_dock_r:
    ld      a,T_PORT_WATER_D & $FF
    cp      a,c
    jr      nz,.not_dock_d
        inc     d ; y++
        jr      .dock_check_end
.not_dock_d:
    ld      a,T_PORT_WATER_U & $FF
    cp      a,c
    jr      nz,.not_dock_u
        dec     d ; y--
        jr      .dock_check_end
.not_dock_u:

.dock_panic:
    ld      b,b ; Panic!
    pop     bc ; (*2) restore index
    ret

.dock_check_end:

    ; DE holds the coordinates of the water tile in front of the dock. It should
    ; be a water tile, but there are valid reasons for it not to be a valid
    ; water tile. For example, there could be a bridge or another dock.

    push    de ; de = coordinates
    call    BoatIsWaterTile ; Arguments: e = x , d = y, returns a = 1 if water
    pop     de
    and     a,a
    jr      nz,.water_ok

    ; No water in front of the dock, just return, maybe the next time it finds
    ; a dock with water in front of it.
    pop     bc ; (*3) restore index
    ret

.water_ok:

    ; Add the extra rows and columns used in the sprite coordinate system
    inc     d
    inc     e

    pop     bc ; (*4) restore index

    ld      hl,BOAT_X_TILE
    add     hl,bc
    ld      [hl],e

    ld      hl,BOAT_Y_TILE
    add     hl,bc
    ld      [hl],d

    ld      hl,BOAT_X_IN_TILE
    add     hl,bc
    ld      [hl],0

    ld      hl,BOAT_Y_IN_TILE
    add     hl,bc
    ld      [hl],0

    ; Set direction and num of steps

    call    BoatSetValidRandomDirection ; sets valid direction of this boat

    ; Set as invisible so that the OAM coordinates are refreshed later

    ld      hl,BOAT_VISIBLE
    add     hl,bc
    ld      [hl],0

    jp      BoatRefreshSpriteCoordinates ; bc = index, return from there

;-------------------------------------------------------------------------------

; Move sprite on the screen, but object coordinates in the map aren't changed.
; Preserves bc
BoatScroll: ; bc = index, e = value to add to X, d = value to add to Y

    ld      hl,BOAT_X_SPR
    add     hl,bc
    ld      a,[hl]
    add     a,e
    ld      [hl],a

    ld      hl,BOAT_Y_SPR
    add     hl,bc
    ld      a,[hl]
    add     a,d
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------

; Move sprite on the screen and update object coordinates in the map.
; Preserves bc
BoatMove: ; bc = index, e = value to add to X, d = value to add to Y

    ld      hl,BOAT_X_SPR
    add     hl,bc
    ld      a,[hl]
    add     a,e
    ld      [hl],a

    ld      hl,BOAT_Y_SPR
    add     hl,bc
    ld      a,[hl]
    add     a,d
    ld      [hl],a

    ld      hl,BOAT_X_IN_TILE
    add     hl,bc
    ld      a,[hl]
    add     a,e ; we won't need this value anymore
    ld      e,a
    and     a,7
    ld      [hl],a
    ld      a,e
    sra     a
    sra     a
    sra     a
    ld      hl,BOAT_X_TILE
    add     hl,bc
    add     a,[hl]
    ld      [hl],a

    ld      hl,BOAT_Y_IN_TILE
    add     hl,bc
    ld      a,[hl]
    add     a,d ; we won't need this value anymore
    ld      d,a
    and     a,7
    ld      [hl],a
    ld      a,d
    sra     a
    sra     a
    sra     a
    ld      hl,BOAT_Y_TILE
    add     hl,bc
    add     a,[hl]
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------

BoatsMovementStep:

    ld      bc,SIMULATION_MAX_BOATS-1
.loop:

        ld      hl,BOAT_ENABLED
        add     hl,bc
        ld      a,[hl]
        and     a,a ; disabled
        jr      z,.skip

        ld      hl,BOAT_DIRECTION
        add     hl,bc
        ld      a,[hl]
        cp      a,-1 ; not spawned
        jr      z,.skip

        ; Check if number of steps is 0
        ld      hl,BOAT_DIRECTION_STEPS_LEFT
        add     hl,bc
        ld      a,[hl]
        and     a,a
        jr      z,.skip ; Don't update if this is zero!

        ld      hl,BOAT_DIRECTION
        add     hl,bc
        ld      a,[hl]
        ld      l,a
        ld      h,0 ; hl = dir

        ld      de,.dir_increment
        add     hl,hl
        add     hl,de ; array base + 2 * direction

        ld      a,[hl+]
        ld      e,a
        ld      d,[hl] ; e = x inc, d = y inc

        ; Preserves bc
        call    BoatMove ; bc = index, e = value to add to X, d = add to Y

        ; Decrement step numer
        ld      hl,BOAT_DIRECTION_STEPS_LEFT
        add     hl,bc
        dec     [hl]

.skip:

    ld      a,c
    dec     c
    and     a,a
    jr      nz,.loop

    ret

.dir_increment: ; x inc, y inc
    DB  0, -1 ; 0 - Top
    DB  1, -1 ; 1 - Top Right
    DB  1,  0 ; 2 - Right
    DB  1,  1 ; 3 - Right Down
    DB  0,  1 ; 4 - Down
    DB -1,  1 ; 5 - Down Left
    DB -1,  0 ; 6 - Left
    DB -1, -1 ; 7 - Left Top

;-------------------------------------------------------------------------------

; Initialize sprites, find starting coordinates for boats, etc.
BoatsReset: ; a = 1 to force reset, a = 0 reset only if num of boats changes

    and     a,a
    jr      z,.dont_force_reset

    ; Force reset, unspawn all boats

    ld      a,-1
    ld      hl,BOAT_DIRECTION
    ld      b,SIMULATION_MAX_BOATS
    call    memset_fast ; a = value    hl = start address    b = size

.dont_force_reset:

    ; Now, enable only the number of planes desired and unspawn the rest

    xor     a,a ; Disable all
    ld      hl,BOAT_ENABLED
    ld      b,SIMULATION_MAX_BOATS
    call    memset_fast ; a = value    hl = start address    b = size

    ; Count the number of docks. The total number of boats is equal to the
    ; number of docks / 2 up to a max of SIMULATION_MAX_BOATS.

    ld      a,[COUNT_DOCKS]
    sra     a
    cp      a,SIMULATION_MAX_BOATS ; cy = 1 if n > a
    jr      c,.not_max
    ld      a,SIMULATION_MAX_BOATS
.not_max:

    ; a = number of boats

    and     a,a
    jr      z,.skip_enable ; check if number = 0

    push    af ; (**) preserve num of boats

        ld      hl,BOAT_ENABLED
        ld      b,a ; b = number of boats enabled
        ld      a,1
        call    memset_fast ; a = value    hl = start address    b = size

    pop     af ; (**) restore num of boats

.skip_enable:

    ld      b,a
    ld      a,SIMULATION_MAX_BOATS
    sub     a,b ; a = num of disabled boats
    ; b = num of enabled boats

    ld      c,b
    ld      b,0 ; bc = num of enabled boats
    ; a = num of disabled boats

    and     a,a
    ret     z ; no disabled boats, so don't unspawn any of them

    ld      hl,BOAT_DIRECTION
    add     hl,bc
    ld      b,a ; num of disabled boats
    ld      a,-1 ; unspawn
    call    memset_fast ; a = value    hl = start address    b = size

    ret

;-------------------------------------------------------------------------------

BoatsWriteOAM:

    ; For each visible sprite, write the coordinates to the shadow OAM. For
    ; the rest, hide them.

    ld      hl,OAM_Copy+BOAT_SPR_OAM_BASE*4

    DEF INDEX = 0
    REPT    SIMULATION_MAX_BOATS

    ld      a,[BOAT_ENABLED+INDEX]
    and     a,a ; disabled
    jr      z,.invisible\@

    ld      a,[BOAT_DIRECTION+INDEX]
    cp      a,-1 ; not spawned
    jr      z,.invisible\@

    ld      a,[BOAT_VISIBLE+INDEX]
    and     a,a
    jr      z,.invisible\@

        ; Visible

        ld      a,[BOAT_Y_SPR+INDEX]
        ld      [hl+],a
        ld      a,[BOAT_X_SPR+INDEX]
        ld      [hl+],a

        LD_BC_HL

        ; Check direction and change tile and flip flags

        ld      de,.tile_attr_data
        ld      a,[BOAT_DIRECTION+INDEX]
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,de
        ld      a,[hl+]
        ld      d,a ; d = tile
        ld      e,[hl] ; e = attr

        LD_HL_BC

        ld      a,d
        ld      [hl+],a

        ld      a,e
        ld      [hl+],a

        jr      .next\@
.invisible\@:

        ; Invisible

        xor     a,a
        ld      [hl+],a ; Set the Y coordinate is 0, it's enough to hide it.
        inc     l ; Advance to next sprite. HL should be 100h byte aligned, so
        inc     l ; incrementing the low byte is enough.
        inc     l

.next\@:

    DEF INDEX = INDEX+1
    ENDR

    ret

.tile_attr_data:
    DB  BOAT_SPRITE_TILE_START+0, 0
    DB  BOAT_SPRITE_TILE_START+1, OAMF_XFLIP
    DB  BOAT_SPRITE_TILE_START+2, OAMF_XFLIP
    DB  BOAT_SPRITE_TILE_START+1, OAMF_XFLIP|OAMF_YFLIP
    DB  BOAT_SPRITE_TILE_START+0, OAMF_YFLIP
    DB  BOAT_SPRITE_TILE_START+1, OAMF_YFLIP
    DB  BOAT_SPRITE_TILE_START+2, 0
    DB  BOAT_SPRITE_TILE_START+1, 0

;-------------------------------------------------------------------------------

BoatsUpdateVisibility:

    DEF INDEX = 0
    REPT    SIMULATION_MAX_BOATS

    ld      a,[BOAT_ENABLED+INDEX]
    cp      a,-1 ; disabled
    jr      z,.invisible\@

    ld      a,[BOAT_DIRECTION+INDEX]
    cp      a,-1 ; not spawned
    jr      z,.invisible\@

    ; Calculate tile where the boat is located on the screen.

    ; Sprite screen tile = Boat tile coords - Top left bg coords (= scroll)

    ld      a,[BOAT_X_TILE+INDEX]
    ld      hl,bg_x ; bg scroll in tiles
    sub     a,[hl] ; a = delta x tiles
    dec     a
    ld      e,a ; e = delta x tiles

    ld      a,[BOAT_Y_TILE+INDEX]
    ld      hl,bg_y ; bg scroll in tiles
    sub     a,[hl] ; a = delta y tiles
    dec     a
    ld      d,a ; d = delta y tiles

    ; If the sprite is inside the screen (or just next to it) make it visible.
    ; Visible if inside (X, Y) = (-1 ~ 20, -1 ~ 18) -- Screen is 20x18
    ; That means: Leave 1 extra row at each border.

    ld      a,e
    inc     a ; check if unsigned X+1 <= 21
    cp      a,22 ; cy = 1 if n > a
    jr      nc,.invisible\@

    ld      a,d
    inc     a ; check if unsigned Y+1 <= 19
    cp      a,20 ; cy = 1 if n > a
    jr      nc,.invisible\@

        ; Visible

        ld      a,1
        ld      [BOAT_VISIBLE+INDEX],a

        jr      .next\@

.invisible\@:

        ; Invisible

        xor     a,a
        ld      [BOAT_VISIBLE+INDEX],a

.next\@:

    DEF INDEX = INDEX+1
    ENDR

    ret

;-------------------------------------------------------------------------------

BoatsHide:

    xor     a,a
    ld      hl,BOAT_VISIBLE
    ld      b,SIMULATION_MAX_BOATS
    call    memset_fast ; a = value    hl = start address    b = size

    jp      BoatsWriteOAM ; Return from there

;-------------------------------------------------------------------------------

BoatRefreshSpriteCoordinates: ; bc = index

    ; Calculate tile where the boat is located on the screen.

    ; Sprite screen tile = Boat tile coords - Top left bg coords (= scroll)

    ld      hl,BOAT_X_TILE
    add     hl,bc
    ld      a,[hl]
    ld      hl,bg_x ; bg scroll in tiles
    sub     a,[hl] ; a = delta x tiles
    dec     a ; extra row

    sla     a
    sla     a
    sla     a ; X tile * 8
    ld      hl,BOAT_X_IN_TILE
    add     hl,bc
    add     a,[hl]
    add     a,8 ; A = X sprite coordinate in the screen
    ld      hl,BOAT_X_SPR
    add     hl,bc
    ld      [hl],a

    ld      hl,BOAT_Y_TILE
    add     hl,bc
    ld      a,[hl]
    ld      hl,bg_y ; bg scroll in tiles
    sub     a,[hl] ; a = delta y tiles
    dec     a ; extra column

    sla     a
    sla     a
    sla     a ; Y tile * 8
    ld      hl,BOAT_Y_IN_TILE
    add     hl,bc
    add     a,[hl]
    add     a,16 ; A = Y sprite coordinate in the screen
    ld      hl,BOAT_Y_SPR
    add     hl,bc
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------

BoatsShow:

    ; Recalculate sprite coordinates from bg scroll and boat position.

    ld      bc,SIMULATION_MAX_BOATS-1
.loop:
    dec     c
    push    bc
    call    BoatRefreshSpriteCoordinates ; bc = index
    pop     bc
    ld      a,c
    and     a,a
    jr      nz,.loop

    ; If the resulting position is inside the screen, flag as visible. If not,
    ; flag as invisible.

    call    BoatsUpdateVisibility

    jp      BoatsWriteOAM ; Return from there

;-------------------------------------------------------------------------------

BoatsCheckOutOfWater:

    DEF INDEX = 0
    REPT    SIMULATION_MAX_BOATS

    ld      a,[BOAT_ENABLED+INDEX]
    and     a,a ; disabled
    jr      z,.next\@

    ld      a,[BOAT_DIRECTION+INDEX]
    cp      a,-1 ; not spawned
    jr      z,.next\@

    ld      bc,INDEX
    call    BoatIsInWater ; bc = index, returns a = 1 if there is water under it
    and     a,a
    jr      z,.outside\@

    ld      a,[BOAT_X_TILE+INDEX]
    cp      a,64+1 ; cy = 1 if n > a
    jr      nc,.outside\@

    ld      a,[BOAT_Y_TILE+INDEX]
    cp      a,64+1 ; cy = 1 if n > a
    jr      nc,.outside\@

    jr      .inside\@

.outside\@:

        ld      bc,INDEX
        call    BoatSpawnDock ; c = index of the boat
        jr      .next\@

.inside\@:

.next\@:

    DEF INDEX = INDEX+1
    ENDR

    ret

;-------------------------------------------------------------------------------

BoatsSpawnIfEnabled: ; spawn boats that are enabled but not spawned

    DEF INDEX = 0
    REPT    SIMULATION_MAX_BOATS

    ld      a,[BOAT_ENABLED+INDEX]
    and     a,a ; disabled
    jr      z,.next\@

    ld      a,[BOAT_DIRECTION+INDEX]
    cp      a,-1 ; don't spawn if it has already spawned
    jr      Nz,.next\@

    ld      bc,INDEX
    call    BoatSpawnDock

.next\@:

    DEF INDEX = INDEX+1
    ENDR

    ret

;-------------------------------------------------------------------------------

BoatsRestartMovement:

    DEF INDEX = 0
    REPT    SIMULATION_MAX_BOATS

    ld      a,[BOAT_ENABLED+INDEX]
    and     a,a ; disabled
    jr      z,.next\@

    ld      a,[BOAT_DIRECTION+INDEX]
    cp      a,-1 ; not spawned
    jr      z,.next\@

    ld      a,[BOAT_DIRECTION_STEPS_LEFT+INDEX]
    and     a,a
    jr      nz,.next\@ ; skip if this hasn't stopped yet

    ; Start randomly 1/32 of times
    call    GetRandom
    cp      a,256/32 ; cy = 1 if n > a
    jr      nc,.next\@

    ; Set direction and num of steps
    ld      bc,INDEX
    call    BoatSetValidRandomDirection

.next\@:

    DEF INDEX = INDEX+1
    ENDR

    ret

;-------------------------------------------------------------------------------

BoatsVBLHandle:

    ; For each boat, move it.

    call    BoatsMovementStep

    ; After moving, if it is not visible, flag as invisible.

    call    BoatsUpdateVisibility

    jp      BoatsWriteOAM ; Return from there

;-------------------------------------------------------------------------------

BoatsHandle:

    ; Sometimes, when reseting the boats, some of them may not find a valid
    ; starting point. Try to enable all disabled boats here.

    call    BoatsSpawnIfEnabled

    ; When a boat realizes that there is no water under it, unspawn and try to
    ; respawn somewhere else. If there is water, move and change directions if
    ; needed. This means that, in practice, boats are only removed when a bridge
    ; is built under them.

    ; This function may be called after a few updates of the coordinates of the
    ; boats. If that happens, it may be possible that a boat doesn't turn at the
    ; shore and leaves the water. This is ok, it will just dissapear and appear
    ; somewhere else.

    call    BoatsCheckOutOfWater

    ; If the movement steps left of the boat are 0, try to start moving in
    ; another direction.

    call    BoatsRestartMovement

    jp      BoatsWriteOAM ; Return from there

;-------------------------------------------------------------------------------

BoatsHandleScroll: ; d = value to add to y, e = value to add to x

    DEF INDEX = 0
    REPT    SIMULATION_MAX_BOATS
        ld      bc,INDEX
        push    de
        call    BoatScroll ; bc = index, e = value to add to X, d = add to Y
        pop     de
        DEF INDEX = INDEX+1
    ENDR

    call    BoatsUpdateVisibility

    jp      BoatsWriteOAM ; Return from there

;###############################################################################
