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
    INCLUDE "room_text_input.inc"

;###############################################################################

    SECTION "Room Text Input Variables",WRAM0

text_prompt_string: DS TEXT_PROMPT_STRING_LENGTH
text_input_buffer:: DS (TEXT_INPUT_LENGTH+1) ; Add 1 for the null terminator

    DEF TEXT_CURSOR_BLINK_FRAMES EQU 30
text_cursor_x:      DS 1 ; keyboard cursor coordinates
text_cursor_y:      DS 1
text_cursor_blink:  DS 1
text_cursor_frames: DS 1 ; number of frames left before switching blink status

text_input_ptr:     DS 1 ; pointer to the current char to be modified

text_input_exit:    DS 1 ; set to 1 to exit

;###############################################################################

    SECTION "Room Text Input Data",ROMX

;-------------------------------------------------------------------------------

TEXT_INPUT_BG_MAP::
    INCBIN  "text_input_bg_map.bin"

;-------------------------------------------------------------------------------

    DEF TEXT_KEYBOARD_ROWS    EQU 6
    DEF TEXT_KEYBOARD_COLUMNS EQU 18

TEXT_KEYBOARD_POSITION_INFO: ; Rows padded to 32 bytes
    DB 1,1,1,1, 1,1,1,1, 0,0, 1,1,1,1, 1,1,1,1,  0,0,0,0,0,0,0,0,0,0,0,0,0,0

    DB 1,1,1,1, 1,1,1,1, 0,0, 1,1,1,1, 1,1,1,1,  0,0,0,0,0,0,0,0,0,0,0,0,0,0

    DB 1,1,1,1, 1,1,1,1, 0,0, 1,1,1,1, 1,1,1,1,  0,0,0,0,0,0,0,0,0,0,0,0,0,0

    DB 1,1,0,0, 0,0,0,0, 0,0, 1,1,0,0, 0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0

    DB 1,1,1,1, 1,1,1,1, 0,0, 1,1,0,0, 1,1,1,1,  0,0,0,0,0,0,0,0,0,0,0,0,0,0

    DB 2,2,2,2, 2,0,0,0, 0,0, 0,0,0,0, 0,3,3,3,  0,0,0,0,0,0,0,0,0,0,0,0,0,0

;-------------------------------------------------------------------------------

TextInputResetCursorBlink:

    ld      a,TEXT_CURSOR_BLINK_FRAMES
    ld      [text_cursor_frames],a
    ld      a,1
    ld      [text_cursor_blink],a

    jp      TextInputDrawKeyboardCursor ; call and return from there

;-------------------------------------------------------------------------------

; Gets the current value for the cursor from TEXT_KEYBOARD_POSITION_INFO
TextInputGetInfo:

    ld      a,[text_cursor_y]
    swap    a
    add     a,a ; Y << 5
    ld      b,a

    ld      a,[text_cursor_x]
    or      a,b ; Y << 5 | X

    ld      hl,TEXT_KEYBOARD_POSITION_INFO
    add     a,l
    ld      l,a
    ld      a,0
    adc     a,h
    ld      h,a
    ld      a,[hl] ; a = hl[a]

    ret

;-------------------------------------------------------------------------------

TextInputMoveRight:

    ld      a,[text_cursor_x]
    inc     a
    cp      a,TEXT_KEYBOARD_COLUMNS
    jr      nz,.dont_wrap
    xor     a,a
.dont_wrap:
    ld      [text_cursor_x],a

    call    TextInputGetInfo
    and     a,a
    jr      z,TextInputMoveRight
    ; if empty, repeat until a valid position is found

    jp      TextInputResetCursorBlink ; call and ret from there

;-------------------------------------------------------------------------------

TextInputMoveLeft:

    ld      a,[text_cursor_x]
    dec     a
    cp      a,-1
    jr      nz,.dont_wrap
    ld      a,TEXT_KEYBOARD_COLUMNS-1
.dont_wrap:
    ld      [text_cursor_x],a

    call    TextInputGetInfo
    and     a,a
    jr      z,TextInputMoveLeft
    ; if empty, repeat until a valid position is found

    jp      TextInputResetCursorBlink ; call and ret from there

;-------------------------------------------------------------------------------

TextInputMoveDown:

    ld      a,[text_cursor_y]
    inc     a
    cp      a,TEXT_KEYBOARD_ROWS
    jr      nz,.dont_wrap
    xor     a,a
.dont_wrap:
    ld      [text_cursor_y],a

    call    TextInputGetInfo
    and     a,a
    jr      z,TextInputMoveDown
    ; if empty, repeat until a valid position is found

    jp      TextInputResetCursorBlink ; call and ret from there

;-------------------------------------------------------------------------------

TextInputMoveUp:

    ld      a,[text_cursor_y]
    dec     a
    cp      a,-1
    jr      nz,.dont_wrap
    ld      a,TEXT_KEYBOARD_ROWS-1
.dont_wrap:
    ld      [text_cursor_y],a

    call    TextInputGetInfo
    and     a,a
    jr      z,TextInputMoveUp
    ; if empty, repeat until a valid position is found

    jp      TextInputResetCursorBlink ; call and ret from there

