;###############################################################################
;
;    µCity - City building game for Game Boy Color.
;    Copyright (C) 2017 Antonio Niño Díaz (AntonioND/SkyLyrac)
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

; Flags are only calculated for RCI type zones!
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

; The following is used to verify if a building can actually grow in this place
; taking in consideration if there are more buildings on the way.

; Vertical and horizontal flags separated for easier understanding. The result
; is the addition of both sides:

; T T T   L C R
; C C C   L C R
; B B B   L C R

; TC TC   LC RC
; BC BC   LC RC

; TCB     LCR

; In short, SCRATCH_RAM is filled with the flags corresponding to the buildings
; that are already there. If a new building wants to grow on a certaing place,
; all the new tiles have to be checked. If the flags corresponding to each one
; of the new tiles ANDed with the ones that are already on SCRATCH_RAM is not 0
; that means that it's not going to cut another building that was there before.

; Also, it is needed to check if the new building is bigger than the old one,
; as this check only works when the new building is bigger. For this check,
; SCRATCH_RAM_2 is filled with the size of the building (being 0 for RCI tiles,
; 1 for the 1x1 buildings, 2 for 2x2 and 3 for 3x3).

F_TL EQU 1 ; Top left
F_TC EQU 2 ; Top center
F_TR EQU 4 ; Top right
F_CL EQU 8 ; Center left
F_CR EQU 16 ; Center right
F_BL EQU 32 ; Bottom left
F_BC EQU 64 ; Bottom center
F_BR EQU 128 ; Bottom right

F_CC EQU F_TL|F_TC|F_TR|F_CL|F_CR|F_BL|F_BC|F_BR ; Center center

BUILDING1X1FLAGS : MACRO
    DB F_CC ; Center center / All
ENDM

BUILDING2X2FLAGS : MACRO
    DB F_TL|F_TC|F_CL ; Top left
    DB F_TC|F_TR|F_CR ; Top right
    DB F_CL|F_BL|F_BC ; Bottom left
    DB F_CR|F_BC|F_BR ; Bottom right
ENDM

BUILDING3X3FLAGS : MACRO
    DB F_TL ; Top left
    DB F_TC ; Top center
    DB F_TR ; Top right
    DB F_CL ; Center left
    DB F_CC ; Center center
    DB F_CR ; Center right
    DB F_BL ; Bottom left
    DB F_BC ; Bottom center
    DB F_BR ; Bottom right
ENDM

IF T_RESIDENTIAL > T_RESIDENTIAL_S1_A
    FAIL "Fix this!"
ENDC
IF T_RESIDENTIAL_S1_A > T_COMMERCIAL_S1_A
    FAIL "Fix this!"
ENDC
IF T_RESIDENTIAL_S1_A > T_INDUSTRIAL_S1_A
    FAIL "Fix this!"
ENDC

; Gets the flag assigned to a tile
CREATE_BUILDING_FLAGS: ; Input = tile number

    ; RCI Tiles
    DS  T_RESIDENTIAL
    BUILDING1X1FLAGS
    BUILDING1X1FLAGS
    BUILDING1X1FLAGS

    ; Buildings
    DS  T_RESIDENTIAL_S1_A - T_RESIDENTIAL - 3
    REPT 3 ; R C I
        REPT 4
            BUILDING1X1FLAGS
        ENDR
        REPT 4
            BUILDING2X2FLAGS
        ENDR
        REPT 4
        ; Not needed to set flags because this is only used to make buildings
        ; grow on top of this. A 3x3 building can't be replaced by anything,
        ; so save some CPU by setting this to 0 and preventing calculations.
            DB 0,0,0, 0,0,0, 0,0,0
        ;    BUILDING3X3FLAGS
        ENDR
    ENDR

; Gets the building level. Used to prevent building small buildings on top of
; bigger ones.
CREATE_BUILDING_LEVEL: ; Input = tile number

    ; Level = size

    ; RCI Tiles
    DS  T_RESIDENTIAL
    DB 0
    DB 0
    DB 0

    ; Buildings
    DS  T_RESIDENTIAL_S1_A - T_RESIDENTIAL - 3
    REPT 3 ; R C I
        REPT 4
            DB 1
        ENDR
        REPT 4
            DB 2,2, 2,2
        ENDR
        REPT 4
            DB 3,3,3, 3,3,3, 3,3,3
        ENDR
    ENDR

