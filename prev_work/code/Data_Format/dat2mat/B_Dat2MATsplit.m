% B_Dat2MATsplit ver 0.75
% 20151118A. export 된 *.dat를 the original recording order 대로 수집/출력
%
% usage: B_Dat2MATsplit( @b_Dat2MAT_SSVEP_NEW )
%	-> param is must be function pointer ! :: attach to '@' first
%
% first created by tigoum 2015/11/18
% last  updated by tigoum 2016/04/23

function [ ] = B_Dat2MATsplit( A_global_AmH )
% ver 0.75 : rename this function

%% SSVEP의 실험 구성: 6자극 * 10번 * 4회 * 3조건
%% 스벤요구: 조건당 4개 파일, 즉, 조건별 4회 측정하므로, 각 측정별로 파일화
%%	따라서, 1 파일에는 6자극 * 10번 의 데이터가 시간흐름 그대로 저장될 것.
%%	1자극에 대한 segment는 5초 이므로, 1 파일에는 60개*5초=300초 분 데이터
% BA에서는 segmentation을 조건(top-down, intermediate, bottom-up)별로 분리
%	하는 것은 가능했지만, 이렇게 segment 된 것은 다시 300분씩 묶는 것이 안됨.
%	그래서, 조건별 segmentation만 한 후, matlab 코드에서 분리하기로 함.

%% 코드 시작하기 전 메모리를 비우고 매트랩에 켜져있는 팝업창들을 닫는 과정
clearvars -except A_global_AmH;
%close all;

%% setting %%

%% Header %%
global	SRC_NAME;
global	WORKNAME;
% 실험 하나에 쓰이는 모든 코드에 동일하게 복사/붙이기 해놓는 것이 편합니다.
%
% hEEG.Chan: 1번 부터 32번 까지 각각 번호에 맞게 채널이름 지정. 분석에 직접적으로 필요하지는 않지만 사용하는 데이터가
% 어느 채널에서 왔는지 확인하거나 디스플레이할 때 쓰면 됩니다.
%
% hEEG.Cond, hEEG.Cond: 실험 패러다임에 따라 알맞게 유동적으로 바꿔주면 됩니다.
%
% hEEG.Inlier: 피험자 리스트. Outlier가 생길 경우 이 리스트에서도 빼주면 됩니다.

%A_globals_AmH();%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@
%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@
%[	hEEG.PATH, Regulation, hEEG.Chan, hEEG.ChRemv, hEEG.Cond, trialname, hEEG.Inlier,	...
%	Freqs, fName, m, ki, cedPATH, sExt	]		=	A_global_AmH();

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%POOL				=	S_paraOpen();
hEEG				=	A_global_AmH();						% param은 fnx ptr

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Total				=	tic;		%전체 연산 시간

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
LocCUT				=	hEEG.LocCUT;
sExt				=	hEEG.ExtName;

	lData			=	'';			%data마다 생성되는 data의 모음 목록
for cond=1:length(hEEG.Cond)
%	for cond=1:length(hEEG.Cond)
%작업순서	%-[
	%1. bdf reader 가동
	%2. bdf reader로 부터 읽은 data 및 추가정보를 토대로 epoching
	%	-> 특히 fs값을 기반으로 하여 정확한 시간 상태 확인 필
	%	-> all(bdf_file.Head.SampleRate(1:65) == fs)	%-]
	if iscell(hEEG.Cond),	sCond	=	hEEG.Cond{cond};
	else,					sCond	=	num2str(hEEG.Cond(cond));	end
	% 제거용 문자열인 경우 4가지 가능성이 있다.
	% ~					:	그냥 이 문자만 제거하면 됨
	% head~REMOVE~other	:	~ 에서 ~ 사이의 REMOVE해당 string을 제거함
	% ~REMOVE			:	~ 이후의 모든 string 제거
	% head~REMOVE		:	~ 이후의 모든 string 제거
	ssCond			=	regexprep(sCond,'\s*~[^~]*~\s*','');		%'~'사이제거
	ssCond			=	regexprep(ssCond,'\s*~\s*[^~]*$','');		%'~'이후제거

	% 20151108A. trial이 쪼개진 경우 등을 모두 고려하여 자동 결합되는 기능 추가됨
for sbj_idx=1:length(hEEG.Inlier)
	BOOL			=	true;									% default return

%	FileInfo		=	hEEG.FileInfo;

%	SubjInfo		=	hEEG.SubjInfo;
%	lSubj			=	SubjInfo.Inlier{hEEG.SubjInfo.CurSubj};	% 배열 or 문자열
	lSubj			=	hEEG.Inlier{sbj_idx};	% 배열 or 문자열

%	ChanInfo		=	hEEG.ChanInfo;
%	FreqDomain		=	hEEG.FreqDomain;

	%% file loading 까지의 process:
