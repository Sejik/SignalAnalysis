function [ ] = mLib_TFplot_alone_AmH(Potn3D, hEEG, MaxFq,MaxTp,MaxCh, JPG)
	%% 모든 채널의 데이터를 overlap 하여 보여줌
	% Potn3D : freq * timepoint * ch 의 2차원 데이터
	% hEEG	: eEEG의 header
	% MaxFq : Potn3D(?,:,:) 에서 MaxFq 주파수 위치에 최대값 있음
	% MaxTp : Potn3D(:,?,:) 에서 MaxTp timpoint 위치에 최대값 있음
	% MaxCh : Potn3D(:,:,?) 에서 MaxCh 위치에 최대값 있음
	% JPG : 저장할 이미지의 파일 이름

	if isnumeric(MaxFq)								%주파수 정보는 문자열로 변환
		sMaxFq		=	sprintf('%4.1f Hz', MaxFq);
	elseif isstr(MaxFq)
		sMaxFq		=	MaxFq;
	else
		sMaxFq		=	'Unknown';
		fprintf('\nWarning : did not specified the frequency info.');
	end

	FreqParti		=	30;								% display 위한 경계선

%% Header %%
global	SRC_NAME;
global	NUMWORKERS;			%define global var for parallel tool box!!
global	WORKNAME;

%A_globals_AmH();%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@
%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
%	Freqs, fName, m, ki, cedPATH	]	=	A_globals_AmH();
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	Time				=	hEEG.Time;
	Freq				=	hEEG.Freq;
	tStep				=	Time.SmplIntrv;				%시간 간격

%	liveChIdx			=	find( ~ismember(channame, removech) );	%alive채널만
	Chan				=	hEEG.Chan;
%	Chan.idxLive;

	MaxValue			=	Potn3D(MaxFq, MaxTp, MaxCh);
%	mxChName			=	channame{MaxCh};
	mxChName			=	Chan.All{MaxCh};

%	selchan				=	channame;
	selchan				=	Chan.All;
	selchan{MaxCh}		=	[ '*' mxChName ];			% Max Ch에 '*' 표기
%	selchan				=	selchan(liveChIdx);			% EOG, NULL 제외

	% F, T 에 대해 peak 들을 구해서 표기하자.
	%% potential 에서 { positive, negative } peak 을 모두 구해야 한다.
	%% 일단은 postitive peak 만 구함.
	% -> 3D에 해당하므로, F에 대한 peak과 T에 대한 peak 이 가능하므로,
	%	구조적으로 구하는 방법을 구성해야 함.
	%
	%방법:
	%	x0. 전채널 평균: 모든 채널을 평균낸다. -> 재검토 해 볼 것
	%	1. 각 주파수별: / (sub)각 채널에 대해, time series 에서 peak 들을 구하자
	%	2. 주파수 분할: 0.5~30(FreqL), 30~80(FreqH) 구분
	%	3. L주파수범위: 위 1의 L범위내에서 구해진 peak들 중 > 3SD 인 값만 추출
	%	4. H주파수점위: 위 1의 H범위내에서 구해진 peak들 중 > 3SD 인 값만 추출
	%%	5. !! MAX : 위 파라미터에 의해 구해진 값이 진짜 max peak 인지 검증!
	%	6. 만약 > 3SD 를 구할 수 없다면, 2SD 등으로 thre를 낮추는 것도 고려
	%
	%주의: -> 비록 findpeaks 이 좋은 기능을 제공하나, max (== positive) 방향만
	%	추출해 주므로, min 방향은 역상으로 구성한 데이터에 대해 max 를 구한 후
	%	다시 복원하여 파악해야 함.

	% 먼저 각 채널별 max peak 를 추출
	% 단!, 반드시 time 0 이후부터 검출해야 함.
	%% -> 아님 time 0 상관없이 모두 구해 볼 것.

	%%	1. 주파수를 분할한다.
	Potn3D				=	double(Potn3D);				% findpeaks(double)!
	HPOTN3D				=	[];
	if size(Potn3D,1) ~= length(Freq.CurWin)			% 불일치!!
		fprintf('\nWarning : a freq-range(%d) mismatch with param(%d)\n',	...
				size(Potn3D,1), length(Freq.CurWin));
		fprintf('SKIP   : TFtopo working.\n');
		return

	elseif min(Freq.CurWin)<=FreqParti && FreqParti< max(Freq.CurWin)
		% freq가 대역 넘어 걸치는 경우 분할
		% 30 Hz 를 기준으로 두개로 나눠서 각각 image를 구성할지, 어떨지 고민중
		% -> subplot 을 작성할 수 있으면 좋은데, 방법을 찾아봐야 함.
		fprintf('\nProcess : spliting frequency by %fHz based.\n', FreqParti);
		HPOTN3D			=	Potn3D(find( Freq.CurWin >  FreqParti), :,:);
		Potn3D			=	Potn3D(find( Freq.CurWin <= FreqParti), :,:);
