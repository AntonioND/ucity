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

;###############################################################################

    SECTION "SRAM Utils Variables",WRAM0

;-------------------------------------------------------------------------------

sram_num_available_banks:: DS 1 ; number of detected available SRAM banks

SRAM_BANK_NUM_MAX EQU 16 ; Max number of banks supported by any mapper

sram_bank_status:: DS SRAM_BANK_NUM_MAX ; 0 = not avail. 1 = ok, 2 = empty/bad

;###############################################################################

    SECTION "SRAM Utils Functions",ROMX

;-------------------------------------------------------------------------------

; Clears one SRAM bank. Call SRAM_CheckIntegrity after this!
SRAM_ClearBank:: ; B = bank to clear

    ld      a,CART_RAM_ENABLE
    ld      [rRAMG],a

    ld      a,b
    ld      [rRAMB],a

    ; It is enough to delete the first byte. It's part of the magic string. If
    ; it is different than the first byte of magic string, the bank is
    ; considered to be corrupted.
    xor     a,a
    ld      [_SRAM],a

    ld      a,CART_RAM_DISABLE
    ld      [rRAMG],a

    ret

;-------------------------------------------------------------------------------

; Check number of available SRAM banks
SRAM_PowerOnCheck::

    ; TODO - Even though this code is really fast, there's still the possibility
    ; of the GBC being turned off during the SRAM manipulation code. Maybe the
    ; checksums should be checked first, as they only require reading data from
    ; the cartridge.

    add     sp,-SRAM_BANK_NUM_MAX

    ld      a,CART_RAM_ENABLE
    ld      [rRAMG],a

    ; Backup data before performing check. Modify the last byte in each SRAM
    ; bank to minimize the risk of corrupting useful data while the check is
    ; in progress.
    ld      hl,sp+0
    ld      a,0
.save_loop:
    ld      [rRAMB],a
    ld      b,a
        ld      a,[_SRAM+$2000-1]
        ld      [hl+],a
    ld      a,b
    inc     a
    cp      a,SRAM_BANK_NUM_MAX
    jr      nz,.save_loop

    ; Write bank number from 15 to 0 to SRAM banks or'ed with $C0
    ld      a,SRAM_BANK_NUM_MAX-1
.write_loop:
    ld      [rRAMB],a
    ld      b,a
        or      a,$C0
        ld      [_SRAM+$2000-1],a
    ld      a,b
    dec     a
    jr      nz,.write_loop

    ; Read the number that we get from bank 15. If there are less banks it will
    ; wrap around and get the actual bank.
    ld      a,SRAM_BANK_NUM_MAX-1
    ld      [rRAMB],a
    ld      a,[_SRAM+$2000-1]
    ld      b,a
    and     a,$F0
    cp      a,$C0
    jr      z,.valid_value
        ; Oh... We didn't get any of the written values. 0 SRAM banks then...
        xor     a,a
        ld      [sram_num_available_banks],a
        jr      .end_check
.valid_value:

    ld      a,b
    and     a,$0F
    inc     a
    ld      [sram_num_available_banks],a

    ; Restore data from bank 15 to 0
    ld      hl,sp+(SRAM_BANK_NUM_MAX-1)
    ld      a,SRAM_BANK_NUM_MAX-1
.restore_loop:
    ld      [rRAMB],a
    ld      b,a
        ld      a,[hl-]
        ld      [_SRAM+$2000-1],a
    ld      a,b
    dec     a
    jr      nz,.restore_loop

.end_check:
    ld      a,CART_RAM_DISABLE
    ld      [rRAMG],a

    add     sp,+SRAM_BANK_NUM_MAX

    ; Now that we know how many banks there are, check data
    call    SRAM_CheckIntegrity

    ret

;-------------------------------------------------------------------------------

SRAM_CheckIntegrity::

    ; Flag all banks as unavailable

    ld      b,SRAM_BANK_NUM_MAX
    ld      hl,sram_bank_status
    ld      a,0
    call    memset_fast ; a = value    hl = start address    b = size

    ; If no banks available, just return

    ld      a,[sram_num_available_banks]
    and     a,a
    ret     z

    ; For all available banks, flag them as ok or corrupted (empty)

    ld      b,0 ; sram number index
    ld      hl,sram_bank_status
.loop_check_bank:

    push    bc
    push    hl

        ; Returns A = 1 if bank is ok, 0 if not
        LONG_CALL_ARGS  SRAMCheckBank ; B = bank to check. doesn't check limits.

        and     a,a
        jr      nz,.sram_bank_ok
            ; Corrupted
            ld      a,2
        jr      .sram_bank_check_end
.sram_bank_ok:
            ; Ok
            ld      a,1
.sram_bank_check_end:

    pop     hl
    pop     bc

    ld      [hl+],a ; save this bank status

    inc     b
    ld      a,[sram_num_available_banks]
    cp      a,b
    jr      nz,.loop_check_bank

    ret

;###############################################################################
