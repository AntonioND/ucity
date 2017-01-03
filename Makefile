################################################################################
#
#    BitCity - City building game for Game Boy Color.
#    Copyright (C) 2016 Antonio Nino Diaz (AntonioND/SkyLyrac)
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
##                                ROM NAME                                    ##

NAME = bitcity
EXT  = gbc

##                                                                            ##
################################################################################

################################################################################
##                         PATH TO RGBDS BINARIES                             ##

RGBASM  = ../rgbasm
RGBLINK = ../rgblink
RGBFIX  = ../rgbfix
EMULATOR = wine ./tools/bgb.exe

##                                                                            ##
################################################################################

################################################################################
##              Source and include folders - includes subfolders              ##

SOURCE = ./source ./data

##                                                                            ##
################################################################################

BIN := $(NAME).$(EXT)

SOURCE_ALL_DIRS_REL := $(shell find $(SOURCE) -type d -print)
SOURCE_ALL_DIRS_ABS := $(foreach dir,$(SOURCE_ALL_DIRS_REL),$(CURDIR)/$(dir))

ASMFILES := $(foreach dir,$(SOURCE_ALL_DIRS_ABS),$(wildcard $(dir)/*.asm))

# Make it include all source folders - Add a '/' at the end of the path
INCLUDES := $(foreach dir,$(SOURCE_ALL_DIRS_REL),-i$(CURDIR)/$(dir)/)

# Prepare object paths
OBJ = $(ASMFILES:.asm=.obj)

# Targets
.PHONY : all rebuild clean run

all: $(BIN)

rebuild:
	@make clean
	@make
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
