;###############################################################################
;#                                                                             #
;#                                                                             #
;#                              GBT PLAYER  3.0.5                              #
;#                                                                             #
;#                                             Contact: antonio_nd@outlook.com #
;###############################################################################

; Copyright (c) 2009-2016, Antonio Niño Díaz (AntonioND)
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; * Redistributions of source code must retain the above copyright notice, this
;  list of conditions and the following disclaimer.
;
; * Redistributions in binary form must reproduce the above copyright notice,
;   this list of conditions and the following disclaimer in the documentation
;   and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;###############################################################################

    INCLUDE "hardware.inc"
    INCLUDE "gbt_player.inc"

;###############################################################################

    SECTION "GBT_VAR_1",WRAM0

;-------------------------------------------------------------------------------

gbt_playing: DS 1

; pointer to the pattern pointer array
gbt_pattern_array_ptr:  DS 2 ; LSB first
IF DEF(GBT_USE_MBC5_512BANKS)
gbt_pattern_array_bank: DS 2 ; LSB first
ELSE
gbt_pattern_array_bank: DS 1
ENDC

; playing speed
gbt_speed:: DS 1

; Up to 12 bytes per step are copied here to be handled in functions in bank 1
gbt_temp_play_data:: DS 12

gbt_loop_enabled:            DS 1
gbt_ticks_elapsed::          DS 1
gbt_current_step::           DS 1
gbt_current_pattern::        DS 1
gbt_current_step_data_ptr::  DS 2 ; pointer to next step data - LSB first
IF DEF(GBT_USE_MBC5_512BANKS)
gbt_current_step_data_bank:: DS 2 ; bank of current pattern data - LSB first
ELSE
gbt_current_step_data_bank:: DS 1 ; bank of current pattern data
ENDC

gbt_channels_enabled:: DS 1

gbt_pan::   DS 4*1 ; Ch 1-4
gbt_vol::   DS 4*1 ; Ch 1-4
gbt_instr:: DS 4*1 ; Ch 1-4
gbt_freq::  DS 3*2 ; Ch 1-3

gbt_channel3_loaded_instrument:: DS 1 ; current loaded instrument ($FF if none)

; Arpeggio -> Ch 1-3
gbt_arpeggio_freq_index:: DS 3*3 ; {base index, base index+x, base index+y} * 3
gbt_arpeggio_enabled::    DS 3*1 ; if 0, disabled
gbt_arpeggio_tick::       DS 3*1

; Cut note
gbt_cut_note_tick:: DS 4*1 ; If tick == gbt_cut_note_tick, stop note.

; Last step of last pattern this is set to 1
gbt_have_to_stop_next_step:: DS 1

gbt_update_pattern_pointers:: DS 1 ; set to 1 by jump effects

;###############################################################################

    SECTION "GBT_BANK0",ROM0

;-------------------------------------------------------------------------------

gbt_get_pattern_ptr:: ; a = pattern number

    ; loads a pointer to pattern a into gbt_current_step_data_ptr and
    ; gbt_current_step_data_bank

    ld      e,a
    ld      d,0

IF DEF(GBT_USE_MBC5_512BANKS)
    ld      a,[gbt_pattern_array_bank+0]
    ld      [rROMB0],a ; MBC5 - Set bank
    ld      a,[gbt_pattern_array_bank+1]
    ld      [rROMB1],a ; MBC5 - Set bank
ELSE
    ld      a,[gbt_pattern_array_bank]
    ld      [rROMB0],a ; MBC1, MBC3, MBC5 - Set bank
ENDC

    ld      hl,gbt_pattern_array_ptr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ; hl = pointer to list of pointers
    ; de = pattern number

IF DEF(GBT_USE_MBC5_512BANKS)
    add     hl,de
ENDC
    add     hl,de
    add     hl,de
    add     hl,de

    ; hl = pointer to pattern bank

    ld      a,[hl+]
    ld      [gbt_current_step_data_bank+0],a
IF DEF(GBT_USE_MBC5_512BANKS)
    ld      a,[hl+]
    ld      [gbt_current_step_data_bank+1],a
ENDC

    ; hl = pointer to pattern data

    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ld      a,l
    ld      [gbt_current_step_data_ptr],a
    ld      a,h
    ld      [gbt_current_step_data_ptr+1],a

    ret

;-------------------------------------------------------------------------------

gbt_play:: ; de = data, bc = bank, a = speed

    ld      hl,gbt_pattern_array_ptr
    ld      [hl],e
    inc     hl
    ld      [hl],d

    ld      [gbt_speed],a

    ld      a,c
    ld      [gbt_pattern_array_bank+0],a
IF DEF(GBT_USE_MBC5_512BANKS)
    ld      a,b
    ld      [gbt_pattern_array_bank+1],a
