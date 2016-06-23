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

    SECTION "Simulation Services Functions",ROMX

;-------------------------------------------------------------------------------

SERVICES_MASK_WIDTH  EQU 32
SERVICES_MASK_HEIGHT EQU 32

SERVICES_MASK_CENTER_X EQU 16
SERVICES_MASK_CENTER_Y EQU 16

SERVICES_INFLUENCE_MASK: ; 32x32
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

;-------------------------------------------------------------------------------

Simulation_ServicesApplyMask: ; e=x d=y (center)

    add     sp,-1

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ; Get top left corner

    ld      a,e
    sub     a,SERVICES_MASK_CENTER_X
    ld      e,a

    ld      a,d
    sub     a,SERVICES_MASK_CENTER_Y
    ld      d,a

    ld      hl,sp+0
    ld      [hl],e ; save left X

    ld      b,0 ; y
.loopy:
        ld      c,0 ; x
        ld      hl,sp+0
        ld      e,[hl] ; restore left x

.loopx:

        ld      a,e
        or      a,d
        and     a,128+64 ; ~63
        jr      nz,.skip

        push    bc
        push    de

            GET_MAP_ADDRESS ; e = x , d = y. preserves de and bc

            LD_DE_HL ; de = destination

            ld      l,b
            ld      h,0
            add     hl,hl
            add     hl,hl
            add     hl,hl
            add     hl,hl
            add     hl,hl ; b<<5 = b*32 (SERVICES_MASK_WIDTH)
IF SERVICES_MASK_WIDTH != 32
    FAIL "Fix this."
ENDC
            ld      a,c
            add     a,l ; y*32+x
            ld      l,a
            ld      bc,SERVICES_INFLUENCE_MASK
            add     hl,bc ; MASK + 32*y + x

            ld      a,[hl] ; new val
            and     a,a
            jr      z,.dont_add

            ; Add the previous value
            ld      b,a
            ld      a,[de]
            add     a,b
            jr      nc,.not_saturated
            ld      a,$FF ; saturate
.not_saturated:
            ld      [de],a ; save

.dont_add:

        pop     de
        pop     bc

.skip:

        inc     e
        inc     c
        ld      a,SERVICES_MASK_WIDTH
        cp      a,c
        jr      nz,.loopx

    inc     d
    inc     b
    ld      a,SERVICES_MASK_HEIGHT
    cp      a,b
    jr      nz,.loopy

    add     sp,+1

    ret

;-------------------------------------------------------------------------------

; Output data to WRAMX bank BANK_SCRATCH_RAM
Simulation_Services:: ; BC = central tile of the building (tileset_info.inc)

    add     sp,-2

    ld      hl,sp+0
    ld      [hl],b
    inc     hl
    ld      [hl],c

    ; Clean
    ; -----

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    call    ClearWRAMX

    ; For each tile check if it is the tile passed as argument
    ; --------------------------------------------------------

    ld      d,0 ; y
.loopy:
        ld      e,0 ; x
.loopx:
        push    de

        call    CityMapGetTile ; e = x , d = y. Returns tile = de

        ld      hl,sp+2
        ld      a,[hl+]
        cp      a,d
        jr      nz,.not_tile
        ld      a,[hl]
        cp      a,e
        jr      nz,.not_tile

            ; Desired tile found
            ; ------------------

            ; Check if there is power

            pop     de
            push    de
            GET_MAP_ADDRESS ; preserves de and bc

            ld      a,BANK_CITY_MAP_FLAGS
            ld      [rSVBK],a
            bit     TILE_OK_POWER_BIT,[hl]
            jr      z,.not_tile ; If there is no power, the building can't work

            call    Simulation_ServicesApplyMask

.not_tile:

        pop     de

        inc     e
        ld      a,CITY_MAP_WIDTH
        cp      a,e
        jr      nz,.loopx

    inc     d
    ld      a,CITY_MAP_HEIGHT
    cp      a,d
    jr      nz,.loopy

    add     sp,+2

    ret

;###############################################################################

    SECTION "Simulation Big Services Functions",ROMX

;-------------------------------------------------------------------------------

SERVICES_MASK_BIG_WIDTH  EQU 64
SERVICES_MASK_BIG_HEIGHT EQU 64

SERVICES_MASK_BIG_CENTER_X EQU 32
SERVICES_MASK_BIG_CENTER_Y EQU 32

