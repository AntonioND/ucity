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

;-------------------------------------------------------------------------------

    INCLUDE "text.inc"

;###############################################################################

    SECTION "Text Data",ROMX

;-------------------------------------------------------------------------------

TextTilesData:
.s:
    INCBIN "data/text_tiles.bin"
.e:

TextTilesNumber EQU (.e - .s) / (8*8/4)
TEXT_BASE_TILE  EQU (128-TextTilesNumber)

;###############################################################################

    SECTION "Text Functions",ROM0

;-------------------------------------------------------------------------------

TEXT_PALETTE:: ; To be loaded in slot 7
    DW (31<<10)|(31<<5)|(31<<0), (21<<10)|(21<<5)|(21<<0)
    DW (10<<10)|(10<<5)|(10<<0), (0<<10)|(0<<5)|(0<<0)

LoadTextPalette:: ; Load text palette into slot 7. Do this during VBL!

    ld      a,7
    ld      hl,TEXT_PALETTE
    call    bg_set_palette

    ret

LoadText::

    xor     a,a
    ld      [rVBK],a

    ld      b,BANK(TextTilesData)
    call    rom_bank_push_set

    ld      bc,TextTilesNumber
    ld      de,TEXT_BASE_TILE ; Bank at 8800h
    ld      hl,TextTilesData
    call    vram_copy_tiles

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

credits_ascii_to_tiles_table:

    ;   .--Space is here!
    ;   v
    ; ##  ! " # $ % & ' ( ) * + , - . / 0 1 2 3 4 5 6 7 8 9 : ; < = > ?##
    ; ##@ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z [ \ ] ^ _##
    ; ##` a b c d e f g h i j k l m n o p q r s t u v w x y z { | } ~  ##

    ;   ' '     !             "      #       $      %           &      '            (      )
    DB O_SPACE,O_EXCLAMATION,O_NONE,O_ARROW,O_NONE,O_COPYRIGHT,O_NONE,O_APOSTROPHE,O_NONE,O_NONE
    ;   *      +      ,       -      .     /
    DB O_NONE,O_NONE,O_COMMA,O_NONE,O_DOT,O_BAR
    ;   0 1 2 3 4 5 6 7 8 9
CHARACTER SET 0
    REPT 10
        DB O_ZERO+CHARACTER
CHARACTER SET CHARACTER+1
    ENDR
    ;   :          ;      <      =      >      ?          @
    DB O_COLON,O_NONE,O_NONE,O_NONE,O_NONE,O_QUESTION,O_AT
    ;   A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
CHARACTER SET 0
    REPT 26
        DB O_A_UPPERCASE+CHARACTER
CHARACTER SET CHARACTER+1
    ENDR
    ;   [      \      ]      ^      _            `
    DB O_NONE,O_NONE,O_NONE,O_NONE,O_UNDERSCORE,O_NONE
    ; a b c d e f g h i j k l m n o p q r s t u v w x y z
CHARACTER SET 0
    REPT 26
        DB O_A_LOWERCASE+CHARACTER
CHARACTER SET CHARACTER+1
    ENDR
    ;   {      |      }      ~
    DB O_NONE,O_NONE,O_NONE,O_NTILDE

;-------------------------------------------------------------------------------

ASCII2Tile:: ; a = ascii code. Returns tile number in a. Destroys de and hl

    sub     a,32 ; Non-printing characters
    ld      hl,credits_ascii_to_tiles_table
    ld      d,0
    ld      e,a
    add     hl,de
    ld      a,[hl]

    ret

;###############################################################################
