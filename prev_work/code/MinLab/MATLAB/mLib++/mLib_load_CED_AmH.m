%function [ ch_num ] = ChConv_Name2Number(channame, CED)
function [ number labels ]	=	mLib_load_CED_AmH(CED);	% CED 에서 chan 목록 수집
% Number	labels	type	theta	radius	X	Y	Z	sph_theta	sph_phi	sph_radius	urchan	ref	datachan	
%% CED 파일을 읽어서 채널정보를 구성함.
	% CED	: topo를 위한 CED 파일 path, [ 절대경로 | 상대경로 | 파일명 only ]
	%		ex) 파일명만 표기시 탐색순서: ./ , ~minlab/Tools/MATLAB/

	%% Loading Experimental Info in VHDR file
		%그래서 [Common Infos]의 nCH, SpI, SDP 읽을 것
		%SpI : 샘플링 간격(sampling rate의 역수), 시간단위는 uS
		%SDP : epocking된 data수	= 시간범위/SpI(단위 일치 요망)
		%EpTm: epocking된 시간범위	= SDP * SpI(단위일치요망)
		%Smpl: 샘플링율				= 1 / SpI
%	fVhdr		=	regexprep(fullPATH, '.[A-Za-z]*$', '.vhdr');
	eval(['Fp	=	fopen(''' CED ''',''r'');']);
%	if Fp < 0, ChanList = []; SDP = 0; fSmpl = 0; return; end
	lCED		=	textscan(Fp, '%s', 'delimiter', '\n');	%cell array
	%white-space를 문자열의 일부로 인식하도록 delimiter  설정함
	fclose(Fp);

	% 라인 단위로 분할 후, 각 라인에서도 [tab] 단위로 분할
	Header		=	lCED{1}(1);
	lCED		=	lCED{1}(2:end);
	lChan		=	cellfun(@(x)({strsplit(x,'\t')}), lCED);	% cell의 array

	number		=	str2num(char(cellfun(@(x)( x(1) ), lChan)));
	labels		=	cellfun(@(x)( x(2) ), lChan);

	return

