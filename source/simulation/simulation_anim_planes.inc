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

; Spawn one plane in any place of the map
PlaneSpawnAllMap: ; c = index of the plane

    ld      b,0 ; bc = index of the plane

    ; Random variables...

    call    GetRandom ; bc, de preserved
    and     a,CITY_MAP_WIDTH-1
    ld      e,a ; e = x

    call    GetRandom ; bc, de preserved
    and     a,CITY_MAP_HEIGHT-1
    ld      d,a ; d = y

    ld      hl,PLANE_X_TILE
    add     hl,bc
    ld      [hl],e ; PLANE_X_TILE[bc] = e

    ld      hl,PLANE_Y_TILE
    add     hl,bc
    ld      [hl],d

    xor     a,a

    ld      hl,PLANE_X_IN_TILE
    add     hl,bc
    ld      [hl],a

    ld      hl,PLANE_Y_IN_TILE
    add     hl,bc
    ld      [hl],a

    call    GetRandom ; bc, de preserved
    and     a,PLANE_NUM_DIRECTIONS-1
    ld      hl,PLANE_DIRECTION
    add     hl,bc
    ld      [hl],a ; By setting a direction the plane is enabled as well.

PlaneSpawnCommon: ; bc = index of the plane

    ; Clear variables...

    xor     a,a

    ld      hl,PLANE_VISIBLE
    add     hl,bc  ; Set as invisible so that the OAM coordinates are refreshed
    ld      [hl],0 ; later.

    call    GetRandom ; bc, de preserved
    and     a,PLANE_CHANGE_DIR_RANGE-1
    add     a,PLANE_CHANGE_DIR_MIN
    ld      hl,PLANE_DIRECTION_CHANGE_COUNTDOWN
    add     hl,bc
    ld      [hl],a

    jp      PlaneRefreshSpriteCoordinates ; bc = index, return from there

;-------------------------------------------------------------------------------

; Spawn one plane in the border of the map or next to the airport (right after
; another plane disappears)
PlaneSpawnBorderOrAirport: ; c = index of the plane

    call    GetRandom ; bc, de preserved
    bit     2,a ; leave 2 bits for spawn at border calculations
    jp      z,.spawn_airport

        ; Spawn at border
        ; ---------------

        ld      b,0
        push    bc ; (*) preserve bc = index

        ; Calculate index of the border to spawn the plane at
        and     a,3
        ld      b,a ; b = 2-bit random value (index of border)

        ; This code assumes that the city width is the same as the height so
        ; that this random value can be used for X or Y.
IF CITY_MAP_WIDTH != CITY_MAP_HEIGHT
    ERROR "Fix this!"
ENDC

        ; Calculate random coordinate, the other one is 0 or CITY_MAP_HEIGHT
        call    GetRandom ; bc, de preserved
        and     a,CITY_MAP_WIDTH-1 ; Same as CITY_MAP_HEIGHT-1
        inc     a
        ld      e,a ; e = random value from 1 to city dimension
        ; This way row/column 0 is skipped and the last one as well. They are
        ; hidden so this is the correct thing to do.

        ; Calculate num from 0 to 2, both included
.loop_rand_012:
        call    GetRandom ; bc, de preserved
        and     a,3
        cp      a,3
        jr      z,.loop_rand_012
        ld      d,a ; d = num from 0 to 2 to calculate direction

        ld      a,b ; prepare to compare border

        pop     bc ; (*) restore bc = index

        ; a = border
        ; bc = plane index
        ; d = direction offset
        ; e = random coordinate

        cp      a,0
        jr      nz,.not_top

            ; Top

            ld      a,3 ; bottom right ~ bottom left
            add     a,d
            and     a,PLANE_NUM_DIRECTIONS-1
            ld      hl,PLANE_DIRECTION
            add     hl,bc
            ld      [hl],a ; Set direction and enable

            ld      hl,PLANE_X_TILE
            add     hl,bc
            ld      [hl],e ; PLANE_X_TILE[bc] = e

            ld      hl,PLANE_Y_TILE
            add     hl,bc
            ld      [hl],0

            ld      hl,PLANE_X_IN_TILE
            add     hl,bc
            ld      [hl],0

            ld      hl,PLANE_Y_IN_TILE
            add     hl,bc
            ld      [hl],0

            ; bc = index
            jp      PlaneSpawnCommon ; return from there
