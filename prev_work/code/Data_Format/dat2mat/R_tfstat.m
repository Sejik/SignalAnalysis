% R_tfstat ver 0.40
%% [기 분석된 결과 토대로, 통계용 특정 구간/채널들/조건별로 max/min/mean 을 구함]
%
% [*Input Parameter]--------------------------------------------------
% LoadPath	: 데이터가 저장된 folder -> data file은 *_wxyz.mat 같은 조건포함
% SbjList	: subject list, string cell = { '02_2', '04', '07', ... };
% VarName	: name of variable, string type = 'TFe' : CAUTION : must be 3D
% tInterval	: 시간 구간, = [ -50 150 ], eEEG(tp)크기와 구간 대조하면 eFS추출
% tWin		: 관심 시간 구간, = [ 70 120 ], must small than tInterval
% cWin		: 관심 채널 목록,
% fInterval	: 주파수 구간 = [ 1/4 70 ], eEEG(fq)크기와 구간 대조하면 fBin추출
% fWin		: 관심 주파수 구간, = [ 5 30 ], must small than fInterval
% CondComb	: 조건 조합 목록
%	ex) 'F__L' 과 같이 합칠 조건은 '_'으로 표기
%	ex) { 'FSH_', 'MA__' }
% Operation	: 데이터 연산 방법, 'max' | 'min' | 'mean' | 'MAX' | 'MIN'
%	ex) max : local max only, if not, nothing : <- default
%	ex) MAX : local max first, if not, global max next
%	ex) mean: 출력 = 평균값, 시간(평균에 가장 근사치 존재), 주파수(근사치)
% SavePath	: 결과(txt형 list)의 저장 장소 및 파일 헤더 명
% blWin		: baseline correction 용 구간, = [-400 -100]
%
% [*Output Parameter]--------------------------------------------------
% SavePath 에 txt 파일들을 생성
%
% ex)
%R_tfstat('/home/minlab/Projects/SKK/SKK_3/TF', { 'su33', 'su07' }, 'TFe', [-500 1500], [ 0 500 ], { 'O2','P8', 'PO10' }, [1/4 70], [8 13], { 'F___', 'M___', 'U___' }, 'max', '/home/minlab/Projects/SKK/SKK_3/SPSS/TF', [-400 -100]);
%
%------------------------------------------------------
% first created at 2016/04/15
% last  updated at 2016/06/02
% by Ahn Min-Hee::tigoum@naver.com, Korea Univ. MinLAB.
%.....................................................
% ver 0.20 : 20160512C. amp, lat 별로 txt 파일을 분리하여 생성할 것
% ver 0.30 : 20160602A. FastPeakFind()를 이용하여 더욱 정교한 peak 찾기
% ver 0.40 : 20160602B. 각 채널별 peaks(min, max 경우) 조사 후, 탐지된 것만 평균
%------------------------------------------------------

function [ ] = R_tfstat(	LoadPath,	SbjList,	VarName,	...
							tInterval,	tWin,		cWin,		...
							fInterval,	fWin,		...
							CondComb,	...
							Operation,	...
							SavePath,	blWin)

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

if nargin <12,	blWin		=	[];	end
if nargin <11,	SavePath	=	'.';	end			% 현재 folder
if nargin <10,	Operation	=	'max';	end			% 기본 최대값
if nargin < 9,	CondComb	=	{'____'};	end		% 기본 최대값
if nargin < 6,	cWin		=	eCHNs{1};	end		% 모든 채널
%if nargin < 5,	tWin		=	tInterval;	end		% interval 과 동일하게.
if 1<= nargin & nargin <=5,	error('# of parameter not enough');	end	% 너무 부족!
if nargin < 1										% 파라미터 없으면 자동예시
%{
	LoadPath	=	'/home/minlab/Projects/SKK/SKK_3/TF';
%	LoadPath	=	'x:/Projects/SKK/SKK_3/TF';							%windows
	SbjList		=	{'su01','su02_2','su04_2','su06','su07', };
%	SbjList		=	{ '01', '02_2', '04_2', '06', '07', };
	VarName		=	'TFi';
	tInterval	=	[ -500, 1500 ];
	tWin		=	[ 0 1500 ];
	cWin		=	{ 'O1', 'Oz', 'O2' };
	fInterval	=	[ 1/4, 70 ];
	fWin		=	[ 5 13 ];
	CondComb	=	{ 'FSH_', 'MA__' };
	Operation	=	'max';
%	SavePath	=	'x:/Projects/SKK/SKK_3/Statis';						%windows
	SavePath	=	'/home/minlab/Projects/SKK/SKK_3/Statis/tfstat';
	blWin		=	[ -500 0 ];						% ERP: 일반적으로 -500
%}
	LoadPath	=	'/home/minlab/Projects/EMO_NEW/EMO_1/TF';
	SbjList		=	{'su0027','su0029','su0030','su0037','su0039', };
	VarName		=	'TFe_bl';
	tInterval	=	[ -500, 2000 ];
	tWin		=	[ 0 500 ];
	cWin		=	{ 'O1', 'Oz', 'O2' };
	fInterval	=	[ 1/4, 70 ];
	fWin		=	[ 4 13 ];
	CondComb	=	{ 'R_H', 'WN_' };
	Operation	=	'max';
	SavePath	=	'/home/minlab/Projects/EMO_NEW/EMO_1/Statis/tfstat';
	blWin		=	[ -500 0 ];						% ERP: 일반적으로 -500
