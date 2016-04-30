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

    IF !DEF(ENGINE_INC)
ENGINE_INC SET 1

;###############################################################################
;#                                                                             #
;#                                   MACROS                                    #
;#                                                                             #
;###############################################################################

DMA_COPY : MACRO ; src, dst, size, is_hdma
    ld      a, ( \1 >> 8 )& $FF
    ld      [rHDMA1],a
    ld      a, \1 & $F0 ; Lower 4 bits ignored
    ld      [rHDMA2],a

    ld      a, ( \2 >> 8 )& $1F ; Upper 3 bits ignored
    ld      [rHDMA3],a
    ld      a, \2 & $F0 ; Lower 4 bits ignored
    ld      [rHDMA4],a

    ld      a, ( ( ( \3 >> 4 ) - 1 ) | ( \4 << 7 ) ) ; ( Size / $10 ) - 1
    ld      [rHDMA5],a
ENDM

;-------------------------------------------------------------------------------

LONG_CALL : MACRO ; function to call
    ld      b,BANK(\1)
    ld      hl,\1
    call    ___long_call
ENDM

LONG_CALL_ARGS : MACRO ; function to call. Slower than LONG_CALL
    ld      a,BANK(\1)
    ld      hl,\1
    ; It can use bc and de for passing arguments
    ; Returned values in any register are preserved through this call
    call    ___long_call_args
ENDM

CALL_HL : MACRO ; Calls hl through rst 8 vector (which has a 'jp hl')
    rst     $08
ENDM

;-------------------------------------------------------------------------------

WAIT_SCREEN_BLANK : MACRO ; Clobbers registers A and C
    ld      c,rSTAT & $FF
.loop\@:
    ld      a,[$FF00+c]
    bit     1,a
    jr      nz,.loop\@ ; Not mode 0 or 1
ENDM

;-------------------------------------------------------------------------------

LD_DE_HL : MACRO ; de = hl
    ld      d,h
    ld      e,l
ENDM

LD_BC_HL : MACRO ; bc = hl
    ld      b,h
    ld      c,l
ENDM

LD_HL_DE : MACRO ; hl = de
    ld      h,d
    ld      l,e
ENDM

LD_HL_BC : MACRO ; hl = bc
    ld      h,b
    ld      l,c
ENDM

LD_DE_BC : MACRO ; de = bc
    ld      d,b
    ld      e,c
ENDM

LD_BC_DE : MACRO ; bc = de
    ld      b,d
    ld      c,e
ENDM

;###############################################################################
;#                                                                             #
;#                                  LUTS.ASM                                   #
;#                                                                             #
;###############################################################################

Sine    EQU $3E00 ; Aligned to $100 to improve speed when
Cosine  EQU $3F00 ; reading from them. :)

;-------------------------------------------------------------------------------
;- GetRandom()    a = returned value    hl is destroyed                        -
;- SetRandomSeed()    a = new seed                                             -
;-------------------------------------------------------------------------------

    GLOBAL  GetRandom
    GLOBAL  SetRandomSeed

;###############################################################################
;#                                                                             #
;#                                  INIT.ASM                                   #
;#                                                                             #
;###############################################################################

;-------------------------------------------------------------------------------
;- irq_set_VBL()    bc = function pointer                                      -
;- irq_set_LCD()    bc = function pointer                                      -
;- irq_set_TIM()    bc = function pointer                                      -
;- irq_set_SIO()    bc = function pointer                                      -
;- irq_set_JOY()    bc = function pointer                                      -
;-------------------------------------------------------------------------------

    GLOBAL  irq_set_VBL
    GLOBAL  irq_set_LCD
    GLOBAL  irq_set_TIM
    GLOBAL  irq_set_SIO
    GLOBAL  irq_set_JOY

;-------------------------------------------------------------------------------
;- CPU_fast()                                                                  -
;- CPU_slow()                                                                  -
;-------------------------------------------------------------------------------

    GLOBAL  CPU_fast
    GLOBAL  CPU_slow

;-------------------------------------------------------------------------------
;- wait_vbl()                                                                  -
;-------------------------------------------------------------------------------

    GLOBAL  wait_vbl

;-------------------------------------------------------------------------------
;- Reset()                                                                     -
;-------------------------------------------------------------------------------

    GLOBAL  Reset

;===============================================================================
;=                                  VARIABLES                                  =
;===============================================================================

    GLOBAL  Init_Reg_A
    GLOBAL  Init_Reg_B

    GLOBAL  VBL_handler
    GLOBAL  LCD_handler
    GLOBAL  TIM_handler
    GLOBAL  SIO_handler
    GLOBAL  JOY_handler

;###############################################################################
;#                                                                             #
;#                                  MAIN.ASM                                   #
;#                                                                             #
;###############################################################################

;-------------------------------------------------------------------------------
;- Main()                                                                      -
;-------------------------------------------------------------------------------

    GLOBAL  Main

;###############################################################################
;#                                                                             #
;#                                UTILITIES.ASM                                #
;#                                                                             #
;###############################################################################

;-------------------------------------------------------------------------------
;- mul_u8u8u16()    hl = returned value    a,c = initial values                -
;- div_u8u8u8()    c = a / b     a = a % b                                     -
;- div_s8s8s8()    a / b -> c     a % b -> a     destroys e                    -
;-------------------------------------------------------------------------------

    GLOBAL  mul_u8u8u16
    GLOBAL  div_u8u8u8
    GLOBAL  div_s8s8s8