.not_top:
        cp      a,1
        jr      nz,.not_right

            ; Right

            ld      a,5 ; bottom left ~ top left
            add     a,d
            and     a,PLANE_NUM_DIRECTIONS-1
            ld      hl,PLANE_DIRECTION
            add     hl,bc
            ld      [hl],a ; Set direction and enable

            ld      hl,PLANE_X_TILE
            add     hl,bc
            ld      [hl],CITY_MAP_WIDTH

            ld      hl,PLANE_Y_TILE
            add     hl,bc
            ld      [hl],e

            ld      hl,PLANE_X_IN_TILE
            add     hl,bc
            ld      [hl],6 ; max offset in tile (scroll is done by 2 px)

            ld      hl,PLANE_Y_IN_TILE
            add     hl,bc
            ld      [hl],0

            ; bc = index
            jp      PlaneSpawnCommon ; return from there
.not_right:
        cp      a,2
        jr      nz,.not_bottom

            ; Bottom

            ld      a,7 ; top left ~ top right
            add     a,d
            and     a,PLANE_NUM_DIRECTIONS-1
            ld      hl,PLANE_DIRECTION
            add     hl,bc
            ld      [hl],a ; Set direction and enable

            ld      hl,PLANE_X_TILE
            add     hl,bc
            ld      [hl],e ; PLANE_X_TILE[bc] = e

            ld      hl,PLANE_Y_TILE
            add     hl,bc
            ld      [hl],CITY_MAP_HEIGHT

            ld      hl,PLANE_X_IN_TILE
            add     hl,bc
            ld      [hl],0

            ld      hl,PLANE_Y_IN_TILE
            add     hl,bc
            ld      [hl],6 ; max offset in tile (scroll is done by 2 px)

            ; bc = index
            jp      PlaneSpawnCommon ; return from there
.not_bottom:

            ; Left

            ld      a,1 ; top right ~ bottom right
            add     a,d
            and     a,PLANE_NUM_DIRECTIONS-1
            ld      hl,PLANE_DIRECTION
            add     hl,bc
            ld      [hl],a ; Set direction and enable

            ld      hl,PLANE_X_TILE
            add     hl,bc
            ld      [hl],0

            ld      hl,PLANE_Y_TILE
            add     hl,bc
            ld      [hl],e

            ld      hl,PLANE_X_IN_TILE
            add     hl,bc
            ld      [hl],0

            ld      hl,PLANE_Y_IN_TILE
            add     hl,bc
            ld      [hl],0

            ; bc = index
            jp      PlaneSpawnCommon ; return from there

.spawn_airport:

    ; Spawn at airport
    ; ----------------

    ; Generate a random number between 0 and the number of airports (which is
    ; clamped to 255, why whould anyone build more than 251 airports anyway?).

    ld      a,[COUNT_AIRPORTS]
    and     a,a
    ret     z ; return if there are no airports

    push    bc ; (*12) preserve index

    ld      b,a ; b = number of airports

    ld      d,a
    REPT 7
    sra     d
    or      a,d
    ENDR
    ld      d,a ; d = (first power of 2 greater than number of airports) - 1

    ; generate num between 0 and b (b not included)
.loop_rand:
    call    GetRandom ; bc, de preserved
    and     a,d ; reduce the number to make this easier
    cp      a,b ; cy = 1 if b > a
    jr      nc,.loop_rand

    ld      c,a
    ; c = number of the airport to spawn the plane at

    ; Look for the correct airport

    ld      hl,CITY_MAP_TILES

.loop:
        ; Returns: - Tile -> Register DE
        call    CityMapGetTileAtAddress ; Arg: hl = address. Preserves BC, HL

        ld      a,(T_AIRPORT_RUNWAY)&$FF
        cp      a,e
        jr      nz,.end
        ld      a,(T_AIRPORT_RUNWAY)>>8
        cp      a,d
        jr      nz,.end
            ld      a,c
            and     a,a
            jr      z,.spawn
            dec     c
.end:

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ; Aiport not found! This means that the number of airports in the cached
    ; count variable is outdated...
    ld      b,b
    pop     bc ; (*1) restore index
    ret

