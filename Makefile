################################################################################
#
#    µCity - City building game for Game Boy Color.
#    Copyright (c) 2017-2019 Antonio Niño Díaz (AntonioND/SkyLyrac)
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

NAME := ucity
EXT  := gbc

################################################################################
##               Command to run resulting ROM in an emulator                  ##

EMULATOR := wine ./tools/bgb.exe

################################################################################
##         Source, data and include folders - subfolders are included         ##

SOURCE := source data

################################################################################

# RGBDS can be made to point at a specific folder with the binaries of RGBDS.

RGBASM  := $(RGBDS)rgbasm
RGBLINK := $(RGBDS)rgblink
RGBFIX  := $(RGBDS)rgbfix

BIN := $(NAME).$(EXT)
COMPAT_BIN := $(NAME)_compat.$(EXT)

# List of relative paths to all folders and subfolders with code or data.
SOURCE_ALL_DIRS := $(sort $(shell find $(SOURCE) -type d -print))

# All files with extension asm are assembled.
ASMFILES := $(foreach dir,$(SOURCE_ALL_DIRS),$(sort $(wildcard $(dir)/*.asm)))

# List of include directories: All source and data folders.
# A '/' is appended to the path.
INCLUDES := $(foreach dir,$(SOURCE_ALL_DIRS),-I$(dir)/)

# Prepare object paths from source files.
OBJ := $(ASMFILES:.asm=.obj)

# Targets
.PHONY : all rebuild clean run

all: $(BIN) $(COMPAT_BIN)

rebuild:
	@make -B
	@rm -f $(OBJ)

run: $(BIN)
	$(EMULATOR) $(BIN)

clean:
	@echo rm $(OBJ) $(BIN) $(COMPAT_BIN) $(NAME).sym $(NAME).map
	@rm -f $(OBJ) $(BIN) $(COMPAT_BIN) $(NAME).sym $(NAME).map

%.obj : %.asm
	@echo rgbasm $<
	@$(RGBASM) $(INCLUDES) -E -Wall -o$@ $<

$(BIN): $(OBJ)
	@echo rgblink $(BIN)
	@$(RGBLINK) -o $(BIN) -p 0xFF -m $(NAME).map -n $(NAME).sym $(OBJ)
	@echo rgbfix $(BIN)
	@$(RGBFIX) -p 0xFF -v $(BIN)

$(COMPAT_BIN): $(BIN)
	@echo rgbfix $(COMPAT_BIN)
	@cp $(BIN) $(COMPAT_BIN)
	@$(RGBFIX) -v -O -r 3 $(COMPAT_BIN)

################################################################################
