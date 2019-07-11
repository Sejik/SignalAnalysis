% L_Elec2DTF ver 0.3
%% [scalp/electrode 수준에서 source localization 및 DTF 계산까지 batch mode 수행]
%
% [*Input Parameter]--------------------------------------------------
% Param_Script: 파라미터 정보가 포함된 script
%
% [*Output Parameter]--------------------------------------------------
% Duration: 수행시간
%
% ex) L_Elec2DTF( l_Elec2DTF_SSVEP_NEW )
%
%------------------------------------------------------
% first created at 2016/03/23
% last  updated at 2016/07/04
% by Ahn Min-Hee::tigoum@naver.com, Korea Univ. MinLAB.
%.....................................................
% ver 0.10 : 20160323. scalp -> source localization 단계까지 작성됨
% ver 0.20 : 20160704. scalp -> source -> DTF 까지 완료. 속도개선(최소5배)
% ver 0.30 : 20160705. 성능개선(특히 scalp->source 병렬화)위한 조치진행 중
%------------------------------------------------------

function [ DurationTime ]	=	L_Elec2DTF( A_global_AmH )
%% minlab scalp mat -> eConnectome -> BA level mat
% designed by Sejik Park, edited by tigoum
clearvars -except BBCI BTB A_global_AmH
close all
%clc

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%%주요 변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@
%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
hEEG		=	A_global_AmH();						% param은 fnx ptr

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Total		=	tic;								%전체 연산 시간

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%% set important variable !!!	-> EEG 데이터의 전 구간을 계산하는 방식으로 변경!
ROI			=	load(fullfile(hEEG.RoiDir, hEEG.RoiName));
%{
%% 전체 ROI 데이터 중 -> BA10L, R 만 확보한다.
ix			=	cellfun(@(x)( strcmp(x, 'BA10L') | strcmp(x, 'BA10R') ), labels);
labels		=	labels(ix);
centers		=	centers(ix,:);						% 2D
vertices	=	vertices(ix);
%}

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%% main
for ixCD	=	hEEG.Cond							% condition 정보 획득
	hEEG.CurCond		=	char(ixCD);				% 현재 조건 등록 for 작업

for ixSJ	=	1:length(hEEG.Inlier)
	SbjTime	=	tic;

	hEEG.CurixSJ		=	ixSJ;					% index for current sbj
	[ EEG hEEG ]		=	S_MATreader( hEEG );	% 개별 sbj file 목록
	if isempty(EEG),	continue; end				% skip this subject

	fprintf('\n--------------------------------------------------\n');
	fprintf('\n-Read & merge the input file----------------------\n');

	%% scalp data -> source localization -> BA (ROI) 처리를 수행!
	[SrcROI options]	=	L_Elec2BAproc(EEG, hEEG, ROI, 1, EEG.points);

	%% SL activity(voxel) -> BA activity(ROI) complete: currently, we needs!
	% BA activity 계산 완료 됐음. 이것을 저장해서 사용하면 됨

	% ---------------------------------------------------------------------------
	% re structuring ROI data to eEEG style : BA x tp(BA) -> tp x BA x ixEP
	% 사용하기 좋도록, 2D화되어 있는 ROI 결과를 eEEG 방식으로 변경
	%	물론, EEG.org_dims field가 존재할 경우에 맞춰서 재구성 후 저장

%	eMRK				=	labels;
	%% 20160323A. 중대 문제 발견: marker는 반드시 eEEG의 original을 쓸 것!!!
	% 만약 기존처럼 labels(==ROI name)을 쓰면 prediction시 아무런 의미가 없음!
	% 즉, 모든 epoch 에서 완전히 동일한 marker 가 주어지는 셈이 되기 때문!
	%% 반드시 원래 실험시점에서 측정된 marker를 그대로 사용해야 정확한 제시 됨
	if ~isfield(EEG, 'marker'), fprintf('Warning : MUST BE needs the marker');
	else,	eMRK		=	EEG.marker; end

	eCHN				=	ROI.labels;
	[eFS, srate]		=	deal(EEG.srate);

	eEEG				=	cell2mat(SrcROI);			% BA x tp
	if isfield(EEG, 'org_dims')
		dims			=	EEG.org_dims;				% tp x ch x ixEP
		if isfield(EEG, 'org_permute') & EEG.org_permute% 원본이 3D 인 경우
			dims		=	[dims(2) dims(1) dims(3)];	% ch x tp x ixEP
		end
		eEEG			=	reshape(eEEG, [], [dims(2)], [dims(3)]);
														% BA x tp -> BA x tp x ixEP
