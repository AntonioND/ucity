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

TrainGetValidRandomDirection: ; hl = address, returns dir in a

    call    GetRandom
    and     a,3

    ret

;-------------------------------------------------------------------------------

TrainSpawn: ; c = index of the plane

    ; Generate a random number between 0 and the number of train tracks

    ld      a,[COUNT_TRAIN_TRACKS+0] ; LSB first
    ld      e,a
    ld      a,[COUNT_TRAIN_TRACKS+1]
    ld      d,a

    or      a,e
    ret     z ; return if there are no train tracks

    push    bc ; (*12) preserve index

    ; Generate num between 0 and de (de not included)
    ; -----------------------------------------------

    ld      a,d
    and     a,a
    jr      .lower_than_256

        ; Higher or equal than 256

        ld      b,d ; b = top num

        ld      a,d
        REPT 7
        sra     e
        or      a,d
        ENDR
        ld      d,a ; d = (first power of 2 > number of tracks) - 1

.loop_rand1:
        call    GetRandom ; bc, de preserved
        and     a,d ; reduce the number to make this easier
        cp      a,b ; cy = 1 if b > a
        jr      nc,.loop_rand1

        ld      d,a
        call    GetRandom ; bc, de preserved
        ld      e,a

        jr      .end_rand_gen

.lower_than_256:

        ; Lower than 256

        ld      b,e ; b = top num

        ld      a,e
        REPT 7
        sra     e
        or      a,e
        ENDR
        ld      e,a ; e = (first power of 2 > number of tracks) - 1

.loop_rand2:
        call    GetRandom ; bc, de preserved
        and     a,e ; reduce the number to make this easier
        cp      a,b ; cy = 1 if b > a
        jr      nc,.loop_rand2

        ld      e,a
        ld      d,0

.end_rand_gen:

    ; de = number of the train track to spawn the train at

    ld      hl,CITY_MAP_TILES

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

.loop2:

        ld      a,[hl+]
        and     a,TYPE_HAS_TRAIN
        jr      z,.skip_train
            dec     de
            ld      a,d
            or      a,e
            jr      nz,.skip_train
                dec     hl
                jr      .spawn

.skip_train:

    bit     5,h ; Up to E000
    jr      z,.loop2

    ; Track not found! This means that the number of train tracks in the cached
    ; count variable is outdated...
    ld      b,b
    pop     bc ; (*1) restore index
    ret

.spawn:

    push    hl
    call    CityMapAddrToCoords ; address = hl, returns d = y, e = x
    pop     hl

    push    de
    call    TrainGetValidRandomDirection ; hl = address, returns dir in a
    pop     de

    pop     bc ; (*2) restore index

    ld      hl,TRAIN_DIRECTION
    add     hl,bc
    ld      [hl],a ; Set direction and enable

    ld      hl,TRAIN_X_TILE
    add     hl,bc
    ld      [hl],e

    ld      hl,TRAIN_Y_TILE
    add     hl,bc
    ld      [hl],d

    ld      hl,TRAIN_X_IN_TILE
    add     hl,bc
    ld      [hl],0

    ld      hl,TRAIN_Y_IN_TILE
    add     hl,bc
    ld      [hl],0

    ; Clear variables...

    xor     a,a

    ld      hl,TRAIN_VISIBLE
    add     hl,bc  ; Set as invisible so that the OAM coordinates are refreshed
    ld      [hl],0 ; later.

    jp      TrainRefreshSpriteCoordinates ; bc = index, return from there

;-------------------------------------------------------------------------------

; Move sprite on the screen, but object coordinates in the map aren't changed.
; Preserves bc
TrainScroll: ; bc = index, e = value to add to X, d = value to add to Y

    ld      hl,TRAIN_X_SPR
    add     hl,bc
    ld      a,[hl]
    add     a,e
    ld      [hl],a

    ld      hl,TRAIN_Y_SPR
    add     hl,bc
    ld      a,[hl]
    add     a,d
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------

; Move sprite on the screen and update object coordinates in the map.
; Preserves bc
TrainMove: ; bc = index, e = value to add to X, d = value to add to Y

    ld      hl,TRAIN_X_SPR
    add     hl,bc
    ld      a,[hl]
    add     a,e
    ld      [hl],a

    ld      hl,TRAIN_Y_SPR
    add     hl,bc
    ld      a,[hl]
    add     a,d
    ld      [hl],a

    ld      hl,TRAIN_X_IN_TILE
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
    ld      hl,TRAIN_X_TILE
    add     hl,bc
    add     a,[hl]
    ld      [hl],a

    ld      hl,TRAIN_Y_IN_TILE
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
    ld      hl,TRAIN_Y_TILE
    add     hl,bc
    add     a,[hl]
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------

TrainsMovementStep:

    ld      bc,SIMULATION_MAX_TRAINS-1
