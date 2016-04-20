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

POLICE_INFLUENCE_MASK: ; 32x32
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$0B,$10,$14,$17
    DB $18,$17,$14,$10,$0B,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$12,$1B,$22,$28,$2C,$2F
    DB $30,$2F,$2C,$28,$22,$1B,$12,$08,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$04,$11,$1D,$28,$31,$39,$3F,$44,$47
    DB $48,$47,$44,$3F,$39,$31,$28,$1D,$11,$04,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$09,$18,$25,$32,$3E,$48,$50,$57,$5C,$5F
    DB $60,$5F,$5C,$57,$50,$48,$3E,$32,$25,$18,$09,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$0A,$1B,$2A,$39,$47,$53,$5E,$67,$6E,$73,$76
    DB $78,$76,$73,$6E,$67,$5E,$53,$47,$39,$2A,$1B,$0A,$00,$00,$00,$00
    DB $00,$00,$00,$00,$09,$1B,$2C,$3D,$4C,$5B,$68,$73,$7D,$85,$8B,$8E
    DB $90,$8E,$8B,$85,$7D,$73,$68,$5B,$4C,$3D,$2C,$1B,$09,$00,$00,$00
    DB $00,$00,$00,$04,$18,$2A,$3D,$4E,$5F,$6E,$7C,$88,$93,$9C,$A2,$A6
    DB $A8,$A6,$A2,$9C,$93,$88,$7C,$6E,$5F,$4E,$3D,$2A,$18,$04,$00,$00
    DB $00,$00,$00,$11,$25,$39,$4C,$5F,$70,$80,$90,$9D,$A9,$B2,$BA,$BE
    DB $C0,$BE,$BA,$B2,$A9,$9D,$90,$80,$70,$5F,$4C,$39,$25,$11,$00,$00
    DB $00,$00,$08,$1D,$32,$47,$5B,$6E,$80,$92,$A2,$B1,$BE,$C9,$D1,$D6
    DB $D8,$D6,$D1,$C9,$BE,$B1,$A2,$92,$80,$6E,$5B,$47,$32,$1D,$08,$00
    DB $00,$00,$12,$28,$3E,$53,$68,$7C,$90,$A2,$B4,$C4,$D2,$DF,$E8,$EE
    DB $F0,$EE,$E8,$DF,$D2,$C4,$B4,$A2,$90,$7C,$68,$53,$3E,$28,$12,$00
    DB $00,$04,$1B,$31,$48,$5E,$73,$88,$9D,$B1,$C4,$D6,$E6,$F4,$FE,$FF
    DB $FF,$FF,$FE,$F4,$E6,$D6,$C4,$B1,$9D,$88,$73,$5E,$48,$31,$1B,$04
    DB $00,$0B,$22,$39,$50,$67,$7D,$93,$A9,$BE,$D2,$E6,$F8,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$F8,$E6,$D2,$BE,$A9,$93,$7D,$67,$50,$39,$22,$0B
    DB $00,$10,$28,$3F,$57,$6E,$85,$9C,$B2,$C9,$DF,$F4,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$F4,$DF,$C9,$B2,$9C,$85,$6E,$57,$3F,$28,$10
    DB $00,$14,$2C,$44,$5C,$73,$8B,$A2,$BA,$D1,$E8,$FE,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FE,$E8,$D1,$BA,$A2,$8B,$73,$5C,$44,$2C,$14
    DB $00,$17,$2F,$47,$5F,$76,$8E,$A6,$BE,$D6,$EE,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$EE,$D6,$BE,$A6,$8E,$76,$5F,$47,$2F,$17
    DB $00,$18,$30,$48,$60,$78,$90,$A8,$C0,$D8,$F0,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$F0,$D8,$C0,$A8,$90,$78,$60,$48,$30,$18
    DB $00,$17,$2F,$47,$5F,$76,$8E,$A6,$BE,$D6,$EE,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$EE,$D6,$BE,$A6,$8E,$76,$5F,$47,$2F,$17
    DB $00,$14,$2C,$44,$5C,$73,$8B,$A2,$BA,$D1,$E8,$FE,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FE,$E8,$D1,$BA,$A2,$8B,$73,$5C,$44,$2C,$14
    DB $00,$10,$28,$3F,$57,$6E,$85,$9C,$B2,$C9,$DF,$F4,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$F4,$DF,$C9,$B2,$9C,$85,$6E,$57,$3F,$28,$10
    DB $00,$0B,$22,$39,$50,$67,$7D,$93,$A9,$BE,$D2,$E6,$F8,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$F8,$E6,$D2,$BE,$A9,$93,$7D,$67,$50,$39,$22,$0B
    DB $00,$04,$1B,$31,$48,$5E,$73,$88,$9D,$B1,$C4,$D6,$E6,$F4,$FE,$FF
    DB $FF,$FF,$FE,$F4,$E6,$D6,$C4,$B1,$9D,$88,$73,$5E,$48,$31,$1B,$04
    DB $00,$00,$12,$28,$3E,$53,$68,$7C,$90,$A2,$B4,$C4,$D2,$DF,$E8,$EE
    DB $F0,$EE,$E8,$DF,$D2,$C4,$B4,$A2,$90,$7C,$68,$53,$3E,$28,$12,$00
    DB $00,$00,$08,$1D,$32,$47,$5B,$6E,$80,$92,$A2,$B1,$BE,$C9,$D1,$D6
    DB $D8,$D6,$D1,$C9,$BE,$B1,$A2,$92,$80,$6E,$5B,$47,$32,$1D,$08,$00
    DB $00,$00,$00,$11,$25,$39,$4C,$5F,$70,$80,$90,$9D,$A9,$B2,$BA,$BE
    DB $C0,$BE,$BA,$B2,$A9,$9D,$90,$80,$70,$5F,$4C,$39,$25,$11,$00,$00
    DB $00,$00,$00,$04,$18,$2A,$3D,$4E,$5F,$6E,$7C,$88,$93,$9C,$A2,$A6
    DB $A8,$A6,$A2,$9C,$93,$88,$7C,$6E,$5F,$4E,$3D,$2A,$18,$04,$00,$00
    DB $00,$00,$00,$00,$09,$1B,$2C,$3D,$4C,$5B,$68,$73,$7D,$85,$8B,$8E
    DB $90,$8E,$8B,$85,$7D,$73,$68,$5B,$4C,$3D,$2C,$1B,$09,$00,$00,$00
    DB $00,$00,$00,$00,$00,$0A,$1B,$2A,$39,$47,$53,$5E,$67,$6E,$73,$76
    DB $78,$76,$73,$6E,$67,$5E,$53,$47,$39,$2A,$1B,$0A,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$09,$18,$25,$32,$3E,$48,$50,$57,$5C,$5F
    DB $60,$5F,$5C,$57,$50,$48,$3E,$32,$25,$18,$09,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$04,$11,$1D,$28,$31,$39,$3F,$44,$47
    DB $48,$47,$44,$3F,$39,$31,$28,$1D,$11,$04,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$12,$1B,$22,$28,$2C,$2F
    DB $30,$2F,$2C,$28,$22,$1B,$12,$08,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$0B,$10,$14,$17
    DB $18,$17,$14,$10,$0B,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

