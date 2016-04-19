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

;###############################################################################

    SECTION "Simulation Police",ROMX

;-------------------------------------------------------------------------------

POLICE_INFLUENCE_MASK: ; 16x16
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$0C,$16,$1D,$1F,$1D,$16,$0C,$00,$00,$00,$00
    DB $00,$00,$00,$06,$19,$29,$35,$3D,$3F,$3D,$35,$29,$19,$06,$00,$00
    DB $00,$00,$06,$1D,$32,$45,$53,$5C,$5F,$5C,$53,$45,$32,$1D,$06,$00
    DB $00,$00,$19,$32,$4A,$5F,$70,$7B,$7F,$7B,$70,$5F,$4A,$32,$19,$00
    DB $00,$0C,$29,$45,$5F,$77,$8C,$9A,$9F,$9A,$8C,$77,$5F,$45,$29,$0C
    DB $00,$16,$35,$53,$70,$8C,$A4,$B7,$BF,$B7,$A4,$8C,$70,$53,$35,$16
    DB $00,$1D,$3D,$5C,$7B,$9A,$B7,$D1,$DF,$D1,$B7,$9A,$7B,$5C,$3D,$1D
    DB $00,$1F,$3F,$5F,$7F,$9F,$BF,$DF,$FF,$DF,$BF,$9F,$7F,$5F,$3F,$1F
    DB $00,$1D,$3D,$5C,$7B,$9A,$B7,$D1,$DF,$D1,$B7,$9A,$7B,$5C,$3D,$1D
    DB $00,$16,$35,$53,$70,$8C,$A4,$B7,$BF,$B7,$A4,$8C,$70,$53,$35,$16
    DB $00,$0C,$29,$45,$5F,$77,$8C,$9A,$9F,$9A,$8C,$77,$5F,$45,$29,$0C
    DB $00,$00,$19,$32,$4A,$5F,$70,$7B,$7F,$7B,$70,$5F,$4A,$32,$19,$00
    DB $00,$00,$06,$1D,$32,$45,$53,$5C,$5F,$5C,$53,$45,$32,$1D,$06,$00
    DB $00,$00,$00,$06,$19,$29,$35,$3D,$3F,$3D,$35,$29,$19,$06,$00,$00
    DB $00,$00,$00,$00,$00,$0C,$16,$1D,$1F,$1D,$16,$0C,$00,$00,$00,$00

POLICE_MASK_CENTER_X EQU 8
POLICE_MASK_CENTER_Y EQU 8

;-------------------------------------------------------------------------------

Simulation_Police:: ; Output data to WRAMX bank BANK_SCRATCH_RAM

    ; Clean

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      bc,$1000
    ld      d,0
    ld      hl,SCRATCH_RAM
    call    memset

    ; For each tile check if it is the central tile of a police station
    ; -----------------------------------------------------------------

    ld      d,0 ; y
.loopy:
        ld      e,0 ; x
.loopx:
        push    de

        call    CityMapGetTile ; e = x , d = y. Returns tile = DE, address = HL

        ld      a,((T_POLICE+4)>>8) & $FF ; Central tile. 4=3+1 (3x3 building)
        cp      a,d
        jr      nz,.not_police_center
        ld      a,(T_POLICE+4) & $FF
        cp      a,e
        jr      nz,.not_police_center

            ; Police center tile
            ; ------------------

            ; Check if there is power in this station

            ; TODO - Get info from "tile OK flags" map

            ; HL should be still the address returned from CityMapGetTile

            ld      a,BANK_SCRATCH_RAM
            ld      [rSVBK],a
            ld      [hl],255

.not_police_center:

        pop     de

        inc     e
        ld      a,64
        cp      a,e
        jr      nz,.loopx

    inc     d
    ld      a,64
    cp      a,d
    jr      nz,.loopy



    ret

;###############################################################################