;-------------------------------------------------------------------------------
;- memset()    d = value    hl = start address    bc = size                    -
;- memset_fast()    a = value    hl = start address    b = size                -
;- memset_rand()    hl = start address    bc = size                            -
;- memcopy()    bc = size    hl = source address    de = dest address          -
;- memcopy_inc()    b = size    c = increase    hl = source    de = dest       -
;-------------------------------------------------------------------------------

    GLOBAL  memset
    GLOBAL  memset_fast
    GLOBAL  memset_rand
    GLOBAL  memcopy
    GLOBAL  memcopy_inc

;-------------------------------------------------------------------------------
;- scan_keys()                                                                 -
;-------------------------------------------------------------------------------

    GLOBAL  scan_keys

;===============================================================================
;=                                  VARIABLES                                  =
;===============================================================================

    GLOBAL  joy_held ; Holds current held keys
    GLOBAL  joy_pressed ; Holds keys that have been pressed this frame
    GLOBAL  joy_released ; Keys released this frame

;===============================================================================
;=                                 DEFINITIONS                                 =
;===============================================================================

PAD_START   EQU $80
PAD_SELECT  EQU $40
PAD_B       EQU $20
PAD_A       EQU $10
PAD_DOWN    EQU $08
PAD_UP      EQU $04
PAD_LEFT    EQU $02
PAD_RIGHT   EQU $01

PAD_BIT_START   EQU 7
PAD_BIT_SELECT  EQU 6
PAD_BIT_B       EQU 5
PAD_BIT_A       EQU 4
PAD_BIT_DOWN    EQU 3
PAD_BIT_UP      EQU 2
PAD_BIT_LEFT    EQU 1
PAD_BIT_RIGHT   EQU 0

;-------------------------------------------------------------------------------
;- rom_handler_init()                                                          -
;- rom_bank_pop()                                                              -
;- rom_bank_push()                                                             -
;- rom_bank_set()    b = bank to change to                                     -
;- rom_bank_push_set()    b = bank to change to                                -
;-                                                                             -
;- ___long_call()    hl = function    b = bank where it is located             -
;-------------------------------------------------------------------------------

    GLOBAL  rom_handler_init
    GLOBAL  rom_bank_pop
    GLOBAL  rom_bank_push
    GLOBAL  rom_bank_set
    GLOBAL  rom_bank_push_set
    GLOBAL  ___long_call

;###############################################################################
;#                                                                             #
;#                                  VIDEO.ASM                                  #
;#                                                                             #
;###############################################################################

;-------------------------------------------------------------------------------
;- wait_ly()    b = ly to wait for                                             -
;- wait_frames()    e = frames to wait                                         -
;- screen_off()                                                                -
;-------------------------------------------------------------------------------

    GLOBAL  wait_ly
    GLOBAL  wait_frames
    GLOBAL  screen_off

;-------------------------------------------------------------------------------
;- vram_copy()    bc = size    hl = source address    de = dest address        -
;- vram_copy_fast()    b = size    hl = source address    de = dest address    -
;- vram_nitro_copy()    b = size    de = source address    hl = dest address   -
;- vram_memset()    bc = size    d = value    hl = dest address                -
;- vram_copy_tiles()    bc = tiles    de = start index    hl = source          -
;-------------------------------------------------------------------------------

    GLOBAL  vram_copy
    GLOBAL  vram_copy_fast
    GLOBAL  vram_nitro_copy ; use only for data != $FF
    GLOBAL  vram_memset
    GLOBAL  vram_copy_tiles

;-------------------------------------------------------------------------------
;- init_OAM()                                                                  -
;- refresh_OAM()                                                               -
;- refresh_custom_OAM()    a = (oam copy >> 8), aligned to 100h                -
;-                                                                             -
;- sprite_get_base_pointer()    l = sprite    return = hl    destroys de       -
;-                                                                             -
;- sprite_set_xy()    b = x    c = y    l = sprite number                      -
;- sprite_set_tile()    a = tile    l = sprite number                          -
;- sprite_set_params()    a = params    l = sprite number                      -
;-                                                                             -
;- spr_set_palette()    a = palette number    hl = pointer to data             -
;- spr_set_palette_safe()    a = palette number    hl = pointer to data        -
;-------------------------------------------------------------------------------

    GLOBAL  init_OAM
    GLOBAL  refresh_OAM
    GLOBAL  refresh_custom_OAM
    GLOBAL  sprite_get_base_pointer
    GLOBAL  sprite_set_xy
    GLOBAL  sprite_set_tile
    GLOBAL  sprite_set_params
    GLOBAL  spr_set_palette
    GLOBAL  spr_set_palette_safe

;===============================================================================
;=                                  VARIABLES                                  =
;===============================================================================

    GLOBAL  OAM_Copy ; Pointer to the copy in RAM of the OAM

;-------------------------------------------------------------------------------
;- bg_set_tile()    b = x    c = y    a = tile index                           -
;- bg_set_tile_wrap()    b = x    c = y    a = tile index                      -
;-                                                                             -
;- bg_set_palette()    a = palette number    hl = pointer to data              -
;- bg_set_palette_safe()    a = palette number    hl = pointer to data         -
;-------------------------------------------------------------------------------

    GLOBAL  bg_set_tile
    GLOBAL  bg_set_tile_wrap
    GLOBAL  bg_set_palette
    GLOBAL  bg_set_palette_safe

;###############################################################################

    ENDC ; ENGINE_INC

;###############################################################################
