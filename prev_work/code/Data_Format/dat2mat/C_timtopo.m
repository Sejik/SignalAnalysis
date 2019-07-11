% C_timtopo ver 0.51
%% ERP 데이터 기반 time plot 구성
% [Parameter] ----------
% Potn2D: timepoint * ch 의 2차원 데이터 -> 비교 위해 다수 입력 가능
% PlotTp: plot용 시간범위(ms): Potn2D timepoint범위 일치필요, %예:[-500,1500]
% CED	: topo를 위한 CED 파일 path, [ 절대경로 | 상대경로 | 파일명 only ]
%		ex) 파일명만 표기시 탐색순서: ./ , ~minlab/Tools/MATLAB/
% Condi : text for condition information
% TopoTp: topo용 시간 목록 : 생략 혹은 NaN 입력시 maximum(abs()) 도시
%		Inf 입력시 maximum variance 도시
%		NaN 과 Inf 동시 입력시 Inf 무시됨.
% DispTp: display용 시간 목록 : 데이터 중 실제 plot 범위 : [ -500 1500 ]
% DispCh: display용 채널 : 번호 해당 채널만 도시, (기본: 0==평균)
% DispPW: power(amp)의 범위: Y 축 range 조정 : [-5 5], (기본: 0==평균)
% DispBar:colorbar의 상,하 scale 조정 : 예: [-1.5 1.5], 기본: autoscale
% DispRatio: TF plot 과 TOPO plot 의 크기 비율 -> TF/TOPO -> 1>이하(topo커짐)
% Filter: 필터링 주파수 범위, 예: [0.5 30](band), [5 nan](high), 기본:not
%
%% examples:	%-[
%% 1. Single 데이터 전체 채널 도시
%	C04timtopo_AmH(	Data2D, [-500 1500],	...
%		'/home2/minlab/Tools/MATLAB/EEG_32chan.ced',		...
%		'USHL',				[NaN | -200 100 300],	...
%		[ -300 800 ],		'',		[0 1],			...
%		[-1.5 1.5],			0.9)
%
%% 2. Single 데이터의 특정 채널
%	C04timtopo_AmH(	Data2D, [-500 1500],	...
%		'/home2/minlab/Tools/MATLAB/EEG_32chan.ced',		...
%		'USHL',				[NaN | -200 100 300],	...
%		[ -300 800 ],		'Cz',	[-5 5],			...
%		[-1.5 1.5],			0.9)
%
%% 3. Multi 데이터의 비교 : (전체 채널평균)
%	C04timtopo_AmH(	{Data2D_1 Data2D_2}, [-500 1500],	...
%		'/home2/minlab/Tools/MATLAB/EEG_32chan.ced',		...
%		{'USHL' 'MSAD'},	[NaN | 300],		...
%		[ -300 800 ],		'',		[-3 3],		...
%		[-1.5 1.5],			0.9)
%
%% 4. Multi 데이터의 비교 : (특정 채널)
%	C04timtopo_AmH(	{Data2D_1 Data2D_2}, [-500 1500],	...
%		'/home2/minlab/Tools/MATLAB/EEG_32chan.ced',		...
%		{'USHL' 'MSAD'},	[NaN | 300],	...
%		[ -300 800 ],		'Cz',	[0 0],	...
%		[-1.5 1.5],			0.9)
%
%% 5. real 예시 (4번 기준)
%	load '/home/minlab/Projects/SKK/SKK_3/GRD/Com_F___.mat'
%	load '/home/minlab/Projects/SKK/SKK_3/GRD/Com_U__D.mat'
%	load '/home/minlab/Projects/SKK/SKK_3/GRD/Com__AI_.mat'
%	load '/home/minlab/Projects/SKK/SKK_3/GRD/Com__A__.mat'
%	load '/home/minlab/Projects/SKK/SKK_3/GRD/Com__SH_.mat'
%	C04timtopo_AmH({ERP_F___ ERP_U__D ERP__AI_ ERP__A__ ERP__SH_}, ...
%		[-500 1500], '/home2/minlab/Tools/MATLAB/EEG_30chan.ced',	...
%		{'F___' 'U__D' '_AI_' '_A__' '_SH_'},		...
%		[NaN], [-300 800], '', [-1.5 1.5], 0.9)
%
%% 6. real 예시 (5번 기준)
%	C04timtopo_AmH({ERP_F___ ERP_U__D ERP__AI_ ERP__A__ ERP__SH_}, ...
%		[-500 1500], '/home2/minlab/Tools/MATLAB/EEG_30chan.ced',	...
%		{'F___' 'U__D' '_AI_' '_A__' '_SH_'},		...
%		[NaN], [-300 800], '', [-1.5 1.5], 0.9,		...
%		[0.5 30])	% 필터 기능 추가	%-]
%
% first created by tigoum 2015/11/01
% last  updated by tigoum 2016/05/03
% ver 0.51 : filter 수행 후, baseline correction 처리

