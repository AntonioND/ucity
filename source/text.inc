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

    IF !DEF(TEXT_INC)
    DEF TEXT_INC = 1

;###############################################################################

; NOTE: This file should be included by any file that stores ASCII strings in
; the ROM, as the charmap defined below will convert them to tile indexes.

;###############################################################################

    ; Offsets
    DEF O_PLUS          EQU 34
    DEF O_MICRO         EQU 35
    DEF O_PERCENT       EQU 39
    DEF O_DASH          EQU 40
    DEF O_CURSOR        EQU 41
    DEF O_RCI_BASE_BAR  EQU 42
    DEF O_SPACE         EQU 53
    DEF O_BAR           EQU 54
    DEF O_COPYRIGHT     EQU 55 ; Mapped to "$"
    DEF O_COMMA         EQU 56
    DEF O_DOT           EQU 57
    DEF O_UNDERSCORE    EQU 58
    DEF O_AT            EQU 59
    DEF O_COLON         EQU 60
    DEF O_ARROW         EQU 61 ; Mapped to "#"
    DEF O_APOSTROPHE    EQU 62
    DEF O_QUESTION      EQU 63
    DEF O_EXCLAMATION   EQU 64
    DEF O_NTILDE        EQU 65 ; Mapped to "~"
    DEF O_ZERO          EQU 66
    DEF O_A_UPPERCASE   EQU 76
    DEF O_A_LOWERCASE   EQU 102
    DEF O_NONE          EQU O_QUESTION

;-------------------------------------------------------------------------------

MACRO BCD2Tile ; a = number from 0 to 9. Returns tile number in a
    add     a,O_ZERO
ENDM

;-------------------------------------------------------------------------------

    CHARMAP "0",O_ZERO+0
    CHARMAP "1",O_ZERO+1
    CHARMAP "2",O_ZERO+2
    CHARMAP "3",O_ZERO+3
    CHARMAP "4",O_ZERO+4
    CHARMAP "5",O_ZERO+5
    CHARMAP "6",O_ZERO+6
    CHARMAP "7",O_ZERO+7
    CHARMAP "8",O_ZERO+8
    CHARMAP "9",O_ZERO+9

    CHARMAP "A",O_A_UPPERCASE+0
    CHARMAP "B",O_A_UPPERCASE+1
    CHARMAP "C",O_A_UPPERCASE+2
    CHARMAP "D",O_A_UPPERCASE+3
    CHARMAP "E",O_A_UPPERCASE+4
    CHARMAP "F",O_A_UPPERCASE+5
    CHARMAP "G",O_A_UPPERCASE+6
    CHARMAP "H",O_A_UPPERCASE+7
    CHARMAP "I",O_A_UPPERCASE+8
    CHARMAP "J",O_A_UPPERCASE+9
    CHARMAP "K",O_A_UPPERCASE+10
    CHARMAP "L",O_A_UPPERCASE+11
    CHARMAP "M",O_A_UPPERCASE+12
    CHARMAP "N",O_A_UPPERCASE+13
    CHARMAP "O",O_A_UPPERCASE+14
    CHARMAP "P",O_A_UPPERCASE+15
    CHARMAP "Q",O_A_UPPERCASE+16
    CHARMAP "R",O_A_UPPERCASE+17
    CHARMAP "S",O_A_UPPERCASE+18
    CHARMAP "T",O_A_UPPERCASE+19
    CHARMAP "U",O_A_UPPERCASE+20
    CHARMAP "V",O_A_UPPERCASE+21
    CHARMAP "W",O_A_UPPERCASE+22
    CHARMAP "X",O_A_UPPERCASE+23
    CHARMAP "Y",O_A_UPPERCASE+24
    CHARMAP "Z",O_A_UPPERCASE+25

    CHARMAP "a",O_A_LOWERCASE+0
    CHARMAP "b",O_A_LOWERCASE+1
    CHARMAP "c",O_A_LOWERCASE+2
    CHARMAP "d",O_A_LOWERCASE+3
    CHARMAP "e",O_A_LOWERCASE+4
    CHARMAP "f",O_A_LOWERCASE+5
    CHARMAP "g",O_A_LOWERCASE+6
    CHARMAP "h",O_A_LOWERCASE+7
    CHARMAP "i",O_A_LOWERCASE+8
    CHARMAP "j",O_A_LOWERCASE+9
    CHARMAP "k",O_A_LOWERCASE+10
    CHARMAP "l",O_A_LOWERCASE+11
    CHARMAP "m",O_A_LOWERCASE+12
    CHARMAP "n",O_A_LOWERCASE+13
    CHARMAP "o",O_A_LOWERCASE+14
    CHARMAP "p",O_A_LOWERCASE+15
    CHARMAP "q",O_A_LOWERCASE+16
    CHARMAP "r",O_A_LOWERCASE+17
    CHARMAP "s",O_A_LOWERCASE+18
    CHARMAP "t",O_A_LOWERCASE+19
    CHARMAP "u",O_A_LOWERCASE+20
    CHARMAP "v",O_A_LOWERCASE+21
    CHARMAP "w",O_A_LOWERCASE+22
    CHARMAP "x",O_A_LOWERCASE+23
    CHARMAP "y",O_A_LOWERCASE+24
    CHARMAP "z",O_A_LOWERCASE+25

    CHARMAP "+",O_PLUS
    CHARMAP "<u>",O_MICRO
    CHARMAP "%",O_PERCENT
    CHARMAP "-",O_DASH
    CHARMAP " ",O_SPACE
    CHARMAP "/",O_BAR
    CHARMAP "$",O_COPYRIGHT
    CHARMAP ",",O_COMMA
    CHARMAP ".",O_DOT
    CHARMAP "_",O_UNDERSCORE
    CHARMAP "@",O_AT
    CHARMAP ":",O_COLON
    CHARMAP "#",O_ARROW
    CHARMAP "'",O_APOSTROPHE
    CHARMAP "?",O_QUESTION
    CHARMAP "!",O_EXCLAMATION
    CHARMAP "~",O_NTILDE

    CHARMAP "<nl>", $0A ; New line

;-------------------------------------------------------------------------------

MACRO STR_ADD ; \1 = String, \2 = Name (optional)
IF _NARG == 2
\2:
ENDC
    DB \1,0
IF _NARG == 2
    DEF \2_LEN EQU STRLEN(\1)+1
ENDC
ENDM

;###############################################################################

    ENDC ; TEXT_INC

;###############################################################################
