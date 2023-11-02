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
    INCLUDE "engine.inc"

;-------------------------------------------------------------------------------

    INCLUDE "room_graphs.inc"

;###############################################################################

    SECTION "Graph Handling Data",WRAM0

;-------------------------------------------------------------------------------

GRAPH_POPULATION_DATA::   DS GRAPH_SIZE
GRAPH_POPULATION_OFFSET:: DS 1 ; Circular buffer start index
GRAPH_POPULATION_SCALE:   DS 1

GRAPH_RESIDENTIAL_DATA::   DS GRAPH_SIZE
GRAPH_RESIDENTIAL_OFFSET:: DS 1 ; Circular buffer start index
GRAPH_RESIDENTIAL_SCALE:   DS 1

GRAPH_COMMERCIAL_DATA::   DS GRAPH_SIZE
GRAPH_COMMERCIAL_OFFSET:: DS 1 ; Circular buffer start index
GRAPH_COMMERCIAL_SCALE:   DS 1

GRAPH_INDUSTRIAL_DATA::   DS GRAPH_SIZE
GRAPH_INDUSTRIAL_OFFSET:: DS 1 ; Circular buffer start index
GRAPH_INDUSTRIAL_SCALE:   DS 1

GRAPH_MONEY_DATA::   DS GRAPH_SIZE
GRAPH_MONEY_OFFSET:: DS 1 ; Circular buffer start index
GRAPH_MONEY_SCALE:   DS 1

;###############################################################################

    SECTION "Graph Handling Functions",ROMX

;-------------------------------------------------------------------------------

GraphsClearRecords:: ; Clear WRAM

    ; Total population graph

    ld      hl,GRAPH_POPULATION_DATA
    ld      a,GRAPH_INVALID_ENTRY
    ld      b,GRAPH_SIZE
    call    memset_fast ; a = value    hl = start address    b = size

    xor     a,a
    ld      [GRAPH_POPULATION_OFFSET],a
    ld      [GRAPH_POPULATION_SCALE],a

    ; Population per sectors graph

    ld      hl,GRAPH_RESIDENTIAL_DATA
    ld      a,GRAPH_INVALID_ENTRY
    ld      b,GRAPH_SIZE
    call    memset_fast ; a = value    hl = start address    b = size

    ld      hl,GRAPH_COMMERCIAL_DATA
    ld      a,GRAPH_INVALID_ENTRY
    ld      b,GRAPH_SIZE
    call    memset_fast ; a = value    hl = start address    b = size

    ld      hl,GRAPH_INDUSTRIAL_DATA
    ld      a,GRAPH_INVALID_ENTRY
    ld      b,GRAPH_SIZE
    call    memset_fast ; a = value    hl = start address    b = size

    xor     a,a
    ld      [GRAPH_RESIDENTIAL_OFFSET],a
    ld      [GRAPH_RESIDENTIAL_SCALE],a
    ld      [GRAPH_COMMERCIAL_OFFSET],a
    ld      [GRAPH_COMMERCIAL_SCALE],a
    ld      [GRAPH_INDUSTRIAL_OFFSET],a
    ld      [GRAPH_INDUSTRIAL_SCALE],a

    ; Money graph

    ld      hl,GRAPH_MONEY_DATA
    ld      a,GRAPH_INVALID_ENTRY
    ld      b,GRAPH_SIZE
    call    memset_fast ; a = value    hl = start address    b = size

    xor     a,a
    ld      [GRAPH_MONEY_OFFSET],a
    ld      [GRAPH_MONEY_SCALE],a

    ret

;-------------------------------------------------------------------------------

