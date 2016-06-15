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
    INCLUDE "building_info.inc"

;###############################################################################

    SECTION "Simulation Create Buildings Functions",ROMX

;-------------------------------------------------------------------------------

; Flags: Power | Services | Education | Pollution | Traffic
FPOW EQU TILE_OK_POWER
FSER EQU TILE_OK_SERVICES
FEDU EQU TILE_OK_EDUCATION
FPOL EQU TILE_OK_POLLUTION
FTRA EQU TILE_OK_TRAFFIC

; The needed flags must be a subset of the desired ones

; TYPE_RESIDENTIAL
R_NEEDED  EQU FPOW|FPOL|FTRA
R_DESIRED EQU FPOW|FSER|FEDU|FPOL|FTRA

; TYPE_COMMERCIAL
C_NEEDED  EQU FPOW|FSER|FPOL|FTRA
C_DESIRED EQU FPOW|FPOL|FTRA

; TYPE_INDUSTRIAL
I_NEEDED  EQU FPOW|FSER|FTRA
I_DESIRED EQU FPOW|FTRA

; Flags are only calculated for RCI zones!
Simulation_FlagCreateBuildings::

    ld      hl,CITY_MAP_TILES

.loop:
    push    hl

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

        ld      b,[hl]
        ld      a,BANK_CITY_MAP_FLAGS
        ld      [rSVBK],a
        ld      a,b

        cp      a,TYPE_RESIDENTIAL
        jr      nz,.not_residential

            ; Residential
            ld      a,[hl]
            and     a,R_DESIRED
            cp      a,R_DESIRED
            jr      z,.build ; all desired flags ok
            and     a,R_NEEDED
            cp      a,R_NEEDED
            jr      z,.clear ; at least we have the needed ones...
            jr      .demolish ; not even that...

.not_residential:
        cp      a,TYPE_COMMERCIAL
        jr      nz,.not_commercial

            ; Commercial
            ld      a,[hl]
            and     a,C_DESIRED
            cp      a,C_DESIRED
            jr      z,.build ; all desired flags ok
            and     a,C_NEEDED
            cp      a,C_NEEDED
            jr      z,.clear ; at least we have the needed ones...
            jr      .demolish ; not even that...

.not_commercial:
        cp      a,TYPE_INDUSTRIAL
        jr      nz,.not_industrial

            ; Industrial
            ld      a,[hl]
            and     a,I_DESIRED
            cp      a,I_DESIRED
            jr      z,.build ; all desired flags ok
            and     a,I_NEEDED
            cp      a,I_NEEDED
            jr      z,.clear ; at least we have the needed ones...
            jr      .demolish ; not even that...

.not_industrial:
        ; Not a RCI tile
        jr      .clear

.build:
        set     TILE_BUILD_REQUESTED_BIT,[hl]
        res     TILE_DEMOLISH_REQUESTED_BIT,[hl]
        jr      .end
.demolish:
        res     TILE_BUILD_REQUESTED_BIT,[hl]
        set     TILE_DEMOLISH_REQUESTED_BIT,[hl]
        jr      .end
.clear:
        res     TILE_BUILD_REQUESTED_BIT,[hl]
        res     TILE_DEMOLISH_REQUESTED_BIT,[hl]
        ;jr      .end
.end:

    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

;-------------------------------------------------------------------------------

; Try to build a building as big as possible.

; coords = bc
; tile = de | only the low byte is needed because d should be 0 from the caller
; address = hl
Simulation_CreateBuildingsTryBuild::

    ; The tiles to test are arranged like this (0 is the origin):

    ; 0 1 2
    ; 3 4 5
    ; 6 7 8

    ; Check if all tiles are the same tile as register DE and if they are
    ; flagged to build. D is 0, so we only need to make sure that each other
    ; tile is < 256 and if E is the same as the lower byte. Any tile outside
    ; the map makes the function to fail.

    ; 1. Set size to 3x3.
    ; 2a. Check coordinates to see if 3x3 fits.
    ; 2b. Check 8, 7, 5, 6, 2. If any of them fails, fall back to 2x2.
    ; 3a. Check coordinates to see if 2x2 fits.
    ; 3b. Check 4, 3, 1. If they fail, fall back to 1x1.
    ; 4. Build building.

    add     sp,-1
    ld      hl,sp+0
    ld      [hl],e ; (*) save tile into stack

    LD_DE_BC

    ; [sp+0] = low byte of tile (high byte should be 0)
    ; d = y, e = x
    ; hl = address

    ; 2a. Check coordinates to see if 3x3 fits

    ld      a,61
    cp      a,d ; carry flag is set if d > a (62 or 63)
    jp      c,.check2x2
    ld      a,61
    cp      a,e ; carry flag is set if d > a (62 or 63)
    jp      c,.check2x2

    ; 2b. Check 8, 7, 5, 6, 2. If any of them fails, fall back to 2x2.

