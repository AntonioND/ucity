==================
General Simulation
==================

This file explains the parts of the simulation that aren't explained in any
other file.

The file ``source/simulation/building_density.asm`` contains information about
each tile, which is used when simulating different things:

  - Population: Total population of the building (not per-tile of the building).
    Used for the traffic simulation and the population density minimap.

  - Energy cost: Energetic cost per-tile. Used for the power simulation and the
    power density minimap.

  - Pollution level: How much each tile pollutes.

  - Fire probability: Probability to catch fire per-tile.

They are stored in the array ``CITY_TILE_DENSITY``, and there are some helper
functions to get this information without directly accessing it.

Time
====

Each simulation step in the game is a month. The game can start at any year
between ``0000`` and ``9999``, and the year will stop increasing when it reaches
``9999``. The months will continue to increase, though.

Note that there are some messages that can only be shown once per year (in order
not to annoy the player too much with them). The flags that prevent them from
being shown again are reseted when ``DateStep`` makes the year increase.

All code related to handling dates and time is in ``source/room_game/date.asm``.

The historic graphs shown in the graphs room (which can be accessed from the
pause menu during gameplay) are updated once per month. The way the graphs work
is that they start being drawn on the right side and they start moving left as
more data is obtained. The code is in ``/source/room_graphs/graphs_handle.asm``.

The data for the graphs is stored in a circular buffer (plus an extra variable
to say where the data starts). All of it is saved in the SRAM when saving the
data of a city.

Services
========

There are a few services that are simulated the same way: police, fire
department, hospitals, schools and high schools. The simulation is done the same
way for all of them (but in different layers). For each layer, the simulation
works the same way.

First of all, the flags ``TILE_OK_SERVICES`` and ``TILE_OK_EDUCATION`` are set
for each tile in ``CITY_MAP_FLAGS``.

The map is scanned for each building of the corresponding type (police stations,
fire department buildings, etc). Then, a circular mask is added to the
simulation layer (in ``BANK_SCRATCH_RAM``). This mask has a circular shape, with
higher values in the center of the circle (where the building is). If, at some
point, the addition of two masks makes the result overflow, it saturates to
``255`` instead of overflowing. This is easier to see by just opening one of the
minimaps of any service and seeing the resulting drawing.

Buildings must have power to work! If a building doesn't have power, it won't
have any effect on the simulation, it will simply be ignored.

Once the effect of each building has been added to the simulation layer, the
value for each tile of the map is compared against a threshold,
``SERVICE_MIN_LEVEL``. If the value is lower than the threshold, the
corresponding flag in the map ``CITY_MAP_FLAGS`` is reset. ``TILE_OK_SERVICES``
depends on the police, fire protection and hospitals. ``TILE_OK_EDUCATION``
depends on schools and high schools.

There isn't a specific function to simulate each type of service,
``Simulation_Services`` is called with a tile ID (which should be the central
tile of the building that wants to be checked). There are two sizes of mask
(32x32 and 64x64). The only buildings to use the 64x64 one are high schools, and
they use the function ``Simulation_ServicesBig``.

Note that, while it is always required to have police departments and schools,
it is only needed to build the others when the city grows. Fire departments,
hospitals and high schools are needed as soon as the settlement is bigger than a
village. The code that checks this is in ``RoomGameSimulateStepNormal`` in
``source/room_game/room_game.asm``.

The service simulation code is in ``source/simulation/simulation_services.asm``,
and the masks have been generated with ``tools/lut_gens/gen_mask.c``.

Technology
==========

Each settlement has a hidden technology level that can't be seen from the
player's point of view.

At the beginning of each year, ``Simulation_AdvanceTechnology`` is called.
It tries to increase the technology level once per each university that is
present in the map.

If the new technology level doesn't unlock anything, the increment will always
be successful. If the new technology level unlocks a new building, there is a
70/256 chance of failing to increase. This happens when the level reaches
``TECH_LEVEL_NUCLEAR``, which unlocks fission nuclear power plants, or
``TECH_LEVEL_FUSION``, which unlocks fusion power plants. If a building is
unlocked, a message is shown so that the player knows which new building is
available.

When ``TECH_LEVEL_MAX`` is reached, the technology level stops increasing.

The relevant code is in ``source/simulation/simulation_technology.asm``. This
file also has a function to check if a building is available based on the
technology level, ``Technology_IsBuildingAvailable``.

Money
=====

The relevant code is in ``source/simulation/simulation_money.asm``. This file
contains data of the cost of each tile (or income generated by it). Note that
the values are bytes in BCD, it can go from ``00`` to ``99``.

Income is generated by taxes in two groups:

  - Residential, commercial and industrial areas.

  - Stadiums, airports, ports and docks.

Costs are divided in a few groups:

  - Police

  - Fire protection

  - Healthcare

  - Education (schools, high schools, universities, museums and libraries).

  - Transportation (maintenance of roads, train tracks, power lines and
    bridges).

  - Loan payments