%	else					% all < 30 or 30 < all 이면, Potn3D 만 처리하면 됨
	end

	%%	2. 각 주파수별: / (sub)각 채널에 대해, time series 에서 peak 들을 구하자
	lMxPks				=	zeros(size(Potn3D));
	lMxLoc				=	zeros(size(Potn3D));
	for f	= 1 : size(Potn3D, 1)						% 주파수 각각
	for ch	= 1 : size(Potn3D, 3)						% 채널 각각
%		[pks loc]		=	findpeaks(Potn3D(f,:,ch), 1/tStep);%실제tp위치 by 2nd
		[pks loc]		=	findpeaks(Potn3D(f,:,ch));	%Live2D구조:t*ch
%		lMxPks(f,:,ch)	=	pks';						% 채널 별 peak: 열->행
		lMxPks(f,loc,ch)=	pks';						% 채널 별 peak: 열->행
		lMxLoc(f,loc,ch)=	loc;						% 채널 별 pk 위치 저장

		[pk loc]		=	max(pks);					% 최대값만:f,ch대비 only1
		mxPeak(f,ch)	=	pk;
%		mxLocs(f,ch)	=	loc;						% time 위치
	end
	end

	hMxPks				=	zeros(size(HPOTN3D));
	hMxPks				=	zeros(size(HPOTN3D));
	for f	= 1 : size(HPOTN3D, 1)						% 주파수 각각
	for ch	= 1 : size(HPOTN3D, 3)						% 채널 각각
%		[pks locs]		=	findpeaks(HPOTN3D(f,:,ch), 1/tStep);%Live2D구조:t*ch
		[pks locs]		=	findpeaks(HPOTN3D(f,:,ch));	%Live2D구조:t*ch
%		hMxPks(f,:,ch)	=	pks';						% 채널 별 peak: 열->행
		hMxPks(f,loc,ch)=	pks';						% 채널 별 peak: 열->행
		hMxLoc(f,loc,ch)=	loc;						% 채널 별 pk 위치 저장

		[pk loc]		=	max(pks);					% 최대값만
		HmxPeak(f,ch)	=	pk;
%		HmxLocs(f,ch)	=	loc;						% time 위치
	end
	end

	%%	3. L주파수범위: 위 1의 L범위내에서 구해진 peak들 중 > 3SD 인 값만 추출
		% > 3SD 인 것 찾기
		% u, SD를 계산하자. -> 단 0 값(즉 peak 아닌 것) 은 배제하도록 조처!
		ixNon0			=	find(lMxPks(:) ~= 0);		% 0값 아닌 index
		NonZero			=	lMxPks( ixNon0 );			% 0값 아닌 것
%		OrgNon0			=	Potn3D( ixNon0 );
%		all(all(all( OrgNon0 == NonZero )))
% lMxPks 에 저장된 pks값과 Potn3D 의 같은 위치에 저장된 값 비교 검사용
%		MN_FC			=	mean(lMxPks(:));			% 1D화 구조로 전체평균
%		SD_FC			=	std(lMxPks(:));				% SD(표준편차)=sqrt(V)
		MN_FC			=	mean(NonZero);				% 전체평균
		SD_FC			=	std(NonZero);				% SD(표준편차)=sqrt(V)

		% 전체data의 정규화 후, significant 성분 추출->그래야 idx 정확 확보 가능
		Z				=	( lMxPks - MN_FC ) / SD_FC;	% Z== array
		ixSgnf			=	find( hEEG.Statistics.Z_threshold< abs(Z) );% SD>3 만

	if ~isempty(ixSgnf)									% 발견
		% 너무 많으면 곤란하므로, 제일 큰것부터 몇개만(thre 기준) 취함
		[lSgPks ix]		=	sort(abs(lMxPks(ixSgnf)), 'descend'); % 최대값 탐지
		nLimit			=	min(length(lSgPks), hEEG.Statistics.Z_threshold+4);
		lSgPks			=	lSgPks(1:nLimit);			% 상위 몇개만 : max 7