SERVICES_INFLUENCE_MASK_BIG: ; 64x64
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$05,$07,$08,$0A,$0B,$0B
    DB $0C,$0B,$0B,$0A,$08,$07,$05,$02,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$04,$08,$0B,$0E,$10,$13,$14,$16,$17,$17
    DB $18,$17,$17,$16,$14,$13,$10,$0E,$0B,$08,$04,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$02,$07,$0B,$0F,$13,$17,$1A,$1C,$1E,$20,$22,$23,$23
    DB $24,$23,$23,$22,$20,$1E,$1C,$1A,$17,$13,$0F,$0B,$07,$02,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$02,$08,$0D,$12,$17,$1B,$1F,$22,$25,$28,$2A,$2C,$2E,$2F,$2F
    DB $30,$2F,$2F,$2E,$2C,$2A,$28,$25,$22,$1F,$1B,$17,$12,$0D,$08,$02
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01
    DB $07,$0D,$13,$18,$1D,$22,$26,$2A,$2E,$31,$34,$36,$38,$3A,$3B,$3B
    DB $3C,$3B,$3B,$3A,$38,$36,$34,$31,$2E,$2A,$26,$22,$1D,$18,$13,$0D
    DB $07,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$0B
    DB $11,$17,$1D,$23,$28,$2D,$31,$35,$39,$3C,$3F,$42,$44,$45,$47,$47
    DB $48,$47,$47,$45,$44,$42,$3F,$3C,$39,$35,$31,$2D,$28,$23,$1D,$17
    DB $11,$0B,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$0E,$15
    DB $1B,$22,$28,$2D,$33,$38,$3C,$41,$45,$48,$4B,$4E,$50,$51,$53,$53
    DB $54,$53,$53,$51,$50,$4E,$4B,$48,$45,$41,$3C,$38,$33,$2D,$28,$22
    DB $1B,$15,$0E,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$09,$10,$18,$1F
    DB $25,$2C,$32,$38,$3E,$43,$48,$4C,$50,$54,$57,$59,$5C,$5D,$5F,$5F
    DB $60,$5F,$5F,$5D,$5C,$59,$57,$54,$50,$4C,$48,$43,$3E,$38,$32,$2C
    DB $25,$1F,$18,$10,$09,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$0A,$12,$1A,$21,$28
    DB $2F,$36,$3C,$42,$48,$4E,$53,$57,$5B,$5F,$62,$65,$67,$69,$6A,$6B
    DB $6C,$6B,$6A,$69,$67,$65,$62,$5F,$5B,$57,$53,$4E,$48,$42,$3C,$36
    DB $2F,$28,$21,$1A,$12,$0A,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$0A,$13,$1B,$23,$2A,$32
    DB $39,$40,$47,$4D,$53,$58,$5E,$62,$67,$6A,$6E,$71,$73,$75,$76,$77
    DB $78,$77,$76,$75,$73,$71,$6E,$6A,$67,$62,$5E,$58,$53,$4D,$47,$40
    DB $39,$32,$2A,$23,$1B,$13,$0A,$02,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$01,$0A,$13,$1B,$24,$2C,$34,$3B
    DB $43,$4A,$51,$57,$5D,$63,$68,$6D,$72,$76,$79,$7C,$7F,$81,$82,$83
    DB $84,$83,$82,$81,$7F,$7C,$79,$76,$72,$6D,$68,$63,$5D,$57,$51,$4A
    DB $43,$3B,$34,$2C,$24,$1B,$13,$0A,$01,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$09,$12,$1B,$24,$2C,$34,$3D,$45
    DB $4C,$54,$5B,$61,$68,$6E,$73,$78,$7D,$81,$85,$88,$8B,$8D,$8E,$8F
    DB $90,$8F,$8E,$8D,$8B,$88,$85,$81,$7D,$78,$73,$6E,$68,$61,$5B,$54
    DB $4C,$45,$3D,$34,$2C,$24,$1B,$12,$09,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$07,$10,$1A,$23,$2C,$34,$3D,$45,$4E
    DB $55,$5D,$64,$6B,$72,$78,$7E,$83,$88,$8D,$90,$94,$97,$99,$9A,$9B
    DB $9C,$9B,$9A,$99,$97,$94,$90,$8D,$88,$83,$7E,$78,$72,$6B,$64,$5D
    DB $55,$4E,$45,$3D,$34,$2C,$23,$1A,$10,$07,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$04,$0E,$18,$21,$2A,$34,$3D,$45,$4E,$56
    DB $5F,$66,$6E,$75,$7C,$82,$88,$8E,$93,$98,$9C,$9F,$A2,$A5,$A6,$A7
    DB $A8,$A7,$A6,$A5,$A2,$9F,$9C,$98,$93,$8E,$88,$82,$7C,$75,$6E,$66
    DB $5F,$56,$4E,$45,$3D,$34,$2A,$21,$18,$0E,$04,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$01,$0B,$15,$1F,$28,$32,$3B,$45,$4E,$56,$5F
    DB $67,$6F,$77,$7F,$86,$8D,$93,$99,$9E,$A3,$A7,$AB,$AE,$B0,$B2,$B3
    DB $B4,$B3,$B2,$B0,$AE,$AB,$A7,$A3,$9E,$99,$93,$8D,$86,$7F,$77,$6F
    DB $67,$5F,$56,$4E,$45,$3B,$32,$28,$1F,$15,$0B,$01,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$07,$11,$1B,$25,$2F,$39,$43,$4C,$55,$5F,$67
    DB $70,$78,$80,$88,$90,$97,$9D,$A3,$A9,$AE,$B2,$B6,$BA,$BC,$BE,$BF
    DB $C0,$BF,$BE,$BC,$BA,$B6,$B2,$AE,$A9,$A3,$9D,$97,$90,$88,$80,$78
    DB $70,$67,$5F,$55,$4C,$43,$39,$2F,$25,$1B,$11,$07,$00,$00,$00,$00
    DB $00,$00,$00,$00,$02,$0D,$17,$22,$2C,$36,$40,$4A,$54,$5D,$66,$6F
    DB $78,$81,$89,$91,$99,$A0,$A7,$AE,$B4,$B9,$BE,$C2,$C5,$C8,$CA,$CB
    DB $CC,$CB,$CA,$C8,$C5,$C2,$BE,$B9,$B4,$AE,$A7,$A0,$99,$91,$89,$81
    DB $78,$6F,$66,$5D,$54,$4A,$40,$36,$2C,$22,$17,$0D,$02,$00,$00,$00
    DB $00,$00,$00,$00,$08,$13,$1D,$28,$32,$3C,$47,$51,$5B,$64,$6E,$77
    DB $80,$89,$92,$9A,$A2,$AA,$B1,$B8,$BE,$C4,$C9,$CD,$D1,$D4,$D6,$D7
    DB $D8,$D7,$D6,$D4,$D1,$CD,$C9,$C4,$BE,$B8,$B1,$AA,$A2,$9A,$92,$89
    DB $80,$77,$6E,$64,$5B,$51,$47,$3C,$32,$28,$1D,$13,$08,$00,$00,$00
    DB $00,$00,$00,$02,$0D,$18,$23,$2D,$38,$42,$4D,$57,$61,$6B,$75,$7F
    DB $88,$91,$9A,$A3,$AB,$B3,$BB,$C2,$C8,$CE,$D4,$D8,$DC,$DF,$E2,$E3
    DB $E4,$E3,$E2,$DF,$DC,$D8,$D4,$CE,$C8,$C2,$BB,$B3,$AB,$A3,$9A,$91
    DB $88,$7F,$75,$6B,$61,$57,$4D,$42,$38,$2D,$23,$18,$0D,$02,$00,$00
    DB $00,$00,$00,$07,$12,$1D,$28,$33,$3E,$48,$53,$5D,$68,$72,$7C,$86
    DB $90,$99,$A2,$AB,$B4,$BC,$C4,$CC,$D2,$D9,$DF,$E4,$E8,$EB,$EE,$EF
    DB $F0,$EF,$EE,$EB,$E8,$E4,$DF,$D9,$D2,$CC,$C4,$BC,$B4,$AB,$A2,$99
    DB $90,$86,$7C,$72,$68,$5D,$53,$48,$3E,$33,$28,$1D,$12,$07,$00,$00
    DB $00,$00,$00,$0B,$17,$22,$2D,$38,$43,$4E,$58,$63,$6E,$78,$82,$8D
    DB $97,$A0,$AA,$B3,$BC,$C5,$CD,$D5,$DC,$E3,$E9,$EF,$F3,$F7,$F9,$FB
    DB $FC,$FB,$F9,$F7,$F3,$EF,$E9,$E3,$DC,$D5,$CD,$C5,$BC,$B3,$AA,$A0
    DB $97,$8D,$82,$78,$6E,$63,$58,$4E,$43,$38,$2D,$22,$17,$0B,$00,$00
    DB $00,$00,$04,$0F,$1B,$26,$31,$3C,$48,$53,$5E,$68,$73,$7E,$88,$93
    DB $9D,$A7,$B1,$BB,$C4,$CD,$D6,$DE,$E6,$ED,$F4,$F9,$FE,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FE,$F9,$F4,$ED,$E6,$DE,$D6,$CD,$C4,$BB,$B1,$A7
    DB $9D,$93,$88,$7E,$73,$68,$5E,$53,$48,$3C,$31,$26,$1B,$0F,$04,$00
    DB $00,$00,$08,$13,$1F,$2A,$35,$41,$4C,$57,$62,$6D,$78,$83,$8E,$99
    DB $A3,$AE,$B8,$C2,$CC,$D5,$DE,$E7,$EF,$F7,$FE,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FE,$F7,$EF,$E7,$DE,$D5,$CC,$C2,$B8,$AE
    DB $A3,$99,$8E,$83,$78,$6D,$62,$57,$4C,$41,$35,$2A,$1F,$13,$08,$00
    DB $00,$00,$0B,$17,$22,$2E,$39,$45,$50,$5B,$67,$72,$7D,$88,$93,$9E
    DB $A9,$B4,$BE,$C8,$D2,$DC,$E6,$EF,$F8,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8,$EF,$E6,$DC,$D2,$C8,$BE,$B4
    DB $A9,$9E,$93,$88,$7D,$72,$67,$5B,$50,$45,$39,$2E,$22,$17,$0B,$00
    DB $00,$02,$0E,$1A,$25,$31,$3C,$48,$54,$5F,$6A,$76,$81,$8D,$98,$A3
    DB $AE,$B9,$C4,$CE,$D9,$E3,$ED,$F7,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F7,$ED,$E3,$D9,$CE,$C4,$B9
    DB $AE,$A3,$98,$8D,$81,$76,$6A,$5F,$54,$48,$3C,$31,$25,$1A,$0E,$02
    DB $00,$05,$10,$1C,$28,$34,$3F,$4B,$57,$62,$6E,$79,$85,$90,$9C,$A7
    DB $B2,$BE,$C9,$D4,$DF,$E9,$F4,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$F4,$E9,$DF,$D4,$C9,$BE
    DB $B2,$A7,$9C,$90,$85,$79,$6E,$62,$57,$4B,$3F,$34,$28,$1C,$10,$05
    DB $00,$07,$13,$1E,$2A,$36,$42,$4E,$59,$65,$71,$7C,$88,$94,$9F,$AB
    DB $B6,$C2,$CD,$D8,$E4,$EF,$F9,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F9,$EF,$E4,$D8,$CD,$C2
    DB $B6,$AB,$9F,$94,$88,$7C,$71,$65,$59,$4E,$42,$36,$2A,$1E,$13,$07
    DB $00,$08,$14,$20,$2C,$38,$44,$50,$5C,$67,$73,$7F,$8B,$97,$A2,$AE
    DB $BA,$C5,$D1,$DC,$E8,$F3,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$F3,$E8,$DC,$D1,$C5
    DB $BA,$AE,$A2,$97,$8B,$7F,$73,$67,$5C,$50,$44,$38,$2C,$20,$14,$08
    DB $00,$0A,$16,$22,$2E,$3A,$45,$51,$5D,$69,$75,$81,$8D,$99,$A5,$B0
    DB $BC,$C8,$D4,$DF,$EB,$F7,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F7,$EB,$DF,$D4,$C8
    DB $BC,$B0,$A5,$99,$8D,$81,$75,$69,$5D,$51,$45,$3A,$2E,$22,$16,$0A
    DB $00,$0B,$17,$23,$2F,$3B,$47,$53,$5F,$6A,$76,$82,$8E,$9A,$A6,$B2
    DB $BE,$CA,$D6,$E2,$EE,$F9,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F9,$EE,$E2,$D6,$CA
    DB $BE,$B2,$A6,$9A,$8E,$82,$76,$6A,$5F,$53,$47,$3B,$2F,$23,$17,$0B
    DB $00,$0B,$17,$23,$2F,$3B,$47,$53,$5F,$6B,$77,$83,$8F,$9B,$A7,$B3
    DB $BF,$CB,$D7,$E3,$EF,$FB,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FB,$EF,$E3,$D7,$CB
    DB $BF,$B3,$A7,$9B,$8F,$83,$77,$6B,$5F,$53,$47,$3B,$2F,$23,$17,$0B
    DB $00,$0C,$18,$24,$30,$3C,$48,$54,$60,$6C,$78,$84,$90,$9C,$A8,$B4
    DB $C0,$CC,$D8,$E4,$F0,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC,$F0,$E4,$D8,$CC
    DB $C0,$B4,$A8,$9C,$90,$84,$78,$6C,$60,$54,$48,$3C,$30,$24,$18,$0C
    DB $00,$0B,$17,$23,$2F,$3B,$47,$53,$5F,$6B,$77,$83,$8F,$9B,$A7,$B3
    DB $BF,$CB,$D7,$E3,$EF,$FB,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FB,$EF,$E3,$D7,$CB
    DB $BF,$B3,$A7,$9B,$8F,$83,$77,$6B,$5F,$53,$47,$3B,$2F,$23,$17,$0B
    DB $00,$0B,$17,$23,$2F,$3B,$47,$53,$5F,$6A,$76,$82,$8E,$9A,$A6,$B2
    DB $BE,$CA,$D6,$E2,$EE,$F9,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F9,$EE,$E2,$D6,$CA
    DB $BE,$B2,$A6,$9A,$8E,$82,$76,$6A,$5F,$53,$47,$3B,$2F,$23,$17,$0B
    DB $00,$0A,$16,$22,$2E,$3A,$45,$51,$5D,$69,$75,$81,$8D,$99,$A5,$B0
    DB $BC,$C8,$D4,$DF,$EB,$F7,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F7,$EB,$DF,$D4,$C8
    DB $BC,$B0,$A5,$99,$8D,$81,$75,$69,$5D,$51,$45,$3A,$2E,$22,$16,$0A
    DB $00,$08,$14,$20,$2C,$38,$44,$50,$5C,$67,$73,$7F,$8B,$97,$A2,$AE
    DB $BA,$C5,$D1,$DC,$E8,$F3,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$F3,$E8,$DC,$D1,$C5
    DB $BA,$AE,$A2,$97,$8B,$7F,$73,$67,$5C,$50,$44,$38,$2C,$20,$14,$08
    DB $00,$07,$13,$1E,$2A,$36,$42,$4E,$59,$65,$71,$7C,$88,$94,$9F,$AB
    DB $B6,$C2,$CD,$D8,$E4,$EF,$F9,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F9,$EF,$E4,$D8,$CD,$C2
    DB $B6,$AB,$9F,$94,$88,$7C,$71,$65,$59,$4E,$42,$36,$2A,$1E,$13,$07
    DB $00,$05,$10,$1C,$28,$34,$3F,$4B,$57,$62,$6E,$79,$85,$90,$9C,$A7
    DB $B2,$BE,$C9,$D4,$DF,$E9,$F4,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$F4,$E9,$DF,$D4,$C9,$BE
    DB $B2,$A7,$9C,$90,$85,$79,$6E,$62,$57,$4B,$3F,$34,$28,$1C,$10,$05
    DB $00,$02,$0E,$1A,$25,$31,$3C,$48,$54,$5F,$6A,$76,$81,$8D,$98,$A3
    DB $AE,$B9,$C4,$CE,$D9,$E3,$ED,$F7,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F7,$ED,$E3,$D9,$CE,$C4,$B9
    DB $AE,$A3,$98,$8D,$81,$76,$6A,$5F,$54,$48,$3C,$31,$25,$1A,$0E,$02
    DB $00,$00,$0B,$17,$22,$2E,$39,$45,$50,$5B,$67,$72,$7D,$88,$93,$9E
    DB $A9,$B4,$BE,$C8,$D2,$DC,$E6,$EF,$F8,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8,$EF,$E6,$DC,$D2,$C8,$BE,$B4
    DB $A9,$9E,$93,$88,$7D,$72,$67,$5B,$50,$45,$39,$2E,$22,$17,$0B,$00
    DB $00,$00,$08,$13,$1F,$2A,$35,$41,$4C,$57,$62,$6D,$78,$83,$8E,$99
    DB $A3,$AE,$B8,$C2,$CC,$D5,$DE,$E7,$EF,$F7,$FE,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FE,$F7,$EF,$E7,$DE,$D5,$CC,$C2,$B8,$AE
    DB $A3,$99,$8E,$83,$78,$6D,$62,$57,$4C,$41,$35,$2A,$1F,$13,$08,$00
    DB $00,$00,$04,$0F,$1B,$26,$31,$3C,$48,$53,$5E,$68,$73,$7E,$88,$93
    DB $9D,$A7,$B1,$BB,$C4,$CD,$D6,$DE,$E6,$ED,$F4,$F9,$FE,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FE,$F9,$F4,$ED,$E6,$DE,$D6,$CD,$C4,$BB,$B1,$A7
    DB $9D,$93,$88,$7E,$73,$68,$5E,$53,$48,$3C,$31,$26,$1B,$0F,$04,$00
    DB $00,$00,$00,$0B,$17,$22,$2D,$38,$43,$4E,$58,$63,$6E,$78,$82,$8D
    DB $97,$A0,$AA,$B3,$BC,$C5,$CD,$D5,$DC,$E3,$E9,$EF,$F3,$F7,$F9,$FB
    DB $FC,$FB,$F9,$F7,$F3,$EF,$E9,$E3,$DC,$D5,$CD,$C5,$BC,$B3,$AA,$A0
    DB $97,$8D,$82,$78,$6E,$63,$58,$4E,$43,$38,$2D,$22,$17,$0B,$00,$00
    DB $00,$00,$00,$07,$12,$1D,$28,$33,$3E,$48,$53,$5D,$68,$72,$7C,$86
    DB $90,$99,$A2,$AB,$B4,$BC,$C4,$CC,$D2,$D9,$DF,$E4,$E8,$EB,$EE,$EF
    DB $F0,$EF,$EE,$EB,$E8,$E4,$DF,$D9,$D2,$CC,$C4,$BC,$B4,$AB,$A2,$99
    DB $90,$86,$7C,$72,$68,$5D,$53,$48,$3E,$33,$28,$1D,$12,$07,$00,$00
    DB $00,$00,$00,$02,$0D,$18,$23,$2D,$38,$42,$4D,$57,$61,$6B,$75,$7F
    DB $88,$91,$9A,$A3,$AB,$B3,$BB,$C2,$C8,$CE,$D4,$D8,$DC,$DF,$E2,$E3
    DB $E4,$E3,$E2,$DF,$DC,$D8,$D4,$CE,$C8,$C2,$BB,$B3,$AB,$A3,$9A,$91
    DB $88,$7F,$75,$6B,$61,$57,$4D,$42,$38,$2D,$23,$18,$0D,$02,$00,$00
    DB $00,$00,$00,$00,$08,$13,$1D,$28,$32,$3C,$47,$51,$5B,$64,$6E,$77
    DB $80,$89,$92,$9A,$A2,$AA,$B1,$B8,$BE,$C4,$C9,$CD,$D1,$D4,$D6,$D7
    DB $D8,$D7,$D6,$D4,$D1,$CD,$C9,$C4,$BE,$B8,$B1,$AA,$A2,$9A,$92,$89
    DB $80,$77,$6E,$64,$5B,$51,$47,$3C,$32,$28,$1D,$13,$08,$00,$00,$00
    DB $00,$00,$00,$00,$02,$0D,$17,$22,$2C,$36,$40,$4A,$54,$5D,$66,$6F
    DB $78,$81,$89,$91,$99,$A0,$A7,$AE,$B4,$B9,$BE,$C2,$C5,$C8,$CA,$CB
    DB $CC,$CB,$CA,$C8,$C5,$C2,$BE,$B9,$B4,$AE,$A7,$A0,$99,$91,$89,$81
    DB $78,$6F,$66,$5D,$54,$4A,$40,$36,$2C,$22,$17,$0D,$02,$00,$00,$00
    DB $00,$00,$00,$00,$00,$07,$11,$1B,$25,$2F,$39,$43,$4C,$55,$5F,$67
    DB $70,$78,$80,$88,$90,$97,$9D,$A3,$A9,$AE,$B2,$B6,$BA,$BC,$BE,$BF
    DB $C0,$BF,$BE,$BC,$BA,$B6,$B2,$AE,$A9,$A3,$9D,$97,$90,$88,$80,$78
    DB $70,$67,$5F,$55,$4C,$43,$39,$2F,$25,$1B,$11,$07,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$01,$0B,$15,$1F,$28,$32,$3B,$45,$4E,$56,$5F
    DB $67,$6F,$77,$7F,$86,$8D,$93,$99,$9E,$A3,$A7,$AB,$AE,$B0,$B2,$B3
    DB $B4,$B3,$B2,$B0,$AE,$AB,$A7,$A3,$9E,$99,$93,$8D,$86,$7F,$77,$6F
    DB $67,$5F,$56,$4E,$45,$3B,$32,$28,$1F,$15,$0B,$01,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$04,$0E,$18,$21,$2A,$34,$3D,$45,$4E,$56
    DB $5F,$66,$6E,$75,$7C,$82,$88,$8E,$93,$98,$9C,$9F,$A2,$A5,$A6,$A7
    DB $A8,$A7,$A6,$A5,$A2,$9F,$9C,$98,$93,$8E,$88,$82,$7C,$75,$6E,$66
    DB $5F,$56,$4E,$45,$3D,$34,$2A,$21,$18,$0E,$04,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$07,$10,$1A,$23,$2C,$34,$3D,$45,$4E
    DB $55,$5D,$64,$6B,$72,$78,$7E,$83,$88,$8D,$90,$94,$97,$99,$9A,$9B
    DB $9C,$9B,$9A,$99,$97,$94,$90,$8D,$88,$83,$7E,$78,$72,$6B,$64,$5D
    DB $55,$4E,$45,$3D,$34,$2C,$23,$1A,$10,$07,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$09,$12,$1B,$24,$2C,$34,$3D,$45
    DB $4C,$54,$5B,$61,$68,$6E,$73,$78,$7D,$81,$85,$88,$8B,$8D,$8E,$8F
    DB $90,$8F,$8E,$8D,$8B,$88,$85,$81,$7D,$78,$73,$6E,$68,$61,$5B,$54
    DB $4C,$45,$3D,$34,$2C,$24,$1B,$12,$09,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$01,$0A,$13,$1B,$24,$2C,$34,$3B
    DB $43,$4A,$51,$57,$5D,$63,$68,$6D,$72,$76,$79,$7C,$7F,$81,$82,$83
    DB $84,$83,$82,$81,$7F,$7C,$79,$76,$72,$6D,$68,$63,$5D,$57,$51,$4A
    DB $43,$3B,$34,$2C,$24,$1B,$13,$0A,$01,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$0A,$13,$1B,$23,$2A,$32
    DB $39,$40,$47,$4D,$53,$58,$5E,$62,$67,$6A,$6E,$71,$73,$75,$76,$77
    DB $78,$77,$76,$75,$73,$71,$6E,$6A,$67,$62,$5E,$58,$53,$4D,$47,$40
    DB $39,$32,$2A,$23,$1B,$13,$0A,$02,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$0A,$12,$1A,$21,$28
    DB $2F,$36,$3C,$42,$48,$4E,$53,$57,$5B,$5F,$62,$65,$67,$69,$6A,$6B
    DB $6C,$6B,$6A,$69,$67,$65,$62,$5F,$5B,$57,$53,$4E,$48,$42,$3C,$36
    DB $2F,$28,$21,$1A,$12,$0A,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$09,$10,$18,$1F
    DB $25,$2C,$32,$38,$3E,$43,$48,$4C,$50,$54,$57,$59,$5C,$5D,$5F,$5F
    DB $60,$5F,$5F,$5D,$5C,$59,$57,$54,$50,$4C,$48,$43,$3E,$38,$32,$2C
    DB $25,$1F,$18,$10,$09,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$0E,$15
    DB $1B,$22,$28,$2D,$33,$38,$3C,$41,$45,$48,$4B,$4E,$50,$51,$53,$53
    DB $54,$53,$53,$51,$50,$4E,$4B,$48,$45,$41,$3C,$38,$33,$2D,$28,$22
    DB $1B,$15,$0E,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$0B
    DB $11,$17,$1D,$23,$28,$2D,$31,$35,$39,$3C,$3F,$42,$44,$45,$47,$47
    DB $48,$47,$47,$45,$44,$42,$3F,$3C,$39,$35,$31,$2D,$28,$23,$1D,$17
    DB $11,$0B,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01
    DB $07,$0D,$13,$18,$1D,$22,$26,$2A,$2E,$31,$34,$36,$38,$3A,$3B,$3B
    DB $3C,$3B,$3B,$3A,$38,$36,$34,$31,$2E,$2A,$26,$22,$1D,$18,$13,$0D
    DB $07,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$02,$08,$0D,$12,$17,$1B,$1F,$22,$25,$28,$2A,$2C,$2E,$2F,$2F
    DB $30,$2F,$2F,$2E,$2C,$2A,$28,$25,$22,$1F,$1B,$17,$12,$0D,$08,$02
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$02,$07,$0B,$0F,$13,$17,$1A,$1C,$1E,$20,$22,$23,$23
    DB $24,$23,$23,$22,$20,$1E,$1C,$1A,$17,$13,$0F,$0B,$07,$02,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$04,$08,$0B,$0E,$10,$13,$14,$16,$17,$17
    DB $18,$17,$17,$16,$14,$13,$10,$0E,$0B,$08,$04,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$05,$07,$08,$0A,$0B,$0B
    DB $0C,$0B,$0B,$0A,$08,$07,$05,$02,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

