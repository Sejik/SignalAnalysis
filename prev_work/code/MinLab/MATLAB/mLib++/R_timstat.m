% R_timstat ver 0.3
%% [기 분석된 결과 토대로, 통계용 특정 구간/채널들/조건별로 max/min/mean 을 구함]
%
% [*Input Parameter]--------------------------------------------------
% LoadPath	: 데이터가 저장된 folder -> data file은 *_wxyz.mat 같은 조건포함
% SbjList	: subject list, string cell = { '02_2', '04', '07', ... };
% VarName	: name of variable, string type = 'ERP' : CAUTION : must be 2D
% tInterval	: 시간 구간, = [ -50 150 ], eEEG(tp)크기와 구간 대조하면 eFS추출
% tWin		: 관심 시간 구간, = [ 70 120 ], must small than tInterval
% cWin		: 관심 채널 목록,
% CondComb	: 조건 조합 목록
%	ex) 'F__L' 과 같이 합칠 조건은 '_'으로 표기
%	ex) { 'FSH_', 'MA__' }
% Operation	: 데이터 연산 방법, 'max' | 'min' | 'mean' | 'MAX' | 'MIN'
%	ex) max : local max only, if not, nothing : <- default
%	ex) MAX : local max first, if not, global max next
%	ex) mean: 출력 = 평균값, 시간(평균에 가장 근사치 존재), 주파수(근사치)
% SavePath	: 결과(txt형 list)의 저장 장소 및 파일 헤더 명
% blWin		: baseline correction 용 구간, = [-400 -100]
% Filter: 필터링 주파수 범위, 예: [0.5 30](band), [5 nan](high), 기본:not
%
% [*Output Parameter]--------------------------------------------------
% SavePath 에 txt 파일들을 생성
%
% ex)
%R_timstat('/home/minlab/Projects/SKK/SKK_3/TF', { 'su33', 'su07' },  'ERP', [-500 1500], [ 0 500 ], { 'O2','P8', 'PO10' }, { 'F___', 'M___', 'U___' }, 'max', '/home/minlab/Projects/SKK/SKK_3/SPSS/TIM', [-400 -100], [0.5 30]);
%
%------------------------------------------------------
% first created at 2016/04/15
% last  updated at 2016/06/02
% by Ahn Min-Hee::tigoum@naver.com, Korea Univ. MinLAB.
%.....................................................
% ver 0.20 : 20160512C. amp, lat 별로 txt 파일을 분리하여 생성할 것
% ver 0.30 : 20160602B. 각 채널별 peaks(min, max 경우) 조사 후, 탐지된 것만 평균
%------------------------------------------------------

function [ ] = R_timstat(	LoadPath,	SbjList,	VarName,		...
							tInterval,	tWin,		cWin,			...
							CondComb,	...
							Operation,	...
							SavePath,	blWin, Filter)

POOL			=	S_paraOpen();

eCHNs	=	{		...		% 30 채널과 63 채널 label 미리 구성
		{	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',	...
			'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8',	...
					'CP5',	'CP1',	'CP2',	'CP6',			'P7',	'P3',	...
			'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' }, ...
			...
		{	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',	...
			'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8',	...
					'CP5',	'CP1',	'CP2',	'CP6',	'FCz',	'P7',	'P3',	...
			'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',  'PO10',	...
			'AF7',	'AF3',	'AF4',	'AF8',	'F5',	'F1',	'F2',	'F6',	...
			'FT9',	'FT7',	'FC3',	'FC4',	'FT8',	'FT10',	'C5',	'C1',	...
			'C2',	'C6',	'TP7',	'CP3',	'CPz',	'CP4',	'TP8',	'P5',	...
			'P1',	'P2',	'P6',	'PO7',	'PO3',	'POz',	'PO4',	'PO8' },...
			};

