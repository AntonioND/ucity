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
    INCLUDE "money.inc"
    INCLUDE "tileset_info.inc"

;###############################################################################

    SECTION "Simulation Calculate Statistics Variables",WRAM0

;-------------------------------------------------------------------------------

city_type:: DS 1 ; TYPE_CITY, etc

city_population:: DS 5 ; BCD, LSB first!
city_population_temp: DS 5 ; BCD, LSB first!

; Internal variables used to calculate the demmand of RCI zones (and RCI graph)
population_residential:: DS 4 ; binary, LSB first
population_commercial::  DS 4 ; binary, LSB first
population_industrial::  DS 4 ; binary, LSB first
population_other::       DS 4 ; binary, LSB first

residential_area_empty: DS 2 ; LSB first. Area in tiles
residential_area_used:  DS 2
commercial_area_empty:  DS 2
commercial_area_used:   DS 2
industrial_area_empty:  DS 2
industrial_area_used:   DS 2

graph_value_r:: DS 1 ; 0-7 (0 = high demand, 3,4 = neutral, 7 = low demand)
graph_value_c:: DS 1 ; They are stored with an offset of -3 to make 0 the
graph_value_i:: DS 1 ; central value

;###############################################################################

    SECTION "Simulation Calculate Statistics Functions",ROMX[$4000]

;-------------------------------------------------------------------------------

; Must be alligned to $100
tile_rci_population_pointer: ; Pointer to variable to add population. LSB first
    DW  population_other ; TYPE_FIELD - No population, but don't set the
    DW  population_other ; TYPE_FOREST  to NULL.
    DW  population_other ; TYPE_WATER
    DW  population_residential ; TYPE_RESIDENTIAL
    DW  population_industrial ; TYPE_INDUSTRIAL
    DW  population_commercial ; TYPE_COMMERCIAL
    DW  population_other ; TYPE_POLICE_DEPT
    DW  population_other ; TYPE_FIRE_DEPT
    DW  population_other ; TYPE_HOSPITAL
    DW  population_other ; TYPE_PARK
    DW  population_other ; TYPE_STADIUM
    DW  population_other ; TYPE_SCHOOL
    DW  population_other ; TYPE_HIGH_SCHOOL
    DW  population_other ; TYPE_UNIVERSITY
    DW  population_other ; TYPE_MUSEUM
    DW  population_other ; TYPE_LIBRARY
    DW  population_other ; TYPE_AIRPORT
    DW  population_other ; TYPE_PORT
    DW  population_other ; TYPE_DOCK
    DW  population_other ; TYPE_POWER_PLANT
    ; End of valid types...

;-------------------------------------------------------------------------------

Simulation_CalculateRCIDemand::

    ; Clear variables

    xor     a,a

    ld      hl,residential_area_empty
    ld      [hl+],a
    ld      [hl],a
    ld      hl,residential_area_used
    ld      [hl+],a
    ld      [hl],a

    ld      hl,commercial_area_empty
    ld      [hl+],a
    ld      [hl],a
    ld      hl,commercial_area_used
    ld      [hl+],a
    ld      [hl],a

    ld      hl,industrial_area_empty
    ld      [hl+],a
    ld      [hl],a
    ld      hl,industrial_area_used
    ld      [hl+],a
    ld      [hl],a

    ; Calculate area used and free

    ld      hl,CITY_MAP_TILES

.loop:
    push    hl

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

        ld      a,[hl] ; get type
        and     a,TYPE_MASK ; without flags!
        cp      a,TYPE_RESIDENTIAL
        jr      z,.type_r
        cp      a,TYPE_COMMERCIAL
        jr      z,.type_c
        cp      a,TYPE_INDUSTRIAL
        jr      z,.type_i
        jr      .end

IF T_RESIDENTIAL >= 256 || T_COMMERCIAL >= 256 || T_INDUSTRIAL >= 256
    FAIL "Fix this!"
ENDC

.type_r:
        ; Returns: Tile -> Register DE
        call    CityMapGetTileAtAddress ; hl = address. Preserves BC and HL
        ld      a,d
        and     a,a
        jr      nz,.not_empty_r
        ld      a,e
        cp      a,T_RESIDENTIAL
        jr      nz,.not_empty_r
            ; Empty
            ld      hl,residential_area_empty
            inc     [hl]
            jr      nc,.end
            inc     hl
            inc     [hl]
            jr      .end
