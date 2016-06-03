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

;###############################################################################
