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

    INCLUDE "room_text_input.inc"
    INCLUDE "save_struct.inc"
    INCLUDE "text.inc"

;###############################################################################

    SECTION "Room Save Menu Variables",WRAM0

    DEF SAVE_MENU_CURSOR_BLINK_FRAMES EQU 30
save_menu_cursor_x:      DS 1 ; page
save_menu_cursor_y:      DS 1 ; selection inside page
save_menu_exit_error:    DS 1 ; 0 if selection is ok, $FF if error
save_menu_cursor_blink:  DS 1
save_menu_cursor_frames: DS 1 ; number of frames left before switching blink

save_menu_exit:    DS 1 ; set to 1 to exit

    DEF SAVE_MENU_MAX_SLOTS_PER_PAGE EQU 4
save_menu_num_pages:        DS 1 ; calculated when loading the room
save_menu_elements_in_page: DS 1 ; calculated when changing page

; If 1, any bank can be returned (useful for saving). If 0, only banks with
; correct data (for loading)
save_menu_select_any: DS 1

;###############################################################################

    SECTION "Room Save Menu Data",ROMX

;-------------------------------------------------------------------------------

SAVE_MENU_BG_MAP::
    INCBIN  "save_menu_map.bin"

SAVE_MENU_ERROR_BG_MAP::
    INCBIN  "save_menu_error_map.bin"

;-------------------------------------------------------------------------------

SaveMenuMoveRight:

    call    SaveMenuClearCursor

    ld      a,[save_menu_cursor_x]
    inc     a
    ld      b,a
    ld      a,[save_menu_num_pages]
    cp      a,b
    jr      nz,.dont_wrap
    ld      b,0
.dont_wrap:
    ld      a,b
    ld      [save_menu_cursor_x],a

    ld      a,SAVE_MENU_CURSOR_BLINK_FRAMES
    ld      [save_menu_cursor_frames],a
    ld      a,1
    ld      [save_menu_cursor_blink],a

    call    SaveMenuRedrawPage
    call    SaveMenuDrawCursor

    ret

;-------------------------------------------------------------------------------

SaveMenuMoveLeft:

    call    SaveMenuClearCursor

    ld      a,[save_menu_cursor_x]
    dec     a
    cp      a,-1
    jr      nz,.dont_wrap
    ld      a,[save_menu_num_pages]
    dec     a
.dont_wrap:
    ld      [save_menu_cursor_x],a

    ld      a,SAVE_MENU_CURSOR_BLINK_FRAMES
    ld      [save_menu_cursor_frames],a
    ld      a,1
    ld      [save_menu_cursor_blink],a

    call    SaveMenuRedrawPage
    call    SaveMenuDrawCursor

    ret

;-------------------------------------------------------------------------------

SaveMenuMoveDown:

    call    SaveMenuClearCursor

    ld      a,[save_menu_cursor_y]
    inc     a
    ld      b,a
    ld      a,[save_menu_elements_in_page]
    cp      a,b
    jr      nz,.dont_wrap
    ld      b,0
.dont_wrap:
    ld      a,b
    ld      [save_menu_cursor_y],a

    ld      a,SAVE_MENU_CURSOR_BLINK_FRAMES
    ld      [save_menu_cursor_frames],a
    ld      a,1
    ld      [save_menu_cursor_blink],a

    call    SaveMenuDrawCursor

    ret

;-------------------------------------------------------------------------------

SaveMenuMoveUp:

    call    SaveMenuClearCursor

    ld      a,[save_menu_cursor_y]
    dec     a
    cp      a,-1
    jr      nz,.dont_wrap
    ld      a,[save_menu_elements_in_page]
    dec     a
.dont_wrap:
    ld      [save_menu_cursor_y],a

    ld      a,SAVE_MENU_CURSOR_BLINK_FRAMES
    ld      [save_menu_cursor_frames],a
    ld      a,1
    ld      [save_menu_cursor_blink],a

    call    SaveMenuDrawCursor

    ret

;-------------------------------------------------------------------------------

MACRO WRITE_B_TO_HL_VRAM ; Clobbers A and C
    di ; critical section
        xor     a,a
        ldh     [rVBK],a
        WAIT_SCREEN_BLANK ; Clobbers registers A and C
        ld      [hl],b
    ei ; end of critical section
