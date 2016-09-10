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

    SECTION "Genenerate Map Variables",HRAM

;-------------------------------------------------------------------------------

seedx: DS 1
seedy: DS 1
seedz: DS 1
seedw: DS 1

;###############################################################################

    SECTION "Genenerate Map Code Data",ROMX

;-------------------------------------------------------------------------------

gen_map_srand:: ; a = seed x, b = seed y

    ldh     [seedx],a ; 21
    ld      a,b ; 229
    ldh     [seedy],a
    ld      a,181
    ldh     [seedz],a
    ld      a,51
    ldh     [seedw],a

    ret

;-------------------------------------------------------------------------------

gen_map_rand:: ; returns a = random number

    ; char t = _x ^ (_x << 3);

    ldh     a,[seedx]
    ld      b,a
    rla
    rla
    rla
    and     a,$F8 ; x << 3
    xor     a,b
    ld      c,a ; c = t

    ; _x = _y;

    ldh     a,[seedy]
    ldh     [seedx],a

    ; _y = _z;

    ldh     a,[seedz]
    ldh     [seedy],a

    ; _z = _w;

    ldh     a,[seedw]
    ldh     [seedz],a

    ; _w = _w ^ (_w >> 5) ^ (t ^ (t >> 2));

    ld      a,c ; c = t
    rra
    rra
    and     a,$3F ; t >> 2
    xor     a,c ; t ^ (t >> 2))
    ld      c,a ; save it

    ldh     a,[seedw]
    ld      b,a
    swap    a
    rra
    and     a,$7 ; _w >> 5
    xor     a,b ; _w ^ (_w >> 5)

    xor     a,c
    ldh     [seedw],a

    ; return _w;

    ret

;###############################################################################
