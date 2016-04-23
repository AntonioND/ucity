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

    SECTION "Room Minimap Variables",WRAM0

;-------------------------------------------------------------------------------

minimap_room_exit: DS 1 ; set to 1 to exit room

minimap_selected_map: DS 1

;###############################################################################

    SECTION "Room Minimap Data",ROMX

;-------------------------------------------------------------------------------

MINIMAP_PALETTES:
    DW (31<<10)|(31<<5)|(31<<0), (21<<10)|(21<<5)|(21<<0)
    DW (10<<10)|(10<<5)|(10<<0), (0<<10)|(0<<5)|(0<<0)
MINIMAP_PALETTE_NUM EQU 1

MINIMAP_BG_MAP:
    INCBIN "minimap_bg_map.bin"

MINIMAP_WIDTH  EQU 20
MINIMAP_HEIGHT EQU 18

MINIMAP_TILES:
    INCBIN "minimap_tiles.bin"
.e:

MINIMAP_TILE_NUM EQU ((.e-MINIMAP_TILES)/16)

;###############################################################################

    SECTION "Room Minimap Functions",ROMX

;-------------------------------------------------------------------------------

MinimapDrawSelectedMap::

    ; Not needed to clear first, the drawing functions draw over everything

    ld      a,[minimap_selected_map]

    cp      a,MINIMAP_SELECTION_GENERAL_VIEW
    jr      nz,.not_general_view
        LONG_CALL   MinimapDrawGeneralView
        ret
.not_general_view:

    cp      a,MINIMAP_SELECTION_ZONE_MAP
    jr      nz,.not_zone_map
        LONG_CALL   MinimapDrawZoneMap
        ret
.not_zone_map:

    cp      a,MINIMAP_SELECTION_TRANSPORT_MAP
    jr      nz,.not_transport_map
        LONG_CALL   MinimapDrawTransportMap
        ret
.not_transport_map:

    cp      a,MINIMAP_SELECTION_POLICE
    jr      nz,.not_police
        LONG_CALL   MinimapDrawPolice
        ret
.not_police:

    cp      a,MINIMAP_SELECTION_FIREMEN
    jr      nz,.not_firemen
        LONG_CALL   MinimapDrawFiremen
        ret
.not_firemen:

    cp      a,MINIMAP_SELECTION_HOSPITALS
    jr      nz,.not_hospitals
        LONG_CALL   MinimapDrawHospitals
        ret
.not_hospitals:

    cp      a,MINIMAP_SELECTION_SCHOOLS
    jr      nz,.not_schools
        LONG_CALL   MinimapDrawSchools
        ret
.not_schools:

    cp      a,MINIMAP_SELECTION_HIGH_SCHOOLS
    jr      nz,.not_high_schools
        LONG_CALL   MinimapDrawHighSchools
        ret
.not_high_schools:

    ld      b,b ; Not found!
    call    MinimapSetDefaultPalette
    call    APA_BufferClear
    call    APA_BufferUpdate

    ret

;###############################################################################

    SECTION "Room Minimap Code Bank 0",ROM0

;-------------------------------------------------------------------------------

APA_PALETTE_DEFAULT:
    DW (31<<10)|(31<<5)|(31<<0), (31<<10)|(31<<5)|(31<<0)
    DW (31<<10)|(31<<5)|(31<<0), (31<<10)|(31<<5)|(31<<0)

MinimapSetDefaultPalette::

    di

    ld      b,144
    call    wait_ly

    ld      hl,APA_PALETTE_DEFAULT
    call    APA_LoadPalette

    ei

    ret

;-------------------------------------------------------------------------------

MinimapSelectMap:: ; a = map to select

    ld      [minimap_selected_map],a

    ret

;-------------------------------------------------------------------------------

InputHandleMinimap:

    call    MinimapMenuMandleInput ; If it returns 1, exit room
    and     a,a
    ret     z ; don't exit

    ; Exit
    ld      a,1
    ld      [minimap_room_exit],a
    ret

;-------------------------------------------------------------------------------

RoomMinimapVBLHandler:

    call    MinimapMenuVBLHandler

    call    refresh_OAM

    ret

;-------------------------------------------------------------------------------