ENDM

;-------------------------------------------------------------------------------

; b = slot in the screen to draw
; c = SRAM bank to print
SaveMenuPrintSRAMBankInfo:

    add     sp,-(TEXT_INPUT_LENGTH+1+1+2) ; (*) Space: name + 0 + month + year

    push    bc

    ; First, read data from SRAM and save to the stack to do the copy to VRAM
    ; with SRAM disabled, which is safer.

    ld      a,CART_RAM_ENABLE
    ld      [rRAMG],a

    ld      a,c ; SRAM
    ld      [rRAMB],a

    ld      hl,sp+2
    LD_DE_HL ; de = dest

    ld      hl,SAV_CITY_NAME ; src
    ld      bc,TEXT_INPUT_LENGTH
    call    memcopy ; bc = size    hl = source address    de = dest address

    xor     a,a
    ld      [de],a ; save terminator to make it easier to print it afterwards
    inc     de

    ld      a,[SAV_YEAR+0]
    ld      [de],a
    inc     de
    ld      a,[SAV_YEAR+1]
    ld      [de],a
    inc     de

    ld      a,[SAV_MONTH]
    ld      [de],a
    inc     de

    ld      a,CART_RAM_DISABLE
    ldh     [rRAMG],a

    pop     bc

    ; b = slot in the screen to draw
    ; c = SRAM bank to print

    push    bc
    ld      a,b ; pass the slot
    call    SaveMenuGetMapPointer ; returns hl = pointer to VRAM
    pop     bc

    ld      d,c ; C is clobbered by the following macro, save this in D

    ; hl = pointer to VRAM
    ; d = SRAM bank

    ; First, draw SRAM bank number

    inc     hl
    inc     hl

    inc     d ; start from 1 instead of 0
    ld      a,d
    cp      a,10 ; cy = 1 if a < 10
    jr      nc,.ten_or_more

        ld      b,O_SPACE
        WRITE_B_TO_HL_VRAM ; clobbers A and C
        inc     hl
        ld      a,d
        BCD2Tile
        ld      b,a
        WRITE_B_TO_HL_VRAM ; clobbers A and C

    jr      .end_print_num
.ten_or_more:

        ld      b,O_ZERO + 1
        WRITE_B_TO_HL_VRAM ; clobbers A and C
        inc     hl
        ld      a,d
        sub     a,10
        BCD2Tile
        ld      b,a
        WRITE_B_TO_HL_VRAM ; clobbers A and C

.end_print_num:

    ; D is not needed anymore after this

    ; Draw name

    inc     hl
    inc     hl
    inc     hl

    push    hl
        ld      bc,TEXT_INPUT_LENGTH
        ld      d,O_SPACE ; Fill with spaces
        call    vram_memset ;  bc = size    d = value    hl = dest address
    pop     hl
    push    hl
        LD_BC_HL
        ld      hl,sp+2
        LD_DE_HL ; de = src
        LD_HL_BC ; hl = dst
.loop_print_name: ; length is not needed, the stack should have a 0 in the end
        ld      a,[de]
        and     a,a
        jr      z,.end_print_name
        ld      b,a
        WRITE_B_TO_HL_VRAM ; clobbers A and C
        inc     hl
        inc     de
        jr      .loop_print_name
.end_print_name:
    pop     hl

    ; Draw date

    ld      de,32
    add     hl,de

    push    hl

    ld      hl,sp+2+(TEXT_INPUT_LENGTH+1)
    ld      a,[hl+]
    ld      c,a
    ld      a,[hl+]
    ld      b,a ; BC = year (B = MSB, C = LSB)

    ld      a,[hl+] ; A = month

    ld      hl,sp+2
    LD_DE_HL ; de = destination. reuse city name as destination for print!
    call    DatePrint ; prints 8 chars, no terminator

    pop     de ; de = dest
    ld      hl,sp+0
    ld      b,8 ; lenght of date string

    call    vram_copy_fast ; b = size    hl = source address    de = dest

    ; End

    add     sp,+(TEXT_INPUT_LENGTH+1+1+2) ; (*) reclaim space

    ret

