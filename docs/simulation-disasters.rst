=========
Disasters
=========

As of now, there are two different disasters: Fires and nuclear meltdowns. They
both appear randomly. Fires appear depending on the number of fire stations,
nuclear meltdowns depend on the number of nuclear fission power plants.
Disasters can be disabled in the options menu if the player wants to play
without distractions from them.

Note that when a disaster starts the main simulation loop switches to disaster
mode, which only updates the fire and ignores the rest of the simulated
elements.

Disasters can appear at the end of any simulation step. If disaster mode is
active, no more disasters can be triggered, not even by the player.

While in disaster mode, there is only a minimap available to see, which shows
the location of the fires.

Fires
=====

The code that handles fires is in ``source/simulation/simulation_fire.asm``.

At every simulation step, the probabilities of a fire starting are:

    :code:`max(4 - number of fire stations, 1) / 256`

If a fire is supposed to start a loop generates random coordinates in the map
until it finds a burnable tile. If it hasn't found one after 10 tries, it just
returns and doesn't start a fire. If it succeeds, a fire starts in that tile
and the simulation loop enters disaster mode. This is all handled by
``Simulation_FireTryStart``.

This means that, even if the player triggers a fire, it is still possible that
the fire doesn't start after all.

Note that, when a tile is burned, if that tile is part of a building, the whole
building is destroyed and catches fire. Obviously, this doesn't cost any money,
buildings can always be destroyed by fire (and the SFX that is played is
different than when the player demolishes them). The function that is used to
burn tiles is ``MapDeleteBuildingFire``.

Once there is a fire, it starts to spread. The function that handles the fire is
``Simulation_Fire``.

1. For each tile in the map, the probability of it catching fire is the
   burnability of the tile multiplied by the number of tiles next to it that are
   on fire (it saturates at 255). This is saved to a temporary ``WRAMX`` bank.

2. For each tile in the map, the chances of the fire being extinguished are:

       :code:`max((fire stations + 1) * 2, 256) / 256`

   The ``+ 1`` is needed so that fires can go off even if there are no fire
   stations.

   Note that the number of fire stations is the one at the start of the fire.
   Even if a fire department is the origin of the fire, that one counts in the
   previous formula.

3. Finally, for each tile with the accumulated probabilities higher than 0 (the
   ones calculated in part 1), a random number is generated. If that number is
   lower than the accumulated saved number, that tile catches fire (and it
   destroys the whole building in case it was a part of one).

Note that nuclear fission power plants, when they explode, spread radiation
tiles around them, the same way as they do when there's a nuclear meltdown.

In practice, the best way to get rid of fires is to demolish every tile around a
fire as soon as possible, as edit mode isn't disabled during disasters.

Nuclear meltdowns
=================

All code related to nuclear meltdowns is in the file
``source/simulation/simulation_meltdown.asm``.

At each simulation step, for every nuclear fission power plant in the map, there
is a 1/256 chance that that particular power plant will explode. This is done in
``Simulation_MeltdownTryStart``.

If the nuclear meltdown has been forced (by the player, for example), the first
power plant to be found is used instead. Obviously, if there are no nuclear
fission power plants, it is impossible to have a meltdown.

When a power plant explodes, it catches fire and spreads radiation tiles around
it. The function ``Simulation_MeltdownTryStart`` doesn't actually spread
radiation. This is done by ``MapDeleteBuildingFire``. That way, when a power
plant is burned down by a regular fire, it will also spread radiation tiles.

The function that spreads radiation is ``Simulation_RadiationSpread``, which is
called by ``MapDeleteBuildingFire`` if it burns a nuclear fission power plant
down. This function generates 16 radiation tiles around the center of the power
plant. If any of them lands outside of the map the function won't repeat the
calculations, there will be simply one less tile of radiation.

Radiation can land up to 8 tiles away in any direction from the center of the
power plant:

.. code::

    radiation x = center of power plant x + (rand() & 15) - 8
    radiation y = center of power plant y + (rand() & 15) - 8

If radiation tiles fall in a building, they destroy it and burn it. If there is
no building (it is just a road, or field, or a forest, for example) nothing
special happens. Water tiles can also be made radioactive. They have a different
image than the ones in land.

Radiation tiles are special in the way that they can't be removed, and they
prevent buildings from being built in that place. They can't burn either.

At each simulation step (in normal mode, not in disaster mode) there is a 1/256
chance for each radioactive tile to be removed and turned back into regular land
or water.
