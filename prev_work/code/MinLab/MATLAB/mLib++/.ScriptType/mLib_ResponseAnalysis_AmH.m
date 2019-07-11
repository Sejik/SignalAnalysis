%% Script Type : source는 A_globals_AmH 로부터 획득

%% Analyzer의 Vmrk 정보로 부터 subject의 Response에 의해 산출되는 핵심정보인
%% RT==Reaction Time 과 Error Rate 를 계산한다.

%%%% 계산에 앞서!, 트리거 코드 중 비정상코드(시간적으로 불가능하게 마킹되는)를
%% 필해 제거해야 함.
%% 이때, PRT 포트에서 8bit 2진수로 코드값이 생성됨에 따른, 각 bit-field 별
%% time overap 에 의해 발생가능한 조합인지와 같은 reasonable 한 경우로 한정!

%% ------------------------------------------------------------------------------
% 코드 시작하기 전 메모리를 비우고 매트랩에 켜져있는 팝업창들을 닫는 과정
%close -except Path4eeg, subj;
clearvars -except MarkerPath, Marker4Stimuli, Marker4Response, SavePath;

%% setting %%
path(localpathdef);	%<UserPath>에 있는 pathdef.m 을 실행하여 추가적인 path를 등록

%A_globals_AmH();%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@
%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki, cedPATH	]		=	A_globals_AmH();
	%Freqs, fName이 cell array 일 경우: float vector로 변경 필요
	if iscell(Freqs)
		Freqs					=	Freqs{1};				% 1st 데이터만 취함
		fName					=	fName{1};
	end
	if ~isfloat(Freqs)
		error('"Freqs" is not float data or vector\n');
	end
[mkStim		mkResp]	=	deal( trialname(1), trialname(2) );	% 마커 용도로 reuse
[StartTp	FinishTp]=	deal( m, ki );						% 타이밍 용도로 reuse
idxLive				=	find( ~ismember(channame, removech) );	%살아있는 채널만
idxRemv				=	find( ismember(channame, removech) );	%살아있는 채널만

Total				=	tic;		%전체 연산 시간

	lData			=	'';			%data마다 생성되는 data의 모음 목록
for datanumb=1:length(dataname)
%	for datanumb=1:length(dataname)
	if iscell(dataname),	sCondi	=	dataname{datanumb};
	else,					sCondi	=	num2str(dataname(datanumb));	end

	% 20151108A. trial이 쪼개진 경우 등을 모두 고려하여 자동 결합되는 기능 추가됨
for subnumb=1:length(subname)
	BOOL			=	true;									% default return

%	FileInfo		=	hEEG.FileInfo;

%	SubjInfo		=	hEEG.SubjInfo;
%	lSubj			=	SubjInfo.Inlier{hEEG.SubjInfo.CurSubj};	% 배열 or 문자열
	lSubj			=	subname{subnumb};	% 배열 or 문자열

%	ChanInfo		=	hEEG.ChanInfo;
%	FreqDomain		=	hEEG.FreqDomain;

	%% file loading 까지의 process:
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
	fHeader			=	strsplit(fullPATH, '/');		% folder명 == header명
	FileInfo.Src	=	[ '/Raw Files/'	char(fHeader(end)) '_' ];
	FileInfo.sExt	=	'.eeg';
	FileInfo.Dest	=	[ '/RespAn/'	char(fHeader(end)) '_' ];
	FileInfo.dExt	=	'.xls';

	lSRCNAME		=	{};	% must be init!:아니면 아래 skip시 다른파일 혼합오류!
	if iscell(lSubj) && length(lSubj)>=3
		% 여러 파일들을 결합시켜야 한다. 최종 이름은 처음에 둠
		% 이때 요소갯수는 최소 3개 -> sub1(목적), sub1_1(src), sub1_2(src)
		for s		=	2 : length(lSubj)				% 1:최종 이름, 2:cut 기준
			WORKNAME=[	char(lSubj{s}) Regulation sCondi	];
			lSRCNAME{s-1}=[	fullPATH FileInfo.Src WORKNAME FileInfo.sExt ]; %배열
		end
		% 최종적인 file명을 구성함
		WORKNAME	=[	char(lSubj{1}) Regulation sCondi	];

	elseif iscell(lSubj) && length(lSubj)<=2
		% 요소 갯수가 2개면, 최종=소스 이므로, 그냥 단일 파일처럼 처리 가능
		WORKNAME	=[	char(lSubj{2}) Regulation sCondi	];
		lSRCNAME{1}	=[	fullPATH FileInfo.Src	WORKNAME FileInfo.sExt	];%only 1

		% 최종적인 file명을 구성함
		WORKNAME	=[	char(lSubj{1}) Regulation sCondi	];

	else	%단일 파일명인 경우
		WORKNAME	=[	char(lSubj) Regulation sCondi	];
		lSRCNAME{1}	=[	fullPATH FileInfo.Src	WORKNAME FileInfo.sExt	];%only 1
	end