.spawn:

    call    CityMapAddrToCoords ; address = hl, returns d = y, e = x
    inc     d ; Add the extra rows and columns used in the sprite coordinate
    inc     e ; system.

    pop     bc ; (*2) restore index

    ld      a,PLANE_TAKEOFF_DIRECTION
    ld      hl,PLANE_DIRECTION
    add     hl,bc
    ld      [hl],a ; Set direction and enable

    ld      hl,PLANE_X_TILE
    add     hl,bc
    ld      [hl],e

    ld      hl,PLANE_Y_TILE
    add     hl,bc
    ld      [hl],d

    ld      hl,PLANE_X_IN_TILE
    add     hl,bc
    ld      [hl],0

    ld      hl,PLANE_Y_IN_TILE
    add     hl,bc
    ld      [hl],0

    jp      PlaneSpawnCommon ; return from there

;-------------------------------------------------------------------------------

; Move sprite on the screen, but object coordinates in the map aren't changed.
; Preserves bc
PlaneScroll: ; bc = index, e = value to add to X, d = value to add to Y

    ld      hl,PLANE_X_SPR
    add     hl,bc
    ld      a,[hl]
    add     a,e
    ld      [hl],a

    ld      hl,PLANE_Y_SPR
    add     hl,bc
    ld      a,[hl]
    add     a,d
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------

; Move sprite on the screen and update object coordinates in the map.
; Preserves bc
PlaneMove: ; bc = index, e = value to add to X, d = value to add to Y

    ld      hl,PLANE_X_SPR
    add     hl,bc
    ld      a,[hl]
    add     a,e
    ld      [hl],a

    ld      hl,PLANE_Y_SPR
    add     hl,bc
    ld      a,[hl]
    add     a,d
    ld      [hl],a

    ld      hl,PLANE_X_IN_TILE
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
    ld      hl,PLANE_X_TILE
    add     hl,bc
    add     a,[hl]
    ld      [hl],a

    ld      hl,PLANE_Y_IN_TILE
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
    ld      hl,PLANE_Y_TILE
    add     hl,bc
    add     a,[hl]
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------

PlanesMovementStep:

    ld      bc,SIMULATION_MAX_PLANES-1
.loop:

        ld      hl,PLANE_DIRECTION
        add     hl,bc
        ld      a,[hl]
        cp      a,-1 ; disabled
        jr      z,.skip

        ld      hl,PLANE_DIRECTION_CHANGE_COUNTDOWN
        add     hl,bc
        dec     [hl]
        jr      nz,.end_change_dir
            call    GetRandom ; bc, de preserved
            ld      e,a

            ld      a,PLANE_CHANGE_DIR_RANGE-1
            and     a,e
            add     a,PLANE_CHANGE_DIR_MIN
            ld      hl,PLANE_DIRECTION_CHANGE_COUNTDOWN
            add     hl,bc
            ld      [hl],a

            call    GetRandom ; bc, de preserved
            bit     6,a
            jr      z,.end_change_dir ; don't change this time

            bit     7,a ; rotate right or left?
            jr      z,.inc_dir
                ld      hl,PLANE_DIRECTION
                add     hl,bc
                ld      a,[hl]
                dec     a
                and     a,PLANE_NUM_DIRECTIONS-1
                ld      [hl],a
                jr      .end_change_dir
.inc_dir
                ld      hl,PLANE_DIRECTION
                add     hl,bc
                ld      a,[hl]
                inc     a
                and     a,PLANE_NUM_DIRECTIONS-1
                ld      [hl],a

.end_change_dir:

        ld      hl,PLANE_DIRECTION
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
        call    PlaneMove ; bc = index, e = value to add to X, d = add to Y

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

; Initialize sprites, find starting coordinates for trains, etc.
PlanesReset: ; a = 1 to force reset, a = 0 reset only if num of planes changes

    and     a,a
    jr      nz,.force_reset

    ; if number of airports is the same, return
    ld      a,[COUNT_AIRPORTS]
    ld      hl,OLD_NUM_AIRPORTS
    cp      a,[hl]
    ret     z

    ; Skip reset of all planes, only the planes that are enabled now are reseted
    jr      .reset_common

