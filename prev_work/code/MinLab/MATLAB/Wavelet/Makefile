MATLABARCH	=	maci
MATLABPATH	=	/Applications/MATLAB_R2009a.app
MATLABLIBS	=	-L$(MATLABPATH)/bin/$(MATLABARCH) -leng -lmx
MATLABINC	=	-I$(MATLABPATH)/extern/include

MFILE		=	m			#m-file의 확장자
LOGFILE		=	$(TARGET).log
MATLAB		=	matlab
OPTS		=	-nodisplay -nosplash -nodesktop -logfile $(LOGFILE) -r

TARGET		=	c_wavelet_EXP_AmH

#cmd type
all:
	$(MATLAB) $(OPTS) $(TARGET)

#gui type
gui:
	$(MATLAB)
