% C_timtopo ver 0.51
%% TF 데이터 기반 TF plot 구성
% [*Input Parameter]--------------------------------------------------
% Potn3D	: freq * timepoint * ch 의 3차원 데이터
% PlotFq	: plot용 주파수 범위 : Potn3D frequency범위 일치필요, %예:[1/4, 70]
% PlotTp:	: plot용 시간범위(ms): Potn3D timepoint범위 일치필요, %예:[-500,1500]
% TopoFq	: topo용 주파수 목록 : 목록 수 만큼 토포가 도시됨
%	ex) NaN -> max 값 자동계산 및 표시
%	ex) inf -> Z score 기반 signif. 자동계산 및 표시
% TopoTp: topo용 시간 목록 : TopoFq 와 갯수 일치 필수
%	ex) NaN -> |local max| 값 자동계산 및 표시 -> 없으면 |global max| 탐지
%	ex) inf -> Z score 기반 signif. 자동계산 및 표시
%	ex) 시간, 주파수 중 하나만 nan or inf 표기 시,
%		정상 값 표기된 영역범위 내에서 자동계산
%			: tp:inf, freq:5 -> 주파수 5Hz 범위내에서 Z 유의미(or max)값 추출
% CED		: topo를 위한 CED 파일 path
% Title		: text for display
% DispFq	: display용 주파수 범위 : 데이터 중 실제 plot 범위 : [ 10, 30 ]
% DispTp	: display용 시간 목록 : 데이터 중 실제 plot 범위 : [ -500 1500 ]
% DispChi	: display용 채널 : 번호 해당 채널만 도시, (기본: 0==All채널 평균)
% DispBar	: colorbar의 상,하 scale 조정 : 예: [-1.5 1.5], 기본: autoscale
% DispRatio	:TF plot 과 TOPO plot 의 크기 비율 -> TF/TOPO -> 1>이하(topo커짐)
%
% [*Output Parameter]--------------------------------------------------
% mainFreq  : 해당 데이터의 중심주파수: individual unique freqeuncy
% mainTime  : 해당 데이터의 maximum value 발생 시간
% StrikeZone: maximum value를 중심으로 high power가 펼치진 zone(l,b,r,t)
%
%% examples: E_tftopo(Data3D,	[1:1/2:30],	[-500:2:1500-1],		...
%	[ 5 NaN NaN 6 inf inf 7 ],	[ -200 -100 NaN 100 200 inf 300 ],		...
%	'..../../32chan.ced',				...
%	'ESHL'								...
%	[ 5 30 ],	[ -300 800 ],	'Cz',	...
%	[-1.5 1.5],	0.9)
%
% first created by tigoum 2015/12/02
% last  updated by tigoum 2016/05/12
% ver 0.51 : 입력 parameter중 PlotFq, PlotTp 의 형식: vector -> interval 변경

function [mainFreq mainTime StrikeZone] =	...
							E_tftopo(	Potn3D,	PlotFq,PlotTp,			...
										TopoFq,TopoTp, CED,		...
										Title,					...
										DispFq,DispTp,DispCh,	...
										DispBar, DispRatio)

	%% 20151202A. 추가: 주파수 성분이 없는 경우에도 전체 주파수 영역에서 도시방법
	% ERP 의 경우, 주파수 정보가 없는 정보블럭이지만 TF 도시를 위해 고려 필요
%	if length(size(Potn3D))== 2 & size(Potn3D,1) > size(Potn3D,2) &		...
%		size(Potn3D,1) == length(PlotTp)				% 그럼 2nd 차원은 채널
		%% 주파수 공간이 없으므로, 전대역에 걸쳐 주파수 공간을 확보해야 함.
