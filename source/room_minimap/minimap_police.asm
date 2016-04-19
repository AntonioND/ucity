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
    INCLUDE "text.inc"

;###############################################################################

    SECTION "Minimap Police Functions",ROMX

;-------------------------------------------------------------------------------

C_WHITE  EQU 0
C_BLUE   EQU 1
C_RED    EQU 2
C_BLACK  EQU 3

MINIMAP_POLICE_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (31<<10)|(0<<5)|(0<<0)
    DW (0<<10)|(0<<5)|(31<<0), (0<<10)|(0<<5)|(0<<0)

MINIMAP_POLICE_TITLE:
    DB O_A_UPPERCASE + "P" - "A"
    DB O_A_LOWERCASE + "o" - "a"
    DB O_A_LOWERCASE + "l" - "a"
    DB O_A_LOWERCASE + "i" - "a"
    DB O_A_LOWERCASE + "c" - "a"
    DB O_A_LOWERCASE + "e" - "a"
    DB 0

;-------------------------------------------------------------------------------

MinimapDrawPolice::

    ; Simulate and get data!
    ; ----------------------

    LONG_CALL   Simulation_Police

    ; Draw map
    ; --------

    LONG_CALL   APA_PixelStreamStart

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)

            call    GetMapAddress ; e = x , d = y. returns address in hl

            ld      a,BANK_SCRATCH_RAM
            ld      [rSVBK],a

            ld      a,[hl]
            and     a,a
            jr      z,.zero

            ld      a,3
            ld      b,3
            ld      c,3
            ld      d,3
            jr      .end
.zero:

            ld      a,0
            ld      b,0
            ld      c,0
            ld      d,0
.end:

            call    APA_SetColors ; a,b,c,d = color (0 to 3)
            LONG_CALL   APA_PixelStreamPlot2x2

        pop     de ; (*)

        inc     e
        bit     6,e
        jp      z,.loopx

    inc     d
    bit     6,d
    jp      z,.loopy

    ; Set White
    call    MinimapSetDefaultPalette

    ; Refresh screen with backbuffer data
    call    APA_BufferUpdate

    ; Load palette
    ld      hl,MINIMAP_POLICE_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_POLICE_TITLE
    call    RoomMinimapDrawTitle

    ret

;###############################################################################
