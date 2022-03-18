#
#  makefile
# ----------------------------------------------- part of the maskarray package
#
#  makefile for assisted maskarray package installation.
#
#  Usecases:
#    - install package system-wide on your machine (needs su privileges)
#        EXAMPLE:        'make install'
#
#    - install package for your local user only (no privileges needed)
#        EXAMPLE:        'make install MODE=--user'
#
#    - compile all cython source files locally
#        EXAMPLE:        'make compile'
#
#    - debug the package by running an interactive session after compiling
#        EXAMPLE:        'make debug'
#
#    - compile documentation with benchmarks on your machine
#        EXAMPLE:        'make doc [OPTIONS=...]'
#        NOTE: This command uses the local default python version or the one
#              specified via the `PYTHON=` switch.
#
#  Author      : Christoph Wagner
#  Introduced  : 2016-07-06
#------------------------------------------------------------------------------
#
#  Copyright 2018 Christoph Wagner
#      https://www.tu-ilmenau.de/it-ems/
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#------------------------------------------------------------------------------

# default: Cancel with a warning as a specific target selection is required.
.PHONY: default
default: .warning

################################################################################
###  PLATFORM SPECIFIC DEFINITIONS
################################################################################

ifeq ($(OS),Windows_NT)
RM=del /F
RMR=deltree
PSEP=$(strip \)
else
RM=rm -f
RMR=rm -rf
PSEP=/
endif


################################################################################
###  LOCAL VARIABLES (user-defined in case needed)
################################################################################

# MODE may be specified from command line for choosing install mode.

# python version
PYTHON=python

ifeq ($(OS),Windows_NT)
else

# STYLE_FILES specifies the files touched during coding style operations
STYLE_FILES=*.py maskarray/*.py maskarray/*.pyx maskarray/*.pxd maskarray/*.h

# STYLE_IGNORES lists the errors to be skipped during style check
STYLE_IGNORES=E26,E116,E203,E221,E222,E225,E227,E241,E402,E731,W504,W605

# TEST_OPTIONS allows passing extra options to tests during `testCode`target
TEST_OPTIONS=-i

# CODEBASE_FILES lists all source code files in codebase
CODEBASE_FILES:=$(shell find ${CURDIR}\
		-name ".*" -prune\
		-o -name '*.py' -o -name '*.pyx' -o -name '*.pxd' -o -name '*.h'\
		-o -name 'makefile'\
	| $(PYTHON) -c 'import sys; print(" ".join([s.strip()\
		for s in sys.stdin.readlines() if "output" not in s]))')
endif

################################################################################
###  BUILD TARGETS
################################################################################

# target 'install': Install fastmat.
.PHONY: install
install:
	$(info * installing ...)
	$(info * using special mode: $(MODE))
	$(PYTHON) setup.py install $(MODE)


# target 'compile': Comile fastmat package locally.
.PHONY: compile
compile:
	$(info * compiling package locally)
	$(PYTHON) setup.py build_ext --inplace

.PHONY: compile-coverage
compile-coverage:
	$(info * compiling  package locally, with profiling and tracing)
	$(PYTHON) setup.py build_ext --inplace --enable-cython-tracing


# target 'doc': Compile documentation
.PHONY: doc
doc: | compile
	$(info * building documentation)
	@$(PYTHON) setup.py build_doc $(OPTIONS) -E

# targer 'debug': Debug package
.PHONY: debug
debug: | compile
	$(info * debugging package)
	$(PYTHON) -i -c '\
		from numpy import *;\
		from maskarray import *;\
		'


# target 'all': Compile everything (code, documentation and run tests)
.PHONY: all
all: | compile doc


################################################################################
###  LINUX-ONLY BUILD TARGETS
################################################################################

ifeq ($(OS),Windows_NT)
else
# target 'styleCheck': Perform a style check for all python code files
.PHONY: styleCheck
styleCheck:
	$(info * running PEP8 code style check (excluding $(STYLE_IGNORES)))
	@pycodestyle --max-line-length=80 --statistics --count\
		--ignore=$(STYLE_IGNORES) $(STYLE_FILES)


# target 'codeStats': Print statistics about the codebase
.PHONY: codeStats
codeStats:
	$(info * LOC & SIZE for source files in codebase)
	$(info * ---------------------------------------)
	@wc -l -c $(CODEBASE_FILES)
endif


################################################################################
###  INTERNAL BUILD TARGETS
################################################################################

# target 'warning': Print warning and exit.
.PHONY: .warning
.warning:
	$(info * WARNING: no makefile target specified. Abort.)
	$(info * valid targets are: install uninstall)