GraphsSaveRecords:: ; Save to SRAM - SRAM should be enabled!

    ; Total population graph

    ld      bc,GRAPH_SIZE
    ld      hl,GRAPH_POPULATION_DATA
    ld      de,SAV_GRAPH_POPULATION_DATA
    call    memcopy ; bc = size    hl = source address    de = dest address

    ld      a,[GRAPH_POPULATION_OFFSET]
    ld      [SAV_GRAPH_POPULATION_OFFSET],a
    ld      a,[GRAPH_POPULATION_SCALE]
    ld      [SAV_GRAPH_POPULATION_SCALE],a

    ; Population per sectors graph

    ld      bc,GRAPH_SIZE
    ld      hl,GRAPH_RESIDENTIAL_DATA
    ld      de,SAV_GRAPH_RESIDENTIAL_DATA
    call    memcopy ; bc = size    hl = source address    de = dest address
    ld      bc,GRAPH_SIZE
    ld      hl,GRAPH_COMMERCIAL_DATA
    ld      de,SAV_GRAPH_COMMERCIAL_DATA
    call    memcopy ; bc = size    hl = source address    de = dest address
    ld      bc,GRAPH_SIZE
    ld      hl,GRAPH_INDUSTRIAL_DATA
    ld      de,SAV_GRAPH_INDUSTRIAL_DATA
    call    memcopy ; bc = size    hl = source address    de = dest address

    ld      a,[GRAPH_RESIDENTIAL_OFFSET]
    ld      [SAV_GRAPH_RESIDENTIAL_OFFSET],a
    ld      a,[GRAPH_RESIDENTIAL_SCALE]
    ld      [SAV_GRAPH_RESIDENTIAL_SCALE],a
    ld      a,[GRAPH_COMMERCIAL_OFFSET]
    ld      [SAV_GRAPH_COMMERCIAL_OFFSET],a
    ld      a,[GRAPH_INDUSTRIAL_SCALE]
    ld      [SAV_GRAPH_INDUSTRIAL_SCALE],a

    ; Money graph

    ld      bc,GRAPH_SIZE
    ld      hl,GRAPH_MONEY_DATA
    ld      de,SAV_GRAPH_MONEY_DATA
    call    memcopy ; bc = size    hl = source address    de = dest address

    ld      a,[GRAPH_MONEY_OFFSET]
    ld      [SAV_GRAPH_MONEY_OFFSET],a
    ld      a,[GRAPH_MONEY_SCALE]
    ld      [SAV_GRAPH_MONEY_SCALE],a

    ret

;-------------------------------------------------------------------------------

GraphsLoadRecords:: ; Load from SRAM - SRAM should be enabled!

    ; Total population graph

    ld      bc,GRAPH_SIZE
    ld      de,GRAPH_POPULATION_DATA
    ld      hl,SAV_GRAPH_POPULATION_DATA
    call    memcopy ; bc = size    hl = source address    de = dest address

    ld      a,[SAV_GRAPH_POPULATION_OFFSET]
    ld      [GRAPH_POPULATION_OFFSET],a
    ld      a,[SAV_GRAPH_POPULATION_SCALE]
    ld      [GRAPH_POPULATION_SCALE],a

    ; Population per sectors graph

    ld      bc,GRAPH_SIZE
    ld      de,GRAPH_RESIDENTIAL_DATA
    ld      hl,SAV_GRAPH_RESIDENTIAL_DATA
    call    memcopy ; bc = size    hl = source address    de = dest address
    ld      bc,GRAPH_SIZE
    ld      de,GRAPH_COMMERCIAL_DATA
    ld      hl,SAV_GRAPH_COMMERCIAL_DATA
    call    memcopy ; bc = size    hl = source address    de = dest address
    ld      bc,GRAPH_SIZE
    ld      de,GRAPH_INDUSTRIAL_DATA
    ld      hl,SAV_GRAPH_INDUSTRIAL_DATA
    call    memcopy ; bc = size    hl = source address    de = dest address

    ld      a,[SAV_GRAPH_RESIDENTIAL_OFFSET]
    ld      [GRAPH_RESIDENTIAL_OFFSET],a
    ld      a,[SAV_GRAPH_RESIDENTIAL_SCALE]
    ld      [GRAPH_RESIDENTIAL_SCALE],a
    ld      a,[SAV_GRAPH_COMMERCIAL_OFFSET]
    ld      [GRAPH_COMMERCIAL_OFFSET],a
    ld      a,[SAV_GRAPH_INDUSTRIAL_SCALE]
    ld      [GRAPH_INDUSTRIAL_SCALE],a

    ; Money graph

    ld      bc,GRAPH_SIZE
    ld      de,GRAPH_MONEY_DATA
    ld      hl,SAV_GRAPH_MONEY_DATA
    call    memcopy ; bc = size    hl = source address    de = dest address

    ld      a,[SAV_GRAPH_MONEY_OFFSET]
    ld      [GRAPH_MONEY_OFFSET],a
    ld      a,[SAV_GRAPH_MONEY_SCALE]
    ld      [GRAPH_MONEY_SCALE],a

    ret