function [ ] = C_timtopo(	Potn2D,	PlotTp, CED,					...
							Condi,	TopoTp,							...
							DispTp,	DispCh,	DispPW, DispBar,		...
							DispRatio,								...
							Filter)

% implementation: CED auto detector & loader : the rule for find CED file
% 0. detect channel size from Potn2D
% 1. find in current folder
% 2. find in Tools/MATLAB folder

%% setting %%
	if nargin < 3										% 반드시 CED까지는 !
		fprintf('\nError   : parameter missing.\n');
		return
	end

	if nargin <11,	Filter		=	[nan nan];		end	% 기능 안함
	if nargin <10,	DispRatio	=	1.0;			end
	if nargin < 9,	DispBar		=	[ nan nan ];	end
	if nargin < 8,	DispPW		=	[ 0 0 ];		end
	if nargin < 7,	DispCh		=	0;				end
	if nargin < 6 | DispTp==0,	DispTp	=	[ PlotTp(1) PlotTp(2) ];	end
	if nargin < 5,	TopoTp		=	NaN;			end
	if nargin < 4,	Condi		=	'';				end

	% 채널 parameter 의 정제
	[ChanNum ChanName]	=	mLib_load_CED_AmH(CED);		% CED 에서 chan 목록 수집

	if isnumeric(DispCh)								% index숫자면 문자열 확보
		if DispCh == 0 | isempty(DispCh), sCh	=	'All';
		else,			sCh	=	[char(ChanName{DispCh}) '(' int2str(DispCh) ')'];
		end
	elseif isempty(DispCh)								% '' 공백 문자면
		sCh			=	'All';
		DispCh		=	find(strcmp(ChanName, sCh));	% 숫자화
	else												% 문자면 index숫자 확보
		sCh			=	DispCh;
		DispCh		=	find(strcmp(ChanName, sCh));	% 숫자화
	end

	if length(DispPW) == 1, DispPW = [ DispPW DispPW ]; end	% 2개의 값이 필요함

	% --------------------------------------------------
	% 자동 eFS 계산
	% Potn2D 에서 제일 큰 값이 tp 임.
	% PlotTp 에 대한 경계값 문제 발생 : 20160324A. 참조
	% -500 ~ 1500 의 시간을 제시하는데, 실제 데이터는 1000개 라면,
	% [-500 , 1500) 이 됨. 따라서, eFS 값이 정수인지 아닌지 조사 필요
	if iscell(Potn2D),	nTp = max(cellfun(@(x)(length(x)), Potn2D));
	else,				nTp = length(Potn2D); end
	eFS				=	1000 * nTp / (PlotTp(2) - PlotTp(1)); %PlotTp==ms
	if int32(eFS) ~= eFS, error('ERROR   : eFS(%f) value not integer', eFS); end
	PlotTp			=	[ PlotTp(1) : 1000/eFS : PlotTp(2)-1 ];	% conv to vector

	% --------------------------------------------------
	% Baseline Correction 의 Timewindow를 지정하는 부분.
	% 만약 input data가 time point 에 대해 (-) 시간, 즉 prestimulus 구간을
	% 제공하지 못하면 baseline correction을 할 수 없음!
	ERP_blTimWin	=	[-500 -1];		% -500 ~ 0ms, (20151102A. 교수님 지시)
	TF_blTimWin 	=	[-400 -101];	% -400 ~ -100ms (TF 용)
	% -----
	ERP_blTimWix	=	find(ismember(PlotTp,			...
						[ERP_blTimWin(1):1000/eFS:ERP_blTimWin(2)]) );
	TF_blTimWix		=	find(ismember(PlotTp,			...
						[TF_blTimWin(1) :1000/eFS: TF_blTimWin(2)]) );

	% --------------------------------------------------
	% 필터 조건에 따라, 필터링을 수행한다.
