%% SSVEP의 실험 구성: 6자극 * 10번 * 4회 * 3조건
%% 스벤요구: 조건당 4개 파일, 즉, 조건별 4회 측정하므로, 각 측정별로 파일화
%%	따라서, 1 파일에는 6자극 * 10번 의 데이터가 시간흐름 그대로 저장될 것.
%%	1자극에 대한 segment는 5초 이므로, 1 파일에는 60개*5초=300초 분 데이터
% BA에서는 segmentation을 조건(top-down, intermediate, bottom-up)별로 분리
%	하는 것은 가능했지만, 이렇게 segment 된 것은 다시 300분씩 묶는 것이 안됨.
%	그래서, 조건별 segmentation만 한 후, matlab 코드에서 분리하기로 함.

%{
function [	fullPATH, Regulation,							...		%-[
			hEEG.Chan, hEEG.ChRemv, dataname, trialname, subname				...
			Freqs, fName, m, ki, cedPATH,	FileExt	]	=	A_globals_AmH( )
%--------------------------------------------------------------------------------
%% 각 m 파일들이 사용하는 전역변수를 공유하도록 구성한다.
%--------------------------------------------------------------------------------

%global	NUMWORKERS;			%define global var for parallel tool box!!

% 실험 하나에 쓰이는 모든 코드에 동일하게 복사/붙이기 해놓는 것이 편합니다.
%
% hEEG.Chan: 1번 부터 32번 까지 각각 번호에 맞게 채널이름 지정. 분석에 직접적으로 필요하지는 않지만 사용하는 데이터가
% 어느 채널에서 왔는지 확인하거나 디스플레이할 때 쓰면 됩니다.
%
% dataname, trialname: 실험 패러다임에 따라 알맞게 유동적으로 바꿔주면 됩니다.
%
% subname: 피험자 리스트. Outlier가 생길 경우 이 리스트에서도 빼주면 됩니다.

%NUMWORKERS	=	20;
%fullPATH	=	'/home/minlab/PLV_theta';
%fullPATH	=	'/home/minlab/Projects/SSVEP_NEW/SSVEP_2';	% nothing, PURE!
fullPATH	=	'/home/minlab/Projects/SSVEP_NEW/SSVEP_3';	% ocular corr ONLY
Regulation	=	'_';	%'Condi'; %'BaselineCorrection_Imagery';
hEEG.Chan	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
hEEG.ChRemv	={	'NULL'	};	%제거할 채널
%selchan		={};				%hEEG.Chan - hEEG.ChRemv
%{
subname		={																...
				{ 'su0001',		'su0001', 'su0001_01', 'su0001_02', },	...
				{ 'su0002',		'su0002', 'su0002_topdown', },			...
				{ 'su0003',		'su0003_01', },						...
				{ 'su0004',		'su0004', },							...
				{ 'su0005',		'su0005', },							...
				{ 'su0006',		'su0006', 'su0006_2', },				...
				{ 'su0007',		'su0007', },							...
				{ 'su0008',		'su0008', },							...
				{ 'su0009',		'su0009', 'su0009_2', },				...
				{ 'su0010',		'su0010', 'su0010_2', },				...
				{ 'su0011',		'su0011', },							...
				{ 'su0012',		'su0012', 'su0012_2', },				...
				{ 'su0013',		'su0013', },							...
				{ 'su0014',		'su0014', },							...
				{ 'su0015',		'su0015', },							...
				{ 'su0016',		'su0016', },							...
				{ 'su0017',		'su0017', },							...
				{ 'su0018',		'su0018', 'su0018_2', },				...
				{ 'su0019',		'su0019', },							...
				{ 'su0020',		'su0020', },							...
				{ 'su0021',		'su0021', },							...
				{ 'su0022',		'su0022', },							...
				{ 'su0023',		'su0023', },							...
				{ 'su0024',		'su0024', },							...
				{ 'su0025',		'su0025', },							...
				{ 'su0026',		'su0026', },							...
				{ 'su0027',		'su0027', 'su0027_2', 'su0027_3', },	...
				{ 'su0028',		'su0028', 'su0028_2', },	...
				{ 'su0029',		'su0029', },							...
				{ 'su0030',		'su0030', },							...
				{ 'su0031',		'su0031', },							...
				{ 'su0032',		'su0032', },							...
				{ 'su0033',		'su0033', },							...
			};
%}
%subname		={	{ 'su0004', 'su0004', },	};
[Head, Common, subname, FileExt]	=	S_sbjlist([ fullPATH '/Export/' ]);
%dataname	=[	11:16 21:26 31:36	];				% trial 그룹핑: 총 6 * 3 개
dataname	={	'TopDown', 'Intermediate', 'BottomUp' };	% original 측정 순서
trialname	=[	6, 10, 4	];				%6자극, 10번, 4회, 3조건(위 dataname)

Freqs		=[	1:1/2:50	];				% 전 대역을 잡는다: step 0.5
fName		=AmHlib_get_freqname(Freqs);	% 주파수 대역의 이름을 식별
m	=	7;	ki	=	5;						% wavelet 분석을 위한 default 값

%cedPATH		=	[ fullPATH '/../MATLAB/Standard-10-10-Cap32.ced' ];
%cedPATH		=	[ fullPATH '/../MATLAB/EEG_32chan.ced' ];
					% cedPATH를 다른 용도(blCUT)로 사용한다.
					% blCUT: 데이터가 너무 길 때, 앞쪽 제거(f) 하는 경우만 표기
cedPATH			={									...
					{ 'su0002', 'f', },				...
					{ 'su0012', 'f', },				...
					{ 'su0018', 'f', },				...
					{ 'su0027', 'f', },				...
					};										% 앞 것 제거	%-]
%}
function [ hEEG ] = A_global_AmH()
%--------------------------------------------------------------------------------
%% project용 parameter를 설정: 데이터에서 feature, classification
%--------------------------------------------------------------------------------

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
%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	hEEG.Version	=	3;									% version !!!

	%% initialize variables
	% the experiment condition that is to be classified
	hEEG.Cond		=	{ 'TopDown', 'Intermediate', 'BottomUp', };
	hEEG.nStimuli	=	6;									% 6개 자극
	hEEG.nPresent	=	10;									% 10번 제시/ 자극 당
	hEEG.nSession	=	4;									% 4회 실험

	hEEG.fgDelTailName=	false;	% 파일 이름에서 su00xx 까지만 유지, 뒤 tail 제거
	hEEG.fgExportMat=	true;	% mat 파일로 저장
	hEEG.fgExportTxt=	false;	% txt 파일로 저장

	hEEG.fgSplitSession=true;	% 데이터의 각 session 별로 저장, false 면 Epoch별
	hEEG.fgSplitEpoch=	false;	% epoch별 저장, false== Session별
								%% 둘다 false: single 파일로 출력
	if hEEG.fgSplitSession & hEEG.fgSplitEpoch
		error('It is impossible splitting that both true of Session & Epoch');
	end

	hEEG.fgRename	=	true;	% rename table 을 기반으로 원래명 -> 변경명 수행
