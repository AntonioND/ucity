;###############################################################################
;
;    uCity - City building game for Game Boy Color.
;    Copyright (C) 2017 Antonio Nino Diaz (AntonioND/SkyLyrac)
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

;###############################################################################

    SECTION "Simulation Pollution Variables",WRAM0

;-------------------------------------------------------------------------------

; Total pollution in the city. LSB first
pollution_total: DS 3 ; Max value = 255*64*64 (fits in 3 bytes!)

;###############################################################################

    SECTION "Simulation Pollution Functions",ROMX

;-------------------------------------------------------------------------------

; Division Look Up Table

DIV_BY_3: ; uint8_t = uint16_t / 3 (but only up to 255*3)

VALUE SET 0
    REPT 256 * 3
        DB VALUE / 3
VALUE SET VALUE + 1
    ENDR

;-------------------------------------------------------------------------------

; Input pointer to central tile in HL
; Returns the value in C
DIFFUMINATE_CENTRAL_TILE : MACRO ; 1=Source bank, 2=Destination bank
                                 ; 3=Top, 4=Left, 5=Right, 6=Bottom

    ld      a,(\1) ; Source bank
    ld      [rSVBK],a

    push    hl

        ld      bc,0

        ld      de,-64 ; Top tile
        add     hl,de
IF (\3) != 0
        ld      c,[hl]
ENDC

        ld      de,63 ; Left tile
        add     hl,de
IF (\4) != 0
        ld      a,c
        add     a,[hl]
        ld      c,a
        ld      a,0
        adc     a,b
        ld      b,a
ENDC

        inc     hl ; Central tile
REPT ( 5 - ((\3)+(\4)+(\5)+(\6)) )
        ld      a,c
        add     a,[hl]
        ld      c,a
        ld      a,0
        adc     a,b
        ld      b,a
ENDR

        inc     hl ; Right tile
IF (\5) != 0
        ld      a,c
        add     a,[hl]
        ld      c,a
        ld      a,0
        adc     a,b
        ld      b,a
ENDC

IF (\6) != 0
        ld      de,63 ; Bottom tile
        add     hl,de
        ld      a,c
        add     a,[hl]
        ld      c,a
        ld      a,0
        adc     a,b
        ld      b,a
ENDC

        ; check if bc < 255*3
        ld      a,b
        cp      a,(255*3)>>8 ; carry flag is set if n > a
        jr      nc,.n_is_greater\@
        jr      nz,.n_is_lower\@

        ; Upper byte is equal
        ld      a,c
        cp      a,(255*3)&$FF ; carry flag is set if n > a
        jr      nc,.n_is_greater\@

.n_is_lower\@:
        ld      hl,DIV_BY_3
        add     hl,bc
        ld      c,[hl]
        jr      .end\@
.n_is_greater\@:
        ld      c,255 ; saturate
.end\@:

    pop     hl

    ld      a,(\2) ; Destination bank
    ld      [rSVBK],a

    ld      [hl],c

ENDM

;-------------------------------------------------------------------------------

; Valid pollution values:  0-255
DIFFUMINATE_LOOP : MACRO ; \1=Source Bank, \2=Destination bank

    ld      hl,SCRATCH_RAM ; Base address of the map!

    ; Top row

    DIFFUMINATE_CENTRAL_TILE    (\1),(\2),0,0,1,1
    inc     hl

    ld      e,64-2
.loopx_ytop\@:
    push    de
        DIFFUMINATE_CENTRAL_TILE    (\1),(\2),0,1,1,1
        inc     hl
    pop     de
    dec     e
    jr      nz,.loopx_ytop\@

    DIFFUMINATE_CENTRAL_TILE    (\1),(\2),0,1,0,1
    inc     hl

    ; Regular row

    ld      d,CITY_MAP_HEIGHT-2 ; d = y
.loopy\@:

        push    de

        DIFFUMINATE_CENTRAL_TILE    (\1),(\2),1,0,1,1
        inc     hl

        ld      e,CITY_MAP_WIDTH-2
.loopx\@:
        push    de
            DIFFUMINATE_CENTRAL_TILE    (\1),(\2),1,1,1,1
            inc     hl
        pop     de
        dec     e
        jr      nz,.loopx\@

        DIFFUMINATE_CENTRAL_TILE    (\1),(\2),1,1,0,1
        inc     hl

        pop     de

    dec     d
    jp      nz,.loopy\@

    ; Bottom row

    DIFFUMINATE_CENTRAL_TILE    (\1),(\2),1,0,1,0
    inc     hl

    ld      e,64-2
.loopx_ybottom\@:
    push    de
        DIFFUMINATE_CENTRAL_TILE    (\1),(\2),1,1,1,0
        inc     hl
    pop     de
    dec     e
    jr      nz,.loopx_ybottom\@

    DIFFUMINATE_CENTRAL_TILE    (\1),(\2),1,1,0,0

ENDM

Simulation_PollutionDiffuminate:

    DIFFUMINATE_LOOP    BANK_SCRATCH_RAM,BANK_SCRATCH_RAM_2
    DIFFUMINATE_LOOP    BANK_SCRATCH_RAM_2,BANK_SCRATCH_RAM
    DIFFUMINATE_LOOP    BANK_SCRATCH_RAM,BANK_SCRATCH_RAM_2
    DIFFUMINATE_LOOP    BANK_SCRATCH_RAM_2,BANK_SCRATCH_RAM

    ret

;-------------------------------------------------------------------------------

; Output data to WRAMX bank BANK_SCRATCH_RAM
Simulation_Pollution::

    ; Clean
    ; -----

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    call    ClearWRAMX

    ld      hl,pollution_total ; Reset total pollution
    xor     a,a
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a

    ; Add to the map the corresponding pollution for each tile
    ; --------------------------------------------------------

    ld      hl,CITY_MAP_TILES

