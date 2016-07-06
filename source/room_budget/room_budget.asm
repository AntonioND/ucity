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

    SECTION "Room Budget Variables",WRAM0

;-------------------------------------------------------------------------------

budget_room_exit:  DS 1 ; set to 1 to exit room

;###############################################################################

    SECTION "Room Budget Data",ROMX

;-------------------------------------------------------------------------------

BUDGET_MENU_BG_MAP:
    INCBIN "budget_menu_bg_map.bin"

BUDGET_MENU_WIDTH  EQU 20
BUDGET_MENU_HEIGHT EQU 18

;###############################################################################

    SECTION "Room Minimap Code Bank 0",ROM0

;-------------------------------------------------------------------------------

BudgetMenuMandleInput: ; If it returns 1, exit room. If 0, continue

    ; Exit if B or START are pressed
    ld      a,[joy_pressed]
    and     a,PAD_B|PAD_START
    jr      z,.end_b_start
        ld      a,1
        ret ; return 1
.end_b_start:

    ld      a,[joy_pressed]
    and     a,PAD_LEFT
    jr      z,.end_left
        ld      a,[tax_percentage]
        and     a,a
        jr      z,.end_left
            dec     a
            ld      [tax_percentage],a
            call    BudgetMenuPrintTaxPercent
.end_left:

    ld      a,[joy_pressed]
    and     a,PAD_RIGHT
    jr      z,.end_right
        ld      a,[tax_percentage]
        cp      a,TAX_PERCENTAGE_MAX
        jr      z,.end_right
            inc     a
            ld      [tax_percentage],a
            call    BudgetMenuPrintTaxPercent
.end_right:

    xor     a,a
    ret ; return 0

;-------------------------------------------------------------------------------

PrintMoneyAmount:: ; [hl] = Print [de] | leading zeros = spaces

    ; Convert to tile from BCD
    ; de - LSB first, LSB in lower nibbles
    ld      bc,3*2-1
    add     hl,bc
    ld      b,3
.loop_decode:
    ld      a,[de]
    inc     de
    ld      c,a

    and     a,$0F
    add     a,O_ZERO
    ld      [hl-],a

    ld      a,c
    swap    a
    and     a,$0F
    add     a,O_ZERO
    ld      [hl-],a

    dec     b
    jr      nz,.loop_decode

    ld      b,3*2-1
    inc     hl
.loop_zero:
    ld      a,[hl]
    cp      a,O_ZERO
    jr      nz,.end
    ld      a,O_SPACE
    ld      [hl+],a
    dec     b
    jr      nz,.loop_zero
.end:

    ret

;-------------------------------------------------------------------------------

BudgetMenuPrintMoneyAmounts:

    add     sp,-6

PRINT_MONEY : MACRO ; \1 = pointer to amount of money, \2 = Y coordinate
    ld      de,\1
    ld      hl,sp+0
    call    PrintMoneyAmount ; [hl] = Print [de]

    ld      de,$9800 + 32*(\2) + 13
    ld      hl,sp+0

    ld      b,6
.loop\@:
    di
    WAIT_SCREEN_BLANK ; Clobbers registers A and C
    ld      a,[hl+]
    ld      [de],a
    inc     de
    ei
    dec     b
    jr      nz,.loop\@
ENDM

    PRINT_MONEY taxes_rci,   6
    PRINT_MONEY taxes_other, 7

    PRINT_MONEY budget_police,     10
    PRINT_MONEY budget_firemen,    11
    PRINT_MONEY budget_healthcare, 12
    PRINT_MONEY budget_education,  13
    PRINT_MONEY budget_transport,  14

    add     sp,+6

    ret

;-------------------------------------------------------------------------------

BudgetMenuPrintTaxPercent:

    xor     a,a
    ld      [rVBK],a

    ld      a,[tax_percentage]
    sla     a
    ld      l,a
    ld      h,(BINARY_TO_BCD>>8) & $FF ; 2 bytes per entry. LSB first
    ld      a,[hl] ; Tax percentage goes from 0 to 20, no need to get MSB!

    ; Coordinates of tax percent on the screen: 15, 5
    ld      de,$9800 + 32*5 + 15

    ld      b,a ; (*) save

        ld      a,b
        swap    a
        and     a,$0F
        jr      nz,.not_zero

.is_zero:
            ld      h,O_SPACE
            jr      .write_tile
.not_zero:
            BCD2Tile
            ld      h,a ; save
.write_tile

        di
        WAIT_SCREEN_BLANK ; Clobbers registers A and C
        ld      a,h ; restore
        ld      [de],a
        ei

    inc     de

        ld      a,b
        and     a,$0F
        BCD2Tile
        ld      h,a ; save
        di
        WAIT_SCREEN_BLANK ; Clobbers registers A and C
        ld      a,h ; restore
        ld      [de],a
        ei

    ret

;-------------------------------------------------------------------------------

InputHandleBudgetMenu:

    call    BudgetMenuMandleInput ; If it returns 1, exit room. If 0, continue
    and     a,a
    ret     z ; don't exit

    ; Exit
    ld      a,1
    ld      [budget_room_exit],a
    ret

;-------------------------------------------------------------------------------

BudgetMenuVBLHandler:

    call    refresh_OAM

    ret

;-------------------------------------------------------------------------------

RoomBudgetMenuLoadBG:

    ; Load border
    ; -----------

    ld      b,BANK(BUDGET_MENU_BG_MAP)
    call    rom_bank_push_set

        ; Load map
        ; --------

        ; Tiles
        xor     a,a
        ld      [rVBK],a

        ld      de,$9800
        ld      hl,BUDGET_MENU_BG_MAP

        ld      a,BUDGET_MENU_HEIGHT
.loop1:
        push    af

        ld      b,BUDGET_MENU_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-BUDGET_MENU_WIDTH
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

        ld      a,BUDGET_MENU_HEIGHT
.loop2:
        push    af

        ld      b,BUDGET_MENU_WIDTH
        call    vram_copy_fast ; b = size - hl = source address - de = dest

        push    hl
        ld      hl,32-BUDGET_MENU_WIDTH
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

RoomBudgetMenu::

    call    SetPalettesAllBlack

    ld      bc,BudgetMenuVBLHandler
    call    irq_set_VBL

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ld      [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    call    RoomBudgetMenuLoadBG

    ; Update numbers
    call    BudgetMenuPrintTaxPercent
    call    BudgetMenuPrintMoneyAmounts

    call    LoadTextPalette

    xor     a,a
    ld      [budget_room_exit],a

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleBudgetMenu

    ld      a,[budget_room_exit]
    and     a,a
    jr      z,.loop

    call    SetDefaultVBLHandler

    call    SetPalettesAllBlack

    ret

;###############################################################################
