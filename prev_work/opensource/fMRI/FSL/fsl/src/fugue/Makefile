# $Id: Makefile,v 1.43 2008/03/26 10:09:36 mark Exp $
include ${FSLCONFDIR}/default.mk

PROJNAME = fugue

USRINCFLAGS = -I${INC_NEWMAT} -I${INC_BOOST} -I${INC_ZLIB}
USRLDFLAGS = -L${LIB_NEWMAT} -L${LIB_ZLIB}

LIBS=-lwarpfns -lbasisfield -lmeshclass -lnewimage -lmiscmaths -lprob -lfslio -lniftiio -lznz -lnewmat -lutils -lz

PRELUDEOBJS=prelude.o unwarpfns.o
FUGUEOBJS=fugue.o unwarpfns.o
APPLYOBJS=applywarp.o
CONVERTOBJS=convertwarp.o
IOBJS=invwarp.o unwarpfns.o
I2OBJS=interpwarp.o unwarpfns.o
SOBJS=sigloss.o
FNIRTFILEUTILSOBJS=fnirtfileutils.o

XFILES=prelude fugue applywarp convertwarp sigloss invwarp fnirtfileutils
SCRIPTS=extractfidparams dof2warp
FSCRIPTS=fmrib_prepare_fieldmap fix_OCMR_fieldmaps
TESTXFILES=interpwarp

all: ${XFILES}

prelude: ${PRELUDEOBJS}
	${CXX} ${CXXFLAGS} ${LDFLAGS} -o $@ ${PRELUDEOBJS} ${LIBS} 

fugue:  ${FUGUEOBJS}
	${CXX} ${CXXFLAGS} ${LDFLAGS} -o $@ ${FUGUEOBJS} ${LIBS} 

applywarp:  ${APPLYOBJS}
	${CXX} ${CXXFLAGS} ${LDFLAGS} -o $@ ${APPLYOBJS} ${LIBS} 

convertwarp:  ${CONVERTOBJS}
	${CXX} ${CXXFLAGS} ${LDFLAGS} -o $@ ${CONVERTOBJS} ${LIBS} 

invwarp: ${IOBJS}
	${CXX} ${CXXFLAGS} ${LDFLAGS} -o $@ ${IOBJS} ${LIBS} 

interpwarp: ${I2OBJS}
	${CXX} ${CXXFLAGS} ${LDFLAGS} -o $@ ${I2OBJS} ${LIBS} 

sigloss: ${SOBJS}
	${CXX} ${CXXFLAGS} ${LDFLAGS} -o $@ ${SOBJS} ${LIBS} 

fnirtfileutils: ${FNIRTFILEUTILSOBJS}
	${CXX} ${CXXFLAGS} ${LDFLAGS} -o $@ ${FNIRTFILEUTILSOBJS} ${LIBS} 