POLICE_MASK_CENTER_X EQU 16
POLICE_MASK_CENTER_Y EQU 16

;-------------------------------------------------------------------------------

Simulation_PoliceApplyMask: ; e=x d=y (center)

    add     sp,-1

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ; Get top left corner

    ld      a,e
    sub     a,POLICE_MASK_CENTER_X
    ld      e,a

    ld      a,d
    sub     a,POLICE_MASK_CENTER_Y
    ld      d,a

    ld      hl,sp+0
    ld      [hl],e ; save left X

    ld      b,0 ; y
.loopy:
        ld      c,0 ; x
        ld      hl,sp+0
        ld      e,[hl] ; restore left x

.loopx:
        push    bc
        push    de

            ld      a,e
            or      a,d
            and     a,128+64 ; ~63
            jr      nz,.skip

            push    bc
            call    GetMapAddress ; e = x , d = y
            pop     bc

            LD_DE_HL ; de = destination

            ld      l,b
            ld      h,0
            add     hl,hl
            add     hl,hl
            add     hl,hl
            add     hl,hl
            add     hl,hl ; b<<5 = b*32
            ld      a,c
            add     a,l ; y*32+x
            ld      l,a
            ld      bc,POLICE_INFLUENCE_MASK
            add     hl,bc

            ld      a,[hl] ; new val

            ; Add the previous value
            ld      b,a
            ld      a,[de]
            add     a,b
            jr      nc,.not_saturated
            ld      a,$FF ; saturate
.not_saturated:

            ld      [de],a ; save

.skip:
        pop     de
        pop     bc

        inc     e
        inc     c
        ld      a,32
        cp      a,c
        jr      nz,.loopx

    inc     d
    inc     b
    ld      a,32
    cp      a,b
    jr      nz,.loopy

    add     sp,+1

    ret

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

            ; TODO - Get info from "tile OK flags" map to check power

            pop     de
            push    de
            call    Simulation_PoliceApplyMask

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