[NONE, HIGH, LOW, BAND]	=	deal(0, 1, 2, 3);			% nmemonic
	if length(find(~isnan(Filter))) >= 2				% bandpass 값 정상 수치
		% Butterworth Filtering 부분.
%		[bbb, aaa]	=	butter(1, [0.5 30]/(eFS/2),'bandpass');
		nOrder		=	Filter / (eFS/2);
		[bbb, aaa]	=	butter(1, nOrder, 'bandpass');	% zero-phase filtering
		fgFilter	=	BAND;

	elseif ~isnan(Filter(1)) % & isnan(Filter(2))		% highpass
		nOrder		=	Filter(1) / (eFS/2);
		[bbb, aaa]	=	butter(1, nOrder, 'high');
		fgFilter	=	HIGH;

	elseif ~isnan(Filter(2)) % & isnan(Filter(1))		% lowpass
		nOrder		=	Filter(2) / (eFS/2);
		[bbb, aaa]	=	butter(1, nOrder, 'low');
		fgFilter	=	LOW;

	else												% 아무것도 안해도 됨
		fgFilter	=	NONE;
	end

	% 여러 data 비교 방식에서 각 데이터 matrix의 차원이 2D를 초과하는지 조사
if isempty(Potn2D)
	error('Error   : data''s empty, please check parameter.');

elseif iscell(Potn2D)									% 여러 data 비교형
	for dim = 1 : length(Potn2D)
		if 2 < length(size(Potn2D{dim}))
			error('Error   : %dth data''s dimension too more than 2D',dim);
		end
		if size(Potn2D{dim},1) ~= length(PlotTp)		% index 초과 -> 경고 출력
			error('Warning : TIME index(%d) mismath with data(%d)',	...
					length(PlotTp), size(Potn2D{dim},2));
		end

		% 만약 각 data의 dimention 별 크기가 다르다면 가장 작은 것으로 통일 시킴
	end

	% 단일 data 비교 방식에서 matrix의 차원이 2D를 초과하는지 조사
	nSize				=	cellfun(@(x)({ size(x) }), Potn2D);	% size 목록
	nDim				=	shiftdim(reshape(cell2mat(nSize), 2,[]), 1);%차원구성
	mnDim				=	min(nDim);					% 최소 크기 차원 구성

	% 이제 최소 차원에 맞춰 데이터 array들의 크기 조절
	Index				=	sprintf('1:%d,1:%d', mnDim);% 인덱스 구성
	eval(['Potn2D		=	cellfun(@(x)({ double(x(' Index ')) }), Potn2D);']);

	Index				=	sprintf('%d, %d', mnDim);	% 인덱스 구성
	eval(['Potn2D		=	reshape(cell2mat(Potn2D),' Index ',[]);']);%구조주의!

%	if fgFilter
%		Potn2D			= arrayfun(@(x)({filtfilt(bbb, aaa, Potn2D(:,:,x))}),...
%								[1:size(Potn2D,3)] );
%		Potn2D			=	reshape(cell2mat(Potn2D),					...
%								[size(Potn2D{1},1)], [size(Potn2D{1},2)], [] );
%		Potn2D			=	filtfilt(bbb, aaa, Potn2D);
%	end % zero-phase: tp x ch * cond