%		fprintf('Warning : have not Frequency dimension in DATA array...\n');
%{
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Time-Frequency Analysis	%-[
		tStep		=	PlotTp(2)-PlotTp(1);
		fSmpl		=	1000/tStep;
%		fprintf('Engagement: Time-Frequency Analysis');
		Potn3D_		=	zeros([length(PlotFq) size(Potn3D)]);	%f x t x ch
		for ch		=	1:size(Potn3D,2),				%loop the all-ch
%			[tf1,tfa1,tfc1]		=	tfmorlet_min(ERP(:,ch),fSmpl,Freqs,m,ki);
			tfPw	=	tfmorlet_min_AmH(Potn3D(:,ch), fSmpl, PlotFq, 7, 5);
			Potn3D_(:,:,ch)	=	tfPw;					%power만 추출
		end
%		Potn3Dx	= arrayfun(@(x)( tfmorlet_min_AmH(x,fSmpl,PlotFq,7,5) ),
%		Potn3D(:,:))

		Potn3D		=	Potn3D_;	clear Potn3D_;
%}
%{
%		Potn3D		=	repmat(Potn3D, [1 1 length(PlotFq)]);	% t x ch x f
%		Potn3D		=	shiftdim(Potn3D,2);						% f x t x ch
%}
%{
		Potn3D_		=	zeros([size(Potn3D,1) size(Potn3D)]);	% tp 차원 확장
		for tp = 1 : size(Potn3D,1)
			Potn3D_(tp,tp,:) = Potn3D(tp,:);
		end
		Potn3D		=	Potn3D_;	clear Potn3D_;
		PlotFq		=	PlotTp;							% 시간축만 존재함
		TopoFq		=	TopoTp;							% 시간축만 존재함
		DispFq		=	DispTp;							% 시간축만 존재함
%}
%{
		tStep		=	PlotTp(2)-PlotTp(1);
		fSmpl		=	1000/tStep;						% Sampling frequency
		sigLen		=	length(PlotTp) * tStep;			% Length of signal
		n			=	2^nextpow2(sigLen);
		dim			=	1;								% 세로방향(채널->가로)
		Y			=	fft(X,n,dim);
		F			=	abs(Y);
		Potn3D_		=	zeros([size(Potn3D,1) size(Potn3D)]);	% tp 차원 확장%-]
%}
%		fprintf('+ adds  : Freq-DIM. into DATA array by processing.\n');
%	end
	% 20160512B. 상기의 time series 데이터에서 freq 추출은 하지 말고, 에러 처리
	if length(size(Potn3D)) < 3,error('Detect  : data require 3 dimension.');end
	if nargin < 6,				error('Error   : parameter missing.'); end

	%% 20160512A. PlotFq, PlotTp 표기 방식의 변경에 의해 data와 size 비교 불가
%{
	if size(Potn3D,1) < length(PlotFq)					% index 초과 -> 경고 출력
		fprintf('\nWarning : FREQ index(%d) too big than data(%d)\n\n',		...
				length(PlotFq), size(Potn3D,1));
	end
	if size(Potn3D,2) < length(PlotTp)					% index 초과 -> 경고 출력
		fprintf('\nWarning : TIME index(%d) too big than data(%d)\n\n',		...
				length(PlotTp), size(Potn3D,2));
	end
%}
	if length(PlotFq)~=2, error('Detect  : PlotFq require interval(2 val).');end
	if length(PlotTp)~=2, error('Detect  : PlotTp require interval(2 val).');end
	if length(TopoFq) ~= length(TopoTp)					% 갯수 불일치 -> 경고
		fprintf('\nWarning : differ a numbers of Topo(F:%d,T:%d)\n\n',		...
				length(TopoFq), length(TopoTp));
	end

	if nargin <12,	DispRatio=	1.0;	end
	if nargin <11,	DispBar	=	[ nan nan ];	end
	if nargin <10,	DispCh	=	0;	end
	if nargin < 9 | DispTp==0,	DispTp	=	[ PlotTp(1) PlotTp(end) ];	end
	if nargin < 8 | DispFq==0,	DispFq	=	[ PlotFq(1) PlotFq(end) ];	end
	if nargin < 7,	Title	=	'';	end

	% --------------------------------------------------
	% 자동 eBIN 계산
	% PlotFq 에 대한 경계값 문제 발생 : 20160324A. 참조
	% 1/4 ~ 70 의 Hz를 제시하는데, 실제 데이터는 280개 라면,
	% bin은 1/4 가 되어야 함. 따라서 eBIN은 소수값~정수배수값 까지 다양.
	% 계산방법: start ~ end 사이에 존재하는 데이터의 간격 갯수 계산
	%	-> 예: [1/4:?:70] 에서 280개 데이터가 존재하며, 이 사이 간격 수는 279
	%	-> 따라서, 간격의 크기 = gap / n(gap) = (70-1/4) / (280-1)
	%
	% Potn3D	: freq * timepoint * ch 의 3차원 데이터
	nFq				=	size(Potn3D, 1);
	eBIN			=	(PlotFq(2) - PlotFq(1)) / (nFq - 1);
