;###############################################################################
;
;    µCity - City building game for Game Boy Color.
;    Copyright (C) 2017 Antonio Niño Díaz (AntonioND/SkyLyrac)
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

    DATA_MONEY_AMOUNT LOAN_AMOUNT_10000, 10000
    DATA_MONEY_AMOUNT LOAN_AMOUNT_20000, 20000

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

    ; This part is only shown in "loan select" mode

    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      z,.end_a ; Accept payment

        ld      a,21 ; Number of payments in both cases
        ld      [LOAN_REMAINING_PAYMENTS],a

        ld      a,[bank_room_cursor]
        and     a,a
        jr      nz,.second_loan

            ; Loan 1

            ld      a,$00 ; 500
            ld      [LOAN_PAYMENTS_AMOUNT+0],a ; BCD, LSB first
            ld      a,$05
            ld      [LOAN_PAYMENTS_AMOUNT+1],a

            ld      de,LOAN_AMOUNT_10000
            call    MoneyAdd

            jr      .end_of_loan_check
.second_loan:

            ; Loan 2

            ld      a,$00 ; 1000
            ld      [LOAN_PAYMENTS_AMOUNT+0],a ; BCD, LSB first
            ld      a,$10
            ld      [LOAN_PAYMENTS_AMOUNT+1],a

            ld      de,LOAN_AMOUNT_20000
            call    MoneyAdd

            jr      .end_of_loan_check

.end_of_loan_check:
        ld      a,1
        ret ; return 1
.end_a:

    ld      a,[joy_pressed]
    and     a,PAD_UP|PAD_DOWN
    jr      z,.end_up_down
        call    RoomBankMenuClearCursor
        ld      hl,bank_room_cursor
        ld      a,1
        xor     a,[hl]
        ld      [hl],a
        call    RoomBankMenuDrawCursor
        ld      hl,bank_room_cursor_frames
        ld      [hl],BANK_ROOM_CURSOR_BLINK_FRAMES
.end_up_down:

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

WRITE_B_TO_HL_VRAM : MACRO ; Clobbers A and C
    di ; critical section
        xor     a,a
        ld      [rVBK],a
        WAIT_SCREEN_BLANK ; Clobbers registers A and C
        ld      [hl],b
    ei ; end of critical section
ENDM

;-------------------------------------------------------------------------------

RoomBankPresentLoanInfoPrint:

    ld      a,[bank_room_loan_active]
    and     a,a
    ret     z ; return if loan not present

    xor     a,a
    ld      [rVBK],a

    ; Print number of payments left

    ld      a,[LOAN_REMAINING_PAYMENTS]
    ld      l,a
    ld      h,0
    add     hl,hl
    ld      de,BINARY_TO_BCD
    add     hl,de
    ld      a,[hl]

    ld      d,a ; save value

    ld      b,O_SPACE

    swap    a
    and     a,$0F
    and     a,a
    jr      z,.empty_digit
        BCD2Tile
        ld      b,a
.empty_digit:
    ld      hl,$9800+32*11+16
    WRITE_B_TO_HL_VRAM ; clobbers A and C
    inc     hl
    ld      a,d
    and     a,$0F
    BCD2Tile
    ld      b,a
    WRITE_B_TO_HL_VRAM ; clobbers A and C

    ; Print amount of each payment

    ld      hl,LOAN_PAYMENTS_AMOUNT ; BCD, LSB first
    ld      e,[hl]
    inc     hl
    ld      d,[hl] ; de = payment, BCD

    ld      hl,$9800+32*12+14

    ld      b,O_SPACE

    ld      a,d
    swap    a
    and     a,$0F
    and     a,a
    jr      z,.empty_digit_2
        BCD2Tile
        ld      b,a
.empty_digit_2:
    WRITE_B_TO_HL_VRAM ; clobbers A and C
    inc     hl
    ld      a,d
    and     a,$0F
    BCD2Tile
    ld      b,a
    WRITE_B_TO_HL_VRAM ; clobbers A and C
    inc     hl
    ld      a,e
    swap    a
    and     a,$0F
    BCD2Tile
    ld      b,a
    WRITE_B_TO_HL_VRAM ; clobbers A and C
    inc     hl
    ld      a,e
    and     a,$0F
    BCD2Tile
    ld      b,a
    WRITE_B_TO_HL_VRAM ; clobbers A and C

    ; Calculate and print total amount remaining

    ; de = payment amount

    add     sp,-(5+10) ; (*) BCD_NUMBER_LENGTH + space for tiles

    ld      hl,sp+0
    ld      [hl],e
    inc     hl
    ld      [hl],d
    inc     hl
    ld      a,$00
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl],a

    ld      a,[LOAN_REMAINING_PAYMENTS]
    ld      b,a ; number of payments

    ld      hl,sp+0
    LD_DE_HL ; de = amount of each payment

    call    BCD_DE_UMUL_B ; [de] = [de] * b (B is not in BCD!)

    ld      hl,sp+0
    LD_DE_HL ; bcd value
    ld      hl,sp+5 ; space for tiles
    call    BCD_DE_2TILE_HL_LEADING_SPACES ; [hl] = BCD2TILE [de]

    ld      hl,sp+5+5 ; start reading from the fifth digit

    LD_DE_HL ; de = src
    ld      hl,$9800+32*13+13 ; hl = dst
    REPT    5
    ld      a,[de]
    inc     de
    ld      b,a
    WRITE_B_TO_HL_VRAM ; clobbers A and C
    inc     hl
    ENDR

    add     sp,+(5+10) ; (*) reclaim space

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

    call    SetDefaultVBLHandler

    ld      a,[LOAN_REMAINING_PAYMENTS]
    and     a,a
    jr      nz,.loan_present
        xor     a,a
        jr      .end_loan_check
.loan_present:
        ld      a,1
.end_loan_check:
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
    call    RoomBankPresentLoanInfoPrint

    call    LoadTextPalette

    xor     a,a
    ld      [bank_room_exit],a

.loop:

    call    wait_vbl

    call    scan_keys
    ; Autorepeat makes it difficult to select a specific loan

    call    InputHandleBankMenu

    ld      a,[bank_room_exit]
    and     a,a
    jr      z,.loop

    call    WaitReleasedAllKeys

    call    SetPalettesAllBlack

    call    InitKeyAutorepeat

    ret

;###############################################################################