%	Potn2D				=	shiftdim(Potn2D,2);			% 1st 가 array 순서
%	Potn2D				=	permute(Potn2D, [2 1 3]);	% t*c*condi->c*t*condi
	% 이제 3차원의 데이터가 구성됨.
%{
	% 이제 데이터를 파라미터 조합에 맞춰 다시 단일 2D 형 데이터로 가공! %-[
	% 1. DispCh == 0 (모든 채널) 인 경우
	%	-> 각 array별로 ch 차원을 평균낸다.
	%	-> 각 array별로 time vector만 남는다.
	%	-> 각 array 데이터를 ch 들의 데이터 처럼 하나로 합침
	% 2. DispCh == 'Cz' (특정 채널 지정) 인 경우
	%	-> 각 array별로 해당 채널만 남긴다.
	%	-> 각 array별로 time vector만 남는다.
	%	-> 각 array 데이터를 ch 들의 데이터 처럼 하나로 합침

	if DispCh == 0										% 위 조건 1 상황
		Potn2D			=	arrayfun(@(x)( squeeze(mean(x,3)) ), Potn2D); %ch평균
	else												% 위 조건 2 상황
		DispCh			=	0;							% ch param 정보는 해제
		Potn2D(:,:, find(~ismember(ChanNum, DispCh)) ) = [];	% 나머지 ch 제거
		Potn2D			=	squeeze(Potn2D);			% 2D 구성
	end
		Potn2D			=	shiftdim(Potn2D,1);			% time 위치를 1st 로 -]
	% 이 방식은 timtopo 에서 topo 작성을 위해서는 부적절한 접근법임.
%}

	% 그리고 다중 데이터인 경우, TopoTp 가 여러개 일지라도 단일 값으로 통일
	if any(isnan(TopoTp))
		TopoTp			=	NaN;
	else
		TopoTp			=	ones(1, size(Potn2D,1)) * TopoTp(1);
	end

%--------------------------------------------------------------------------------
else													% 단일 data 표시형
	%% 3D 라도, condi 차원이 1개 라면, squeeze 할 것.

	if 3 <= length(size(Potn2D))							% 차원 과잉
		error('\nError   : the dimension too more than 2D\n\n');
%{
		% time 과 ch 의 dim 을 찾은 후, 나머지 차원은 mean 처리.	%-[
		lenTp				=	length(PlotTp);
		lenCh				=	length(ChanNum);
		ixTp				=	find(size(Potn2D) == lenTp);
		ixCh				=	find(size(Potn2D) == lenCh);
		if ixTp < ixCh,
			Potn2D			=	reshape(Potn2D, [], lenTp, lenCh);	%3D 구조화
		else
			Potn2D			=	reshape(Potn2D, [], lenCh, lenTp);	%3D 구조화
		end
		Potn2D				=	squeeze(mean(Potn2D, 1));			% 2D 변경 -]
%}
	end

%	if fgFilter, Potn2D	=	filtfilt(bbb, aaa, Potn2D);	end % zero-phase: tp x ch
end
%{
	if length(TopoFq) ~= length(TopoTp)					% 갯수 불일치 -> 경고
		fprintf('\nWarning : differ a numbers of Topo(F:%d,T:%d)\n\n',		...
				length(TopoFq), length(TopoTp));
	end
%}
	if fgFilter
		Potn2D		=	filtfilt(bbb, aaa, Potn2D);		% zero-phase: 2D or 3D

		% 필터실행 후에는, 필히 baseline correction을 수행할 것
		Potn2D=Potn2D-repmat(mean(Potn2D(ERP_blTimWix,:,:)),size(Potn2D,1),1,1);
	end

	% --------------------------------------------------
	% 유효한 데이터만 cutting
	[ixTpStart ixTpFinish]	=	deal(	find(PlotTp == DispTp(1)),			...
										find(PlotTp == DispTp(2)) );
	if isempty(ixTpFinish), ixTpFinish = find(PlotTp == PlotTp(end)); end