ENDC

    ld      a,0
    call    gbt_get_pattern_ptr

    xor     a,a
    ld      [gbt_current_step],a
    ld      [gbt_current_pattern],a
    ld      [gbt_ticks_elapsed],a
    ld      [gbt_loop_enabled],a
    ld      [gbt_have_to_stop_next_step],a
    ld      [gbt_update_pattern_pointers],a

    ld      a,$FF
    ld      [gbt_channel3_loaded_instrument],a

    ld      a,$0F
    ld      [gbt_channels_enabled],a

    ld      hl,gbt_pan
    ld      a,$11 ; L and R
    ld      [hl+],a
    add     a,a
    ld      [hl+],a
    add     a,a
    ld      [hl+],a
    add     a,a
    ld      [hl],a

    ld      hl,gbt_vol
    ld      a,$F0 ; 100%
    ld      [hl+],a
    ld      [hl+],a
    ld      a,$20 ; 100%
    ld      [hl+],a
    ld      a,$F0 ; 100%
    ld      [hl+],a

    ld      a,0

    ld      hl,gbt_instr
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a

    ld      hl,gbt_freq
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a

    ld      [gbt_arpeggio_enabled+0],a
    ld      [gbt_arpeggio_enabled+1],a
    ld      [gbt_arpeggio_enabled+2],a

    ld      a,$FF
    ld      [gbt_cut_note_tick+0],a
    ld      [gbt_cut_note_tick+1],a
    ld      [gbt_cut_note_tick+2],a
    ld      [gbt_cut_note_tick+3],a

    ld      a,$80
    ldh     [rNR52],a
    ld      a,$00
    ldh     [rNR51],a
    ld      a,$00 ; 0%
    ldh     [rNR50],a

    xor     a,a
    ldh     [rNR10],a
    ldh     [rNR11],a
    ldh     [rNR12],a
    ldh     [rNR13],a
    ldh     [rNR14],a
    ldh     [rNR21],a
    ldh     [rNR22],a
    ldh     [rNR23],a
    ldh     [rNR24],a
    ldh     [rNR30],a
    ldh     [rNR31],a
    ldh     [rNR32],a
    ldh     [rNR33],a
    ldh     [rNR34],a
    ldh     [rNR41],a
    ldh     [rNR42],a
    ldh     [rNR43],a
    ldh     [rNR44],a

    ld      a,$77 ; 100%
    ldh     [rNR50],a

    ld      a,$01
    ld      [gbt_playing],a

    ret

;-------------------------------------------------------------------------------

gbt_pause:: ; a = pause/unpause
    ld      [gbt_playing],a
    or      a,a
    ret     z
    xor     a,a
    ldh     [rNR50],a
    ret

;-------------------------------------------------------------------------------

gbt_loop:: ; a = loop/don't loop
    ld      [gbt_loop_enabled],a
    ret

;-------------------------------------------------------------------------------

gbt_stop::
    xor     a,a
    ld      [gbt_playing],a
    ldh     [rNR50],a
    ldh     [rNR51],a
    ldh     [rNR52],a
    ret

;-------------------------------------------------------------------------------

gbt_enable_channels:: ; a = channel flags (channel flag = (1<<(channel_num-1)))
    ld      [gbt_channels_enabled],a
    ret

;-------------------------------------------------------------------------------

    EXPORT  gbt_update_bank1

gbt_update::

    ld      a,[gbt_playing]
    or      a,a
    ret     z ; If not playing, return

    ; Handle tick counter

    ld      hl,gbt_ticks_elapsed
    ld      a,[gbt_speed] ; a = total ticks
    ld      b,[hl] ; b = ticks elapsed
    inc     b
    ld      [hl],b
    cp      a,b
    jr      z,.dontexit

    ; Tick != Speed, update effects and exit
IF DEF(GBT_USE_MBC5_512BANKS)
    xor     a,a
    ld      [$3000],a
ENDC
    ld      a,$01
    ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank 1
    ; Call update function in bank 1 (in gbt_player_bank1.s)
    call    gbt_update_effects_bank1

    ret

.dontexit:
    ld      [hl],$00 ; reset tick counter

    ; Clear tick-based effects
    ; ------------------------

    xor     a,a
    ld      hl,gbt_arpeggio_enabled ; Disable arpeggio
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl],a
    dec     a ; a = $FF
    ld      hl,gbt_cut_note_tick ; Disable cut note
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl],a

    ; Update effects
    ; --------------

IF DEF(GBT_USE_MBC5_512BANKS)
    xor     a,a
    ld      [$3000],a
ENDC
    ld      a,$01
    ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank 1
    ; Call update function in bank 1 (in gbt_player_bank1.s)
    call    gbt_update_effects_bank1

    ; Check if last step
    ; ------------------

    ld      a,[gbt_have_to_stop_next_step]
    or      a,a
    jr      z,.dont_stop

    call    gbt_stop
    ld      a,0
    ld      [gbt_have_to_stop_next_step],a
    ret

.dont_stop:

    ; Get this step data
    ; ------------------

    ; Change to bank with song data