%	PrjName			=	strsplit(hEEG.PATH, '/');				% 프로젝트 이름만
%	PrjName			=	char(PrjName(end-1));					% except Method
	% 1. Inlier 목록의 요소가 cell 형이면 전체 파일명을 구성하여 배열에 기록
	% 2. 아니면 그냥 그 파일명을 기록
	%
	% 3. dest(result) 파일의 존재를 점검
	% 4. src 파일들(1,2에서 기록한 파일들 대상)의 존재를 점검
	%
	% 5. Inlier 목록의 요소가 cell 형이면 결합해야 하는 구성임
	% 5-1. 목록 중 2번째~끝 항목을 모두 load해서 하나로 결합
	% 5-2. 첫번째 이름으로 WORKNAME 구성
	% 6. 아니면 그냥 그 이름으로 WORKNAME 구성
	lSRCNAME		=	{};	% must be init!:아니면 아래 skip시 다른파일 혼합오류!
	if iscell(lSubj) && length(lSubj)>=3
		% 여러 파일들을 결합시켜야 한다. 최종 이름은 처음에 둠
		% 이때 요소갯수는 최소 3개 -> sub1(목적), sub1_1(src), sub1_2(src)
		for s		=	2 : length(lSubj)				% 1:최종 이름, 2:cut 기준
			WORKNAME=[	char(lSubj{s}) hEEG.Common '_' sCond	];
%			lSRCNAME{s-1}=[	hEEG.PATH hEEG.Src	WORKNAME sExt	]; %배열
			lSRCNAME{s-1}=fullfile(hEEG.PATH,[hEEG.Src WORKNAME sExt]);%배열
		end
		% 최종적인 file명을 구성함
		WORKNAME	=[	char(lSubj{1}) '_' ssCond	];

	elseif iscell(lSubj) && length(lSubj)<=2
		% 요소 갯수가 2개면, 최종=소스 이므로, 그냥 단일 파일처럼 처리 가능
		WORKNAME	=[	char(lSubj{2}) hEEG.Common '_' sCond	];
%		lSRCNAME{1}	=[	hEEG.PATH hEEG.Src	WORKNAME sExt	];%only 1
		lSRCNAME{1}	=fullfile(hEEG.PATH,[hEEG.Src WORKNAME sExt]);%only 1

		% 최종적인 file명을 구성함
		WORKNAME	=[	char(lSubj{1}) '_' ssCond	];

	else	%단일 파일명인 경우
		WORKNAME	=[	char(lSubj) hEEG.Common '_' sCond	];
%		lSRCNAME{1}	=[	hEEG.PATH hEEG.Src	WORKNAME sExt	];%only 1
		lSRCNAME{1}	=fullfile(hEEG.PATH,[hEEG.Src WORKNAME sExt]);%only 1
	end

%		hEEG.FileInfo.WORK	=	WORKNAME;		% 파일이름 중 공통

	% 최종 출력 파일명 구성
%		OUT_NAME	=[	hEEG.PATH hEEG.Dest	WORKNAME '.mat' ];
		WORKNAME	=	regexprep(WORKNAME, '[_]+$', '');		% '_' 로 끝남
%		OUT_NAME	=[	hEEG.PATH hEEG.Dest	WORKNAME '_1.mat' ];
%		OUT_NAME	=	fullfile(hEEG.PATH,[hEEG.Dest WORKNAME '_1.mat']);
%		hEEG.FileInfo.OutFile	=	OUT_NAME;
		OUT_NAME	=	fullfile(hEEG.PATH, [hEEG.Dest WORKNAME '_']);
		OUT_NAME	=	regexprep(OUT_NAME, hEEG.OutRemv, ''); % filter
		if	~hEEG.fgSplitSession & ~hEEG.fgSplitEpoch			% single파일 case
			OUT_NAME=	regexprep(OUT_NAME, '[_]+$', '');		% 끝 '_' 제거
		end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%check result file & skip analysis if aleady exists.
%	if	hEEG.fgRename & isfield(hEEG, 'lRename')		% renaming
	if	hEEG.fgRename									% renaming
		su	=	regexp(OUT_NAME, 'su[0-9]{4}', 'match');% extract
%		re	=	hEEG.lRename(cellfun(@(x)( strcmp(x{1},su) ), hEEG.lRename));
%		OUT_NAME=regexprep(OUT_NAME, su, re{1}{2});		% mapping new name
		re	=	sprintf('su%04d', sbj_idx);
		OUT_NAME=regexprep(OUT_NAME, su, re);			% mapping new name
	end
%	fprintf('\nChecking: Analyzed result file: ''%s''...',[OUT_IMAG '.jpg']);
	fprintf('\nChecking: Analyzed result file: ''%s''...', [OUT_NAME '*.*t']);
%	if exist([OUT_IMAG '.jpg'], 'file') > 0				%exist !!
	try, EXIST = ls([OUT_NAME '*.*t'], '-1'); catch, EXIST = 0; end
%	if exist(OUT_NAME, 'file') > 0						%exist !!
	if ~EXIST											% no exist, let's go
		fprintf('NOT & Continue the Analyzing\n');

	elseif isfield(hEEG, 'Retain') & any(ismember(hEEG.Retain, lSubj{1}))
		fprintf('exist! & SKIP analyzing this, Retaining\n');
		continue;										% skip
	
	elseif isfield(hEEG, 'Rework') & any(ismember(hEEG.Rework, lSubj{1}))
		fprintf('exist, BUT Continue the Analyzing\n');

	else												% Retain/Rework 무소속
		fprintf('exist! & SKIP analyzing this\n');
		continue;										% skip
	end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	AllTime			=	tic;		%데이터 preparing 시간을 계측한다.
	fprintf('--------------------------------------------------\n');
	fprintf('Convert : %s''s DAT to RAW for [ %s ]\n', WORKNAME,			...
			[ regexprep(OUT_NAME, '.*(su[0-9]{4}.*)$', '$1') '*.*t' ]);
	%'\n'안하는 이유는 아래의 toc 결과가 끝에 붙어나오게 하려고.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% merging 기능: 만약 SubjInfo.Inlier 의 한 cell에 다수 개의 subj 
