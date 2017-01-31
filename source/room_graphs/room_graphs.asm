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
    INCLUDE "room_graphs.inc"

;###############################################################################

    SECTION "Room Graphs Variables",WRAM0

;-------------------------------------------------------------------------------

graphs_room_exit: DS 1 ; set to 1 to exit room

graphs_selected: DS 1

;###############################################################################

    SECTION "Room Graphs Functions",ROMX

;-------------------------------------------------------------------------------

GraphsDrawSelected::

    ; Not needed to clear first, the drawing functions draw over everything

    ld      a,[graphs_selected]

    cp      a,GRAPHS_SELECTION_POPULATION
    jr      nz,.not_population
        LONG_CALL   GraphDrawTotalPopulation
        ret
.not_population:
    cp      a,GRAPHS_SELECTION_RCI
    jr      nz,.not_rci
        LONG_CALL   GraphDrawRCI
        ret
.not_rci:
    cp      a,GRAPHS_SELECTION_MONEY
    jr      nz,.not_money
        LONG_CALL   GraphDrawMoney
        ret
.not_money:

    ld      b,b ; Not found!
    call    MinimapSetDefaultPalette
    LONG_CALL   APA_BufferClear
    call    APA_BufferUpdate

    ret

;-------------------------------------------------------------------------------

GraphsSelectGraph:: ; b = graph to select

    ld      a,b
    ld      [graphs_selected],a

    ret

;-------------------------------------------------------------------------------

InputHandleGraphs:

    LONG_CALL_ARGS  GraphsMenuHandleInput ; If it returns 1, exit room
    and     a,a
    ret     z ; don't exit

    ; Exit
    ld      a,1
    ld      [graphs_room_exit],a
    ret

;-------------------------------------------------------------------------------

RoomGraphs::

    call    SetPalettesAllBlack

    LONG_CALL   GraphsMenuReset

    ld      bc,RoomGraphsVBLHandler
    call    irq_set_VBL

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ld      [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    LONG_CALL   RoomMinimapLoadBG ; Same graphics as minimap room

    call    LoadTextPalette

    ld      a,GRAPHS_SELECTION_POPULATION
    ld      [graphs_selected],a

    LONG_CALL   GraphsDrawSelected

    ; This can be loaded after the rest, it isn't shown until A is pressed
    ; so there is no hurry.
    LONG_CALL   GraphsMenuLoadGFX

    xor     a,a
    ld      [graphs_room_exit],a

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleGraphs

    ld      a,[graphs_room_exit]
    and     a,a
    jr      z,.loop

    call    SetDefaultVBLHandler

    call    SetPalettesAllBlack

    ret

;###############################################################################

    SECTION "Room Graphs Code Bank 0",ROM0

;-------------------------------------------------------------------------------

RoomGraphsVBLHandler:

    call    GraphsMenuVBLHandler

    call    refresh_OAM

    ret

;###############################################################################