%		lMxLocSgnf		=	lMxLoc(ixSgnf);				% significant 성분만
%		lSgTp			=	lMxLocSgnf(ix(1:nLimit));	% tp 도 몇개만

		% ix 에는 lSgPks(==lMxPks(ixSgnf))를 기준으로 한 index 가 들어 있음
		% 따라서, lMxPks 에 대한 index 를 구해야 함.
		[SgF, SgT, SgC]	=	ind2sub(size(lMxPks), ixSgnf(ix(1:nLimit)));%3D 각idx

		[imxF imxT imxC]=	deal( SgF(1), SgT(1), SgC(1) );	%최대 위치
		mxPk			=	lMxPks( imxF, imxT, imxC );	% 최대값
%		imxT
%		imxT			=	lMxLoc(imxF, imxC)			% time 위치 획득

	else
		lSgPks			=	[];
%		lSgLoc			=	[];

		% 일단 max 부터 구하자.
		[mxPk_c, imxC]	=	max(mxPeak, [], 2);			% 채널 중 최대
		[mxPk,   imxF]	=	max(mxPk_c);				% 주파수 중 최대
		imxC			=	imxC(imxF);					% 단 하나의 채널
		imxT			=	lMxLoc(imxF, imxC);			% time 위치 확인
	end

	%%	4. H주파수점위: 위 1의 H범위내에서 구해진 peak들 중 > 3SD 인 값만 추출
	[ hSgPks HmxPk HimxF HimxT HimxC ] = deal([], 0, 0, 0, 0);			%-[
	if ~isempty(HPOTN3D) && ~isempty(hMxPks)			% high freq 있으면 처리
		% > 3SD 인 것 찾기
		% u, SD를 계산하자. -> 단 0 값(즉 peak 아닌 것) 은 배제하도록 조처!
		NonZero			=	lMxPks( find(hMxPks(:) ~= 0) );	% 0값 아닌 것
%		MN_FC			=	mean(hMxPks(:));			% 1D화 구조로 전체평균
%		SD_FC			=	std(hMxPks(:));				% SD(표준편차)=sqrt(V)
		MN_FC			=	mean(NonZero);				% 전체평균
		SD_FC			=	std(NonZero);				% SD(표준편차)=sqrt(V)

		% 전체data의 정규화 후, significant 성분 추출->그래야 idx 정확 확보 가능
		Z				=	( hMxPks - MN_FC ) / SD_FC;	% Z== array
		ixSgnf			=	find( hEEG.Statistics.Z_threshold< abs(Z) );% SD>3 만

	if ~isempty(ixSgnf)								% 발견
		% 너무 많으면 곤란하므로, 제일 큰것부터 몇개만(thre 기준) 취함
		[hSgPks ix]		=	sort(abs(hMxPks(ixSgnf)), 'descend'); % 최대값 탐지
		nLimit			=	min(length(lSgPks), hEEG.Statistics.Z_threshold+4);
		hSgPks			=	hSgPks(1:hEEG.Statistics.Z_threshold+2);% 상위 몇개만

%		hMxLocSgnf		=	hMxLoc(ixSgnf);				% significant 성분만
%		lSgTp			=	hMxLocSgnf(ix(1:nLimit));	% tp 도 몇개만
		[hSgF hSgT hSgC]=	ind2sub(size(hMxPks), ixSgnf(ix(1:nLimit)));%3D 각idx

		[HimxF HimxT HimxC]=	deal( hSgF(1), hSgT(1), hSgC(1) );	%최대 위치
		mxPk			=	hMxPks( HimxF, HimxT, HimxC );	% 최대값
%		HimxT			=	hMxLoc(HimxF, HimxC);			% time 위치 획득

	else
		hSgPks			=	[];
%		hSgLoc			=	[];

		[HmxPk_c, HimxC]=	max(HmxPeak, [], 2);		% 채널 중 최대
		[HmxPk,   HimxF]=	max(HmxPk_c);				% 주파수 중 최대
		HimxC			=	HimxC(HimxF);				% 단 하나의 채널
		HimxT			=	hMxLoc(HimxF, HimxC);		% time 위치 확인
	end
	end													%-]

	if isempty(lSgPks) && isempty(hSgPks)				% 심각! 유의한 것 없음!
		fprintf('\nDiffcult: detection for a significant peaks\n');
		fprintf('SKIP   : TFtopo working.\n');
		return
	end

	%%	5. !! MAX : 위 파라미터에 의해 구해진 값이 진짜 max peak 인지 검증!
	if HmxPk==MaxValue && HimxF==MaxFq && HimxT==MaxTp && HimxC==MaxCh
		% H 주파수 영역에서 param(MaxValue) 일치
		% L 영역의 signif 성분을 제거해야 하는가?(H 쪽이 display 되도록...)

	elseif mxPk==MaxValue && imxF==MaxFq && imxF==MaxTp && imxC==MaxCh
		% L 주파수 영역에서 param(MaxValue) 일치

	else												% 검증 실패
		fprintf('\nWarning : inconsist with max peaks & param(MaxValue)\n');

	end

	%	6. 만약 > 3SD 를 구할 수 없다면, 2SD 등으로 thre를 낮추는 것도 고려

	%%	7. 유의한 성분이 발견되었으므로, TF topo 작성
	%	7-0. 유의한 성분(없으면 max peak 들)의 thre+4 개 기준으로 범위를 축소
	%		-> 전체 Potn3D 는 범위가 넓으므로, 탐지된 성분의 분포 범위로 한정
	%
	%	주파수가, L & H 로 분할되는 경우에 subplot 구성 방법도 찾아볼 것.
	%	-> 현재는 아래의 경우에 따라, 하나만 작성
	%	7-1. L, H 모두 유의: L 만 작성
	%	7-2. L만 유의: L 작성
	%	7-3. H만 유의: H 작성
	%	7-4. 둘다 N.S. : L 만 작성 -> 유의하진 않으나 max peak 찾아서 도시

	CED				=	find( cellfun(@(x)(x{1}), Chan.CED) == size(Potn3D,3) );
	if isempty(CED)
		fprintf('\nError   : correct CED(%dch) not found\n', size(Potn3D,3));
	end
	CED					=	Chan.CED{CED}{2};		% path 확보
	% ------------------
	% 유의하거나 혹은 아니더라도 peak에 대한 imxF, imxT, imxC, mxPk 가 구해짐.
	sMaxFq				=	sprintf('%.2f Hz', Freq.CurWin(imxF));
	sMaxTp				=	sprintf('%d ms', Time.EpochRange(imxT));
	sMaxCh				=	Chan.All{imxC};
	title	=	sprintf('Freq: %s, Time: %s, Ch: %s', sMaxFq, sMaxTp, sMaxCh);
	%	7-1. L, H 모두 유의: L 만 작성
	%	7-2. L만 유의: L 작성
	figure;	hold on;									% 반드시 핸들을 구성해 둠
	if ~isempty(lSgPks) && ~isempty(hSgPks)									...
		| ~isempty(lSgPks)