%	if int32(eBIN)~=eBIN, error('ERROR   : eBIN(%f) value not integer',eBIN); end
	PlotFq			=	[ PlotFq(1) : eBIN : PlotFq(2)-0 ];	% conv to vector
	%
%	ixDispFq				=	[DispFq(1) : PlotFq(2)-PlotFq(1) : DispFq(2)];
	ixDispFq				=	[DispFq(1) : eBIN : DispFq(2)];
	[ixFqStart ixFqFinish]	=	deal(	find(PlotFq == ixDispFq(1)),		...
										find(PlotFq == ixDispFq(end)) );
	ixFreq					=	PlotFq(ixFqStart:ixFqFinish);

	% --------------------------------------------------
	% 자동 eFS 계산
	% Potn2D array element's length 에서 제일 큰 값이 tp 임.
	% PlotTp 에 대한 경계값 문제 발생 : 20160324A. 참조
	% -500 ~ 1500 의 시간을 제시하는데, 실제 데이터는 1000개 라면,
	% [-500 , 1500) 이 됨. 따라서, eFS 값이 정수인지 아닌지 조사 필요
	%
	% Potn3D	: freq * timepoint * ch 의 3차원 데이터
	nTp				=	size(Potn3D, 2);
	eFS				=	1000 * nTp / (PlotTp(2) - PlotTp(1)); %PlotTp==ms
	if int32(eFS) ~= eFS, error('ERROR   : eFS(%f) value not integer', eFS); end
	PlotTp			=	[ PlotTp(1) : 1000/eFS : PlotTp(2)-1 ];	% conv to vector
	%
%	ixDispTp				=	[DispTp(1) : PlotTp(2)-PlotTp(1) : DispTp(2)];
	ixDispTp				=	[DispTp(1) : 1000/eFS : DispTp(2)];
	[ixTpStart ixTpFinish]	=	deal(	find(PlotTp == ixDispTp(1)),		...
										find(PlotTp == ixDispTp(end)) );
	ixTime					=	PlotTp(ixTpStart:ixTpFinish);

	Potn3D			=	Potn3D(ixFqStart:ixFqFinish, ixTpStart:ixTpFinish, :);

%	FreqCutoff		=	30;								% display 위한 경계선
%	tStep			=	PlotTp(2) - PlotTp(1);	%시간 간격

	%% drawing 3D graph for TFc data
	[ChanNum ChanName]	=	mLib_load_CED_AmH(CED);		% CED 에서 chan 목록 수집
	if isnumeric(DispCh)								% index숫자면 문자열 확보
		if DispCh == 0, sCh	=	'RMS of All';
		else,			sCh	=	[char(ChanName{DispCh}) '(' int2str(DispCh) ')'];
		end
	else												% 문자면 index숫자 확보
		sCh			=	DispCh;
		DispCh		=	find(strcmp(ChanName, sCh));
	end
	if ~isempty(Title)
		title	= sprintf('[%s]''s TF (Ch:%s) & Topo', Title, sCh);
	else
		title		=	sprintf('TF (Ch:%s) & Topo', sCh);
	end

	figure,
%	tftopo(Potn3D, PlotTp, PlotFq, 'timefreqs',[ TopoTp ; TopoFq ]',		...
%			'mode','ave', 'chanlocs',CED, 'title',title);
	tftopo(Potn3D, ixTime, ixFreq, 'timefreqs',[ TopoTp ; TopoFq ]',		...
			'mode','ave', 'chanlocs',CED, 'title',title,					...
			'showchan',DispCh, 'limits',[nan nan nan nan DispBar],			...
			'tradeoff',DispRatio );

	print('-djpeg', [Title '_' sCh '.jpg']);

	return
%end function

