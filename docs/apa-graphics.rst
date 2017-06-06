=============================
All Points Addressable Graphs
=============================

As the Game Boy Color doesn't have any bitmap modes, it is needed to implement
it by software. This mode is used when drawing minimaps and graphs showing the
evolution of something over time. Note that the buffer can be either 64x64 or
128x128 pixels in size. There is no 160x144 mode.

The code is located in:

- ``source/apa.asm`` : Implementation of the routines needed to plot pixels.
  The functions allow to plot individual pixels in the buffer, but this system
  is quite slow, so there are also functions to stream pixels (from left to
  right and top to bottom), which is a lot faster if the final image is known
  beforehand.

- ``source/apa.inc`` : Some definitions related to the implementation.

Usage guide
===========

All functions work on a temporary buffer at address ``MINIMAP_BACKBUFFER_BASE``
in ``WRAMX`` bank ``MINIMAP_BACKBUFFER_WRAMX_BANK`` which is used as backbuffer
so as not to show graphical glitches while drawing. This buffer is then copied
to tiles 128-383 of ``VRAM`` bank 1.

The first thing to do is to prepare the map with ``APA_ResetBackgroundMapping``
if needed, it fills a 16x16 block of tiles with the correct indexes and
attributes. The alternative is to design your map with the same values.

At some point it is needed to load the palette with ``APA_LoadPalette``. It can
be done before drawing the map, after doing it, or it can be set to black/white
before drawing and set to the real colors when the image is drawn.

Then, unless all pixels are going to be drawn, it is needed to clear the map
with ``APA_BufferClear`` or ``APA_BufferFillColor3``. It may be a good idea to
update the visualization with ``APA_BufferUpdate`` at this point, unless showing
the previous image isn't a problem.

Then, depending on the type of drawing, there are two options:

- If the image consists on just a few points around the picture, ``APA_Plot`` is
  probably the fastest way to do it. With it, it is possible to plot individual
  pixels in the map. It only works in 128x128 maps, though.

- If all the pixels are going to be redrawn, it is possible to stream pixels in
  rows (left to right, top to bottom). For that, ``APA_PixelStreamStart`` has to
  be called at the beginning. Then, if the map is 128x128, it is possible to
  draw 2x2 pixel blocks with ``APA_PixelStreamPlot2x2`` (so the effective
  resolution is 64x64). If the map is 64x64, ``APA_64x64PixelStreamPlot`` can be
  used instead.

Note that the plot functions don't accept a color as an argument. For functions
``APA_Plot`` and ``APA_64x64PixelStreamPlot`` the correct function is
``APA_SetColor0``, which sets the color that is going to be used from that
moment on. For ``APA_PixelStreamPlot2x2``, ``APA_SetColors`` sets the color of
each one of the 4 pixels that are drawn at once (top left, top right, bottom
left, bottom right).

Once the image is drawn, ``APA_BufferUpdate`` will copy it from the temporary
buffer to ``VRAM``.

Examples
========

This mode is used by the following files:

- ``source/room_gen_map/gen_map.asm`` : 64x64 minimap shown when generating
  random maps. It uses a pixel stream to draw the minimap.

- ``source/room_scenarios/room_scenarios.asm`` : 64x64 minimap shown when
  selecting scenarios. Same as the previous example, pixel stream.

- ``source/room_minimap/minimap_***.asm`` : 128x128 minimaps shown in-game from
  the pause menu (zones, traffic, population density, etc). It uses a pixel
  stream of 2x2 blocks. Note that the map doesn't have the correct values to
  display the final image, so ``APA_ResetBackgroundMapping`` is used (in
  ``source/room_minimap/room_minimap.asm``).

- ``source/room_graphs/graph_***.asm`` : 128x128 graphs shown in-game (funds,
  population, etc). In this case, ``APA_Plot`` is used, as most of the image is
  left blank.