;-------------------------------------------------------------------------------

SaveMenuPrintSRAMBankEmpty:

    ; b = slot in the screen to draw
    ; c = SRAM bank to print

    push    bc
    ld      a,b ; pass the slot
    call    SaveMenuGetMapPointer ; returns hl = pointer to VRAM
    pop     bc

    ld      d,c ; C is clobbered by the following macro, save this in D

    ; hl = pointer to VRAM
    ; d = SRAM bank

    ; First, draw SRAM bank number

    inc     hl
    inc     hl

    inc     d ; start from 1 instead of 0
    ld      a,d
    cp      a,10 ; cy = 1 if a < 10
    jr      nc,.ten_or_more

        ld      b,O_SPACE
        WRITE_B_TO_HL_VRAM ; clobbers A and C
        inc     hl
        ld      a,d
        BCD2Tile
        ld      b,a
        WRITE_B_TO_HL_VRAM ; clobbers A and C

    jr      .end_print_num
.ten_or_more:

        ld      b,O_ZERO + 1
        WRITE_B_TO_HL_VRAM ; clobbers A and C
        inc     hl
        ld      a,d
        sub     a,10
        BCD2Tile
        ld      b,a
        WRITE_B_TO_HL_VRAM ; clobbers A and C

.end_print_num:

    ; D is not needed anymore after this

    ; Draw name

    inc     hl
    inc     hl
    inc     hl

    push    hl

    LD_DE_HL
    ld      hl,.str_empty_city_name
    ld      b,TEXT_INPUT_LENGTH
    call    vram_copy_fast ; b = size    hl = source address    de = dest

    pop     hl

    ; Draw date

    ld      de,32
    add     hl,de

    LD_DE_HL
    ld      hl,.str_empty_city_date
    ld      b,8
    call    vram_copy_fast ; b = size    hl = source address    de = dest

    ret

.str_empty_city_name:
    STR_ADD "Empty     "
.str_empty_city_date:
    STR_ADD "        "

;-------------------------------------------------------------------------------

SaveMenuPrintSRAMBankNotAvailable:

    ; b = slot in the screen to draw

    push    bc
    ld      a,b ; pass the slot
    call    SaveMenuGetMapPointer ; returns hl = pointer to VRAM
    pop     bc

    ; hl = pointer to VRAM

    ; First, draw SRAM bank number

    inc     hl
    inc     hl

    ld      b,O_SPACE
    WRITE_B_TO_HL_VRAM ; clobbers A and C
    inc     hl
    WRITE_B_TO_HL_VRAM ; clobbers A and C
    inc     hl
    WRITE_B_TO_HL_VRAM ; clobbers A and C

    ; Draw name

    inc     hl
    inc     hl

    push    hl

    LD_DE_HL
    ld      hl,.str_doesnt_exist_city_name
    ld      b,TEXT_INPUT_LENGTH
    call    vram_copy_fast ; b = size    hl = source address    de = dest

    pop     hl

    ; Draw date

    ld      de,32
    add     hl,de

    LD_DE_HL
    ld      hl,.str_doesnt_exist_city_date
    ld      b,8
    call    vram_copy_fast ; b = size    hl = source address    de = dest

    ret

.str_doesnt_exist_city_name:
    STR_ADD "          "
.str_doesnt_exist_city_date:
    STR_ADD "        "

;-------------------------------------------------------------------------------

SaveMenuRedrawPage:

    ; Calculate number of entries in this page
    ; ----------------------------------------

    ld      a,[save_menu_cursor_x]

    sla     a
    sla     a
    ld      c,a ; (*) base SRAM bank of this page, save for later
    ld      b,a
    ld      a,[sram_num_available_banks]
    sub     a,b ; a = number of banks in the current page

    ; Clamp A to 4
    cp      a,4 ; cy = 1 if 4 > a
    jr      c,.dont_clamp ; skip clamp if a < 4
    ld      a,4
.dont_clamp:

    ld      [save_menu_elements_in_page],a ; save it

    ; Clamp cursor to max elements in this page

    push    bc ; save number of SRAM banks

    ld      b,a ; b = num of elements
    ld      a,[save_menu_cursor_y]

    cp      a,b ; cy = 1 if num of elements > cursor
    jr      c,.dont_clamp_2

    ld      a,b
    dec     a
    ld      [save_menu_cursor_y],a

