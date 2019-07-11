%function [ ]	=	AmHlib_topoplot_pairs(Potn1D, MaxVal, MaxTp, MaxCh, JPG)
function [] = AmHlib_topoplot_alone(Potn2D, tRng,tWin, MaxFq,MaxTp,MaxCh, JPG)
	%% 단일 채널 단위로 에너지를 표기해 줌
	% Potn2D : timepoint * ch 의 2차원 데이터
	% tRng=[start:step:end] : 시작시점 ~ 끝까지 범위
	% tWin=[x1:step:x2] : time window
	% MaxTp : Potn2D(?,:) 에서 MaxTp timpoint 위치에 최대값 있음
	% MaxCh : Potn2D(:,?) 에서 MaxCh 위치에 최대값 있음
	% JPG : 저장할 이미지의 파일 이름

if isnumeric(MaxFq)									%주파수 정보는 문자열로 변환
	sMaxFq		=	sprintf('%4.1f Hz', MaxFq);
elseif isstr(MaxFq)
	sMaxFq		=	MaxFq;
else
	sMaxFq		=	'Unknown';
	fprintf('\nWarning : did not specified the frequency info.');
end

%% Header %%
global	SRC_NAME;
global	NUMWORKERS;			%define global var for parallel tool box!!
global	WORKNAME;

%A_globals_AmH();%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@
%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki, cedPATH	]	=	A_globals_AmH();

%% 20151025A. 우선 ced 파일의 채널수와 Potn2D 의 채널수가 일치하는지 점검
	% ced 파일을 읽어서 목록을 파악하자.
	fCED		=	fopen(cedPATH{1}, 'r');
%	fprintf('Generating VHDR file to %s\n', fvhdr);

	lCED		=	textscan(fCED, '%s', 'delimiter', '');	%cell array
	fclose(fCED);
	nLine		=	size(lCED{1},1);						%전체 라인 수
	lLine		=	strsplit(lCED{1}{nLine}, '\t');			%마지막 라인 분리
	nChan		=	str2double(lLine(1));					%채널 수 최대값

	if nLine-1 ~= size(Potn2D, 2)
		fprintf('\nErrors  : # of Ch. loss for CED(%d) : Data(%d)\n',		...
				nLine-1, size(Potn2D, 2));
	elseif nChan ~= size(Potn2D, 2)
		fprintf('\nErrors  : Ch. ID mismatch for CED(%d) : Data(%d)\n',		...
				nChan, size(Potn2D, 2));
	end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	livechIDX			=	find( ~ismember(channame, removech) );	%alive채널만

	MaxValue			=	Potn2D(MaxTp, MaxCh);

	%% drawing topo ploting ------------------------------
	tStep				=	tRng(2)-tRng(1);			%시간 간격
	% TopoPlot	%필히 ced는 1번째(NULL, EOG 채널 위치정보가 배제되어 있음)
	figure,
	[attr, data]		=	topoplot(Potn2D(MaxTp,:),	cedPATH{1},			...
					'style','map', 'electrodes','on');%,'chaninfo',EEG.chaninfo);

	eval([	'title(sprintf('''												...
				'Max Value: %f, Freq: %s, Time: %d ms, Ch: %s'', '	...
				'MaxValue, sMaxFq, MaxTp *tStep +tRng(1), channame{MaxCh}));' ]);
%	caxis([-MaxMax, MaxMax]);
	colorbar;	%('FontSize', 30);

	%% saving topo to jpeg ------------------------------
	fprintf('\nWrites  : TOPO to JPEG file : ''%s''... ', JPG);
	print('-djpeg', JPG);
	close all;

%end function
