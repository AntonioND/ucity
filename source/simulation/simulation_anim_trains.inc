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

TrainGetValidRandomDirection: ; d=y,e=x, b=prohibited dir (or -1), returns a=dir

    ; Convert direction into flag

    ld      a,b
    cp      a,-1
    jr      nz,.skipminus1
        ld      b,0
        jr      .end_convert_dir
.skipminus1:
    cp      a,0
    jr      nz,.skip0
        ld      b,PAD_UP
        jr      .end_convert_dir
.skip0:
    cp      a,1
    jr      nz,.skip1
        ld      b,PAD_RIGHT
        jr      .end_convert_dir
.skip1:
    cp      a,2
    jr      nz,.skip2
        ld      b,PAD_DOWN
        jr      .end_convert_dir
.skip2:
    cp      a,3
    jr      nz,.skip3
        ld      b,PAD_LEFT
        jr      .end_convert_dir
.skip3:

.end_convert_dir:

    ; Get allowed directions

    push    bc
    call    CityMapGetTile ; Arguments: e = x , d = y, returns tile in de
    pop     bc

    ld      a,e
    sub     a,T_TRAIN_TB ; Base of the array
    ld      e,a
    ; Assert that this is a valid train tile!
    cp      a,T_TRAIN_LR_BRIDGE-T_TRAIN_TB+1 ; cy = 1 if n > a
    ld      a,0
    ret     nc
    ld      hl,.allowed_directions
    add     hl,de
    ld      c,[hl] ; c = possible dirs
    ; b = user-prohibited dirs

    ld      a,b
    cpl ; a = user-allowed dirs
    and     a,c
    ld      b,a ; b = possible dirs - prohibited dirs

    ; Try to get just one direction

.loop_rand:
    ; b = possible dirs
    call    GetRandom ; bc, de preserved
    and     a,b ; a = random flags, let's check if there is one or more

    ld      d,a ; d = flags, to preserve them

    ld      c,0

    bit     0,a
    jr      z,.not_0
    inc     c
.not_0:
    bit     1,a
    jr      z,.not_1
    inc     c
.not_1:
    bit     2,a
    jr      z,.not_2
    inc     c
.not_2:
    bit     3,a
    jr      z,.not_3
    inc     c
.not_3:

    ld      a,c
    cp      a,1
    jr      nz,.loop_rand

    ld      a,d ; a = result flag

    ; Convert flag into train direction

    cp      a,PAD_UP
    jr      nz,.not_up
        ld      a,0
        ret
.not_up:
    cp      a,PAD_RIGHT
    jr      nz,.not_right
        ld      a,1
        ret
.not_right:
    cp      a,PAD_DOWN
    jr      nz,.not_down
        ld      a,2
        ret
.not_down:
    ;cp      a,PAD_LEFT
    ;jr      nz,.not_left
        ld      a,3
        ret
;.not_left:
;    ret

.allowed_directions:
    DB  PAD_UP|PAD_DOWN     ; T_TRAIN_TB
    DB  PAD_LEFT|PAD_RIGHT  ; T_TRAIN_LR
    DB  PAD_RIGHT|PAD_DOWN  ; T_TRAIN_RB
    DB  PAD_LEFT|PAD_DOWN   ; T_TRAIN_LB
    DB  PAD_UP|PAD_RIGHT    ; T_TRAIN_TR
    DB  PAD_UP|PAD_LEFT     ; T_TRAIN_TL
    DB  PAD_UP|PAD_RIGHT|PAD_DOWN   ; T_TRAIN_TRB
    DB  PAD_LEFT|PAD_RIGHT|PAD_DOWN ; T_TRAIN_LRB
    DB  PAD_UP|PAD_LEFT|PAD_DOWN    ; T_TRAIN_TLB
    DB  PAD_UP|PAD_RIGHT|PAD_LEFT   ; T_TRAIN_TLR
    DB  PAD_UP|PAD_RIGHT|PAD_DOWN|PAD_LEFT  ; T_TRAIN_TLRB
    DB  PAD_LEFT|PAD_RIGHT  ; T_TRAIN_LR_ROAD
    DB  PAD_UP|PAD_DOWN     ; T_TRAIN_TB_ROAD
    DB  PAD_UP|PAD_DOWN     ; T_TRAIN_TB_POWER_LINES
    DB  PAD_LEFT|PAD_RIGHT  ; T_TRAIN_LR_POWER_LINES
    DB  PAD_UP|PAD_DOWN     ; T_TRAIN_TB_BRIDGE
    DB  PAD_LEFT|PAD_RIGHT  ; T_TRAIN_LR_BRIDGE