%	hEEG.fgSeperateDir=	false;	% 각 sbj 별로 directory 별도 구분 저장: 미지원

	hEEG.fgInvTime	=	false;								% 시간역순 재배열

	%----------------------------------------------------------------------------
%	hEEG.SmplRate	=	500;								% sampling rate
	hEEG.FreqWindow	=	[5, 13.5];							% freq win
	hEEG.FreqBins	=	1/2;								% freq step

%	hEEG.FreqWindow	=	[2, 50];							% or [4, 30]
%	hEEG.FreqWindow	=[min([4 cell2mat(hEEG.BOI)]), max([30 cell2mat(hEEG.BOI)])];
%	hEEG.FreqWindow	=	cellfun(@(y)({	...
%arrayfun(@(x)({[min([4 cell2mat(x)]),max([30 cell2mat(x)])]}), y) }), hEEG.BOI);
	%----------------------------------------------------------------------------
%	hEEG.DataPoint	=	5000 * nFolds * Stimulus;			% 데이터의 총 길이
%	hEEG.TimeWindow	=	[0, 5000];			% 0~5000msec
	hEEG.tInterval	=	[-2000, 5000];						% -2000~5000msec
%%	hEEG.tInterval	=	[0, 5000];							% 0 ~ 5000msec
	hEEG.TimeWindow	=	[-2000, 5000];						% -2000 ~ 5000msec
