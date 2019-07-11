MATLABARCH	=	maci
MATLABPATH	=	/Applications/MATLAB_R2009a.app
MATLABLIBS	=	-L$(MATLABPATH)/bin/$(MATLABARCH) -leng -lmx
MATLABINC	=	-I$(MATLABPATH)/extern/include

MFILE		=	m			#m-file의 확장자
LOGFILE		=	matlab.log
MATLAB		=	matlab
OPTS		=	-nodisplay -nosplash -nodesktop -logfile $(LOGFILE) -r

TARGET		=	f_phase_AmH

#cmd type
all:
	@echo -e "You must be append a string '/home/minlab/MATLAB/PLV4SKK' to <UserPath>@~/.matlab/R2015a/matlab.settings"
	@echo -e "For details, please read a <CAUTION> scription on 'A_globals_AmH.m'\n"
	$(MATLAB) $(OPTS) $(TARGET)

#gui type
gui:
	$(MATLAB)