%	ixTime					=	PlotTp(ixTpStart:ixTpFinish);

	if 3 <= length(size(Potn2D)) %iscell(Potn2D)
%		Potn2D		=	cellfun(@(x)({ x(ixTpStart:ixTpFinish, :) }), Potn2D);
%		Potn2D		=	cellfun(@(x)({ shiftdim(x,1) }), Potn2D);	% t*c->c*t
%		Potn2D		=	Potn2D(:, ixTpStart:ixTpFinish, :);	% cond * t * c
		Potn2D		=	Potn2D(ixTpStart:ixTpFinish, :, :);	% t * c * cond
		Potn2D		=	permute(Potn2D, [2 1 3]);		% t*c *cond->c*t *cond
	else
		Potn2D		=	Potn2D(ixTpStart:ixTpFinish, :);
		Potn2D		=	shiftdim(Potn2D,1);				% t*c->c*t
	end

	% --------------------------------------------------
%	FreqCutoff		=	30;								% display 위한 경계선
%	tStep			=	PlotTp(2) - PlotTp(1);			%시간 간격

	%% drawing 2D graph for ERP data
	if ~isempty(Condi)
		if iscell(Condi)
			sCond	=	strjoin(Condi, ', ');
			nCond	=	length(Condi);
		else
			sCond	=	Condi;
			nCond	=	1;
		end
		title		=	sprintf('Condition(%s)''s ERP plot(Ch:%s)', sCond, sCh);
%		title		=	sprintf('%d Condition''s ERP plot(Ch:%s)', nCond, sCh);
	else
		title		=	sprintf('ERP plot(Ch:%s) & Topography', sCh);
	end

	figure,
%{
%>> help timtopo															%-[
  timtopo()   - plot all channels of a data epoch on the same axis 
                and map its scalp map(s) at selected latencies.
  Usage:
   >> timtopo(data, chan_locs);
   >> timtopo(data, chan_locs, 'key', 'val', ...);
  Inputs:
   data       = (channels,frames) single-epoch data matrix
   chan_locs  = channel location file or EEG.chanlocs structure. 
                See >> topoplot example for file format.
 
  Optional ordered inputs:
   'limits'    = [minms maxms minval maxval] data limits for latency (in ms) and y-values
                  (assumes uV) {default|0 -> use [0 npts-1 data_min data_max]; 
                  else [minms maxms] or [minms maxms 0 0] -> use
                 [minms maxms data_min data_max]
   'plottimes' = [vector] latencies (in ms) at which to plot scalp maps 
                 {default|NaN -> latency of maximum variance}
  'title'      = [string] plot title {default|0 -> none}
  'plotchans'  = vector of data channel(s) to plot. Note that this does not
                 affect scalp topographies {default|0 -> all}
  'voffsets'   = vector of (plotting-unit) distances vertical lines should extend 
                 above the data (in special cases) {default -> all = standard}
 
  Optional keyword, arg pair inputs (must come after the above):
  'topokey','val' = optional topoplot() scalp map plotting arguments. See >> help topoplot 
 
  Author: Scott Makeig, SCCN/INC/UCSD, La Jolla, 1-10-98 
 
  See also: envtopo(), topoplot()											%-]

	timtopo(Potn2D,			CED,											...
			'title',		title,											...
			'plottimes',	TopoTp,											...
			'plotchans',	DispCh,											...
			'limits',		[ixTime(1) ixTime(end) DispPW DispBar],			...
			'tradeoff',		DispRatio );
%}
	timtopo(Potn2D,			CED,											...
			'title',		title,											...
			'plottimes',	TopoTp,											...
			'plotchans',	DispCh,											...
			'limits',	[PlotTp(ixTpStart) PlotTp(ixTpFinish) DispPW DispBar],...
			'tradeoff',		DispRatio );

	fname			=	[sCond '_' sCh '.jpg'];
	print('-djpeg', fname);

	return
%end function