;-------------------------------------------------------------------------------

TrainIsCenteredInTile: ; bc = train index, returns a=1 if centered, 0 if not

    ld      hl,TRAIN_X_IN_TILE
    add     hl,bc
    ld      a,[hl]

    ld      hl,TRAIN_Y_IN_TILE
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

TrainHasNextTileTrack: ; bc = train index, returns a = 1 if it has train else 0

    ld      hl,TRAIN_X_TILE
    add     hl,bc
    ld      e,[hl]

    ld      hl,TRAIN_Y_TILE
    add     hl,bc
    ld      d,[hl]

    ld      hl,TRAIN_DIRECTION
    add     hl,bc
    ld      c,[hl]
    ld      b,0
    ld      hl,.dir_increment
    add     hl,bc
    add     hl,bc

    ld      a,[hl+]
    add     a,e
    ld      e,a
    ld      a,[hl]
    add     a,d
    ld      d,a

    call    CityMapGetType ; Arguments: e = x , d = y, returns type in a
    and     a,TYPE_HAS_TRAIN
    ret     z

    ld      a,1
    ret

.dir_increment: ; x inc, y inc
    DB  0, -1 ; 0 - Top
    DB  1,  0 ; 1 - Right
    DB  0,  1 ; 2 - Down
    DB -1,  0 ; 3 - Left

;-------------------------------------------------------------------------------

TrainHasThisTileTrack: ; bc = train index, returns a = 1 if it has train else 0

    ld      hl,TRAIN_X_TILE
    add     hl,bc
    ld      e,[hl]

    ld      hl,TRAIN_Y_TILE
    add     hl,bc
    ld      d,[hl]

    call    CityMapGetType ; Arguments: e = x , d = y, returns type in a
    and     a,TYPE_HAS_TRAIN
    ret     z

    ld      a,1
    ret

.dir_increment: ; x inc, y inc
    DB  0, -1 ; 0 - Top
    DB  1,  0 ; 1 - Right
    DB  0,  1 ; 2 - Down
    DB -1,  0 ; 3 - Left

;-------------------------------------------------------------------------------

TrainCurrentTrackNumDirections: ; bc = train index. returns a = number

    ld      hl,TRAIN_X_TILE
    add     hl,bc
    ld      e,[hl]

    ld      hl,TRAIN_Y_TILE
    add     hl,bc
    ld      d,[hl]

    call    CityMapGetTile ; Arguments: e = x , d = y, returns tile in de

    ld      a,e
    sub     a,T_TRAIN_TB ; Base of the array
    ; Assert that this is a valid train tile!
    cp      a,T_TRAIN_LR_BRIDGE-T_TRAIN_TB+1 ; cy = 1 if n > a
    jr      c,.ok
    ld      a,0
    ret
.ok:
    ld      e,a
    ld      hl,.num_allowed_directions
    add     hl,de
    ld      a,[hl] ; a = num possible dirs

    ret

.num_allowed_directions:
    DB  2 ; T_TRAIN_TB
    DB  2 ; T_TRAIN_LR
    DB  2 ; T_TRAIN_RB
    DB  2 ; T_TRAIN_LB
    DB  2 ; T_TRAIN_TR
    DB  2 ; T_TRAIN_TL
    DB  3 ; T_TRAIN_TRB
    DB  3 ; T_TRAIN_LRB
    DB  3 ; T_TRAIN_TLB
    DB  3 ; T_TRAIN_TLR
    DB  4 ; T_TRAIN_TLRB
    DB  2 ; T_TRAIN_LR_ROAD
    DB  2 ; T_TRAIN_TB_ROAD
    DB  2 ; T_TRAIN_TB_POWER_LINES
    DB  2 ; T_TRAIN_LR_POWER_LINES
    DB  2 ; T_TRAIN_TB_BRIDGE
    DB  2 ; T_TRAIN_LR_BRIDGE