%		if EEG.org_permute, eEEG = permute(eEEG,[2 1 3]); end %BA*tp*ixEP->tp*BA*ixEP
%		eEEG			=	permute(eEEG, [2 1 3]);		% tp*BA*ixEP->BA*tp*ixEP
	else
		eEEG			=	shiftdim(eEEG, 1);			% BA x tp -> tp x BA
	end

%{
	% Source Data structure
	sourcedata	: {1x2500 cell}
	srate		: 500
	startepoch	: 1
	endepoch	: 2500
%}
	SRCTS.sourcedata	=	SrcROI;
	SRCTS.srate			=	EEG.srate;
	SRCTS.startepoch	=	options.startepoch;
	SRCTS.endepoch		=	options.endepoch;
%	save([ FILEPATH '.source' ],	'sourcedata', 'srate',					...
%									'startepoch', 'endepoch', '-v7.3');
%	SRCTSS{ixEP}			=	SRCTS;

	% eConnectome 환경에의 적용을 위해서, 해당 포맷으로도 출력
	% 조사에 의하면, ROI time serise window 에서는 위에서 계산된 ROI time
	% 데이터를 import 할 수 있는 기능이 없음!
	% 따라서, 출력 생성 무의미
%{
	% ROITS structure
	labels: {1x12 cell}
	vertices: {1x12 cell}
	centers: [12x3 double]
	data: [12x2500 double]
	srate: 500
	cortex: [1x1 struct]
	individual: 0
%}
	ROITS				=	struct;						% structure
	ROITS.labels		=	ROI.labels;		% array for ROITS ( from ROI.mat )
	ROITS.centers		=	ROI.centers;	% array for ROITS ( from ROI.mat )
	ROITS.vertices		=	ROI.vertices;	% array for ROITS ( from ROI.mat )
	ROITS.srate			=	EEG.srate;					% sampling rate
	ROITS.data			=	cell2mat(SrcROI);
	ROITS.individual	=	0;
	ROITS.cortext.Vertices			=	[];	%[20516 x 3 double];
	ROITS.cortext.Faces				=	[];	%[41136 x 3 double];
	ROITS.cortext.FaceVertexCData	=	[];	%[20516 x 3 double];
%	save(fullfile(hEEG.PATH,hEEG.DstDir,[EEG.name '_ROITS.mat']),'ROITS');
%	ROITSS{ixEP}			=	ROITS;

%	fprintf('\nStoring data for %s ', EEG.name);
%	save(FILEPATH, 'eEEG', 'eMRK', 'eCHN', 'eFS', '-v7.3');

%	clear eEEG eMRK SrcROI								% be clear for mem free
%%	delete(fullfile(hEEG.Dst, [EEG.name '_cplog' '.mat']));% cplog 제거

	% --------------------------------------------------
	fprintf('\nMigration to DTF calculation for %s.', EEG.name);

%	load(fullfile(hEEG.Src, EEG.name));					% eEEG : tp x BA x ixEP
%	eMRK				=	EEG.marker;
%	eCHN				=	labels;
%	labels				=	eCHN;
%	[eFS, srate]		=	deal(EEG.srate);
%	srate				=	eFS;

%	dtflowfedit			=	hEEG.FreqWindow(1);
%	dtfhighfedit		=	hEEG.FreqWindow(2);
%	optimalorder		=	4;

%	dtfmatrixs			=	zeros(length(eCHN), length(eCHN), 0, size(eEEG,3));
%	dtfmatrixs			=	[;;;;];						% dummy 4D
	DTFS				=	{};							% dummy
