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

    INCLUDE "text_messages.inc"

;###############################################################################

    SECTION "Persistent Messages Variables",WRAM0

;-------------------------------------------------------------------------------

persistent_msg_flags:: DS BYTES_SAVE_PERSISTENT_MSG

;###############################################################################

    SECTION "Persistent Messages Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

; Load data from HL into persistent message flags
PersistentMessageDataLoadFrom:: ; hl = ptr to data to load

    ld      bc,BYTES_SAVE_PERSISTENT_MSG
    ld      de,persistent_msg_flags
    call    memcopy ; bc = size    hl = source address    de = dest address

    ret

;-------------------------------------------------------------------------------

; Save data to DE from persistent message flags
PersistentMessageDataSaveTo:: ; de = ptr to space to save

    ld      bc,BYTES_SAVE_PERSISTENT_MSG
    ld      hl,persistent_msg_flags
    call    memcopy ; bc = size    hl = source address    de = dest address

    ret

;-------------------------------------------------------------------------------

; The message ID should be a valid persistent message ID
PersistentMessageShow:: ; a = message ID

    ld      c,a ; (**) save original message ID

    ; Message IDs start at 1
    dec     a

    ld      b,a ; (*) save message ID - 1

    sra     a
    sra     a
    sra     a ; a = ID - 1 / 8
    ld      hl,persistent_msg_flags
    ld      e,a
    ld      d,0
    add     hl,de
    ; hl = pointer to byte which contains the flag

    ld      a,7
    and     a,b ; (*) get bit inside the byte (must be preserved a bit more)

; Test if bit \1 is set and sets it to 1
MACRO TEST_AND_SET_FLAG ; \1 = bit
    cp      a,\1
    jr      nz,.not_set\@
        bit     \1,[hl] ; set or reset Z flag
        set     \1,[hl]
        jr      .end_test
.not_set\@:
ENDM

    TEST_AND_SET_FLAG 0
    TEST_AND_SET_FLAG 1
    TEST_AND_SET_FLAG 2
    TEST_AND_SET_FLAG 3
    TEST_AND_SET_FLAG 4
    TEST_AND_SET_FLAG 5
    TEST_AND_SET_FLAG 6
    TEST_AND_SET_FLAG 7

    ld      b,b ; This shouldn't happen!
    ret

.end_test: ; If Z flag is set to 1, show message

    ld      a,c ; (**) get message id
    call    z,MessageRequestAdd ; a = message ID to show

    ret

;-------------------------------------------------------------------------------

PersistentYearlyMessagesReset::

    ld      hl,persistent_msg_flags
    ; hl = pointer to byte which contains the first flag

    xor     a,a
    ld      b,ID_MSG_RESET_YEAR_NUM/8
.loop:
    ld      [hl+],a
    dec     b
    jr      nz,.loop

    ret

;###############################################################################