;-------------------------------------------------------------------------------

Simulation_ServicesApplyMaskBig: ; e=x d=y (center)

    add     sp,-1

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ; Get top left corner

    ld      a,e
    sub     a,SERVICES_MASK_BIG_CENTER_X
    ld      e,a

    ld      a,d
    sub     a,SERVICES_MASK_BIG_CENTER_Y
    ld      d,a

    ld      hl,sp+0
    ld      [hl],e ; save left X

    ld      b,0 ; y
.loopy:
        ld      c,0 ; x
        ld      hl,sp+0
        ld      e,[hl] ; restore left x

.loopx:

        ld      a,e
        or      a,d
        and     a,128+64 ; ~63
        jr      nz,.skip

        push    bc
        push    de

            GET_MAP_ADDRESS ; e = x , d = y. preseves de and bc

            LD_DE_HL ; de = destination

            ld      l,b
            ld      h,0
            add     hl,hl ; TODO - Optimize this
            add     hl,hl
            add     hl,hl
            add     hl,hl
            add     hl,hl
            add     hl,hl ; b<<6 = b*64 (SERVICES_MASK_BIG_WIDTH)
IF SERVICES_MASK_BIG_WIDTH != 64
    FAIL "Fix this."
ENDC
            ld      a,c
            add     a,l ; y*32+x
            ld      l,a
            ld      bc,SERVICES_INFLUENCE_MASK_BIG
            add     hl,bc ; MASK + 32*y + x

            ld      a,[hl] ; new val
            and     a,a
            jr      z,.dont_add

            ; Add the previous value
            ld      b,a
            ld      a,[de]
            add     a,b
            jr      nc,.not_saturated
            ld      a,$FF ; saturate