%	eEEG				=	permute(eEEG, [2 1 3]);		% tp*BA*ixEP->BA*tp*ixEP
%	eEEG				=	reshape(eEEG, size(eEEG,1), []);	% 2D
	%% eEEG dims : BA * tp * ixEP
	for ixEP = 1:size(eEEG, 3)							% 2D 일땐, size()==1
		fprintf('\nCalculate DTF of epoch [%d/%d] on [Brodmann] level.\n',	...
				ixEP,size(eEEG,3));

	% 이 시점에서 voxel 단위로 계산된 source 값을 BA 단위로 계산(즉 평균)
	%% -> 그런데, 앞서 저장된 eEEG 는 이미 BA 단위로 계산된 값이므로 여기선 생략
	%% 그래서, 여기서는 바로 roidata 에 대한 이후 연산 진행
	roidata				=	squeeze(eEEG(:,:,ixEP));		% BA x tp

	% setting info to TS
	TS.data				=	roidata;
	TS.srate			=	srate;
	[TS.nbchan TS.points]	=	size(TS.data);

	startpoint			=	1;
	endpoint			=	TS.points;

%	output				=	dtf_computation(TS, startpoint, endpoint,		...
%								dtflowfedit, dtfhighfedit, srate, optimalorder);
	% output.dtfmatrixs : BA x BA x freq
	output				=	dtf_computation2(TS, startpoint, endpoint,		...
								hEEG.FreqWindow(1), hEEG.FreqWindow(2));
	% output.dtfmatrixs : BA x BA x freq

%	dtfmatrixs = output.dtfmatrixs;
%	dtfmatrixs = mean(dtfmatrixs,3);
%	dtfmatrixs(:,:,:,ixEP)	=	output.dtfmatrixs;
%{
	% DTF structure
	labels		: {1x12 cell}
	locations	: [12x3 double]
	frequency	: [5 14]
	matrix		: [12x12x10 double]
	type		: 'ROI'
	isadtf		: 0
	srate		: 500
	vertices	: {1x12 cell}
%}
	DTF					=	struct();
%	DTF.matrix			=	dtfmatrixs;					% 4D : BA x BA x fq x ixEP
	DTF.matrix			=	output.dtfmatrixs;			% 3D : BA x BA x fq
%	DTF.dims			=	{ 'channel', 'channel', 'frequency' };
	DTF.labels			=	eCHN;
	DTF.locations		=	ROI.centers;	% array for ROITS ( from ROI.mat )
	DTF.frequency		=	hEEG.FreqWindow;	%[dtflowfedit dtfhighfedit];
	DTF.type			=	'ROI';
	DTF.isadtf			=	0;
	DTF.srate			=	srate;
	DTF.vertices		=	ROI.vertices;
%	save(FILEPATH, 'DTF', '-v7.3');

	DTFS{ixEP}			=	DTF;
	end	% for ix = ixEP


	fprintf('\n');
%	S_DTFwriter(hEEG, DTFS, ROITS, SRCTS);				% 이제 출력해보자
	S_DTFwriter(hEEG, DTFS, [], []);					% 이제 출력해보자

	delete(fullfile(hEEG.PATH,hEEG.DstDir,[EEG.name '_cplog.mat']));	% 제거
	fprintf('\nComplete: %s''s processing :: ',char(hEEG.Inlier{ixSJ}{1}) );
	toc(SbjTime),fprintf('==================================================\n');
end				% for sbj
end				% for cond

fprintf('\nFinished: total time is ');	toc(Total);

	%%==================================================

%% -----------------------------------------------------------------------------
% This is local function
%..........................................................................
%
%	input :
%		hEEG	: project header structure
%		lSBJ	: individual (한 명) 의 electrode data file 목록
%
%	output:
%		EEG		: structure
%		hEEGo	: 수정된 hEEG
%			+ (필수) OutName : 내부에서 (입력 이름 파악 후) 적절 구성한 출력path
%			+ (필수) eMRK	: marker
%
function [ EEG hEEGo ] = S_MATreader( hEEG, lSBJ )	% 개별 sbj file 목록

	EEG				=	[];								% 초기화
	hEEGo			=	hEEG;							% return 대비

	sCond			=	hEEG.CurCond;					% condition 정보 획득
	% 제거용 문자열인 경우 4가지 가능성이 있다.
	% ~					:	그냥 이 문자만 제거하면 됨
	% head~REMOVE~other	:	~ 에서 ~ 사이의 REMOVE해당 string을 제거함
	% ~REMOVE			:	~ 이후의 모든 string 제거
	% head~REMOVE		:	~ 이후의 모든 string 제거
	ssCond			=	regexprep(sCond,'\s*~[^~]*~\s*','');		%'~'사이제거
	ssCond			=	regexprep(ssCond,'\s*~\s*[^~]*$','');		%'~'이후제거
	sExt			=	hEEG.ExtName;

	%% 1차 단계: 입력파일의 목록들을 hEEG.Inlier 리스트에서 추출한다
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
	lSBJ			=	hEEG.Inlier{hEEG.CurixSJ};
	lSRCNAME		=	{};	% must be init!:아니면 아래 skip시 다른파일 혼합오류!
	if iscell(lSBJ) && length(lSBJ)>=3
		% 여러 파일들을 결합시켜야 한다. 최종 이름은 처음에 둠
		% 이때 요소갯수는 최소 3개 -> sub1(목적), sub1_1(src), sub1_2(src)
		for s		=	2 : length(lSBJ)				% 1:최종 이름, 2:cut 기준
			WORKNAME=[	char(lSBJ{s}) hEEG.Common '_' sCond	];