.force_reset:

    ; Disable all planes so that all visible planes will be reseted

    ld      a,-1
    ld      hl,PLANE_DIRECTION
    ld      b,SIMULATION_MAX_PLANES
    call    memset_fast ; a = value    hl = start address    b = size

.reset_common:

    ; Count the number of airports. The total number of planes is equal to the
    ; number of airports * 2 up to a max of SIMULATION_MAX_PLANES.

    ld      a,[COUNT_AIRPORTS]
    ld      [OLD_NUM_AIRPORTS],a ; update saved number of airports

    add     a,a ; sla     a
    cp      a,SIMULATION_MAX_PLANES ; cy = 1 if n > a
    jr      c,.not_max
    ld      a,SIMULATION_MAX_PLANES
.not_max:

    ; A holds the number of planes (up to SIMULATION_MAX_PLANES)

    ; Initialize planes to any point in the map

    ld      bc,0 ; c = counter variable for the next two loops

    and     a,a
    jr      z,.skip_all_spawn ; check if number = 0

.spawn_plane:
    push    af ; save top num
        ld      hl,PLANE_DIRECTION
        add     hl,bc
        ld      a,[hl]
        cp      a,-1 ; If disabled, enable
        jr      nz,.skip_spawn
            push    bc
            call    PlaneSpawnAllMap
            pop     bc
.skip_spawn:
    pop     af
    inc     c
    cp      a,c
    jr      nz,.spawn_plane

.skip_all_spawn:
    ; Disable the rest of the planes

    cp      a,SIMULATION_MAX_PLANES
    ret     z

    ; bc is still the counter variable
    ld      d,-1 ; disable value
    ld      a,SIMULATION_MAX_PLANES ; limit
.disable_plane:
    ld      hl,PLANE_DIRECTION
    add     hl,bc
    ld      [hl],d
    inc     c
    cp      a,c
    jr      nz,.disable_plane

    ret

;-------------------------------------------------------------------------------

PlanesWriteOAM:

    ; For each visible sprite, write the coordinates to the shadow OAM. For
    ; the rest, hide them.

    ld      hl,OAM_Copy+PLANE_SPR_OAM_BASE*4

    DEF INDEX = 0
    REPT    SIMULATION_MAX_PLANES

    ld      a,[PLANE_DIRECTION+INDEX]
    cp      a,-1 ; disabled
    jr      z,.invisible\@

    ld      a,[PLANE_VISIBLE+INDEX]
    and     a,a
    jr      z,.invisible\@

        ; Visible

        ld      a,[PLANE_Y_SPR+INDEX]
        ld      [hl+],a
        ld      a,[PLANE_X_SPR+INDEX]
        ld      [hl+],a

        LD_BC_HL

        ; Check direction and change tile and flip flags

        ld      de,.tile_attr_data
        ld      a,[PLANE_DIRECTION+INDEX]
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
    DB  PLANE_SPRITE_TILE_START+0, 0
    DB  PLANE_SPRITE_TILE_START+1, OAMF_XFLIP
    DB  PLANE_SPRITE_TILE_START+2, OAMF_XFLIP
    DB  PLANE_SPRITE_TILE_START+1, OAMF_XFLIP|OAMF_YFLIP
    DB  PLANE_SPRITE_TILE_START+0, OAMF_YFLIP
    DB  PLANE_SPRITE_TILE_START+1, OAMF_YFLIP
    DB  PLANE_SPRITE_TILE_START+2, 0
    DB  PLANE_SPRITE_TILE_START+1, 0

;-------------------------------------------------------------------------------

PlanesUpdateVisibility:

    DEF INDEX = 0
    REPT    SIMULATION_MAX_PLANES

    ld      a,[PLANE_DIRECTION+INDEX]
    cp      a,-1 ; disabled
    jr      z,.invisible\@

    ; Calculate tile where the plane is located on the screen.

    ; Sprite screen tile = Plane tile coords - Top left bg coords (= scroll)

    ld      a,[PLANE_X_TILE+INDEX]
    ld      hl,bg_x ; bg scroll in tiles
    sub     a,[hl] ; a = delta x tiles
    dec     a
    ld      e,a ; e = delta x tiles

    ld      a,[PLANE_Y_TILE+INDEX]
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
        ld      [PLANE_VISIBLE+INDEX],a

        jr      .next\@