.not_saturated:
            ld      [de],a ; save

.dont_add:

        pop     de
        pop     bc

.skip:

        inc     e
        inc     c
        ld      a,SERVICES_MASK_BIG_WIDTH
        cp      a,c
        jr      nz,.loopx

    inc     d
    inc     b
    ld      a,SERVICES_MASK_BIG_HEIGHT
    cp      a,b
    jr      nz,.loopy

    add     sp,+1

    ret

;-------------------------------------------------------------------------------

; Output data to WRAMX bank BANK_SCRATCH_RAM
Simulation_ServicesBig:: ; BC = central tile of the building (tileset_info.inc)

    add     sp,-2

    ld      hl,sp+0
    ld      [hl],b
    inc     hl
    ld      [hl],c

    ; Clean
    ; -----

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    call    ClearWRAMX

    ; For each tile check if it is the tile passed as argument
    ; --------------------------------------------------------

    ld      d,0 ; y
.loopy:
        ld      e,0 ; x
.loopx:
        push    de

        call    CityMapGetTile ; e = x , d = y. Returns tile = de

        ld      hl,sp+2
        ld      a,[hl+]
        cp      a,d
        jr      nz,.not_tile
        ld      a,[hl]
        cp      a,e
        jr      nz,.not_tile

            ; Desired tile found
            ; ------------------

            ; Check if there is power

            pop     de
            push    de
            GET_MAP_ADDRESS ; preserves de and bc

            ld      a,BANK_CITY_MAP_FLAGS
            ld      [rSVBK],a
            bit     TILE_OK_POWER_BIT,[hl]
            jr      z,.not_tile ; If there is no power, the building can't work

            call    Simulation_ServicesApplyMaskBig

