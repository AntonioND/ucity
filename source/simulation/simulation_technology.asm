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

    INCLUDE "building_info.inc"
    INCLUDE "room_game.inc"
    INCLUDE "text_messages.inc"
    INCLUDE "tileset_info.inc"

;###############################################################################

    SECTION "Simulation Technology Variables",WRAM0

;-------------------------------------------------------------------------------

TECH_LEVEL_NUCLEAR  EQU 10
TECH_LEVEL_FUSION   EQU 40

TECH_LEVEL_MAX      EQU 40

;-------------------------------------------------------------------------------

technology_level:: DS 1 ; maxes out at TECH_LEVEL_MAX

;###############################################################################

    SECTION "Simulation Technology Functions",ROMX

;###############################################################################

; Returns b = 1 if available, 0 if not
Technology_IsBuildingAvailable:: ; b = B_xxxx define

    ld      a,b

    ; Nuclear power plant

    cp      a,B_PowerPlantNuclear
    jr      nz,.not_nuclear

        ld      a,[technology_level]
        cp      a,TECH_LEVEL_NUCLEAR ; cy = 1 if n > a
        jr      c,.not_available_nuclear
            ld      b,1
            ret
.not_available_nuclear:
            ld      a,ID_MSG_TECH_INSUFFICIENT
            call    MessageRequestAdd
            ld      b,0
            ret
.not_nuclear:

    ; Nuclear fusion power plant

    cp      a,B_PowerPlantFusion
    jr      nz,.not_fusion

        ld      a,[technology_level]
        cp      a,TECH_LEVEL_FUSION ; cy = 1 if n > a
        jr      c,.not_available_fusion
            ld      b,1
            ret
.not_available_fusion:
            ld      a,ID_MSG_TECH_INSUFFICIENT
            call    MessageRequestAdd
            ld      b,0
            ret
.not_fusion:

    ; The rest of buildings are always available

    ld      b,1
    ret

;-------------------------------------------------------------------------------

Technology_TryIncrement:

    ; Each year, each university tries to increment the technology level of
    ; the city. If a certain building is discovered at the next level, it tries
    ; to discover it (with a certain % of it being discovered). If it's
    ; discovered, the level increases. If not, try again next year (or next
    ; university) and keep the same level.

    ; 1. Check if the next level unlocks anything
    ; -------------------------------------------

    ld      a,[technology_level]
    inc     a

    cp      a,TECH_LEVEL_NUCLEAR
    jr      z,.level_match

    cp      a,TECH_LEVEL_FUSION
    jr      z,.level_match

    ld      [technology_level],a
    ret ; if no match, just increment the level

.level_match:

    ; 2. Try to randomly increase a level if it unlocks something
    ; -----------------------------------------------------------

    ; 70/256 chances of failing to increase

    call    GetRandom
    cp      a,$70 ; cy = 1 if n > a
    ret     nc ; if a > n, return. the lower the n, the more difficult

    ld      a,[technology_level]
    inc     a
    ld      [technology_level],a

    ; 3. If something is unlocked, show a message
    ; -------------------------------------------

    cp      a,TECH_LEVEL_NUCLEAR
    jr      nz,.not_nuclear
        ld      a,ID_MSG_TECH_NUCLEAR
        call    MessageRequestAdd
        ret
.not_nuclear:

    cp      a,TECH_LEVEL_FUSION
    jr      nz,.not_fusion
        ld      a,ID_MSG_TECH_FUSION
        call    MessageRequestAdd
        ret
.not_fusion:

    ret

;-------------------------------------------------------------------------------

Simulation_AdvanceTechnology::

    ; If technology is maxed out, just return now.

    ld      a,[technology_level]
    cp      a,TECH_LEVEL_MAX ; cy = 1 if n > a
    ret     nc ; Has the max level been reached? If so, return.

    ; Increment technology level for each university
    ; ----------------------------------------------

    ld      a,[COUNT_UNIVERSITIES]
    and     a,a
    ret     z ; don't enter loop if there are no universities

    ld      b,a
.loop_increment:
    push    bc
    call    Technology_TryIncrement
    pop     bc

    ld      a,[technology_level]
    cp      a,TECH_LEVEL_MAX ; cy = 1 if n > a
    ret     nc ; Has the max level been reached? If so, return.

    dec     b
    jr      nz,.loop_increment

    ret

;###############################################################################