;-------------------------------------------------------------------------------

TextInputGetMapPointer: ; returns hl = pointer to VRAM to selected tile

    ; ptr = base + (y*2)*32 + x

    ld      a,[text_cursor_y]
    swap    a ; Y << 6
    ld      l,a
    ld      h,0
    add     hl,hl
    add     hl,hl ; hl = y * 2 * 32

    ld      a,[text_cursor_x]
    or      a,l ; Y << 6 | X
    ld      l,a

    ld      de,$9800+32*6+1 ; VRAM map for coordinates (1, 6)
    add     hl,de

    ret

;-------------------------------------------------------------------------------

TextInputDrawKeyboardCursor:

    call    TextInputGetMapPointer
    ld      de,32
    add     hl,de ; next row

    di ; critical section

        xor     a,a
        ldh     [rVBK],a

        WAIT_SCREEN_BLANK ; Clobbers registers A and C

        ld      [hl],O_UNDERSCORE

        ld      a,1
        ldh     [rVBK],a

        set     6,[hl] ; Y flip

    reti ; end of critical section and return

;-------------------------------------------------------------------------------

TextInputClearKeyboardCursor:

    call    TextInputGetMapPointer
    ld      de,32
    add     hl,de ; next row

    di ; critical section

        xor     a,a
        ldh     [rVBK],a

        WAIT_SCREEN_BLANK ; Clobbers registers A and C

        ld      [hl],O_SPACE

    reti ; end of critical section and return

;-------------------------------------------------------------------------------

TextInputGetSelectedChar: ; returns A = selected char (-1 = End)

    call    TextInputGetInfo

    cp      a,3
    jr      nz,.not_end
        ld      a,-1
        ret
.not_end:

    cp      a,2
    jr      nz,.not_space
        ld      a,O_SPACE
        ret
.not_space:

    call    TextInputGetMapPointer

    di ; critical section

        xor     a,a
        ldh     [rVBK],a

        WAIT_SCREEN_BLANK ; Clobbers registers A and C

        ld      a,[hl]

    reti ; end of critical section and return

;-------------------------------------------------------------------------------

InputHandleTextInputMenu:

    ld      a,[joy_pressed]
    and     a,PAD_START
    jr      z,.not_start
        ld      a,[text_input_ptr]
        and     a,a
        jr      z,.not_start ; if text lenght is 0, don't allow to end
            ld      a,1
            ld      [text_input_exit],a
            ret
.not_start:

    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      z,.not_a
        call    TextInputGetSelectedChar ; returns A = selected char (-1 = End)
        cp      a,-1
        jr      nz,.dont_end
            ld      a,[text_input_ptr]
            and     a,a
            jr      z,.not_a ; if text lenght is 0, don't allow to end
                ld      a,1
                ld      [text_input_exit],a
                ret
.dont_end:
        ; A = char to draw
        call    TextPutChar
        ret
.not_a:

    ld      a,[joy_pressed]
    and     a,PAD_B
    jr      z,.not_b
        ld      a,[text_input_ptr]
        and     a,a
        jr      nz,.not_empty
            ld      a,1 ; if empty, exit
            ld      [text_input_exit],a
            ret
.not_empty:
        call    TextClearChar
        ret
.not_b:

    ; If the user pressed A, B or START this point won't be reached

    ld      a,[joy_pressed]
    and     a,PAD_LEFT
    jr      z,.not_left
        call    TextInputClearKeyboardCursor
        call    TextInputMoveLeft
        call    TextInputDrawKeyboardCursor
        jr      .end_left_right
.not_left:
    ld      a,[joy_pressed]
    and     a,PAD_RIGHT
    jr      z,.end_left_right
        call    TextInputClearKeyboardCursor
        call    TextInputMoveRight
        call    TextInputDrawKeyboardCursor
.end_left_right:

    ld      a,[joy_pressed]
    and     a,PAD_UP
    jr      z,.not_up
        call    TextInputClearKeyboardCursor
        call    TextInputMoveUp
        call    TextInputDrawKeyboardCursor
        jr      .end_up_down
.not_up:
    ld      a,[joy_pressed]
    and     a,PAD_DOWN
    jr      z,.end_up_down
        call    TextInputClearKeyboardCursor
        call    TextInputMoveDown
        call    TextInputDrawKeyboardCursor
.end_up_down:

    ret

;-------------------------------------------------------------------------------

TextInputCursorsBlinkHandle:

    ld      hl,text_cursor_frames
    dec     [hl]
    jr      nz,.end_cursor_blink

        ld      [hl],TEXT_CURSOR_BLINK_FRAMES

        ld      hl,text_cursor_blink
        ld      a,1
        xor     a,[hl]
        ld      [hl],a

        and     a,a
        jr      z,.cleared_cursor
            call    TextInputDrawKeyboardCursor
            jr      .end_cursor_blink
.cleared_cursor:
            call    TextInputClearKeyboardCursor
            jr      .end_cursor_blink

.end_cursor_blink:

    ret

;-------------------------------------------------------------------------------

TextInputMenuHandle:

    call    InputHandleTextInputMenu

    call    TextInputCursorsBlinkHandle

    ret

