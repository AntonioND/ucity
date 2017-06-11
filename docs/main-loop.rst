=========
Main Loop
=========

Execution of the game starts in ``source/engine/init.asm`` at ``StartPoint``.
There is some hardware initialization code and it eventually jumps to ``Main``
in ``source/main.asm``, which does game initialization.

At the end of ``Main``, ``RoomTitle`` is called. As soon as that room is left,
there is the start of the main loop. It calls ``RoomMenu`` and ``RoomGame`` in a
loop. This is how the game manages to go from the main menu to the game room and
back to the main menu. The main menu room is straightforward, the game room
isn't, and it is explained below. Note that the code of the game room is in
``source/room_game/room_game.asm``.

Game main loop
==============

The game room needs to handle the user interface, animations (if enabled),
update the sprites, music and the simulation of every subsystem (traffic,
electricity, etc). Not all of them have the same priority:

- Animations are critical, as they can make the game feel glitchy if they are
  not completely fluid. Note that, as explained in the documentation of the
  animations (in `this <animated-graphics.rst>`_ file), there are two animation
  routines. Only the VBL handling part is critical. The status bar interrupt
  handler is also critical, as it can create graphical glitches if it isn't
  handled at the correct time.

- Music and SFXs have high priority, the player won't notice a delay of one
  frame in a song (it's 1/60th of a second, after all), but it still needs to be
  handled reliably. The rest of the animation handling is also treated with this
  priority.

- The user interface is also important, but it only has medium priority because
  updating graphics is slow, so the code can't rely on the user interface
  updates being fast enough for the music to be updated reliably.

- The game simulation has low priority. A single simulation step can take
  several seconds to end, so it's something that has to be handled in the
  background.

To be able to treat all of them as needed, there is a main loop that handles the
simulation and a VBL handler that handles everything else.

- The main loop simply executes steps of the simulation unless the user
  interface tells it not do do so (because the player has paused, for example).
  Note that this is also the reason sometimes the user interface complains when
  the player tries to enter any room of the pause menu, or why it can take a few
  seconds to go to the main menu after pressing that option. Also, that's why
  sometimes building/demolishing doesn't work for a few seconds, it's just a
  really, really bad idea to modify the map during the simulation, so the game
  stops you. The red dot that appears on the screen is there for that reason, to
  tell the player when the step has ended.

- The VBL handler is a bit more complicated. First of all, it allows other
  interrupts to interrupt it. Second, it can modify data that is also modified
  by the main loop so it is needed to create critical parts in the code that
  cannot be interrupted (or corruption will appear). The problem is that some
  parts of the VBL handler have higher priority than others.

  The way the handler works is by having a critical section at the beginning.
  This section can't be interrupted by anything. It updates the status bar
  position, the sprites, background scroll, the critical part of the animations,
  music and SFXs. There's a debug check to make sure that the VBL period hasn't
  ended by the time updates are going to be done to the VRAM/OAM (that is,
  animations, music and SFXs are handled after the check). Note that this is
  only for debug purposes. A real player wouldn't see anything happen if the
  test fails (maybe glitches, if the problem is serious). Note that all of this
  must take less than a frame to be completed. If not, the CPU simply has no
  time to do anything else!

  After all of that is handled, interruptions are enabled again. At this point,
  a new VBL could happen and trigger the VBL handler. This nested interrupt
  would be detected, and the handler of the nested interrupt would return here.

  If this isn't a nested interrupt, there is more work to do. It is needed to
  update the user interface. This update may modify the map (if the user builds
  or demolishes something). The player can also move the map around, so it is
  needed to update the position of animated sprites of planes, boats and trains.
  Also, it is needed to handle the non-critical part of the animations. This
  division is the reason why sometimes a train will fail to turn in a curve and
  it will disappear, as explained `here <animated-graphics.rst>`_. If the
  critical part of the animations is handled, but not the non-critical, right in
  the step when a train should turn, it won't turn, and it will leave the train
  tracks, making the train jump to a new random position.

The main loop doesn't always do the same tasks. It can do normal simulation of
traffic, power, services, building growth, etc, but it can also simulate
disasters (in disaster mode). In disaster mode, animated sprites are removed.
After all, it is likely that ports, airports and train tracks are damaged, and
it would be overkill to update the number of objects in this case. Only water
and fire can be animated during a disaster. The sprites reappear after exiting
this mode.
