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
    INCLUDE "money.inc"
    INCLUDE "tileset_info.inc"

;###############################################################################

    SECTION "Simulation Calculate Money Variables",WRAM0

;-------------------------------------------------------------------------------

; Only 3 bytes needed of BCD data. LSB first
; Max amount of money per tile * tiles in map = 99*64*64 = 175890 = 3 BCD bytes

taxes_rci::         DS 3 ; Residential, commercial, industrial
taxes_other::       DS 3 ; Stadium, airport, seaport
budget_police::     DS 3
budget_firemen::    DS 3
budget_healthcare:: DS 3 ; Hospital, park
budget_education::  DS 3 ; School, high school, university, museum, library
budget_transport::  DS 3 ; Road, train tracks

budget_result::     DS 5

tax_percentage::    DS 1

;###############################################################################

    SECTION "Simulation Calculate Money Functions",ROMX

;###############################################################################

CITY_TILE_MONEY_COST_SIZE EQU 1

CURTILE       SET 0
MONEY_AMOUNT  SET 0

; Tile Add - Base tile of the building to add information of
;            Will only fill the building when the next one is added!
T_ADD : MACRO ; 1=Tile index, 2=Money amount

    IF (\1) < CURTILE ; check if going backwards and stop if so
        FAIL "ERROR : simulation_money.asm : Tile already in use!"
    ENDC

    ; Fill previous building
    IF (\1) > CURTILE ; In the first call all are 0 and this has to be skipped
        REPT (\1) - CURTILE
            DB MONEY_AMOUNT
        ENDR
    ENDC

    ; Set parameters for this building
CURTILE       SET (\1)
MONEY_AMOUNT  SET (\2)

ENDM

;###############################################################################

IF CITY_TILE_MONEY_COST_SIZE != 1
    FAIL "Fix this!"
ENDC

; Cost and income is per-tile. The amount can be 0-$99 (BCD, watch out!)
CITY_TILE_MONEY_COST:: ; 512 entries - BCD - LSB first - Cost / Income

    T_ADD   T_GRASS__FOREST_TL, 0
    T_ADD   T_GRASS__FOREST_TC, 0
    T_ADD   T_GRASS__FOREST_TR, 0
    T_ADD   T_GRASS__FOREST_CL, 0
    T_ADD   T_GRASS,            0
    T_ADD   T_GRASS__FOREST_CR, 0
    T_ADD   T_GRASS__FOREST_BL, 0
    T_ADD   T_GRASS__FOREST_BC, 0
    T_ADD   T_GRASS__FOREST_BR, 0
    T_ADD   T_GRASS__FOREST_CORNER_TL, 0
    T_ADD   T_GRASS__FOREST_CORNER_TR, 0
    T_ADD   T_GRASS__FOREST_CORNER_BL, 0
    T_ADD   T_GRASS__FOREST_CORNER_BR, 0
    T_ADD   T_FOREST,       0
    T_ADD   T_GRASS_EXTRA,  0
    T_ADD   T_FOREST_EXTRA, 0

    T_ADD   T_WATER__GRASS_TL, 0
    T_ADD   T_WATER__GRASS_TC, 0
    T_ADD   T_WATER__GRASS_TR, 0
    T_ADD   T_WATER__GRASS_CL, 0
    T_ADD   T_WATER,           0
    T_ADD   T_WATER__GRASS_CR, 0
    T_ADD   T_WATER__GRASS_BL, 0
    T_ADD   T_WATER__GRASS_BC, 0
    T_ADD   T_WATER__GRASS_BR, 0
    T_ADD   T_WATER__GRASS_CORNER_TL, 0
    T_ADD   T_WATER__GRASS_CORNER_TR, 0
    T_ADD   T_WATER__GRASS_CORNER_BL, 0
    T_ADD   T_WATER__GRASS_CORNER_BR, 0
    T_ADD   T_WATER_EXTRA, 0

    T_ADD   T_RESIDENTIAL, $1
    T_ADD   T_COMMERCIAL,  $1
    T_ADD   T_INDUSTRIAL,  $1
    T_ADD   T_DEMOLISHED,  0

