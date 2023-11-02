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

    IF !DEF(APA_INC)
    DEF APA_INC = 1

;###############################################################################

; This APA Library uses tiles 128-383 of VRAM bank 1

    DEF APA_FB_WIDTH  EQU 128
    DEF APA_FB_HEIGHT EQU 128

    DEF APA_TILE_WIDTH  EQU 16
    DEF APA_TILE_HEIGHT EQU 16

    DEF APA_TILE_NUMBER EQU (APA_TILE_WIDTH*APA_TILE_HEIGHT)

    DEF APA_TILE_OFFSET_X EQU ((20-APA_TILE_WIDTH)/2) ; Center of the screen
    DEF APA_TILE_OFFSET_Y EQU (18-APA_TILE_HEIGHT) ; Bottom of the screen

    DEF APA_PALETTE_INDEX EQU 6 ; Palette index used by the minimap

;###############################################################################

    ENDC ; APA_INC

;###############################################################################
