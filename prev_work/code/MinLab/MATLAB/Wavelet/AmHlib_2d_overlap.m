function [ ] = AmHlib_2d_overlap(Potn2D, tRng,tWin, MaxFq,MaxTp,MaxCh, JPG)
	%% 모든 채널의 데이터를 overlap 하여 보여줌
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
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	liveChIdx			=	find( ~ismember(channame, removech) );	%alive채널만

	MaxValue			=	Potn2D(MaxTp, MaxCh);
	mxChName			=	channame{MaxCh};

	selchan				=	channame;
	selchan{MaxCh}		=	[ '*' mxChName ];			% Max Ch에 '*' 표기
	selchan				=	selchan(liveChIdx);			% EOG, NULL 제외

	%% drawing 2D graph for signal T * ch : checking for noise or spike
%	tStep				=	length(tRng) / size(Potn2D,1);	%시간 간격 계산
	tStep				=	tRng(2)-tRng(1);			%시간 간격
	% 2D Plot
	figure,
	plot(tRng, Potn2D(:,liveChIdx)); hold on;			% EOG, NULL 제외
	YLim				=	get(gca, 'YLim');
%	if tWin ~= 0										% 0 이면 time win 표기 X
	rectangle('EdgeColor','r', 'LineWidth',2,							...
		'Position',[tWin(1),YLim(1),tWin(end)-tWin(1),YLim(2)-YLim(1)]); hold on;
%	end
	legend(selchan, 'Location','eastoutside', 'Orientation','vertical');
	xlabel('t(ms)');		ylabel(sprintf('%d of ch', length(selchan)));
	title(sprintf('Max Value: %f, Freq: %s, Time: %d ms, Ch: %s',			...
			MaxValue, sMaxFq, MaxTp *tStep +tRng(1), mxChName));
%	ylim([-0.1 1.2]);
	grid on;

	% 최대값 위치에 marker 표기
	plot(MaxTp *tStep +tRng(1), MaxValue, 'ro','MarkerSize',10,'LineWidth',1);

	%% saving 2D to jpeg ------------------------------
	fprintf('\nWrites  : Graph to JPEG file : ''%s''... ', JPG);
	print('-djpeg', JPG);
	close all;

%end function