;-------------------------------------------------------------------------------

; Try to build a building as big as possible.

; c = type
; de = coords
Simulation_CreateBuildingsTryBuild::

    ; The tiles to test are arranged like this (0 is the origin):

    ; 0 1 2
    ; 3 4 5
    ; 6 7 8

    ; Check if all tiles are the same type as register C and if they are
    ; flagged to build. Any tile outside the map makes the function to fail.

    ; 1. Set size to 3x3.
    ; 2a. Check coordinates to see if 3x3 fits.
    ; 2b. Check 8, 7, 5, 6, 2. If any of them fails, fall back to 2x2.
    ; 3a. Check coordinates to see if 2x2 fits.
    ; 3b. Check 4, 3, 1. If they fail, fall back to 1x1.
    ; 4. Check 0.
    ; 5. Build building.

    add     sp,-1
    ld      hl,sp+0
    ld      [hl],c ; (*12) save tile into stack

    ; [sp+0] = type
    ; d = y, e = x

    ; 2a. Check coordinates to see if 3x3 fits

    ld      a,61
    cp      a,d ; carry flag is set if d > a (62 or 63)
    jp      c,.check2x2
    cp      a,e ; carry flag is set if e > a (62 or 63)
    jp      c,.check2x2

    ; 2b. Check 8, 7, 5, 6, 2. If any of them fails, fall back to 2x2.

START_POS_TEST : MACRO
    push    de
ENDM

; 1 = check position flags, 2 = this building level, 3 = jump here if failed
END_POS_TEST : MACRO
    call    CityMapGetTypeNoBoundCheck ; coords = de
    ; returns a = type, hl = address

    pop     de

    LD_BC_HL ; save address

    ld      hl,sp+0 ; point to type
    cp      a,[hl] ; type should be the same!
    jp      nz,\3

    LD_HL_BC ; restore address

    ; Check if building has been requested or demolished has been requested
    ld      a,BANK_CITY_MAP_FLAGS
    ld      [rSVBK],a

    ld      a,[hl] ; get flags

    bit     TILE_BUILD_REQUESTED_BIT,a ; if not requested, exit
    jp      z,\3

    bit     TILE_DEMOLISH_REQUESTED_BIT,a ; if requested, exit
    jp      nz,\3

    ; Make sure that the position flags allow us to build here
    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      a,[hl]
    and     a,\1
    jp      z,\3

    ; Make sure that the building already present here has a lower level than
    ; the one we are trying to build. This will also prevent a building to be
    ; built on top of another one of the same size.
    ld      a,BANK_SCRATCH_RAM_2
    ld      [rSVBK],a

    ld      a,[hl]
    cp      a,\2 ; carry flag is set if \2 > a (new level > old level)
    jp      nc,\3 ; it is lower or equal, don't build
ENDM

    ; d = y, e = x

    START_POS_TEST ; Check 8
        inc     e
        inc     e
        inc     d
        inc     d
    END_POS_TEST    F_BR,3,.check2x2

    START_POS_TEST ; Check 7
        inc     e
        inc     d
        inc     d
    END_POS_TEST    F_BC,3,.check2x2

    START_POS_TEST ; Check 5
        inc     e
        inc     e
        inc     d
    END_POS_TEST    F_CR,3,.check2x2

    START_POS_TEST ; Check 6
        inc     d
        inc     d
    END_POS_TEST    F_BL,3,.check2x2

    START_POS_TEST ; Check 2
        inc     e
        inc     e
    END_POS_TEST    F_TR,3,.check2x2

    START_POS_TEST ; Check 4
        inc     e
        inc     d
    END_POS_TEST    F_CC,3,.check2x2

    START_POS_TEST ; Check 3
        inc     d
    END_POS_TEST    F_CL,3,.check2x2

    START_POS_TEST ; Check 1
        inc     e
    END_POS_TEST    F_TC,3,.check2x2

    START_POS_TEST ; Check 0
    END_POS_TEST    F_TL,3,.check2x2

    jp      .build3x3

