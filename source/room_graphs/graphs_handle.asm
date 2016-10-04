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

    INCLUDE "room_graphs.inc"

;###############################################################################

    SECTION "Graph Handling Data",WRAM0

;-------------------------------------------------------------------------------

GRAPH_POPULATION_DATA::   DS GRAPH_SIZE
GRAPH_POPULATION_OFFSET:: DS 1 ; Circular buffer start index
GRAPH_POPULATION_SCALE:   DS 1

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

    ret

;-------------------------------------------------------------------------------

GraphsSaveRecords:: ; Save to SRAM

    ; Enable SRAM

    ld      a,CART_RAM_ENABLE
    ld      [rRAMG],a

    ; Total population graph

    ld      bc,GRAPH_SIZE
    ld      hl,GRAPH_POPULATION_DATA
    ld      de,SAV_GRAPH_POPULATION_DATA
    call    memcopy ; bc = size    hl = source address    de = dest address

    ld      a,[GRAPH_POPULATION_OFFSET]
    ld      [SAV_GRAPH_POPULATION_OFFSET],a

    ld      a,[GRAPH_POPULATION_SCALE]
    ld      [SAV_GRAPH_POPULATION_SCALE],a

    ; Disable SRAM

    ld      a,CART_RAM_DISABLE
    ld      [rRAMG],a

    ret

;-------------------------------------------------------------------------------

GraphsLoadRecords:: ; Load from SRAM

    ; Enable SRAM

    ld      a,CART_RAM_ENABLE
    ld      [rRAMG],a

    ; Total population graph

    ld      bc,GRAPH_SIZE
    ld      de,GRAPH_POPULATION_DATA
    ld      hl,SAV_GRAPH_POPULATION_DATA
    call    memcopy ; bc = size    hl = source address    de = dest address

    ld      a,[SAV_GRAPH_POPULATION_OFFSET]
    ld      [GRAPH_POPULATION_OFFSET],a

    ld      a,[SAV_GRAPH_POPULATION_SCALE]
    ld      [GRAPH_POPULATION_SCALE],a

    ; Disable SRAM

    ld      a,CART_RAM_DISABLE
    ld      [rRAMG],a

    ret

;-------------------------------------------------------------------------------

GraphHandleRecords::

    ; This calls the individual graph handling functions

    call    GraphTotalPopulationAddRecord

    ret

;-------------------------------------------------------------------------------

GraphTotalPopulationAddRecord:

    ; TODO

    ret

;###############################################################################
