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

    IF !DEF(TEXT_MESSAGES_INC)
    DEF TEXT_MESSAGES_INC = 1

;###############################################################################

    DEF ROM_BANK_TEXT_MSG EQU 3

;-------------------------------------------------------------------------------

    ; Labels should be named MSG_xxxx and IDs should be named ID_MSG_xxxx

    DEF ID_MSG_EMPTY EQU 0

    ; Messages that are only shown once per year.
    DEF ID_MSG_POLLUTION_HIGH           EQU 1
    DEF ID_MSG_TRAFFIC_HIGH             EQU 2
    DEF ID_MSG_MONEY_NEGATIVE_CAN_LOAN  EQU 3
    DEF ID_MSG_MONEY_NEGATIVE_CANT_LOAN EQU 4

    DEF ID_MSG_RESET_YEAR_NUM   EQU 8 ; Multiple of 8

    ; Persistent messages (they are only shown once per city)
    DEF ID_MSG_CLASS_TOWN       EQU 9
    DEF ID_MSG_CLASS_CITY       EQU 10
    DEF ID_MSG_CLASS_METROPOLIS EQU 11
    DEF ID_MSG_CLASS_CAPITAL    EQU 12
    DEF ID_MSG_TECH_NUCLEAR     EQU 13
    DEF ID_MSG_TECH_FUSION      EQU 14

    DEF ID_MSG_PERSISTENT_NUM EQU 16 ; Multiple of 8

    ; Regular messages
    DEF ID_MSG_FIRE_INITED             EQU 17
    DEF ID_MSG_NUCLEAR_MELTDOWN        EQU 18
    DEF ID_MSG_TECH_INSUFFICIENT       EQU 19
    DEF ID_MSG_POPULATION_INSUFFICIENT EQU 20
    DEF ID_MSG_FINISHED_LOAN           EQU 21
    DEF ID_MSG_GAME_OVER_1             EQU 22
    DEF ID_MSG_GAME_OVER_2             EQU 23

    ; Extra
    DEF ID_MSG_CUSTOM EQU $FF ; Can only be in the queue once! Careful with it!

;-------------------------------------------------------------------------------

    ; Number of bytes needed to store a flag for each persistent message.
    DEF BYTES_SAVE_PERSISTENT_MSG EQU ((ID_MSG_PERSISTENT_NUM+7)/8) ; Round up to 8 bits

;###############################################################################

    ENDC ; TEXT_MESSAGES_INC

;###############################################################################