.check2x2:

    ; 3a. Check coordinates to see if 2x2 fits.

    ld      a,62
    cp      a,d ; carry flag is set if d > a (63)
    jp      c,.check1x1
    cp      a,e ; carry flag is set if e > a (63)
    jp      c,.check1x1

    ; 3b. Check 4, 3, 1. If they fail, fall back to 1x1.

    START_POS_TEST ; Check 4
        inc     e
        inc     d
    END_POS_TEST    F_CR|F_BC|F_BR,2,.check1x1

    START_POS_TEST ; Check 3
        inc     d
    END_POS_TEST    F_CL|F_BL|F_BC,2,.check1x1

    START_POS_TEST ; Check 1
        inc     e
    END_POS_TEST    F_TC|F_TR|F_CR,2,.check1x1

    START_POS_TEST ; Check 0
    END_POS_TEST    F_TL|F_TC|F_CL,2,.check1x1

    jr      .build2x2

.check1x1:

    ; 4. Check 0

    START_POS_TEST ; Check 0
    END_POS_TEST    F_CC,1,.exit_no_build

    ;jr      .build_1x1

.build1x1:
    ld      b,B_ResidentialS1A - B_ResidentialS1A
    jr      .build_end
.build2x2:
    ld      b,B_ResidentialS2A - B_ResidentialS1A
    jr      .build_end
.build3x3:
    ld      b,B_ResidentialS3A - B_ResidentialS1A
    ;jr      .build_end
.build_end:

    ld      hl,sp+0
    ld      a,[hl]

    add     sp,+1 ; (*2) restore stack

    ; a = RCI type
    ; b = building size offset
    ; de = origin coordinates

    cp      a,TYPE_RESIDENTIAL ; Residential first, it's the most common one.
    jr      z,.res
    cp      a,TYPE_COMMERCIAL
    jr      z,.com
    cp      a,TYPE_INDUSTRIAL
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

    ld      b,a
    ; de = origin coordinates
    ; b = building index
    LONG_CALL_ARGS  MapDrawBuildingForcedCoords

    ret

.exit_no_build:

    add     sp,+1 ; (*1) restore stack

    ret


;-------------------------------------------------------------------------------

; Higher number = Higher probability (0-255)

CreateBuildingProbability: ; 0 to 20% taxes - 21 values
    DB $FF ; no taxes = everyone wants to come!
    DB $FF,$FE,$FE,$FB,$FB,$F8,$F8,$F3,$F3,$EE
    DB $EE,$E7,$E7,$E0,$E0,$D8,$D8,$D0,$D0,$C6

DemolishBuildingProbability: ; 0 to 20% taxes - 21 values
    DB $04 ; no taxes = nobody wants to leave!
    DB $04,$05,$05,$07,$07,$0A,$0A,$0F,$0F,$14
    DB $14,$1B,$1B,$22,$22,$2A,$2A,$32,$32,$3C

;-------------------------------------------------------------------------------

; After calling Simulation_FlagCreateBuildings and calculating the RCI demand in
; Simulation_CalculateStatistics, create and destroy buildings!

; The functions used to build and delete buildings will clear the FLAGS in the
; tiles affected by the change, so the loop won't try to handle all tiles after
; one of these changes.

; Don't update VRAM map, let the animation loop do that for us.
Simulation_CreateBuildings::

    ; The probability of creating and destroying buildings depend on the amount
    ; of taxes.

    add     sp,-2 ; (***)

    ld      a,[tax_percentage]
    ld      b,a

    ; Penalize if pollution is high
    ld      a,[pollution_total+2] ; Max value = 255*64*64  = 0x0FF000
    sra     a
    ; a = 0 ~ F / 2 = 0 ~ 7
    add     a,b
    ld      b,a

    ; Penalize if traffic is high
    ld      a,[simulation_traffic_jam_num_tiles_percent]
    swap    a
    and     a,$0F
    add     a,b

    cp      a,20 ; cy = 1 if n > a
    jr      c,.not_overflow
    ld      a,20
