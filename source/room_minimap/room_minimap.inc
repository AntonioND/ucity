;###############################################################################
;
;    µCity - City building game for Game Boy Color.
;    Copyright (C) 2017 Antonio Niño Díaz (AntonioND/SkyLyrac)
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

    IF !DEF(ROOM_MINIMAP_INC)
ROOM_MINIMAP_INC SET 1

;###############################################################################

MINIMAP_SELECTION_OVERVIEW           EQU 0
MINIMAP_SELECTION_ZONE_MAP           EQU 1
MINIMAP_SELECTION_TRANSPORT_MAP      EQU 2
MINIMAP_SELECTION_POLICE             EQU 3
MINIMAP_SELECTION_FIRE_PROTECTION    EQU 4
MINIMAP_SELECTION_HOSPITALS          EQU 5
MINIMAP_SELECTION_SCHOOLS            EQU 6
MINIMAP_SELECTION_HIGH_SCHOOLS       EQU 7
MINIMAP_SELECTION_POWER_GRID         EQU 8
MINIMAP_SELECTION_POWER_DENSITY      EQU 9
MINIMAP_SELECTION_POPULATION_DENSITY EQU 10
MINIMAP_SELECTION_TRAFFIC            EQU 11
MINIMAP_SELECTION_POLLUTION          EQU 12
MINIMAP_SELECTION_HAPPINESS          EQU 13

MINIMAP_SELECTION_MAX                EQU 13
; There's no room for any other map with the current selection menu!

MINIMAP_SELECTION_DISASTERS          EQU 14

;###############################################################################

    ENDC ; ROOM_MINIMAP_INC

;###############################################################################
