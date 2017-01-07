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

PlaneSpawnCommon: ; bc = index of the plane

    call    GetRandom ; bc, de preserved
    and     a,PLANE_NUM_DIRECTIONS-1
    ld      hl,PLANE_DIRECTION
    add     hl,bc
    ld      [hl],a ; By setting a direction the plane is enabled as well.

    ; Clear variables...

    xor     a,a

    ld      hl,PLANE_X_IN_TILE
    add     hl,bc
    ld      [hl],a

    ld      hl,PLANE_Y_IN_TILE
    add     hl,bc
    ld      [hl],a

    ld      hl,PLANE_VISIBLE
    add     hl,bc ; set as invisible so that the OAM coordinates are refreshed
    ld      [hl],0 ; later

    call    PlaneRefreshSpriteCoordinates ; bc = index

    ret

;-------------------------------------------------------------------------------

; Spawn one plane in the border of the map or next to the airport (right after
; another plane disappears)
PlaneSpawnBorderOrAirport: ; c = index of the plane

    jr      PlaneSpawnAllMap ; TODO - Remove

    ; TODO - Coordinates

    jr      PlaneSpawnCommon ; return from there

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
PlanesReset:

    ; Disable all planes

    ld      a,-1
    ld      hl,PLANE_DIRECTION
    ld      b,SIMULATION_MAX_PLANES
    call    memset_fast ; a = value    hl = start address    b = size

    ; Count the number of airports. The total number of planes is equal to the
    ; number of airports * 2 up to a max of SIMULATION_MAX_PLANES.

    ld      c,0 ; number of airports

    ld      hl,CITY_MAP_TILES

.loop:
    push    hl

        ; Returns: - Tile -> Register DE
        call    CityMapGetTileAtAddress ; Arg: hl = address. Preserves BC, HL

        ld      a,(T_AIRPORT+0)&$FF
        cp      a,e
        jr      nz,.next
        ld      a,(T_AIRPORT+0)>>8
        cp      a,d
        jr      nz,.next

            inc     c
            inc     c
            ld      a,SIMULATION_MAX_PLANES
            cp      a,c
            jr      nz,.next
                pop     hl
                jr      .endloop
.next:

    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

.endloop: ; C holds the number of airports (up to SIMULATION_MAX_PLANES)

    ; Initialize planes to any point in the map

    ld      a,c
    and     a,a
    ret     z ; check if c = 0

.add_plane:
    dec     c
    push    bc
    call    PlaneSpawnAllMap
    pop     bc
    ld      a,c
    and     a,a
    jr      nz,.add_plane

    ret

;-------------------------------------------------------------------------------

PlanesWriteOAM:

    ; For each visible sprite, write the coordinates to the shadow OAM. For
    ; the rest, hide them.

    ld      hl,OAM_Copy+PLANE_SPR_OAM_BASE*4

INDEX SET 0
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

INDEX SET INDEX+1
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

INDEX SET 0
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

INDEX SET INDEX+1
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
    dec     a

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
    dec     a

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

INDEX SET 0
    REPT    SIMULATION_MAX_PLANES

    ld      a,[PLANE_DIRECTION+INDEX]
    cp      a,-1 ; disabled
    jr      z,.next\@

    ld      a,[PLANE_X_TILE+INDEX]
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

INDEX SET INDEX+1
    ENDR

    ret

;-------------------------------------------------------------------------------

PlanesHandle:

    ; For each plane, move it.

    call    PlanesMovementStep

    ; After moving, if it is not visible, flag as invisible.

    call    PlanesUpdateVisibility

    ; When it leaves the map it should reappear either at the airport or the
    ; edge of the map. If there are no airports then, don't make it reappear.

    call    PlanesCheckOutOfMap

    jp      PlanesWriteOAM ; Return from there

;-------------------------------------------------------------------------------

PlanesHandleScroll: ; d = value to add to y, e = value to add to x

INDEX SET 0
    REPT    SIMULATION_MAX_PLANES
    ld      bc,INDEX
    push    de
    call    PlaneScroll ; bc = index, e = value to add to X, d = add to Y
    pop     de
INDEX SET INDEX+1
    ENDR

    call    PlanesUpdateVisibility

    jp      PlanesWriteOAM ; Return from there

;###############################################################################
