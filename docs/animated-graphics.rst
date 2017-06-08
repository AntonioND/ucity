=================
Animated Graphics
=================

The city map has some animated elements (cars, trains, boats, planes, water and
fire). This document describes their high-level behaviour. Note that, since the
animations take quite a bit of CPU time, the player can disable them in the
options menu to speed up the game a bit.

Note that the code related to planes, boats and trains is included in the file
``source/simulation/simulation_transport_anims.asm``, which holds generic code
used by the animations of all of them, as well as some defines like the maximum
number of elements of each kind that can be shown.

The different handling is due to the fact that planes, boats and trains are
sprites that move around the map, while cars, water and fire are tiles that are
replaced by other tiles in the same place. This means that the sprites need
special care when moving around the map, as they have to be scrolled at the same
speed as the background, and they must disappear when they leave the screen so
that they don't reappear on the other side after wrapping around the screen.

Sprite animations have two handlers. One of them is the emergency handler,
function ``Simulation_TransportAnimsVBLHandle``, that runs forcefully at every
VBL interrupt so that the player doesn't notice any interruptions in the
animations. The other one is ``Simulation_TransportAnimsHandle``, that handles
the movement logic, hides and shows sprites according to the scroll of the map,
etc. This isn't critical, and it's ok to wait for a bit until it is executed.

Note that animation functions that handle background maps don't update the VRAM
map so that it is done for all animations at once at the end once they are
finished.

Cars
====

The code is located in ``source/simulation/simulation_traffic.asm``. The
function that animates it is ``Simulation_TrafficAnimate``, whereas
``Simulation_TrafficRemoveAnimationTiles`` removes all animation-related tiles
and leaves the roads empty. Note that neither of them update the VRAM map, it
has to be updated by the caller.

There are 4 levels of traffic animation for vertical and horizontal road
segments. There are no traffic tiles for any other segment, like curves or
crossings.

The animation consists on toggling the vertical/horizontal flip bit in the
background (for vertical and horizontal roads respectively). This system is
memory efficient as it doesn't need any extra tiles in VRAM.

The traffic level is set in ``Simulation_Traffic``, and it follows the following
rules (3 = max level of traffic in tile drawing, 0 = no traffic):

.. code:: c

    unsigned char get_tile_traffic_level_drawing(unsigned char traffic_level)
    {
        if (traffic_level > 127)
            return 3;
        else
            return (traffic_level + 32) >> 6;
    }

Planes
======

The code is located in ``source/simulation/simulation_anim_planes.inc``.

The number of planes that are shown is the number of airports multiplied by 2
up to a maximum of ``SIMULATION_MAX_PLANES``. Planes can spawn at any airport or
at the edges of the map (all air space is connected to airports). If they spawn
at an airport, they start moving in the direction defined by
``PLANE_TAKEOFF_DIRECTION`` (0 = up, 1 = up right, 2 = right, etc).

Note that up to 255 airports are allowed. If there are more airports, the last
ones won't ever spawn planes.

Planes randomly rotate one direction step (for example, from 0 (up) to 1
(up-right). The number of animation steps needed for the change is calculated
with the following formula:

    ``(rand() & (PLANE_CHANGE_DIR_RANGE-1)) + PLANE_CHANGE_DIR_MIN``

Note that the minimum value for ``PLANE_CHANGE_DIR_MIN`` should be high enough
so that the plane doesn't rotate before leaving the runway of an airport. In
practice, this means that the value should be higher than the lenght of the
runway in pixels. Planes spawn at tiles with index ``T_AIRPORT_RUNWAY``, defined
in ``source/room_game/tileset_info.inc``.

Boats
=====

The code is located in ``source/simulation/simulation_anim_boats.inc``.

The number of boats that spawn is the number of tiles with type dock divided by
2 up to a maximum of ``SIMULATION_MAX_BOATS``. Boats can spawn only next to
docks, as there is no way to ensure that a boat that spawns at the border of the
map (or any other water tile) is actually connected to a port.

Similarly, only the first 255 docks are taken into consideration when spawning
boats. If there are more, they will be ignored.

Boats have a 1/32 chance of start moving in any direction (with water tiles on
it, of course!) as seen on ``BoatsRestartMovement``. Boats move a random number
of tiles at once up to a maximum of ``BOAT_MAX_CONTINUOUS_DISTANCE`` (but each
tile has a 1/4 chance of randomly stopping the boat anyway, as seen in
``BoatSetValidRandomDirection``). When they stop, they start trying again to
move with a 1/32 chance of actually making it.

Trains
======

The code is located in ``source/simulation/simulation_anim_trains.inc``. Note
that this file also contains ``TrainGenRandomMax16``, function that generates
16-bit numbers from 0 to a maximum specified number. It is only used here, but
it could be used in other places if needed.

The number of trains that spawn is the number of train track tiles divided by 64
up to a maximum of ``SIMULATION_MAX_TRAINS``. Trains spawn at any tile that
contains train tracks and start moving in a random direction, generated with
``TrainGetValidRandomDirection``.

Trains move in a straight line until they find a tile with more than one path to
take (checked in ``TrainsCheckOutOfTrack``. When that happens, a new direction
is generated with ``TrainGetValidRandomDirection``, excluding the one the train
comes from.

Trains move normally until they aren't on top of a tile, at which point they
jump to a different tile with train tracks. This can happen either when a train
reaches a dead end or when it fails to rotate fast enough because of other
simulation tasks taking too long (``Simulation_TransportAnimsVBLHandle`` is
executed twice before ``Simulation_TransportAnimsHandle`` is executed, so there
is one step in the train animation that is missed. If that step is the one where
it would rotate in a curve tile, it will just leave the train tracks instead of
starting to move in a different direction. This may seen undesirable, but it
can actually be useful if the train system in the city consists on a series of
isolated closed circuits. This way there is the possibility of a train jumping
to a different circuit and animating it.

Water
=====

The code is located in ``source/simulation/simulation_water.asm``. The function
``Simulation_WaterAnimate`` has a loop that modifies a random number of water
tiles. In short, a number is calculated with ``(rand() & 31) + 1``. That number
of water tiles is skipped. The first tile after them is toggled between
``T_WATER`` and ``T_WATER_EXTRA``. Then, a new number is calculated, and the
process is repeated until the end of the map is reached.

Fire
====

The code is located in ``source/simulation/simulation_fire.asm``. The function
``Simulation_FireAnimate`` has a loop that updates all tiles with ``TYPE_FIRE``.
The tiles ``T_FIRE_1`` and ``T_FIRE_2`` are contiguous in the tileset. Not only
that, but the index of ``T_FIRE_1`` is an even number and ``T_FIRE_2`` is the
tile right after that one. That way, replacing one tile by the other one (which
is the fire animation) is as easy as toggling the bit 0 of the tile map.