%{
%% ex: timef(), computing time-frequency decomposition for all electrodes	%-[
for elec = 1:EEG.nbchan
	[ersp,itc,powbase,times,freqs,erspboot,itcboot] =				...
	timef(EEG, ...
	1, elec, [EEG.xmin EEG.xmax]*1000, [3 0.5], 'maxfreq', 50, 'padratio', 4, ...
	'plotphase', 'off', 'timesout', 60, ...
	'alpha', .05, 'plotersp','off', 'plotitc','off');
	if elec == 1
		allersp     = zeros([ size(ersp)     EEG.nbchan]);
		allitc      = zeros([ size(itc)      EEG.nbchan]);
		allpowbase  = zeros([ size(powbase)  EEG.nbchan]);
		alltimes    = zeros([ size(times)    EEG.nbchan]);
		allfreqs    = zeros([ size(freqs)    EEG.nbchan]);
		allerspboot = zeros([ size(erspboot) EEG.nbchan]);
		allitcboot  = zeros([ size(itcboot)  EEG.nbchan]);
	end;
	allersp     (:,:,elec) = ersp;
	allitc      (:,:,elec) = itc;
	allpowbase  (:,:,elec) = powbase;
	alltimes    (:,:,elec) = times;
	allfreqs    (:,:,elec) = freqs;
	allerspboot (:,:,elec) = erspboot;
	allitcboot  (:,:,elec) = itcboot;
end;	%-]
%% doc: tftopo(), 설명서	%-[
tftopo() -	Generate a figure showing a selected or representative image (e.g.,
			an ERSP, ITC or ERP-image) from a supplied set of images,
			one for each scalp channel. Then, plot topoplot() scalp maps of
			value distributions at specified (time, frequency) image points.
			Else, image the signed (selected) between-channel std().
			Inputs may be outputs of timef(), crossf(), or erpimage().
Usage:
			>> tftopo(tfdata,times,freqs, 'key1', 'val1', 'key2', val2' ...)
Inputs:
tfdata	= Set of time/freq images, one for each channel. Matrix dims:
			(time,freq,chans). Else, (time,freq,chans,subjects) for grand mean
			RMS plotting.
times		= Vector of image (x-value) times in msec, from timef()).
freqs		= Vector of image (y-value) frequencies in Hz, from timef()).

Optional inputs:
'timefreqs'	= Array of time/frequency points at which to plot topoplot() maps.
				Size: (nrows,2), each row given the [ms Hz] location
				of one point. Or size (nrows,4), each row given [min_ms
				max_ms min_hz max_hz].
'showchan'	= [integer] Channel number of the tfdata to image. Else 0 to image
				the (median-signed) RMS values across channels. {default: 0}
'chanlocs'	= ['string'|structure] Electrode locations file (for format, see
				>> topoplot example) or EEG.chanlocs structure  {default: none}
'limits'	=Vector of plotting limits[minms maxms minhz maxhz mincaxis maxcaxis]
				May omit final vales, or use NaN's to use the input data limits.
				Ex: [nan nan -100 400];
'signifs'	= (times,freqs) Matrix of significance level(s) (e.g., from timef())
				to zero out non-signif. tfdata points. Matrix size must be
						([1|2], freqs, chans, subjects)
				if using the same threshold for all time points at each freq., or
						([1|2], freqs, times, chans, subjects).
				If first dimension is of size 1, data are assumed to contain
				positive values only {default: none}
'sigthresh'	= [K L] After masking time-freq. decomposition using the 'signifs'
				array (above), concatenate (time,freq) values for which no more
				than K electrodes have non-0 (significant) values. If several
				subjects, the second value L is used to concatenate subjects in
				the same way. {default: [1 1]}
'selchans'	= Channels to include in the topoplot() scalp maps (and image values)
				{default: all}
'smooth'	= [pow2] magnification and smoothing factor. power of 2 (default: 1}.
'mode'		= ['rms'|'ave'] ('rms') return root-mean-square, else ('ave') average
				power {default: 'rms' }
'logfreq'	= ['on'|'off'|'native'] plot log frequencies {default: 'off'}
				'native' means that the input is already in log frequencies
'vert'		= [times vector] (in msec) plot vertical dashed lines at specified
				times {default: 0}
'ylabel'	= [string] label for the ordinate axis. Default is
				"Frequency (Hz)"
'shiftimgs' = [response_times_vector] shift time/frequency images from several
				subjects by each subject's response time {default: no shift}
'title'		= [quoted_string] plot title (default: provided_string).
'cbar'		= ['on'|'off'] plot color bar {default: 'on'}
'cmode'		= ['common'|'separate'] 'common' or 'separate' color axis for each
				topoplot {default: 'common'}
'plotscalponly' = [x,y] location (e.g. msec,hz). Plot one scalp map only; no
				time-frequency image.
'events'	= [real array] plot event latencies. The number of event
				must be the same as the number of "frequecies".
'verbose'	= ['on'|'off'] comment on operations on command line {default: 'on'}.
'axcopy'	= ['on'|'off'] creates a copy of the figure axis and its graphic
				objects in a new pop-up window using the left mouse button
				{default: 'on'}..
'denseLogTicks'= ['on'|'off'] creates denser labels on log freuqncy axis
				{default: 'off'}

Notes:
1) Additional topoplot() optional arguments can be used.
2) In the topoplot maps, average power (not masked by significance) is used
	instead of the (signed and masked) root-mean-square (RMS) values used in
	the image.