.not_tile:

        pop     de

        inc     e
        ld      a,CITY_MAP_WIDTH
        cp      a,e
        jr      nz,.loopx

    inc     d
    ld      a,CITY_MAP_HEIGHT
    cp      a,d
    jr      nz,.loopy

    add     sp,+2

    ret

;###############################################################################

SERVICE_MIN_LEVEL EQU (256/4) ; Min level of adequate service coverage

;-------------------------------------------------------------------------------

Simulation_ServicesSetTileOkFlag::

    ; NOTE: Don't call when drawing minimaps, this can only be called from the
    ; simulation loop!

    ld      hl,CITY_MAP_FLAGS ; Base address of the map!

.loop:

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

        ld      a,[hl]
        and     a,TYPE_MASK

        ; Ignore non-building tiles - Set the tile!
        cp      a,TYPE_FIELD
        jr      z,.tile_set_flag
        cp      a,TYPE_FOREST
        jr      z,.tile_set_flag
        cp      a,TYPE_WATER
        jr      z,.tile_set_flag
        cp      a,TYPE_DOCK
        jr      z,.tile_set_flag

.check_service:

            ; Building, check!

            ld      a,BANK_SCRATCH_RAM
            ld      [rSVBK],a

            ld      a,[hl] ; Get coverage value

            cp      a,SERVICE_MIN_LEVEL ; carry flag is set if n > a
            jr      c,.tile_res_flag
            ;jr      .tile_set_flag

