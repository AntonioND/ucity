==========
Game Rooms
==========

The game is organized in rooms. A room is simply one 'screen' with its own main
loop, keypress handler, etc. The game has the following rooms:

Title room
==========

Nothing special, it just loads a random predefined scenario and displays it
along with the game title.

Code: ``source/room_title/room_title.asm``

GBC only error room
===================

When the game is run in a non-color Game Boy, the game enters this room (which
cannot be left). It shows an error that tells the player to use a Game Boy Color
instead.

Code: ``source/room_gbc_only/room_gbc_only.asm``

Main menu room
==============

This is the main menu, which lets the player create a new city, load a
previously created city or enter the credits room. This room is entered after
the title room is left. The player can return here from the regular game room,
or from the game load and new city rooms.

Code: ``source/room_menu/room_menu.asm``

Credits room
============

It shows the credits. When the room is left the game enters the main menu again.

Code: ``source/room_credits/room_credits.asm``

Scenario load room
==================

This room allows the player to load one of the predefined scenarios.

Code: ``source/room_scenarios/room_scenarios.asm``

Text input room
===============

This room has a virtual keyboard to let the player input text strings. It also
shows a short message to remind what it is supposed to be written. This is only
used to input the name of the randomly generated cities.

Code: ``source/room_text_input/room_text_input.asm``

Random map generation room
==========================

This room lets the player select a random seed to generate a map.

Code: ``source/room_gen_map/room_gen_map.asm``

Load/Save city room
===================

The code of this room is used for both selecting an empty slot to save a city or
to select a filled slot to load it. It shows the appropriate number of slots
according to the size of the SRAM that the cartridge has (or that the emulator
has given the game).

Code: ``source/room_save_menu/room_save_menu.asm``

Game room
=========

This is the room where the game actually happens. The explanation about how the
main loop works is in `this <main-loop.rst>`_ file.

The main code of the room (and main loop of the game) is in
``source/room_game/room_game.asm``. The code used to handle the status bar (and
the pause menu is in ``source/room_game/status_bar_menu.asm``. The code of the
menu that appears when the player has to select a building to be built is in
``source/room_game/build_menu.asm``.

Note that it is possible to go back to the main menu room from here if the
correct option is selected in the pause menu.

Budget room
===========

This room allows the player to select the amount of taxes that are be collected.
It also shows the amount of money that is collected and spent in different
things.

Code: ``source/room_budget/room_budget.asm``

Bank room
=========

This room allows the player to get a loan or shows the status of the current
loan (the player can't get two loans at the same time).

Code: ``source/room_bank/room_bank.asm``

Minimap room
============

This room shows different minimaps with helpful information for the player.

The code of the room is in ``source/room_minimap/room_minimap.asm``. The code of
the menu, in ``source/room_minimap/minimap_menu.asm``.

Graphs room
===========

This room shows different graphs with helpful information for the player.

The code of the room is in ``source/room_graphs/room_graphs.asm``. The code of
the menu, in ``source/room_graphs/graphs_menu.asm``.

City stats room
===============

This room shows some statistics about the city. There are some percentages that
can be a bit confusing:

- The percentage of built land is calculated as the number of tiles with any
  kind of constructions divided by the number of tiles of land.

- The percentages of residential, commercial and industrial are calculated as
  the number of tiles of that zone type with buildings divided by the total
  number of tiles dedicated to that zone type.

- The percentage of high traffic is just the percentage of tiles with high
  traffic divided by the total number of tiles with roads.

Note: There is a secret in this room. If SELECT, UP, LEFT and A are held at the
same time, the funds will be set to ``999999999``.

Code: ``source/room_city_stats/room_city_stats.asm``

Options room
============

Allows the player to do things like disable sound or animations, or to trigger
disasters (fires or nuclear meltdowns).

Code: ``source/room_options/room_options.asm``
