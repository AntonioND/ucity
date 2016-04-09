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
    INCLUDE "building_info.inc"
    INCLUDE "text.inc"

;###############################################################################

    SECTION "Status Bar Functions",ROMX

;-------------------------------------------------------------------------------

STATUS_BAR_MAP:
.s:
    INCBIN "data/info_bar_game_map.bin"
.e:

STATUS_BAR_MAP_ROWS EQU (((.e-.s)/20)/2)

;###############################################################################

    SECTION "Status Bar Variables",WRAM0

;-------------------------------------------------------------------------------

status_bar_active:  DS 1
status_bar_on_top:: DS 1 ; 1 if on top, 0 if on the bottom

status_menu_active:    DS 1 ; if 1, show menu
status_menu_selection: DS 1

MENU_NUMBER_ELEMENTS EQU 6

;###############################################################################

    SECTION "Status Bar Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

StatusBarRefreshStatRegisters:

    ld      a,[status_bar_active]
    and     a,a
    ret     z

    ; Check if on top or at the bottom
    ld      a,[CursorY]

    cp      a,(SCRN_Y/2)-24
    jr      nc,.dont_set_on_bottom
    ld      a,0
    ld      [status_bar_on_top],a
    jr      .end_set
.dont_set_on_bottom:

    ld      b,a
    ld      a,[CursorSizeY]
    rla
    rla
    rla ; * 8
    add     a,b
    cp      a,(SCRN_Y/2)+24+16+8
    jr      c,.dont_set_on_top
    ld      a,1
    ld      [status_bar_on_top],a
.dont_set_on_top:

.end_set:

    ld      a,[status_bar_on_top]
    and     a,a
    jr      nz,.on_top

        ; At the bottom
        ld      a,0
        ld      [status_bar_on_top],a

        ld      a,144-16-1
        ld      [rLYC],a

        ld      a,144-16
        ld      [rWY],a
        ld      a,7
        ld      [rWX],a

    jr      .end_config
.on_top:

        ; On top
        ld      a,1
        ld      [status_bar_on_top],a

        ld      a,16-1
        ld      [rLYC],a

        ld      a,0
        ld      [rWY],a
        ld      a,7
        ld      [rWX],a

    ; End configuration
.end_config:

    ret

;-------------------------------------------------------------------------------

StatusBarHandlerSTAT:

;    ld      a,[status_bar_active]
;    and     a,a
;    ret     z

    ; Check if on top or at the bottom
    ld      a,[status_bar_on_top]
    and     a,a
    jr      nz,.on_top

        ; At the bottom
        call    wait_screen_blank

        ld      a,[game_sprites_8x16]
        or      a,LCDCF_BG9C00|LCDCF_OBJON|LCDCF_WIN9800|LCDCF_WINON|LCDCF_ON|LCDCF_BG8000
        ld      [rLCDC],a

        ld      a,7
        ld      [rWX],a

    ret
.on_top:

        ; On top
        call    wait_screen_blank
        ld      a,[game_sprites_8x16]
        or      a,LCDCF_BG9C00|LCDCF_OBJON|LCDCF_WIN9800|LCDCF_WINON|LCDCF_ON|LCDCF_BG8800
        ld      [rLCDC],a

        ld      a,255
        ld      [rWX],a

    ret

;-------------------------------------------------------------------------------

StatusBarHandlerVBL::

    ld      a,[status_bar_active]
    and     a,a
    ret     z

    call    StatusBarRefreshStatRegisters

    ; Check if on top or at the bottom
    ld      a,[status_bar_on_top]
    and     a,a
    jr      nz,.on_top

        ; At the bottom
        ld      a,[game_sprites_8x16]
        or      a,LCDCF_BG9C00|LCDCF_OBJON|LCDCF_WIN9800|LCDCF_WINON|LCDCF_ON|LCDCF_BG8800
        ld      [rLCDC],a

        ld      a,255
        ld      [rWX],a

        jr      .end