;-------------------------------------------------------------------------------

TextClearChar:

    ld      a,[text_input_ptr]
    and     a,a
    ret     z ; nothing writen!

    dec     a
    ld      [text_input_ptr],a ; save decreased value and use it

    ld      d,0
    ld      e,a
    ; DE = index inside str array
    ; B = char to draw

    ld      hl,text_input_buffer
    add     hl,de
    ld      [hl],0 ; write string terminator

    ld      hl,$9800+32*3+9 ; VRAM map for coordinates (9, 3)
    add     hl,de

    di ; critical section

        xor     a,a
        ldh     [rVBK],a

        WAIT_SCREEN_BLANK ; Clobbers registers A and C

        ld      [hl],O_UNDERSCORE ; No character = underscore

    reti ; end of critical section and return

;-------------------------------------------------------------------------------

TextPutChar: ; A = char to draw

    ld      b,a ; preserve char

    ld      a,[text_input_ptr]
    cp      a,TEXT_INPUT_LENGTH
    ret     z ; max lenght!

    push    af
    call    TextInputResetCursorBlink
    pop     af

    ld      d,0
    ld      e,a
    ; DE = index inside str array
    ; B = char to draw

    inc     a
    ld      [text_input_ptr],a ; save increased value of index, use original!

    ld      hl,text_input_buffer
    add     hl,de
    ld      [hl],b

    ld      hl,$9800+32*3+9 ; VRAM map for coordinates (9, 3)
    add     hl,de

    di ; critical section

        xor     a,a
        ldh     [rVBK],a

        WAIT_SCREEN_BLANK ; Clobbers registers A and C

        ld      [hl],b

    reti ; end of critical section and return

;-------------------------------------------------------------------------------

RoomTextInput:: ; returns a = 0 if empty, not 0 if valid text

    xor     a,a
    ld      [text_input_exit],a

    ld      [text_input_ptr],a

    ld      [text_cursor_x],a
    ld      [text_cursor_y],a
    ld      [text_cursor_blink],a

    ld      a,TEXT_CURSOR_BLINK_FRAMES
    ld      [text_cursor_frames],a

    ld      d,0
    ld      hl,text_input_buffer
    ld      bc,TEXT_INPUT_LENGTH+1
    call    memset ; d = value    hl = start address    bc = size

    call    SetPalettesAllBlack

    call    SetDefaultVBLHandler

    call    RoomTextInputLoadBG

    LONG_CALL   TextInputDrawKeyboardCursor

    ld      b,0 ; bank at 8000h
    call    LoadText

    di ; Entering critical section

    ld      b,144
    call    wait_ly

    xor     a,a
    ldh     [rIF],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8000|LCDCF_ON
    ldh     [rLCDC],a

    call    LoadTextPalette

    ei ; End of critical section

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    LONG_CALL   TextInputMenuHandle

    ld      a,[text_input_exit]
    and     a,a
    jr      z,.loop

    call    WaitReleasedAllKeys

    call    SetPalettesAllBlack

    ld      a,[text_input_ptr] ; return 0 if empty, not 0 if valid text
    ret

;-------------------------------------------------------------------------------

RoomTextInputSetPrompt:: ; de = pointer to string

    ; Clear current string

    push    de

    ld      d,O_SPACE
    ld      bc,TEXT_PROMPT_STRING_LENGTH
    ld      hl,text_prompt_string
    call    memset

    pop     de

    ; Copy string

    ld      b,TEXT_PROMPT_STRING_LENGTH
    ld      hl,text_prompt_string

.loop:
    ld      a,[de]
    and     a,a
    ret     z ; return if 0 terminator

    ld      [hl+],a
    inc     de

    dec     b
    jr      nz,.loop

    ret

;###############################################################################

    SECTION "Room Text Input Code Data",ROM0

;-------------------------------------------------------------------------------

RoomTextInputLoadBG:

    ; Reset scroll
    ; ------------

    xor     a,a
    ldh     [rSCX],a
    ldh     [rSCY],a

    ; Load graphics
    ; -------------

    ld      b,BANK(TEXT_INPUT_BG_MAP)
    call    rom_bank_push_set

    ; Tiles

    xor     a,a
    ldh     [rVBK],a

    ld      de,$9800
    ld      hl,TEXT_INPUT_BG_MAP

    ld      a,18
.loop1:
    push    af

    ld      b,20
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    push    hl
    ld      hl,32-20
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl

    pop     af
    dec     a
    jr      nz,.loop1

    ; Load title

    push    hl ; preserve source pointer from previous copy

        ld      b,TEXT_PROMPT_STRING_LENGTH
        ld      de,$9800+32*1+1
        ld      hl,text_prompt_string
        call    vram_copy_fast ; b = size - hl = source address - de = dest

    pop     hl

    ; Attributes

    ld      a,1
    ldh     [rVBK],a

    ld      de,$9800

    ld      a,18
.loop2:
    push    af

    ld      b,20
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    push    hl
    ld      hl,32-20
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl

    pop     af
    dec     a
    jr      nz,.loop2

    call    rom_bank_pop

    ret

;###############################################################################
