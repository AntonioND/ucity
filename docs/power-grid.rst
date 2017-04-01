=====================
Power Grid Simulation
=====================

The power grid simulation is quite CPU expensive. For each power plant a flood
fill algorithm is used centered on it. There is a limited amount of 'paint',
which is the power output of the plant. This way, buildings close to the power
plant are most likely to be powered if there is not enough power for all of the
buildings connected to it.

Note: Power lines use power as well. It is done this way to simulate the
transport loses.

The code is located in:

- ``source/simulation/simulation_power.asm`` : Main code which iterates over all
  the tiles in the map and for each power plant powers the buildings around it.

The result of the simulation is stored in ``BANK_SCRATCH_RAM``. This means that
the data must be used right after the simulation or it will be lost as soon as
other simulation or anything else uses this bank as temporary storage.

In the main simulation loop, the function called right after the simulation
checks for each building if all the tiles of it are fully powered. If so, the
whole building is flagged as powered. If not, as unpowered. The flag is stored
in the bit ``TILE_OK_POWER_BIT`` of ``BANK_CITY_MAP_FLAGS`` permanently. This
information can be used for the minimap of the power distribution or to simulate
other subsystems that depend on buildings being powered (like public services).

Input data
==========

The city map is the main input for the simulation, but the current month of the
year is also used to change the power output of the power plant. For example,
wind plants have a higher output in winter while solar plants have the peak
output in summer. Other power plants are affected too, as the efficiency of the
thermodynamic cycles vary over the year, increasing the efficiency in winter.

Algorithm
=========

Main loop
---------

Located in ``Simulation_PowerDistribution``.

- Clear ``BANK_SCRATCH_RAM``.

- For each tile, check if it is a power plant.

  If it is a power plant, call ``Simulation_PowerPlantFloodFill``, which will
  power the buildings surounding the plant. After handling a power plant, all
  the tiles of the plant is flagged as handled, so the only tile that is
  actually considered when simulating is the top left one. It will fill
  ``BANK_SCRATCH_RAM`` with the output of the simulation.

Function ``Simulation_PowerDistributionSetTileOkFlag``, in the simulation loop,
is called right after finishing ``Simulation_PowerDistribution``. It takes the
data in in ``BANK_SCRATCH_RAM`` and fills the ``TILE_OK_POWER_BIT`` of
``BANK_CITY_MAP_FLAGS``.

Power Plant Flood Fill
----------------------

Located in ``Simulation_PowerPlantFloodFill``.

This function receives the coordinates of the top left tile of a power plant,
gets the power of that type of power plant for the current month, and powers the
building around it by using a flood fill algorithm with a limited amount of
paint (power output). The algorithm isn't recursive, it uses the queue functions
located in the file ``source/simulation/queue.asm``.

- Check if this power plant has already been handled

  If the value at ``BANK_SCRATCH_RAM`` has the bit ``TILE_HANDLED_POWER_PLANT``
  set to 1, it has been handled, return.

- Reset the ``TILE_HANDLED`` flag of all tiles in the map

  This bit of ``BANK_SCRATCH_RAM`` is set to 1 whenever a tile is handled in
  the simulation to avoid handling it twice by the same power plant, but not by
  this one, so they must be cleared first! A handled bit set to 1 doesn't mean
  that it has all the power it needs, maybe the power plant ran out of power
  with that tile and some power is still needed.

- Flag power plant as handled

  Get dimensions of the power plant and set the bit ``TILE_HANDLED_POWER_PLANT``
  in all the tiles of the power plant in ``BANK_SCRATCH_RAM``.

- Get power output and central point of the power plant

  Get the power output for this type of power plant for this month and the
  coordinates from where we have to start the flood algorithm. Save the power
  output to the variable ``power_plant_energy_left``, init the queue, and
  push the coordinates of the central tile to the queue to start the flood fill
  loop.

- While queue is not empty.

  1. Check that there is power left.

     If not, exit.

  2. Get queue element.

     Get address and check if it has already been handled (``TILE_HANDLED_BIT``
     if set is so). If it has been handled, jump to the step that checks if the
     queue is empty.

     If not, add power to the tile with ``AddPowerToTile``. It will try to add
     as much power as possible to the tile until the tile has all power it needs
     or the remaining power of the power plant goes down to 0. The amount of
     power that the tile has received is saved to ``BANK_SCRATCH_RAM`` so that
     the tile won't use power twice. It is also saved between power plant flood
     fills, which means that two power plants next to each other won't power the
     same tiles. The first one to be handled will power the buildings next to it
     and the second one will power the ones that are next to the border of the
     first one's power extent.

     Regardless of how much power the building has received (even if the power
     plant has no more power to give) flag the tile as handled (by setting
     ``TILE_HANDLED_BIT``).

  3. Add all valid neighbours to the queue

     Check all 4 direct neighbours and add their coordinates to the queue if
     they are either buildings or power lines. Unlike the traffic simulation,
     the bridges are handled correctly in the power grid simulation. It means
     that, unless the drawing implies that there is a connection between the 2
     tiles (bridge and ground) there won't be power transfer.

     This is checked in ``Simulation_PowerPlantFloodFill`` (check if the power
     is going from a bridge to the ground) and in
     ``AddToQueueVerticalDisplacement`` and ``AddToQueueHorizontalDisplacement``
     (check if the power is trying to go from the ground to a bridge).

  4. Check if the queue is empty.

     If so, exit loop.

Output Data
===========

The output is stored in ``BANK_SCRATCH_RAM``. The only useful data is the low 6
bits of each tile, which holds the amount of power that the building received
from power plants. If it is the same as the expected power density of this
building, the building is fully powered. It could happen that it is between 0
and that value (the building is half-powered, not good enough) or 0 (it didn't
receive any energy. This also means that the maximum power consumption of a tile
can be ``0x3F = 63``.

All tiles that can transmit energy consume power, even power lines (only 1 unit
of energy, but it's something).
