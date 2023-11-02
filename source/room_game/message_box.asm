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
    INCLUDE "text_messages.inc"

;###############################################################################

    SECTION "Message Box Variables",WRAM0

;-------------------------------------------------------------------------------

saved_scx: DS 1
saved_scy: DS 1

    DEF MESSAGE_BOX_HEIGHT EQU 8*5
    DEF MESSAGE_BOX_MSG_TILES_HEIGHT EQU 3 ; 2 tiles for the border

    DEF MESSAGE_BOX_Y   EQU (((144-MESSAGE_BOX_HEIGHT)/2)&(~7)) ; Align to 8 pixels
    DEF MESSAGE_BOX_SCY EQU (144-MESSAGE_BOX_Y)

message_box_enabled: DS 1 ; 1 if enabled

;###############################################################################

    SECTION "Message Box Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

MessageBoxHandlerSTAT:

    ; This handler is only called if the message box is active, no need to check

    ; This is a critical section, but as we are inside an interrupt handler
    ; there is no need to use 'di' and 'ei' with WAIT_SCREEN_BLANK.

    ldh     a,[rLYC]
    cp      a,MESSAGE_BOX_Y-1
    jr      nz,.hide

        ; Show

        WAIT_SCREEN_BLANK

        ldh     a,[rLCDC]
        and     a,(~LCDCF_BG9C00) & $FF
        or      a,LCDCF_BG8000
        ldh     [rLCDC],a

        ldh     a,[rLCDC]
        and     a,(~LCDCF_BG9C00|LCDCF_BG8000) & $FF
        ldh     [rLCDC],a

        xor     a,a
        ldh     [rSCX],a
        ld      a,MESSAGE_BOX_SCY
        ldh     [rSCY],a

        ld      a,MESSAGE_BOX_Y+MESSAGE_BOX_HEIGHT-1
        ldh     [rLYC],a

        ret

.hide:
        ; Hide

        WAIT_SCREEN_BLANK

        ldh     a,[rLCDC]
        or      a,LCDCF_BG9C00
        and     a,(~LCDCF_BG8000) & $FF
        ldh     [rLCDC],a

        ld      a,[saved_scx]
        ldh     [rSCX],a
        ld      a,[saved_scy]
        ldh     [rSCY],a

        ld      a,MESSAGE_BOX_Y-1
        ldh     [rLYC],a

        ret

;-------------------------------------------------------------------------------

MessageBoxHide::

    di

    WAIT_SCREEN_BLANK

    ld      a,[saved_scx]
    ldh     [rSCX],a
    ld      a,[saved_scy]
    ldh     [rSCY],a

        ldh     a,[rLCDC]
        or      a,LCDCF_BG9C00
        and     a,(~LCDCF_BG8000) & $FF
        ldh     [rLCDC],a

    xor     a,a
    ldh     [rSTAT],a

    ld      bc,$0000
    call    irq_set_LCD

    ei

    xor     a,a
    ld      [message_box_enabled],a

    ret

;-------------------------------------------------------------------------------

MessageBoxShow::

    ld      a,1
    ld      [message_box_enabled],a

    ldh     a,[rSCX]
    ld      [saved_scx],a
    ldh     a,[rSCY]
    ld      [saved_scy],a

    ld      bc,MessageBoxHandlerSTAT
    call    irq_set_LCD

    ld      a,STATF_LYC
    ldh     [rSTAT],a

    ld      hl,rIE
    set     1,[hl] ; enable STAT interrupt

    ret

;-------------------------------------------------------------------------------

MessageBoxIsShowing::

    ld      a,[message_box_enabled]

    ret

;-------------------------------------------------------------------------------

MessageBoxClear::

    xor     a,a
    ldh     [rVBK],a

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

    ret

;-------------------------------------------------------------------------------

MessageBoxPrint:: ; bc = pointer to string

    ; Clear message box

    push    bc ; (*) save pointer

    call    MessageBoxClear

    pop     bc ; (*) restore pointer

    ; Print message

    xor     a,a
    ldh     [rVBK],a

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

    push    bc
    ld      b,a
    di
    WAIT_SCREEN_BLANK ; Clobbers registers A and C
    ld      a,b
    ld      [hl+],a
    ei
    pop     bc

    jr      .loop

;-------------------------------------------------------------------------------

MessageBoxPrintMessageID:: ; a = message ID

    ld      d,a ; save ID
    ld      b,ROM_BANK_TEXT_MSG
    call    rom_bank_push_set ; preserves de
    ld      a,d ; restore ID

    call    MessageRequestGetPointer ; a = message ID, returns hl = pointer

    LD_BC_HL
    call    MessageBoxPrint ; bc = pointer to string

    call    rom_bank_pop

    ret

;###############################################################################
