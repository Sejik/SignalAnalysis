# $Id: systemvars.mk,v 1.3 2007/07/13 11:00:21 duncan Exp $

# System dependent paths

RM = /bin/rm
CHMOD = /bin/chmod
MKDIR = /bin/mkdir
CP = /bin/cp
MV = /bin/mv
INSTALL = install -p
TCLSH = ${FSLDIR}/bin/fsltclsh
RANLIB = echo

FSLML = ${FSLDIR}/bin/fslml

# for SHELL, do not change the type of shell - only use Bourne or BASH
SHELL = /bin/sh

# Compiler dependent variables

CC = gcc
CXX = c++
CSTATICFLAGS = -static
CXXSTATICFLAGS = -static

ARCHFLAGS = -march=pentium -mtune=pentium

DEPENDFLAGS = -MM

OPTFLAGS = -O3 -fexpensive-optimizations ${ARCHFLAGS}
MACHDBGFLAGS = -g
GNU_ANSI_FLAGS = -Wall -ansi -pedantic
SGI_ANSI_FLAGS = -ansi -fullwarn
ANSI_FLAGS = ${GNU_ANSI_FLAGS}