.dont_clamp_2:

    pop     bc

    ; Draw information of all the available slots
    ; -------------------------------------------

    ld      b,0
    ; b = current slot number to draw
    ; c = current SRAM bank to draw
.loop_draw_bank:
    push    bc

    ld      hl,sram_bank_status
    ld      e,c
    ld      d,0
    add     hl,de ; hl = sram_bank_status[SRAM bank to draw]

    ld      a,[hl] ; 1 = ok, 2 = corrupted
    cp      a,1
    jr      nz,.not_ok

        call    SaveMenuPrintSRAMBankInfo
        jr      .end_bank_ok_check
.not_ok:
        ; If the bank is corrupted or empty, print default data
        call    SaveMenuPrintSRAMBankEmpty

.end_bank_ok_check

    pop     bc
    ld      a,[save_menu_elements_in_page]
    inc     b
    inc     c
    cp      a,b
    jr      nz,.loop_draw_bank

    ; Draw "not available" in the other slots
    ; ---------------------------------------

    ; b = current slot to print, from previous loop

.loop_not_available:
    ld      a,b
    cp      a,4
    jr      z,.end_not_available

    push    bc
    call    SaveMenuPrintSRAMBankNotAvailable
    pop     bc

    inc     b
    jr      .loop_not_available
.end_not_available:

    ; Draw page number
    ; ----------------

    ld      a,[save_menu_cursor_x]
    inc     a
    BCD2Tile
    ld      b,a
    ld      hl,$9800+16*32+16

    di ; critical section

        xor     a,a
        ldh     [rVBK],a

        WAIT_SCREEN_BLANK ; Clobbers registers A and C

        ld      [hl],b

    ei ; end of critical section

    ; Print cursor and exit
    ; ---------------------

    call    SaveMenuDrawCursor

    ret

;-------------------------------------------------------------------------------

; A = slot of the screen to get the base coordinates to. The coordinates are
; the ones corresponding to the arrow cursor
SaveMenuGetMapPointer: ; returns hl = pointer to VRAM to selected tile

    ; ptr = base + (y*3)*32

    ld      b,a
    add     a,a
    add     a,b ; a *= 3

    swap    a ; a <<= 4 (*16)

    ld      l,a
    ld      h,0
    add     hl,hl ; a <<= 5 (*32)

    ld      de,$9800+32*4+1 ; VRAM map for coordinates (1, 4)
    add     hl,de

    ret

;-------------------------------------------------------------------------------

SaveMenuDrawCursor:

    ld      a,[save_menu_cursor_y]
    call    SaveMenuGetMapPointer

    di ; critical section

        xor     a,a
        ldh     [rVBK],a

        WAIT_SCREEN_BLANK ; Clobbers registers A and C

        ld      [hl],O_ARROW

    reti ; end of critical section and return

;-------------------------------------------------------------------------------

SaveMenuClearCursor:

    ld      a,[save_menu_cursor_y]
    call    SaveMenuGetMapPointer

    di ; critical section

        xor     a,a
        ldh     [rVBK],a

        WAIT_SCREEN_BLANK ; Clobbers registers A and C

        ld      [hl],O_SPACE

    reti ; end of critical section and return

;-------------------------------------------------------------------------------

InputHandleSaveMenuMenu:

    ; Clear data

    ld      a,[save_menu_select_any]
    cp      a,0 ; 0 = load mode
    jr      nz,.not_clear_data ; if this is not load mode, don't allow this

    ld      a,[joy_held]
    ld      b,PAD_START|PAD_SELECT|PAD_UP|PAD_RIGHT ; Right+Up+Select + Start
    and     a,b
    cp      a,b
    jr      nz,.not_clear_data

        ; If this is called we can safely assume that the number of banks is
        ; greater than 0. If not, the menu wouldn't have been shown, only the
        ; error screen.
        ld      b,0
