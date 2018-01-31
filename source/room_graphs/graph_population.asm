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
    INCLUDE "text.inc"

;###############################################################################

    SECTION "Total Population Graph Functions",ROMX

;-------------------------------------------------------------------------------

GRAPH_TOTAL_POPULATION_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (0<<10)|(31<<5)|(0<<0)
    DW (0<<10)|(31<<5)|(31<<0), (0<<10)|(0<<5)|(0<<0)

GRAPH_TOTAL_POPULATION_TITLE:
    STR_ADD "Total Population"

GraphDrawTotalPopulation::

    ; Clean graph buffer first
    ; ------------------------

    LONG_CALL   APA_BufferClear

    ld      a,3
    call    APA_SetColor0 ; a = color

    ; Draw graph
    ; ----------

    ld      hl,GRAPH_POPULATION_DATA
    ld      d,0
    ld      a,[GRAPH_POPULATION_OFFSET]
    ld      e,a
    add     hl,de ; hl = start of data

    ld      d,a ; d = current offset
    ld      e,0 ; e = x
.loopx:

    push    hl
    push    de ; (*)

        ld      a,[hl]
        cp      a,GRAPH_INVALID_ENTRY
        jr      z,.skip_entry

            ld      c,a ; 127-y
            ld      b,e ; x

            ld      a,127
            sub     a,c
            ld      c,a

            LONG_CALL_ARGS  APA_Plot ; b = x, c = y (0-127!)
.skip_entry:

    pop     de ; (*)
    pop     hl

    inc     hl
    inc     d

    bit     7,d
    jr      z,.not_overflow_ring_buffer
        ld      hl,GRAPH_POPULATION_DATA
        ld      d,0
.not_overflow_ring_buffer:

    inc     e
    bit     7,e ; GRAPH_SIZE = 128
    jr      z,.loopx

    ; Set White
    call    MinimapSetDefaultPalette

    ; Refresh screen with backbuffer data
    call    APA_BufferUpdate

    ; Load palette
    ld      hl,GRAPH_TOTAL_POPULATION_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,GRAPH_TOTAL_POPULATION_TITLE
    call    RoomMinimapDrawTitle

    ret

;###############################################################################
