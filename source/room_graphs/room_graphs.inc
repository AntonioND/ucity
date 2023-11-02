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

    IF !DEF(ROOM_GRAPHS_INC)
    DEF ROOM_GRAPHS_INC = 1

;###############################################################################

    DEF GRAPHS_SELECTION_POPULATION EQU 0
    DEF GRAPHS_SELECTION_RCI        EQU 1
    DEF GRAPHS_SELECTION_MONEY      EQU 2

    DEF GRAPHS_SELECTION_MAX        EQU 2

;-------------------------------------------------------------------------------

    ; Valid values are 0-127
    DEF GRAPH_INVALID_ENTRY EQU -1 ; Entries that should be considered empty

    DEF GRAPH_SIZE EQU 128 ; Entries per graph. It must be a power of 2

;###############################################################################

    ENDC ; ROOM_GRAPHS_INC

;###############################################################################