%	이름이 담겨 있다면, 이들을 순서대로 읽어서, 하나의 데이터로 합침
%	epoch 기준으로 concatenate 해야 함.
	eMRK			=	{;};							% empty 2D array
	eEEG			=	[;;];							% empty 3D array
	for s			= 1 : length(lSRCNAME)				% 반드시 cell array 임!
		SRC_NAME	=	regexprep(lSRCNAME{s}, '_([.][a-zA-Z]+)$', '$1'); % trim
%		hEEG.FileInfo.InFile	=	SRC_NAME;

		%check & auto skip if not exist a 'dat file.
		fprintf('Checking: Source file: ''%s''... ', SRC_NAME);
		if exist(SRC_NAME, 'file') <= 0					%skip
			fprintf('not! & SKIP converting this\n\n');
			continue;									%exist !!
		else
			fprintf('EXIST & Continue the converting\n\n');
		end

%%-------------------------------------------------------------------------------
% Convert: DAT -> eEEG...mat
% -------------------------------------------------------------------------------
		ChanLive	=	hEEG.Chan(hEEG.ixLive);			% only live
		ixLive		=	hEEG.ixLive;
		ixRemv		=	hEEG.ixRemv;

		[eCHN,SDP,eFS,Orient]	=	S_importVHDR(SRC_NAME);
%		eCHN		=	upper(eCHN);
		MxCh		=	length(eCHN);					% eCHN : 채널 목록
		hEEG.SmplRate=	eFS;

		% cell array는 직접 비교 (ex: ch 	== label) 할 수 없으므로 별도 구조화