if nargin <11,	Filter		=	[nan nan];	end
if nargin <10,	blWin		=	[];	end
if nargin < 9,	SavePath	=	'.';	end			% 현재 folder
if nargin < 8,	Operation	=	'max';	end			% 기본 최대값
if nargin < 7,	CondComb	=	{'____'};	end		% 기본 최대값
if nargin < 6,	cWin		=	eCHNs{1};	end		% 모든 채널
%if nargin < 5,	tWin		=	tInterval;	end		% interval 과 동일하게.
if 1<= nargin & nargin <=5,	error('# of parameter not enough');	end	% 너무 부족!
if nargin < 1										% 파라미터 없으면 자동예시
%{
	LoadPath	=	'/home/minlab/Projects/SKK/SKK_3/TF';
%	LoadPath	=	'x:/Projects/SKK/SKK_3/TF';							%window
	SbjList		=	{'su01','su02','su04','su06','su07', };
%	SbjList		=	{ '01', '02_2', '04_2', '06', '07', };
	VarName		=	'ERP';
	tInterval	=	[ -500, 1500 ];
	tWin		=	[ 0 1500 ];
	cWin		=	{ 'O1', 'Oz', 'O2' };
	CondComb	=	{ 'FSH_', 'MA__' };
	Operation	=	'max';
%	SavePath	=	'x:/Projects/SKK/SKK_3/Statis';						%window
	SavePath	=	'/home/minlab/Projects/SKK/SKK_3/Statis/timstat';
	blWin		=	[ -500 0 ];						% ERP: 일반적으로 -500 ms
	Filter		=	[ 0.5 30 ];						% ERP: 일반적으로 0.5 ~ 30Hz
%}
	LoadPath	=	'/home/minlab/Projects/EMO_NEW/EMO_1/TF';
	SbjList		=	{'su0027','su0029','su0030','su0037','su0039', };
	VarName		=	'ERP';
	tInterval	=	[ -500, 2000 ];
	tWin		=	[ 0 500 ];
	cWin		=	{ 'O1', 'Oz', 'O2' };
	CondComb	=	{ 'R_H', 'WN_' };
	Operation	=	'max';
	SavePath	=	'/home/minlab/Projects/EMO_NEW/EMO_1/Statis/timstat';
	blWin		=	[ -500 0 ];						% ERP: 일반적으로 -500 ms
	Filter		=	[ 0.5 30 ];						% ERP: 일반적으로 0.5 ~ 30Hz
end

clearvars -except	LoadPath SbjList VarName tInterval tWin cWin		...
					CondComb Operation SavePath blWin Filter eCHNs
%close all;

%% notify %%
if exist('blWin', 'var') & ~isempty(blWin)			% 옵션여부 출력
	fprintf('+Option   : [%d ~ %d] baseline correction\n', blWin(1), blWin(2));
end
% Butterworth Filtering 부분.
[NONE, HIGH, LOW, BAND]	=	deal(0, 1, 2, 3);		% nmemonic
if length(find(~isnan(Filter))) >= 2				% bandpass 값 모두 정상 수치
	fgFilter	=	BAND;
	fprintf('+Option   : [Bandpass] filter\n');
elseif ~isnan(Filter(1)) % & isnan(Filter(2))		% highpass
	fgFilter	=	HIGH;
	fprintf('+Option   : [highpass] filter\n');
elseif ~isnan(Filter(2)) % & isnan(Filter(1))		% lowpass
	fgFilter	=	LOW;
	fprintf('+Option   : [lowpass] filter\n');
else												% 아무것도 안해도 됨
	fgFilter	=	NONE;
	fprintf('+Notify   : not set the filter\n');
end
fprintf('================================================================================\n');

%% setting %%
% FSHL
% If there is no node, it should work.
% 여러 조건조합이 요구될 수 있으므로, param의 type을 판독해야 함.
if ~iscell(CondComb), CondComb	=	{ CondComb }; end
nCond			=	length(CondComb{1});			% 조건의 갯수
SaveDir			=	regexprep(SavePath, '[^/]+$', '');	% dir 만 추출
if ~exist(SaveDir, 'dir'), mkdir(SaveDir); end		% dir 존재 여부 확인
% 20160411A. amp, lat 별로 파일을 개별 작성할 것.
% 20160512C. 위 사항 진행 개시.
dtType			=	{ 'Amp', 'Lat', };
%OUTNAME			=	sprintf('_Sbj%d,Cond%s.txt',			...
%							length(SbjList), strjoin(CondComb, ',') );
OUTNAME			=	cellfun(@(x)({ sprintf('_Sbj%d-%s.txt',			...
						length(SbjList), x) }), dtType);