ROAD_MAINTENANCE  EQU $1
TRAIN_MAINTENANCE EQU $2
POWER_MAINTENANCE EQU $1

    T_ADD   T_ROAD_TB,   ROAD_MAINTENANCE
    T_ADD   T_ROAD_TB_1, ROAD_MAINTENANCE
    T_ADD   T_ROAD_TB_2, ROAD_MAINTENANCE
    T_ADD   T_ROAD_TB_3, ROAD_MAINTENANCE
    T_ADD   T_ROAD_LR,   ROAD_MAINTENANCE
    T_ADD   T_ROAD_LR_1, ROAD_MAINTENANCE
    T_ADD   T_ROAD_LR_2, ROAD_MAINTENANCE
    T_ADD   T_ROAD_LR_3, ROAD_MAINTENANCE
    T_ADD   T_ROAD_RB,   ROAD_MAINTENANCE
    T_ADD   T_ROAD_LB,   ROAD_MAINTENANCE
    T_ADD   T_ROAD_TR,   ROAD_MAINTENANCE
    T_ADD   T_ROAD_TL,   ROAD_MAINTENANCE
    T_ADD   T_ROAD_TRB,  ROAD_MAINTENANCE
    T_ADD   T_ROAD_LRB,  ROAD_MAINTENANCE
    T_ADD   T_ROAD_TLB,  ROAD_MAINTENANCE
    T_ADD   T_ROAD_TLR,  ROAD_MAINTENANCE
    T_ADD   T_ROAD_TLRB, ROAD_MAINTENANCE
    T_ADD   T_ROAD_TB_POWER_LINES, ROAD_MAINTENANCE+POWER_MAINTENANCE
    T_ADD   T_ROAD_LR_POWER_LINES, ROAD_MAINTENANCE+POWER_MAINTENANCE
    T_ADD   T_ROAD_TB_BRIDGE, ROAD_MAINTENANCE*2
    T_ADD   T_ROAD_LR_BRIDGE, ROAD_MAINTENANCE*2

    T_ADD   T_TRAIN_TB,   TRAIN_MAINTENANCE
    T_ADD   T_TRAIN_LR,   TRAIN_MAINTENANCE
    T_ADD   T_TRAIN_RB,   TRAIN_MAINTENANCE
    T_ADD   T_TRAIN_LB,   TRAIN_MAINTENANCE
    T_ADD   T_TRAIN_TR,   TRAIN_MAINTENANCE
    T_ADD   T_TRAIN_TL,   TRAIN_MAINTENANCE
    T_ADD   T_TRAIN_TRB,  TRAIN_MAINTENANCE
    T_ADD   T_TRAIN_LRB,  TRAIN_MAINTENANCE
    T_ADD   T_TRAIN_TLB,  TRAIN_MAINTENANCE
    T_ADD   T_TRAIN_TLR,  TRAIN_MAINTENANCE
    T_ADD   T_TRAIN_TLRB, TRAIN_MAINTENANCE
    T_ADD   T_TRAIN_LR_ROAD, TRAIN_MAINTENANCE+ROAD_MAINTENANCE
    T_ADD   T_TRAIN_TB_ROAD, TRAIN_MAINTENANCE+ROAD_MAINTENANCE
    T_ADD   T_TRAIN_TB_POWER_LINES, TRAIN_MAINTENANCE+POWER_MAINTENANCE
    T_ADD   T_TRAIN_LR_POWER_LINES, TRAIN_MAINTENANCE+POWER_MAINTENANCE
    T_ADD   T_TRAIN_TB_BRIDGE, TRAIN_MAINTENANCE*2
    T_ADD   T_TRAIN_LR_BRIDGE, TRAIN_MAINTENANCE*2

    T_ADD   T_POWER_LINES_TB,   POWER_MAINTENANCE
    T_ADD   T_POWER_LINES_LR,   POWER_MAINTENANCE
    T_ADD   T_POWER_LINES_RB,   POWER_MAINTENANCE
    T_ADD   T_POWER_LINES_LB,   POWER_MAINTENANCE
    T_ADD   T_POWER_LINES_TR,   POWER_MAINTENANCE
    T_ADD   T_POWER_LINES_TL,   POWER_MAINTENANCE
    T_ADD   T_POWER_LINES_TRB,  POWER_MAINTENANCE
    T_ADD   T_POWER_LINES_LRB,  POWER_MAINTENANCE
    T_ADD   T_POWER_LINES_TLB,  POWER_MAINTENANCE
    T_ADD   T_POWER_LINES_TLR,  POWER_MAINTENANCE
    T_ADD   T_POWER_LINES_TLRB, POWER_MAINTENANCE
    T_ADD   T_POWER_LINES_TB_BRIDGE, POWER_MAINTENANCE*2
    T_ADD   T_POWER_LINES_LR_BRIDGE, POWER_MAINTENANCE*2

    T_ADD   T_POLICE_DEPT, $10
    T_ADD   T_FIRE_DEPT,   $10
    T_ADD   T_HOSPITAL,    $20

    T_ADD   T_PARK_SMALL, $5 ; Cost
    T_ADD   T_PARK_BIG,   $5 ; Cost
    T_ADD   T_STADIUM,   $30 ; Income

    T_ADD   T_SCHOOL,       $5 ; Cost
    T_ADD   T_HIGH_SCHOOL, $10
    T_ADD   T_UNIVERSITY,  $20
    T_ADD   T_MUSEUM,       $7
    T_ADD   T_LIBRARY,      $6

    T_ADD   T_AIRPORT,     $40 ; Income
    T_ADD   T_PORT,        $50 ; Income
    T_ADD   T_PORT_WATER_L, $0
    T_ADD   T_PORT_WATER_R, $0
    T_ADD   T_PORT_WATER_D, $0
    T_ADD   T_PORT_WATER_U, $0

    T_ADD   T_POWER_PLANT_COAL,    $0
    T_ADD   T_POWER_PLANT_OIL,     $0
    T_ADD   T_POWER_PLANT_WIND,    $0
    T_ADD   T_POWER_PLANT_SOLAR,   $0
    T_ADD   T_POWER_PLANT_NUCLEAR, $0
    T_ADD   T_POWER_PLANT_FUSION,  $0

    T_ADD   T_RESIDENTIAL_S1_A, $6
    T_ADD   T_RESIDENTIAL_S1_B, $7
    T_ADD   T_RESIDENTIAL_S1_C, $8
    T_ADD   T_RESIDENTIAL_S1_D, $8

    T_ADD   T_RESIDENTIAL_S2_A, $10
    T_ADD   T_RESIDENTIAL_S2_B, $12
    T_ADD   T_RESIDENTIAL_S2_C, $13
    T_ADD   T_RESIDENTIAL_S2_D, $15

    T_ADD   T_RESIDENTIAL_S3_A, $20
    T_ADD   T_RESIDENTIAL_S3_B, $21
    T_ADD   T_RESIDENTIAL_S3_C, $22
    T_ADD   T_RESIDENTIAL_S3_D, $24

    T_ADD   T_COMMERCIAL_S1_A, $8
    T_ADD   T_COMMERCIAL_S1_B, $8
    T_ADD   T_COMMERCIAL_S1_C, $9
    T_ADD   T_COMMERCIAL_S1_D, $10

    T_ADD   T_COMMERCIAL_S2_A, $10
    T_ADD   T_COMMERCIAL_S2_B, $12
    T_ADD   T_COMMERCIAL_S2_C, $14
    T_ADD   T_COMMERCIAL_S2_D, $16

    T_ADD   T_COMMERCIAL_S3_A, $23
    T_ADD   T_COMMERCIAL_S3_B, $24
    T_ADD   T_COMMERCIAL_S3_C, $25
    T_ADD   T_COMMERCIAL_S3_D, $27

    T_ADD   T_INDUSTRIAL_S1_A, $9
    T_ADD   T_INDUSTRIAL_S1_B, $9
    T_ADD   T_INDUSTRIAL_S1_C, $10
    T_ADD   T_INDUSTRIAL_S1_D, $11

    T_ADD   T_INDUSTRIAL_S2_A, $14
    T_ADD   T_INDUSTRIAL_S2_B, $15
    T_ADD   T_INDUSTRIAL_S2_C, $17
    T_ADD   T_INDUSTRIAL_S2_D, $18

    T_ADD   T_INDUSTRIAL_S3_A, $24
    T_ADD   T_INDUSTRIAL_S3_B, $26
    T_ADD   T_INDUSTRIAL_S3_C, $27
    T_ADD   T_INDUSTRIAL_S3_D, $30

    T_ADD   T_FIRE_1, 0
    T_ADD   T_FIRE_2, 0

    T_ADD   T_RADIATION_GROUND, 0
    T_ADD   T_RADIATION_WATER,  0

    T_ADD   512, 0 ; Fill array