end

clearvars -except	LoadPath SbjList VarName tInterval tWin cWin		...
					fInterval fWin CondComb Operation SavePath blWin eCHNs
close all;

%% notify %%
if exist('blWin', 'var') & ~isempty(blWin)			% 옵션여부 출력
	fprintf('+Option   : [%d ~ %d] baseline correction\n', blWin(1), blWin(2));
end

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
dtType			=	{ 'Pwr', 'Lat', 'Fq', };
%OUTNAME			=	sprintf('_[%s]Sbj%d,Cond%s.txt',			...
%							Operation, length(SbjList), strjoin(CondComb, ',') );
%OUTNAME			=	cellfun(@(x)({ sprintf('_Sbj%d-Cond%s-%s.txt',			...
%						length(SbjList), strjoin(CondComb, ','), x) }), dtType);
OUTNAME			=	cellfun(@(x)({ sprintf('_Sbj%d-%s.txt',			...
						length(SbjList), x) }), dtType);
%FP				=	fopen([SavePath OUTNAME], 'wt');% 파일 생성
FP				=	cellfun(@(x)( fopen([SavePath x], 'wt') ), OUTNAME);%파일생성

% 화면에 데이터를 출력해야 하므로, 우선 subject 부터 제시 한다.
%fprintf(FP,		'Subjects(%s)\t', Operation);		% 저장소에 title 구성
%fprintf(FP,		'%s', strjoin(	...
%cellfun(@(x)({sprintf('%-7s\t%-7s\t%-7s',[x '_pwr'],[x '_lat'],[x '_fq'])}), ...
%					CondComb), '\t') );
arrayfun(@(x)  ( fprintf(x, 'Subjects(%s)\t', Operation) ), FP);	% 파일별 출력
arrayfun(@(x,y)( fprintf(x, '%s', strjoin(	...			% 파일별
	cellfun(@(x)({sprintf('%-7s',[x dtType{y}])}),CondComb),'\t'))), FP, [1:3]);
	%-----
stdout			=	1;								% 화면에 출력
fprintf(stdout, 'Subjects(%s)\t', Operation);
fprintf(stdout, '%s', strjoin(	...
cellfun(@(x)({sprintf('||%-7s\t| %-7s\t| %-7s',[x '_pwr'],[x '_lat'],[x '_fq']...
			)}),	CondComb), '\t') );
fprintf('\n--------------------------------------------------------------------------------');

Total			=	tic;							%전체 연산 시간
% ===============================================================================
	Statis		=	zeros(length(SbjList), length(CondComb));	% 2D
	Latency		=	zeros(length(SbjList), length(CondComb));	% 2D
	Frequency	=	zeros(length(SbjList), length(CondComb));	% 2D
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
%		fprintf(FP, '%7s\t%-7s\t%-7s\t',	'       ', '       ', '       ');
		arrayfun(@(x)( fprintf(x, '%7s\t', '       ') ), FP);	% 파일별 출력
		fprintf('||%7s\t| %-7s\t| %-7s\t',	'       ', '       ', '       ');

		continue
	end

AllTime			=	tic;		%조건별 해당 전체 파일 연산 시간
% ===============================================================================
Data			=	cell(1,	length(GetName));		% 병렬처리용 data 저장고
parfor f = 1 : length(GetName)						% F___에 대응하는 data
%	load( GetName{f} );								% 파일 읽기
	Data{f}		=	load(GetName{f}, [VarName '*']);% 파일 읽기