.loop:

        ld      hl,TRAIN_DIRECTION
        add     hl,bc
        ld      a,[hl]
        cp      a,-1 ; disabled
        jr      z,.skip

        ld      hl,TRAIN_DIRECTION
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
        call    TrainMove ; bc = index, e = value to add to X, d = add to Y

.skip:

    ld      a,c
    dec     c
    and     a,a
    jr      nz,.loop

    ret

.dir_increment: ; x inc, y inc
    DB  0, -1 ; 0 - Top
    DB  1,  0 ; 2 - Right
    DB  0,  1 ; 4 - Down
    DB -1,  0 ; 6 - Left

;-------------------------------------------------------------------------------

; Initialize sprites, find starting coordinates for trains, etc.
TrainsReset: ; a = 1 to force reset, a = 0 reset only if num of trains changes

    ld      d,a ; d = force or not

    ; Calculate number of trains from number of train tracks
    ld      a,[COUNT_TRAIN_TRACKS+0] ; LSB first
    ld      l,a
    ld      a,[COUNT_TRAIN_TRACKS+1]
    ld      h,a

    add     hl,hl
    add     hl,hl
    add     hl,hl
    ld      a,h ; a = (count << 3) >> 8 = count >> 5 = count / 32
    cp      a,SIMULATION_MAX_TRAINS ; cy = 1 if n > a
    jr      c,.not_max
    ld      a,SIMULATION_MAX_TRAINS
.not_max:
    ld      b,a ; b = number of expected trains

    ; if number of trains is the same, return
    ld      a,[OLD_NUM_TRAINS]
    ld      c,a ; c = old number of trains

    ld      a,b
    ld      [OLD_NUM_TRAINS],a ; update number

    ld      a,d
    and     a,a
    jr      nz,.force_reset

    ld      a,b
    cp      a,c
    ret     z ; return if both numbers are equal

    ; Skip reset of all trains, only the ones that are enabled now are reseted
    jr      .reset_common

.force_reset:

    ; Disable all trains so that all visible trains will be reseted

    ld      a,-1
    ld      hl,TRAIN_DIRECTION
    ld      b,SIMULATION_MAX_TRAINS
    call    memset_fast ; a = value    hl = start address    b = size

.reset_common:

    ; Initialize trains to any point in the map

    ld      bc,0 ; c = counter variable for the next two loops

    ld      a,[OLD_NUM_TRAINS]
    and     a,a
    jr      z,.skip_all_spawn ; check if number = 0

.spawn_train:
    push    af ; save top num
        ld      hl,TRAIN_DIRECTION
        add     hl,bc
        ld      a,[hl]
        cp      a,-1 ; If disabled, enable
        jr      nz,.skip_spawn
            push    bc
            call    TrainSpawn
            pop     bc
.skip_spawn:
    pop     af
    inc     c
    cp      a,c
    jr      nz,.spawn_train

.skip_all_spawn:
    ; Disable the rest of the trains

    cp      a,SIMULATION_MAX_TRAINS
    ret     z

    ; bc is still the counter variable
    ld      d,-1 ; disable value
    ld      a,SIMULATION_MAX_TRAINS ; limit
.disable_train:
    ld      hl,TRAIN_DIRECTION
    add     hl,bc
    ld      [hl],d
    inc     c
    cp      a,c
    jr      nz,.disable_train

    ret

;-------------------------------------------------------------------------------

TrainsWriteOAM:

    ; For each visible sprite, write the coordinates to the shadow OAM. For
    ; the rest, hide them.

    ld      hl,OAM_Copy+TRAIN_SPR_OAM_BASE*4

INDEX SET 0
    REPT    SIMULATION_MAX_TRAINS

    ld      a,[TRAIN_DIRECTION+INDEX]
    cp      a,-1 ; disabled
    jr      z,.invisible\@

    ld      a,[TRAIN_VISIBLE+INDEX]
    and     a,a
    jr      z,.invisible\@

        ; Visible

        ld      a,[TRAIN_Y_SPR+INDEX]
        ld      [hl+],a
        ld      a,[TRAIN_X_SPR+INDEX]
        ld      [hl+],a

        LD_BC_HL

        ; Check direction and change tile and flip flags

        ld      de,.tile_attr_data
        ld      a,[TRAIN_DIRECTION+INDEX]
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
    DB  TRAIN_SPRITE_TILE_START+1, 1
    DB  TRAIN_SPRITE_TILE_START+0, 1
    DB  TRAIN_SPRITE_TILE_START+1, 1|OAMF_XFLIP
    DB  TRAIN_SPRITE_TILE_START+0, 1|OAMF_YFLIP

;-------------------------------------------------------------------------------

TrainsUpdateVisibility:

