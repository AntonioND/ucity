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

    INCLUDE "hardware.inc"
    INCLUDE "engine.inc"

;-------------------------------------------------------------------------------

    INCLUDE "text.inc"

;###############################################################################

    SECTION "Room Gen Map Variables",WRAM0

;-------------------------------------------------------------------------------

gen_map_seed: DS 1
gen_map_generated: DS 1 ; set to 1 after generating a map

gen_map_room_exit:  DS 1 ; set to 1 to exit room

    DEF GEN_MAP_SELECT_WATER EQU 0
    DEF GEN_MAP_SELECT_LAND  EQU 1
gen_map_selection: DS 1

;###############################################################################

    SECTION "Room Gen Map Code Data",ROMX

;-------------------------------------------------------------------------------

GEN_MAP_BG_MAP:
    INCBIN "map_gen_minimap_bg_map.bin"

    DEF GEN_MAP_MENU_WIDTH  EQU 20
    DEF GEN_MAP_MENU_HEIGHT EQU 18

;-------------------------------------------------------------------------------

GenMapUpdateGUI:

    xor     a,a
    ldh     [rVBK],a ; Tile map

    ; Draw seed

    ld      a,[gen_map_seed]
    ld      b,a
    swap    a
    and     a,$0F
    BCD2Tile
    ld      d,a ; MSB
    ld      a,b
    and     a,$0F
    BCD2Tile
    ld      e,a ; LSB

    ld      hl,$9800 + 7*32 + 4

    di ; critical section

    WAIT_SCREEN_BLANK ; clobbers A and C

    ld      a,d
    ld      [hl+],a
    ld      [hl],e ; 5 cycles. there should be enough time in LCD mode 2

    ei ; end of critical section

    ; Clear type map cursor

    ld      hl,$9800 + 10*32 + 1
    ld      de,32*2
    ld      b,O_SPACE
    di
    WAIT_SCREEN_BLANK ; clobbers A and C
    ld      [hl],b
    add     hl,de
    ld      [hl],b
    ei

    ; Draw cursor

    ld      a,[gen_map_selection]
    swap    a
    add     a,a ; sla a
    add     a,a ; sla a
    ; a <<= 6 ( = 32 * 2)
    ld      e,a
    ld      d,0
    ld      hl,$9800 + 10*32 + 1
    add     hl,de

    ld      b,O_ARROW

    di ; critical section

    WAIT_SCREEN_BLANK ; clobbers A and C

    ld      [hl],b

    reti ; end of critical section

;-------------------------------------------------------------------------------

GenMapGenerate:

    ld      a,[gen_map_seed] ; 21 is the default of the algorithm...
    add     a,$80 ; I don't like the results of the seed 0 for water, so
    ld      b,a ; let's hide it... :P
    ld      c,229 ; b, c = seeds

    ld      a,[gen_map_selection]
    cp      a,GEN_MAP_SELECT_LAND
    jr      nz,.not_land
        ld      d,-$18 ; More land
        jr      .end_selection
.not_land:
        ld      d,0 ; More water
.end_selection: ; d = offset

    LONG_CALL_ARGS  map_generate ; b = seed x, c = seed y (229), d = offset

    ret

;-------------------------------------------------------------------------------

GenMapHandleInput: ; If it returns 1, exit room. If 0, continue

    ld      a,[joy_pressed]
    and     a,PAD_UP|PAD_DOWN
    jr      z,.end_up_down
        ld      hl,gen_map_selection
        ld      a,[hl]
        xor     a,1
        ld      [hl],a
        call    GenMapUpdateGUI
.end_up_down:

    ld      a,[joy_pressed]
    and     a,PAD_RIGHT
    jr      z,.end_right
        ld      hl,gen_map_seed
        inc     [hl]
        call    GenMapUpdateGUI
.end_right:
    ld      a,[joy_pressed]
    and     a,PAD_LEFT
    jr      z,.end_left
        ld      hl,gen_map_seed
        dec     [hl]
        call    GenMapUpdateGUI
.end_left:

    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      z,.end_a

        di ; Entering critical section

        ld      b,$91
        call    wait_ly

        ld      hl,GEN_MAP_EMPTY_PALETTE_BLACK
        call    APA_LoadPalette

        ei ; End of critical section

        call    GenMapGenerate

        ld      a,1
        ld      [gen_map_generated],a
.end_a:

    ; Exit if START is pressed and a map is generated
    ld      a,[joy_pressed]
    and     a,PAD_START
    jr      z,.end_start
        ld      a,[gen_map_generated]
        ret ; return 1 if map has been generated
.end_start:

    xor     a,a
    ret ; return 0

;-------------------------------------------------------------------------------

InputHandleGenMap:

    call    GenMapHandleInput ; If it returns 1, exit room. If 0, continue
    and     a,a
    ret     z ; don't exit

    ; Exit
    ld      a,1
    ld      [gen_map_room_exit],a
    ret

;-------------------------------------------------------------------------------

RoomGenMapLoadBG:

    ; Load border
    ; -----------

    ld      b,BANK(GEN_MAP_BG_MAP)
    call    rom_bank_push_set

        ; Load map
        ; --------

        ; Tiles
        xor     a,a
        ldh     [rVBK],a

        ld      de,$9800
        ld      hl,GEN_MAP_BG_MAP

        ld      a,GEN_MAP_MENU_HEIGHT
.loop1:
        push    af

        ld      b,GEN_MAP_MENU_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-GEN_MAP_MENU_WIDTH
        add     hl,de
        ld      d,h
        ld      e,l
        pop     hl

        pop     af
        dec     a
        jr      nz,.loop1

        ; Attributes
        ld      a,1
        ldh     [rVBK],a

        ld      de,$9800

        ld      a,GEN_MAP_MENU_HEIGHT
.loop2:
        push    af

        ld      b,GEN_MAP_MENU_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-GEN_MAP_MENU_WIDTH
        add     hl,de
        ld      d,h
        ld      e,l
        pop     hl

        pop     af
        dec     a
        jr      nz,.loop2

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

GEN_MAP_EMPTY_PALETTE_BLACK:
    DW 0, 0, 0, 0

GEN_MAP_EMPTY_PALETTE_WHITE:
    DW $7FFF, $7FFF, $7FFF, $7FFF

RoomGenerateMap::

    call    SetPalettesAllBlack

    ld      a,0
    ld      [gen_map_generated],a

    ld      a,GEN_MAP_SELECT_WATER
    ld      [gen_map_selection],a

    call    SetDefaultVBLHandler

    xor     a,a
    ldh     [rSCX],a
    ldh     [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ldh     [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    call    RoomGenMapLoadBG

    LONG_CALL   APA_BufferFillColor3
    call    APA_BufferUpdate

    call    LoadTextPalette

    ld      hl,GEN_MAP_EMPTY_PALETTE_WHITE
    call    APA_LoadPalette

    xor     a,a
    ld      [gen_map_room_exit],a

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleGenMap

    ld      a,[gen_map_room_exit]
    and     a,a
    jr      z,.loop

    call    WaitReleasedAllKeys

    call    SetPalettesAllBlack

    LONG_CALL   map_tilemap_to_real_tiles

    ret

;###############################################################################
