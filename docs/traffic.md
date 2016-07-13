# Traffic Simulation

Traffic simulation is the most CPU expensive part of the simulation. In short,
for each residential building, the cars try to find the closest destination
buildings (any type but residential) until all the people of that building have
left.

Even buildings with no electricity generate/absorb traffic. The idea is that
these buildings will eventually dissapear, but until that moment the people that
live there need to go to work, etc.

The code is located in:
- `source/simulation/simulation_traffic.asm` : Main code which iterates over all
  the tiles in the map and identifies buildings that can be used as source and
  destination.
- `source/simulation/simulation_traffic_trip.asm` : For a certain residential
  building, find valid destinations and increase the traffic value of the roads
  used to get to that point.

The result of the simulation is stored permanently in `BANK_CITY_MAP_TRAFFIC` in
order to be able to show the results easily and fast when showing the traffic
minimap. Bank `BANK_SCRATCH_RAM` is used as temporary storage.

## Input data

The city map is the only actual input for the simulation. As stated above, even
buildings that are not powered are handled the same way as the powered ones.

## Algorithm

### Main loop

Located in `Simulation_Traffic`.

- Clear `BANK_CITY_MAP_TRAFFIC`

- Initialize non-residential buildings

  For each tile, check if it is the top left tile of a building. If so, save the
  population density of this building in this tile in `BANK_CITY_MAP_TRAFFIC`.
  This value is then used to keep track of how many cars have arrived at this
  building.

- Handle residential buildings

  For each tile, check if it is a residential tile. Check if it has been handled
  (the value in `BANK_CITY_MAP_TRAFFIC` is 0 if not). If it hasn't been handled,
  check if this is the top left tile of a residential building. If so, call
  `Simulation_TrafficHandleSource`.

  After handling a residential building the population that couldn't find a
  destination is stored in the top left tile. The rest of the tiles of the
  building are flagged as handled (set `BANK_CITY_MAP_TRAFFIC` to 1), so we will
  speed up the code by not checking if each remaining tile is the top left tile
  of this building.

- Update tiles of the map to show the traffic level

### Car Trip

Located in `Simulation_TrafficHandleSource`.

This function searches for the closest possible buildings within a limited
distance that are a valid destination. It uses `BANK_SCRATCH_RAM` to store the
partial results of each call to this function, and adds the partial results to
the data already in `BANK_CITY_MAP_TRAFFIC`. The population in the top left
tile of each destination building in `BANK_CITY_MAP_TRAFFIC` is reduced as a
result of this function, and the traffic value in each road in said bank is
increased as needed.

The expansion algorithm is a Dijkstra algorithm in which the cost of each tile
is affected by the type of the tile and the traffic that is already on that
tile. That way, curves have a higher cost than straight roads, and roads with
more traffic have a higher cost so cars can try to go through a different path.
It's not recursive, it uses the queue functions located in the file
`source/simulation/queue.asm`.

NOTE: Only the type of the tile is checked when moving from one tile to another.
Because of this some weird situations can happen, like cars jumping from the
middle of a bridge to a parallel road, or from a building to a bridge parallel
to it. It also connects train tracks and roads in any possible way, even if the
drawings imply that the movement isn't valid. The reason is that more checking
would have made the algorithm even slower.

- Get density and dimensions of this residential building

  Flag all the tiles as handled. Note tha the top left one will be overwriten at
  the end of the function with the remaining amount of people that couldn't find
  a destination.

- Init queue and clear temporary WRAMX scratch bank

- Add neighbours of this building source of traffic to the queue

  All tiles touching the borders of this building are added to the queue if they
  are either roads or train tracks (see `TrafficAddStart`). Note that, because
  of the simple movement checks, bridges next to the building are valid starting
  points, even if they don't actually reach the building according to the
  drawing.

  Note: This means that buildings that aren't connected to a road are isolated,
  as the algorithm only works through roads. Even if a residential building is
  next to an industrial one, if there is not a road connecting them, they are
  isolated!

- While queue is not empty

  1. Check that there is population that needs to continue traveling.

     Check that the variable holding the remaining population of the building is
     not 0. If it is, exit.

  2. Check that there are tiles to handle.

     If there are no elements left in the queue, exit loop. This means that
     there are no more roads to travel trough, or that we reached the maximum
     distance from this building.

  3. Get tile coordinates to handle

     If there are elements in the queue, get one.

  4. Read tile type.

    - It is a road or a train track

      Try to expand from it by calling `TrafficTryExpand`. This function checks
      if the amount of people leaving the building is less or equal than the
      remaining traffic that this tile can hold.

      The trip generator algorithm won't go through a tile if "source building
      remaining population" + "tile current traffic" > 255. This means that if a
      destination  building only needs 1 person but the source building is
      trying to find a  destination for 5 people and the tile traffic is 254 it
      won't be able to go  through it, even if the logic says it should be able
      to. A value of 255 means that the road is full.

      This function also calculates the cost of moving from this tile to the
      neighbours, which is calculated by adding the traffic already on this tile
      to the base cost of movement of the tile. The cost is passed to the
      functions `TrafficTryMoveUp`, `TrafficTryMoveDown`, etc, which will write
      it to `BANK_SCRATCH_RAM` in the neighbours if there is a valid movement.

      `TrafficTryMoveUp` and the rest check if the cost of moving to this
      building is over the threshold. If not, they will call `TrafficAdd`, which
      checks if it is a valid destination and save the total movement cost to
      `BANK_SCRATCH_RAM` if so. Non-residential buildings are always a valid
      destination regardless of the cost.

      All valid neighbours are also added to the queue.

    - It is a building

      If this is not a road or train tracks, it must be a building, and not a
      residential one because `TrafficAdd` wouldn't allow that.

      Check if it has enough remaining density to accept more population. If
      there is some population left in the top left tile it means that it can
      accept  more population. Reduce it as much as possible and continue in
      next tile obtained from the queue with the remaining population.

      After that, retrace steps to increase traffic in all tiles used to get to
      this building (using the population that has actually arrived to the
      destination building). This is done in `TrafficRetraceStep`, which is a
      recursive function. It uses the actual amount of people that performed
      this trip and adds it in `BANK_CITY_MAP_TRAFFIC` to each tile that was
      used to get to this building.

- If there is remaining density, restore it to the source building

This means that the people from this residential building will be unhappy as
they couldn't find a valid destination! The same happens for non-residential
buildings: if its final density is not 0 it means that this building couldn'
get all the people it needs for working on it, for example!

## Output Data

The only valid output data is the one left in `BANK_CITY_MAP_TRAFFIC`.

For roads and train tracks, the value is the amount of traffic on that tile. It
saturates when it reaches 255.a

For buildings, only the top left tile is useful. It contains the amount of
people that couldn't left the building (for residential buildings) or couldn't
reach the building (for any other building).
