function [ hEEG ] = A_global_AmH()
%--------------------------------------------------------------------------------
%% project용 parameter를 설정: 데이터에서 feature, classification
%--------------------------------------------------------------------------------

	%% initialize variables
	% the experiment condition that is to be classified
	hEEG.Condi		=	{ 'TopDown', 'Intermediate', 'BottomUp', };
	%----------------------------------------------------------------------------
	hEEG.SmplRate	=	500;								% sampling rate
	fBin			=	1/2;
	hEEG.FreqBins	=	fBin;								% freq step

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 기본 구조는 밭 '전' 자의 가로와 세로에 각기 다른 주파수를 할당하고 조합함
%		┏┳┓
%		┣╋┫
%		┗┻┛
% 위 그림에 대해 아래와 같이 주파수를 배당함.
%
%%		5.5 6.5 7.5
%%		|	|	|
%% 5.0- ┏  ┳  ┓	R1
%% 6.0- ┣  ╋  ┫	R2
%% 7.0- ┗  ┻  ┛	R3
%%		C1	C2	C3
%
% 이를 기준으로 아래와 같이 구성되는 문자별로 주파수 조합(harmonic)이 결정됨
% tgr	R/C		char	R-freq	C-freq
% 1x1	R1C3	(┓)	5.0 Hz	7.5 Hz
% 1x2	R3C1	(┗)	7.0 Hz	5.5 Hz
% 1x3	R2C1	(┣)	6.0 Hz	5.5 Hz
% 1x4	R2C3	(┫)	6.0 Hz	7.5 Hz
% 1x5	R3C2	(┻)	7.0 Hz	6.5 Hz
% 1x6	R1C2	(┳)	5.0 Hz	6.5 Hz
%	-> tgr 1x. 에서 x == 1(top down), 2(intermediate), 3(bottom up)
	%----------------------------------------------------------------------------
	% COI == class of interest, ( == stimulus frequency)
		COIbase1st	=	{ [5] [7] [6] [6] [7] [5] };
		COIbase2nd	=	{ [7.5] [5.5] [5.5] [7.5] [6.5] [6.5] };
%		COIbase		=	{ [5 7.5] [5.5 7] [5.5 6] [7.5 6] [6.5 7] [6.5 5] };
		COIbase		=	cellfun(@(x,y)({ [x y] }), COIbase1st, COIbase2nd);%결합
		COIbaseBT	=	{ [5] [6] [7] [5.5] [6.5] [7.5] };			% bottom up용
%		COIsum		=	{ [5+7.5] [7+5.5] [6+5.5] [6+7.5] [7+6.5] [5+6.5] };
		COIsum		=	cellfun(@(x,y)({ [x+y] }), COIbase1st, COIbase2nd);%덧셈
%		COIbs_sum	=	{ [5 7.5 5+7.5] [7 5.5 7+5.5] [6 5.5 6+5.5] ... %{base+%}
%						  [6 7.5 6+7.5] [7 6.5 7+6.5] [5 6.5 5+6.5] };	% harmon
%		COIBsSm		=	cellfun(@(x,y)({ [x y] }), COIbase, COIsum);  % base+sum
		COIharm1st	=	cellfun(@(x)({ x*2 }), COIbase1st);				% harmon
		COIharm2nd	=	cellfun(@(x)({ x*2 }), COIbase2nd);				% harmon
%		COIharm		=	cellfun(@(x)({ x*2 }), COIbase);				% harmon
		COIharm		=	cellfun(@(x,y)({ [x y] }), COIharm1st, COIharm2nd);%결합
		COIharmBT	=	cellfun(@(x)({ x*2 }), COIbaseBT);				% harmon
		COIBsHm1st	=	cellfun(@(x,y)({ [x y] }), COIbase1st, COIharm1st);%1st만
		COIBsHm2nd	=	cellfun(@(x,y)({ [x y] }), COIbase2nd, COIharm2nd);%2nd만
		COIBsHm		=	cellfun(@(x,y)({ [x y] }), COIbase, COIharm); % base+harm
		COIBsHmBT	=	cellfun(@(x,y)({ [x y] }), COIbaseBT, COIharmBT);
		COIBsHmSm	=	cellfun(@(x,y,z)({ [x y z] }), COIbase, COIharm, COIsum);
	% COI는 각 셀당 자극 갯수만큼 요소를 가져야함. 따라서 2차원 cell type 구성
%	hEEG.COI		=	{ COIBsHm };

	% 20160223A. CCA에서 bottom-up은 한번에 1개의 주파수(1st harmonic도 해당
	%	주파수만)만 줄 수 있음. 예를 들어, 'ㄱ' 에 대해 5Hz(그리고 10) 만 줄 것
	% 이와 같은 구조로 인해, top down, intermediate, bottom up 별로 COI를 각각
	%	구성해야 함.
