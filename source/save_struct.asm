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

    INCLUDE "hardware.inc"

;-------------------------------------------------------------------------------

    INCLUDE "money.inc"
    INCLUDE "room_text_input.inc"
    INCLUDE "save_struct.inc"
    INCLUDE "text_messages.inc"

;###############################################################################

    SECTION "Save Data", SRAM[_SRAM]

;-------------------------------------------------------------------------------

; Each SRAM bank can hold information for one city.

; Magic string must always be first, checksum second.
SAV_MAGIC_STRING:: DS MAGIC_STRING_LEN
SAV_CHECKSUM::     DS 2 ; LSB first

SAV_CITY_NAME:: DS TEXT_INPUT_LENGTH

SAV_MONEY:: DS MONEY_AMOUNT_SIZE

SAV_YEAR::  DS 2 ; LSB first
SAV_MONTH:: DS 1

SAV_TAX_PERCENT:: DS 1

SAV_LAST_SCROLL_X:: DS 1
SAV_LAST_SCROLL_Y:: DS 1

SAV_PERSISTENT_MSG:: DS BYTES_SAVE_PERSISTENT_MSG

SAV_MAP_ATTR_BASE::  DS $1000/8 ; compressed, only the bank 0/1 bit is saved

SAV_OPTIONS_DISASTERS_DISABLED:: DS 1

; TODO : Reorganize every field so that it makes sense

;-------------------------------------------------------------------------------

    SECTION "Save Data 2", SRAM[_SRAM+$1000]

;-------------------------------------------------------------------------------

SAV_MAP_TILE_BASE:: DS $1000 ; Aligned to $1000

;###############################################################################
