===============
Editing the map
===============

This documentation file explains how the edition mode works: How the game
handles it when buildings are built/demolished by the player.

Note that, for the player, it is only possible to build buildings on top of
empty field tiles. However, if there are power lines, they will automatically be
removed. That's the only exception.

The relevant code and functions are located in:

- ``source/room_game/tileset_info.inc`` : List of tiles that can be used in the
  map.

- ``source/room_game/tileset_info.asm`` : Basic information about all tiles that
  can be used in the map, like tile type and whether it belongs to a bigger
  building or not.

  The origin of coordinates of a building is the top left tile. That tile has
  delta X and delta Y equal to 0. The following tiles (arranged in rows, from
  left to right, top to bottom) have the value that has to be added to the
  coordinates of this tile to find the origin. The deltas are available in this
  file to be accessed quickly when needed for other calculations.

- ``source/room_game/draw_building.asm`` : Auxiliary functions and top level
  building/demolishing functions.

    - Utility functions:

        - ``BuildingGetCoordinateOrigin`` : From the coordinates of any tile of
          a building, it returns the coordinates of the origin of the building.

        - ``BuildingGetCoordinateOriginAndSize`` : From the coordinates of any
          tile of a building, it returns the coordinates of the origin of the
          building and the size of the building.

    - Building functions:

        - ``MapUpdateBuildingSuroundingPowerLines`` : When a building has been
          built, it is possible that the surrounding power lines have to be
          updated to be joined to it. This function does that (otherwise
          cosmetic) change.

        - ``MapDrawBuildingForcedCoords`` : Force a building to be built at the
          specified coordinates, ignoring money, available technology, city
          size... It doesn't play SFX.

        - ``MapDrawBuildingForced`` : Same as above, but the building is built
          at the current cursor coordinates. It doesn't play SFX.

        - ``MapDrawBuilding`` : Builds a building at the cursor coordinates. It
          checks that the player has enough money to do it, and subtracts that
          amount of money from the city funds. It also checks if the terrain
          allows a building to be built or not. It plays SFX.

    - Demolishing functions:

        - ``MapDeleteBuildingForced`` : Removes a building from the coordinates
          of any of its tiles. It doesn't check money or play SFX. Used for
          residential, commercial and industrial buildings when they are
          demolished automatically.

        - ``MapDeleteBuilding`` : Removes a building from the coordinates of any
          of its tiles. It checks if there is enough money to do so, and
          subtracts the amount of money needed to do it from the city funds. It
          plays SFX (it is different if it is removing debris from a removed
          building than when removing a building).

        - ``MapClearDemolishedTile`` : It converts a demolished tile into a
          field one checking money and subtracting it from the city funds. It
          plays SFX.

- ``source/room_game/building_info.inc`` : List of building IDs.

- ``source/room_game/building_info.asm`` : Functions to handle buildings. Note
  that the demolition tool is also considered a building, but not all the
  functions that handle them allow it as an argument. This file also has
  information about the tiles of a building, their size, prices, etc.

    - Utility functions:

        - ``BuildingIsAvailable`` : It returns 1 if the specified building type
          is available by checking the technology level and the city size.
          Nuclear power plants (fission and fusion) can only be built after
          reaching a specific technological level. Stadiums, ports and airports
          can only be built in cities or bigger settlements.

        - ``BuildingTypeSelect`` : Sets the type of building that the player
          wants to build. It can update the cursor size to the building size if
          needed.

        - ``BuildingTypeGet`` : Get currently selected building type.

        - ``BuildingGetSize`` : Returns the size of the specified building.

        - ``BuildingGetSizeAndBaseTile`` : Returns the size and base tile of the
          specified building. It can't be called with the delete building ID.

        - ``BuildingCurrentGetSizeAndBaseTile`` : Same as above, but it returns
          the information of the currently selected building.

        - ``BuildingUpdateCursorSize`` : Updates cursor size to the one of the
          selected building.

        - ``BuildingGetSizeFromBaseTile`` : Get size of a building from its base
          tile. If the specified tile isn't the base tile of a building, execute
          an emulator breakpoint (instruction :code:`ld b,b`) and return 1x1.

        - ``BuildingGetSizeFromBaseTileIgnoreErrors`` : Same as above, but
          without breakpoint.

        - ``BuildingSelectedGetPricePointer`` : Returns the price of the
          currently selected building.

        - ``BuildingPriceTempSet``, ``BuildingPriceTempMultiply`` and
          ``BuildingPriceTempGet`` : Used to operate with the prices of
          buildings. They allow the caller to specify a price and multiply it by
          a given value (more than once if needed) to calculate the total price
          of a building, for example. Note that they use a temporary buffer for
          the calculations, so they can't be used to calculate 2 things at the
          same time.

    - Building functions:

        - ``BuildingBuildAtCursor`` : Top level function used by the user
          interface. This function is called whenever the player wants to build
          (or demolish) a building. Internally it checks the building type
          trying to be built and calls the corresponding build or demolish
          function (for example, ``MapDrawRoad``, ``MapDrawPort``,
          ``BuildingRemoveAtCursor``, etc). All the sub functions verify that
          the player has enough money to build or demolish, and subtract the
          corresponding amount of money from the city funds. It refreshes the
          VRAM live map before returning the control to the user interface code.

    - Demolishing functions:

        - ``BuildingRemoveRoadTrainPowerLines`` : Remove a tile of roads, train
          tracks or power lines. They require special care because the removal
          of bridges requires special handling.

        - ``BuildingRemoveAtCursor`` : Removes the building at the cursor's
          coordinates, checking that the player has enough money.

        - ``BuildingRemoveAtCoords`` : Removes the building at the specified
          coordinates, checking that the player has enough money.