.on_top:

        ; On top
        ld      a,[game_sprites_8x16]
        or      a,LCDCF_BG9C00|LCDCF_OBJON|LCDCF_WIN9800|LCDCF_WINON|LCDCF_ON|LCDCF_BG8000
        ld      [rLCDC],a

        ld      a,7
        ld      [rWX],a

.end:

    call    BuildOverlayIconRefresh

    ret

;-------------------------------------------------------------------------------

StatusBarHide::

    ld      a,[status_bar_active]
    and     a,a
    ret     z ; return if already hidden

    xor     a,a
    ld      [status_bar_active],a
    ld      [status_menu_active],a

    ld      hl,rIE
    res     1,[hl]

    ld      a,[game_sprites_8x16]
    or      a,LCDCF_BG9C00|LCDCF_OBJON|LCDCF_WIN9800|LCDCF_WINON|LCDCF_ON|LCDCF_BG8800
    ld      [rLCDC],a

    xor     a,a
    ld      [rSTAT],a

    ld      bc,$0000
    call    irq_set_LCD

    ld      a,255
    ld      [rWX],a
    ld      [rWY],a

    ret

;-------------------------------------------------------------------------------

StatusBarShow::

    ld      a,[status_bar_active]
    and     a,a
    ret     nz ; return if already shown

    ld      a,1
    ld      [status_bar_active],a

    ; At the bottom
    xor     a,a
    ld      [status_bar_on_top],a

    call    StatusBarRefreshStatRegisters

    ld      a,STATF_LYC
    ld      [rSTAT],a

    ld      bc,StatusBarHandlerSTAT
    call    irq_set_LCD

    ld      hl,rIF
    res     1,[hl]
    ld      hl,rIE
    set     1,[hl]

    ret

;-------------------------------------------------------------------------------

StatusBarMenuHide::

    ld      a,[status_menu_active]
    and     a,a
    ret     z ; return if not shown

    xor     a,a
    ld      [status_menu_active],a

    ld      a,[game_sprites_8x16]
    or      a,LCDCF_BG9C00|LCDCF_OBJON|LCDCF_WIN9800|LCDCF_WINON|LCDCF_ON|LCDCF_BG8800
    ld      [rLCDC],a

    ld      a,255
    ld      [rWX],a
    ld      [rWY],a

    ret

;-------------------------------------------------------------------------------

StatusBarMenuShow::

    ld      a,[status_menu_active]
    and     a,a
    ret     nz ; return if already shown

    xor     a,a
    ld      [rWY],a
    ;ld      [rSCY],a
    ;ld      [rSCX],a
    ld      a,7
    ld      [rWX],a

    ld      a,LCDCF_BG8000|LCDCF_WIN9800|LCDCF_WINON|LCDCF_ON
    ld      [rLCDC],a

    ; Clear cursor positions except for the first one
    xor     a,a
.loop:
    push    af
    ld      [status_menu_selection],a
    call    StatusBarMenuClearCursor
    pop     af
    inc     a
    cp      a,MENU_NUMBER_ELEMENTS
    jr      nz,.loop

    ld      a,1
    ld      [status_menu_active],a

    xor     a,a
    ld      [status_bar_on_top],a
    ld      [status_menu_selection],a

    call    StatusBarMenuDrawCursor


    ret

;-------------------------------------------------------------------------------

StatusBarMenuLoadGfx::

    xor     a,a
    ld      [status_bar_active],a

    ld      b,BANK(STATUS_BAR_MAP)
    call    rom_bank_push_set

    xor     a,a
    ld      [rVBK],a

    ld      a,STATUS_BAR_MAP_ROWS
    ld      hl,STATUS_BAR_MAP
    ld      de,$9800
.loop_tiles:
    push    af
    ld      bc,20
    call    vram_copy
    push    hl
    ld      hl,12
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    pop     af
    dec     a
    jr      nz,.loop_tiles

    ld      a,1
    ld      [rVBK],a

    ld      a,STATUS_BAR_MAP_ROWS
    ;ld      hl,STATUS_BAR_MAP+(STATUS_BAR_MAP_ROWS/2)*20
    ld      de,$9800
