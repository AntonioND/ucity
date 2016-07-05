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

;###############################################################################

    SECTION "Room Budget Variables",WRAM0

;-------------------------------------------------------------------------------

budget_room_exit:  DS 1 ; set to 1 to exit room

tax_percentage::   DS 1

TAX_PERCENTAGE_MAX EQU 20

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
.end_left:

    ld      a,[joy_pressed]
    and     a,PAD_RIGHT
    jr      z,.end_right
        ld      a,[tax_percentage]
        cp      a,TAX_PERCENTAGE_MAX+1
        jr      z,.end_right
            inc     a
            ld      [tax_percentage],a
.end_right:

    xor     a,a
    ret ; return 0

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