.not_empty_r:
            ; Used
            ld      hl,residential_area_used
            inc     [hl]
            jr      nc,.end
            inc     hl
            inc     [hl]
            jr      .end

.type_c:
        ; Returns: Tile -> Register DE
        call    CityMapGetTileAtAddress ; hl = address. Preserves BC and HL
        ld      a,d
        and     a,a
        jr      nz,.not_empty_c
        ld      a,e
        cp      a,T_COMMERCIAL
        jr      nz,.not_empty_c
            ; Empty
            ld      hl,commercial_area_empty
            inc     [hl]
            jr      nc,.end
            inc     hl
            inc     [hl]
            jr      .end
.not_empty_c:
            ; Used
            ld      hl,commercial_area_used
            inc     [hl]
            jr      nc,.end
            inc     hl
            inc     [hl]
            jr      .end

.type_i:
        ; Returns: Tile -> Register DE
        call    CityMapGetTileAtAddress ; hl = address. Preserves BC and HL
        ld      a,d
        and     a,a
        jr      nz,.not_empty_i
        ld      a,e
        cp      a,T_INDUSTRIAL
        jr      nz,.not_empty_i
            ; Empty
            ld      hl,industrial_area_empty
            inc     [hl]
            jr      nc,.end
            inc     hl
            inc     [hl]
            jr      .end
.not_empty_i:
            ; Used
            ld      hl,industrial_area_used
            inc     [hl]
            jr      nc,.end
            inc     hl
            inc     [hl]
            jr      .end

.end:
    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ; Calculate proportion of land used

; The more percentage of area is used, the higher the demand!
CALCULATE_GRAPH : MACRO ; \1 = empty ptr, \2 = used ptr, \3 = destination

    ld      a,[\1+0] ; LSB first
    ld      l,a
    ld      a,[\1+1]
    ld      h,a
    ; hl = empty area

    ld      a,[\2+0] ; LSB first
    ld      e,a
    ld      a,[\2+1]
    ld      d,a
    ; de = used area

    add     hl,de
    ; hl = total area

    ld      a,l
    or      a,h
    jr      nz,.more_than_zero_area\@
        ld      a,$FF ; zero area = set demand to max because there is nothing!
        jr      .end\@
.more_than_zero_area\@:

    ; de = used area
    ; hl = total area

    ld      c,16 ; get the top 7 bits of the area to simplify divisions
.loop\@:
        ld      a,h
        or      a,d
        bit     6,a ; get 7 bits only
        jp      nz,.end_simplify_loop\@
        add     hl,hl ; hl <<= 1
        sla     e     ; de <<= 1
        rl      d
    dec     c
    jr      nz,.loop\@
.end_simplify_loop\@:

    ; d = aprox used area
    ; h = aprox total area

    ; empty / total => hl / c

    ld      c,h ; total

    ld      h,d ; empty
    ld      l,0 ; 8.8 fixed point!

    call    div_u16u7u16 ; hl / c -> hl

    ; hl = empty / total 8.8 fixed point

    ld      a,h
    and     a,a ; if hl >= 1.0
    jr      z,.not_saturated\@

        ld      a,$FF
        jr      .end\@
.not_saturated\@:

    ld      a,l ; get fractionary part
.end\@:

    ; Save to graph the value in register A (0 - $FF)

    swap    a
    rra
    and     a,7

    ld      b,a
    ld      a,7
    sub     a,b

    ; 0-7 (0 = high demand, 3,4 = neutral, 7 = low demand)

    sub     a,3 ; offset

    ld      [\3],a

ENDM

    CALCULATE_GRAPH residential_area_empty,residential_area_used,graph_value_r
    CALCULATE_GRAPH commercial_area_empty, commercial_area_used, graph_value_c
    CALCULATE_GRAPH industrial_area_empty, industrial_area_used, graph_value_i

    ret

;-------------------------------------------------------------------------------

Simulation_CalculateStatistics::

    ; First, add up population (total population and separated by types)
    ; ------------------------------------------------------------------

    ; Clear variables

    xor     a,a

    ld      hl,city_population_temp
    REPT    5
    ld      [hl+],a
    ENDR

    ld      hl,population_residential
    REPT    4
    ld      [hl+],a
    ENDR

    ld      hl,population_commercial
    REPT    4
    ld      [hl+],a
    ENDR

    ld      hl,population_industrial
    REPT    4
    ld      [hl+],a
    ENDR

    ld      hl,population_other
    REPT    4
    ld      [hl+],a
    ENDR

    ; Calculate

    ld      hl,CITY_MAP_TILES

