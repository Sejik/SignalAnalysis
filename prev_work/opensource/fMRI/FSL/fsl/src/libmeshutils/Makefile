# $Id: Makefile,v 1.12 2009/03/24 11:55:17 mwebster Exp $
include ${FSLCONFDIR}/default.mk

PROJNAME = meshUtils

LD_LIBRARY_PATH=${FSLDIR}/lib

USRINCFLAGS = -I${INC_NEWMAT} -I${INC_ZLIB} -I${INC_PROB} -I${INC_BOOST} 
USRLDFLAGS =  -L${LIB_PROB} 

ifneq ($(strip $(VTKDIR_INC)),)
	USRINCFLAGS+=-I${VTKDIR_INC}
endif

ifneq ($(strip $(VTKDIR_LIB)),)
        LIBS+=-L${VTKDIR_LIB}
endif

LIBS+=--L${LIB_NEWMAT} -L${LIB_ZLIB} -L${FSLDIR}/lib 

LIBS+=-lwarpfns -lbasisfield -lfslvtkio -lMVdisc

ifneq ($(strip $(VTKDIR_LIB)),)
        LIBS+=-lfslvtkconv 
endif

LIBS+=-lfirst_lib -lmeshclass -lnewimage -lmiscmaths -lprob -lfslio -lniftiio -lznz -lutils -lnewmat  -lz

LIBrun=-lmeshUtils ${LIBS}

ARCHFLAGS =
ARCHLDFLAGS =

SWOBJS=meshUtils.o
XFILES= run_mesh_utils


SCRIPTS = 

all: meshUtils.a ${XFILES}

meshUtils.a: ${SWOBJS} 
	${AR} -r libmeshUtils.a  ${SWOBJS} 

run_mesh_utils: run_mesh_utils.o
	${CXX} ${CXXFLAGS} ${LDFLAGS} -o $@  run_mesh_utils.o ${LIBrun}