;###############################################################################

tile_money_destination: ; Pointer to variable to add money. LSB first
    DW  budget_transport  ; TYPE_FIELD - Roads, train tracks, power lines
    DW  taxes_other       ; TYPE_FOREST
    DW  budget_transport  ; TYPE_WATER - Bridges
    DW  taxes_rci         ; TYPE_RESIDENTIAL
    DW  taxes_rci         ; TYPE_INDUSTRIAL
    DW  taxes_rci         ; TYPE_COMMERCIAL
    DW  budget_police     ; TYPE_POLICE_DEPT
    DW  budget_firemen    ; TYPE_FIRE_DEPT
    DW  budget_healthcare ; TYPE_HOSPITAL
    DW  budget_healthcare ; TYPE_PARK
    DW  taxes_other       ; TYPE_STADIUM
    DW  budget_education  ; TYPE_SCHOOL
    DW  budget_education  ; TYPE_HIGH_SCHOOL
    DW  budget_education  ; TYPE_UNIVERSITY
    DW  budget_education  ; TYPE_MUSEUM
    DW  budget_education  ; TYPE_LIBRARY
    DW  taxes_other       ; TYPE_AIRPORT
    DW  taxes_other       ; TYPE_PORT
    DW  taxes_other       ; TYPE_DOCK
    DW  taxes_other       ; TYPE_POWER_PLANT
    DW  taxes_other       ; TYPE_FIRE
    DW  taxes_other       ; TYPE_RADIATION
    ; End of valid types...