%	fprintf('Loading : file from %s\n', GetName{f});	% notify file name
end	% parfor

Var				=	cell(1,	length(GetName));		% 병렬처리용 중간 변수
parfor f = 1 : length(GetName)						% F___에 대응하는 data
	% 참고: 읽어온 데이터 변수는 하나의 파일에 여러개 있으므로,
	% 그 중 VarName 에 해당하는 것만 찾아서 기록
	% n varible / 1 file -> find 1 variable in [VarName]:
%{
%	eval( [ 'VAR = whos(''-regexp'', ''[A-Z]{3}_' rCondi ''');' ] ); % 모두 수집
%	eval( [ 'VAR = whos(''-regexp'', ''' VarName '*'');' ] ); % 모두 수집
	eval( [ 'VAR = whos(''-regexp'', ''' VarName ''');' ] ); % 모두 수집
	VAR			=	struct2cell(VAR);				% 구조변경
	vName		=	VAR(1, :);						% 변수명만 추출
	vSize		=	VAR(2, :);						% 크기만 추출

	eval( [ 'Var{f} = ' vName{ixVar} ';' ]);		% 값 가져오기
	eval( [ 'clear ' vName{ixVar} ]);				% remove variable
%}
	VAR			=	regexp(fieldnames(Data{f}), [VarName '.*'], 'match'); %일치만
	VAR			=	VAR(cellfun(@(x)( ~isempty(x) ), VAR));	% 필드중 불일치 제거
	vName		=	table2cell(cell2table(VAR));	% 이중 cell 구조 flatten
	vSize		=	cellfun(@(x)({ size(Data{f}.(x)) }), vName); % Data 필드 ref

	%% 최종적으로는 매 처음 발견된 변수명을 선택하게 됨.
	%% 그러나 이것이 반드시 요구한 변수라고 확신할 방법은?
	if length(vName) >= 2
		ixVar	=	find(ismember(vName, VarName));	% 정확한 변수 idx 찾기
		if ixVar <= 0, ixVar=	1;	end				% 못 찾음, 1st 선택
	else
		ixVar	=	1;
	end

	Var{f}		=	Data{f}.( vName{ixVar} );		% 값 가져오기
	Var{f}		=	double(Var{f});					% 반드시 type 조정!

	nDim		=	length( vSize{ixVar} );			% 변수의 차원 갯수
	% 당연히 2개여야 하고, 구조는 tp x ch
	if nDim ~= 3, error('Error   : a dimension size(%d) not 3D', nDim); end

	% 최우선적으로, sampling rate 부터 구한다.
	eFS			= 1000*size(Var{f},1)/(tInterval(2)-1-tInterval(1)+1);%SmplRate
	if int32(eFS) ~= eFS, error('ERROR   : eFS(%f) value not integer', eFS); end
	% baseline correction : must have ! eEEG(tp, ep, ch)
	% 여러 조건 데이터를 합쳐서, 각 데이터의 ERP_filt_bl 과는 다른 값이기 때문
	if ~isempty(blWin)
		ix		=	ismember(	tInterval(1):1000/eFS :tInterval(2)-1,	...
								blWin(1)	:1000/eFS :blWin(2)-1 );
		% mean()으로 f x 1 x ch -> t 만 n배 확장 : f x t x ch (원래 % 크기화)
		Var{f} = Var{f}-repmat(mean(Var{f}(:,ix,:),2),[1,size(Var{f},2),1]);
	end

	fData(f, :, :, :)=	Var{f};					% 각 조건별 3D 데이터
end	% for each data

	eEEG		=	squeeze(mean(fData, 1));	% mean(F111,F112,..)->F___
	clear Data Var nDim VAR vName vSize GetName fData	% garbage 제거 위해 삭제

% ===============================================================================
	% 조건 조합에 해당하는 모든 파일들의 변수를 합산하였으므로:

	% 3D 데이터에 대해서는 baseline correction 을 할 필요가 없다.
	% 왜냐하면, eveke, total activity 들을 power 값이기 때문.

	% 채널에 대해 filter 를 수행하자
	switch size(eEEG, 3)
	case 30, eCHN	=	eCHNs{1};
	case 63, eCHN	=	eCHNs{2};
	otherwise, error('Error   : incorrect channel size(%d)', size(eEEG,3));
	end
%	eEEG		=	eEEG(:, ismember(eCHN, cWin));	% 원하는 채널만

	% 20160602B. 각 채널에 대해 개별적인 operation을 수행한 후 mean 처리함.
	%	종전의 미리 채널 평균 후 진행시, no peaks 인 경우가 너무 많음.
	%	그래서, 주어진 채널에 대해 개별적인 peaks 조사후, 탐색된 것만으로 평균!
	ixCh		=	find( ismember(eCHN, cWin) );	% extract for cWin
	eEEG		=	eEEG(:, :, ixCh);				% 원하는 채널만
%	eEEG		=	squeeze( mean(eEEG, 3) );		% 채널 평균 == 2D (fq x tp)

	eFS			=	1000 *size(eEEG,2) /(tInterval(2)-1-tInterval(1)+1);%SmplRate
	if int32(eFS) ~= eFS, error('ERROR   : eFS(%f) value not integer', eFS); end
	tBin		=	1000 / eFS;
	tIntrV		=	[ tInterval(1) : tBin : tInterval(2)-1 ];	% vector
	tWinV		=	[ tWin(1) : tBin : tWin(2)-1 ];	% vector
	ixTp		=	find( ismember(tIntrV, tWinV) );% get index

	% fBin은 간격이므로, 구간 양끝 값의 차이 갯수보다 1 적음
	fBin		=	1 / ((size(eEEG,1)-1) / (fInterval(2)-fInterval(1)) );%fq간격
	fIntrV		=	[ fInterval(1) : fBin : fInterval(2) ];		% vector
	fWinV		=	[ fWin(1) : fBin : fWin(2) ];	% vector
	ixFq		=	find( ismember(fIntrV, fWinV) );% get index

	Stat		=	zeros(1, length(cWin));			% 병렬처리 + op 결과 값
	Lat			=	zeros(1, length(cWin));			% 병렬처리 + time
	Freq		=	zeros(1, length(cWin));			% 병렬처리 + freq
parfor c = 1 : length(cWin)							% 채널에 대응하는 data
	eEEGp		=	squeeze(eEEG(ixFq, ixTp, c));	% 원하는 주파수, 시간

% ===============================================================================
	% 1D eEEG에 대해 operation을 수행하자
	% local max , min , mean
	[VL ixF ixT]=	deal( NaN, NaN, NaN );			% 초기값

	switch Operation
	case 'max'										%% local max 만 찾음
		[MX MI]	=	S_localpeaks(eEEGp, 'max');		% 2D max 찾기
	if ~isempty(MX) & ~isempty(MI)
		[VL ixF ixT]=	deal( MX, MI(1), MI(2) );
	else
		[VL ixF ixT]=	deal( NaN, NaN, NaN );		% 못 찾으면 null
	end

	case 'MAX'							% local max 먼저 찾고, 없으면, global max
%{
		[MX MI]	=	findpeaks( eEEGp(:) );			% 1D 기반 계산
	if ~isempty(MX) & ~isempty(MI)
		[VL IX]	=	max(MX);						% 최대값 및 latency
		IX		=	MI(IX);							% eEEGp 에 해당하는 idx 확보
	else											% not found local max
		[VL IX]	=	max( eEEGp(:) );				% substitute global max
	end
		[ixF ixT]=	ind2sub( size(eEEGp), IX);		% 2D 구조에 대응하는 idx 찾기
%}
		[MX MI]	=	S_localpeaks(eEEGp, 'max');		% 2D max 찾기
	if ~isempty(MX) & ~isempty(MI)
		[VL ixF ixT]=	deal( MX, MI(1), MI(2) );
	else											% not found local max
		[VL IX]	=	max( eEEGp(:) );				% substitute global max
		[ixF ixT]=	ind2sub( size(eEEGp), IX);		% 2D 구조에 대응하는 idx 찾기
	end

	case 'min'										%% local min 만 찾음
		[MN MI]	=	S_localpeaks(-eEEGp, 'min');		% 2D max 찾기
	if ~isempty(MN) & ~isempty(MI)
		[VL ixF ixT]=	deal(-MN, MI(1), MI(2) );
	else											% not found local max
		[VL ixF ixT]=	deal( NaN, NaN, NaN );		% 못 찾으면 null
	end

	case 'MIN'							% local min 먼저 찾고, 없으면, global min
%{
		[MN MI]	=	findpeaks( -eEEGp(:) );
	if ~isempty(MN) & ~isempty(MI)
		[VL IX]	=	min(-MN);						% 최소값 및 latency
		IX		=	MI(IX);							% eEEGp 에 해당하는 idx 확보
	else											% not found local min
		[VL IX]	=	min( eEEGp(:) );				% substitute global min
	end
		[ixF ixT]=	ind2sub( size(eEEGp), IX);		% 2D 구조에 대응하는 idx 찾기
%}
		[MN MI]	=	S_localpeaks(-eEEGp, 'min');		% 2D max 찾기
	if ~isempty(MN) & ~isempty(MI)
		[VL ixF ixT]=	deal(-MN, MI(1), MI(2) );
	else											% not found local min
		[VL IX]	=	min( eEEGp(:) );				% substitute global min
		[ixF ixT]=	ind2sub( size(eEEGp), IX);		% 2D 구조에 대응하는 idx 찾기
	end

	case 'mean'
		% 전체 평균, 시간기반 평균, 주파수기반 평균을 구해서 출력
		VL		=	mean( eEEGp(:) );
		[NEAR IX]=	min(abs(eEEGp(:) - VL));		% 가장 근사값 찾기
		[ixF ixT]=	ind2sub( size(eEEGp), IX);		% 2D 구조에 대응하는 idx 찾기

	otherwise
		[VL ixF ixT]	=	deal( NaN, NaN, NaN );	% default index
	end

% ===============================================================================
	% register for condition 이제 저장소에 저장
	Stat(c)		=	VL;

	% latency 계산하자: 상대idx(IX) -> 절대idx -> 상대time -> 절대time
	TM			=	( ixT +ixTp(1) -1 ) * 1000/eFS + (tInterval(1) - 1000/eFS);
%	TM			=	tIntrV( find(eEEG == VL ) );	% 다른 계산 방법
	Lat(c)		=	TM;

	% freq 계산하자: 상대idx(IX) -> 절대idx -> 상대freq -> 절대freq
	FQ			=	( ixF +ixFq(1) -1 ) * fBin + (fInterval(1) - fBin);
%	[FQ TM]		=	ind2sub(size(eEEG), find(eEEG == VL));	% 다른 계산 방법
%	[FQ TM]		=	deal( fIntrV(FQ), tIntrV(TM) );	% freq, time 동시 산출!
	Freq(c)		=	FQ;

%	clear eEEGp
end	% parfor c
	clear eEEG										% garbage 제거 위해 삭제

% ===============================================================================
	% NaN이 아닌 정규 데이터만 추출
	Stat		=	mean(Stat(~isnan(Stat)));		% 유효값 갯수 대비 평균
	Lat			=	mean(Lat(~isnan(Lat)));			% 유효값 갯수 대비 평균
	Freq		=	mean(Freq(~isnan(Freq)));		% 유효값 갯수 대비 평균

% ===============================================================================
	% 이제 결과 출력 -> 한 줄로 표기
%	fprintf(FP, '%7.3f\t%-7d\t%-7.3f\t',	Statis(ixSJ, ixCD),		...
%									Latency(ixSJ, ixCD), Frequency(ixSJ, ixCD));
	FPRINTF		=	@(fp, form, dat) ~isnan(dat) &&	fprintf(fp,form,dat) ||	...
													fprintf(fp,'%7s\t','');
	arrayfun(@(x, y) FPRINTF(x, '%7.3f\t', y),	FP, [Stat, Lat, Freq]);	% 파일별
	FPRINTF		=	@(form, dat)	~isnan(dat) &&	fprintf(form, dat)	||	...
													fprintf('%7s\t', '');
	cellfun(@(x, y) FPRINTF(x, y),	{'||%7.3f\t', '| %-7.3f\t|', ' %-7.3f\t'},...
									{Stat, Lat, Freq} );

% ===============================================================================
	% register for condition 이제 저장소에 저장
	Statis(ixSJ,ixCD)	=	Stat;
	Latency(ixSJ,ixCD)	=	Lat;
	Frequency(ixSJ,ixCD)=	Freq;
end	% for condi

end	% for sbj
%fclose(FP);
arrayfun(@(x)( fclose(x) ),	FP);
fprintf('\n================================================================================');
fprintf('\n\nFinished: total time is ');	toc(Total);

% ===============================================================================

	return