%			lSRCNAME{s-1}=[	hEEG.PATH hEEG.Src	WORKNAME sExt	]; %배열
			lSRCNAME{s-1}=fullfile(hEEG.PATH,[hEEG.Src WORKNAME sExt]);%배열
		end
		% 최종적인 file명을 구성함
		WORKNAME	=[	char(lSBJ{1}) '_' ssCond	];

	elseif iscell(lSBJ) && length(lSBJ)<=2
		% 요소 갯수가 2개면, 최종=소스 이므로, 그냥 단일 파일처럼 처리 가능
		WORKNAME	=[	char(lSBJ{2}) hEEG.Common '_' sCond	];
%		lSRCNAME{1}	=[	hEEG.PATH hEEG.Src	WORKNAME sExt	];%only 1
		lSRCNAME{1}	=fullfile(hEEG.PATH,[hEEG.Src WORKNAME sExt]);%only 1

		% 최종적인 file명을 구성함
		WORKNAME	=[	char(lSBJ{1}) '_' ssCond	];

	else	%단일 파일명인 경우
		WORKNAME	=[	char(lSBJ) hEEG.Common '_' sCond	];
%		lSRCNAME{1}	=[	hEEG.PATH hEEG.Src	WORKNAME sExt	];%only 1
		lSRCNAME{1}	=fullfile(hEEG.PATH,[hEEG.Src WORKNAME sExt]);%only 1
	end

	%% 2차 단계, 구성한 입력 목록에 대해, Fold 목록을 추가하여, 확장 구성한다.
	if length(lSRCNAME) == 1 & isfield(hEEG, 'lFolds')	% 1개 일때만 fold처리가능
		[PT NM EX]	=	fileparts(lSRCNAME{1});
		lSRCNAME	=	{};
	for ixFL		=	hEEG.lFolds
		lSRCNAME{end+1}=	fullfile(PT, [NM '_' num2str(ixFL) EX]);
	end
	end

	% 최종 출력 파일명 구성
%		OUT_NAME	=[	hEEG.PATH hEEG.Dst	WORKNAME '.mat' ];
		WORKNAME	=	regexprep(WORKNAME, '[_]+$', '');		% '_' 로 끝남
%		OUT_NAME	=[	hEEG.PATH hEEG.Dst	WORKNAME '_1.mat' ];
%		OUT_NAME	=	fullfile(hEEG.PATH,[hEEG.Dst WORKNAME '_1.mat']);
%		hEEG.FileInfo.OutFile	=	OUT_NAME;
		OUT_NAME	=	fullfile(hEEG.PATH, [hEEG.Dst WORKNAME '_']);
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
		re	=	sprintf('su%04d', hEEG.CurixSJ);
		OUT_NAME=regexprep(OUT_NAME, su, re);			% mapping new name
	end
	[DIR, OUT, Ext]	=	fileparts(OUT_NAME);			% 출력파일 존재 확인용
	if	hEEG.fgExportTxt, Ext = '.txt'; else Ext = '.mat'; end
%	fprintf('\nChecking: Analyzed result file: ''%s''...',[OUT_IMAG '.jpg']);
	fprintf('\nChecking: Analyzed result file: ''%s''...', [OUT_NAME '*' Ext]);