;-------------------------------------------------------------------------------

Simulation_CalculateBudgetAndTaxes::

    ; Clear variables
    ; ---------------

    xor     a,a

    ld      hl,taxes_rci
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a

    ld      hl,taxes_other
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a

    ld      hl,budget_police
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a

    ld      hl,budget_firemen
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a

    ld      hl,budget_healthcare
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a

    ld      hl,budget_education
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a

    ld      hl,budget_transport
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a

    ; Calculate taxes and budget
    ; --------------------------

    ld      hl,CITY_MAP_TILES

.loop:
    push    hl

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

        ld      a,[hl] ; get type
        and     a,TYPE_MASK ; without flags!

        ld      c,a ; (*) c = type with no flags

        ; Returns: - Tile -> Register DE
        call    CityMapGetTileAtAddress ; Arg: hl = address. Preserves BC, HL

        ; (*) c = type with no flags

IF CITY_TILE_MONEY_COST_SIZE != 1
    FAIL "Fix this!"
ENDC

        ld      hl,CITY_TILE_MONEY_COST ; BCD - LSB first - Cost / Income
        add     hl,de

        ld      e,[hl] ; get cost/income

        ; e = cost
        ; c = type with no flags

        ld      hl,tile_money_destination ; LSB first
        ld      b,0 ; bc = type
        add     hl,bc
        add     hl,bc
        ld      a,[hl+]
        ld      h,[hl]
        ld      l,a

        ; hl = pointer to money destination variable
        ; e = cost

        ld      d,0 ; zero helper register
        ld      a,e
        add     a,[hl]
        daa ; BCD
        ld      [hl+],a

        ld      a,d ; zero
        adc     a,[hl]
        daa ; BCD
        ld      [hl+],a

        ld      a,d ; zero
        adc     a,[hl]
        daa ; BCD
        ld      [hl+],a

    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ; Adjust taxes according to the tax percentage
    ; --------------------------------------------

    ; 10% = base cost => Final cost = base cost * tax / 10

    add     sp,-4 ; (**) reserve space for temporary calculations + 1 byte

MULTIPLY_TAX : MACRO ; \1 = pointer to the amount to multiply
    xor     a,a
    ld      hl,sp+0
    REPT    4
    ld      [hl+],a
    ENDR

    ld      a,[tax_percentage] ; multiply base cost
    and     a,a
    jr      z,.end_addition\@
    ld      c,a
.loop_addition\@:

        ld      de,\1
        ld      hl,sp+0

        scf
        ccf ; clear carry flag

        REPT    3 ; add
            ld      a,[de]
            adc     a,[hl]
            daa
            ld      [hl+],a
            inc     de
        ENDR

        ld      a,0
        adc     a,[hl]
        daa
        ld      [hl+],a

    dec     c
    jr      nz,.loop_addition\@
