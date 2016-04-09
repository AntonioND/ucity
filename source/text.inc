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

    IF !DEF(TEXT_INC)
TEXT_INC SET 1

;###############################################################################

; Offsets
O_CURSOR        EQU 41
O_SPACE         EQU 53
O_BAR           EQU 54
O_COPYRIGHT     EQU 55 ; Mapped to "%"
O_COMMA         EQU 56
O_DOT           EQU 57
O_UNDERSCORE    EQU 58
O_AT            EQU 59
O_COLON         EQU 60
O_ARROW         EQU 61 ; Mapped to "#"
O_APOSTROPHE    EQU 62
O_QUESTION      EQU 63
O_EXCLAMATION   EQU 64
O_NTILDE        EQU 65 ; La eñe, leches XD - Mapped to "~"
O_ZERO          EQU 66
O_A_UPPERCASE   EQU 76
O_A_LOWERCASE   EQU 102
O_NONE          EQU O_QUESTION

;-------------------------------------------------------------------------------

BCD2Tile : MACRO ; a = number from 0 to 9. Returns tile number in a
    add     a,O_ZERO
ENDM

;###############################################################################

    ENDC ;TEXT_INC

;###############################################################################