%		hEEG.FileInfo.WORK	=	WORKNAME;		% 파일이름 중 공통

	% 최종 출력 파일명 구성
%		OUT_NAME	=[	fullPATH FileInfo.Dest	WORKNAME '.mat' ];
		OUT_NAME	=[	fullPATH FileInfo.Dest	WORKNAME					...
						'_' num2str(MkStim) '_' num2str(mkResp) '.txt' ];
%		hEEG.FileInfo.OutFile	=	OUT_NAME;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%check result file & skip analysis if aleady exists.
%	fprintf('\nChecking: Analyzed result file: ''%s''...',[OUT_IMAG '.jpg']);
	fprintf('\nChecking: Analyzed result file: ''%s''...', OUT_NAME);
%	if exist([OUT_IMAG '.jpg'], 'file') > 0					%exist !!
	if exist(OUT_NAME, 'file') > 0							%exist !!
		fprintf('exist! & SKIP analyzing this\n');
		continue;											%skip
	else
		fprintf('NOT & Continue the Analyzing\n');
	end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	AllTime			=	tic;		%데이터 preparing 시간을 계측한다.
	fprintf('--------------------------------------------------\n');
	fprintf('Convert : %s''s [VMRK] to Response on WORKSPACE.\n', WORKNAME);
	%'\n'안하는 이유는 아래의 toc 결과가 끝에 붙어나오게 하려고.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% merging 기능: 만약 SubjInfo.Inlier 의 한 cell에 다수 개의 subj 
%	이름이 담겨 있다면, 이들을 순서대로 읽어서, 하나의 데이터로 합침
%	epoch 기준으로 concatenate 해야 함.
	eMRK			=	{;};								% empty 2D array
	eEEG			=	[;;];								% empty 3D array
	for s			= 1 : length(lSRCNAME)					% 반드시 cell array임
		SRC_NAME	=	lSRCNAME{s};
		hEEG.FileInfo.InFile	=	SRC_NAME;

		%check & auto skip if not exist a 'dat file.
		fprintf('Checking: Source file: ''%s''... ', SRC_NAME);
		if exist(SRC_NAME, 'file') <= 0						%skip
			fprintf('not! & SKIP converting this\n\n');
			continue;										%exist !!
		else
			fprintf('EXIST & Continue the converting\n\n');
		end

%%-------------------------------------------------------------------------------
% Convert: VMRK@EEG -> Response
% -------------------------------------------------------------------------------
		% VMRK 파일을 생성한다.
		fVmrk		=	regexprep(SRC_NAME, '.[A-Za-z]*$', '.vmrk');
