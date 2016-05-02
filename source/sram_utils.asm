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

    SECTION "SRAM Utils Variables",WRAM0

;-------------------------------------------------------------------------------

sram_bank_number: DS 1

;###############################################################################

    SECTION "SRAM Utils Functions",ROMX

;-------------------------------------------------------------------------------

; Check number of available SRAM banks
SRAM_PowerOnCheck::

    add     sp,-16

    ld      a,CART_RAM_ENABLE
    ld      [rRAMG],a

    ; Backup data before performing check
    ld      hl,sp+0
    ld      a,0
.save_loop:
    ld      [rRAMB],a
    ld      b,a
        ld      a,[_SRAM+0]
        ld      [hl+],a
    ld      a,b
    inc     a
    cp      a,16
    jr      nz,.save_loop

    ; Write bank number from 15 to 0 to SRAM banks or'ed with $C0
    ld      a,15
.write_loop:
    ld      [rRAMB],a
    ld      b,a
        or      a,$C0
        ld      [_SRAM+0],a
    ld      a,b
    dec     a
    jr      nz,.write_loop

    ; Read the number that we get from bank 15. If there are less banks it will
    ; wrap around and get the actual bank.
    ld      a,15
    ld      [rRAMB],a
    ld      a,[_SRAM+0]
    ld      b,a
    and     a,$F0
    cp      a,$C0
    jr      z,.valid_value
        ; Oh... We didn't get any of the written values. 0 SRAM banks then...
        xor     a,a
        ld      [sram_bank_number],a
        jr      .end_check
.valid_value:

    ld      a,b
    and     a,$0F
    inc     a
    ld      [sram_bank_number],a

    ; Restore data from bank 15 to 0
    ld      hl,sp+15
    ld      a,15
.restore_loop:
    ld      [rRAMB],a
    ld      b,a
        ld      a,[hl-]
        ld      [_SRAM+0],a
    ld      a,b
    dec     a
    jr      nz,.restore_loop

.end_check:
    ld      a,CART_RAM_DISABLE
    ld      [rRAMG],a

    add     sp,+16

    ; Now that we know how many banks there are, check data
    call    SRAM_CheckIntegrity

    ret

;-------------------------------------------------------------------------------

SRAM_CheckIntegrity:: ; TODO

    ld      a,[sram_bank_number]
    and     a,a
    ret     z ; return if no SRAM available

    ret

;###############################################################################
