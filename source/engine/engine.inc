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

    IF !DEF(ENGINE_INC)
    DEF ENGINE_INC = 1

;###############################################################################
;#                                                                             #
;#                                   MACROS                                    #
;#                                                                             #
;###############################################################################

MACRO DMA_COPY ; src, dst, size, is_hdma
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

MACRO LONG_CALL ; function to call
    ld      b,BANK(\1)
    ld      hl,\1
    call    ___long_call
ENDM

MACRO LONG_CALL_ARGS ; function to call. Slower than LONG_CALL
    ld      a,BANK(\1)
    ld      hl,\1
    ; It can use BC and DE for passing arguments
    ; Returned values in any register are preserved through this call
    call    ___long_call_args
ENDM

MACRO CALL_HL ; Calls hl through rst 8 vector (which has a 'jp hl')
    rst     $08
ENDM

;-------------------------------------------------------------------------------

MACRO WAIT_SCREEN_BLANK ; Clobbers registers A and C
    ld      c,rSTAT & $FF
.loop\@:
    ld      a,[$FF00+c]
    bit     1,a
    jr      nz,.loop\@ ; Not mode 0 or 1
ENDM

;-------------------------------------------------------------------------------

MACRO LD_DE_HL ; de = hl
    ld      d,h
    ld      e,l
ENDM

MACRO LD_BC_HL ; bc = hl
    ld      b,h
    ld      c,l
ENDM

MACRO LD_HL_DE ; hl = de
    ld      h,d
    ld      l,e
ENDM

MACRO LD_HL_BC ; hl = bc
    ld      h,b
    ld      l,c
ENDM

MACRO LD_DE_BC ; de = bc
    ld      d,b
    ld      e,c
ENDM

MACRO LD_BC_DE ; bc = de
    ld      b,d
    ld      c,e
ENDM

;###############################################################################
;#                                                                             #
;#                                  LUTS.ASM                                   #
;#                                                                             #
;###############################################################################

;-------------------------------------------------------------------------------
;- GetRandom()    a = returned value    hl is destroyed    bc, de preserved    -
;- SetRandomSeed()    a = new seed                                             -
;-------------------------------------------------------------------------------

    EXPORT  GetRandom
    EXPORT  SetRandomSeed

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

    EXPORT  irq_set_VBL
    EXPORT  irq_set_LCD
    EXPORT  irq_set_TIM
    EXPORT  irq_set_SIO
    EXPORT  irq_set_JOY

;-------------------------------------------------------------------------------
;- CPU_fast()                                                                  -
;- CPU_slow()                                                                  -
;-------------------------------------------------------------------------------

    EXPORT  CPU_fast
    EXPORT  CPU_slow

;-------------------------------------------------------------------------------
;- wait_vbl()                                                                  -
;-------------------------------------------------------------------------------

    EXPORT  wait_vbl

;-------------------------------------------------------------------------------
;- Reset()                                                                     -
;-------------------------------------------------------------------------------

    EXPORT  Reset

;===============================================================================
;=                                  VARIABLES                                  =
;===============================================================================

    EXPORT  Init_Reg_A
    EXPORT  Init_Reg_B

    EXPORT  VBL_handler
    EXPORT  LCD_handler
    EXPORT  TIM_handler
    EXPORT  SIO_handler
    EXPORT  JOY_handler

;###############################################################################
;#                                                                             #
;#                                  MAIN.ASM                                   #
;#                                                                             #
;###############################################################################

;-------------------------------------------------------------------------------
;- Main()                                                                      -
;-------------------------------------------------------------------------------

    EXPORT  Main

;###############################################################################
;#                                                                             #
;#                                UTILITIES.ASM                                #
;#                                                                             #
;###############################################################################

;-------------------------------------------------------------------------------
;- mul_u8u8u16()    hl = result    a,c = initial values    de preserved        -
;- div_u8u8u8()    c = a / b     a = a % b                                     -
;- div_s8s8s8()    a / b -> c     a % b -> a     destroys e                    -
;- div_u16u7u16()     hl / c -> hl     hl % c -> a                             -
;-------------------------------------------------------------------------------

    EXPORT  mul_u8u8u16
    EXPORT  div_u8u8u8
    EXPORT  div_s8s8s8
    EXPORT  div_u16u7u16