.tile_set_flag:
        ld      a,BANK_CITY_MAP_FLAGS
        ld      [rSVBK],a
        set     TILE_OK_SERVICES_BIT,[hl]
        jr      .tile_end

.tile_res_flag:
        ld      a,BANK_CITY_MAP_FLAGS
        ld      [rSVBK],a
        res     TILE_OK_SERVICES_BIT,[hl]
        ;jr      .tile_end

.tile_end:

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

;-------------------------------------------------------------------------------

; Like Simulation_ServicesSetTileOkFlag, but can only set to 1 if it was 1
; before.

Simulation_ServicesAddTileOkFlag::

    ; NOTE: Don't call when drawing minimaps, this can only be called from the
    ; simulation loop!

    ld      hl,CITY_MAP_FLAGS ; Base address of the map!

.loop:

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

        ld      a,[hl]
        and     a,TYPE_MASK

        ; Ignore non-building tiles - Set the flag!
        cp      a,TYPE_FIELD
        jr      z,.tile_set_flag
        cp      a,TYPE_FOREST
        jr      z,.tile_set_flag
        cp      a,TYPE_WATER
        jr      z,.tile_set_flag
        cp      a,TYPE_DOCK
        jr      z,.tile_set_flag

.check_service:

            ; Building, check!

            ld      a,BANK_SCRATCH_RAM
            ld      [rSVBK],a

            ld      a,[hl] ; Get coverage value

            cp      a,SERVICE_MIN_LEVEL ; carry flag is set if n > a
            jr      c,.tile_res_flag
            ;jr      .tile_set_flag

