;###############################################################################
;
;    µCity - City building game for Game Boy Color.
;    Copyright (C) 2017 Antonio Niño Díaz (AntonioND/SkyLyrac)
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

    IF !DEF(BG_HANDLER_INC)
BG_HANDLER_INC SET 1

;###############################################################################
;#                                                                             #
;#                                   MACROS                                    #
;#                                                                             #
;###############################################################################

;-------------------------------------------------------------------------------
;- BG_LOAD()    \1 = bg label    d = x    e = y                                -
;-------------------------------------------------------------------------------

    GLOBAL  _bg_load

BG_LOAD : MACRO   ;   bg label
    ld      b,BANK(\1)
    ld      hl,\1
    call    _bg_load
ENDM

;###############################################################################
;#                                                                             #
;#                                  FUNCTIONS                                  #
;#                                                                             #
;###############################################################################

;-------------------------------------------------------------------------------
;- bg_vbl_handler()                                                            -
;- bg_reload()                                                                 -
;-------------------------------------------------------------------------------

    GLOBAL  bg_vbl_handler
    GLOBAL  bg_reload

;-------------------------------------------------------------------------------
;- bg_scroll_XXXXX()    a = returned value (1 if scrolled, 0 if not)           -
;-------------------------------------------------------------------------------

    GLOBAL  bg_scroll_right
    GLOBAL  bg_scroll_left
    GLOBAL  bg_scroll_down
    GLOBAL  bg_scroll_up

;###############################################################################

    ENDC ; BG_HANDLER_INC

;###############################################################################