%FP				=	fopen([SavePath OUTNAME], 'wt');% 파일 생성
FP				=	cellfun(@(x)( fopen([SavePath x], 'wt') ), OUTNAME);%파일생성

% 화면에 데이터를 출력해야 하므로, 우선 subject 부터 제시 한다.
%fprintf(FP,		'Subjects(%s)\t', Operation);		% 저장소에 title 구성
%fprintf(FP,		'%s', strjoin(	...
%	cellfun(@(x)({sprintf('%-7s\t%-7s',[x '_amp'],[x '_lat'])}),CondComb),'\t'));
arrayfun(@(x)  ( fprintf(x, 'Subjects(%s)\t', Operation) ), FP);	% 파일별 출력
arrayfun(@(x,y)( fprintf(x, '%s', strjoin(	...			% 파일별
	cellfun(@(x)({sprintf('%-7s',[x dtType{y}])}),CondComb),'\t'))), FP, [1:2]);
	%-----
stdout			=	1;								% 화면에 출력
fprintf(stdout, 'Subjects(%s)\t', Operation);
fprintf(stdout, '%s', strjoin(	...
cellfun(@(x)({sprintf('| %-7s\t| %-7s',[x '_amp'],[x '_lat'])}),CondComb),'\t'));
fprintf('\n--------------------------------------------------------------------------------');

Total			=	tic;							%전체 연산 시간
% ===============================================================================
	Statis		=	zeros(length(SbjList), length(CondComb));	% 2D
	Latency		=	zeros(length(SbjList), length(CondComb));	% 2D
for ixSJ		=	1 : length(SbjList)				% working base: subject
%	fprintf(FP,		'\n%-10s\t', sprintf('%s', SbjList{ixSJ}));	% 화면 출력
	arrayfun(@(x)( fprintf(x, '\n%-10s\t', sprintf('%s',SbjList{ixSJ})) ), FP);
	fprintf(stdout,	'\n%-10s\t', sprintf('%s', SbjList{ixSJ}));	% 화면 출력
%	FILENAME	=	sprintf('*_su%s_*.mat', SbjList{ixSJ});	% base form
	FILENAME	=	sprintf('*_%s_*.mat', SbjList{ixSJ});	% base form

% load path 에 있는 모든 data를 읽기 위해, 우선 condition 별 파일명 확보
	fName		=	ls(fullfile(LoadPath, FILENAME),'-1');%하나의 문자열로 올라옴
	fName		=	regexprep(fName, '[ ]+', '\n');	% 공백분리 항목을 라인구분
	fName		=	strsplit(fName, '\n');			% 파일별로 분리
%	fName		=	dir([ LoadPath '/*_*.mat' ]);	% 하나의 문자열로 올라옴
%	fName		=	struct2cell(fName);
%	fName		=	fName(1, :);					% 파일이름만

% ===============================================================================
for ixCD		=	1 : length(CondComb)
	sCondi		=	CondComb{ixCD};					% 전체 조건 중 현재 조건

	% scondi 에 해당하는 파일목록만 추출
%	rCondi		=	regexprep(sCondi, '[_]', '.');	% '_' -> '.' 으로 변경
	rCondi		=	regexprep(sCondi, '[_]', '[^_]');	% '_' -> '.'(_ 안됨) 변경
	ix			=	regexp(fName, ['.*_' rCondi '[.]mat'], 'match'); % match 여부
	ix			=	cellfun(@(x)( ~isempty(x) ), ix);	% 각 셀별로 비었는지
	ix			=	find( ix );						% 내용이 있는 것의 index 만
	GetName		=	fName( ix );					% 해당 파일명 확보

	if isempty(GetName)								% 파일 없으면 처리 skip
%		error('No File : exist for condition [%s] & SKIP this.\n', sCondi);
%		return %continue
		% 이제 결과 출력 -> 한 줄로 표기
%		fprintf(FP, '%7s\t%-7s\t',	'       ', '       ');
		arrayfun(@(x)( fprintf(x, '%7s\t', '       ') ), FP);	% 파일별 출력
		fprintf('| %7s\t| %-7s\t',	'       ', '       ');

		continue
	end