%		COI_topdown	=	{ COIBsHmSm };
%		COI_intermdt=	{ COIBsHmSm };
%		COI_bottomup=	{ COIBsHmBT  };
	% COI는 각 셀당 자극 갯수만큼 요소를 가져야하고, 또한 실험조건별로 각각 구분.
	% 따라서 3차원 cell type 구성
%	hEEG.COI		=	{ COI_topdown, COI_intermdt, COI_bottomup };
	hEEG.COI		=	{ COIBsHmSm, COIBsHmSm, COIBsHmBT };

	%----------------------------------------------------------------------------
	% FOI == band of interest
		%% 10:0.5:15 는 first harmonic && 가로와 세로의 주파수 합 포함!
		%% 다른 방법: 가로+세로 주파수 합 only , 그리고 곱 only
	if isfield(hEEG, 'COI')									% COI 존재->기반 구성
		%%[20160221A 참고] COI는 CCA를 위해 구성되는 것이기도 하며, 이 경우,
		% 각 marker에 대응하는 freq가 할당되므로, f 갯수와 marker 수가 일치한다.
		% -> 즉, sparse 주파수 분석만 가능
		% 이와 달리, LDA 계통은 여러 주파수 범위를 할당 할 수 있으므로,
		% - 그래서 어떤 주파수가 상관성 있는지 조사 가능 하다.
		% -> sparse 뿐만 아니라, whole 주파수 분석도 가능하다.
		%
		% 이런 이유로, COI와 대조를 위한 분석시, LDA도 sparse 분석만 가능함
		%	COI는 2D 구조의 cell 이므로, flatten 시켜야 함.
%		hEEG.FOI=cellfun(@(x)({unique(table2array(cell2table(x)))}),hEEG.COI{1});
		% sparse COI : whole FOI 구성
%		hEEG.FOI	=	{ [min(hEEG.FOI{1}):fBin:max(hEEG.FOI{1})] };

		% FOI도 COI처럼 조건별로 각자 구성
%		hEEG.FOI		=	cellfun(@(y)({	...
%			cellfun(@(x)({unique(table2array(cell2table(x)))}),y) }), hEEG.COI);
		% sparse COI : whole FOI 구성, 2D cell 구조
%		hEEG.FOI	=	cellfun(@(y)({	...
%			cellfun(@(x)({ [min(x):fBin:max(x)] }), y) }), hEEG.FOI);

		hEEG.FOI	=	{ [5:fBin:13.5] };
	else
		FOIbase		=	[ 5:fBin:7.5 ];
		FOIsum		=	[ 5+7.5 5.5+7 5.5+6 7.5+6 6.5+7 6.5+5 ];
		FOIharmonic	=	[ FOIbase(1)*2:fBin:FOIbase(end)*2 ];
		FOIcombi	=	[ FOIbase*2 FOIsum ];
		FOIext		=	[ FOIbase FOIsum];
		FOImul		=	[ 5*7.5 5.5*7 5.5*6 7.5*6 6.5*7 6.5*5 ];
%		FOImul		=	[ 20 22 24 26 28 30 ];
%		hEEG.FOI	=	[ unique(FOIsum) unique(FOImul) ];
%		hEEG.FOI	=	{ [FOIbase] [unique(FOIsum)] [unique(FOImul)] };
%		hEEG.FOI	=	{ [FOIbase] [unique(FOIsum)] };
%		hEEG.FOI	=	{ [FOIbase] };
%		hEEG.FOI	=	{ [unique(FOIharmonic)] };
%		hEEG.FOI	=	{ [FOIbase] [unique(FOIcombi)] };
%		hEEG.FOI	=	{ [FOIbase] [unique(FOIext)] };
%		hEEG.FOI	=	{ [FOIbase] [unique(FOIsum)] [unique([FOIbase FOIsum])]};
		hEEG.FOI	=	{ [unique([FOIbase FOIsum])] [5:fBin:13.5] };
		% FOI도 COI처럼 조건별로 각자 구성
%		hEEG.FOI	={	{ [unique([FOIbase FOIsum])] [5:fBin:13.5] } ...
%						{ [unique([FOIbase FOIsum])] [5:fBin:13.5] } ...
%						{ [unique([FOIbase FOIsum])] [5:fBin:13.5] } };
						% 3rd cell: 5 ~ 13.5Hz 가 최종체계 : 20160201A
	end
	%----------------------------------------------------------------------------
	hEEG.sFOI		=	{							...
'over stimulation frequencies',						...
'over sum combination of stimulation frequencies',	...
'over base+sum combination of stimulation frequencies',	...
						};		% FOI matched string