.not_overflow:

    ld      e,a
    ld      d,0
    ld      hl,CreateBuildingProbability ; 0 to 20% taxes - 21 amounts
    add     hl,de
    ld      b,[hl] ; create probability
    ld      hl,DemolishBuildingProbability ; 0 to 20% taxes - 21 amounts
    add     hl,de
    ld      c,[hl] ;demolish probability

    ld      hl,sp+0
    ld      [hl],b ; [sp+0] = create probability
    inc     hl
    ld      [hl],c ; [sp+1] = demolish probability

    ; Create buildings
    ; ----------------

    ; First, set a temporary map with information to expand buildings and
    ; another one with information about the building size in order not to
    ; build small buildings on top of a big one.

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a
    call    ClearWRAMX

    ; Not needed to clear SCRATCH_RAM_2 because it will only be used if a
    ; building is being built in a tile, and to get to that point a few extra
    ; checks are needed.

    ;ld      a,BANK_SCRATCH_RAM_2
    ;ld      [rSVBK],a
    ;call    ClearWRAMX

    ld      hl,CITY_MAP_TILES ; Base address of the map!

    ld      a,BANK_CITY_MAP_TYPE
    ld      [rSVBK],a

.loop_set_flags:

        ld      a,[hl]

        cp      a,TYPE_RESIDENTIAL
        jr      z,.set_flags
        cp      a,TYPE_COMMERCIAL
        jr      z,.set_flags
        cp      a,TYPE_INDUSTRIAL
        jr      nz,.skip_set_flags
.set_flags:

        ; Arguments: hl = address. Preserves BC and HL
        call    CityMapGetTileAtAddress ; returns tile = de
        push    hl

            ld      hl,CREATE_BUILDING_FLAGS
            add     hl,de
            ld      c,[hl] ; c = flags

            ld      hl,CREATE_BUILDING_LEVEL
            add     hl,de
            ld      b,[hl] ; b = level

        pop     hl

        ld      a,BANK_SCRATCH_RAM
        ld      [rSVBK],a
        ld      [hl],c ; save flags

        ld      a,BANK_SCRATCH_RAM_2
        ld      [rSVBK],a
        ld      [hl],b ; save level

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

.skip_set_flags:

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop_set_flags

    ; We know that only RCI type tiles can have a build or demolish flag set.
    ; If the flag is set to 1, check if we can build. If built, clear the build
    ; flag from the modified tiles!

    ld      hl,CITY_MAP_TILES ; Base address of the map!

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)
        push    hl

            ld      a,BANK_CITY_MAP_TYPE
            ld      [rSVBK],a

            ld      a,[hl] ; a = type

            ; type = a
            ; coords = de
            ; address = hl

            cp      a,TYPE_RESIDENTIAL
            jr      z,.type_rci
            cp      a,TYPE_COMMERCIAL
            jr      z,.type_rci
            cp      a,TYPE_INDUSTRIAL
            jr      nz,.not_type_rci

.type_rci:
                ld      c,a

                ; type = c
                ; coords = de
                ; address = hl

                ; This is a RCI tile, check that we got a request to build or
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

                    ; c = type
                    ; de = coords
                    ; hl = address
                    push    de
                    push    hl
                    call    GetRandom
                    ld      hl,sp+8 ; [sp+0] = create probability (4 push)
                    cp      a,[hl] ; carry flag is set if [hl] > a (build)
                    pop     hl
                    pop     de
                    call    c,Simulation_CreateBuildingsTryBuild

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
    ; ---------------------------------------------------------------------

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

                    push    de
                    call    GetRandom
                    ld      hl,sp+7 ; [sp+1] = demolish probability (3 push)
                    cp      a,[hl] ; carry flag is set if [hl] > a (demolish)
                    pop     de
                    call    c,MapDeleteBuildingForced

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

    ; End

    add     sp,+2 ; (***)

    ret

;###############################################################################
