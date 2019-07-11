function [gamma2] = DTFsigtest2(gamma2,gamma2_sig)
% DTFsigtest() 대비 평균 10배 빠른 연산 속도

% Generate the significant cut-off
gamma2( gamma2 < gamma2_sig )	=	0;
EYE								=	eye(size(gamma2,1));		% gen I matrix
EYE								=	repmat(~EYE, 1, 1, size(gamma2,3)); % 3D
gamma2							=	gamma2 .* EYE;				% clear diagonal
