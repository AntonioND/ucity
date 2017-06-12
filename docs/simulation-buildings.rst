============================
Building Creation Simulation
============================

Buildings in residential, commercial and industrial areas can't be built by the
player. The player can only allocate zones for them and the game decides whether
to create buildings, make old buildings grow, or demolish them. Big buildings
can's shrink, they can only be demolished. The simulation decides this based on
the number of needs that are met in each tile.

All source code related to this is in:

- ``source/simulation/simulation_create_buildings.asm`` : Code related to the
  simulation of this module.

- ``tools/lut_gens/gen_build_prob.c`` : Tool used to generate look up tables
  with probabilities of buildings being demolished or built based on the amount
  of taxes collected in the city.

Input data
==========

The city map and the flags layer of the city are the main inputs. The percentage
of taxes is also used to calculate the odds of a building being built or
demolished.

This information isn't used as-is. At the end of the main simulation loop the
function ``Simulation_FlagCreateBuildings`` is called. This function checks
every residential, commercial and industrial tile and checks if its needs are
covered. If the basic needs of that tile aren't covered, it is flagged for
demolition by setting bit ``TILE_DEMOLISH_REQUESTED_BIT``. If the basic needs
are met, but the desired needs aren't no flags are set. If all the desired needs
are met, the tile is flagged for building (or upgrade if there's already a
building there) by setting bit ``TILE_BUILD_REQUESTED_BIT``. Those two flags are
the actual inputs of ``Simulation_CreateBuildings``, which is the function used
to build and demolish buildings.

This function is called at the end of the loop so that buildings are updated at
the beginning of the next simulation step. This allows the simulation to be
paused and resumed from a saved game and have the same result always. If not, if
the game was saved, ``Simulation_CreateBuildings`` could receive different
information before saving and after loading the data. In the first case it would
receive the information of the previous step, in the second case it would have
to refresh the information based on the current buildings.

Algorithm
=========

The simulation function is ``Simulation_CreateBuildings``.

Preparation
-----------

First, the probabilities of building and demolishing buildings are calculated.
The following value is calculated:

    ``taxes + (2 * (total pollution >> 16)) + (% tiles with traffic jam / 16)``

    Note: The max value of the total pollution is ``255*64*64 = 0x0FF000``.

    If the resulting value of that expression is greater than 20, it is clamped
    to 20.

It is used as input for the arrays ``CreateBuildingProbability`` and
``DemolishBuildingProbability``, which have been generated with the tool in
``tools/lut_gens/gen_build_prob.c``.

Note that, while the probabilities are common to the three types of zones, the
next part of the algorithm is done separately for each one of them.

Once this is calculated it is needed to setup some helper information. ``WRAMX``
bank ``BANK_SCRATCH_RAM`` is filled with information to expand buildings and
``BANK_SCRATCH_RAM_2`` with the size of the current buildings (1, 2 or 3) in
order not to build small buildings on top of big ones.

The information saved in ``BANK_SCRATCH_RAM`` is the trick of this simulation
module. In order to check quickly if a building can be placed on top of the
other one, the following is done.

A flag is assigned to each tile of a 3x3 block of tiles except to the center.
That is, there is a flag for the top left corner (bit 0), another one for the
top center tile (bit 1), and so on. The central tile has all the flags set to 1
for consistency with the rest of the algorithm. For 2x2 and 1x1 buildings the
flags are OR'ed. The resulting patterns are the following ones:

    +----+-----+-----+
    |  1 |   2 |   4 |
    +----+-----+-----+
    |  8 | 255 |  16 |
    +----+-----+-----+
    | 32 |  64 | 128 |
    +----+-----+-----+

    +---------+-----------+
    |  1+2+8  |   2+4+16  |
    +---------+-----------+
    | 8+32+64 | 16+64+128 |
    +---------+-----------+

    +-----+
    | 255 |
    +-----+

So, in short, ``BANK_SCRATCH_RAM`` is filled with flags that indicate the corner
and side to which a tile belongs, and ``BANK_SCRATCH_RAM_2`` is filled with the
size of the building.

Note that, in practice, the 3x3 pattern isn't written to ``BANK_SCRATCH_RAM``
because 3x3 buildings can't be replaced by bigger ones. Not writing the flags
makes it faster to check for failures to build on top of them.

Construction and demolition
---------------------------

First, there is a loop that checks all residential, commercial and industrial
tiles for requests to build. For each tile that has requested to be built, a
random number is generated. It is compared to the probabilities to build and, if
the check passes, ``Simulation_CreateBuildingsTryBuild`` is called with the
coordinates of this tile.

This function tries to build a building as big as possible taking the
coordinates passed as arguments as the top left tile of the building. It starts
checking a 3x3 square of tiles, then 2x2 and finally 1x1 (just itself). The
checks, for each one of the tiles, are the following ones:

- It checks if it is flagged to build or demolished. Unless all tiles have been
  flagged to build, it will fail to build. If there is a request to demolish, it
  will fail to build, logically.

- The size of the new building must be bigger than the one in all tiles in bank
  ``BANK_SCRATCH_RAM_2``. This is done so that buildings don't change all the
  time if they are happy.

- The old buildings must be in positions that allow a new building to be placed
  there. This is where the flags in ``BANK_SCRATCH_RAM`` come into play.

  For example, if the code is trying to see if a 3x3 building can be placed in
  this place, the 3x3 pattern is overlaid on top of the current flags. The
  flags in each current tile are AND'ed with the ones overlaid. If the result
  of all of them is non-zero, the building is allowed to be built.

  This system is a bit tricky, but it works, and it's reasonably fast, so it's
  good enough for this game.

All tiles must be checked for the 3x3 case, then the 2x2 and finally the 1x1.
However, the order of the checks has been chosen so that it the checks are
faster on average if it is going to fail to build.

If the building is actually built, all flags are cleared (by the function that
draws the building in the map) so that the process isn't repeated again in the
same place.

Finally, another loop checks for any tile that has requested to be demolished.
For each one of them, a random number is generated and compared against the
probabilities of a building being demolished. If the check passes, the whole
building is demolished with ``MapDeleteBuildingForced`` and replaced by 'R', 'C'
or 'I' tiles. Obviously, 'R', 'C' and 'I' tiles cannot be demolished by this
function.