.loop_clear_data:
        push    bc
        LONG_CALL_ARGS  SRAM_ClearBank
        pop     bc
        inc     b
        ld      a,[sram_num_available_banks]
        cp      a,b
        jr      nz,.loop_clear_data

        ; Refresh integrity data
        LONG_CALL   SRAM_CheckIntegrity

.not_clear_data:

    ; Regular commands

    ld      a,[joy_pressed]
    and     a,PAD_START|PAD_A
    jr      z,.not_start_a

        ld      a,[save_menu_select_any]
        and     a,a
        jr      nz,.any_bank_ok

            ld      a,[save_menu_cursor_x]
            sla     a
            sla     a
            ld      b,a
            ld      a,[save_menu_cursor_y] ; selection = cursor + page * 4
            or      a,b

            ; Check if this bank has data
            ld      hl,sram_bank_status
            ld      e,a
            ld      d,0
            add     hl,de
            ld      a,[hl]
            cp      a,1
            ret     nz ; if not 1, data is not ok (or there is no data)

.any_bank_ok:
        ld      a,1
        ld      [save_menu_exit],a
        ret
.not_start_a:

    ld      a,[joy_pressed]
    and     a,PAD_B
    jr      z,.not_b
        ld      a,$FF
        ld      [save_menu_exit_error],a ; set selected banck to error
        ld      a,1
        ld      [save_menu_exit],a
        ret ; Go back to main menu, return $FF
.not_b:

    ; If the user pressed A, B or START this point won't be reached

    ld      a,[joy_pressed]
    and     a,PAD_LEFT
    jr      z,.not_left
        call    SaveMenuMoveLeft
        jr      .end_left_right
.not_left:
    ld      a,[joy_pressed]
    and     a,PAD_RIGHT
    jr      z,.end_left_right
        call    SaveMenuMoveRight
.end_left_right:

    ld      a,[joy_pressed]
    and     a,PAD_UP
    jr      z,.not_up
        call    SaveMenuClearCursor
        call    SaveMenuMoveUp
        call    SaveMenuDrawCursor
        jr      .end_up_down
.not_up:
    ld      a,[joy_pressed]
    and     a,PAD_DOWN
    jr      z,.end_up_down
        call    SaveMenuClearCursor
        call    SaveMenuMoveDown
        call    SaveMenuDrawCursor
.end_up_down:

    ret

;-------------------------------------------------------------------------------

SaveMenuCursorBlinkHandle:

    ld      hl,save_menu_cursor_frames
    dec     [hl]
    jr      nz,.end_cursor_blink

        ld      [hl],SAVE_MENU_CURSOR_BLINK_FRAMES

        ld      hl,save_menu_cursor_blink
        ld      a,1
        xor     a,[hl]
        ld      [hl],a

        and     a,a
        jr      z,.cleared_cursor
            call    SaveMenuDrawCursor
            jr      .end_cursor_blink
.cleared_cursor:
            call    SaveMenuClearCursor
            jr      .end_cursor_blink

.end_cursor_blink:

    ret

;-------------------------------------------------------------------------------

SaveMenuHandle:

    call    InputHandleSaveMenuMenu

    call    SaveMenuCursorBlinkHandle

    ret

;-------------------------------------------------------------------------------

RoomSaveMenuError: ; always returns -1!

    call    SetPalettesAllBlack

    call    SetDefaultVBLHandler

    call    RoomSaveMenuLoadErrorBG

    ld      b,0 ; bank at 8000h
    call    LoadText

    di ; Entering critical section

    ld      b,144
    call    wait_ly

    xor     a,a
    ldh     [rIF],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8000|LCDCF_ON
    ldh     [rLCDC],a

    call    LoadTextPalette

    ei ; End of critical section

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      z,.loop

    ld      a,$FF ; always returns error!
    ret

;-------------------------------------------------------------------------------

