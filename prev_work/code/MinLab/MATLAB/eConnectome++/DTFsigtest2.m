%% DTFsigtest2 ver 0.10
%
% License
% ==============================================================
% This program is part of the mLib by minlab tools.
% 
% Copyright (C) 2015 MinLAB. of the University of Korea. All rights reserved.
% Correspondence: tigoum@korea.ac.kr
% Web: mindbrain.korea.ac.kr
%
% ==============================================================================
% Revision Logs
% ------------------------------------------------------
% Program Editor, not Author: Ahn Min-Hee @ tigoum, University of Korean, KOREA
% User feedback welcome: e-mail::tigoum@korea.ac.kr
% ......................................................
% first created at 2016/06/27
% last  updated at 2016/06/27
% ......................................................
% Release Version 0.10 beta
% Ver 0.10 : DTFsigtest() 대비 평균 10배 빠른 연산 속도
% ==============================================================================

function [gamma2] = DTFsigtest2(gamma2,gamma2_sig)

% Generate the significant cut-off
gamma2( gamma2 < gamma2_sig )	=	0;
EYE								=	eye(size(gamma2,1));		% gen I matrix
EYE								=	repmat(~EYE, 1, 1, size(gamma2,3)); % 3D
gamma2							=	gamma2 .* EYE;				% clear diagonal