%		eval(['Fp	=	fopen(''' fVmrk ''',''r'');']);
%		if Fp < 0, ChanList = []; SDP = 0; fSmpl = 0; return; end
%		fprintf('Generating VHDR file to %s\n', fvhdr);

		lTGR		=	bva_readmarker(fVmrk);

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%%%% 계산에 앞서!, 트리거 코드 중 비정상코드(시간적으로 불가능하게 마킹되는)를
%% 필히 제거해야 함.
%% 이때, PRT 포트에서 8bit 2진수로 코드값이 생성됨에 따른, 각 bit-field 별
%% time overap 에 의해 발생가능한 조합인지와 같은 reasonable 한 경우로 한정!

		% 20151204A. 상기 비정상코드를 reasonable 한 상황하에서 판독해 낼 것.
		%	1. 시간적인 불가능성 고려할 것.
		%	2. bit-field 조합에서 판독할 것.
		% lTGR의 구조: (a,b) = ( marker, time )

		% 마커를 stim vs resp 의 조합으로 묶으면서, 시간적으로 불가능한 경우 조사
		% 이 조합은 인접한 두개의 marker 이며, stim은 2자리+, resp는 1 자리 임.
		if isnan(lTGR(1,1)), lTGR(1,1) = 0; end	% 첫번째 marker는 NaN 임!
%{
		Rm4Over		=	zeros(0);				% bit-field overalp 문제 %-[
		Rm4Time		=	zeros(0);				% 시차 오류
		for m = 2 : size(lTGR, 2)-1				% 맨 처음은 NaN !
		if 10 <= lTGR(1,m) & lTGR(1,m+1) <= 9	% stim 2자리+, resp 1자리
			if lTGR(2,m+1) - lTGR(2,m) <= 10	% 시차가 10ms 이내?
			% -----
			if bitor(lTGR(1,m-1), lTGR(1,m+1)) == lTGR(1,m) %bit필드 overlap 현상
				Rm4Over(end+1)	=	m;			% 제거할 인덱스
			elseif 10 <= lTGR(1,m-1)			% overlap없고, 그 앞도 stim 경우
				Rm4Time(end+1)	=	m;			% 제거할 인덱스
			else								% overlap 아니고, 앞도 stim X ?
				error('Error');
			end

%			else								% 시차정상인 경우
%				lTGR(:,n+0)	=	lTGR(:,m-0);
%				lTGR(:,n+1)	=	lTGR(:,m+1);
			end

		end	% if stim ~ resp 자릿수
		end	% for	%-]
%}
		% detection 함수 정의
		fEpoch		=	@(m) ( 10 <= lTGR(1,m) & lTGR(1,m+1) <= 9 ); % stim~resp
		fNarrow		=	@(m) ( lTGR(2,m+1) - lTGR(2,m) <= 10 );	% 시차 10ms 이내
		fOverlap	=	@(m) ( bitor(lTGR(1,m-1), lTGR(1,m+1)) == lTGR(1,m) );
		fContStim	=	@(m) ( 10 <= lTGR(1,m-1) & 10 <= lTGR(1,m) ); % 연속stim

		m			=	2:size(lTGR, 2)-1;				% 마커 의 범위

		Rm4Over		=	arrayfun(@(x) ( fEpoch(x)*fNarrow(x)*fOverlap(x) ), m);
		Rm4Over		=	find(Rm4Over)+1;				% m == 2 부터 시작

		Rm4Time		=	arrayfun(@(x) ( fEpoch(x)*fNarrow(x)*fContStim(x) ), m);
		Rm4Time		=	find(Rm4Time)+1;				% m == 2 부터 시작
		Rm4Time		=	find(~ismember(Rm4Over, Rm4Time));	% 중복 제거

		if length(Rm4Over) > 1
			fprintf('Detect  : #%d of MARKERs for bit-field overaping.\n',	...
				length(Rm4Over));
		end
		if length(Rm4Time) > 1
			fprintf('Detect  : #%d of MARKERs for too short timing.\n',		...
				length(Rm4Time));
		end
		lTgr		=	lTGR;
		lTgr(:,[ Rm4Over Rm4Time ] )	=	[];			% 비정상 마커 제거

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		% lTgr이 정리되었으므로, stim ~ resp 마커 조합을 구체적으로 찾아낸다.
		RT			=	bva_rt(lTgr, mkStim, mkResp, Freqs);	% reaction time

		% --------------------------------------------------
%		Timing		=	squeeze(lTgr(2,:));		% 시간정보만 추출
		lMkXResp	=	find(lTgr(1,:) <= 9 & lTgr(1,:) ~= mkResp);	% 틀림|miss
		lMkXResp	=	lTgr(1, lMkXResp);		%  마커 번호
%		InCr		=	bva_rt(lTgr, mkStim, mkInCr, Freqs);	% reaction time
%		Miss		=	bva_rt(lTgr, mkStim, mkMiss, Freqs);	% reaction time
		XRT			=	arrayfun(@(x)({bva_rt(lTgr,mkStim,x,Freqs)}), lMkXResp);
		XRT			=	cell2mat(XRT);
%		[RT, SD, n]	=	RT(mrk, [101 1], [13 ...])

		% --------------------------------------------------
%		ER			=	ErrRt(lTgr, [101 1], [2,3,...]); % [ ]속: % incor, miss
		% 공식: correct / (correct + incorrect + missing )
		%		correct: [ 101 1 ]
		%		incor  : [ 101 2 ]
		%		missing: [ 101 3 ]
		ER			=	length(RT) / (length(RT) + sum(XRT));

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		% RT, ER 을 구했으므로, 일정한 양식으로 출력하자.
		fprintf(['Results : %s''s Reaction Time(s:%d vs r:%d) = #%d\n',		...
				'& Error Rate = %.2f\n\n'],OUT_NAME,mkStim,mkResp,length(RT),ER);
%		for r = 1 : length(RT), fprintf('%3dth Trial''s RT = %4d\n',r,RT(r)); end

		XLS			=	fopen(OUT_NAME, 'w');			% txt 로 출력
		for r = 1 : length(RT)
			fprintf(XLS, '%d\n', RT(r));
		end
			fprintf(XLS, '%f\n', ER);
		fclose(XLS);

	end % for s

end	% for sub
end	% for data
