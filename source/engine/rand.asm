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

    INCLUDE "hardware.inc"

;###############################################################################
;#                                                                             #
;#                                   RANDOM                                    #
;#                                                                             #
;###############################################################################

    SECTION "RandomLUT",ROM0,ALIGN[8]

;-------------------------------------------------------------------------------

_Random:
    DB $29,$23,$be,$84,$e1,$6c,$d6,$ae,$52,$90,$49,$f1,$f1,$bb,$e9,$eb
    DB $b3,$a6,$db,$3c,$87,$0c,$3e,$99,$24,$5e,$0d,$1c,$06,$b7,$47,$de
    DB $b3,$12,$4d,$c8,$43,$bb,$8b,$a6,$1f,$03,$5a,$7d,$09,$38,$25,$1f
    DB $5d,$d4,$cb,$fc,$96,$f5,$45,$3b,$13,$0d,$89,$0a,$1c,$db,$ae,$32
    DB $20,$9a,$50,$ee,$40,$78,$36,$fd,$12,$49,$32,$f6,$9e,$7d,$49,$dc
    DB $ad,$4f,$14,$f2,$44,$40,$66,$d0,$6b,$c4,$30,$b7,$32,$3b,$a1,$22
    DB $f6,$22,$91,$9d,$e1,$8b,$1f,$da,$b0,$ca,$99,$02,$b9,$72,$9d,$49
    DB $2c,$80,$7e,$c5,$99,$d5,$e9,$80,$b2,$ea,$c9,$cc,$53,$bf,$67,$d6
    DB $bf,$14,$d6,$7e,$2d,$dc,$8e,$66,$83,$ef,$57,$49,$61,$ff,$69,$8f
    DB $61,$cd,$d1,$1e,$9d,$9c,$16,$72,$72,$e6,$1d,$f0,$84,$4f,$4a,$77
    DB $02,$d7,$e8,$39,$2c,$53,$cb,$c9,$12,$1e,$33,$74,$9e,$0c,$f4,$d5
    DB $d4,$9f,$d4,$a4,$59,$7e,$35,$cf,$32,$22,$f4,$cc,$cf,$d3,$90,$2d
    DB $48,$d3,$8f,$75,$e6,$d9,$1d,$2a,$e5,$c0,$f7,$2b,$78,$81,$87,$44
    DB $0e,$5f,$50,$00,$d4,$61,$8d,$be,$7b,$05,$15,$07,$3b,$33,$82,$1f
    DB $18,$70,$92,$da,$64,$54,$ce,$b1,$85,$3e,$69,$15,$f8,$46,$6a,$04
    DB $96,$73,$0e,$d9,$16,$2f,$67,$68,$d4,$f7,$4a,$4a,$d0,$57,$68,$76

;###############################################################################

    SECTION "RandomPtr",WRAM0

;-------------------------------------------------------------------------------

random_ptr: DS 1

;###############################################################################

    SECTION "RandomFunction",ROM0

;-------------------------------------------------------------------------------

; bc and de preserved
GetRandom::

    ld      hl,random_ptr
    ld      l,[hl]
    ld      h,_Random>>8

    ldh     a,[rDIV]
    xor     a,[hl]

    inc     l
    add     a,[hl]

    ld      hl,random_ptr
    ld      [hl],a

    ret

;-------------------------------------------------------------------------------

SetRandomSeed::

    ld      [random_ptr],a
    ret

;Check if it generates every number
;----------------------------------
;
;    ld      b,0
;.next
;    call GetRandom
;    cp      b
;    jr      nz,.next
;    inc     b
;    xor     a,a
;    cp      b
;    jr      z,.end
;    jr     .next
;.end

;###############################################################################