- ``source/room_game/draw_train.asm`` : Functions to draw train tracks.

    - ``MapTileUpdateTrain`` : Update the tile at the specified coordinates.
      Useful after building or removing train tracks around it.

    - ``MapUpdateNeighboursTrain`` : Update all tiles around the specified
      coordinates (and the central tile).

    - ``MapDrawTrain`` : Draw a train track tile on the cursor and update the
      tiles around it to connect them to it.

- ``source/room_game/draw_power_lines.asm`` : Functions to draw power lines.

    - ``TypeHasElectricityExtended`` : Checks whether the specified tile type is
      something that uses electricity (buildings and power lines).

    - ``TypeBuildingHasElectricity`` : Checks if the specified type is a
      building that requires electricity (it doesn't check power lines).

    - ``MapTileUpdatePowerLines`` : Update the tile at the specified
      coordinates. Useful after building or removing power lines around it.

    - ``MapUpdateNeighboursPowerLines`` : Update all tiles around the specified
      coordinates (and the central tile).

    - ``MapDrawPowerLines`` : Draw a power lines tile on the cursor and update
      the tiles around it to connect them to it.

- ``source/room_game/draw_road.asm`` : Functions to draw roads.

    - ``MapTileUpdateRoad`` : Update the tile at the specified coordinates.
      Useful after building or removing power lines around it.

    - ``MapDrawRoad`` : Draw a road tile on the cursor and update the tiles
      around it to connect them to it.

    - ``MapUpdateNeighboursRoad`` : Update all tiles around the specified
      coordinates (and the central tile).

    - ``MapDeleteRoadTrainPowerlines`` :  It deletes one tile of road, train or
      power lines, but it doesn't update neighbours, that has to be done by the
      caller. It doesn't work to demolish bridges.

- ``source/room_game/draw_port.asm`` : Functions to draw and demolish ports.

    - ``MapCheckSurroundingWater`` : Returns 1 if there is water in any tile
      surrounding this building (defined by its coordinates and size).

    - ``MapBuildDocksSurrounding`` : Checks all tiles surrounding a port and
      builds docks on the water ones. Called from ``MapDrawPort``. It doesn't
      refresh the VRAM map.

    - ``MapConvertDocksIntoWater`` : It checks the tiles surrounding this port.
      For each dock tile, if it is facing this port, it sets it to water. Docks
      that belong to other ports are left unchanged. Used by ``MapDeletePort``.

    - ``MapRemoveDocksSurrounding`` : Once the docks have been removed with
      ``MapConvertDocksIntoWater``, this function refreshes the water tiles so
      that the drawings are the correct ones. It is needed to do it after
      converting all tiles to water to avoid partial updates of tiles that have
      an adjacent tile that hasn't had time to be updated. It doesn't refresh
      the VRAM map. Used by ``MapDeletePort``.

    - ``MapDrawPort`` : Draws a port and all the docks that it is possible to
      build around it (by looking for empty water tiles). It checks for money
      (docks are free).

    - ``MapDeletePort`` : Deletes a port and its associated docks. It must be
      passed as argument the coordinates of one of the tiles of the port, not
      the docks. It checks for money (docks are free).

- ``source/room_game/draw_common.asm`` : General functions, used for things like
  getting information from the map. Also, there are functions to build and
  demolish bridges.

  It also contains the array ``CLAMP_0_63``, used to clamp any signed 8-byte
  value to the range 0-63 easily. This is specially useful when there is more
  than one value to clamp, as it isn't needed to load the address of the array
  twice and the pointer can be reused (it is aligned to 256 bytes).

    - Utility functions:

        - ``CityMapAddrToCoords`` : Converts an address in ``WRAMX`` to the
          corresponding coordinates of the map.

        - ``CityMapRefreshAttributeMap`` : Refreshes the attribute map (filling
          the palette) from the 9-bit tile numbers. To be called when a
          preloaded scenario (or saved map) is loaded, as only the tile number
          is saved.

        - ``CityMapRefreshTypeMap`` : Refreshes the type map. To be called when
          loading a map, same as above.

        - ``CityMapGetType`` : Get type of the tile at the specified
          coordinates, doing coordinate bound checks. This function can also be
          used to guess the type of the rows and columns right next to the map
          (but out of it). They expand the type of the tile in the border (water
          or field). For example, if the last tile at row 63 is a forest, row 64
          would have a field. If it was water, the result would be water as
          well.

        - ``CityMapGetTypeNoBoundCheck`` : Same as above, but it returns garbage
          when invalid coordinates are passed as it doesn't do any bounds
          checks.

        - ``CityMapGetTile`` : Get tile index at the specified coordinates,
          doing coordinate bound checks. This function can also be used to guess
          the type of the rows and columns right next to the map (but out of
          it). They expand the type of the tile in the border (water or field).
          For example, if the last tile at row 63 is a forest, row 64 would have
          a field. If it was water, the result would be water as well.

        - ``CityMapGetTileNoBoundCheck`` : Same as above, but it returns garbage
          when invalid coordinates are passed as it doesn't do any bounds
          checks.

        - ``CityMapGetTypeAndTile`` : Get tile index and type at the specified
          coordinates, doing coordinate bound checks. This function can also be
          used to guess the type of the rows and columns right next to the map
          (but out of it). They expand the type of the tile in the border (water
          or field). For example, if the last tile at row 63 is a forest, row 64
          would have a field. If it was water, the result would be water as
          well.

        - ``CityMapGetTileAtAddress`` : Gets the tile number at the specified
          address. This is just a helper to avoid constructing the tile number
          manually wherever it is needed.

        - ``UpdateWater`` : Updates the drawing of a water tile.

    - Building functions:

        - ``CityMapDraw`` : Function called by the user interface when the
          player wants to build (or demolish) something. It's a wrapper around
          the actual function that does the work, ``BuildingBuildAtCursor``. The
          only thing it does is to block draw requests if the scroll is in the
          middle of a tile.

        - ``CityMapDrawTerrainTile`` and ``CityMapDrawTerrainTileAddress`` :
          Draw a terrain tile at the specified coordinates or address
          respectively (not used for buildings). Sets tile, attributes and type.
          It also clears all tile flags to make the previous simulation state
          invalid.

        - ``CityMapCheckBuildBridge`` : Checks if a bridge of a certain type can
          be built. For that to be possible the coordinates must point at a
          water tile next to the ground, but with only one tile of ground
          surrounding it (or 2 at two opposite sides). It cannot leave the map
          (the bridge must end inside of the map). It returns the length of the
          bridge that could be built there.

        - ``CityMapBuildBridge`` : Builds a bridge of the specified type from
          the given starting point until the water ends. It doesn't do any
          special checking, so ``CityMapCheckBuildBridge`` should have been
          called before.

    - Demolishing functions:

        - ``DrawCityDeleteBridgeForce`` : Deletes a bridge and refreshes the
          tiles at both ends so that they update their drawings to disconnect
          them from the bridge. It is assumed that it is called with the
          coordinates of any of the tiles of a bridge, and it removes the
          complete bridge without checking for money or play SFX.

        - ``DrawCityDeleteBridgeWithCheck`` : Same as above, but it checks the
          funds to see if there is money to demolish the bridge and plays SFX if
          it is actually demolished.