.loop:
    push    hl

        ; Get tile type.
        ; - If road, check traffic. Train doesn't pollute as it is electric.
        ; - If building, check if the building has power and add pollution
        ;   if so. If it is a power plant, add the corresponding pollution
        ;   level.
        ; - If park, forest or water set a negative level of pollution (they
        ;   reduce it)

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

        ld      a,[hl]

        bit     TYPE_HAS_ROAD_BIT,a
        jr      z,.not_road

            ld      a,BANK_CITY_MAP_TRAFFIC
            ld      [rSVBK],a

            ld      b,[hl]

            ; Pollution is the amount of cars going through here

            jr      .save_value

.not_road:

        ; Read pollution level array

        push    hl
        call    CityMapGetTileAtAddress ; hl = address, returns de = tile
        call    CityTilePollution ; de = tile, returns d=pollution
        pop     hl

        ld      b,d

;        jr      .save_value

.save_value:

        ld      a,BANK_SCRATCH_RAM
        ld      [rSVBK],a

        ld      [hl],b

        ; Add to total pollution

        ld      hl,pollution_total

        ld      a,[hl]
        add     a,b
        ld      [hl+],a

        ld      a,[hl]
        add     a,0
        ld      [hl+],a

        ld      a,[hl]
        add     a,0
        ld      [hl],a

    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ; Smooth map
    ; ----------

    call    Simulation_PollutionDiffuminate

    ; Check if pollution is too high
    ; ------------------------------

    ; Max value = 255*64*64  = 0x0FF000
    ; Complain if pollution >= 0x030000 so that we only need to check top byte

    ld      hl,pollution_total+2
    ld      a,[hl]
    cp      a,$03 ; cy = 1 if n > a (threshold > current value)
    ret     c

    ; TODO - Use this for total city score or to make people not want to come
    ; here?

    ; This message is shown only once per year
    ld      a,ID_MSG_POLLUTION_HIGH
    call    PersistentMessageShow

    ret

;###############################################################################

; Max valid pollution for zones that need non-polluted air
POLLUTION_MAX_VALID_LEVEL EQU (256/2)

;-------------------------------------------------------------------------------

; Reads data from SCRATCH RAM and saves the result to the FLAGS map
Simulation_PollutionSetTileOkFlag::

    ; NOTE: Don't call when drawing minimaps, this can only be called from the
    ; simulation loop!

    ld      hl,CITY_MAP_FLAGS ; Base address of the map!

.loop:

    push    hl

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

        ld      a,[hl] ; get type
        and     a,TYPE_MASK ; remove flags

        ; List of terrains that ignore the pollution level. In general, any
        ; terrain that generates pollution ignores it. This is only used for
        ; buildings, so no need to check fields, forests or water zones.

        ld      de,.ignore_tile_array
        ; 1 = ignore this tile, 0 = handle pollution
        add     a,e
        ld      e,a
        ld      a,0
        adc     a,d
        ld      d,a ; de = &(array[type])

        ld      a,[de]
        and     a,a
        jr      nz,.ignore_pollution

        ; If the building actually requires a pollution level check...

        ld      a,BANK_SCRATCH_RAM
        ld      [rSVBK],a

        ld      a,[hl] ; get pollution
        cp      a,POLLUTION_MAX_VALID_LEVEL ; carry flag is set if n > a
        jr      c,.non_polluted
            ; Polluted - Clear "valid pollution level" bit
            ld      a,BANK_CITY_MAP_FLAGS
            ld      [rSVBK],a
            res     TILE_OK_POLLUTION_BIT,[hl]
            jr      .end_pollution_check
.non_polluted:
.ignore_pollution:
            ; Non-polluted - Set "valid pollution level" bit
            ld      a,BANK_CITY_MAP_FLAGS
            ld      [rSVBK],a
            set     TILE_OK_POLLUTION_BIT,[hl]
            ;jr      .end_pollution_check
.end_pollution_check:

    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

; This array says whether a particular tile type has to be checked for pollution
; or not. Type flags should be removed before accesing it.
.ignore_tile_array: ; 1 = ignore this tile, 0 = handle pollution
    DB  1 ; TYPE_FIELD - There's nothing here, don't check...
    DB  1 ; TYPE_FOREST
    DB  1 ; TYPE_WATER
    DB  0 ; TYPE_RESIDENTIAL - R and C must be clean. I generates pollution.
    DB  1 ; TYPE_INDUSTRIAL
    DB  0 ; TYPE_COMMERCIAL
    DB  1 ; TYPE_POLICE_DEPT - Services are supposed to work even in very
    DB  1 ; TYPE_FIRE_DEPT     polluted areas.
    DB  1 ; TYPE_HOSPITAL
    DB  0 ; TYPE_PARK - Recreation and education, they must be clean.
    DB  0 ; TYPE_STADIUM
    DB  0 ; TYPE_SCHOOL
    DB  0 ; TYPE_HIGH_SCHOOL
    DB  0 ; TYPE_UNIVERSITY
    DB  0 ; TYPE_MUSEUM
    DB  0 ; TYPE_LIBRARY
    DB  1 ; TYPE_AIRPORT - The following tiles generate pollution, so it's
    DB  1 ; TYPE_PORT      illogical to ask for no pollution there.
    DB  1 ; TYPE_DOCK
    DB  1 ; TYPE_POWER_PLANT
    DB  0 ; TYPE_FIRE - Simulation should be off during fires.
    DB  1 ; TYPE_RADIATION - Ignore pollution here
    ; End of valid types...

;###############################################################################