INDEX SET 0
    REPT    SIMULATION_MAX_TRAINS

    ld      a,[TRAIN_DIRECTION+INDEX]
    cp      a,-1 ; disabled
    jr      z,.invisible\@

    ; Calculate tile where the plane is located on the screen.

    ; Sprite screen tile = Train tile coords - Top left bg coords (= scroll)

    ld      a,[TRAIN_X_TILE+INDEX]
    ld      hl,bg_x ; bg scroll in tiles
    sub     a,[hl] ; a = delta x tiles
    ;dec     a ; TODO CHECK
    ld      e,a ; e = delta x tiles

    ld      a,[TRAIN_Y_TILE+INDEX]
    ld      hl,bg_y ; bg scroll in tiles
    sub     a,[hl] ; a = delta y tiles
    ;dec     a ; TODO CHECK
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
        ld      [TRAIN_VISIBLE+INDEX],a

        jr      .next\@

.invisible\@:

        ; Invisible

        xor     a,a
        ld      [TRAIN_VISIBLE+INDEX],a

.next\@:

INDEX SET INDEX+1
    ENDR

    ret

;-------------------------------------------------------------------------------

TrainsHide:

    xor     a,a
    ld      hl,TRAIN_VISIBLE
    ld      b,SIMULATION_MAX_TRAINS
    call    memset_fast ; a = value    hl = start address    b = size

    jp      TrainsWriteOAM ; Return from there

;-------------------------------------------------------------------------------

TrainRefreshSpriteCoordinates: ; bc = index

    ; Calculate tile where the train is located on the screen.

    ; Sprite screen tile = Train tile coords - Top left bg coords (= scroll)

    ld      hl,TRAIN_X_TILE
    add     hl,bc
    ld      a,[hl]
    ld      hl,bg_x ; bg scroll in tiles
    sub     a,[hl] ; a = delta x tiles

    sla     a
    sla     a
    sla     a ; X tile * 8
    ld      hl,TRAIN_X_IN_TILE
    add     hl,bc
    add     a,[hl]
    add     a,8 ; A = X sprite coordinate in the screen
    ld      hl,TRAIN_X_SPR
    add     hl,bc
    ld      [hl],a

    ld      hl,TRAIN_Y_TILE
    add     hl,bc
    ld      a,[hl]
    ld      hl,bg_y ; bg scroll in tiles
    sub     a,[hl] ; a = delta y tiles

    sla     a
    sla     a
    sla     a ; Y tile * 8
    ld      hl,TRAIN_Y_IN_TILE
    add     hl,bc
    add     a,[hl]
    add     a,16 ; A = Y sprite coordinate in the screen
    ld      hl,TRAIN_Y_SPR
    add     hl,bc
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------

TrainsShow:

    ; Recalculate sprite coordinates from bg scroll and train position.

    ld      bc,SIMULATION_MAX_TRAINS-1
.loop:
    dec     c
    push    bc
    call    TrainRefreshSpriteCoordinates ; bc = index
    pop     bc
    ld      a,c
    and     a,a
    jr      nz,.loop

    ; If the resulting position is inside the screen, flag as visible. If not,
    ; flag as invisible.

    call    TrainsUpdateVisibility

    jp      TrainsWriteOAM ; Return from there

;-------------------------------------------------------------------------------

TrainsCheckOutOfTrack:

INDEX SET 0
    REPT    SIMULATION_MAX_TRAINS

    ld      a,[TRAIN_DIRECTION+INDEX]
    cp      a,-1 ; disabled
    jr      z,.next\@

    ld      a,[TRAIN_X_TILE+INDEX]
    cp      a,64 ; cy = 1 if n > a
    jr      nc,.outside\@

    ld      a,[TRAIN_Y_TILE+INDEX]
    cp      a,64 ; cy = 1 if n > a
    jr      nc,.outside\@

        jr      .next\@

.outside\@:

        ld      bc,INDEX
        call    TrainSpawn ; c = index of the train

.next\@:

INDEX SET INDEX+1
    ENDR

    ret

;-------------------------------------------------------------------------------

TrainsVBLHandle:

    ; For each train, move it.

    call    TrainsMovementStep

    ; After moving, if it is not visible, flag as invisible.

    call    TrainsUpdateVisibility

    jp      TrainsWriteOAM ; Return from there

;-------------------------------------------------------------------------------

TrainsHandle:

    ; When a train realizes that there are no tracks under it, unspawn and try
    ; to respawn somewhere else. If there are tracks, move and change directions
    ; if needed. This means that, in practice, trains are only removed when the
    ; tracks under them are demolished.

    call    TrainsCheckOutOfTrack

    jp      TrainsWriteOAM ; Return from there

;-------------------------------------------------------------------------------

TrainsHandleScroll: ; d = value to add to y, e = value to add to x

INDEX SET 0
    REPT    SIMULATION_MAX_TRAINS
    ld      bc,INDEX
    push    de
    call    TrainScroll ; bc = index, e = value to add to X, d = add to Y
    pop     de
INDEX SET INDEX+1
    ENDR

    call    TrainsUpdateVisibility

    jp      TrainsWriteOAM ; Return from there

;###############################################################################
