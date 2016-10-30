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

    INCLUDE "money.inc"
    INCLUDE "text.inc"

;###############################################################################

    SECTION "Room Bank Variables",WRAM0

;-------------------------------------------------------------------------------

LOAN_REMAINING_PAYMENTS:: DS 1 ; 0 if no remaining payments (no loan)
LOAN_PAYMENTS_AMOUNT::    DS 2 ; BCD, LSB first
; Set to 1 or 0 when entering the room to keep a consistent state until it is
; exited.
bank_room_loan_active: DS 1

BANK_ROOM_CURSOR_BLINK_FRAMES EQU 30
bank_room_cursor: DS 1
bank_room_cursor_blink:  DS 1
bank_room_cursor_frames: DS 1 ; number of frames left before switching blink

bank_room_exit:  DS 1 ; set to 1 to exit room

;###############################################################################

    SECTION "Room Bank Data",ROMX

;-------------------------------------------------------------------------------

BANK_OFFER_MENU_BG_MAP:
    INCBIN "bank_offer_menu_bg_map.bin"

BANK_REPAY_MENU_BG_MAP:
    INCBIN "bank_repay_menu_bg_map.bin"

BANK_MENU_WIDTH  EQU 20
BANK_MENU_HEIGHT EQU 18

;-------------------------------------------------------------------------------

BankMenuHandleInput: ; If it returns 1, exit room. If 0, continue

    ; Exit if B or START are pressed
    ld      a,[joy_pressed]
    and     a,PAD_B|PAD_START
    jr      z,.end_b_start
        ld      a,1
        ret ; return 1
.end_b_start:

    ld      a,[bank_room_loan_active]
    and     a,a
    jr      z,.continue ; continue if asking for a loan present
        xor     a,a
        ret ; return 0
.continue:

    ld      a,[joy_pressed]
    and     a,PAD_UP
    jr      z,.end_up
        call    RoomBankMenuClearCursor
        ld      hl,bank_room_cursor
        ld      a,1
        xor     a,[hl]
        ld      [hl],a
        call    RoomBankMenuDrawCursor
        ld      hl,bank_room_cursor_frames
        ld      [hl],BANK_ROOM_CURSOR_BLINK_FRAMES
.end_up:

    ld      a,[joy_pressed]
    and     a,PAD_DOWN
    jr      z,.end_down
        call    RoomBankMenuClearCursor
        ld      hl,bank_room_cursor
        ld      a,1
        xor     a,[hl]
        ld      [hl],a
        call    RoomBankMenuDrawCursor
        ld      hl,bank_room_cursor_frames
        ld      [hl],BANK_ROOM_CURSOR_BLINK_FRAMES
.end_down:

    xor     a,a
    ret ; return 0

;-------------------------------------------------------------------------------

InputHandleBankMenu:

    call    RoomBankMenuCursorBlinkHandle

    call    BankMenuHandleInput ; If it returns 1, exit room. If 0, continue
    and     a,a
    ret     z ; don't exit

    ; Exit
    ld      a,1
    ld      [bank_room_exit],a
    ret

;-------------------------------------------------------------------------------

; A = slot of the screen to get the base coordinates to. The coordinates are
; the ones corresponding to the arrow cursor
RoomBankMenuGetMapPointer: ; returns hl = pointer to VRAM to selected tile

    and     a,a
    jr      nz,.slot1
        ld      hl,$9800+32*8+1 ; VRAM map for coordinates (1, 8)
        ret
.slot1:
    ld      hl,$9800+32*13+1 ; VRAM map for coordinates (1, 13)
    ret

;-------------------------------------------------------------------------------

RoomBankMenuDrawCursor:

    ld      a,[bank_room_cursor]
    call    RoomBankMenuGetMapPointer ; returns hl = pointer to VRAM

    di ; critical section

        xor     a,a
        ld      [rVBK],a

        WAIT_SCREEN_BLANK ; Clobbers registers A and C

        ld      [hl],O_ARROW

    reti ; end of critical section and return

;-------------------------------------------------------------------------------

RoomBankMenuClearCursor:

    ld      a,[bank_room_cursor]
    call    RoomBankMenuGetMapPointer ; returns hl = pointer to VRAM

    di ; critical section

        xor     a,a
        ld      [rVBK],a

        WAIT_SCREEN_BLANK ; Clobbers registers A and C

        ld      [hl],O_SPACE

    reti ; end of critical section and return

;-------------------------------------------------------------------------------

RoomBankMenuCursorBlinkHandle:

    ld      a,[bank_room_loan_active]
    and     a,a
    ret     nz ; return if loan present

    ld      hl,bank_room_cursor_frames
    dec     [hl]
    jr      nz,.end_cursor_blink

        ld      [hl],BANK_ROOM_CURSOR_BLINK_FRAMES

        ld      hl,bank_room_cursor_blink
        ld      a,1
        xor     a,[hl]
        ld      [hl],a

        and     a,a
        jr      z,.cleared_cursor
            call    RoomBankMenuDrawCursor
            jr      .end_cursor_blink
.cleared_cursor:
            call    RoomBankMenuClearCursor
            jr      .end_cursor_blink

.end_cursor_blink:

    ret

;-------------------------------------------------------------------------------

RoomBankMenuLoadBG:

    ; Load border
    ; -----------

    ld      b,BANK(BANK_OFFER_MENU_BG_MAP)
    call    rom_bank_push_set

        ld      a,[bank_room_loan_active]
        and     a,a
        jr      nz,.loan_active
        ld      hl,BANK_OFFER_MENU_BG_MAP
        jr      .end_loan_check
.loan_active:
        ld      hl,BANK_REPAY_MENU_BG_MAP
.end_loan_check:

        ; Load map
        ; --------

        ; Tiles
        xor     a,a
        ld      [rVBK],a

        ld      de,$9800
        ;HL = pointer to map

        ld      a,BANK_MENU_HEIGHT
.loop1:
        push    af

        ld      b,BANK_MENU_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-BANK_MENU_WIDTH
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

        ld      a,BANK_MENU_HEIGHT
.loop2:
        push    af

        ld      b,BANK_MENU_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-BANK_MENU_WIDTH
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

RoomBankMenu::

    call    SetPalettesAllBlack

    ld      bc,BankMenuVBLHandler
    call    irq_set_VBL

    ld      a,0 ; TODO
    ld      [bank_room_loan_active],a

    xor     a,a
    ld      [bank_room_cursor],a
    ld      [bank_room_cursor_blink],a

    ld      a,BANK_ROOM_CURSOR_BLINK_FRAMES
    ld      [bank_room_cursor_frames],a

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ld      [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    call    RoomBankMenuLoadBG

    ; Update numbers
    ; TODO

    call    LoadTextPalette

    xor     a,a
    ld      [bank_room_exit],a

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleBankMenu

    ld      a,[bank_room_exit]
    and     a,a
    jr      z,.loop

    call    SetDefaultVBLHandler

    call    SetPalettesAllBlack

    ret

;###############################################################################

    SECTION "Room Bank Data Bank 0",ROM0

;-------------------------------------------------------------------------------

BankMenuVBLHandler:

    call    refresh_OAM

    ret

;###############################################################################
