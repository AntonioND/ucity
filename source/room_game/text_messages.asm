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

    SECTION "Text Messages Functions",ROMX,BANK[ROM_BANK_TEXT_MSG]

;-------------------------------------------------------------------------------

    DEF CURINDEX = 0

MACRO MSG_SET_INDEX ; 1 = Index
    IF (\1) < CURINDEX ; check if going backwards and stop if so
        FAIL "ERROR : text_messages.asm : Index already in use!"
    ENDC
    IF (\1) > CURINDEX ; If there's a hole to fill, fill it
        REPT (\1) - CURINDEX
            DW $0000
        ENDR
    ENDC
    DEF CURINDEX = (\1)
ENDM

MACRO MSG_ADD ; 1=Name of label where the text is
    MSG_SET_INDEX ID_\1
    DW  \1
    DEF CURINDEX = CURINDEX + 1
ENDM

;-------------------------------------------------------------------------------

; Labels should be named MSG_xxxx and IDs should be named ID_MSG_xxxx

MSG_EMPTY:
MSG_CUSTOM: ; Placeholder, not actually used
    DB 0 ; End string

MSG_POLLUTION_HIGH:
    STR_ADD "Pollution is too<nl>high!"
MSG_TRAFFIC_HIGH:
    STR_ADD "Traffic is too<nl>high!"
MSG_MONEY_NEGATIVE_CAN_LOAN:
    STR_ADD "You have run out<nl>of money. Consider<nl>getting a loan."
MSG_MONEY_NEGATIVE_CANT_LOAN:
    STR_ADD "You have run out<nl>of money!"

MSG_CLASS_TOWN:
    STR_ADD "Your village is<nl>now a town!"
MSG_CLASS_CITY:
    STR_ADD "Your town is now a<nl>city!"
MSG_CLASS_METROPOLIS:
    STR_ADD "Your city is now a<nl>metropolis!"
MSG_CLASS_CAPITAL:
    STR_ADD "Your metropolis is<nl>now a capital!"

MSG_TECH_NUCLEAR:
    STR_ADD "Scientists have<nl>invented nuclear<nl>power plants!"
MSG_TECH_FUSION:
    STR_ADD "Scientists have<nl>invented fusion<nl>power plants!"

MSG_FIRE_INITED:
    STR_ADD "A fire has started<nl>somewhere!"
MSG_NUCLEAR_MELTDOWN:
    STR_ADD "A nuclear power<nl>plant has had a<nl>meltdown!"

MSG_TECH_INSUFFICIENT:
    STR_ADD "Technology isn't<nl>advanced enough<nl>to build that!"
MSG_POPULATION_INSUFFICIENT:
    STR_ADD "There isn't enough<nl>population to<nl>build that!"
MSG_FINISHED_LOAN:
    STR_ADD "You have finished<nl>repaying your<nl>loan."
MSG_GAME_OVER_1:
    STR_ADD "The people are<nl>tired of you."
MSG_GAME_OVER_2:
    STR_ADD "<nl>     Game Over"

;-------------------------------------------------------------------------------

MSG_POINTERS: ; Array of pointer to messages. LSB first
    MSG_ADD MSG_EMPTY

    MSG_ADD MSG_POLLUTION_HIGH
    MSG_ADD MSG_TRAFFIC_HIGH
    MSG_ADD MSG_MONEY_NEGATIVE_CAN_LOAN
    MSG_ADD MSG_MONEY_NEGATIVE_CANT_LOAN

    MSG_ADD MSG_CLASS_TOWN
    MSG_ADD MSG_CLASS_CITY
    MSG_ADD MSG_CLASS_METROPOLIS
    MSG_ADD MSG_CLASS_CAPITAL

    MSG_ADD MSG_TECH_NUCLEAR
    MSG_ADD MSG_TECH_FUSION

    MSG_ADD MSG_FIRE_INITED
    MSG_ADD MSG_NUCLEAR_MELTDOWN

    MSG_ADD MSG_TECH_INSUFFICIENT
    MSG_ADD MSG_POPULATION_INSUFFICIENT
    MSG_ADD MSG_FINISHED_LOAN
    MSG_ADD MSG_GAME_OVER_1
    MSG_ADD MSG_GAME_OVER_2

    MSG_ADD MSG_CUSTOM

;###############################################################################

    SECTION "Text Messages Variables",WRAM0

;-------------------------------------------------------------------------------

    DEF MSG_QUEUE_DEPTH EQU 16 ; must be a power of 2