3) If tfdata from several subjects is used (via a 4-D tfdata input),
	RMS power is first computed across electrodes, then across the subjects.

Authors: Scott Makeig, Arnaud Delorme & Marissa Westerfield, SCCN/INC/UCSD,
			La Jolla, 3/01

See also: timef(), topoplot(), spectopo(), timtopo(), envtopo(), changeunits()%-]
%}
	% Potn2D와 정확한 채널수가 일치하는 CED 를 찾아야 함.
%%		tftopo(blTFe, 1:2:2000, 0.5:1/2:80, 'mode', 'ave', 'limits', [nan nan nan 35 -1.5 1.5], 'timefreqs', [500 5; 600 5.5; 700 6; 800 6.5], 'chanlocs', '/home/minlab/MATLAB/EEG_30chan.ced');
		TITLE =	sprintf('Sgnf. Max: %.3f, %s', Potn3D(imxF, imxT, imxC), title)

		% SgT, SgF 에는 Potn3D 배열의 인덱스가 들어 있기 때문에, 이를 변경해야 함
		% 즉, EpochRange, CurWin의 범위로 변경이 필요함.
		tftopo(Potn3D, Time.EpochRange, Freq.CurWin,						...
			'title',		TITLE,											...
			'mode',			'ave',											...
			'limits',		[nan nan nan nan nan nan],						...
			'timefreqs',	[Time.EpochRange(SgT); Freq.CurWin(SgF)]',		...
			'showchan',		imxC,											...
			'chanlocs',		CED);
			% signifs	: ( time, freq ) 각각 설정
			% sigthresh	: ( K:최대 갯수, L:여러 subj ) 각각 설정

	%	7-3. H만 유의: H 작성
	elseif ~isempty(hSgPks)
		TITLE =	sprintf('Sgnf. Max: %.3f, %s', HPOTN3D(imxF, imxT, imxC), title);

		tftopo(HPOTN3D, Time.EpochRange, Freq.CurWin,						...
			'title',		TITLE,											...
			'mode',			'ave',											...
			'timefreqs',	[Time.EpochRange(hSgT); Freq.CurWin(hSgF)]',	...
			'showchan',		imxC,											...
			'signifs', ones(length(Time.EpochRange),length(Freq.CurWin))*0.05,...
			'sigthresh',	[5 1],											...
			'chanlocs',		CED);

	%	7-4. 둘다 N.S. : L 만 작성 -> 유의하진 않으나 max peak 찾아서 도시
	else
		TITLE =	sprintf('N.S. Max: %.3f, %s', Potn3D(imxF, imxT, imxC), title);

		tftopo(Potn3D, Time.EpochRange, Freq.CurWin,						...
			'title',		TITLE,											...
			'mode',			'ave',											...
			'timefreqs',	[Time.EpochRange(imxT); Freq.CurWin(imxF)]',	...
			'showchan',		imxC,											...
			'chanlocs',		CED);
	end