%	if exist([OUT_IMAG '.jpg'], 'file') > 0				%exist !!
%	oPATH	=	regexprep(OUT_NAME, '(.+\/)([^/]+)$', '$1');
%	oNAME	=	regexprep(OUT_NAME, '(.+\/)([^/]+)$', '$2');
%	try, EXIST = ls([OUT_NAME '*.*t'], '-1'); catch, EXIST = 0; end
%	if ~EXIST											% no exist, let's go
	[~, EXIST] = system(['find "' DIR '/" -name "' OUT '*' Ext '" 2>/dev/null']);
	EXIST			=	regexprep(EXIST, '[\r\n]', '');	% trim
	if	isempty(EXIST) |	...								% no exist, let's go
		strcmp(fullfile(DIR,[OUT 'cplog' Ext]), EXIST)	% only log
		fprintf('NOT & Continue the Analyzing\n');

	elseif isfield(hEEG, 'Retain') & any(ismember(hEEG.Retain, lSBJ{1}))
		fprintf('exist! & SKIP analyzing this, Retaining\n');
		return;											% skip

	elseif isfield(hEEG, 'Rework') & any(ismember(hEEG.Rework, lSBJ{1}))
		fprintf('exist, BUT Continue the Analyzing\n');

	else												% Retain/Rework 무소속
		fprintf('exist! & SKIP analyzing this\n');
		return;											% skip
	end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%	AllTime			=	tic;		%데이터 preparing 시간을 계측한다.
	fprintf('--------------------------------------------------\n');
	fprintf('Convert : %s''s DAT to RAW for [ %s ]\n', WORKNAME,			...
			[ regexprep(OUT_NAME, '.*(su[0-9]{4}.*)$', '$1') '*' Ext ]);
	%'\n'안하는 이유는 아래의 toc 결과가 끝에 붙어나오게 하려고.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% merging 기능: 만약 SubjInfo.Inlier 의 한 cell에 다수 개의 subj 
%	이름이 담겨 있다면, 이들을 순서대로 읽어서, 하나의 데이터로 합침
%	epoch 기준으로 concatenate 해야 함.
%	eMRK			=	{;};							% empty 2D array
	eMRK			=	[];								% empty 2D array
	eEEG			=	[;;];							% empty 3D array
	for s			= 1 : length(lSRCNAME)				% 반드시 cell array 임!
		SRC_NAME	=	regexprep(lSRCNAME{s}, '_([.][a-zA-Z]+)$', '$1'); % trim
%		hEEG.FileInfo.InFile	=	SRC_NAME;

		%check & auto skip if not exist a 'dat file.
		fprintf('\nChecking: Source file: ''%s''... ', SRC_NAME);
		if exist(SRC_NAME, 'file') <= 0					%skip
			fprintf('not! & SKIP converting this\n\n');
			continue;									%exist !!
		else
			fprintf('EXIST & Continue the converting\n');
		end

		%% 해당 subject 에 대한 data 를 loading 한다
		if strcmp(hEEG.ExtName, '.dat')
%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
		VMRK		=	VMRK{1};							% only marker 추출

		% --------------------------------------------------
