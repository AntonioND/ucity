==============
µCity - Manual
==============

Introduction
============

The aim of the game is to build a city. Simple enough. This manual explains the
basic concepts of the game, as well some tricks.

Start game
==========

The first thing to do is to decide whether you want to start with a predefined
scenario or with a completely empty random map.

If you decide to go for a random map, remember that the number used as seed to
generate the map will always generate the same map, in case you want to play
again the same map.

Once the city map is loaded, the controls are the following ones:

- SELECT: Open build menu.

- START: Open pause menu. From there, it is possible to go back to the main
  menu, save the city, etc.

- B: When held, it allows the player to move around the map freely without the
  cursor.

- A: If not building, show the name of the element under the cursor.

Note that, at some point, a red dot may appear on the screen and not let you do
certain actions. This means that the game is simulating something and it can't
let you do that until the simulation step has ended.

Building
========

To build something, just select the icon in the building selection menu
(opened by pressing SELECT).

Most buildings can be built by the player, but some of the most important ones
can't. Residential, commercial and industrial buildings (houses, shops and
factories respectively) must be created by the city. The player can only try to
attract people to the city.

Also, buildings can't be built on top of others. The exception are power lines,
which can be replaced by any building (not roads or train tracks).

Demolishing buildings is as easy as building them, just select the dynamite in
the building selection menu.

There are some buildings that require specific things to be built (like having
more than a certain number of people, having a specific technological level...).

Services
========

Services are needed to make the population happy. While all buildings have a
level of happiness based on the needs that are met, it is specially important
for residential, commercial and industrial zones. If those zones don't have
their needs covered, people will leave them.

The services needed by people are determined by the class of the settlement.

Police departments and schools are always needed. It is only needed to build
fire department, hospitals and high schools when the settlement becomes a town.

Universities are a special case. They are not needed to cover the needs of the
population, but they are the only ways of making the technological level of the
city increase. This is the only way of unlocking fission nuclear power plants
and, eventually, fusion power plants.

Transportation
==============

Transportation is essential to allow people move between different buildings.
Residential areas are sources of traffic and other areas are sinks of traffic.

If people in residential areas cannot reach schools and workplaces (commercial
and industrial zones, for example) they will leave.

Roads and train tracks have a specific capacity. The more people using them, the
less people will want to use them. At some point, they are too crowded for more
people to use them.

Roads and train tracks can be interleaved and they count as being connected even
if the drawing of the tiles in the map don't look like they are connected. It is
enough for them to be next to each other.

Ports and airports don't have any effect on transportation within a city, they
are only a source of income, like stadiums.

Power
=====

Power plants are needed to provide energy to all your buildings (even parks!).
Buildings with no power can't work.

The generation depends on the time of the year. Some power plants are more
effective in summer, like solar power plants, and others are more effective in
winter, like wind power plants. All other power plants are slightly affected by
the time of the year, the efficiency depends on the temperature of the
environment after all.

Pollution
=========

Transportation, factories, polluting power plants... They all create pollution.
A polluted city will make less people want to come!

City class
==========

A settlement changes class depending on the population and the presence of some
buildings.

- Village: From the start.

- Town: Population >= 500.

- City: At least one library. Population >= 1000.

- Metropolis: At least one stadium, university and museum. Population >= 3000.

- Capital: At least one port and an airport. Population >= 6000.

The requirements add up, that is, to upgrade to a capital it is needed to meet
all requirements of the lower classes.

Similarly, some building types are unlocked by reaching specific classes.

- City: Unlocks stadiums, ports and airports.

Loans
=====

If you are short of money, you can ask the bank for a loan. Information about
the payments is in the same screen where you can get them. You can only have one
loan at a time.

Disasters
=========

Sometimes, unexpected disastrous events can happen. In this game, fires can
happen anytime, as well as nuclear meltdowns (if there are fission nuclear power
plants).

The more fire departments, the lower the risk of fires. However, once a fire has
started, the best way to get rid of it is to demolish every tile around it as
soon as possible, edit mode isn't disabled during disasters.

Nuclear meltdowns always have the same risk of happening. When a fission nuclear
power plant explodes it spreads radiation (even if the fire was propagated from
another building). Radiation takes a really long time to disappear, and there is
no way of building things on top of it or of removing it. It can stay in both
water and land.

Disasters can be turned off in the options menu, if you prefer to play that way.

Game Over
=========

The only way to lose in this game is to have a negative budget 4 times in a row.
If there is a positive budget, the counter decreases back to 0 once per positive
budget. Note that negative funds don't matter in this case.

After 4 negative budgets, the population will get tired of you and remove you
from your position as mayor.

There is no way to win! Isn't the satisfaction of a fully developed city enough
for everybody? :)
