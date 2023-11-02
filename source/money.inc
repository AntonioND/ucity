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

    IF !DEF(MONEY_INC)
    DEF MONEY_INC = 1

;###############################################################################

    DEF TAX_PERCENTAGE_MAX EQU 20

;-------------------------------------------------------------------------------

    DEF MONEY_AMOUNT_SIZE EQU 5 ; 5 bytes

;-------------------------------------------------------------------------------

; Create an array of bytes consisting on the money amount passed as argument
; Up to 10 digits!
MACRO DATA_MONEY_AMOUNT ; \1 = Label, \2 = Amount
    IF \2 > 9999999999
        FAIL "Invalid amount of money."
    ENDC
    IF \2 < 0
        FAIL "Invalid amount of money."
    ENDC
\1:
    DB   (\2              % 10)  |  (((\2 / 10)         % 10) << 4)
    DB  ((\2 / 100)       % 10)  |  (((\2 / 1000)       % 10) << 4)
    DB  ((\2 / 10000)     % 10)  |  (((\2 / 100000)     % 10) << 4)
    DB  ((\2 / 1000000)   % 10)  |  (((\2 / 10000000)   % 10) << 4)
    DB  ((\2 / 100000000) % 10)  |  (((\2 / 1000000000) % 10) << 4)
ENDM

;###############################################################################

    ENDC ; MONEY_INC

;###############################################################################