.loop_attrs:
    push    af
    ld      bc,20
    call    vram_copy
    push    hl
    ld      hl,12
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    pop     af
    dec     a
    jr      nz,.loop_attrs

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

StatusBarUpdate::

    ld      a,[status_bar_active]
    ld      b,a
    ld      a,[status_menu_active]
    or      a,b
    ret     z ; return if not menu or status bar active

    add     sp,-10 ; (*)

    call    GameStateMachineStateGet

    cp      a,GAME_STATE_WATCH
    jr      z,.watch
    cp      a,GAME_STATE_EDIT
    jr      z,.edit
    cp      a,GAME_STATE_WATCH_FAST_MOVE
    jr      z,.end ; nothing
    cp      a,GAME_STATE_SELECT_BUILDING
    jr      z,.building
    cp      a,GAME_STATE_PAUSE_MENU
    jr      z,.pause

    ld      b,b ; Catch invalid state
    jr      .end

.watch: ; Money + Date + RCI
    call    .print_money
    call    .print_date
    call    .print_rci
    jr      .end

.edit: ; Money + Price + No RCI
    call    .print_money
    call    .print_price
    call    .print_hide_rci_black
    jr      .end

.building: ; Money + Price + RCI
    call    .print_money
    call    .print_price
    call    .print_rci
    jr      .end

.pause: ; Money + Date + Population
    call    .print_money
    call    .print_date
    call    .print_population
    call    .print_rci
    jr      .end

.end: ; Exit

    add     sp,+10 ; (*)

    ret

;-----------------------------------

.print_money:
    ; Convert to tile from BCD
    ld      de,MoneyWRAM ; BCD, LSB first, LSB in lower nibbles
    ld      hl,sp+2
    call    BCD_DE_2TILE_HL_LEADING_SPACES

    ; Copy to VRAM
    xor     a,a
    ld      [rVBK],a

    ld      b,10
    ld      hl,sp+2
    LD_DE_HL
    ld      hl,$9800+32*0+6
    call    vram_nitro_copy

    ret

;-----------------------------------

.price_label:
    DB O_A_UPPERCASE - "A" + "P"
    DB O_A_LOWERCASE - "a" + "r"
    DB O_A_LOWERCASE - "a" + "i"
    DB O_A_LOWERCASE - "a" + "c"
    DB O_A_LOWERCASE - "a" + "e"
    DB O_COLON
.end_price_label:

PRICE_LABEL_LEN EQU .end_price_label - .price_label

.print_price:
    call    BuildingTypeGet
    cp      a,B_None
    ret     z

    ; Convert to tile from BCD
    call    BuildingSelectedGetPricePointer ; returns pointer in de
    ; BCD, LSB first, LSB in lower nibbles
    ld      hl,sp+2
    call    BCD_DE_2TILE_HL_LEADING_SPACES

    ; Copy to VRAM
    xor     a,a
    ld      [rVBK],a

    ld      b,10
    ld      hl,sp+2
    LD_DE_HL
    ld      hl,$9800+32*1+6
    call    vram_nitro_copy

    ld      b,PRICE_LABEL_LEN
    ld      de,.price_label
    ld      hl,$9800+32*1+0
    call    vram_nitro_copy

    ret

;-----------------------------------

.date_label:
    DB O_A_UPPERCASE - "A" + "D"
    DB O_A_LOWERCASE - "a" + "a"
    DB O_A_LOWERCASE - "a" + "t"
    DB O_A_LOWERCASE - "a" + "e"
    DB O_COLON
    DB O_SPACE
.end_date_label:

DATE_LABEL_LEN EQU .end_date_label - .date_label

.print_date: ; TODO
    ld      b,10
    ld      de,.test_array
    ld      hl,$9800+32*1+6
    call    vram_nitro_copy

    ld      b,DATE_LABEL_LEN
    ld      de,.date_label
    ld      hl,$9800+32*1+0
    call    vram_nitro_copy

    ret
