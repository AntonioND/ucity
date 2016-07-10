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

    INCLUDE "text.inc"
    INCLUDE "text_messages.inc"

;###############################################################################

    SECTION "Message Box Variables",WRAM0

;-------------------------------------------------------------------------------

saved_scx: DS 1
saved_scy: DS 1

MESSAGE_BOX_HEIGHT EQU 8*5
MESSAGE_BOX_MSG_TILES_HEIGHT EQU 3 ; 2 tiles for the border

MESSAGE_BOX_Y   EQU (((144-MESSAGE_BOX_HEIGHT)/2)&(~7)) ; Align to 8 pixels
MESSAGE_BOX_SCY EQU (144-MESSAGE_BOX_Y)

;###############################################################################

    SECTION "Message Box Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

MessageBoxHandlerSTAT:

    ; This handler is only called if the message box is active, no need to check

    ; This is a critical section, but as we are inside an interrupt handler
    ; there is no need to use 'di' and 'ei' with WAIT_SCREEN_BLANK.

    ld      a,[rLYC]
    cp      a,MESSAGE_BOX_Y-1
    jr      nz,.hide

        ; Show

        WAIT_SCREEN_BLANK

        ld      a,[rLCDC]
        and     a,(~LCDCF_BG9C00) & $FF
        or      a,LCDCF_BG8000
        ld      [rLCDC],a

        ld      a,[rLCDC]
        and     a,(~LCDCF_BG9C00|LCDCF_BG8000) & $FF
        ld      [rLCDC],a

        xor     a,a
        ld      [rSCX],a
        ld      a,MESSAGE_BOX_SCY
        ld      [rSCY],a

        ld      a,MESSAGE_BOX_Y+MESSAGE_BOX_HEIGHT-1
        ld      [rLYC],a

        ret

.hide:
        ; Hide

        WAIT_SCREEN_BLANK

        ld      a,[rLCDC]
        or      a,LCDCF_BG9C00
        and     a,(~LCDCF_BG8000) & $FF
        ld      [rLCDC],a

        ld      a,[saved_scx]
        ld      [rSCX],a
        ld      a,[saved_scy]
        ld      [rSCY],a

        ld      a,MESSAGE_BOX_Y-1
        ld      [rLYC],a

        ret

;-------------------------------------------------------------------------------

MessageBoxHide::

    di

    WAIT_SCREEN_BLANK

    ld      a,[saved_scx]
    ld      [rSCX],a
    ld      a,[saved_scy]
    ld      [rSCY],a

        ld      a,[rLCDC]
        or      a,LCDCF_BG9C00
        and     a,(~LCDCF_BG8000) & $FF
        ld      [rLCDC],a

    xor     a,a
    ld      [rSTAT],a

    ld      bc,$0000
    call    irq_set_LCD

    ei

    ret

;-------------------------------------------------------------------------------

MessageBoxShow::

    ld      a,[rSCX]
    ld      [saved_scx],a
    ld      a,[rSCY]
    ld      [saved_scy],a

    ld      bc,MessageBoxHandlerSTAT
    call    irq_set_LCD

    ld      a,STATF_LYC
    ld      [rSTAT],a

    ld      hl,rIE
    set     1,[hl] ; enable STAT interrupt

    ret

;-------------------------------------------------------------------------------

MessageBoxPrint:: ; bc = pointer to string

    ; Clear message box

    push    bc ; (*) save pointer

    ld      hl,$9800 + 32*19 + 1

    REPT    MESSAGE_BOX_MSG_TILES_HEIGHT

        ld      b,18
        ld      d,O_SPACE
.loop_clear\@:
        WAIT_SCREEN_BLANK ; Clobbers registers A and C
        ld      [hl],d
        inc     hl
        dec     b
        jr      nz,.loop_clear\@

        ld      de,32-18
        add     hl,de
    ENDR

    pop     bc ; (*) restore pointer

    ; Print message

    ld      hl,$9800 + 32*19 + 1

.loop:
    ld      a,[bc]
    inc     bc
    and     a,a
    ret     z ; Return if the character is a 0 (string terminator)

    cp      a,$0A ; $0A is a line feed character
    jr      nz,.not_line_jump
        ld      de,32
        add     hl,de

        ld      a,l
        and     a,(~31) & $FF ; align to next line
        inc     a ; skip first column
        ld      l,a

        jr      .loop ; continue
.not_line_jump:

    push    hl
    call    ASCII2Tile ; destroys de and hl
    pop     hl

    push    bc
    ld      b,a
    WAIT_SCREEN_BLANK ; Clobbers registers A and C
    ld      a,b
    ld      [hl+],a
    pop     bc

    jr      .loop

;-------------------------------------------------------------------------------

MessageBoxPrintMessageID:: ; a = message ID

    call    MessageRequestGetPointer ; a = message ID, returns hl = pointer

    LD_DE_HL
    ld      b,ROM_BANK_TEXT_MSG
    call    rom_bank_push_set ; preserves de
    LD_BC_DE

    call    MessageBoxPrint ; bc = pointer to string

    call    rom_bank_pop

    ret

;###############################################################################