;-------------------------------------------------------------------------------

TrainGenRandomMax16: ; de = max number (excluded), must be greater than 0

    ; The idea is to generate random numbers until one of them is lower than
    ; the provided value. To speed up things, a mask is created to clamp the
    ; generated numbers. This way, the worst case is that half of the generated
    ; numbers have to be discarded. If not, a number like $100 would take
    ; forever because there's only 1 chance in 256 to generate a smaller number
    ; in the high byte.

    LD_BC_DE
    LD_HL_DE

    ; bc = shift register
    ; hl = register to generate bitmask at
    REPT    16
    ; bc = bc | (bc >> 1)
    sra     b
    rr      c ; bc >>= 1
    ; bc |= hl
    ld      a,h
    or      a,b
    ld      h,a
    ld      a,l
    or      a,c
    ld      l,a
    ENDR
    LD_BC_HL

    ; bc = first (power of 2 - 1) greater or equal than de
    ; de = max number
.loop_rand:

    call    GetRandom ; bc, de preserved
    push    af
    call    GetRandom ; bc, de preserved
    ld      l,a
    pop     af
    ld      h,a ; hl = random number

    ; hl = rand & mask
    ld      a,b
    and     a,h
    ld      h,a

    ld      a,c
    and     a,l
    ld      l,a

    ; if hl < de (rand < max) return hl

    ld      a,h
    cp      a,d ; cy = 1 if d > a
    jr      z,.check_low_byte
    jr      nc,.loop_rand
    jr      .loop_rand_end

.check_low_byte:
    ; Top 8 bit are equal, check lower 8 bit

    ld      a,l
    cp      a,e ; cy = 1 if e > a
    jr      nc,.loop_rand
    ;jr      .loop_rand_end

.loop_rand_end:

    LD_DE_HL

    ret

;-------------------------------------------------------------------------------

TrainSpawn: ; c = index of the train

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

    ; Get a random number in de
    call    TrainGenRandomMax16 ; de = max number (excluded), must be > 0

    ; de = number of the train track to spawn the train at (0 to num-1)

    ld      hl,CITY_MAP_TILES

    ld      a,BANK_CITY_MAP_TYPE
    ldh     [rSVBK],a

.loop2:

        ld      a,[hl+]
        and     a,TYPE_HAS_TRAIN
        jr      z,.skip_tile
            ld      a,d ; If DE is 0 this is the tile to spawn at.
            or      a,e
            jr      nz,.skip_spawn
                dec     hl ; HL was post-incremented when reading from it
                jr      .spawn
.skip_spawn:
            dec     de ; try again
.skip_tile:

    bit     5,h ; Up to E000
    jr      z,.loop2

    ; Track not found! This means that the number of train tracks in the cached
    ; count variable is outdated...
    ld      b,b
    pop     bc ; (*1) restore index
    ret

.spawn:

    call    CityMapAddrToCoords ; address = hl, returns d = y, e = x

    push    de
    ; d=y,e=x, b=prohibited dir (or -1), returns a=dir
    ld      b,-1
    call    TrainGetValidRandomDirection
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
    DB  1,  0 ; 1 - Right
    DB  0,  1 ; 2 - Down
    DB -1,  0 ; 3 - Left

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
    ld      a,h ; a = (count << 2) >> 8 = count >> 6 = count / 64
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

    DEF INDEX = 0
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

        DEF INDEX = INDEX+1
    ENDR

    ret

.tile_attr_data:
    DB  TRAIN_SPRITE_TILE_START+1, 1
    DB  TRAIN_SPRITE_TILE_START+0, 1
    DB  TRAIN_SPRITE_TILE_START+1, 1|OAMF_YFLIP
    DB  TRAIN_SPRITE_TILE_START+0, 1|OAMF_XFLIP

