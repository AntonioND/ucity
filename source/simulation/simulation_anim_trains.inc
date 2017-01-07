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

; NOTE: To be included in "simulation_anims_transport.asm"

;###############################################################################

; Initialize sprites, find starting coordinates for trains, etc.
TrainsReset:

    ; Count the number of train tracks

    ; TODO

    ret

;-------------------------------------------------------------------------------

TrainsHandle:

    ; When a train realizes that there are no tracks under it, unspawn and try
    ; to respawn somewhere else. If there are tracks, move and change directions
    ; if needed. This means that, in practice, trains are only removed when the
    ; track under it is demolished.

    ; TODO

    ret

;###############################################################################
