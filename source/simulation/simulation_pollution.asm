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

; Valid pollution values:  0-255
DIFFUMINATE_LOOP : MACRO ; \1=Source Bank, \2=Destination bank

    ld      hl,SCRATCH_RAM ; Base address of the map!

    ld      d,0 ; d = y
.loopy\@:

        ld      e,0 ; e = x
.loopx\@:

        push    de ; (*)
        push    hl

            ld      a,(\1) ; Source bank
            ld      [rSVBK],a

            ld      de,-64 ; Top tile
            add     hl,de
            ld      b,0
            ld      c,[hl]

            ld      de,63 ; Left tile
            add     hl,de
            ld      a,c
            add     a,[hl]
            ld      c,a
            ld      a,0
            adc     a,b
            ld      b,a

            inc     hl ; Center tile
            ld      a,c
            add     a,[hl]
            ld      c,a
            ld      a,0
            adc     a,b
            ld      b,a

            inc     hl ; Right tile
            ld      a,c
            add     a,[hl]
            ld      c,a
            ld      a,0
            adc     a,b
            ld      b,a

            ld      de,63 ; Bottom tile
            add     hl,de
            ld      a,c
            add     a,[hl]
            ld      c,a
            ld      a,0
            adc     a,b
            ld      b,a

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

        pop     de ; (*)

        inc     hl

        inc     e
        bit     6,e
        jr      z,.loopx\@

    inc     d
    bit     6,d
    jr      z,.loopy\@

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

    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ; Smooth map
    ; ----------

    call    Simulation_PollutionDiffuminate

    ret

;-------------------------------------------------------------------------------

Simulation_PollutionSetTileOkFlag::

    ; NOTE: Don't call when drawing minimaps, this can only be called from the
    ; simulation loop!

    ld      hl,CITY_MAP_FLAGS ; Base address of the map!

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)
        push    hl


        pop     hl
        pop     de ; (*)

        inc     hl

        inc     e
        bit     6,e
        jr      z,.loopx

    inc     d
    bit     6,d
    jr      z,.loopy

    ret

;###############################################################################