%'over first harmonics of stimulation frequencies',	...
%'over multiple combination of stimulation frequencies',	...
%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%	hEEG.FreqWindow	=	[2, 50];							% or [4, 30]
	hEEG.FreqWindow	=[min([4 cell2mat(hEEG.FOI)]), max([30 cell2mat(hEEG.FOI)])];
%	hEEG.FreqWindow	=	cellfun(@(y)({	...
%arrayfun(@(x)({[min([4 cell2mat(x)]),max([30 cell2mat(x)])]}), y) }), hEEG.FOI);
	%----------------------------------------------------------------------------
%	hEEG.DataPoint	=	5000 * nFolds * Stimulus;			% 데이터의 총 길이
%	hEEG.TimeWindow	=	[0, 5000];			% 0~5000msec
	hEEG.tInterval	=	[-2000, 5000];						% -2000~5000msec
%%	hEEG.tInterval	=	[0, 5000];							% 0 ~ 5000msec
	hEEG.TimeWindow	=	[0, 5000];							% 0 ~ 5000msec
%	hEEG.OverlapWin	=	0;	% 200, 앞 신호와 뒷 신호 사이의 겹침 time point 범위
	%----------------------------------------------------------------------------
	hEEG.fFolds		=	{ [1:4] };							% 4 session file
%%	hEEG.fFolds		=	{ [1 2] [3 4] };					% 4 session 2 cat
%	hEEG.fFolds		=	{ [1] [2] [3] [4] };				% 4 session each
%%	hEEG.fFolds		=	arrayfun(@(x)({ [x] }), [1:4]);		% 4 session each
	%% 20160302A. 새로운 시도를 위해 원래 측정된 fold data 갯수와
	%				분석 파라미터로서의 nfold 값을 분리하여 지정
	hEEG.nFolds		=	10;									% 4 session
%	hEEG.nFolds		=	16;									% 두배로 구성
%	hEEG.fgFolds	=	0;									% 세션 모두 합침?
	hEEG.nChannel	=	30;									% 살펴 볼 총 채널 수
	hEEG.ChSide		=	{	'EOG'	};						% 부가적인 분석용
	hEEG.Chan		=	{	'O1',	'Oz',	'O2',	hEEG.ChSide{:},	};
%{
	hEEG.ChRemv		=	{	'not',	'NULL*',	};			% 불필요 채널
	hEEG.ChRemv		=	{	'not',	'NULL*',	'*EOG*'	};	% 불필요 채널
	hEEG.ChRemv={		'not',	...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
						'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
				% EOG 만 계산 위해, 나머지는 모두 제거 (맨 처음에 꼭 'not' 달기)
	hEEG.ChRemv={		'not',	...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
						'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',			'O2',	'PO10' };
				% Oz 계산 위해, 나머지 모두 제거(맨 처음에 꼭 'not' 달기)
	hEEG.ChRemv={		'not',	...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
						'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',							'PO10' };
				% O1, Oz, O2 계산 위해, 나머지 모두 제거(맨 처음에 꼭 'not' 달기)
%}

	hEEG.PATH		=	'/home/minlab/Projects/SSVEP_NEW/SSVEP_3';
	hEEG.Src		=	'eEEG';
	hEEG.Dest		=	fullfile(hEEG.PATH, 'Results');
	% accuracy : hEEG.Dest/decoding_accuracy/ 에 출력
	% pattern  : hEEG.Dest/classifier_patterns/ 에 출력
	% fft power: hEEG.Dest/power_spectra/ 에 출력

%	all_list		=	1:33;							% list of subject indices
	if exist(fullfile(hEEG.PATH, hEEG.Src))
%		[lAllSbj, Head, Common]=S05sbjlist_AmH([hEEG.PATH '/eEEG.Inlier/']);
%		[lAllSbj, Head, Common, FileExt]=S05sbjlist_AmH([hEEG.PATH '/eEEG/']);
	[lAllSbj, Head,Common, FileExt] = S_sbjlist(fullfile(hEEG.PATH, hEEG.Src));
	else
	[lAllSbj, Head,Common, FileExt] = S_sbjlist(fullfile(hEEG.PATH, '/Export/'));
	end
	hEEG.Head		=	Head;
	hEEG.Allier		=	cellfun(@(x)({x{1}}), lAllSbj);	% 1st 요소만 추출
%exc_list	=	[ 2 5 7 9 14 15 16 17 21 25 26 27 28 32 ];	% list for exclude
	hEEG.Outlier	=	{ };	% { 'su0002', };
	hEEG.Inlier		=	hEEG.Allier(find(~ismember(hEEG.Allier, hEEG.Outlier)));
%		Allier	: 모든 피험자 목록, ex:{ { 'su0001, 'su0001, 'su0001_1' },...}
%		Outlier	: 제외 목록, ex: { 'su0001', 'su0002', ... }

	return

