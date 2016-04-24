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

    IF !DEF(BUILDING_DENSITY_INC)
BUILDING_DENSITY_INC SET 1

;###############################################################################

    GLOBAL CITY_TILE_DENSITY ; 512 entries: Population density, energetic cost

CITY_TILE_DENSITY_ELEMENT_SIZE EQU 2 ; Size of elements of CITY_TILE_DENSITY

; Add the following check when using this array:
;
; IF CITY_TILE_DENSITY_ELEMENT_SIZE != 2
;     FAIL "Fix this!"
; ENDC

MAX_DISPLAYABLE_POPULATION_DENSITY EQU 15

;###############################################################################

    ENDC ; BUILDING_DENSITY_INC

;###############################################################################
