function [ ] = AmHlib_ERP_overlap(Potn2D, tRng, tWin, JPG)
	%% 모든 채널의 데이터를 overlap 하여 보여줌
	% Potn2D : timepoint * ch 의 2차원 데이터
	% tRng=[start:step:end] : 시작시점 ~ 끝까지 범위
	% tWin=[x1:step:x2] : time window
	% MaxTp : Potn2D(?,:) 에서 MaxTp timpoint 위치에 최대값 있음
	% MaxCh : Potn2D(:,?) 에서 MaxCh 위치에 최대값 있음
	% JPG : 저장할 이미지의 파일 이름

%% Header %%
global	SRC_NAME;
global	NUMWORKERS;			%define global var for parallel tool box!!
global	WORKNAME;

%A_globals_AmH();%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@
%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki, cedPATH	]	=	A_globals_AmH();
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	% 여기 도착했을 때는 무조건 channame 갯수와 일치해야 함!
	if size(Potn2D,2) ~= length(channame)
%		liveChIdx		=	find( ~ismember(channame, removech) );	%alive채널만
%		Live2D			=	Potn2D(:, liveChIdx);
%		selchan			=	channame( liveChIdx );
		Error;
	end
	Live2D				=	Potn2D;
	selchan				=	channame;

%	tStep				=	length(tRng) / size(Live2D,1);	%시간 간격 계산
	tStep				=	tRng(2)-tRng(1);			%시간 간격

	% time 0 부터 끝까지의 window도 구성해야 함.
%	t0Idx				=	find(0 <= tRng);			% 먼저 array index를 취함
	tWidx				=	find(ismember(tRng, tWin));	% window
%	t0Rng				=	tRng( t0Idx );				% 실제 time 값을 획득
%	tWrng				=	tRng( tWidx );				% 실제 time 값을 획득

	%% potential 에서 { positive, negative } peak 을 모두 구해야 한다.
	% 특기할 것은, 2D 데이터 ( 원래 peak 은 single vector 에서 구함) 상에서
	%	peak 을 찾아야 하며, 따라서, 채널 차원을 하나로 merge 해야 하는데,
	%	이렇게 merge 된 데이터에서도 peak 은 반드시 최대값을 보여주는 하나의 채널
	%	및 최소값을 보여주는 하나의 채널에 대해서만 각각 구해야 함!
	%	예를 들어, 두 채널이 교대로 peak 을 보여주더라도, 전체적으로 더 큰 값을
	%	가지는 단 하나의 채널에 대해서만 peak 이 탐색되어야 함.
	%방법: 채널별로 peak 을 모두 구한다음, 최대값인 채널과 최소값이 채널을
	%	찾아서, 이 두 채널에 대해서만 peak을 image에 표기
	%주의: -> 비록 findpeaks 이 좋은 기능을 제공하나, max (== positive) 방향만
	%	추출해 주므로, min 방향은 역상으로 구성한 데이터에 대해 max 를 구한 후
	%	다시 복원하여 파악해야 함.
	%	-> 경우에 따라, 한 채널에서 min, max 가 다 나올 수도 있음에 유의.

	% 먼저 각 채널별 max peak 를 추출
	% 단!, 반드시 time 0 이후부터 검출해야 함.
	for ch = 1 : size(Live2D, 2)						% length of ch
		[pks, locs]		=	findpeaks(Live2D(tWidx,ch), 1/tStep);%Live2D구조:t*ch
		lMxPks{ch}		=	pks';						% 채널 별 peak: 열->행
		mxPeak(ch)		=	max(pks);					% 최대값만
		lMxLocs{ch}		=	locs;						% 채널 별 pk 위치 저장
	end
%	[mxPeak, ixPeak]	=	max(lMxPks, [], 2);			% 채널 내 최대값
	[mxPkCh, ixPkCh]	=	max(mxPeak);				% 채널 중 최대값

	% 이어 각 채널별 min peak 를 추출
	for ch = 1 : size(Live2D, 2)						% length of ch
		[pks, locs]		=	findpeaks(-1*Live2D(tWidx,ch), 1/tStep);% amp reverse
		lMnPks{ch}		=	-1*pks';					% 채널 별 min 값 저장
		mnPeak(ch)		=	min(-1*pks);				% 최소값만
		lMnLocs{ch}		=	locs;						% ch 별 min pk 위치 저장
	end