START_POS_TEST : MACRO
    push    de
ENDM

END_POS_TEST : MACRO ; 1 = jump here if failed
        call    CityMapGetTileNoBoundCheck ; coords=de, returns tile=de
        LD_BC_DE ; bc = tile
    pop     de

    xor     a,a
    cp      a,b ; high byte should be 0!
    jp      nz,\1

    ld      hl,sp+2
    ld      a,[hl]
    cp      a,c ; low byte should be the same!
    jp      nz,\1
ENDM

    ; d = y, e = x

    START_POS_TEST ; Check 8
        inc     e
        inc     e
        inc     d
        inc     d
    END_POS_TEST    .check2x2

    START_POS_TEST ; Check 7
        inc     e
        inc     d
        inc     d
    END_POS_TEST    .check2x2

    START_POS_TEST ; Check 5
        inc     e
        inc     e
        inc     d
    END_POS_TEST    .check2x2

    START_POS_TEST ; Check 6
        inc     d
        inc     d
    END_POS_TEST    .check2x2

    START_POS_TEST ; Check 2
        inc     e
        inc     e
    END_POS_TEST    .check2x2

    START_POS_TEST ; Check 4
        inc     e
        inc     d
    END_POS_TEST    .check2x2

    START_POS_TEST ; Check 3
        inc     d
    END_POS_TEST    .check2x2

    START_POS_TEST ; Check 1
        inc     e
    END_POS_TEST    .check2x2

    jr      .build3x3

.check2x2:

    ; 3a. Check coordinates to see if 2x2 fits.

    ld      a,62
    cp      a,d ; carry flag is set if d > a (63)
    jp      c,.build1x1
    ld      a,62
    cp      a,e ; carry flag is set if d > a (63)
    jp      c,.build1x1

    ; 3b. Check 4, 3, 1. If they fail, fall back to 1x1.

    START_POS_TEST ; Check 4
        inc     e
        inc     d
    END_POS_TEST    .build1x1

    START_POS_TEST ; Check 3
        inc     d
    END_POS_TEST    .build1x1

    START_POS_TEST ; Check 1
        inc     e
    END_POS_TEST    .build1x1

    ;jr      .build2x2

    ; Get offset
.build2x2:
    ld      b,B_ResidentialS2A - B_ResidentialS1A
    jr      .build_end
.build3x3:
    ld      b,B_ResidentialS3A - B_ResidentialS1A
    jr      .build_end
.build1x1:
    ld      b,B_ResidentialS1A - B_ResidentialS1A
    ;jr      .build_end
.build_end:

    ld      hl,sp+0
    ld      a,[hl]

    add     sp,+1 ; (*) restore stack

    ; a = RCI tile low byte
    ; b = building size offset
    ; de = origin coordinates

    cp      a,T_RESIDENTIAL & $FF
    jr      z,.res
    cp      a,T_COMMERCIAL & $FF
    jr      z,.com
    cp      a,T_INDUSTRIAL & $FF
    jr      z,.ind

    ld      b,b ; Panic!
    ret

.res:
    ld      a,B_ResidentialS1A
    add     a,b
    jr      .build
.com:
    ld      a,B_CommercialS1A
    add     a,b
    jr      .build
.ind:
    ld      a,B_IndustrialS1A
    add     a,b
    ;jr      .build

    ; a = building size + type
.build:

    ld      b,a
    call    GetRandom ; bc and de preserved
    and     a,3
    add     a,b ; randomize building type

    ; TODO - Instead of randomizing, check demand? Maybe not a good idea
    ; because it would reduce the variety.

    ld      b,a
    ; de = origin coordinates
    ; b = building index
    LONG_CALL_ARGS  MapDrawBuildingForcedCoords

    ret

;-------------------------------------------------------------------------------

; After calling Simulation_FlagCreateBuildings and calculating the RCI demand in
; Simulation_CalculateStatistics, create and destroy buildings!

