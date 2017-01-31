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
    INCLUDE "tileset_info.inc"

;###############################################################################

    SECTION "Simulation Water Functions",ROMX

;-------------------------------------------------------------------------------

Simulation_WaterAnimate:: ; This doesn't refresh tile map!

    ld      a,BANK_CITY_MAP_TILES
    ld      [rSVBK],a

    call    GetRandom ; preserves bc, de
    ; a = counter until the next change
    and     a,31
    inc     a

    ld      hl,CITY_MAP_TILES ; Map base

.loop:

    dec     a
    jr      nz,.next_skip_rand

IF (T_WATER > 255) || (T_WATER_EXTRA > 255)
    FAIL    "T_WATER and T_WATER_EXTRA should be in the first 256-tile bank."
ENDC

        ld      a,[hl] ; Get low bytes

        cp      a,T_WATER & $FF
        jr      nz,.not_water

            ld      a,BANK_CITY_MAP_ATTR
            ld      [rSVBK],a

            bit     3,[hl]
            jr      nz,.next

                ld      a,BANK_CITY_MAP_TILES
                ld      [rSVBK],a

                ld      [hl],T_WATER_EXTRA & $FF

.not_water:

        cp      a,T_WATER_EXTRA & $FF
        jr      nz,.not_water_extra

            ld      a,BANK_CITY_MAP_ATTR
            ld      [rSVBK],a

            bit     3,[hl]
            jr      nz,.next

                ld      a,BANK_CITY_MAP_TILES
                ld      [rSVBK],a

                ld      [hl],T_WATER & $FF

.not_water_extra:

.next:

        LD_BC_HL
        call    GetRandom ; preserves bc, de
        LD_HL_BC
        ; a = counter until the next change
        and     a,31
        inc     a

.next_skip_rand:

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

;###############################################################################