;-------------------------------------------------------------------------------

GraphHandleRecords::

    ; This calls the individual graph handling functions

    call    GraphTotalPopulationAddRecord

    call    GraphRCIAddRecord

    call    GraphMoneyAddRecord

    ret

;-------------------------------------------------------------------------------

SRL32: ; a = shift value, bcde = value (B = MSB, E = LSB), return value = bcde

    cp      a,32 ; cy = 1 if 32 > a  (a <= 31)
    jr      c,.not_trivial
        ld      bc,0 ; shift value too big, just return 0!
        ld      de,0
        ret
.not_trivial:

    bit     4,a
    jr      z,.not_16
        LD_DE_BC ; Shift by 16
        ld      bc,0
.not_16:
    bit     3,a
    jr      z,.not_8
        ld      e,d ; Shift by 8
        ld      d,c
        ld      c,b
        ld      b,0
.not_8:
    bit     2,a
    jr      z,.not_4
        REPT    4 ; Shift by 4
        sra     b
        rr      c
        rr      d
        rr      e
        ENDR
.not_4:
    bit     1,a
    jr      z,.not_2
        REPT    2 ; Shift by 2
        sra     b
        rr      c
        rr      d
        rr      e
        ENDR
.not_2:
    bit     0,a
    jr      z,.not_1
        sra     b ; Shift by 1
        rr      c
        rr      d
        rr      e
.not_1:

    ret

;-------------------------------------------------------------------------------

MACRO ADD_RECORD_POPULATION ; \1 = name in lowercase, \2 = name in uppercase

    ; Calculate value
    ; ---------------

.loop_calculate\@:

        ld      hl,population_\1 ; LSB first, 4 bytes
        ld      a,[hl+]
        ld      e,a
        ld      a,[hl+]
        ld      d,a
        ld      a,[hl+]
        ld      c,a
        ld      b,[hl]

        ld      a,[GRAPH_\2_SCALE]

        call    SRL32 ; a = shift value, bcde = value to shift

        ld      a,e
        and     a,$80
        or      a,d
        or      a,c
        or      a,b ; check if it fits in 127 (0000007F)
        jr      z,.end_loop\@

        ; If it is bigger than the scale, change scale and scale stored data

        ld      hl,GRAPH_\2_SCALE
        inc     [hl] ; no need to check, we are only shifting a 32 bit value
        ; so a shift by 32 should make anything fit in the graph.

        ; Divide by 2 the stored data

        ld      b,GRAPH_SIZE
        ld      hl,GRAPH_\2_DATA
.loop_scale_down\@:
        sra     [hl] ; GRAPH_INVALID_ENTRY == -1, it will be preserved
        inc     hl
        dec     b
        jr      nz,.loop_scale_down\@

    jr      .loop_calculate\@

.end_loop\@:

    ld      b,e ; b = value to save

    ; Finally, save this value
    ; ------------------------

    ld      a,[GRAPH_\2_OFFSET]
    ld      e,a
    ld      d,0
    ld      hl,GRAPH_\2_DATA
    add     hl,de ; hl = pointer to next entry

    ld      [hl],b

    ld      a,[GRAPH_\2_OFFSET]
    inc     a
    and     a,GRAPH_SIZE-1
    ld      [GRAPH_\2_OFFSET],a

ENDM

;-------------------------------------------------------------------------------

GraphTotalPopulationAddRecord:
    ADD_RECORD_POPULATION total, POPULATION
    ret

;-------------------------------------------------------------------------------

GraphRCIAddRecord:
    ADD_RECORD_POPULATION residential, RESIDENTIAL
    ADD_RECORD_POPULATION commercial,  COMMERCIAL
    ADD_RECORD_POPULATION industrial,  INDUSTRIAL
    ret

;-------------------------------------------------------------------------------

MultBy10: ; BCDE = value, returned value in BCDE, clobbers HL

    sla     e ; Shift by 1
    rl      d
    rl      c
    rl      b

    push    bc ; Push top 16 bit first, low 16 bits second. That way they will
    push    de ; be read in reverse order as we need.

    REPT    2
    sla     e ; Shift by 2
    rl      d
    rl      c
    rl      b
    ENDR

    ; BCDE  = value * 8
    ; STACK = value * 2

    pop     hl ; pop low 16 bits
    add     hl,de ; add low 16 bits
    jr      nc,.no_carry
    inc     bc ; increment top 16 bit if carry