; Don't update VRAM map, let the animation loop do that for us
Simulation_CreateBuildings::

    ; TODO - Actually use the city statistics (RCI demand) to affect the
    ; creation or destruction of buildings

    ; First, create buildings. Then, demolish.

    ; We know that only RCI zones can have a build or demolish flag set. No need
    ; to check the type, only the tile number!

    ; First, build. Make sure that it is a RCI tile!

    ld      hl,CITY_MAP_TILES ; Base address of the map!

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)
        push    hl

IF (T_RESIDENTIAL >= 256) || (T_COMMERCIAL >= 256) || (T_INDUSTRIAL >= 256)
    FAIL "RCI tiles should be in positions lower than 256."
ENDC

            LD_BC_DE ; save coords in bc

            ; Arguments: hl = address. Preserves BC and HL
            ; Returns: de = tile
            call    CityMapGetTileAtAddress

            ; coords = bc
            ; tile = de
            ; address = hl

            ld      a,d
            and     a,a ; High byte should be 0
            jr      nz,.not_type_rci

            ; Low byte should be one of the RCI tiles
            ld      a,e
            cp      a,T_RESIDENTIAL
            jr      z,.type_rci
            cp      a,T_COMMERCIAL
            jr      z,.type_rci
            cp      a,T_INDUSTRIAL
            jr      nz,.not_type_rci

.type_rci:
                ; coords = bc
                ; tile = de
                ; address = hl

                ; This is a RCI flag, check that we got a request to build or
                ; demolish.
                ; - To build, all tiles must be at least ok (none of them can be
                ;   flagged to demolish.
                ; - Demolish if even one single tile is flagged to demolish.

                ld      a,BANK_CITY_MAP_FLAGS
                ld      [rSVBK],a

                ld      a,[hl] ; get flags

                bit     TILE_BUILD_REQUESTED_BIT,a
                jr      z,.not_build

                    ; Try to build

                    ; coords = bc
                    ; tile = de | only the low byte is needed, d is 0
                    ; hl = address
                    call    Simulation_CreateBuildingsTryBuild

                    ; TODO - Try to build even if there are small buildings
                    ; on the way!
.not_build:

.not_type_rci:

        pop     hl
        pop     de ; (*)

        inc     hl

        inc     e
        bit     6,e
        jp      z,.loopx

    inc     d
    bit     6,d
    jp      z,.loopy

    ; Demolish buildings. Make sure that we are not demolishing a RCI tile!

    ld      hl,CITY_MAP_TILES ; Base address of the map!

    ld      d,0 ; d = y
.loopy2:

        ld      e,0 ; e = x
.loopx2:

        push    de ; (*)
        push    hl

IF (T_RESIDENTIAL >= 256) || (T_COMMERCIAL >= 256) || (T_INDUSTRIAL >= 256)
    FAIL "RCI tiles should be in positions lower than 256."
ENDC

            LD_BC_DE ; save coords in bc

            ; Arguments: hl = address. Preserves BC and HL
            ; Returns: de = tile
            call    CityMapGetTileAtAddress

            ; coords = bc
            ; tile = de
            ; address = hl

            ld      a,d
            and     a,a ; If high byte is not 0, not RCI tile
            jr      nz,.demolish

            ; Low byte shouldn't be one of the RCI tiles
            ld      a,e
            cp      a,T_RESIDENTIAL
            jr      z,.dont_demolish
            cp      a,T_COMMERCIAL
            jr      z,.dont_demolish
            cp      a,T_INDUSTRIAL
            jr      z,.dont_demolish

.demolish:
                ld      a,BANK_CITY_MAP_FLAGS
                ld      [rSVBK],a

                ld      a,[hl] ; get flags

                bit     TILE_DEMOLISH_REQUESTED_BIT,a
                jr      z,.dont_demolish

                    ; Demolish building

                    ; coords = bc
                    ; hl = address

                    LD_DE_BC
                    call    MapDeleteBuildingForced

                    ; After demolishing the building all the tiles will be RCI,
                    ; so it is not needed to clear the demolish request flag.
                    ; Only non-RCI tiles with demolish request flag are
                    ; demolished, when demolishing a RCI building the tiles will
                    ; go back to RCI tiles, so they won't be demolished again.

.dont_demolish:

        pop     hl
        pop     de ; (*)

        inc     hl

        inc     e
        bit     6,e
        jp      z,.loopx2

    inc     d
    bit     6,d
    jp      z,.loopy2

    ret

;###############################################################################
