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

    IF !DEF(GBT_PLAYER_INC)
    DEF GBT_PLAYER_INC = 1

;###############################################################################

    EXPORT  gbt_play ; Starts playing a song.
                     ; de = pointer to song data
                     ; a = default speed. Careful, 0 = 256!
                     ; bc = data bank (b ignored if ROM with < 256 banks)
                     ; THIS WILL CHANGE ROM BANK!!!

    EXPORT  gbt_pause ; Pauses or unpauses the song.
                      ; a = 0 to unpause, anything else to pause.

    EXPORT  gbt_loop ; Enables/disables looping at the end of the song.
                     ; a = 0 to stop at the end, anything else to loop

    EXPORT  gbt_stop   ; Stops the song.

    EXPORT  gbt_enable_channels ; Enables given channels.
                                ; a = channel flags ORed:
                                ;         channel 1 = 1
                                ;         channel 2 = 2
                                ;         channel 3 = 4
                                ;         channel 4 = 8

    EXPORT  gbt_update  ; Updates the player, must be called each VBL.
                        ; THIS WILL CHANGE ROM BANK!!!

; - If the following value is uncomented, the total of banks allowed is 512
; (or more), but it's a bit slower. MBC5 ONLY, DOESN'T WORK WITH OTHERS!!!
; YOU MUST USE THE -512-banks OPTION WHEN CONVERTING A SONG WITH mod2gbt!!!
; - If it's commented, only 256 banks are allowed, it's a little bit faster
; and saves a few bytes. MBC1, MBC3 and MBC5 (and others).
;GBT_USE_MBC5_512BANKS SET 1

;###############################################################################

    ENDC ;GBT_PLAYER_INC

;###############################################################################
