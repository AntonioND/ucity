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

    IF !DEF(MAP_LOAD_INC)
    DEF MAP_LOAD_INC = 1

;###############################################################################

    ; Autogenerated map. CITY_MAP_SRAM_FLAG is ignored if this value is used.
    DEF CITY_MAP_GENERATE_RANDOM EQU $FF

    ; If set, load from SRAM. If not, load a predefined map.
    DEF CITY_MAP_SRAM_FLAG       EQU %10000000

    DEF CITY_MAP_NUMBER_MASK     EQU %01111111

    DEF SCENARIOS_TOTAL_NUM      EQU 4 ; Total number of scenarios included in the ROM

;###############################################################################

    ENDC ; MAP_LOAD_INC

;###############################################################################
