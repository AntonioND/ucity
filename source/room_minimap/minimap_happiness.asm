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

;###############################################################################

    SECTION "Minimap Happiness Map Functions",ROMX

;-------------------------------------------------------------------------------

MINIMAP_HAPPINESS_MAP_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (0<<10)|(31<<5)|(0<<0)
    DW (0<<10)|(31<<5)|(31<<0), (0<<10)|(0<<5)|(31<<0)

MINIMAP_HAPPINESS_MAP_TITLE:
    DB "Happinness",0

MinimapDrawHappinessMap::

    ; No need to simulate, get data from CITY_MAP_FLAGS

    ; Draw map
    ; --------

    LONG_CALL   APA_PixelStreamStart

    ld      hl,CITY_MAP_TILES ; Base address of the map!

.loop:

    push    hl

            ld      a,BANK_CITY_MAP_FLAGS
            ld      [rSVBK],a

            ld      a,[hl]

;TILE_OK_POWER_BIT
;TILE_OK_SERVICES_BIT
;TILE_OK_EDUCATION_BIT
;TILE_OK_POLLUTION_BIT
;TILE_OK_TRAFFIC_BIT

            rra
            and     a,2
            ld      b,a
            ld      c,a
            ld      d,a

            call    APA_SetColors ; a,b,c,d = color (0 to 3)
            LONG_CALL   APA_PixelStreamPlot2x2

    pop     hl

    inc     hl

    bit     5,h ; Up to E000
    jr      z,.loop


    ; Set White
    call    MinimapSetDefaultPalette

    ; Refresh screen with backbuffer data
    call    APA_BufferUpdate

    ; Load palette
    ld      hl,MINIMAP_HAPPINESS_MAP_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_HAPPINESS_MAP_TITLE
    call    RoomMinimapDrawTitle

    ret

;###############################################################################