%		eval(['BAdat		=	importdata(''' SRC_NAME ''');']);


		%% pop_matreader 에서 *.dat format 을 loading 하도록 수정해야 함.
		%	-> pop_matreader 가 vidx, StdLocation 등 source 변환에 필요한
		%		정보를 생성하줘야 하기 때문.
		%% 당장은 시간부족으로 처리 못함!
		BAdat		=	importdata( SRC_NAME );
		%*.dat 파일의 첫 줄에 저장된 채널 순서를 확인해 보아야 함!
		if ~isstruct(BAdat),	BAdat	=	struct('data', BAdat); end

%		B			=	BAdat.data;
%		B			=	shiftdim(B, 1);
%		eBLK		=	reshape(B, 1000, [], 32);
%		eBLK		=	reshape(BAdat.data, 1000, [], 32);
%%		eBLK		=	reshape(BAdat.data, SDP, [], MxCh); %% time * ixEP * ch

		%% 20151117A. BA의 export 옵션에 따른, import *.dat reshape 오류 발견
		% Wavelet을 사용할 때 데이터 타입은 항상 (timepoint x epochs x channels)
		% 형태 일 것! 하지만, 경우에 따라서, Brain Analyzer의 export로부터
		% 전혀 다른 구조의 dat format 이 load 될 수 있음.
		% DataOrientation=MULTIPLEXED: 인 경우 [data point seriese] x [ch] 구조
		% DataOrientation=VECTORIZED : 인 경우 [ch] x [data point seriese] 구조
		% 따라서, orientation 에 따라 다른 처리 과정을 거쳐, 최종적인 eEEG 형식
		% 확보를 시행해야 함.
		% eEEG 형식: timepoint x epoch x ch
%%		if		strcmp(Orient,'VECTORIZED') &&	size(BAdat.data,1)==MxCh
%%			eBLK	=	reshape(BAdat.data, MxCh, SDP, []);	%% ch * time * ixEP
%%			eBLK	=	shiftdim(eBLK, 1);				% tm x ixEP x ch

%%		elseif	strcmp(Orient,'MULTIPLEXED') &&	size(BAdat.data,2)==MxCh
			eBLK	=	reshape(BAdat.data, SDP, [], MxCh);	%% time * ixEP * ch

			% 20160430A.simulating for confused data as VECTORIZED->MULTIPLEXED
%			eBLK	=	shiftdim(eBLK, 2);				% ch * time * ixEP
%			eBLK	=	reshape(eBLK, SDP, [], MxCh);	% time * ixEP * ch
%%		end

%		clear B BAdat
		clear BAdat

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		elseif strcmp(hEEG.ExtName, '.mat')			% eEEG 담기 mat 형식
		[DIR, OUT]	=	fileparts(SRC_NAME);		% 출력파일 존재 확인용
%		EEG			=	load( SRC_NAME );			% 읽은 data -> EEG struct
		EEG			=	pop_matreader(OUT, fullfile(DIR), hEEG.Chan);	% read
%		clear EEG

		% EEG.data를 3D 구조(원본 구조)로 재변경 한다: 부수적인 작업 때문
		% 구조: ch x tp(x ixEP) -> ch x tp x ixEP
		if isfield(EEG, 'marker')					% ch x tp -> ch x tp x ixEP
			[eBLK VMRK]=deal(EEG.data, EEG.marker);	% 추출
			eBLK	=	reshape(eBLK, EEG.nbchan, [], [length(EEG.marker)]);
		else
			[eBLK VMRK]=deal(EEG.data, []);			% 추출
			eBLK	=	reshape(eBLK, EEG.nbchan, [], [1]);
		end
			eBLK	=	permute(eBLK, [ 2 3 1 ]);	% -> tp x ixEP x ch
		end

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%		eBLK(:,:,17)=	NaN;	% EOG
%		eBLK(:,:,22)=	NaN;	% NULL
%		eBLK(:,:,find(ismember(eCHN,'EOG')) )	=	0;	% EOG

%%		save([hEEG.PATH '/skk_data/skk_' SRC_NAME], 'eBLK');	% eBLK array 저장

		nMRK		=	size(VMRK, 1);
%		eMRK(end+1:end+nMRK,:)	=	VMRK;			% horzcat or vertcat
		eMRK(end+1:end+nMRK)	=	VMRK;			% horzcat or vertcat

		%% 원본 eEEG (*.mat) 가 3D 구조일 경우라도,
		% pop_matreader() 를 통해 읽혀진 EEG.data는 2D 변환 된 구조이고,
		% 그래서, 2번째 차원은 tp x ixEP 을 1D 로 sequence 하게 나열된 구조임.
		% 이것들을 아래와 같이 concatenate 하면, 2번째 차원 에 append 됨
		% 테스트 결과, 이 결과에 대해 reshape하면 원본3D를 epoch에 대해
		% concatenate 한 것과 동일함!
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
	if isempty(eEEG), return; end					% data 없으면 다음 subj로!
	%% ----------

%% ------------------------------------------------------------------------------
%% 20150517B. eEEG 데이터에 대한 기본적인 처리/점검 기능이 필요함.	%-[
	%단, 데이터가 아닌 더미채널을 제거해야 한다.
	% ch17= EOG, ch22=NULL, 없는 부분 날림. 뒤에서 부터 날려야 제대로 처리됨.
	% -> 20150517C. 이젠 이 제약은 없어졌음. 앞에서부터 순서대로 제거 가능

	tic; fprintf('\nFinding : & remove a dummy channels on eEEG array.\n');
	%% it must be consider to hEEG.ixLive with EEG.vidx index!
%	hEEG.ixLive		=	find(~ismember(EEG.labels,hEEG.ChRemv) );%살아있는 채널만
%	hEEG.ixRemv		=	find( ismember(EEG.labels,hEEG.ChRemv) );%죽어있는 채널만

	% eCHN 에서도 live 채널만 남겨 두기로 한다.
%	eEEG([ hEEG.ixRemv ],:,:)	=	[];				% remove 채널 제거
%	EEG.labels		=	EEG.labels([ hEEG.ixLive ]);% live 만 유지
%	EEG.nbchan		=	length(EEG.labels);			% update

	%eEEG 데이터 중 NaN 인 것이 있으면, 해당 값을 가진 채널과의 비교에서
	%매번 엉뚱한 값을 생성하며, 불필요한 연산을 유발할 수 있음.
	%따라서, 이 값을 가진 채널이 있다면, Notify 해야 함!!
	%eEEG 규모가 광범위 할 경우, 시간이 소요 될 수도 있음에 유의할 것.
	fprintf('Search  : a NaN value on eEEG array\n');
%	[ rNaN cNaN ]	=	find(isnan(eEEG));			% 2D 관점에서 위치 찾기
%	Linear			=	sub2ind(size(eEEG), rNaN, cNaN);	% eEEG 1D형 index
	Linear			=	find(isnan(eEEG(:)));		% 1D 관점으로 찾기
	if ~isempty(Linear)								% 뭔가 값이 있음
		fprintf('Notify  : eEEG(%s) have %d of NaNs\n', WORKNAME,length(Linear));
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

%% ------------------------------------------------------------------------------
	% tp 에 대한 time window 조정해야 함.
	%% 필요한 범위만 capture, tp x ixEP x ch
	eFS				=	EEG.srate;					% sample rate
	% interval param 이 eFS 및 eEEG tp length 와 적절히 대응하는지 조사
	tIntr			=	[hEEG.tInterval(1) :1000/eFS: hEEG.tInterval(2)-1];
	tWin			=	[hEEG.TimeWindow(1):1000/eFS: hEEG.TimeWindow(2)-1];
	if length(tIntr)~=size(eEEG,1) error('Mismatch [Interval] for Data'); end
	eEEG			=	eEEG(ismember(tIntr, tWin), :, :);	% window 범위만 취득
	fprintf('\nModulate: TIME window [%d] -> [%d]\n',length(tIntr),size(eEEG,1));

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 20160426A. flag에 따라 [original 순서] 혹은 [sort 재구성 순서] 해서 출력한다
%%_______________________________________________________________________________
	if ~isempty(eMRK) & isfield(hEEG, 'fgReorder') & hEEG.fgReorder	% mrk별 sort
%		eMRKa		=	cell2mat(squeeze(eMRK(:,2)))';	% 마커값만 추출
%		[~, ix]		=	sort(eMRKa);				% 변경된 ix 만 확보
		[eMRK ix]	=	sort(eMRK);					% 변경된 ix 만 확보
		eEEG		=	eEEG(:, ix, :);				% epoch 정렬
	elseif isempty(eMRK)
		eMRK		=	ones(1,size(eEEG,2));		% 기본값 설정
	end

	%% 최종 결과를 3D -> 2D 로 다시 조정 후 EEG 에 update (마커도)
%	EEG.org_dims	=	size(eEEG);
	EEG.org_dims(1)	=	size(eEEG,1);				% tp
	EEG.org_dims(2)	=	size(eEEG,3);				% ch
	EEG.org_dims(3)	=	size(eEEG,2);				% ixEP

%	eEEG			=	reshape(eEEG,EEG.nbchan,EEG.points,[]); % ch*tp->ch*tp*ep
	eEEG			=	permute(eEEG, [ 3 1 2 ]);	% tp*ixEP*ch -> ch*tp*ixEP
	EEG.org_permute	=	true;						% using shiftdim()
	EEG.data		=	reshape(eEEG, EEG.nbchan, []);	% ch x tp x ep -> ch x tp
%%	EEG.data		=	eEEG;						% 3D 유지!
	EEG.nbchan		=	size(EEG.data, 1);
	EEG.points		=	size(EEG.data, 2);
%%	EEG.epoch		=	size(EEG.data, 3);
	EEG.marker		=	eMRK;
	hEEGo.eMRK		=	eMRK;
	[~, OUT]		=	fileparts(OUT_NAME);		% 출력파일 존재
	EEG.name		=	regexprep(OUT, '_$', '');
	hEEGo.OutName	=	OUT_NAME;					% 보관

	vdata			=	EEG.data(EEG.vidx,:);		% 임시, 선택채널 데이터만
    EEG.min			=	min(EEG.data(:));
    EEG.max			=	max(EEG.data(:));

	%%==================================================

%% -----------------------------------------------------------------------------
% This is local function
%...............................................................................
%
%	input :
%		hEEG	: project header structure
%			+ (필수) OutName
%			+ (필수) eMRK
%
%		(*) data 종류: electrode (순수입력) -> SOURCE -> ROITS -> DTF
%		DTF		: Direct Transfer Function, BA x BA x freq x epoch
%		ROITS	: ROI Time Series, BA x tp x epoch
%		SRCTS	: Source Localization, VX x tp x epoch
%
%	output:
%		BOOL	: 저장 성공 여부
%
function [ BOOL ] = S_DTFwriter( hEEG, DTFS, ROITSS, SRCTSS )
	% 마커는 이미 reader 에 의해 정렬되어 있으므로, 여기서는 마커 그룹별로
	% 분류 (폴더 생성) 해서 출력하는 작업 시행.
	% 마커 폴더 내에서 각 epoch의 번호는 파일이름 끝에 부여됨
	fprintf('--------------------------------------------------\n');
	fprintf('Write   : DTF to file by each epoch\n');

	sFrom			=	S_form4len( length(hEEG.eMRK), true );
	for ixEP		=	1:length(hEEG.eMRK);			% ixEP 수 == 마커 수

		[DIR, OUT]	=	fileparts(hEEG.OutName);		% 출력파일 존재 확인용
		if isfield(hEEG, 'fgSplitSbj')  & hEEG.fgSplitSbj	% subject 별 분리
			sbj		=	char(regexp(OUT, 'su[0-9]{4}', 'match'));	% extract
			DIR		=	fullfile(DIR, sbj);
		end
		if isfield(hEEG, 'fgSplitCond') & hEEG.fgSplitCond	% cond 별 분리
			DIR		=	fullfile(DIR, hEEG.CurCond);	% 만약 '' 이면 무시
		end
		if hEEG.fgSplitEpoch & hEEG.fgReorder			% 마커별 분리
%			DIR		=	[ DIR '_' num2str(hEEG.eMRK(ixEP)) ]; % 폴더명에 마커추가
			DIR		=	fullfile(DIR, num2str(hEEG.eMRK(ixEP)));
		end
		if not(exist(DIR, 'dir')), mkdir(DIR); end		% 없으면 폴더 생성

		% 저장한 변수를 epoch 단위로 추출
%		[DTF ROITS SRCTS]=deal(DTFS(:,:,ixEP),ROITSS(:,:,ixEP),SRCTSS(:,:,ixEP));
		DTF			=	DTFS{ixEP};

		% DTF의 frequency dimension을 평균내서 제거할 것인지 조처
		if hEEG.fgAvgDTF, DTF.matrix=squeeze(mean(DTF.matrix,3)); end %freq차원X

		% 저장할 데이터 종류에 대한 flag 를 기준으로, 파일에 데이터를 저장
		OUT_NAME	=	fullfile(DIR, sprintf(['%s_' sFrom], OUT, ixEP));% 파일명
		OUT_NAME	=	regexprep(OUT_NAME, '_{2,}', '_'); % del 2 more '_'
		Var			=	{};
		if hEEG.fgSaveDTF, Var{end+1} = 'DTF'; end		% 저장변수 목록에 추가
%		if hEEG.fgSaveROI, Var{end+1} = 'ROITS'; end	% 저장변수 목록에 추가
%		if hEEG.fgSaveSRC, Var{end+1} = 'SRCTS'; end	% 저장변수 목록에 추가

		% 이제 저장하자.
		eval(['save(''' OUT_NAME ''',''' strjoin(Var,''',''') ''',''-v7.3'');']);
	end	% for ixEP