;-------------------------------------------------------------------------------
;- memset()    d = value    hl = start address    bc = size                    -
;- memset_fast()    a = value    hl = start address    b = size                -
;- memset_rand()    hl = start address    bc = size                            -
;- memcopy()    bc = size    hl = source address    de = dest address          -
;- memcopy_inc()    b = size    c = increase    hl = source    de = dest       -
;-------------------------------------------------------------------------------

    EXPORT  memset
    EXPORT  memset_fast
    EXPORT  memset_rand
    EXPORT  memcopy
    EXPORT  memcopy_inc

;-------------------------------------------------------------------------------
;- scan_keys()                                                                 -
;-------------------------------------------------------------------------------

    EXPORT  scan_keys

;===============================================================================
;=                                  VARIABLES                                  =
;===============================================================================

    EXPORT  joy_held ; Holds current held keys
    EXPORT  joy_pressed ; Holds keys that have been pressed this frame
    EXPORT  joy_released ; Keys released this frame

;===============================================================================
;=                                 DEFINITIONS                                 =
;===============================================================================

    DEF PAD_START   EQU $80
    DEF PAD_SELECT  EQU $40
    DEF PAD_B       EQU $20
    DEF PAD_A       EQU $10
    DEF PAD_DOWN    EQU $08
    DEF PAD_UP      EQU $04
    DEF PAD_LEFT    EQU $02
    DEF PAD_RIGHT   EQU $01

    DEF PAD_BIT_START   EQU 7
    DEF PAD_BIT_SELECT  EQU 6
    DEF PAD_BIT_B       EQU 5
    DEF PAD_BIT_A       EQU 4
    DEF PAD_BIT_DOWN    EQU 3
    DEF PAD_BIT_UP      EQU 2
    DEF PAD_BIT_LEFT    EQU 1
    DEF PAD_BIT_RIGHT   EQU 0

;-------------------------------------------------------------------------------
;- rom_handler_init()                                                          -
;- rom_bank_pop()                                                              -
;- rom_bank_push()                                                             -
;- rom_bank_set()    b = bank to change to                                     -
;- rom_bank_push_set()    b = bank to change to                                -
;-                                                                             -
;- ___long_call()    hl = function    b = bank where it is located             -
;-------------------------------------------------------------------------------

    EXPORT  rom_handler_init
    EXPORT  rom_bank_pop
    EXPORT  rom_bank_push
    EXPORT  rom_bank_set
    EXPORT  rom_bank_push_set
    EXPORT  ___long_call

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

    EXPORT  wait_ly
    EXPORT  wait_frames
    EXPORT  screen_off

;-------------------------------------------------------------------------------
;- vram_copy()    bc = size    hl = source address    de = dest address        -
;- vram_copy_fast()    b = size    hl = source address    de = dest address    -
;- vram_nitro_copy()    b = size    de = source address    hl = dest address   -
;- vram_memset()    bc = size    d = value    hl = dest address                -
;- vram_copy_tiles()    bc = tiles    de = start index    hl = source          -
;-------------------------------------------------------------------------------

    EXPORT  vram_copy
    EXPORT  vram_copy_fast
    EXPORT  vram_nitro_copy ; use only for data != $FF
    EXPORT  vram_memset
    EXPORT  vram_copy_tiles

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

    EXPORT  init_OAM
    EXPORT  refresh_OAM
    EXPORT  refresh_custom_OAM
    EXPORT  sprite_get_base_pointer
    EXPORT  sprite_set_xy
    EXPORT  sprite_set_tile
    EXPORT  sprite_set_params
    EXPORT  spr_set_palette
    EXPORT  spr_set_palette_safe

;===============================================================================
;=                                  VARIABLES                                  =
;===============================================================================

    EXPORT  OAM_Copy ; Pointer to the copy in RAM of the OAM

;-------------------------------------------------------------------------------
;- bg_set_tile()    b = x    c = y    a = tile index                           -
;- bg_set_tile_wrap()    b = x    c = y    a = tile index                      -
;-                                                                             -
;- bg_set_palette()    a = palette number    hl = pointer to data              -
;- bg_set_palette_safe()    a = palette number    hl = pointer to data         -
;-------------------------------------------------------------------------------

    EXPORT  bg_set_tile
    EXPORT  bg_set_tile_wrap
    EXPORT  bg_set_palette
    EXPORT  bg_set_palette_safe

;###############################################################################

    ENDC ; ENGINE_INC

;###############################################################################