%	hEEG.TimeWindow	=	[0, 5000];							% 0 ~ 5000msec
%	hEEG.OverlapWin	=	0;	% 200, 앞 신호와 뒷 신호 사이의 겹침 time point 범위

	hEEG.blTimeWin	=	[-2000, -1500];						% baseline correction
	%----------------------------------------------------------------------------
	hEEG.lFolds		=	{ [1:hEEG.nSession] };				% 4 session cat
%%	hEEG.lFolds		=	{ [1 2] [3 4] };					% 4 session 2 cat
%	hEEG.lFolds		=	{ [1] [2] [3] [4] };				% 4 session each
%%	hEEG.lFolds		=	arrayfun(@(x)({ [x] }), [1:4]);		% 4 session each
	%% 20160302A. 새로운 시도를 위해 원래 측정된 fold data 갯수와
	%				분석 파라미터로서의 nfold 값을 분리하여 지정
	hEEG.nFolds		=	hEEG.nSession;						% 4 session
%	hEEG.nFolds		=	16;									% 두배로 구성
%	hEEG.fgFolds	=	0;									% 세션 모두 합침?
	hEEG.nChannel	=	30;									% 살펴 볼 총 채널 수
	hEEG.Chan		=	{		...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
	hEEG.ChRemv		=	{	'not',	'NULL',	};				% 불필요 채널
%	hEEG.ChRemv		=	{	'not',	'NULL',	'EOG'	};		% 불필요 채널
	hEEG.ixLive		=	find(~ismember(hEEG.Chan, hEEG.ChRemv) );%살아있는 채널만
	hEEG.ixRemv		=	find( ismember(hEEG.Chan, hEEG.ChRemv) );%죽어있는 채널만

%	hEEG.PATH		=	'/home/minlab/Projects/SSVEP_NEW/SSVEP_3';
	hEEG.PATH = ['/home/minlab/Projects/SSVEP_NEW/SSVEP_' num2str(hEEG.Version)];
	hEEG.PrjName	=	strsplit(hEEG.PATH, '/');			% 프로젝트 이름만
	hEEG.PrjName	=	char(hEEG.PrjName(end-1));			% except Method
	hEEG.SrcDir		=	'Export';
	hEEG.Src		=	fullfile(hEEG.SrcDir, [hEEG.PrjName '_' ]);
	if hEEG.fgInvTime
		hEEG.Dest	=	fullfile('iEEG.0~5000', [hEEG.PrjName '_' ]);
	else
%		hEEG.Dest	=	fullfile('gEEG.0~5000', [hEEG.PrjName '_' ]);	%grd avg
		hEEG.Dest	=	fullfile('eEEG', [hEEG.PrjName '_' ]);
	end
	hEEG.eConTag	=	'eCon';								% eConnectome용 tag
%	all_list		=	1:33;							% list of subject indices
%	if exist([ hEEG.PATH '/eEEG.Inlier' ])
%[Head, Common, lAllSbj, FileExt]=S_sbjlist([hEEG.PATH '/eEEG.Inlier/']);
%	else
	[lAllSbj, Head, Common, FileExt] = S_sbjlist([hEEG.PATH '/' hEEG.SrcDir]);
%	end
	hEEG.HeadName	=	Head;
	hEEG.Common		=	Common;								% common name
	hEEG.OutRemv	=	Common;								% remove on out_name
	hEEG.ExtName	=	FileExt;

	hEEG.Allier		=	cellfun(@(x)({x{1}}), lAllSbj);	% 1st 요소만 추출
%exc_list	=	[ 2 5 7 9 14 15 16 17 21 25 26 27 28 32 ];	% list for exclude
	hEEG.Outlier	=	{							...
					'su0002',						...
					'su0005',						...
					'su0007',						...
					'su0009',						...
					'su0014',						...
					'su0015',						...
					'su0016',						...
					'su0017',						...
					'su0021',						...
					'su0025',						...
					'su0026',						...
					'su0027',						...
					'su0028',						...
					'su0032',						...
					};
	% renaming table
%{
	SSVEP_NEW_su0001	->	SSVEP_NEW_su0001
	SSVEP_NEW_su0003	->	SSVEP_NEW_su0002
	SSVEP_NEW_su0004	->	SSVEP_NEW_su0003
	SSVEP_NEW_su0006	->	SSVEP_NEW_su0004
	SSVEP_NEW_su0008	->	SSVEP_NEW_su0005
	SSVEP_NEW_su0010	->	SSVEP_NEW_su0006
	SSVEP_NEW_su0011	->	SSVEP_NEW_su0007
	SSVEP_NEW_su0012	->	SSVEP_NEW_su0008
	SSVEP_NEW_su0013	->	SSVEP_NEW_su0009
	SSVEP_NEW_su0018	->	SSVEP_NEW_su0010
	SSVEP_NEW_su0019	->	SSVEP_NEW_su0011
	SSVEP_NEW_su0020	->	SSVEP_NEW_su0012
	SSVEP_NEW_su0022	->	SSVEP_NEW_su0013
	SSVEP_NEW_su0023	->	SSVEP_NEW_su0014
	SSVEP_NEW_su0024	->	SSVEP_NEW_su0015
	SSVEP_NEW_su0029	->	SSVEP_NEW_su0016
	SSVEP_NEW_su0030	->	SSVEP_NEW_su0017
	SSVEP_NEW_su0031	->	SSVEP_NEW_su0018
	SSVEP_NEW_su0033	->	SSVEP_NEW_su0019
	SSVEP_NEW_su0034	->	SSVEP_NEW_su0020
%}
%	hEEG.Inlier		=	hEEG.Allier(find(~ismember(hEEG.Allier, hEEG.Outlier)));
%	hEEG.Inlier		=	hEEG.Allier(~ismember(hEEG.Allier, hEEG.Outlier));
	hEEG.Inlier		=	lAllSbj(~ismember(hEEG.Allier, hEEG.Outlier));
%		Allier	: 모든 피험자 목록, ex:{ { 'su0001, 'su0001, 'su0001_1' },...}
%		Outlier	: 제외 목록, ex: { 'su0001', 'su0002', ... }

	hEEG.LocCUT		={								...		% data 초과: 제거위치
					{ 'su0002', 'f', },				...
					{ 'su0012', 'f', },				...
					{ 'su0018', 'f', },				...
					{ 'su0027', 'f', },				...
					};										% 앞 것 제거

	% data 파일이 이미 있더라도, 다시 작업해서 rewrite 할 subject 목록 기재
%	hEEG.Rework		={								...		% 재작업 대상
%					'su0001',						...
%					};
%%	hEEG.Rework		=	cellfun(@(x)({x{1}}), hEEG.Inlier);	% 1st 요소만 추출
	% Rework와 반대로, 이미 있는 data 파일은 유지할 subject 목록 기재
	% -----
	%% 만약, Rework와 Retain 에 같은 subject가 중복되면, Retain 우선순위!
%	hEEG.Retain		={								...		% Rework 반대 목록
%					'su0001',						...
%					};
%%	hEEG.Retain		=	cellfun(@(x)({x{1}}), hEEG.Inlier);	% 1st 요소만 추출
	%% 만약, Rework와 Retain 모두 생략: Retain에 모든 sbj 할당한 것처럼 작동

	return