In short, for each tile of the map, the value in the ``CITY_TILE_MONEY_COST``
array is added to a different variable pointed by the ``tile_money_destination``
array. Then, each sum is added or removed from the funds as expected.

The costs are always the same, they depend on the buildings of the settlement.
Taxes can be risen or lowered. The base values are the ones corresponding to a
10% in taxes, but it can be set to any value between 0% and 20%. Taxes affect
how people feel about the city. High taxes may lead people out of the city while
low taxes may help them come.

Budget is applied every 3 months, not yearly.

There are some helper functions to handle money in ``source/money.asm``, and
some definitions in ``source/money.inc``. The macro ``DATA_MONEY_AMOUNT`` is
specially useful. Money amounts are stored as BCD values, this macro helps the
coder introduce new money amounts without having to do it manually.

The only way to lose in this game is to have a negative budget 4 times in a row.
If there is a positive budget, the counter decreases back to 0 once per positive
budget. Note that having negative funds doesn't have any negative effect.

Pollution
=========

The code that simulates the pollution is in ``Simulation_Pollution`` in the file
``source/simulation/simulation_pollution.asm``.

First, ``BANK_SCRATCH_RAM`` is filled with the pollution values of each tile.
They are either the values in the ``CITY_TILE_DENSITY`` array or the ones
generated during the traffic simulation (only used for tiles that contain roads
or train tracks).

Then, it is smoothed. The value of each tile is replaced by the sum of its value
plus the one of the top, bottom, right and left tiles divided by 3. This is done
4 times, moving the data from ``BANK_SCRATCH_RAM`` to ``BANK_SCRATCH_RAM_2`` and
back so that the code doesn't erase values that are still needed for the
calculations of the next row.

Tiles in the border of the map are special. For them, only the neighbour tiles
that are inside the map are added, the rest are treated as 0.

Note that this file contains a look up table to divide by 3 as fast as possible.
It simply has the result of dividing all unsigned 8-bit values by 3.

For each tile with pollution lower than ``POLLUTION_MAX_VALID_LEVEL``, the bit
``TILE_OK_POLLUTION_BIT`` is set in ``BANK_CITY_MAP_FLAGS``. This is only done
for tiles with buildings that require the check, though. Areas like fields or
forests don't complain about pollution.

The total pollution (before smoothing it) is stored in ``pollution_total``. If
it is too high, the player will get a message complaining about it. The
percentage of pollution is stored in ``pollution_total_percent`` (current
pollution divided by maximum possible pollution).

City Statistics
===============

First, there are some building types that influence the simulation depending on
the amount of them. The number of them is constant during the normal simulation
of the game, so it is useless to recalculate the number at each step. The file
``source/simulation/simulation_building_count.asm`` has a function that counts
the number of tiles used for roads and train tracks, and the number of some
types of buildings. This is only updated when the map is first loaded, when the
user leaves the editor mode (where it can build and demolish buildings), and
when disaster mode is finished (after a fire has gone off).

The file ``source/simulation/simulation_calculate_stats.asm`` contains code that
calculates different statistics:

  - Population (residential, commercial, industrial, others, and total). Note
    that the population of a building isn't tile-based, only the top left tile
    of each building should be added to the total population.

  - Demand for residential, commercial and industrial zones (displayed in the
    status bar and plotted in one of the historical graphs).

  - Sets flags signalling the availability of certain types of buildings.

There is also the function ``Simulation_CalculateCityType``, which updates the
class of the settlement depending on the total population and the availability
of some buildings.

Also, note that there are some buildings that cannot be built in settlements
smaller than a city (stadiums, ports and airports).

Happiness
=========

Happiness is an abstract magnitude that depends on the type of tile. While it
doesn't affect in any way the simulation in most cases, it does affect the
creation and destruction of buildings in residential, commercial and industrial
zones. The effect of this is discussed `here <simulation-buildings.rst>`_.

The happiness of each tile of the settlement can be visualized in a minimap. The
source code is in ``source/room_minimap/minimap_happiness.asm``.

In short, for each tile, the corresponding entry in ``WRAMX`` in bank
``BANK_CITY_MAP_FLAGS`` is checked for the flags ``TILE_OK_POWER``,
``TILE_OK_SERVICES``, ``TILE_OK_EDUCATION``, ``TILE_OK_POLLUTION`` and
``TILE_OK_TRAFFIC``. Depending on the tile, there are different needs.

In the map, if a tile isn't part of a building (or a road or train track), it
will appear white. If a tile has all needed flags set to 1, it will be shown as
yellow. The needed flags are those that are a must for the building to work. The
desired flags are a superset of the needed flags, and they are the ones needed
for the building to be happy (for example, low levels of pollution). If those
are met too, the building will appear as green in the map. If not even the
needed flags are met, the building will appear as red.

Buildings in red may not work. For example, police stations, hospitals, schools,
etc, without power, aren't taken into account in the simulation, they are just
ignored. Residential, commercial and industrial areas that don't get what they
need will become empty.