RoomMinimapLoadBG:

    ; Clear APA buffer
    ; ----------------

    call    APA_BufferClear
    call    APA_BufferUpdate

    ; Load border
    ; -----------

    ld      b,BANK(MINIMAP_TILES)
    call    rom_bank_push_set

        ; Load tiles
        ; ----------

        xor     a,a
        ld      [rVBK],a

        ld      bc,MINIMAP_TILE_NUM
        ld      de,256
        ld      hl,MINIMAP_TILES
        call    vram_copy_tiles

        ; Load map
        ; --------

        ; Tiles
        xor     a,a
        ld      [rVBK],a

        ld      de,$9800
        ld      hl,MINIMAP_BG_MAP

        ld      a,MINIMAP_HEIGHT
.loop1:
        push    af

        ld      b,MINIMAP_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-MINIMAP_WIDTH
        add     hl,de
        ld      d,h
        ld      e,l
        pop     hl

        pop     af
        dec     a
        jr      nz,.loop1

        ; Attributes
        ld      a,1
        ld      [rVBK],a

        ld      de,$9800

        ld      a,MINIMAP_HEIGHT
.loop2:
        push    af

        ld      b,MINIMAP_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-MINIMAP_WIDTH
        add     hl,de
        ld      d,h
        ld      e,l
        pop     hl

        pop     af
        dec     a
        jr      nz,.loop2

        ; Prepare APA map
        ; ---------------

        LONG_CALL   APA_ResetBackgroundMapping

        ; Load palettes
        ; -------------

        di
        ld      b,144
        call    wait_ly

        xor     a,a
        ld      hl,MINIMAP_PALETTES
.loop_pal:
        push    af
        call    bg_set_palette ; a = palette number - hl = pointer to data
        pop     af
        inc     a
        cp      a,MINIMAP_PALETTE_NUM
        jr      nz,.loop_pal

        ld      hl,APA_PALETTE_DEFAULT
        call    APA_LoadPalette

        ei

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

RoomMinimapDrawTitle:: ; hl = ptr to text string

    xor     a,a
    ld      [rVBK],a

    push    hl ; save string (*)

    ; Clear previous title

    ld      hl,$9800
    ld      b,20
.clear_loop:
    WAIT_SCREEN_BLANK ; Clobbers A and C
    xor     a,a
    ld      [hl+],a
    dec     b
    jr      nz,.clear_loop

    ; Calculate length and store in b

    pop     hl ; get string (*)
    push    hl ; save string (**)

    ld      b,0
.count_loop:
    ld      a,[hl+]
    and     a,a
    jr      z,.count_end
    inc     b
    jr      .count_loop
.count_end:

    ; Calculate starting point of text string

    ld      a,20 ; Screen tile width
    sub     a,b
    sra     a ; a = (20-length)/2

    ld      l,a
    ld      h,0
    ld      de,$9800
    add     hl,de
    LD_DE_HL

    ; Draw

    pop     hl ; get string (**)

.loop:
    ld      a,[hl+]
    and     a,a
    ret     z ; return from function from here!

    push    hl
    push    de
    call    ASCII2Tile
    pop     de
    pop     hl

    ld      b,a
    WAIT_SCREEN_BLANK ; Clobbers A and C
    ld      a,b

    ld      [de],a
    inc     de

    jr      .loop

;-------------------------------------------------------------------------------

RoomMinimap::

    call    SetPalettesAllBlack

    call    MinimapMenuReset

    ld      bc,RoomMinimapVBLHandler
    call    irq_set_VBL

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ld      [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    call    RoomMinimapLoadBG

    di

    ld      b,144
    call    wait_ly
    call    LoadTextPalette

    ei

    ld      a,MINIMAP_SELECTION_GENERAL_VIEW
    ld      [minimap_selected_map],a
    LONG_CALL   MinimapDrawSelectedMap

    ; This can be loaded after the rest, it isn't shown until A is pressed so
    ; there is no hurry.
    call    MinimapMenuLoadGFX

    xor     a,a
    ld      [minimap_room_exit],a

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleMinimap

    ld      a,[minimap_room_exit]
    and     a,a
    jr      z,.loop

    call    SetDefaultVBLHandler

    call    SetPalettesAllBlack

    ret

;###############################################################################
