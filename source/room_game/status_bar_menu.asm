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

    INCLUDE "building_info.inc"
    INCLUDE "room_game.inc"
    INCLUDE "text.inc"
    INCLUDE "room_text_input.inc"

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

status_bar_active:: DS 1
status_bar_on_top:: DS 1 ; 1 if on top, 0 if on the bottom

status_menu_active::   DS 1 ; if 1, show menu
status_menu_selection: DS 1

MENU_NUMBER_ELEMENTS EQU 8

STATUS_MENU_BLINK_FRAMES EQU 30
status_menu_blink_status: DS 1
status_menu_blink_frames: DS 1 ; frames left to change status

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

    ; This handler is only called if the status bar is active, no need to check.
;    ld      a,[status_bar_active]
;    and     a,a
;    ret     z

    ; This is a critical section, but as we are inside an interrupt handler
    ; there is no need to use 'di' and 'ei' with WAIT_SCREEN_BLANK.

    ; Check if on top or at the bottom
    ld      a,[status_bar_on_top]
    and     a,a
    jr      nz,.on_top

        ; At the bottom

        WAIT_SCREEN_BLANK

        ld      a,[menu_overlay_sprites_active]
        ld      b,a
        ld      a,[game_sprites_8x16]
        or      a,b
        or      a,LCDCF_BG9C00|LCDCF_WIN9800|LCDCF_WINON|LCDCF_ON|LCDCF_BG8000

        ld      [rLCDC],a

        ld      a,7
        ld      [rWX],a

    ret
.on_top:

        ; On top

        WAIT_SCREEN_BLANK

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
        ld      a,[menu_overlay_sprites_active]
        ld      b,a
        ld      a,[game_sprites_8x16]
        or      a,b
        or      a,LCDCF_BG9C00|LCDCF_WIN9800|LCDCF_WINON|LCDCF_ON|LCDCF_BG8000
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

    ld      a,LCDCF_BG8000|LCDCF_WIN9800|LCDCF_WINON|LCDCF_OBJON|LCDCF_ON
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

    ld      a,STATUS_MENU_BLINK_FRAMES
    ld      [status_menu_blink_frames],a
    ld      a,1
    ld      [status_menu_blink_status],a

    call    StatusBarMenuDrawCursor

    ret

;-------------------------------------------------------------------------------

StatusBarMenuLoadGfx::

    ; Load graphics

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

    ; Update pause sign

    call    StatusBarMenuDrawPauseState

    call    StatusBarMenuDrawCityName ; only do this once!

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
    jr      z,.end ; Status bar is not shown in this mode
    cp      a,GAME_STATE_SELECT_BUILDING
    jr      z,.building
    cp      a,GAME_STATE_PAUSE_MENU
    jr      z,.pause
    cp      a,GAME_STATE_SHOW_MESSAGE
    jr      z,.end ; Status bar is not shown when a message box is shown

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
    ;jr      .end

.end: ; Exit

    add     sp,+10 ; (*)

    ret

;-----------------------------------

.print_money:
    ; Convert to tile from BCD
    ld      de,MoneyWRAM ; BCD, LSB first, LSB in lower nibbles
    ld      hl,sp+2
    call    BCD_SIGNED_DE_2TILE_HL_LEADING_SPACES

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

    ld      b,6
    ld      de,.price_label
    ld      hl,$9800+32*1+0
    call    vram_nitro_copy

    ret

.price_label:
    STR_ADD "Price:"

;-----------------------------------

.print_date:

    add     sp,-8

    ld      hl,sp+0
    LD_DE_HL

    ld      a,[date_year+1] ; LSB first in date_year
    ld      b,a
    ld      a,[date_year+0]
    ld      c,a
    ld      a,[date_month]
    call    DatePrint

    ld      b,8
    ld      hl,sp+0
    LD_DE_HL
    ld      hl,$9800+32*1+8
    call    vram_nitro_copy

    add     sp,+8

    ld      b,8
    ld      de,.date_label
    ld      hl,$9800+32*1+0
    call    vram_nitro_copy

    ret

.date_label:
    STR_ADD "Date:   "

;-----------------------------------

.print_population:

    ; Print population
    ; ----------------

    ; Convert to tile from BCD
    ld      de,city_population ; BCD, LSB first, LSB in lower nibbles
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

    ; City class
    ; ----------

    ld      a,[city_class]
    ld      e,a
    ld      d,0
    ld      hl,.class_strings
    add     hl,de
    add     hl,de
    ld      a,[hl+]
    ld      d,[hl]
    ld      e,a ; get pointer to class string

    ld      b,10
    ld      hl,$9800+32*3+6
    call    vram_nitro_copy

    ret

.class_strings:
    DW  .class_village, .class_town, .class_city
    DW  .class_metropolis, .class_capital

; The strings have to be 10 chars long
.class_village:
    STR_ADD "   Village"
.class_town:
    STR_ADD "      Town"
.class_city:
    STR_ADD "      City"