; b = 1 for saving, 0 for loading
RoomSaveMenu:: ; returns A = selected SRAM bank, -1 if error

    ld      a,b
    ld      [save_menu_select_any],a

    ; The first thing to do is to calculate how many pages we have

    ld      a,[sram_num_available_banks]
    and     a,a
    jp      z,RoomSaveMenuError ; Zero banks: Call error room and return from it

    dec     a
    srl     a
    srl     a
    inc     a
    ld      [save_menu_num_pages],a

    ; Then, analyse all SRAM banks to check for corruption, empty banks, etc

    LONG_CALL   SRAM_CheckIntegrity

    ; Reset variables, load graphics, etc

    xor     a,a
    ld      [save_menu_exit],a
    ld      [save_menu_exit_error],a

    ld      [save_menu_cursor_blink],a

    ld      a,SAVE_MENU_CURSOR_BLINK_FRAMES
    ld      [save_menu_cursor_frames],a

    ; Load coordinates of last accesed SRAM bank instead of moving to 0,0.
    ; The coordinates are set to 0 when loading the ROM (when clearing the WRAM)
    ; and then they will remain at the last used position when the menu is
    ; called again.
;    ld      [save_menu_cursor_x],a
;    ld      [save_menu_cursor_y],a

    call    SetPalettesAllBlack

    call    SetDefaultVBLHandler

    call    RoomSaveMenuLoadBG

    LONG_CALL   SaveMenuRedrawPage

    ld      b,0 ; bank at 8000h
    call    LoadText

    di ; Entering critical section

    ld      b,144
    call    wait_ly

    xor     a,a
    ldh     [rIF],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8000|LCDCF_ON
    ldh     [rLCDC],a

    call    LoadTextPalette

    ei ; End of critical section

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    LONG_CALL   SaveMenuHandle

    ld      a,[save_menu_exit]
    and     a,a
    jr      z,.loop

    call    WaitReleasedAllKeys

    call    SetPalettesAllBlack

    ; Return A = bank, -1 if error

    ld      a,[save_menu_cursor_x]
    sla     a
    sla     a
    ld      b,a
    ld      a,[save_menu_cursor_y] ; selection = cursor + page * 4
    or      a,b

    ld      b,a
    ld      a,[save_menu_exit_error]
    or      a,b ; if error = $FF, return $FF regardless of the selection
    ; if it is 0, return the selection

    ret

;-------------------------------------------------------------------------------

RoomSaveMenuLoadErrorBG:

    ; Reset scroll
    ; ------------

    xor     a,a
    ldh     [rSCX],a
    ldh     [rSCY],a

    ; Load graphics
    ; -------------

    ld      b,BANK(SAVE_MENU_ERROR_BG_MAP)
    call    rom_bank_push_set

    ; Tiles

    xor     a,a
    ldh     [rVBK],a

    ld      de,$9800
    ld      hl,SAVE_MENU_ERROR_BG_MAP

    ld      a,18
.loop1:
    push    af

    ld      b,20
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    push    hl
    ld      hl,32-20
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

    ld      a,18
.loop2:
    push    af

    ld      b,20
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    push    hl
    ld      hl,32-20
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

RoomSaveMenuLoadBG:

    ; Reset scroll
    ; ------------

    xor     a,a
    ldh     [rSCX],a
    ldh     [rSCY],a

    ; Load graphics
    ; -------------

    ld      b,BANK(SAVE_MENU_BG_MAP)
    call    rom_bank_push_set

    ; Tiles

    xor     a,a
    ldh     [rVBK],a

    ld      de,$9800
    ld      hl,SAVE_MENU_BG_MAP

    ld      a,18
.loop1:
    push    af

    ld      b,20
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    push    hl
    ld      hl,32-20
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl

    pop     af
    dec     a
    jr      nz,.loop1

    ; Print number of available pages

    push    hl ; (*) preserve current src pointer

    ld      a,[save_menu_num_pages]
    BCD2Tile
    ld      b,a ; b = tile to draw

    ld      hl,$9800+16*32+18

    di ; critical section

        xor     a,a
        ldh     [rVBK],a

        WAIT_SCREEN_BLANK ; Clobbers registers A and C

        ld      [hl],b

    ei ; end of critical section and return

    pop     hl ; (*) restore current src pointer

    ; Attributes

    ld      a,1
    ldh     [rVBK],a

    ld      de,$9800

    ld      a,18
.loop2:
    push    af

    ld      b,20
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    push    hl
    ld      hl,32-20
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl

    pop     af
    dec     a
    jr      nz,.loop2

    xor     a,a
    ldh     [rVBK],a

    call    rom_bank_pop

    ret

;###############################################################################