%		incorrect	=	find( cellfun(@strcmp, hEEG.Chan, eCHN) == 0 );
		incorrect	=	find( ~ismember(ChanLive, eCHN) );
		if length(incorrect) > 0						% 틀린 index 가 존재
			fprintf('Warning : mismatch channels b/w script & VHDR\n');
		for err 	= 1 : length(incorrect)
			idx		=	incorrect(err);
			fprintf('  + #%03d: %s <-> %s\n', idx, ChanLive{idx}, eCHN{idx});
		end
			fprintf('Replace : using VHDR(%d) rather than script(%d)\n',	...
					MxCh, length(ChanLive));
			ChanInfo.All=	eCHN;
			ixLive	=	find(~ismember(eCHN, hEEG.ChRemv) ); %갱신
			ixRemv	=	find( ismember(eCHN, hEEG.ChRemv) ); %갱신
		end

		% -----	실험의 종류에 따라, 마커 길이가 다를 수 있으므로, 가변성 고려
		nMRK		=	3;								% maximum len is 3
		VMRK		=	{;};
		while isempty(VMRK) & nMRK > 0
			[ VMRK ]=	S_importVMRK(SRC_NAME, nMRK);% load a marker
			nMRK	=	nMRK - 1;						%% change len of marker
		end

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		%% Subjects_All Epochs_bl
%		eval(['BAdat		=	importdata(''' SRC_NAME ''');']);
		BAdat		=	importdata( SRC_NAME );
		%*.dat 파일의 첫 줄에 저장된 채널 순서를 확인해 보아야 함!
		if ~isstruct(BAdat),	BAdat	=	struct('data', BAdat); end

%		B			=	BAdat.data;
%		B			=	shiftdim(B, 1);
%		eBLK		=	reshape(B, 1000, [], 32);
%		eBLK		=	reshape(BAdat.data, 1000, [], 32);
%%		eBLK		=	reshape(BAdat.data, SDP, [], MxCh); %% time * ep * ch

		%% 20151117A. BA의 export 옵션에 따른, import *.dat reshape 오류 발견
		% Wavelet을 사용할 때 데이터 타입은 항상 (timepoint x epochs x channels)
		% 형태 일 것! 하지만, 경우에 따라서, Brain Analyzer의 export로부터
		% 전혀 다른 구조의 dat format 이 load 될 수 있음.
		% DataOrientation=MULTIPLEXED: 인 경우 [data point seriese] x [ch] 구조
		% DataOrientation=VECTORIZED : 인 경우 [ch] x [data point seriese] 구조
		% 따라서, orientation 에 따라 다른 처리 과정을 거쳐, 최종적인 eEEG 형식
		% 확보를 시행해야 함.
		% eEEG 형식: timepoint x epoch x ch
		if		strcmp(Orient,'VECTORIZED') &&	size(BAdat.data,1)==MxCh
			eBLK=	reshape(BAdat.data, MxCh, SDP, []);	%% ch * time * ep
			eBLK=	shiftdim(eBLK, 1);						% tm x ep x ch

		elseif	strcmp(Orient,'MULTIPLEXED') &&	size(BAdat.data,2)==MxCh
			eBLK=	reshape(BAdat.data, SDP, [], MxCh);	%% time * ep * ch
		end

%		clear B BAdat
		clear BAdat

%		eBLK(:,:,17)=	NaN;	% EOG
%		eBLK(:,:,22)=	NaN;	% NULL
%		eBLK(:,:,find(ismember(eCHN,'EOG')) )	=	0;	% EOG

%%		save([hEEG.PATH '/skk_data/skk_' SRC_NAME], 'eBLK');	% eBLK array 저장

		nMRK		=	size(VMRK, 1);
		eMRK(end+1:end+nMRK,:)	=	VMRK;			% horzcat or vertcat

		s1EEG		=	strjoin(arrayfun(@num2str, size(eEEG), 'unif', 0), '*');
		eEEG		=	[ eEEG eBLK ];				% horzcat or vertcat
		seBLK		=	strjoin(arrayfun(@num2str, size(eBLK), 'unif', 0), '*');
		s2EEG		=	strjoin(arrayfun(@num2str, size(eEEG), 'unif', 0), '*');
		if s > 1 && length(eEEG) > 0				% 2번째 데이터 merging 시
			fprintf(['Merging : eEEG(%s:%s) = eEEG(%s) + Part(%s:%s) '		...
					'based EPOCHs.\n'], WORKNAME,s2EEG, s1EEG, SRC_NAME,seBLK);
		end

		clear eBLK, VMRK;
	end;
	%% ----------
	if isempty(eEEG), continue; end					% data 없으면 다음 subj로!
	%% ----------

%% ------------------------------------------------------------------------------
%% 20150517B. eEEG 데이터에 대한 기본적인 처리/점검 기능이 필요함.	%-[
	%단, 데이터가 아닌 더미채널을 제거해야 한다.
	% ch17= EOG, ch22=NULL, 없는 부분 날림. 뒤에서 부터 날려야 제대로 처리됨.
	% -> 20150517C. 이젠 이 제약은 없어졌음. 앞에서부터 순서대로 제거 가능

	tic; fprintf('\nFinding : & remove a dummy channels on eEEG array.\n');
	eEEG(:,:,[ ixRemv ])	=	[];					% remove 채널 제거

	% eCHN 에서도 live 채널만 남겨 두기로 한다.
	eCHN		=	eCHN([ ixLive ]);				% live 만 유지
	MxCh		=	length(eCHN);					% must be update !

	%% marker의 시점이 정확한지 점검
	fprintf('Search  : consistency a triggering marker vs eEEG data\n');
	if size(eEEG,2) ~= size(eMRK,1)					% trial 수 == 마커 수?
		fprintf('Warning : not consist the number of (%.1f : %.1f)\n',	...
				size(eEEG,2), size(eMRK,1));

		% 이 경우, eMRK 의 값 중 time point 길이와 불일치 하는 것을 제거
		% 우선, 불일치 하는 것(tp의 배수가 아닌 것)의 갯수를 구한 다음,
		% 일치갯수(tp의 배수 인 것)와 eEEG epoch 수가 동일한 지 점검.
		lMod0	=	find( mod((cell2mat(eMRK(:,3))-eMRK{1,3}), size(eEEG,1))==0);
		if length(lMod0) == size(eEEG,2)			% 동일!
			lModNo0=find( mod( (cell2mat(eMRK(:,3)) - 1), size(eEEG,1) ) ~= 0);
			fprintf('Matching: success removing the garbage MARKERs(#%s)\n', ...
			strjoin(cellfun(@(x)( {sprintf('%d',x)} ), eMRK(lModNo0,3)),', '));
			eMRK=	eMRK(lMod0,:);					% 일치 되는것 만 추출
		else										% 여전히 동일 안함!
			error('Error   : not consist number of (%.1f : %.1f)\n',		...
					size(eEEG,2), size(eMRK,1));
		end
	end
	for m = 1 : size(eEEG,2)						% epoch갯수 대응하는 마커갯수
		if size(eEEG,1)*(m-1)+eMRK{1,3} ~= eMRK{m,3}% 마커시작(1번마커)과 sync
			fprintf('Warning : not consist at time point(%.1f : %.1f)\n',	...
						size(eEEG,1)*(m-1)+1, eMRK{m,3});
		end
	end % for

	%eEEG 데이터 중 NaN 인 것이 있으면, 해당 값을 가진 채널과의 비교에서
	%매번 엉뚱한 값을 생성하며, 불필요한 연산을 유발할 수 있음.
	%따라서, 이 값을 가진 채널이 있다면, Notify 해야 함!!
	%eEEG 규모가 광범위 할 경우, 시간이 소요 될 수도 있음에 유의할 것.
	fprintf('Search  : a NaN value on eEEG array\n');
	flagNaN			=	0;
	[ rNaN cNaN ]	=	find(isnan(eEEG));			% 2D 관점에서 위치 찾기
	Linear			=	sub2ind(size(eEEG), rNaN, cNaN);	% eEEG 1D형 index
	if length(Linear)								% 뭔가 값이 있음
		fprintf('Notify  : eEEG(%s) have %d of NaNs\n', WORKNAME,length(Linear));
		flagNaN		=	1;
%		eEEG(Linear)=	0.0;						% all NaN -> 0.0
	end
%{
	for t=1:size(eEEG,1)	for e=1:size(eEEG,2)	for c=1:size(eEEG,3)
		if isnan(eEEG(t,e,c))
			flagNaN	=	1;
			fprintf(['Notify: eEEG has a undefined values at ' ...
					'[Time(%d), Epoch(%d), Ch(%d)]\n'], t, e, c);
		end
	end; end; end
	if flagNaN,		%NaN 값 발견!
		fprintf('Press CTRL+C to stop or AnyKey to continue\n');
		pause;
	end
%}
	fprintf('\nSearch  : completed. ');	toc;		% 작업 종료시간 출력	%-]

	%% 조사에서 문제없으면, eEEG 의 32번째 채널에 마커 정보를 주입함!
%	eEEG(1,:,end+1)	=	cell2mat(eMRK(:,2));		% 마커값->eEEG 추가채널
	% 마커는 한개의 값이므로, time point 의 1에만 저장, 2:end==0 임
%	clear eMRK

%% ------------------------------------------------------------------------------
	%% 중요: 실험횟수 대비 초과하는 데이터 및 마커의 판독&제거 체계
	%% epoch의 수가 제대로 만족하는지 확인부터 먼저 해야 함!

	fprintf('--------------------------------------------------\n');
	nIter			=	hEEG.nPresent;				% 자극당 횟수
	nTrial			=	hEEG.nStimuli * nIter;		% 자극수 * 자극당 횟수
	nTry			=	hEEG.nSession;				% 시도 횟수
	nMarker			=	nIter * nTry;				% 시도*자극횟수=각 자극 총수

	eMRKa			=	cell2mat(squeeze(eMRK(:,2)))';	% 마커값만 추출
	if nTrial*nTry < size(eEEG, 2)	% nTrial은 갯수, 이보다 크면 문제!
		fprintf('Warning : trial size(%d) is too big than %d*%d\n',			...
				size(eEEG,2), nTrial, nTry);

		% trial 갯수는 반드시 맞아야 하므로, 각 trigger 갯수를 세어서,
		% 기준값 대비, "같은 것", "많은 것" "적은 것"을 찾아야 함.
		cMRK		=	unique(eMRKa);				% catch a trigger code
		nMRK		=	arrayfun(@(x)(length(find(eMRKa==x))), cMRK);

%		CeqMRK		=	cMRK( find(nMRK == nMarker) );% 같은 갯수인 것 == code
%		CgtMRK		=	cMRK( find(nMRK >  nMarker) );% 더 많은 것
%		CltMRK		=	cMRK( find(nMRK <  nMarker) );% 더 적은 것
		CeqMRK		=	cMRK( nMRK == nMarker );	% 같은 갯수인 것 == code
		CgtMRK		=	cMRK( nMRK >  nMarker );	% 더 많은 것
		CltMRK		=	cMRK( nMRK <  nMarker );	% 더 적은 것

		NeqMRK		=	nMRK( arrayfun(@(x)( find(cMRK==x) ), CeqMRK) ); %갯수
		NgtMRK		=	nMRK( arrayfun(@(x)( find(cMRK==x) ), CgtMRK) ); %갯수
		NltMRK		=	nMRK( arrayfun(@(x)( find(cMRK==x) ), CltMRK) ); %갯수

		% gt 가 발생하면, 이를 제거해야 함 -> eEEG 및 eMRK 에서 모두 !
		if isempty(NltMRK) && ~isempty(NgtMRK)			%% gt 존재!
			IgtMRK	=	arrayfun(@(x)( {find(eMRKa==x)} ), CgtMRK);%전체중 위치들

			ixCUT	=	find(cellfun(@(x)(strcmp(char(x{1}),lSubj{1})),LocCUT));
			if isempty(ixCUT) | LocCUT{ixCUT}{2}=='l'				%목록 no 감안
				IgtMRK=	cellfun(@(x)( {x(nMarker+1:end)} ), IgtMRK);%초과 위치만
			elseif LocCUT{ixCUT}{2}=='f'
				IgtMRK=	cellfun(@(x)( {x(1:length(x)-nMarker)} ), IgtMRK);%처음
			end
			ixgtMRK	=	cell2mat(IgtMRK);

			% 초과 위치를 후반부로 잡았으며, 이들을 eEEG 와 eMRK 를 제거하면 됨
			% IgtMRK 에는 cell형 배열이 들어가 있으므로, 이를 vector로 변경필요
			% 이때, 각 마커는 고유한 위치를 차지하므로, 중복값이 되지 않음
%			xCgtMRK	=	arrayfun(@(x,y)( {repmat(x, [length(y{:}) 1])} ),	...
%						CgtMRK, IgtMRK);			% 코드를 위치갯수 만큼 복제
			SgtMRK	=	cellfun(@(x)( { strjoin(		...
							arrayfun(@(y)( {num2str(y)}), x) , ',')}		...
									), IgtMRK);		% gt마커별 위치들->문자열묶기

			eMRK(	[ ixgtMRK ], :)	=	[];			% gt마커 성분 제거
			eEEG(:,	[ ixgtMRK ], :)	=	[];			% gt마커 성분 제거

			fprintf('Control : removing the over Marker: %s\n',				...
strjoin(arrayfun(@(x,y)( {sprintf('%d(#%s)',x,char(y))} ), CgtMRK,SgtMRK),', '));

		%% ::::::::::::::::::::::::::::::::::::::::::::::::::
		% 적은 것이 있으면 문제임! lt->eq로 만들기 위해, gt를 섞어야 함.
		% lt 와 gt 의 갯수: n(lt) < n(gt) 여야 함. -> 아니면 FAULT!
		%% 일단은 이런 상황 자체가 없도록 조처하는 것이 맞음!!!
		%% 현재는 무시할 것.
		elseif ~isempty(NltMRK) && sum(NltMRK) <= sum(NgtMRK)	%-[
			%% 엄밀하게 말해서, sum(NltMRK) == sum(NgtMRK) 는 발생 불가능
			% 왜냐하면, 같은 갯수이면 total sum = nTrial*nTry == size(eEEG, 2) !
			% 따라서, sum(NltMRK) < sum(NgtMRK) 인 경우만 계산 하면 됨

			fprintf(['FAULT  : matching #Marker irregularities : '			...
					'lt{%s} < gt{%s}\n'],									...
strjoin(arrayfun(@(x,y)( {sprintf('%d(#%d)', x,y)} ), CltMRK, NltMRK), ', '), ...
strjoin(arrayfun(@(x,y)( {sprintf('%d(#%d)', x,y)} ), CgtMRK, NgtMRK), ', ') );
			FAULT	%-]
		elseif ~isempty(NltMRK)	% &&i sum(NltMRK) > sum(NgtMRK)	%-[
			fprintf(['FAULT  : matching #Marker irregularities : '			...
					'lt{%s} > gt{%s}\n'],									...
strjoin(arrayfun(@(x,y)( {sprintf('%d(#%d)', x,y)} ), CltMRK, NltMRK), ', '), ...
strjoin(arrayfun(@(x,y)( {sprintf('%d(#%d)', x,y)} ), CgtMRK, NgtMRK), ', ') );
			FAULT	%-]
		%% ::::::::::::::::::::::::::::::::::::::::::::::::::
		end

%	elseif nTrial > size(eEEG, 2)	% nTrial은 갯수,이보다 작아도 문제
%		fprintf('Warning : trial size(%d) is too small than %d\n',		...
%				size(eEEG,2), nTrial);
	elseif nTrial*nTry > size(eEEG, 2)	% nTrial은 갯수,이보다 작아도 문제
		fprintf('\nFATAL   : trial size(%d) is too small than %d*%d\n\n',	...
				size(eEEG,2), nTrial, nTry);
		FATAL
	end

%% ------------------------------------------------------------------------------
	%% try 별로 개별 파일로 출력해야 함.
	eEEG					=	eEEG(		...		% window 범위만 취득
		ismember(	hEEG.tInterval(1) :1000/eFS :hEEG.tInterval(2)-1,		...
					hEEG.TimeWindow(1):1000/eFS :hEEG.TimeWindow(2)-1 ),	:,:);

	% 데이터에 대한 점검과 정리가 완료되어 clean 상태이므로, 이제 time inverse
	% 를 수행하자. (물론 flag option이 있다면)
	% data 및 marker 모두 시간에 대해 inverse 시켜야 함.
	% -> 방법: data를 3D -> 2D 로 원래대로 환원해서 수행 후 3D 변환
	% eEEG 형식: timepoint x epoch x ch
	if hEEG.fgInvTime
%		eMRK2		=	eMRK([size(eMRK,1):-1:1], :);	% inverse ordering tp
%		eMRK3		=	eMRK2([size(eMRK,1):-1:1], :);	% inverse ordering tp
%		isequal(eMRK, eMRK3)
		eMRKa		=	eMRK ([size(eMRK, 1):-1:1], :);	% inverse ordering tp
		eMRKb		=	eMRKa([size(eMRKa,1):-1:1], :);	% inverse ordering tp
		if isequal(eMRKb, eMRK)
		fprintf('[Pass]  : inversion marker equal than origins...\n');
		else
		fprintf('Warning : inversion marker mismatch than origins...\n');
		end
		eMRK		=	eMRKa;

%		eEEG2		=	reshape(eEEG, [], [MxCh]);	% 2D로 변환
%		eEEG2		=	eEEG2([size(eEEG2,1):-1:1], :);	% inverse ordering tp
%		eEEG2		=	reshape(eEEG2, [size(eEEG,1)], [], [MxCh]); %3D
		% 2D변환후 inverse와 3D 그대로 inverse 한 결과 비교요망
%		eEEG3		=	eEEG([size(eEEG,1):-1:1], [size(eEEG,2):-1:1], :);
%		isequal(eEEG2, eEEG3)
		eEEGa		=	eEEG ([size(eEEG, 1):-1:1], [size(eEEG, 2):-1:1], :);
		eEEGb		=	eEEGa([size(eEEGa,1):-1:1], [size(eEEGa,2):-1:1], :);
		if isequal(eEEGb, eEEG)
		fprintf('[Pass]  : inversion data equal than origins...\n');
		else
		fprintf('Warning : inversion data mismatch than original data...\n');
		end
		eEEG		=	eEEGa;

		clear eMRKa eMRKb eEEGa eEEGb
	end

%% ------------------------------------------------------------------------------
	% 이어서 데이터와 마커를 실험횟수(nTry)에 대응하여 잘라서 파일별로 저장

	fprintf('--------------------------------------------------\n');
	tic; fprintf('Write   : 3D data to a MAT file\n');

	% eEEG 형식 변경: timepoint x epoch x ch -> tp x ch x ep
	eMRKa			=	cell2mat(squeeze(eMRK(:,2)))';	% 마커값만 추출
	eEEGa			=	permute(eEEG, [1, 3, 2]);	% 2번과 3번 순서 바꾸기
	eEEGb			=	permute(eEEGa,[1, 3, 2]);	% 다시 바꾸기(정확성 검토용)
	if isequal(eEEGb, eEEG)		%all(all(all(eEEGb == eEEG)))
		fprintf('Swapping: a location b/w epoch & chan\n');
	else
		fprintf('Swapping: FAILURE! b/w epoch & chan\n');
		FAILURE
	end
	if		hEEG.fgSplitSession
		[mxLen, nSize]			=	deal(nTry,	nTrial);
	elseif	hEEG.fgSplitEpoch
		[mxLen, nSize, nIter]	=	deal(size(eEEGa,3),	1, 1);
	else
		[mxLen, nSize, nIter]	=	deal(1,	size(eEEG, 2), nMarker);% single file
	end
	cMRK			=	unique(eMRKa);				% catch a trigger code
	gnMRK			=	zeros(mxLen, length(cMRK));
	OUT				=	cell(mxLen, 1);
	for nBlk = 1 : mxLen							% 자극 수 * n번 단위 쪼개기
		eMRK		=	eMRKa(nSize*(nBlk-1)+1:nSize*nBlk);
		eEEG		=	eEEGa(:, :, nSize*(nBlk-1)+1:nSize*nBlk); % tp x ch x ep

		% check the availability of trigger number.
		nMRK		=	cell2mat(arrayfun(@(x)({length(find(eMRK==x))}), cMRK));
		misMK		=	find(nMRK ~= nIter);		% diff for nIter
		gnMRK(nBlk,:)=	nMRK;	% 각 loop 에서 확인된 갯수 저장 -> 나중 grand 함.

		fprintf('\nInfo.   : Marker with %s\n',								...
		strjoin(arrayfun(@(x,y)( {sprintf('%d(#%d)', x,y)} ), cMRK,nMRK),', ') );
		if ~isempty(misMK)							% inconsistent # of MRK
			fprintf('WARNING : differ size with Marker(#): %s\n',			...
				strjoin(arrayfun(@(x,y)( {sprintf('%d(#%d)', x,y)} ),		...
						cMRK(misMK), nMRK(misMK)), ', ') );
		end

		fprintf('Write   : a PART(%d/%d) of eEEG Epoch(%d:%d)\n',			...
				nBlk, mxLen, nSize*(nBlk-1)+1, nSize*nBlk);
		PATH	=	regexprep(fullfile(hEEG.PATH, hEEG.Dest), '/[^/]+$', '');
%		if not(exist(fullfile(hEEG.PATH, hEEG.Dest), 'dir'))
%		if not(exist(PATH, 'dir')), mkdir(fullfile(hEEG.PATH,hEEG.Dest)); end
		if not(exist(PATH, 'dir')), mkdir(PATH); end

		% 저장방식에 따라: 확장자, 저장데이터 종류, 데이터 구조 고려하여 출력
		OUT		=	OUT_NAME;						% single이면 이것만 씀
		if mxLen > 1								% multiple 분할이면
			OUT = [OUT sprintf(['%0' num2str(length(num2str(mxLen))) 'd'],nBlk)];
		end
		if		hEEG.fgExportMat					% 20160309 smpl추가
			save([OUT '.mat'],'eEEG','eMRK','eCHN','eFS', '-v7.3'); % 호환성!
		elseif	hEEG.fgExportTxt
			eEEG2D	=	squeeze(eEEG);				% tp x ch
			save([OUT '.txt'], 'eEEG2D', '-ascii');
		end
	end
%{
	if hEEG.fgExportTxt		%-[
		%% 20160310A. txt 형식 저장 개시
		% data 및 marker 까지 저장
		% txt 형식이므로, data는 2D 구조로 저장해야 함.
		% eEEG (원본) 형식: tp x ep x ch
		% 그러고 나서, (tp x ep) x ch 로 변경
%		eEEG2D		=	reshape( eEEGb, [], [length(eCHN)] );

		fprintf('\nWrite   : a [TXT] of %d epoch eEEG\n', size(eEEGb,2));
		%% 20160310B. txt 형식이되, ep별로 개별 파일 분할 저장
	for nEp		=	1:size(eEEGb, 2)
		TXT_NAME=fullfile(hEEG.PATH,	[hEEG.Dest WORKNAME '_'	...
										sprintf('%03d', nEp) '.txt']);
		eEEG2D	=	squeeze(eEEGb(:,nEp,:));			% tp x ch
		save(TXT_NAME, 'eEEG2D', '-ascii');
	end
	end	%-]
%}
	SnMRK			=	sum(gnMRK,1);
	misMK			=	find(SnMRK ~= nMarker);		% diff for 각 마커총수
	if isempty(misMK)								% # of MRK 일치
		fprintf('\n[Nice!] : consists with all Marker(#): %s\n',			...
		strjoin(arrayfun(@(x,y)( {sprintf('%d(#%d)', x,y)} ), cMRK,SnMRK),', '));
	else											% 불일치!!!
		fprintf('\nWARNING : differ total size with Marker(#): %s\n',		...
			strjoin(arrayfun(@(x,y)( {sprintf('%d(#%d)', x,y)} ),			...
					cMRK(misMK), SnMRK(misMK)), ', ') );
	end
	clear eEEG eEEGa eEEGb;

%{
	%%plot 확인을 위해 BrainAnalyzer에서 사용할 수 있도록 *.dat 구성함
	tic; fprintf('Write   : to a MAT or DAT file\n');
	bDATl			=	reshape(eEEGl, [], numChan);	% t_ep * ch
	% bDATl(timepoint<=>epochs * ch) = (256*9*30, 65);
	save(DATL_NAME,	'bDATl', '-ascii');				%dat 형식으로 저장
	AmHlib_makeVHDR(DATL_NAME, SpI, eCHN);		%헤더정보파일 생성
	bDATr			=	reshape(eEEGr, [], numChan);	% t_ep * ch
	save(DATR_NAME,	'bDATr', '-ascii');				%dat 형식으로 저장
	AmHlib_makeVHDR(DATR_NAME, SpI, eCHN);		%헤더정보파일 생성
	toc;
%}
	%%==================================================
%{
	%% 사전에 max ch 을 개략적으로 확인해 보기 위한 작업 수행	%-[
	StartTp			=	-2000;						% ms
	Fin_Tps			=	7000;
	SpI				=	1000 / eFS;
%		twin_bl			=	1:( (StartTp*-1)/SpI );
%		twin_bl			=	1:( 500/SpI );				% 베이스라인 범위
	twin_bl			=	(-500/SpI) : 0;
	twin_bl			=	twin_bl - twin_bl(1);		% 0에 기준 맞춤
	twin_bl			=	twin_bl( twin_bl >= 1);		% 1이상인 값만
		%인덱스로 사용될 time win 이라서, 반드시 index 1 부터 시작해야 함

%		[mERP  iERP]	=	max(eEEGa, [], 2);			% epoch 해체
%		mERP			=	squeeze(mERP);
	mERP			=	squeeze(mean(eEEGa, 2));	% epoch 해체: t * ch
%		bl				=	mean(mERP(twin_bl,:));		% baseline 값
%		mERP			= mERP-repmat(mean(mERP([twin_bl],:)),[size(mERP,1),1]);

	[mChan iChn]	=	max(mERP, [], 2);			% 채널 해체
	[MxVal MxTp]	=	max(mChan);					% 타임 해체

	iChn			=	iChn(MxTp);					%단 한개의 채널
	MaxTpoint		=	MxTp*1000/eFS +StartTp -1;% -2000~7000 ms

	%%print out fined FreqVal info to screen.
	fprintf(['Finding %s''s Maximum(%7.5f) at '							...
			'TimePoint(%dms), Channel(%s)\n'],							...
			WORKNAME, MxVal, MaxTpoint, eCHN{iChn});

	Potential_TOPO	=	mERP(MxTp, :);				% 특정Tp * all Ch

	%%==================================================
	%% drawing topo ploting ------------------------------
	% TopoPlot
	fprintf('\nDrawing : for topoplot');
	figure;
	[attr, data]		=	topoplot(Potential_TOPO,	cedPATH,		...
	'style','map', 'electrodes','on');%,'chaninfo',EEG.chaninfo);

	title(sprintf('Max Value: %f, Time: %d ms, Ch: %s',					...
			MxVal, MaxTpoint, eCHN{iChn}));		% -2000~7000 ms
%		caxis([-MaxMax, MaxMax]);
	colorbar;

	%% saving topo to jpeg ------------------------------
	fprintf('\nWrites  : TOPO to JPEG file : ''%s''... ', [OUT_IMAG '.jpg']);
	print('-djpeg', [ OUT_IMAG '.jpg' ]);
%		print('-depsc', [ OUT_IMAG '.eps' ]);

	%%==================================================
	%% drawing 2D graph for signal T * ch : checking for noise or spike
	figure;	%set(gcf, 'DefaultAxesColorOrder',[1 0 0; 0 0 1; 0 1 0]);
	Time				=	[0 : 2 : 2*size(mERP,1)-1] +StartTp;
	plot(Time, mERP); hold on;
	selchan				=	eCHN;
	selchan{iChn}		=	[ '*' selchan{iChn} ];	% Max Ch에 '*' 표기
	legend(selchan, 'Location','eastoutside', 'Orientation','vertical');
	xlabel('t(ms)');		ylabel(sprintf('%d of ch', length(eCHN)));
	title(sprintf('Max Value: %f, Time: %d ms, Ch: %s',					...
			MxVal, MaxTpoint, eCHN{iChn}));
%		ylim([-0.1 1.2]);
	grid on;
	%% saving 2D to jpeg ------------------------------
	fprintf('\nWrites  : Graph to JPEG file : ''%s''... ',[O2D_IMAG 'jpg']);
	print('-djpeg', [ O2D_IMAG '.jpg' ]);
%		print('-depsc', [ O2D_IMAG '.eps' ]);

	close all;										% 안해주면 나중 오류 %-]
%}
	fprintf('\nComplete: %s''s processing :: ',WORKNAME);	toc(AllTime);
	fprintf('==================================================\n');

end		%for sub
end		%for data

fprintf('\nFinished: total time is ');	toc(Total);