.class_metropolis:
    STR_ADD "Metropolis"
.class_capital:
    STR_ADD "   Capital"

;-----------------------------------

.print_rci:

    ld      e,O_RCI_BASE_BAR+3 ; base tile + offset

    ld      hl,sp+2
    ld      a,[graph_value_r]
    add     a,e
    ld      [hl+],a
    ld      a,[graph_value_c]
    add     a,e
    ld      [hl+],a
    ld      a,[graph_value_i]
    add     a,e
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
STATUS_BAR_CURSOR_COORDINATE_OFFSET:
    DW 8*32+CURSOR_X+$9800 ; Budget
    DW 9*32+CURSOR_X+$9800 ; Minimaps
    DW 10*32+CURSOR_X+$9800 ; Graphs
    DW 11*32+CURSOR_X+$9800 ; Options
    DW 12*32+CURSOR_X+$9800 ; Pause/Unpause
    DW 13*32+CURSOR_X+$9800 ; Help
    DW 15*32+CURSOR_X+$9800 ; Save Game
    DW 16*32+CURSOR_X+$9800 ; Main Menu

StatusBarMenuClearCursor:

    ld      b,O_SPACE
    jr      StatusBarMenuPlaceAtCursor

StatusBarMenuDrawCursor:

    ld      b,O_ARROW

StatusBarMenuPlaceAtCursor: ; b = tile number

    add     sp,-1 ; Create space in the stack for the value to write
    ld      hl,sp+0
    ld      a,b
    ld      [hl],a

    ld      a,[status_menu_selection]
    ld      l,a
    ld      h,0
    add     hl,hl

    ld      de,STATUS_BAR_CURSOR_COORDINATE_OFFSET
    add     hl,de
    ld      e,[hl]
    inc     hl
    ld      d,[hl]

    xor     a,a
    ld      [rVBK],a

    ld      b,1
    ld      hl,sp+0
    call    vram_copy_fast
    add     sp,+1

    ret

StatusBarMenuHandle:: ; ret A = menu selection if the user presses A, $FF if not

    ld      hl,status_menu_blink_frames
    dec     [hl]
    jr      nz,.end_blink
        ld      [hl],STATUS_MENU_BLINK_FRAMES

        ld      hl,status_menu_blink_status
        ld      a,[hl]
        xor     a,1
        ld      [hl],a
        and     a,a
        jr      z,.clear_cursor
            ; Draw cursor
            call    StatusBarMenuDrawCursor
            jr      .end_blink
.clear_cursor:
            call    StatusBarMenuClearCursor
.end_blink:

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
            ld      a,STATUS_MENU_BLINK_FRAMES
            ld      [status_menu_blink_frames],a
            ld      a,1
            ld      [status_menu_blink_status],a
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
            ld      a,STATUS_MENU_BLINK_FRAMES
            ld      [status_menu_blink_frames],a
            ld      a,1
            ld      [status_menu_blink_status],a
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

;-------------------------------------------------------------------------------

StatusBarMenuDrawPauseState::

    xor     a,a
    ld      [rVBK],a

    ld      a,[simulation_paused]
    and     a,a
    jr      z,.not_paused
        ; Paused. Menu must show "Unpause"
        ld      hl,.str_unpause
    jr      .print
.not_paused:
        ; Unpaused. Menu must show "Pause"
        ld      hl,.str_pause
.print:
    ld      b,7
    ld      de,12*32+CURSOR_X+2+$9800 ; Pause/Unpause
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    ret

.str_pause:
    STR_ADD "Pause  "

.str_unpause:
    STR_ADD "Unpause"

;-------------------------------------------------------------------------------

StatusBarMenuDrawCityName:: ; only do this once, when loading the map!

    ; Align name to the right

    ; Get number of spaces needed before name

    ld      b,0 ; counter
    ld      hl,current_city_name
.loop_count:
    ld      a,[hl+]
    and     a,a
    jr      z,.loop_count_end ; terminator character
    inc     b
    ld      a,TEXT_INPUT_LENGTH ; limit to the max length
    cp      a,b
    jr      nz,.loop_count
.loop_count_end:

    ld      a,b
    and     a,a
    ret     z ; if name length is 0, return (this shouldn't happen!)

    ; b = name lenght
    ld      a,TEXT_INPUT_LENGTH ; limit to the max length
    sub     a,b ; a = Number of spaces needed before name

    ld      hl,$9800+32*4+6 ; prepare pointer for VRAM writes

    and     a,a
    jr      z,.skip_spaces ; if name length is the max one, don't print spaces

    push    bc ; preserve lenght

        ld      b,0
        ld      c,a
        ld      d,O_SPACE
        call    vram_memset ; bc = size    d = value    hl = dest address

    pop     bc ; get lenght in b again

.skip_spaces:

    LD_DE_HL
    ld      hl,current_city_name
    call    vram_copy_fast ; b = size    hl = source address    de = dest

    ret

;###############################################################################
