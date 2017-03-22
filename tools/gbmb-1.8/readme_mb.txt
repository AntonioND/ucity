                          Gameboy Map Builder

                             Version 1.8

                         Release date: 2-10-99

                       Copyright H. Mulder 1999

DESCRIPTION:
------------
You can use the Gameboy Map Builder ("GBMB") to design maps for your own
Gameboy productions.


DISCLAIMER:
-----------
The Gameboy Map Builder is Freeware; you are allowed to use it in any way 
you want, without paying me anything. The only thing I want in return are 
bug-reports and enhancement-requests, which can be mailed to 
hpmulder@casema.net.

You are also allowed (and encouraged) to distribute this software, as long
as you don't receive any payment for it. If you want to link your home page
to GBMB, be sure to link it to the main site, not directly to the file, as 
updates will receive different filenames.

Keep in mind that you use this software at your own risk; any damage which 
might occur, in whatever form, is your own responsibility.


TO INSTALL:
-----------
  Start GBMB.EXE (That's generally it).

  For maximum enjoyment, make sure all accompanied files are in the same
  directory as GBMB.EXE. Also, associate .GBM-files to GBMB; next to loading
  GBMB when you select a .GBM-file, GBMB will also start adding these files
  to your Documents-menu when this association exists. Adding GBMB.EXE to
  your start-bar or desktop might also simplify things.


CONTACT INFO:
-------------
  You can get the latest version and info about GBMB from www-site:

    http://www.casema.net/~hpmulder

  I can be contacted though E-Mail at: hpmulder@casema.net


HISTORY:
--------

  Version:      Date:            Description:

     1.8        2 October 1999   NEW! each location can have its own palette
                                 Fix: 'Copy as Bitmap' works for SGB colorsets
                                 Note:Copy/paste format changed due to location-palettes

     1.7        28 August 1999   NO$GMB Filter is now optional (under "Color set")
                                 Added various hotkeys
                                 Fix: C-export corrected when splitting data
                                 Fixed usage of relative paths for GBR-files:
                                 -Killed off AVs
                                 -Auto Update now works for them
                                 -Some other minor glitches

      1.6       13 August 1999   'Win9X cleanup':
                                 Fix: Copy/Paste finally works
                                 Fix: Much less system drag
                                 Fix: Saved tilesets now directly updated

                                 Note that I use NT4 myself, so if you see
                                 technical problems on the Win9X-platform,
                                 mail me. I will try to handle these problems
                                 more swiftly in the future.

      1.5       6 August 1999    NO$GMB GBC color filter (thanks to Martin)
                                 Fix: #512> tiles are saved correctly
                                 Fix: Only last Paste is Undone

      1.4       13 June 1999     Fix: Copy as Bitmap works again
                                 Fix: large Pastes are undone correctly

      1.3       24 May 1999      Auto update! (see HLP for info)
                                 768 tile-support
                                 Fix: Ver/Hor flip are shown correctly
                                 Tile Copy/Paste tweaked
                                 MouseWheel support

      1.2       21 March 1999    Export: Tile offset added
                                 Block Fill: new patterns added
                                 Relative filepath support (Export, Tileset)
                                 Cleaned up Clipboard:
                                 - Tile Paste bug fixed
                                 - Property Copy bug fixed
                                 - V & H-Flip are now copied
                                 - Format changed; see HLP

      1.1       23 January 1999  New: ISAS export-format
                                 New: Bank constant generated in export
                                 Fix: Possible AV when opening tilefiles
                                 Fix: GBDK format error
                                 Fix: GUI-settings not always saved
                                 Fix: Zoom wrong in new file

      1.0       17 January 1999  Larger maps (1024 x 1024)
                                 More properties (32)
                                 Less memory usage (new mem-handling)
                                 Build-in vert/hor flip for GBC
                                 More predefined export properties
                                 New info-panel
                                 Export: 'Split' for >16K maps
                                 512 tiles support

---------------------------------------------------------------------------
NOTE: As of version 1.0, a new file-format is used. Download GBMB Converter
      from my page to convert older files to the new format.
---------------------------------------------------------------------------

      0.9       29 November 1998 Gameboy Color support

      0.8       30 August 1998   New feature: Property colors
                                 New feature: Copy as bitmap

      0.7       22 August 1998   Fixed SGB/GB palette behaviour
                                 New drawtool: Dropper
                                 New zoom: 25%
                                 Faster screen-draws
                                 Fixed: Maximized forms saved incorrectly

      0.6       27 July 1998     Super Gameboy support
                                 New Export-setting: Map layout
                                 Fixed 0.5 plane export-output

      0.5       5 june 1998      New: Block selection
                                 NOTE: The following functions have changed 
                                 due to Block selection; see HLP for new 
                                 behaviour.
                                   Mouse buttons (!!)
                                   Block Fill
                                   Info Panel
                                 Cut/Copy/Paste implemented.
                                 Selection-visibility increased.
                                 Space bar fills current selection with 
                                 selected tile.

      0.4       22 May 1998      New feature: Grid.
                                 New feature: Double markers.
                                 Undo for Insert/Delete Row/Column.
                                 Undo less sensitive.
                                 Scrollbars move a page.
                                 Cleaner GUI when loading.
                                 Fixed: Some settings were not saved.

      0.3       17 May 1998      Tileset automatically reloaded when changed.
                                 (Partial) Undo implemented.
                                 New feature: Block fill.
                                 Cleaned up GBDK C export.

      0.2       2 May 1998       Faster screen-updates.
                                 Infopanel-input friendlier.
                                 'Clear map' added.
                                 'Color set' added.
                                 [Ctrl]-cursorkeys move the map.
                                 Defaults can be set in GBMB.INI.
                                 Bug fix: Export filename not always 
                                          shown correctly.
                                 Bug fix: RGBDS Obj could not export 
                                          to bank 0.
                                 Bug fix: Didn't use tileset palette.
                                 Various GUI tweaks.

      0.1       25 April 1998    Initial release.

