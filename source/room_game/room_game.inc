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

    IF !DEF(ROOM_GAME_INC)
ROOM_GAME_INC SET 1

;###############################################################################

CITY_MAP_WIDTH  EQU 64
CITY_MAP_HEIGHT EQU 64

;-------------------------------------------------------------------------------

; This shouldn't be needed, but if removed the assembler will complain when
; getting the BANK() of a label that hasn't been used before in that file.
BANK_CITY_MAP_TILES       EQU 1
BANK_CITY_MAP_ATTR        EQU 2
BANK_CITY_MAP_TYPE        EQU 3
BANK_CITY_MAP_ELECTRICITY EQU 4
BANK_CITY_MAP_SERVICES    EQU 5
BANK_CITY_MAP_TRAFFIC     EQU 6
BANK_CITY_MAP_something   EQU 7

;-------------------------------------------------------------------------------

GAME_STATE_WATCH            EQU 0
GAME_STATE_EDIT             EQU 1
GAME_STATE_WATCH_FAST_MOVE  EQU 2
GAME_STATE_SELECT_BUILDING  EQU 3
GAME_STATE_PAUSE_MENU       EQU 4

;-------------------------------------------------------------------------------

; Item type
; ---------

TYPE_HAS_ROAD_BIT  EQU 7
TYPE_HAS_TRAIN_BIT EQU 6
TYPE_HAS_POWER_BIT EQU 5

TYPE_HAS_ROAD   EQU (1<<TYPE_HAS_ROAD_BIT)
TYPE_HAS_TRAIN  EQU (1<<TYPE_HAS_TRAIN_BIT)
TYPE_HAS_POWER  EQU (1<<TYPE_HAS_POWER_BIT)

TYPE_MASK       EQU %00011111
TYPE_FLAGS_MASK EQU %11100000

; TYPE_FIELD must be 0 always so that TYPE_HAS_ROAD, TYPE_HAS_TRAIN and
; TYPE_HAS_POWER are always considered to be in TYPE_FIELD. The exceptions are
; bridges, that allow them to be with TYPE_WATER, and sea ports, which have some
; tiles in water.
TYPE_FIELD              EQU 0 ; This one must be 0.
TYPE_FOREST             EQU 1
TYPE_WATER              EQU 2
TYPE_RESIDENTIAL        EQU 3
TYPE_INDUSTRIAL         EQU 4
TYPE_COMMERCIAL         EQU 5
TYPE_POLICE             EQU 6
TYPE_FIREMEN            EQU 7
TYPE_HOSPITAL           EQU 8
TYPE_PARK               EQU 9
TYPE_STADIUM            EQU 10
TYPE_SCHOOL             EQU 11
TYPE_HIGH_SCHOOL        EQU 12
TYPE_UNIVERSITY         EQU 13
TYPE_MUSEUM             EQU 14
TYPE_LIBRARY            EQU 15
TYPE_TRAIN_STATION      EQU 16
TYPE_AIRPORT            EQU 17
TYPE_PORT               EQU 18
TYPE_DOCK               EQU 19
TYPE_POWER_PLANT        EQU 20

TYPE_OTHER              EQU 21 ; Decoration

TYPE_NUMBER             EQU 32 ; Max. number. Upper 3 bits used as flags

;###############################################################################

    ENDC ; ROOM_GAME_INC

;###############################################################################
