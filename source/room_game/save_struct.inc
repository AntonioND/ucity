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

    IF !DEF(SAVE_STRUCT_INC)
SAVE_STRUCT_INC SET 1

;###############################################################################

    INCLUDE "hardware.inc"

;-------------------------------------------------------------------------------

    INCLUDE "money.inc"

;###############################################################################

MAGIC_STRING        SET "BCTY"
MAGIC_STRING_LEN    SET STRLEN({MAGIC_STRING})

;-------------------------------------------------------------------------------

SAV_PTR SET 0

SAV_ADD_FIELD : MACRO ; \1 = Name of the field, \2 = Size
\1      EQU _SRAM+SAV_PTR ; Save absolute address, not offset of SRAM bank
SAV_PTR SET SAV_PTR+(\2)
ENDM

SAV_SET_PTR : MACRO ; \1 = Value to set the pointer to
IF (\1) < SAV_PTR
    FAIL "Space already used by save data!"
ENDC
SAV_PTR SET (\1)
ENDM

;-------------------------------------------------------------------------------

; Save file definitions. Each offset must be added to SRAM base address: $A000
; Each SRAM bank can hold information for one city.

    SAV_SET_PTR     0 ; Start

    SAV_ADD_FIELD   SAV_MAGIC_STRING, MAGIC_STRING_LEN

    SAV_ADD_FIELD   SAV_CHECKSUM, 2

    SAV_ADD_FIELD   SAV_MONEY, MONEY_AMOUNT_SIZE

    SAV_ADD_FIELD   SAV_YEAR,  2
    SAV_ADD_FIELD   SAV_MONTH, 1

    SAV_ADD_FIELD   SAV_TAX_PERCENT, 1

    SAV_ADD_FIELD   SAV_LAST_SCROLL_X, 1
    SAV_ADD_FIELD   SAV_LAST_SCROLL_Y, 1

    SAV_ADD_FIELD   SAV_MAP_ATTR_BASE, $1000/8

    SAV_SET_PTR     $1000 ; Align to $1000

    SAV_ADD_FIELD   SAV_MAP_TILE_BASE, $1000

;###############################################################################

    ENDC ; SAVE_STRUCT_INC

;###############################################################################