.loop:
    push    hl

        ld      a,BANK_CITY_MAP_TYPE
        ld      [rSVBK],a

        ld      a,[hl] ; get type
        and     a,TYPE_MASK ; without flags!

        cp      a,TYPE_FIELD
        jr      z,.skip
        cp      a,TYPE_FOREST
        jr      z,.skip
        cp      a,TYPE_WATER
        jr      z,.skip
        cp      a,TYPE_DOCK
        jr      z,.skip

        ld      b,a
        push    bc ; (*) b = type

        ; Returns: Tile -> Register DE
        ; Arguments: hl = address. Preserves BC and HL
        call    CityMapGetTileAtAddress

        push    de
        ; de = tile number, returns a = 1 if it is the origin of a building
        call    BuildingIsTileCoordinateOrigin
        pop     de

        pop     bc ; (*) b = type

        and     a,a
        jr      z,.skip ; not the origin of the building, already handled

        push    bc ; preserve type
        call    CityTileDensity ; de = tile, returns d=population
        pop     bc

        ; Preserve population (d)

        ; Add population to the corresponding type variable

        ld      a,b ; b = type. no need to save it after this
        add     a,a ; a * 2
        ld      l,a
        ld      h,tile_rci_population_pointer>>8 ; LSB first

        ld      a,[hl+]
        ld      h,[hl]
        ld      l,a ; hl = pointer to variable to add the population to

        ld      e,0 ; helper zero register

        ld      a,[hl]
        add     a,d
        ld      [hl+],a

        REPT    3
        ld      a,[hl]
        adc     a,e
        ld      [hl+],a
        ENDR

        ; Restore population (d)

        ; Add population to the global population variable

        ld      e,d ; BINARY_TO_BCD
        ld      d,0
        ld      hl,BINARY_TO_BCD ; 2 bytes per entry. LSB first
        add     hl,de
        add     hl,de

        ld      a,[hl+]
        ld      b,[hl]
        ld      c,a ; bc = population in bcd

        ld      hl,city_population_temp
        ld      e,0 ; helper zero register

        ld      a,[hl]
        add     a,c
        daa ; yeah, really!
        ld      [hl+],a

        ld      a,[hl]
        adc     a,b
        daa ; yeah, really!
        ld      [hl+],a

        REPT    3
        ld      a,[hl]
        adc     a,e
        daa ; yeah, really!
        ld      [hl+],a
        ENDR

.skip:
    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop

    ; Save result to final variable!

    ld      de,city_population
    ld      hl,city_population_temp
    REPT    5
    ld      a,[hl+]
    ld      [de],a
    inc     de
    ENDR

    ; Save city type to variable

    jr      Simulation_CalculateCityType ; call and return from here

;-------------------------------------------------------------------------------

    DATA_MONEY_AMOUNT   POPULATION_TOWN,        1000
    DATA_MONEY_AMOUNT   POPULATION_CITY,        5000
    DATA_MONEY_AMOUNT   POPULATION_METROPOLIS, 10000
    DATA_MONEY_AMOUNT   POPULATION_CAPITAL,    50000

Simulation_CalculateCityType::

    ld      a,TYPE_VILLAGE
    ld      [city_type],a

    ld      de,POPULATION_TOWN
    ld      hl,city_population
    call    BCD_HL_GE_DE ; Returns 1 if [hl] >= [de]
    and     a,a
    ret     z ; continue actual population > reference population

    ld      a,TYPE_TOWN
    ld      [city_type],a

    ld      de,POPULATION_CITY
    ld      hl,city_population
    call    BCD_HL_GE_DE ; Returns 1 if [hl] >= [de]
    and     a,a
    ret     z ; continue actual population > reference population

    ld      a,TYPE_CITY
    ld      [city_type],a

    ld      de,POPULATION_METROPOLIS
    ld      hl,city_population
    call    BCD_HL_GE_DE ; Returns 1 if [hl] >= [de]
    and     a,a
    ret     z ; continue actual population > reference population

    ld      a,TYPE_METROPOLIS
    ld      [city_type],a

    ld      de,POPULATION_CAPITAL
    ld      hl,city_population
    call    BCD_HL_GE_DE ; Returns 1 if [hl] >= [de]
    and     a,a
    ret     z ; continue actual population > reference population

    ld      a,TYPE_CAPITAL
    ld      [city_type],a

    ret

;###############################################################################