.tile_set_flag:
        ld      a,BANK_CITY_MAP_FLAGS
        ld      [rSVBK],a
        bit     TILE_OK_SERVICES_BIT,[hl]
        jr      z,.tile_end ; if it was 0, don't set to 1!
        set     TILE_OK_SERVICES_BIT,[hl]
        jr      .tile_end

.tile_res_flag:
        ld      a,BANK_CITY_MAP_FLAGS
        ld      [rSVBK],a
        res     TILE_OK_SERVICES_BIT,[hl]
        ;jr      .tile_end

.tile_end:

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

;-------------------------------------------------------------------------------

Simulation_EducationSetTileOkFlag::

    ; NOTE: Don't call when drawing minimaps, this can only be called from the
    ; simulation loop!

    ld      hl,CITY_MAP_FLAGS ; Base address of the map!

.loop:

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

        ld      a,[hl]
        and     a,TYPE_MASK

        ; Ignore non-residential tiles - Set the tile!
        cp      a,TYPE_RESIDENTIAL
        jr      nz,.tile_set_flag

.check_service:

            ; Residential, check!

            ld      a,BANK_SCRATCH_RAM
            ld      [rSVBK],a

            ld      a,[hl] ; Get coverage value

            cp      a,SERVICE_MIN_LEVEL ; carry flag is set if n > a
            jr      c,.tile_res_flag
            ;jr      .tile_set_flag

