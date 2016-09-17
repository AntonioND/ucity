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
O_PERCENT       EQU 39
O_DASH          EQU 40
O_CURSOR        EQU 41
O_RCI_BASE_BAR  EQU 42
O_SPACE         EQU 53
O_BAR           EQU 54
O_COPYRIGHT     EQU 55 ; Mapped to "$"
O_COMMA         EQU 56
O_DOT           EQU 57
O_UNDERSCORE    EQU 58
O_AT            EQU 59
O_COLON         EQU 60
O_ARROW         EQU 61 ; Mapped to "#"
O_APOSTROPHE    EQU 62
O_QUESTION      EQU 63
O_EXCLAMATION   EQU 64
O_NTILDE        EQU 65 ; Mapped to "~"
O_ZERO          EQU 66
O_A_UPPERCASE   EQU 76
O_A_LOWERCASE   EQU 102
O_NONE          EQU O_QUESTION

;-------------------------------------------------------------------------------

BCD2Tile : MACRO ; a = number from 0 to 9. Returns tile number in a
    add     a,O_ZERO
ENDM

;-------------------------------------------------------------------------------

; To use this macro, do:
;     String2Tiles "S","t","r","i","n","g",0
; This macro can (probably?) have as many arguments as needed. Normally, RGBDS
; only lets the code access the lower 9 values (\1 to \9), but actually there
; can be up to MAXMACROARGS arguments (as of now, 256).

String2Tiles : MACRO

String2TilesLenght SET 0

    REPT _NARG ; Repeat for each argument (even if there are more than 9!)

        IF \1 == "%"
            DB O_PERCENT
        ENDC
        IF \1 == "-"
            DB O_DASH
        ENDC
        IF \1 == " "
            DB O_SPACE
        ENDC
        IF \1 == "/"
            DB O_BAR
        ENDC
        IF \1 == "$"
            DB O_COPYRIGHT
        ENDC
        IF \1 == ","
            DB O_COMMA
        ENDC
        IF \1 == "."
            DB O_DOT
        ENDC
        IF \1 == "_"
            DB O_UNDERSCORE
        ENDC
        IF \1 == "@"
            DB O_AT
        ENDC
        IF \1 == ":"
            DB O_COLON
        ENDC
        IF \1 == "#"
            DB O_ARROW
        ENDC
        IF \1 == "'"
            DB O_APOSTROPHE
        ENDC
        IF \1 == "?"
            DB O_QUESTION
        ENDC
        IF \1 == "!"
            DB O_EXCLAMATION
        ENDC
        IF \1 == "~"
            DB O_NTILDE
        ENDC
        IF \1 >= "0" && \1 <= "9"
            DB O_ZERO + \1 - "0"
        ENDC
        IF \1 >= "A" && \1 <= "Z"
            DB O_A_UPPERCASE + \1 - "A"
        ENDC
        IF \1 >= "a" && \1 <= "z"
            DB O_A_LOWERCASE + \1 - "a"
        ENDC
        IF \1 == 0
            DB 0
        ENDC

        SHIFT ; Get next argument

String2TilesLenght SET String2TilesLenght + 1

    ENDR

ENDM

;###############################################################################

    ENDC ; TEXT_INC

;###############################################################################
