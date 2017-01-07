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

; bg_scx, bg_scy = shadow registers, copied to rSCX and rSCY during VBL
; bg_x, bg_y = bg scroll (in tiles)
; Complete scroll value: (bg_x * 8) + (bg_scx & 7)

;###############################################################################

    SECTION "Simulation Transportation Map Variables",WRAM0

;-------------------------------------------------------------------------------

SIMULATION_MAX_PLANES   EQU 6
SIMULATION_MAX_TRAINS   EQU 2

SIMULATION_OBJECTS_OAM_BASE EQU 20 ; First OAM index to use for transportation

SIMULATION_SPRITES_SHOWN: DS 1 ; 0 if sprites are hidden, 1 if not

; This holds the previous scroll values. We are only going to handle small
; displacements, not jumps to other places of the screen, so we only need
; the lower 8 bits of the scroll. If a big jump is performed, the correct thing
; to do is a refresh of all the objects.
simulation_scx_old: DS 1
simulation_scy_old: DS 1

;-------------------------------------------------------------------------------

PLANE_SPR_OAM_BASE EQU SIMULATION_OBJECTS_OAM_BASE

PLANE_SPRITE_TILE_START EQU (147-128)

PLANE_NUM_DIRECTIONS EQU 8 ; 4 directions + 4 diagonals

; Coordinates in tiles of the plane. 0 is actually -1, there is one extra row
; and column at each border.
PLANE_X_TILE:    DS SIMULATION_MAX_PLANES
PLANE_Y_TILE:    DS SIMULATION_MAX_PLANES
; (0 - 7) Coordinates inside the tile, to be added to PLANE_X/Y_TILE.
PLANE_X_IN_TILE: DS SIMULATION_MAX_PLANES
PLANE_Y_IN_TILE: DS SIMULATION_MAX_PLANES
; Coordinates of the sprite (in px)
PLANE_X_SPR:     DS SIMULATION_MAX_PLANES
PLANE_Y_SPR:     DS SIMULATION_MAX_PLANES
; Clockwise, 0 is up, 1 up right, etc. -1 = Plane is disabled
PLANE_DIRECTION: DS SIMULATION_MAX_PLANES
PLANE_VISIBLE:   DS SIMULATION_MAX_PLANES ; 1 = Visible on screen

TRAIN_SPR_OAM_BASE EQU PLANE_SPR_OAM_BASE+SIMULATION_MAX_PLANES

;###############################################################################

    SECTION "Simulation Transportation Animations Functions",ROMX

;###############################################################################

    INCLUDE "simulation_anim_planes.inc"

;-------------------------------------------------------------------------------

    INCLUDE "simulation_anim_trains.inc"

;###############################################################################

; Initialize objects to random locations. It doesn't refresh the sprites.
; It must be called after initializing the BG and its scroll as this function
; sets the initial reference.
Simulation_TransportAnimsInit::

    xor     a,a
    ld      [SIMULATION_SPRITES_SHOWN],a

    call    PlanesReset

    call    TrainsReset

    ; Set scroll reference

    ld      a,[bg_scx]
    ld      [simulation_scx_old],a

    ld      a,[bg_scy]
    ld      [simulation_scy_old],a

    ret

;-------------------------------------------------------------------------------

; This refreshes all sprites, but doesn't refresh the OAM. It should be used
; right after the objects are generated or if they have been hidden before and
; they should appear on the place they were back then. This should also be used
; after a jump to a different part of the map, at least if the objects are
; supposed to be visible after the jump.
Simulation_TransportAnimsShow::

    ld      a,[simulation_disaster_mode]
    and     a,a
    ret     nz ; don't enable sprites in disaster mode...

    call    PlanesShow

    ; TODO

    ld      a,1
    ld      [SIMULATION_SPRITES_SHOWN],a

    ret

;-------------------------------------------------------------------------------

; Move objects according to the movement of each transport means, to be called
; once per animation step. It hides objects when they leave the screen and
; shows them when they reach the screen area again.
Simulation_TransportAnimsHandle::

    ; Check if sprites are hidden or not (for example, during disasters)

    ld      a,[SIMULATION_SPRITES_SHOWN]
    and     a,a ; if they aren't visible, do nothing, they will have to be
    ret     z ; refreshed when the disaster ends, for example...

    call    PlanesHandle

    call    TrainsHandle

    ret

;-------------------------------------------------------------------------------

; Update sprites according to the scroll of the background. It checks the
; current scroll and compares it with the previous one. It can only handle small
; displacements, in case of a jump to another part of the map, this function
; isn't enough (a refresh is needed).
Simulation_TransportAnimsScroll::

    ; Check if sprites are hidden or not (for example, during disasters)

    ld      a,[SIMULATION_SPRITES_SHOWN]
    and     a,a ; if they aren't visible, do nothing, they will have to be
    ret     z   ; refreshed when they are shown again...

    ; Read bg registers and calculate increment

    ld      a,[bg_scx]
    ld      e,a
    ld      a,[simulation_scx_old]
    sub     a,e
    ld      e,a ; e = old x - new x

    ld      a,[bg_scy]
    ld      d,a
    ld      a,[simulation_scy_old]
    sub     a,d
    ld      d,a ; d = old y - new y

    ; Update scroll reference (preserve de)

    ld      a,[bg_scx]
    ld      [simulation_scx_old],a

    ld      a,[bg_scy]
    ld      [simulation_scy_old],a

    ; Scroll sprites

    ; e = old x - new x
    ; d = old y - new y

    ld      a,e
    or      a,d
    ret     z ; if no scroll, do nothing...

    push    de
    call    PlanesHandleScroll ; d = value to add to y, e = value to add to x
    pop     de

    ; TODO

    ret

;-------------------------------------------------------------------------------

; This hides all sprites, but doesn't refresh the OAM.
Simulation_TransportAnimsHide::

    xor     a,a
    ld      [SIMULATION_SPRITES_SHOWN],a

    call    PlanesHide

    ; TODO

    ret

;###############################################################################
