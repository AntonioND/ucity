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
    INCLUDE "engine.inc"

;-------------------------------------------------------------------------------

    INCLUDE "room_game.inc"
    INCLUDE "room_minimap.inc"

;###############################################################################

    SECTION "Minimap Menu Variables",WRAM0

;-------------------------------------------------------------------------------

;###############################################################################

    SECTION "Minimap Menu Data",ROMX

;-------------------------------------------------------------------------------

MINIMAP_MENU_SPRITES:
    INCBIN "minimap_menu_sprites.bin"

;###############################################################################

    SECTION "Minimap Menu Functions",ROMX

;-------------------------------------------------------------------------------

;###############################################################################

    SECTION "Minimap Menu Code Bank 0",ROM0

;-------------------------------------------------------------------------------

;###############################################################################