msg_stack:   DS MSG_QUEUE_DEPTH ; emtpy elements must be set to 0
msg_in_ptr:  DS 1
msg_out_ptr: DS 1

    DEF MSG_CUSTOM_LENGTH EQU ((20-2)*3) ; text box size

msg_custom_text: DS MSG_CUSTOM_LENGTH+1 ; storage for custom msg + terminator

;###############################################################################

    SECTION "Text Messages Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

; NOTE: Don't use with ID_MSG_CUSTOM! Use MessageRequestAddCustom instead.
MessageRequestAdd:: ; a = message ID to show. returns a = 1 if ok, 0 if not

    ld      c,a ; (*) save ID

    ; Check if this message is already in the queue

    ld      hl,msg_stack
    ld      b,MSG_QUEUE_DEPTH
.loop:
    ld      a,[hl+]
    cp      a,c ; (*)
    jr      nz,.dont_ret
        xor     a,a
        ret ; return 0 = not ok
.dont_ret:
    dec     b
    jr      nz,.loop

    ; Check if there is space to save another message

    ld      a,[msg_in_ptr]
    ld      hl,msg_stack
    ld      e,a
    ld      d,0
    add     hl,de

    ld      a,[hl]
    and     a,a ; if the next slot is 0, there's free space
    jr      z,.free_space

        ld      b,b ; Panic!
        xor     a,a
        ret ; return 0 = not ok

.free_space:

    ; Add message to the queue

    ld      a,[msg_in_ptr]
    ld      hl,msg_stack
    ld      e,a
    ld      d,0
    add     hl,de

    ld      [hl],c ; (*) save ID to queue

    inc     a
    and     a,MSG_QUEUE_DEPTH-1 ; wrap around
    ld      [msg_in_ptr],a

    ld      a,1
    ret ; return 1 = ok

;-------------------------------------------------------------------------------

MessageRequestAddCustom:: ; bc = pointer to message. ret a = 1 if ok, 0 if not

    push    bc
    ld      a,ID_MSG_CUSTOM
    call    MessageRequestAdd
    pop     bc
    and     a,a
    ret     z ; return 0 if adding the message failed

    ld      hl,msg_custom_text
    ld      d,MSG_CUSTOM_LENGTH ; storage for custom messages
.loop:
    ld      a,[bc]
    ld      [hl+],a

    and     a,a ; if this is a terminator, exit now
    jr      .dont_ret
        ld      a,1
        ret ; return 1 = ok
.dont_ret:
    inc     bc
    dec     d
    jr      nz,.loop

    ld      [hl],0 ; terminator, just in case

    ld      a,1
    ret ; return 1 = ok

;-------------------------------------------------------------------------------

MessageRequestQueueNotEmpty:: ; returns a = 1 if queue is not empty

    ; Check if there are messages left, and return the first one if so

    ld      a,[msg_out_ptr]
    ld      hl,msg_stack
    ld      e,a
    ld      d,0
    add     hl,de

    ld      a,[hl]
    and     a,a
    ret     z ; return 0 if the message is 0 (empty)

    ld      a,1
    ret ; return not empty

;-------------------------------------------------------------------------------

MessageRequestGet:: ; returns a = message ID to show

    ; Check if there are messages left, and return the first one if so

    ld      a,[msg_out_ptr]
    ld      hl,msg_stack
    ld      e,a
    ld      d,0
    add     hl,de

    ld      a,[hl]
    and     a,a
    ret     z ; return 0 if the message is 0

    ; Clear slot

    ld      [hl],0

    ; Increase out pointer

    ld      c,a ; preserve message ID

    ld      a,[msg_out_ptr]
    inc     a
    and     a,MSG_QUEUE_DEPTH-1 ; wrap around
    ld      [msg_out_ptr],a

    ld      a,c ; return message ID

    ret

;-------------------------------------------------------------------------------

; This function must be called while on bank ROM_BANK_TEXT_MSG
MessageRequestGetPointer:: ; a = message ID, returns hl = pointer to message

    cp      a,ID_MSG_CUSTOM
    jr      nz,.not_custom
        ld      hl,msg_custom_text ; storage for custom messages
        ret
.not_custom:

    ld      e,a
    ld      d,0
    ld      hl,MSG_POINTERS
    add     hl,de
    add     hl,de

    ld      a,[hl+] ; LSB first
    ld      h,[hl]
    ld      l,a

    ret

;###############################################################################
