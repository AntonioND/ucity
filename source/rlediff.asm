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

    SECTION "RLE Uncompress",ROM0

;-------------------------------------------------------------------------------

; Decompress data from a buffer into a different buffer, returning the
; uncompressed size.
; If the size marked in the buffer header is incorrect bad things may happen.
RLE_Uncompress:: ; hl = src, bc = dst. Returns de = size

    ld      a,[hl+]
    cp      a,$30
    jr      z,.magic_ok
        ld      b,b
        ret
.magic_ok:

    ld      a,[hl+]
    ld      e,a
    ld      a,[hl+]
    ld      d,a ; DE = raw size.
    ld      a,[hl+]
    and     a,a
    jr      z,.size_ok ; The size can't possibly be bigger than 16 bits
        ld      b,b
        ret
.size_ok:

    push    de ; (*) save this to return it later!

.loop:

    push    de
    ld      a,[hl+] ; get block header

    bit     7,a
    jr      z,.uncomp
        ; N+3 compressed bytes
        and     a,$7F
        add     a,3
        ld      e,a
        ld      d,a ; preserve size to subtract it later

        ld      a,[hl+]
.loopcomp:
            ld      [bc],a
            inc     bc
            dec     e
            jr      nz,.loopcomp

        jr      .continueloop
.uncomp:
        ; N+1 uncompressed bytes
        inc     a
        ld      e,a
        ld      d,a ; preserve size to subtract it later

.loopuncomp:
            ld      a,[hl+]
            ld      [bc],a
            inc     bc
            dec     e
            jr      nz,.loopuncomp

.continueloop:

        ; D holds the size of the last block
        ld      a,d

    pop     de

    cpl
    inc     a ; a = -a
    add     a,e
    ld      e,a

    ld      a,$FF
    adc     a,0
    add     a,d
    ld      d,a

    or      a,e

    jr      nz,.loop

    pop     de ; (*) get size and return it in DE

    ret
;-------------------------------------------------------------------------------

; Undoes a diff filter. The source buffer is also used as destination.
Diff_Uncompress:: ; hl = src = dst, de = size

    ld      b,0

.loop:

    ld      a,b
    add     a,[hl]
    ld      [hl+],a
    ld      b,a

    dec     de
    ld      a,d
    or      a,e
    jr      nz,.loop

    ret

;###############################################################################