%{
	%% drawing 2D graph for signal T * ch : checking for noise or spike
%	tStep				=	length(tRng) / size(Potn3D,1);	%시간 간격 계산
%	tStep				=	tRng(2)-tRng(1);			%시간 간격
	% 2D Plot
	figure,
%	plot(tRng, Potn3D(:,liveChIdx)); hold on;			% EOG, NULL 제외
%	plot(Time.EpochRange, Potn3D); hold on;				% EOG, NULL -> 이미 제거
	%% peak 들을 구해서, 해당 지점에 대해 topo 들을 지정해 줌.
	% 주파수 범위가 넓을 경우, 30Hz 에서 잘라서 분리하여 구성해야 함.
%%	tftopo(blTFe, 1:2:2000, 0.5:1/2:80, 'mode', 'ave', 'limits', [nan nan nan 35 -1.5 1.5], 'timefreqs', [500 5; 600 5.5; 700 6; 800 6.5], 'chanlocs', '/home/minlab/MATLAB/EEG_30chan.ced');

	YLim				=	get(gca, 'YLim');
	tWin				=	Time.WinStart : Time.WinFinish;	% 시간 범위
%	if tWin ~= 0										% 0 이면 time win 표기 X
	rectangle('EdgeColor','r', 'LineWidth',2,							...
		'Position',[tWin(1),YLim(1),tWin(end)-tWin(1),YLim(2)-YLim(1)]); hold on;
%	end
	legend(selchan, 'Location','eastoutside', 'Orientation','vertical');
	xlabel('t(ms)');		ylabel(sprintf('%d of ch', length(selchan)));
	title(sprintf('Max Value: %f, Freq: %s, Time: %d ms, Ch: %s',			...
		MaxValue, sMaxFq, MaxTp *tStep +Time.Start, mxChName));
%	ylim([-0.1 1.2]);
	grid on;

	% 최대값 위치에 marker 표기
	plot(MaxTp *tStep +Time.Start, MaxValue, 'ro','MarkerSize',10,'LineWidth',1);
%}
	%% saving 2D to jpeg ------------------------------
	fprintf('\nWrites  : Graph to JPEG file : ''%s''... ', JPG);
	print('-djpeg', JPG);
	close all;

%end function
