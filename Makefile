################################################################################
#
#    µCity - City building game for Game Boy Color.
#    Copyright (C) 2017 Antonio Niño Díaz (AntonioND/SkyLyrac)
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################
##                                ROM name                                    ##

NAME = ucity
EXT  = gbc

################################################################################
##                         Path to RGBDS binaries                             ##

RGBDS   = ..

################################################################################
##               Command to run resulting ROM in an emulator                  ##

EMULATOR = wine ./tools/bgb.exe

################################################################################
##         Source, data and include folders - subfolders are included         ##

SOURCE = source data

################################################################################

RGBASM  = $(RGBDS)/rgbasm
RGBLINK = $(RGBDS)/rgblink
RGBFIX  = $(RGBDS)/rgbfix

BIN := $(NAME).$(EXT)

# List of relative paths to all folders and subfolders with code or data.
SOURCE_ALL_DIRS := $(shell find $(SOURCE) -type d -print)

# All files with extension asm are assembled.
ASMFILES := $(foreach dir,$(SOURCE_ALL_DIRS),$(wildcard $(dir)/*.asm))

# List of include directories: All source and data folders.
# A '/' is appended to the path.
INCLUDES := $(foreach dir,$(SOURCE_ALL_DIRS),-i$(CURDIR)/$(dir)/)

# Prepare object paths from source files.
OBJ = $(ASMFILES:.asm=.obj)

# Targets
.PHONY : all rebuild clean run

all: $(BIN)

rebuild:
	@make -B
	@rm -f $(OBJ)

run: $(BIN)
	$(EMULATOR) $(BIN)

clean:
	@echo rm $(OBJ) $(BIN) $(NAME).sym $(NAME).map
	@rm -f $(OBJ) $(BIN) $(NAME).sym $(NAME).map

%.obj : %.asm
	@echo rgbasm $<
	@$(RGBASM) $(INCLUDES) -E -o$@ $<

$(BIN): $(OBJ)
	@echo rgblink $(BIN)
	@$(RGBLINK) -o $(BIN) -p 0xFF -m $(NAME).map -n $(NAME).sym $(OBJ)
	@echo rgbfix $(BIN)
	@$(RGBFIX) -p 0xFF -v $(BIN)

################################################################################