IF DEF(GBT_USE_MBC5_512BANKS)
    ld      a,[gbt_current_step_data_bank+0]
    ld      [$2000],a ; MBC5 - Set bank
    ld      a,[gbt_current_step_data_bank+1]
    ld      [$3000],a ; MBC5 - Set bank
ELSE
    ld      a,[gbt_current_step_data_bank]
    ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank
ENDC

    ; Get step data

    ld      a,[gbt_current_step_data_ptr]
    ld      l,a
    ld      a,[gbt_current_step_data_ptr+1]
    ld      h,a ; hl = pointer to data

    ld      de,gbt_temp_play_data

    ld      b,4
.copy_loop: ; copy as bytes as needed for this step

    ld      a,[hl+]
    ld      [de],a
    inc     de
    bit     7,a
    jr      nz,.more_bytes
    bit     6,a
    jr      z,.no_more_bytes_this_channel

    jr      .one_more_byte

.more_bytes:

    ld      a,[hl+]
    ld      [de],a
    inc     de
    bit     7,a
    jr      z,.no_more_bytes_this_channel

.one_more_byte:

    ld      a,[hl+]
    ld      [de],a
    inc     de

.no_more_bytes_this_channel:
    dec     b
    jr      nz,.copy_loop

    ld      a,l
    ld      [gbt_current_step_data_ptr],a
    ld      a,h
    ld      [gbt_current_step_data_ptr+1],a ; save pointer to data

    ; Increment step/pattern
    ; ----------------------

    ; Increment step

    ld      a,[gbt_current_step]
    inc     a
    ld      [gbt_current_step],a
    cp      a,64
    jr      nz,.dont_increment_pattern

    ; Increment pattern

    ld      a,0
    ld      [gbt_current_step],a ; Step 0

    ld      a,[gbt_current_pattern]
    inc     a
    ld      [gbt_current_pattern],a

    call    gbt_get_pattern_ptr

    ld      a,[gbt_current_step_data_ptr]
    ld      b,a
    ld      a,[gbt_current_step_data_ptr+1]
    or      a,b
    jr      nz,.not_ended ; if pointer is 0, song has ended

    ld      a,[gbt_loop_enabled]
    and     a,a

    jr      z,.loop_disabled

    ; If loop is enabled, jump to pattern 0

    ld      a,0
    ld      [gbt_current_pattern],a

    call    gbt_get_pattern_ptr

    jr      .end_handling_steps_pattern

.loop_disabled:

    ; If loop is disabled, stop song
    ; Stop it next step, if not this step won't be played

    ld      a,1
    ld      [gbt_have_to_stop_next_step],a

.not_ended:

.dont_increment_pattern:

.end_handling_steps_pattern:

IF DEF(GBT_USE_MBC5_512BANKS)
    xor     a,a
    ld      [$3000],a ; MBC5
ENDC
    ld      a,$01
    ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank 1
    ; Call update function in bank 1 (in gbt_player_bank1.s)
    call    gbt_update_bank1

    ; Check if any effect has changed the pattern or step

    ld      a,[gbt_update_pattern_pointers]
    and     a,a
    ret     z
    ; if any effect has changed the pattern or step, update

    xor     a,a
    ld      [gbt_update_pattern_pointers],a ; clear update flag

    ld      [gbt_have_to_stop_next_step],a ; clear stop flag

    ld      a,[gbt_current_pattern]
    call    gbt_get_pattern_ptr ; set ptr to start of the pattern

    ; Search the step

    ; Change to bank with song data

IF DEF(GBT_USE_MBC5_512BANKS)
    ld      a,[gbt_pattern_array_bank+1]
    ld      [$3000],a ; MBC5
ENDC
    ld      a,[gbt_pattern_array_bank+0]
    ld      [$2000],a ; MBC1, MBC3, MBC5

    ld      a,[gbt_current_step_data_ptr]
    ld      l,a
    ld      a,[gbt_current_step_data_ptr+1]
    ld      h,a ; hl = pointer to data

    ld      a,[gbt_current_step]
    and     a,a
    ret     z ; if changing to step 0, exit

    add     a,a
    add     a,a
    ld      b,a ; b = iterations = step * 4 (number of channels)
.next_channel:

    ld      a,[hl+]
    bit     7,a
    jr      nz,.next_channel_more_bytes
    bit     6,a
    jr      z,.next_channel_no_more_bytes_this_channel

    jr      .next_channel_one_more_byte

.next_channel_more_bytes:

    ld      a,[hl+]
    bit     7,a
    jr      z,.next_channel_no_more_bytes_this_channel

.next_channel_one_more_byte:

    ld      a,[hl+]

.next_channel_no_more_bytes_this_channel:
    dec     b
    jr      nz,.next_channel

    ld      a,l
    ld      [gbt_current_step_data_ptr],a
    ld      a,h
    ld      [gbt_current_step_data_ptr+1],a ; save pointer to data

    ret

;###############################################################################
