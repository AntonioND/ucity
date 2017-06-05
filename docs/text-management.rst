===============
Text Management
===============

Even though the game doesn't do any special manipulation of text, storing text
and handling it correctly requires a bit of care. The relevant code is located
in:

- ``source/text.asm`` : Text font tileset, palette and functions to load them.
  The font can be loaded at the end of both tile banks (starting at ``0x8000``
  or at ``0x8800``). The tiles use palette index 7.

- ``source/text.inc`` : Utilities to create strings. Instead of saving them in
  ASCII format, they are converted to tiles so that the game doesn't have to do
  the conversion at runtime.

- ``source/room_game/tileset_text.asm`` : Strings to describe each type of
  terrain (field, road, etc) and function to write it to a buffer.

- ``source/room_game/text_messages.asm`` : Message definitions and functions to
  handle the message queue (requests, peeks, etc).

- ``source/room_game/text_messages.inc`` : Message IDs. Space needed to store
  the status of persistent messages.

- ``source/room_game/persistent_messages.asm`` : Functions to handle persistent
  messages and yearly messages.

- ``source/room_game/message_box.asm`` : Functions to handle the message box
  shown in the room game.

Message queue
=============

In order to handle multiple messages happening at the same time there is a
message queue that holds a number of unique (non-repeated) message IDs (exactly
``MSG_QUEUE_DEPTH`` messages). They are added to the queue with the function
``MessageRequestAdd``, and they are shown in the same order they are added. All
messages are predefined.

There is a special message ID, ``ID_MSG_CUSTOM``. This message can be modified
at runtime, but it must be requested with ``MessageRequestAddCustom``.

Note that only one instance of each ID can be in the queue at any point in time.
More requests to show the same message will be ignored.

Persistent messages
===================

Persistent messages are messages that can only be shown once per game (or once
per in-game year). They are shown with ``PersistentMessageShow``. Examples of
this kind of messages are the ones that tell the player that the city has grown
and gained a new title.

Yearly messages are treated the same way, except for the fact that the function
``PersistentYearlyMessagesReset`` resets their state at the end of each year so
that they can be shown again. This way they aren't too annoying for the player.
Examples of messages of this kind are the ones that notify the player that the
city has run out of money.

The state of both kinds of persistent messages is stored in the saved data of
the city. To make it easier, the message IDs of persistent and yearly messages
are the first ones. Only one bit is needed to know the state of each message, so
they are packed in bytes. The number of bytes needed to save them all is
``BYTES_SAVE_PERSISTENT_MSG``.