%	[mnPeak, inPeak]	=	min(lMnPks, [], 2);			% 채널 내 최소값
	[mnPkCh, inPkCh]	=	min(mnPeak);				% 채널 중 최소값

	% 다음, 2D plot을 작성하자.
	mnChName			=	selchan{inPkCh};			% max 와 min 이 겹칠수도
	selchan{inPkCh}		=	[ '-' mnChName ];			% Min Ch에 '-' 표기
	mxChName			=	selchan{ixPkCh};
	selchan{ixPkCh}		=	[ '+' mxChName ];			% Max Ch에 '+' 표기
	others				=	find(~ismember(selchan, selchan([inPkCh ixPkCh])));

%	linetype			=	cell(1,length(selchan));	% row type 선언
%	linetype(:)			=	{ ':' };					% 셀 전체 초기화: 점선

	%% drawing 2D graph for signal T * ch : checking for noise or spike
	% 2D Plot
	figure,
%	plot(tRng, Live2D(:,others), ':'); hold on;		% max, min 이외: 점선
%	plot(tRng, Live2D(:,[inPkCh ixPkCh]), '-'); hold on;% max, min 만 실선
%	plot(tRng, Live2D, linetype); hold on;			% 기정의한 선 모양 리스트
	lPlt				=	plot(tRng, Live2D, ':'); hold on;%각 plot 라인 handle
	lPlt(inPkCh).LineWidth	=	2;							% 더 굵게
	lPlt(ixPkCh).LineWidth	=	2;							% 더 굵게
	lPlt(inPkCh).Color		=	'cyan';						% negative 는 청색
	lPlt(ixPkCh).Color		=	'magenta';					% positive 는 적색
	lPlt(inPkCh).LineStyle	=	'-.';						% negative 는 실선
	lPlt(ixPkCh).LineStyle	=	'-';						% positive 는 점선

	% 최대값 위치에 marker 표기
	plot(lMxLocs{ixPkCh}, lMxPks{ixPkCh}, 'rv','MarkerSize',5,'LineWidth',1);
%	for n = 1 : length(lMxLocs{ixPkCh})					% negative peak 표기
%		text(lMxLocs{ixPkCh}(n), lMxPks{ixPkCh}(n), sprintf('n%d', n));
%	end
	pkname	=	arrayfun(@(x)({sprintf('p%d',x)}), [1:length(lMxPks{ixPkCh})]);
	text(lMxLocs{ixPkCh}+.0, lMxPks{ixPkCh}+.2, pkname);

	% 최소값 위치에 marker 표기
	plot(lMnLocs{inPkCh}, lMnPks{inPkCh}, 'b^','MarkerSize',5,'LineWidth',1);
%	for p = 1 : length(lMnLocs{inPkCh})					% positive peak 표기
%		text(lMnLocs{inPkCh}(p), lMnPks{inPkCh}(p), sprintf('p%d', p));
%	end
	pkname	=	arrayfun(@(x)({sprintf('n%d',x)}), [1:length(lMnPks{inPkCh})]);
	text(lMnLocs{inPkCh}+.0, lMnPks{inPkCh}-.2, pkname);

%	set(gca, 'Ydir', 'rev');							% Y축의 증가 방향 역전
	YLim			=	get(gca, 'YLim');
	YMax			=	max(abs(YLim));					% Y축 min/max중 절대최대
	ylim([ -YMax YMax ]);								% 동일 gadient 구성
	if tWin ~= 0										% 0 이면 time win 표기 X
		rectangle('EdgeColor','r', 'LineWidth',2,							...
		'Position',[tWin(1),YLim(1),tWin(end)-tWin(1),YLim(2)-YLim(1)]); hold on;
	end
	legend(selchan, 'Location','eastoutside', 'Orientation','vertical');
	xlabel('t(ms)'); ylabel(sprintf('%d chs, Potential(uV)', length(selchan)));
	title(sprintf('Max: %.3fuV/%s, Min: %.3fuV/%s',							...
max(cell2mat(lMxPks)), selchan{ixPkCh}, min(cell2mat(lMnPks)), selchan{inPkCh}));
%	ylim([-0.1 1.2]);
	grid on;

	%% saving 2D to jpeg ------------------------------
	fprintf('\nWrites  : Graph to JPEG file : ''%s''... ', JPG);
	print('-djpeg', JPG);
	close all;

%end function