.test_array:
    DB O_ZERO+2,O_ZERO+9,O_BAR
    DB O_ZERO+0,O_ZERO+5,O_BAR
    DB O_ZERO+1,O_ZERO+9,O_ZERO+9,O_ZERO+1

;-----------------------------------

.population_test:
    DB $89,$67,$45,$23,$01

.print_population: ; TODO
    ; Convert to tile from BCD
    ld      de,.population_test ; BCD, LSB first, LSB in lower nibbles
    ld      hl,sp+2
    call    BCD_DE_2TILE_HL_LEADING_SPACES

    ; Copy to VRAM
    xor     a,a
    ld      [rVBK],a

    ld      b,10
    ld      hl,sp+2
    LD_DE_HL
    ld      hl,$9800+32*2+6
    call    vram_nitro_copy

    ret

    ret

;-----------------------------------

.print_rci: ; TODO

    ld      hl,sp+2
    ld      a,43
    ld      [hl+],a
    ld      a,47
    ld      [hl+],a
    ld      a,44
    ld      [hl+],a
    ld      b,3
    ld      hl,sp+2
    LD_DE_HL
    ld      hl,$9800+32*0+17
    call    vram_nitro_copy

    ld      hl,sp+2
    ld      a,50
    ld      [hl+],a
    ld      a,51
    ld      [hl+],a
    ld      a,52
    ld      [hl+],a
    ld      b,3
    ld      hl,sp+2
    LD_DE_HL
    ld      hl,$9800+32*1+17
    call    vram_nitro_copy

    ret

;-----------------------------------

.print_hide_rci_black:
    ld      hl,sp+2
    ld      a,O_SPACE
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a
    ld      b,3
    ld      hl,sp+2
    LD_DE_HL
    ld      hl,$9800+32*0+17
    call    vram_nitro_copy
    ld      b,3
    ld      hl,sp+2
    LD_DE_HL
    ld      hl,$9800+32*1+17
    call    vram_nitro_copy
    ret

;-------------------------------------------------------------------------------

CURSOR_X EQU 4
CURSOR_COORDINATE_OFFSET:
    DW 8*32+CURSOR_X+$9800
    DW 9*32+CURSOR_X+$9800
    DW 10*32+CURSOR_X+$9800
    DW 11*32+CURSOR_X+$9800
    DW 13*32+CURSOR_X+$9800
    DW 14*32+CURSOR_X+$9800

StatusBarMenuClearCursor:

    ld      b,O_SPACE
    jr      StatusBarMenuPlaceAtCursor

StatusBarMenuDrawCursor:

    ld      b,O_ARROW

StatusBarMenuPlaceAtCursor: ; b = tile number

    add     sp,-1
    ld      hl,sp+0
    ld      a,b
    ld      [hl],a

    ld      a,[status_menu_selection]
    ld      l,a
    ld      h,0
    add     hl,hl

    ld      de,CURSOR_COORDINATE_OFFSET
    add     hl,de
    ld      e,[hl]
    inc     hl
    ld      d,[hl]

    ld      b,1
    ld      hl,sp+0
    call    vram_copy_fast
    add     sp,+1

    ret

StatusBarMenuHandle:: ; ret A = menu selection if the user presses A, $FF if not

    ; UP
    ld      a,[joy_pressed]
    and     a,PAD_UP
    jr      z,.not_up
        ld      a,[status_menu_selection]
        and     a,a
        jr      z,.not_up
            call    StatusBarMenuClearCursor
            ld      hl,status_menu_selection
            dec     [hl]
            call    StatusBarMenuDrawCursor
.not_up:

    ; DOWN
    ld      a,[joy_pressed]
    and     a,PAD_DOWN
    jr      z,.not_down
        ld      a,[status_menu_selection]
        cp      a,MENU_NUMBER_ELEMENTS-1
        jr      z,.not_down
            call    StatusBarMenuClearCursor
            ld      hl,status_menu_selection
            inc     [hl]
            call    StatusBarMenuDrawCursor
.not_down:

    ; A
    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      z,.not_a
        ld      a,[status_menu_selection]
        ret
.not_a:


    ld      a,$FF
    ret

;###############################################################################
