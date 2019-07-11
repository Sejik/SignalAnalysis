# $Id: Makefile,v 1.4 2008/11/26 13:25:48 mwebster Exp $
include ${FSLCONFDIR}/default.mk

PROJNAME = MVdisc

USRINCFLAGS = -I${INC_NEWMAT} -I${INC_ZLIB}
USRLDFLAGS = -L${LIB_NEWMAT}  -L${LIB_ZLIB} 

LIBS= -lfslvtkio -lmeshclass -lnewimage -lmiscmaths -lfslio -lniftiio -lznz -lnewmat -lutils -lz

SHAPEOBJS=MVdisc.o
 
MODELOBJS=MVdisc.o

DBGFLAGS=-g
ARCHLDFLAGS=
ARCHFLAGS=

all: MVdisc.a 

MVdisc.a: ${SHAPEOBJS}
	${AR} -r libMVdisc.a ${SHAPEOBJS}