.no_carry:
    LD_DE_HL ; move data back to its place

    pop     hl ; pop high 16 bits
    add     hl,bc ; add top 16 bits
    LD_BC_HL ; move data back to its place
    ; ignore overflows...

    ret

;-------------------------------------------------------------------------------

GraphMoneyAddRecord:

    ; Get BCD value and convert it to binary
    ; --------------------------------------

    ; If lower than 0, use 0!
    ld      de,MoneyWRAM
    call    BCD_DE_LW_ZERO ; returns a = 1 if [de] < 0
    and     a,a
    jr      z,.greater_than_zero

        ; Lower than zero
        ld      bc,0
        ld      de,0 ; use 0
        jp      .end_bcd_to_binary

.greater_than_zero:

MACRO BCDE_ADD_A ; BCDE += A
    add     a,e
    ld      e,a
    ld      a,0
    adc     a,d
    ld      d,a
    jr      nc,.no_carry\@
    inc     bc
.no_carry\@:
ENDM

MACRO BCD_2_BIN_ADD_LOW_NIBBLE ; \1 = byte inside money array
    call    MultBy10 ; BCDE = value, returned value in BCDE, clobbers HL

    ld      a,[MoneyWRAM+\1]
    and     a,$0F

    BCDE_ADD_A ; BCDE += A
ENDM

MACRO BCD_2_BIN_ADD_HIGH_NIBBLE ; \1 = byte inside money array
    call    MultBy10 ; BCDE = value, returned value in BCDE, clobbers HL

    ld      a,[MoneyWRAM+\1]
    swap    a
    and     a,$0F

    BCDE_ADD_A ; BCDE += A
ENDM

    ld      bc,0
    ld      de,0 ; Accumulated binary value = 0

    ; for each nibble from MSB to LSB
    ;     value = value * 10 + nibble

    BCD_2_BIN_ADD_LOW_NIBBLE  4 ; Only low nibble of byte 4
    BCD_2_BIN_ADD_HIGH_NIBBLE 3
    BCD_2_BIN_ADD_LOW_NIBBLE  3
    BCD_2_BIN_ADD_HIGH_NIBBLE 2
    BCD_2_BIN_ADD_LOW_NIBBLE  2
    BCD_2_BIN_ADD_HIGH_NIBBLE 1
    BCD_2_BIN_ADD_LOW_NIBBLE  1
    BCD_2_BIN_ADD_HIGH_NIBBLE 0
    BCD_2_BIN_ADD_LOW_NIBBLE  0

.end_bcd_to_binary:

    ; BCDE = current money in binary!

    ; Now, add scaled value to graphic

    ; Calculate value
    ; ---------------

.loop_calculate:

        push    bc ; Preserve value for next iteration of the loop
        push    de ; (*12)

        ld      a,[GRAPH_MONEY_SCALE]

        call    SRL32 ; a = shift value, bcde = value to shift

        ld      a,e
        and     a,$80
        or      a,d
        or      a,c
        or      a,b ; check if it fits in 127 (0000007F)
        jr      z,.end_loop

        ; If it is bigger than the scale, change scale and scale stored data

        ld      hl,GRAPH_MONEY_SCALE
        inc     [hl] ; no need to check, we are only shifting a 32 bit value
        ; so a shift by 32 should make anything fit in the graph.

        ; Divide by 2 the stored data

        ld      b,GRAPH_SIZE
        ld      hl,GRAPH_MONEY_DATA
.loop_scale_down:
        sra     [hl] ; GRAPH_INVALID_ENTRY == -1, it will be preserved
        inc     hl
        dec     b
        jr      nz,.loop_scale_down

        pop     de ; (*1)
        pop     bc

    jr      .loop_calculate

.end_loop:

    add     sp,+4 ; (*2)

    ld      b,e ; b = value to save

    ; Finally, save this value
    ; ------------------------

    ld      a,[GRAPH_MONEY_OFFSET]
    ld      e,a
    ld      d,0
    ld      hl,GRAPH_MONEY_DATA
    add     hl,de ; hl = pointer to next entry

    ld      [hl],b

    ld      a,[GRAPH_MONEY_OFFSET]
    inc     a
    and     a,GRAPH_SIZE-1
    ld      [GRAPH_MONEY_OFFSET],a

    ret

;###############################################################################