AllTime			=	tic;		%조건별 해당 전체 파일 연산 시간
Data			=	cell(1,	length(GetName));		% 병렬처리용 data 저장고
% ===============================================================================
parfor f = 1 : length(GetName)						%F___대응:file->Data{f} write
	Data{f}		=	load(GetName{f}, [VarName '*']);% 파일 읽기
%	fprintf('Loading : file from %s\n', GetName{f});	% notify file name
end	% parfor

InVar			=	cell(1,	length(GetName));		% 병렬처리용 중간 변수
aaa				=	cell(1,	length(GetName));		% 병렬처리용 필터 정보
bbb				=	cell(1,	length(GetName));		% 병렬처리용 필터 정보
parfor f = 1 : length(GetName)						%Data{f} read, InVar{f} write

	% 참고: 읽어온 데이터 변수는 하나의 파일에 여러개 있으므로,
	% 그 중 VarName 에 해당하는 것만 찾아서 기록
	% n varible / 1 file -> find 1 variable in [VarName]:
%{
	eval( [ 'VAR = whos(''-regexp'', ''[A-Z]{3}_' rCondi ''');' ] ); % 모두 수집
	eval( [ 'VAR = whos(''-regexp'', ''' VarName ''');' ] ); % 모두 수집
	VAR			=	struct2cell(VAR);				% 구조변경
	vName		=	VAR(1, :);						% 변수명만 추출
	vSize		=	VAR(2, :);						% 크기만 추출
	eval( [ 'InVar{f} = ' vName{1} ';' ]);			% 값 가져오기
	eval( [ 'clear ' vName{1} ]);					% remove variable
%}
	% 상기의 workspace (global) 전체 조사 및 획득 방식에서 탈피 위해,
	% struct로 받아서, 필드에 속한 변수명 추출
	VAR			=	regexp(fieldnames(Data{f}), [VarName '.*'], 'match'); %일치만
	VAR			=	VAR(cellfun(@(x)( ~isempty(x) ), VAR));	% 필드중 불일치 제거
	vName		=	table2cell(cell2table(VAR));	% 이중 cell 구조 flatten
	vSize		=	cellfun(@(x)({ size(Data{f}.(x)) }), vName); % Data 필드 ref

%	eval( [ 'InVar{f} = Data{f}.' vName{1} ';' ]);			% 값 가져오기
	InVar{f}	=	Data{f}.( vName{1} );			% 값 가져오기

	nDim		=	length( vSize{1} );	% 변수의 차원 갯수
	% 당연히 2개여야 하고, 구조는 tp x ch
	if nDim ~= 2, error('Error   : a dimension size(%d) not 2D', nDim); end

	% --------------------------------------------------
	% 최우선적으로, sampling rate 부터 구한다.
	eFS			= 1000*size(InVar{f},1)/(tInterval(2)-1-tInterval(1)+1);%SmplRate
	if int32(eFS) ~= eFS, error('ERROR   : eFS(%f) value not integer', eFS); end

	% --------------------------------------------------
	% 필터 조건에 따라, 필터링을 수행한다.
	if		fgFilter	==	BAND
%		[bbb{f} aaa{f}]	=	butter(1, [0.5 30]/(eFS/2),'bandpass');
		nOrder			=	Filter / (eFS/2);
		[bbb{f} aaa{f}]	=	butter(1, nOrder, 'bandpass'); % zero-phase filtering
	elseif	fgFilter	==	HIGH;					% highpass
		nOrder			=	Filter(1) / (eFS/2);
		[bbb{f} aaa{f}]	=	butter(1, nOrder, 'high');
	elseif	fgFilter	==	LOW;					% lowpass
		nOrder			=	Filter(2) / (eFS/2);
		[bbb{f} aaa{f}]	=	butter(1, nOrder, 'low');
	end
	% 필터실행 후에는, 필히 baseline correction을 수행할 것
	if fgFilter,	InVar{f} = filtfilt(bbb{f}, aaa{f}, InVar{f}); end	% tp x ch

	% --------------------------------------------------
	% baseline correction : must have ! eEEG(tp, ep, ch)
	% 여러 조건 데이터를 합쳐서, 각 데이터의 ERP_filt_bl 과는 다른 값이기 때문
	if ~isempty(blWin)
		ix		=	ismember(	tInterval(1):1000/eFS :tInterval(2)-1,	...
								blWin(1)	:1000/eFS :blWin(2)-1 );
		InVar{f}= InVar{f} -repmat(mean(InVar{f}(ix,:)), [size(InVar{f},1),1,1]);
	end

	fData(f, :, :)=	InVar{f};						% 각 조건별 2D 데이터
end	% for each data

	eEEG		=	squeeze(mean(fData, 1));		% mean(F111,F112,..)->F___
	clear Data InVar aaa bbb nDim VAR vName vSize GetName fData	% garbage 제거용

% ===============================================================================
	% 조건 조합에 해당하는 모든 파일들의 변수를 합산하였으므로:

	% 채널에 대해 filter 를 수행하자
	switch size(eEEG, 2)
	case 30, eCHN	=	eCHNs{1};
	case 63, eCHN	=	eCHNs{2};
	otherwise, error('Error   : incorrect channel size(%d)', size(eEEG,2));
	end
%	eEEG		=	eEEG(:, ismember(eCHN, cWin));	% 원하는 채널만

	% 20160602B. 각 채널에 대해 개별적인 operation을 수행한 후 mean 처리함.
	%	종전의 미리 채널 평균 후 진행시, no peaks 인 경우가 너무 많음.
	%	그래서, 주어진 채널에 대해 개별적인 peaks 조사후, 탐색된 것만으로 평균!
	ixCh		=	find( ismember(eCHN, cWin) );	% extract for cWin
	eEEG		=	eEEG(:, ixCh);					% 원하는 채널만
%	eEEG		=	squeeze( mean(eEEG, 2) );		% 채널 평균 == 1D (tp)

	% 20160324A. tInterval의 경계값에서 문제 발생
	% -500 ~ 1500 의 시간을 제시하는데, 실제 데이터는 1000개 라면,
	% [-500 , 1500) 이 됨. 따라서, eFS 값이 정수인지 아닌지 조사 필요
	eFS			=	1000 *size(eEEG,1) /(tInterval(2)-1-tInterval(1)+1);%SmplRate
	if int32(eFS) ~= eFS, error('ERROR   : eFS(%f) value not integer', eFS); end
	tIntrV		=	[ tInterval(1) : 1000/eFS : tInterval(2)-1 ];	% vector
	tWinV		=	[ tWin(1) : 1000/eFS : tWin(2)-1 ];	% vector
	ixTp		=	find( ismember(tIntrV, tWinV) );	% get index

	Stat		=	zeros(1, length(cWin));			% 병렬처리 + op 결과 값
	Lat			=	zeros(1, length(cWin));			% 병렬처리 + time
parfor c = 1 : length(cWin)							% 채널에 대응하는 data
	eEEGp		=	squeeze(eEEG(ixTp, c));			% 원하는 주파수, 시간

% ===============================================================================
	% 1D eEEG에 대해 operation을 수행하자
	% local max , min , mean
	% -> 단 못 찾으면, global min/max
	[VL IX]		=	deal( NaN, NaN );				% 초기값

	switch Operation
	case 'max'			% 먼저 peak을 찾고, 그 중 최대에 대한 val & ix 구하기
%{
		[MX MI]	=	findpeaks( eEEGp );				% 1D 기반 계산
	if ~isempty(MX) & ~isempty(MI)
		[VL IX]	=	max(MX);						% 최대값 및 latency
		IX		=	MI(IX);							% eEEGp 에 해당하는 idx 확보
	else											% not found local max
		[VL IX]=	deal( NaN, NaN );				% 못 찾으면 null
	end
%}
		[MX MI]	=	S_localpeaks(eEEGp, 'max');		% 2D max 찾기
	if ~isempty(MX) & ~isempty(MI)
		[VL IX]	=	deal( MX, MI(1) );
	else											% not found local max
		[VL IX]	=	deal( NaN, NaN );				% 못 찾으면 null
	end

	case 'MAX'			% 먼저 peak을 찾고, 그 중 최대에 대한 val & ix 구하기
		[MX MI]	=	S_localpeaks(eEEGp, 'max');		% 2D max 찾기
	if ~isempty(MX) & ~isempty(MI)
		[VL IX]	=	deal( MX, MI(1) );
	else											% not found local max
		[VL IX]	=	max( eEEGp(:) );				% substitute global max
	end


	case 'min'
%{
		[MN MI]	=	findpeaks( -eEEGp );
	if ~isempty(MN) & ~isempty(MI)
		[VL IX]	=	min(-MN);						% 최소값 및 latency
		IX		=	MI(IX);							% eEEGp 에 해당하는 idx 확보
	else
		[VL IX]=	deal( NaN, NaN );				% 못 찾으면 null
	end
%}
		[MN MI]	=	S_localpeaks(-eEEGp, 'min');	% 2D max 찾기
	if ~isempty(MN) & ~isempty(MI)
		[VL IX]	=	deal(-MN, MI(1) );
	else											% not found local max
		[VL IX]	=	deal( NaN, NaN );				% 못 찾으면 null
	end

	case 'MIN'
		[MN MI]	=	S_localpeaks(-eEEGp, 'min');	% 2D max 찾기
	if ~isempty(MN) & ~isempty(MI)
		[VL IX]	=	deal(-MN, MI(1) );
	else											% not found local min
		[VL IX]	=	min( eEEGp(:) );				% substitute global min
	end

	case 'mean'
		VL		=	mean( eEEGp );
		[NEAR IX]=	min(abs(eEEGp(:) - VL));		% 가장 근사값 찾기

	otherwise
		[VL IX]=	deal( NaN, NaN );				% default index
	end

% ===============================================================================
	% register for condition 이제 저장소에 저장
	Stat(c)		=	VL;

	% latency 계산하자: 상대idx(IX) -> 절대idx -> 상대time -> 절대time
	TM			=	( IX +ixTp(1) -1 ) * 1000/eFS + (tInterval(1) - 1000/eFS);
%	TM			=	tIntrV( find(eEEG == VL ) );	% 다른 계산 방법
	Lat(c)		=	TM;

%	clear eEEGp
end	% parfor c
	clear eEEG										% garbage 제거 위해 삭제

% ===============================================================================
	% NaN이 아닌 정규 데이터만 추출
	Stat		=	mean(Stat(~isnan(Stat)));		% 유효값 갯수 대비 평균
	Lat			=	mean(Lat(~isnan(Lat)));			% 유효값 갯수 대비 평균

% ===============================================================================
	% 이제 결과 출력 -> 한 줄로 표기
%	fprintf(FP, '%7.3f\t%-7d\t',	Statis(ixSJ, ixCD),	Latency(ixSJ, ixCD) );
%	arrayfun(@(x, y)( fprintf(x, '%7.3f\t', y) ),							...
%					FP, [Statis(ixSJ, ixCD), Latency(ixSJ, ixCD)]);	% 파일별 출력
%	fprintf('| %7.3f\t| %-7d\t',	Statis(ixSJ, ixCD),	Latency(ixSJ, ixCD) );
	FPRINTF		=	@(fp, form, dat) ~isnan(dat) &&	fprintf(fp,form,dat) ||	...
													fprintf(fp,'%7s\t','');
	arrayfun(@(x, y) FPRINTF(x, '%7.3f\t', y),	FP, [Stat, Lat]);	% 파일별 출력
	FPRINTF		=	@(form, dat)	~isnan(dat) &&	fprintf(form, dat)	||	...
													fprintf('%7s\t', '');
	cellfun(@(x, y) FPRINTF(x, y),	{'|%7.3f\t', '| %-7.3f\t'}, {Stat, Lat} );

% ===============================================================================
	% register for condition 이제 저장소에 저장
	Statis(ixSJ,ixCD)	=	Stat;
	Latency(ixSJ,ixCD)	=	Lat;
end	% for condi

end	% for sbj
%fclose(FP);
arrayfun(@(x)( fclose(x) ),	FP);
fprintf('\n================================================================================');
fprintf('\n\nFinished: total time is ');	toc(Total);

% ===============================================================================

	return
