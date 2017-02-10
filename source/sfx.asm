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

    INCLUDE "gbt_player.inc"
    INCLUDE "hardware.inc"
    INCLUDE "engine.inc"

;###############################################################################

    SECTION "SFX Variables 0",WRAM0

;-------------------------------------------------------------------------------

sfx_active:         DS 1
sfx_used_channels:  DS 1 ; A sfx can have times when there is no sound
sfx_countdown_stop: DS 1
sfx_end_callback:   DS 2 ; LSB first

;###############################################################################

    SECTION "SFX Functions Bank 0",ROM0

;-------------------------------------------------------------------------------

SFX_InitSystem::

    xor     a,a
    ld      [sfx_used_channels],a
    ld      [sfx_active],a

    ld      a,$80
    ld      [rNR52],a ; sound on
    ld      a,$77
    ld      [rNR50],a ; volume max for both speakers
    ld      a,$FF
    ld      [rNR51],a ; enable all channels in both speakers

    ret

;-------------------------------------------------------------------------------

SFX_EndSound:

    ; Silence all channels that were used by the last sfx

    ld      hl,sfx_used_channels

    bit     0,[hl]
    jr      z,.not_0

        xor     a,a ; vol = 0
        ld      [rNR12],a
        ld      a,$80 ; start
        ld      [rNR14],a

.not_0:

IF 0
    bit     1,[hl]
    jr      z,.not_1

        xor     a,a ; vol = 0
        ld      [rNR22],a
        ld      a,$80 ; start
        ld      [rNR24],a

.not_1:
    bit     2,[hl]
    jr      z,.not_2

        xor     a,a ; vol = 0
        ld      [rNR32],a
        ld      a,$80 ; start
        ld      [rNR34],a

.not_2:
ENDC

    bit     3,[hl]
    jr      z,.not_3

        xor     a,a ; vol = 0
        ld      [rNR42],a
        ld      a,$80 ; start
        ld      [rNR44],a

.not_3:

    xor     a,a
    ld      [hl],a ; set disable channels
    ld      [sfx_active],a ; set disable sound

    ; Return ownership of channels to music player

    ld      a,$0F
    call    gbt_enable_channels

    ret

;-------------------------------------------------------------------------------

SFX_Handler::

    ; Return if no sound active
    ld      a,[sfx_active]
    and     a,a
    ret     z

    ; Return if it's not the time to change
    ld      hl,sfx_countdown_stop
    dec     [hl]
    ret     nz

    ld      a,[sfx_end_callback+0] ; LSB first
    ld      l,a
    ld      a,[sfx_end_callback+1]
    ld      h,a

    or      a,l ; If no callback, stop sound
    jp      z,SFX_EndSound

    jp      hl ; If callback, jump to it

;-------------------------------------------------------------------------------

SFX_INIT : MACRO
    ld      a,[game_music_disabled]
    and     a,a
    ret     nz

    ; Stop previous sound if any
    ld      a,[sfx_active]
    and     a,a
    call    nz,SFX_EndSound
ENDM

SFX_TIME : MACRO ; \1=frames
    ld      a,\1
    ld      [sfx_countdown_stop],a
ENDM

SFX_END_WITH_CALLBACK : MACRO ; \1=function
    ld      a,(\1) & $FF
    ld      [sfx_end_callback+0],a
    ld      a,(\1) >> 8
    ld      [sfx_end_callback+1],a

    ld      a,1
    ld      [sfx_active],a
ENDM

SFX_END_NO_CALLBACK : MACRO
    xor     a,a
    ld      [sfx_end_callback+0],a
    ld      [sfx_end_callback+1],a

    ld      a,1
    ld      [sfx_active],a
ENDM

SFX_CHANNEL_1 : MACRO ; \1=sweep, \2=duty, \3=volume, \4=freq
    ld      a,\1
    ld      b,(\2)<<6
    ld      c,(\3)<<4
    ld      hl,\4
    call    SFX_Channel1 ; b = duty, lenght, c = volume, hl = freq
ENDM

SFX_Channel1: ; a = sweep, b = duty, lenght, c = volume, hl = freq

    ld      [rNR10],a ; sweep

    ld      a,b ; duty, lenght (unused)
    ld      [rNR11],a
    ld      a,c ; 50% volume, no envelope
    ld      [rNR12],a

    ld      a,l
    ld      [rNR13],a
    ld      a,h
    or      a,$80 ; start
    ld      [rNR14],a

    ld      hl,sfx_used_channels
    set     0,[hl]

    ret

IF 0
SFX_CHANNEL_2 : MACRO ; \1=duty, \2=volume, \3=freq
    ld      b,(\1)<<6
    ld      c,(\2)<<4
    ld      hl,\3
    call    SFX_Channel2 ; b = duty, lenght, c = volume, hl = freq
ENDM

SFX_Channel2: ; b = duty, lenght, c = volume, hl = freq

    ld      a,b ; duty, lenght (unused)
    ld      [rNR21],a
    ld      a,c ; 50% volume, no envelope
    ld      [rNR22],a

    ld      a,l
    ld      [rNR23],a
    ld      a,h
    or      a,$80 ; start
    ld      [rNR24],a

    ld      hl,sfx_used_channels
    set     1,[hl]

    ret
ENDC

SFX_CHANNEL_4 : MACRO ; \1=instrument, \2=volume
    ld      b,\1
    ld      c,(\2)<<4
    call    SFX_Channel4 ; b = instrument, c = volume
ENDM

SFX_Channel4: ; b = instrument, c = volume

    xor     a,a
    ld      [rNR41],a

    ld      a,c
    ld      [rNR42],a

    ld      a,b
    ld      [rNR43],a

    ld      a,$80 ; start
    ld      [rNR44],a

    ld      hl,sfx_used_channels
    set     3,[hl]

    ret

;-------------------------------------------------------------------------------

SFX_Build:: ; Building built
    SFX_INIT
    SFX_CHANNEL_4   $80, 7
    SFX_TIME    5
    SFX_END_NO_CALLBACK
    ret

SFX_BuildError:: ; Can't build or demolish
    SFX_INIT
    ; sweep : time, subtract, 7 sweeps
    SFX_CHANNEL_1   (1<<4) | (1<<3) | 7, 1, 7, 1379
    SFX_TIME    5
    SFX_END_NO_CALLBACK
    ret

SFX_Demolish:: ; Building demolished
    SFX_INIT
    SFX_CHANNEL_4   $5F, 7
    SFX_TIME    5
    SFX_END_NO_CALLBACK
    ret

SFX_Clear:: ; Remove destroyed tile or forest
    SFX_INIT
    SFX_CHANNEL_4   $63, 7
    SFX_TIME    5
    SFX_END_NO_CALLBACK
    ret

SFX_ErrorUI:: ; Invalid option in menu, etc
    SFX_INIT
    SFX_CHANNEL_1   0, 1, 7, 1046
    SFX_TIME    4
    SFX_END_WITH_CALLBACK SFX_ErrorUI2
    ret
SFX_ErrorUI2:
    SFX_INIT
    SFX_CHANNEL_1   0,1, 7, 854
    SFX_TIME    4
    SFX_END_NO_CALLBACK
    ret

SFX_FireExplosion::
    SFX_INIT
    SFX_CHANNEL_4   $90, 7
    SFX_TIME    20
    SFX_END_NO_CALLBACK
    ret

;###############################################################################