;-------------------------------------------------------------------------------

TrainsUpdateVisibility:

    DEF INDEX = 0
    REPT    SIMULATION_MAX_TRAINS

    ld      a,[TRAIN_DIRECTION+INDEX]
    cp      a,-1 ; disabled
    jr      z,.invisible\@

    ; Calculate tile where the train is located on the screen.

    ; Sprite screen tile = Train tile coords - Top left bg coords (= scroll)

    ld      a,[TRAIN_X_TILE+INDEX]
    ld      hl,bg_x ; bg scroll in tiles
    sub     a,[hl] ; a = delta x tiles
    ld      e,a ; e = delta x tiles

    ld      a,[TRAIN_Y_TILE+INDEX]
    ld      hl,bg_y ; bg scroll in tiles
    sub     a,[hl] ; a = delta y tiles
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

        DEF INDEX = INDEX+1
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

    DEF INDEX = 0
    REPT    SIMULATION_MAX_TRAINS

    ld      a,[TRAIN_DIRECTION+INDEX]
    cp      a,-1 ; disabled
    jr      z,.next\@

    ld      bc,INDEX
    call    TrainHasThisTileTrack ; bc = index, returns a = 1 if it has train
    and     a,a
    jr      z,.outside\@

    ld      a,[TRAIN_X_TILE+INDEX]
    cp      a,64 ; cy = 1 if n > a
    jr      nc,.outside\@

    ld      a,[TRAIN_Y_TILE+INDEX]
    cp      a,64 ; cy = 1 if n > a
    jr      nc,.outside\@

    jr      .inside\@

.outside\@:

        ld      bc,INDEX
        call    TrainSpawn ; c = index of the train
        jr      .next\@

.inside\@:

    ld      bc,INDEX
    call    TrainIsCenteredInTile ; bc = index, returns a=1 if centered else 0
    and     a,a
    jr      z,.dont_change_dir\@

        ; Try to change direction

        ld      bc,INDEX
        call    TrainHasNextTileTrack ; bc = index, returns a = 1 if it has
        and     a,a
        jr      z,.change_dir\@

        ld      bc,INDEX
        call    TrainCurrentTrackNumDirections ; bc = index. returns a = number
        cp      a,2
        jr      z,.dont_change_dir\@
        cp      a,0
        jr      z,.dont_change_dir\@

.change_dir\@:

        ld      a,[TRAIN_DIRECTION+INDEX]
        add     a,2
        and     a,TRAIN_NUM_DIRECTIONS-1
        ld      b,a ; get opposite direction
        ld      a,[TRAIN_X_TILE+INDEX]
        ld      e,a
        ld      a,[TRAIN_Y_TILE+INDEX]
        ld      d,a
        ; d=y,e=x, b=prohibited dir (or -1), returns a=dir
        call    TrainGetValidRandomDirection
        ld      [TRAIN_DIRECTION+INDEX],a

        ld      bc,INDEX
        call    TrainRefreshSpriteCoordinates ; bc = index

.dont_change_dir\@:

.next\@:

        DEF INDEX = INDEX+1
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

    ; This function may be called after a few updates of the coordinates of the
    ; trains. If that happens, it may be possible that a train doesn't turn at
    ; a corner and leaves the train tracks. This is ok, it will just dissapear
    ; and appear somewhere else.

    call    TrainsCheckOutOfTrack

    jp      TrainsWriteOAM ; Return from there

;-------------------------------------------------------------------------------

TrainsHandleScroll: ; d = value to add to y, e = value to add to x

    DEF INDEX = 0
    REPT    SIMULATION_MAX_TRAINS
        ld      bc,INDEX
        push    de
        call    TrainScroll ; bc = index, e = value to add to X, d = add to Y
        pop     de
        DEF INDEX = INDEX+1
    ENDR

    call    TrainsUpdateVisibility

    jp      TrainsWriteOAM ; Return from there

;###############################################################################