.tile_set_flag:
        ld      a,BANK_CITY_MAP_FLAGS
        ld      [rSVBK],a
        set     TILE_OK_EDUCATION_BIT,[hl]
        jr      .tile_end

.tile_res_flag:
        ld      a,BANK_CITY_MAP_FLAGS
        ld      [rSVBK],a
        res     TILE_OK_EDUCATION_BIT,[hl]
        ;jr      .tile_end

.tile_end:

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

;-------------------------------------------------------------------------------

; Like Simulation_EducationSetTileOkFlag, but can only set to 1 if it was 1
; before.

Simulation_EducationAddTileOkFlag::

    ; NOTE: Don't call when drawing minimaps, this can only be called from the
    ; simulation loop!

    ld      hl,CITY_MAP_FLAGS ; Base address of the map!

.loop:

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

        ld      a,[hl]
        and     a,TYPE_MASK

        ; Ignore non-residential tiles - Set the tile!
        cp      a,TYPE_RESIDENTIAL
        jr      nz,.tile_set_flag

.check_service:

            ; Residential, check!

            ld      a,BANK_SCRATCH_RAM
            ld      [rSVBK],a

            ld      a,[hl] ; Get coverage value

            cp      a,SERVICE_MIN_LEVEL ; carry flag is set if n > a
            jr      c,.tile_res_flag
            ;jr      .tile_set_flag

.tile_set_flag:
        ld      a,BANK_CITY_MAP_FLAGS
        ld      [rSVBK],a
        bit     TILE_OK_EDUCATION_BIT,[hl]
        jr      z,.tile_end ; if it was 0, don't set to 1!
        set     TILE_OK_EDUCATION_BIT,[hl]
        jr      .tile_end

.tile_res_flag:
        ld      a,BANK_CITY_MAP_FLAGS
        ld      [rSVBK],a
        res     TILE_OK_EDUCATION_BIT,[hl]
        ;jr      .tile_end

.tile_end:

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ret

;###############################################################################
