SHELL = /bin/sh

# ======================================================================
# Makefile for VCTitleCase test
# ======================================================================


# Project Variables
# -----------------

# Name of output file
OUTFILE = test_titles

# Intermediate objects required for output file
OBJECTS = test_titles.o VCTitleCase.o


# ======================================================================


# Compiler Setup
# --------------

# Use built-in compiler
CC = cc

# Show all warnings
WARNINGS = -Wall

# Framework linking shortcuts
FOUNDATION = -framework Foundation


# ======================================================================


# Custom Objective-C Build Process Setup
# --------------------------------------

# Location for intermediate object files
OBJECT_DIR = build/intermediates

# Location for dependency list files
DEPENDS_DIR = build/dependencies

# Location for final output file
OUTPUT_DIR = build

# Include these directories in the dependency search path
vpath %.o ${OBJECT_DIR}
vpath %.d ${DEPENDS_DIR}
vpath %   ${OUTPUT_DIR}

# Create list of objects with intermediate directory prefix
OBJECTS_FULL = ${OBJECTS:%=${OBJECT_DIR}/%}

# Create list of dependency list files for objects
DEPENDS = ${OBJECTS:%.o=%.d}

# Create list of dependency list files with directory prefix
DEPENDS_FULL = ${OBJECTS:%.o=${DEPENDS_DIR}/%.d}

# Clear and set up auto-compile suffixes
.SUFFIXES:
.SUFFIXES: .o .d

# Define compilation rule for Objective-C files.
# Missing object files are compiled from .m files and
# placed in the intermediate object directory.
%.o : %.m
	@mkdir -p ${OBJECT_DIR}
	${CC} -c ${CFLAGS} ${CPPFLAGS} ${WARNINGS} -o ${OBJECT_DIR}/$@ $<

# Define compilation rule for dependency files.
# Missing dependency list files are created from .m files
# and placed in the dependency directory.  The sed command
# causes a .d file to be required for each dependency as
# well, so that every source file has an auto-generated
# .d file.
${DEPENDS_DIR}/%.d : %.m
	@mkdir -p ${DEPENDS_DIR}
	@echo Generating dependency list for $*.m...
	@set -e; \
	    ${CC} -MM ${CPPFLAGS} $< | \
		sed 's/\($*\)\.o[ :]*/\1.o $*.d : /g' > $@; \
		[ -s $@ ] || rm -f $@


# ======================================================================


# Targets
# -------

all : ${OUTFILE}

${OUTFILE} : ${OBJECTS}
	${CC} ${WARNINGS} ${FOUNDATION} ${OBJECTS_FULL} -o ${OUTPUT_DIR}/${OUTFILE}

include ${DEPENDS_FULL}

.PHONY: clean
clean:
	rm ${OBJECTS_FULL}
	rm ${DEPENDS_FULL}
	rm ${OUTPUT_DIR}/${OUTFILE}
	rmdir ${OBJECT_DIR}
	rmdir ${DEPENDS_DIR}
	rmdir ${OUTPUT_DIR}