.invisible\@:

        ; Invisible

        xor     a,a
        ld      [PLANE_VISIBLE+INDEX],a

.next\@:

        DEF INDEX = INDEX+1
    ENDR

    ret

;-------------------------------------------------------------------------------

PlanesHide:

    xor     a,a
    ld      hl,PLANE_VISIBLE
    ld      b,SIMULATION_MAX_PLANES
    call    memset_fast ; a = value    hl = start address    b = size

    jp      PlanesWriteOAM ; Return from there

;-------------------------------------------------------------------------------

PlaneRefreshSpriteCoordinates: ; bc = index

    ; Calculate tile where the plane is located on the screen.

    ; Sprite screen tile = Plane tile coords - Top left bg coords (= scroll)

    ld      hl,PLANE_X_TILE
    add     hl,bc
    ld      a,[hl]
    ld      hl,bg_x ; bg scroll in tiles
    sub     a,[hl] ; a = delta x tiles
    dec     a ; extra row

    sla     a
    sla     a
    sla     a ; X tile * 8
    ld      hl,PLANE_X_IN_TILE
    add     hl,bc
    add     a,[hl]
    add     a,8 ; A = X sprite coordinate in the screen
    ld      hl,PLANE_X_SPR
    add     hl,bc
    ld      [hl],a

    ld      hl,PLANE_Y_TILE
    add     hl,bc
    ld      a,[hl]
    ld      hl,bg_y ; bg scroll in tiles
    sub     a,[hl] ; a = delta y tiles
    dec     a ; extra column

    sla     a
    sla     a
    sla     a ; Y tile * 8
    ld      hl,PLANE_Y_IN_TILE
    add     hl,bc
    add     a,[hl]
    add     a,16 ; A = Y sprite coordinate in the screen
    ld      hl,PLANE_Y_SPR
    add     hl,bc
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------

PlanesShow:

    ; Recalculate sprite coordinates from bg scroll and plane position.

    ld      bc,SIMULATION_MAX_PLANES-1
.loop:
    dec     c
    push    bc
    call    PlaneRefreshSpriteCoordinates ; bc = index
    pop     bc
    ld      a,c
    and     a,a
    jr      nz,.loop

    ; If the resulting position is inside the screen, flag as visible. If not,
    ; flag as invisible.

    call    PlanesUpdateVisibility

    jp      PlanesWriteOAM ; Return from there

;-------------------------------------------------------------------------------

PlanesCheckOutOfMap:

    DEF INDEX = 0
    REPT    SIMULATION_MAX_PLANES

    ld      a,[PLANE_DIRECTION+INDEX]
    cp      a,-1 ; disabled
    jr      z,.next\@

    ld      a,[PLANE_X_TILE+INDEX] ; 64 rows/columns + 2 extra
    cp      a,66 ; cy = 1 if n > a
    jr      nc,.outside\@

    ld      a,[PLANE_Y_TILE+INDEX]
    cp      a,66 ; cy = 1 if n > a
    jr      nc,.outside\@

        jr      .next\@

.outside\@:

        ld      bc,INDEX
        call    PlaneSpawnBorderOrAirport ; c = index of the plane

.next\@:

        DEF INDEX = INDEX+1
    ENDR

    ret

;-------------------------------------------------------------------------------

PlanesVBLHandle:

    ; For each plane, move it.

    call    PlanesMovementStep

    ; After moving, if it is not visible, flag as invisible.

    call    PlanesUpdateVisibility

    jp      PlanesWriteOAM ; Return from there

;-------------------------------------------------------------------------------

PlanesHandle:

    ; When it leaves the map it should reappear either at the airport or the
    ; edge of the map. If there are no airports then, don't make it reappear.

    call    PlanesCheckOutOfMap

    jp      PlanesWriteOAM ; Return from there

;-------------------------------------------------------------------------------

PlanesHandleScroll: ; d = value to add to y, e = value to add to x

    DEF INDEX = 0
    REPT    SIMULATION_MAX_PLANES
        ld      bc,INDEX
        push    de
        call    PlaneScroll ; bc = index, e = value to add to X, d = add to Y
        pop     de
        DEF INDEX = INDEX+1
    ENDR

    call    PlanesUpdateVisibility

    jp      PlanesWriteOAM ; Return from there

;###############################################################################
