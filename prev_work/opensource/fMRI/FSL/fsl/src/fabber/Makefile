include ${FSLCONFDIR}/default.mk

PROJNAME = fabber

USRINCFLAGS = -I${INC_NEWMAT} -I${INC_PROB} -I${BOOSTDIR}
USRLDFLAGS = -L${LIB_NEWMAT} -L${LIB_PROB}

LIBS = -lutils -lnewimage -lmiscmaths -lprob -lnewmat -lfslio -lniftiio -lznz -lz 

XFILES = fabber mvntool



OBJS = fwdmodel_flobs.o tools.o fwdmodel_q2tips.o inference_spatialvb.o dataset.o inference_vb.o noisemodel.o noisemodel_white.o fwdmodel_quipss2.o fwdmodel.o fwdmodel_simple.o fwdmodel_linear.o noisemodel_ar.o inference.o dist_mvn.o easylog.o easyoptions.o fwdmodel_asl_grase.o fwdmodel_asl_buxton.o inference_nlls.o fwdmodel_dsc.o


# For debugging:
OPTFLAGS = -ggdb
#OPTFLAGS =

all:	${XFILES}

fabber: ${OBJS} fabber.o
	${CXX}  ${CXXFLAGS} ${LDFLAGS} -o $@ ${OBJS} fabber.o ${LIBS}

mvntool: ${OBJS} mvntool.o
	${CXX}  ${CXXFLAGS} ${LDFLAGS} -o $@ ${OBJS} mvntool.o ${LIBS}

SCRIPTS = fabber_var

# DO NOT DELETE
