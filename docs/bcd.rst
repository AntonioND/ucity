========
BCD Math
========

Most big numbers in the game are stored in BCD format. Examples of this are
money amounts or city populations. The reason for doing it this way is that it
simplifies the display of the values on the screen for the player to see. As
most of the operations that are done on huge numbers are really simple, this
format doesn't cause a big loss in performance over plain binary.

The code is located in ``source/bcd_math.asm``.

BCD numbers are 5 bytes wide, LSB stored first. Inside a byte, the lower nibble
is the least significative digit of the two. They can be interpreted as signed
or unsigned values.

For example, the unsigned decimal value ``123456789`` would be stored in memory
like this:

    ``DB $89,$67,$45,$23,$01``

Signed values are stored in tens' complement format, similar to the two's
complement format used for regular values:

                +--------------+-------------+
                | -50000000000 | $5000000000 |
                +--------------+-------------+
                | -49999999999 | $5000000001 |
                +--------------+-------------+
                | -49999999998 | $5000000002 |
                +--------------+-------------+
                |      ...     |     ...     |
                +--------------+-------------+
                |  -9999999999 | $9000000001 |
                +--------------+-------------+
                |      ...     |     ...     |
                +--------------+-------------+
                |           -2 | $9999999998 |
                +--------------+-------------+
                |           -1 | $9999999999 |
                +--------------+-------------+
                |            0 | $0000000000 |
                +--------------+-------------+
                |           +1 | $0000000001 |
                +--------------+-------------+
                |           +2 | $0000000002 |
                +--------------+-------------+
                |      ...     |     ...     |
                +--------------+-------------+
                |  +9999999999 | $0999999999 |
                +--------------+-------------+
                |      ...     |     ...     |
                +--------------+-------------+
                | +49999999998 | $4999999998 |
                +--------------+-------------+
                | +49999999999 | $4999999999 |
                +--------------+-------------+

However, in game, numbers saturate at +/-0999999999. This is done to make sure
that the number always fits in a string with 10 bytes allocated, including the
minus sign for negative numbers.

The current library implements a few common operations to make it easier to use
this kind of format. There are helpers for simple operations like addition,
subtraction and sign change. There are also two helpers to compare numbers. One
of them tests if a number is lower than zero, the other one tests if one of them
is greater or equal than the other one. There's also a helper to multiply a BCD
number by a 8-bit non-BCD value (it just adds the same value repeatidly).

Addition of signed numbers works the same way as two's complement and it is as
simple as addition of unsigned numbers. Note that, since the numbers are stored
in BCD, after every addition or subtraction instruction (``add``, ``adc``,
``sub``, ``sbc``) it is needed to add a ``daa`` instruction.

                +---------------+-----------------+
                | 5 + (-7) = -2 | $05 + $93 = $98 |
                +---------------+-----------------+
                |   -2 + 2 = 0  | $98 + $02 = $00 |
                +---------------+-----------------+

Of course, it is needed to convert from this format to something that can be
represented on the screen. There are 3 helpers to achieve this. All of them read
the original 5-byte value and output a 10-byte character string. One of them
prints an unsigned value including leading zeros, other prints them as spaces
(except if there is only one zero to be printed!). The last helper prints a
signed number including the minus sign if needed.

There's also a LUT that can be used to convert an 8-bit value into BCD, useful
to convert small binary values to BCD before operating on them.