.end_addition\@:

    ; Divide by 10

    ld      de,\1
    ld      hl,sp+0

    ld      a,[hl+]
    swap    a
    and     a,$0F
    ld      b,a

    ld      a,[hl+]
    ld      c,a

    and     a,$0F
    swap    a
    or      a,b

    ld      [de],a
    inc     de


    ld      a,c
    swap    a
    and     a,$0F
    ld      b,a

    ld      a,[hl+]
    ld      c,a

    and     a,$0F
    swap    a
    or      a,b

    ld      [de],a
    inc     de


    ld      a,c
    swap    a
    and     a,$0F
    ld      b,a

    ld      a,[hl]

    and     a,$0F
    swap    a
    or      a,b

    ld      [de],a
ENDM

    MULTIPLY_TAX    taxes_rci
    MULTIPLY_TAX    taxes_other

    add     sp,+4 ; (**) reclaim space

    ; Calculate total budget
    ; ----------------------

    add     sp,-MONEY_AMOUNT_SIZE*2 ; (*) save space for 2 money amounts

MONEY_DEST EQU 0 ; add to sp to get the pointer to this variable
MONEY_TEMP EQU 5

EXPAND_MONEY : MACRO ; de = ptr to 3 byte amount, hl = ptr to 5 byte dest
    REPT    3
        ld      a,[de]
        ld      [hl+],a
        inc     de
    ENDR
    xor     a,a
    ld      [hl+],a
    ld      [hl+],a
ENDM

    ; Clear destination variable

    xor     a,a
    ld      hl,sp+MONEY_DEST
    REPT    MONEY_AMOUNT_SIZE
        ld      [hl+],a
    ENDR

ADD_TAXES : MACRO ; \1 = pointer to 3-byte money amount
    ld      de,\1
    ld      hl,sp+MONEY_TEMP
    EXPAND_MONEY

    ld      hl,sp+MONEY_TEMP
    LD_DE_HL
    ld      hl,sp+MONEY_DEST
    call    BCD_HL_ADD_DE ; [hl] = [hl] + [de]
ENDM

    ; Add RCI taxes
    ADD_TAXES   taxes_rci

    ; Add other taxes
    ADD_TAXES   taxes_other

PAY_COST : MACRO ; \1 = pointer to 3-byte money amount
    ld      de,\1
    ld      hl,sp+MONEY_TEMP
    EXPAND_MONEY

    ld      hl,sp+MONEY_DEST
    LD_DE_HL
    ld      hl,sp+MONEY_TEMP
    call    BCD_HL_SUB_DE ; [de] = [de] - [hl]
ENDM

    ; Pay police
    PAY_COST    budget_police

    ; Pay firemen
    PAY_COST    budget_firemen

    ; Pay healthcare
    PAY_COST    budget_healthcare

    ; Pay education
    PAY_COST    budget_education

    ; Pay transport
    PAY_COST    budget_transport

    ; Pay loans
    ld      a,[LOAN_REMAINING_PAYMENTS]
    and     a,a ; Decrement when applying budget
    jr      z,.skip_loan ; skip if no loan active

        ld      hl,sp+MONEY_TEMP
        ld      a,[LOAN_PAYMENTS_AMOUNT+0] ; BCD, LSB first
        ld      [hl+],a
        ld      a,[LOAN_PAYMENTS_AMOUNT+1]
        ld      [hl+],a
        xor     a,a
        REPT    3
        ld      [hl+],a
        ENDR

        ld      hl,sp+MONEY_DEST
        LD_DE_HL
        ld      hl,sp+MONEY_TEMP
        call    BCD_HL_SUB_DE ; [de] = [de] - [hl]

.skip_loan:

    ; Save result
    ld      de,budget_result
    ld      hl,sp+MONEY_DEST
    REPT    MONEY_AMOUNT_SIZE
        ld      a,[hl+]
        ld      [de],a
        inc     de
    ENDR

    add     sp,+MONEY_AMOUNT_SIZE*2 ; (*) reclaim space

    ret

;-------------------------------------------------------------------------------

Simulation_ApplyBudgetAndTaxes::

    ; Add temp variable to original amount of money

    ld      de,budget_result
    call    MoneyAdd ; de = ptr to the amount of money to add.

    ; Reduce number of remaining loan payments

    ld      a,[LOAN_REMAINING_PAYMENTS]
    and     a,a
    jr      z,.skip_loan ; skip if no loan active

        dec     a
        ld      [LOAN_REMAINING_PAYMENTS],a

.skip_loan:

    ret

;###############################################################################
