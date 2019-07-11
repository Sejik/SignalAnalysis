% B_Dat2MATsplit ver 0.75
% 20151118A. export 된 *.dat를 the original recording order 대로 수집/출력
%
% usage: B_Dat2MATsplit( @b_Dat2MAT_SSVEP_NEW )
%	-> param is must be function pointer ! :: attach to '@' first
%
% first created by tigoum 2015/11/18
% last  updated by tigoum 2016/04/23

%%function [ DurationTime ]	=	L03Elec2eConBA_AmH( hEeg )
% ver 0.75 : rename this function

%% minlab scalp mat -> eConnectome -> BA level mat
% designed by Sejik Park, edited by tigoum
clearvars -except BBCI BTB hEeg
close all
%clc

%% set variable
basePATH	=	'/home/minlab/Tools/MATLAB/eConnectome++/';
%eEEGDir		=	[ basePATH 'eEEG' ];			% eEEG(minlab) 데이터
%rawDir		=	[ basePATH 'RAW' ];				% ERP(minlab) -> eCon 변환된 raw
roiDir		=	[ basePATH 'ROI' ];				% BA 대응 ROI 좌표 저장된 mat
%sourceDir	=	[ basePATH 'SRC' ];				% 연산 결과 저장 공간

%% initialize
sProject			=	'SSVEP_NEW';
%sProject			=	'PFC_64';

if		strcmp(sProject, 'SSVEP_NEW')		%-[
dataPATH	=	[ '/home/minlab/Projects/' sProject '/SSVEP_3/' ];
condition	=	{ 'TopDown', 'Intermediate', 'BottomUp' };
sbj_list	=	[ 1:20 ];
fold_list	=	[ 1:4 ];	%-]
elseif	strcmp(sProject, 'PFC_64')		%-[
dataPATH	=	[ '/home/minlab/Projects/' sProject '/PFC_3/' ];
condition	=	{ '' };	%'TopDown', 'Intermediate', 'BottomUp' };
%sbj_format	=	'PFC_64_su%04d_%s.mat';
%sbj_list	=	[ arrayfun(@(x)({sprintf('su%04d',x)}), [1:29] ) 'GrdAvg' ]; %30
sbj_list	=	[ 12 24 3 4 5 7 9 14 15 16 19 27 26 30 ];	%[ 1:28 30 ];
fold_list	=	[ 1:7 ];
end		%-]

eEEGDir		=	[ dataPATH 'eEEG' ];			% eEEG 데이터
srcDir		=	[ dataPATH 'sEEG' ];
if not(exist(srcDir, 'dir')), mkdir(srcDir); end
sbj_format	=	[ sProject '_%s_%s' ];
CPgap		=	5;								% CP 기록 기준: 매 5% 마다

%% set important variable !!!	-> EEG 데이터의 전 구간을 계산하는 방식으로 변경!
%% 전체 ROI 데이터 중 -> BA10L, R 만 확보한다.
load(fullfile(roiDir, 'ROI100_BALx50_BARx50.mat'));	% BA 좌우42개씩 총 84개 좌표
%{
load(fullfile(roiDir, 'ROI82_BALx41_BARx41.mat'));	% BA 좌우42개씩 총 84개 좌표
ix			=	cellfun(@(x)( strcmp(x, 'BA10L') | strcmp(x, 'BA10R') ), labels);
labels		=	labels(ix);
centers		=	centers(ix,:);					% 2D
vertices	=	vertices(ix);
%}

%POOL				=	S06paraOpen_AmH(false, 4);	% 강제로 core 4개
POOL				=	S_paraOpen();				% 자동 restart
%POOL				=	S_paraOpen(true);			% 강제로 restart

%{
%for f			=	1 : length(hEEG.Trial.Window)
for c			=	1 : length(hEEG.Trial.AllCond)
for s			=	1 : length(hEEG.Subj.Inlier)
%		[hEEG.Trial.CurCond, hEEG.Subj.CurSubj]	=	deal( c, s );
%[hEEG.Freq.CurWin, hEEG.Trial.CurCond, hEEG.Subj.CurSubj] = deal(stFreq.Window{1}, 3, 5);
	[hEEG.Freq.CurWin, hEEG.Trial.CurCond, hEEG.Subj.CurSubj]	=		...
		deal(stFreq.Window{1}, c, s );			% 데이터 파일용 정보 수집
	%-----
	stFreq		=	hEEG.Freq;					% 갱신
	
	[eEEG hEEG BOOL]	=	S03importDat_AmH(hEEG);	% 해당 조건의 데이터
	if ~BOOL,	continue;	end					% BOOL==false, then SKIP
%	if ~BOOL,	return;	end						% BOOL==false, then SKIP

	stChan		=	hEEG.Chan;
	MxCh		=	size(eEEG, 3);				% length(stChan.idxLive);

	if		length(stChan.idxLive) < MxCh		% 데이터 채널수가 더 많음
		fprintf('Warning : \n');
	elseif	length(stChan.idxLive) > MxCh		% 데이터 채널수가 적음
		fprintf('FatalErr: \n');
%	else		% ==	% 문제 될 것 없음
	end
%}

%% main
for ixCD	=	condition
for ixSJ	=	sbj_list
for ixFL	=	fold_list
	tic;

	fprintf('\n--------------------------------------------------\n');
%	FILENAME			=	sprintf(sbj_format, char(ixSJ), [char(ixCD), '_BA']);
	FILENAME			=	[sProject	'_' sprintf('su%04d', char(ixSJ))	...
										'_' char(ixCD) '_' num2str(ixFL)];
	FILENAME			=	regexprep(FILENAME, '_{2}+', '_');	% '_' 2개 이상
	FILENAME			=	regexprep(FILENAME, '_$', '');	% 끝에 '_'
	FILEPATH			=	fullfile(srcDir, FILENAME);
	fprintf('\nChecking: Resulted output file: ''%s''... ', FILEPATH);
	if exist([FILEPATH '.mat'], 'file') > 0			% exist !!
		fprintf('exist! & SKIP this\n');
		continue;									% skip, 다음 subject
	else
		fprintf('NOT & Continue\n');
	end
	% -----
%	FILENAME			=	sprintf(sbj_format, char(ixSJ), char(ixCD));
%	FILENAME			= [sPRJ '_' char(ixSJ) '_' char(ixCD) '_' num2str(ixFL)];
%	FILENAME			=	regexprep(FILENAME, '_$', '');	% 끝에 '_'
	fprintf('Loading data for %s\n', FILENAME);
	% -----
	EEG					=	pop_matreader(FILENAME, fullfile(eEEGDir));	% read
	sForm				=	[ '%' num2str(length( num2str(EEG.points) )) 'd' ];
	stdout				=	1;

	% --------------------------------------------------
	% pop_sourceloc(EEG);
	fprintf('construct model for BEM / transfer eeg data to BEM matrix.\n'); %-[

	% basic varible
	model.italyskin		=	load('italyskin.mat');
	model.cutskin		=	load('cutskin.mat');
	model.italyskinxy	=	load('italyskin-in-xy.mat');
	model.italyskinxyz	=	load('italyskin-in-xyz.mat');
	model.colinbemskin	=	load('colinbemskin.mat');
	model.cortex		=	load('colincortex.mat');
	model.bemcortex		=	load('colinbemcortex.mat');
	model.neighbors		=	load('neighbors.mat');

	transmatrix			=	load('LargeTransMatrix.mat'); % large transfer matrix for colin BEM skin and cortex 
	k					=	cell2mat({EEG.locations(EEG.vidx).colinbemskinidx});
	model.transmatrix	=	transmatrix.TransMatrix(k,:); % get transfer matrix for the electrodes
	[model.U, model.s, model.V]	=	csvd(model.transmatrix);

	% get electrode positions, labels and indices on the italyskin.
	%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	model.k				=	cell2mat({EEG.locations(EEG.vidx).italyskinidx});
	model.electrodes.labels	=	EEG.labels(EEG.vidx);
	model.electrodes.locations= model.italyskin.italyskin.Vertices(model.k,:);
	model.X				=	model.italyskinxy.xy(model.k,1);
			% standard xy coordinates relative to electrodes on the skin
	model.Y				=	model.italyskinxy.xy(model.k,2);   
	zmin				=	min(model.italyskinxyz.xyz(model.k,3));
	Z					=	model.italyskinxyz.xyz(:,3);
	model.interpk		=	find(Z > zmin);		% focus interpolated vertices
	model.XI			=	model.italyskinxy.xy(model.interpk,1);
	model.YI			=	model.italyskinxy.xy(model.interpk,2);		%-]
	%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	options.step			=	round(EEG.points/10);	% -[
	if options.step <= 0, options.step=	2; end
	options.vidx			=	EEG.vidx;
	options.currentpoint	=	1;
	options.auto			=	0;
	options.method			=	'mn';
	options.lamda			=	274.082947;
	options.autocorner		=	1;
	options.threshold		=	0.0;
	options.HWHM			=	3;
%	options.startepoch		=	156;					% startepoch;
%	options.endepoch		=	468;					% endepoch;
%	options.endepoch		=	156+10000;				% endepoch;
	options.startepoch		=	1;						% startepoch;
	options.endepoch		=	EEG.points;				% endepoch;
	options.alpha			=	1;
	options.cutskin			=	0;
	options.labels			=	0;
	options.electrodes		=	0;
	options.sensorcaxis		=	'local';
	options.sensorminmax	=	[EEG.min, EEG.max];
	options.sourcecaxis		=	'local';
	options.sourceminmax	=	[realmax, realmin];
	options.usebem			=	0;
	options.currymatrix		=	0;						%-]

	% --------------------------------------------------
	[StartTp, FinishTp]	=	deal(options.startepoch, options.endepoch);
	fprintf('Localizing epoch [%d:%d] on [Electrode] to [Brodmann] level.\n', ...
			StartTp, FinishTp);

	WorkTp				=	StartTp;				% 작업시작 epoch 지점
	nROI				=	length(labels);
	nTP					=	FinishTp -StartTp +1;
	ROIdata				=	cell(1, nTP);			% compute ROI time series
%________________________________________________________________________________
	%% 20160320A. 계산도중 병렬코어 중 stall 되는 core로 작업 hold 상태 유발
	%	원인: 불명, 아마도 60000개(PFC_64)에 달하는 epoch을 처리하는 과정
	%		에서 모종의 resource deadlock 발생 가능성 추측.
	%	대응: 수행과정의 매 10% 마다 checkpoint log 기록
	%		새로 실행시 log 기록에 의해 마지막 수행기록 시점을 load하여
	%		그 시점부터 재개(rollback) -> 매번 처음부터 다시시작 문제 대응
	if exist(fullfile(srcDir, [FILENAME '_cplog' '.mat']))	% cplog 존재! 읽자
		fprintf('[Detect]   : checkpoint log data ! & analyzing...\n');
		load(fullfile(srcDir, [FILENAME '_cplog']));
		nCalcData		=	length(find(cellfun(@(x)(~isempty(x)), ROIdata)));
		
		% 읽었으면 조사해보자.
		if strcmp(sFILE,FILENAME) & nROI == length(labels) &				...
			nTP == FinishTp -StartTp +1 & length(ROIdata) == nTP &			...
			nCalcData == WorkEnd
%			length(find(cellfun(@(x)(~isempty(x)), ROIdata))) == work-StartTp+1	
			WorkTp		=	WorkEnd + StartTp;			% rollback & restart 시점
			fprintf('[Recovery] : Rollback & Redo from %d to %d epoch\n',	...
					StartTp, WorkTp);
		elseif nCalcData ==		...		% 처음부터 연속된 data면 살려보자
			length(find(cellfun(@(x)(~isempty(x)), ROIdata(1:nCalcData))))
			WorkTp		=	nCalcData + StartTp;
			fprintf('[Recovery] : Rollback & Redo from %d to %d epoch\n',	...
					StartTp, WorkTp);
		else
			fprintf('[Sorry]    : inconsist current metadata, so NEW Start\n');
		end
		clear sFILE;
	end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

%	for		ix	=	StartTp : FinishTp
%	parfor	ix	=	1 : nTP
	% WORKER 단위로 블럭을 나눠서 수행해야 진행상황을 식별할 수 있음
%	for		work		=	[StartTp	: POOL.NumWorkers	: FinishTp]
	for		work		=	[WorkTp		: POOL.NumWorkers	: FinishTp]
		WorkStart		=	work -StartTp +1;		% ix 가 1부터 시작하게!
		WorkEnd			=	min(work+POOL.NumWorkers-1, FinishTp) -StartTp +1;
		% 이경우, workend 가 numworker의 배수가 아니면, 끝에 모자란 부분 감안

		% 진행 경과 판독 및 출력
		fprintf(stdout,	['+ %s : COMPUTE Localizing for [' sForm ':' sForm ']'...
	' / %d = %6.3f%%\r'],	regexprep(FILENAME, [sProject '_(.+)'], '$1'),	...
							WorkStart, WorkEnd, nTP, WorkEnd/nTP*100);

	parfor	ix			=	[WorkStart : WorkEnd]
%		electrodes		=	EEG.data(options.vidx, ix);
		electrodes		=	EEG.data(options.vidx, ix +StartTp -1);

		ROIdata(ix)		=	L_CalcElec2ROI(electrodes, vertices, model, options);

%		fprintf('+ Localizing for [%05.3f%%] (%d / %d)\n',					...
%					ix / nTP *100, ix, nTP);
	end		% parfor
%________________________________________________________________________________
		%% 20160320A. 이슈에 의해 구성된 log 저장 기능
		if nTP >= 10000 & mod( round(WorkEnd / nTP * 100, 1), CPgap) == 0
		% epoch 수가 10000 개 이상일 때 cp 기능 수행: 소수 2자리 버림: 5% 확정
			sFILE		=	FILENAME;
			save(fullfile(srcDir, [FILENAME '_cplog']), 'sFILE',			...
				'nROI', 'nTP', 'WorkStart', 'WorkEnd', 'ROIdata');
			clear sFILE
		end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	end		% for work

%	options.sourceminmax(1)	=	min( cellfun(@(x)( min(x(:)) ), sourcedata) );
%	options.sourceminmax(2)	=	max( cellfun(@(x)( max(x(:)) ), sourcedata) );

	%% SL activity(voxel) -> BA activity(ROI) complete: currently, we needs!
	% BA activity 계산 완료 됐음. 이것을 저장해서 사용하면 됨

	% ---------------------------------------------------------------------------
	% re structuring ROI data to eEEG style : BA x tp(BA) -> tp x BA x ep
	% 사용하기 좋도록, 2D화되어 있는 ROI 결과를 eEEG 방식으로 변경
	%	물론, EEG.org_dims field가 존재할 경우에 맞춰서 재구성 후 저장

%	eMRK				=	labels;
	%% 20160323A. 중대 문제 발견: marker는 반드시 eEEG의 original을 쓸 것!!!
	% 만약 기존처럼 labels(==ROI name)을 쓰면 prediction시 아무런 의미가 없음!
	% 즉, 모든 epoch 에서 완전히 동일한 marker 가 주어지는 셈이 되기 때문!
	%% 반드시 원래 실험시점에서 측정된 marker를 그대로 사용해야 정확한 제시 됨
	if ~isfield(EEG, 'marker'), error('FATAL   : MUST BE needs the marker'); end
	eMRK				=	EEG.marker;

	eCHN				=	labels;
	[eFS, srate]		=	deal(EEG.srate);

	eEEG				=	cell2mat(ROIdata);			% BA x tp
	if isfield(EEG, 'org_dims')
		dims			=	EEG.org_dims;				% tp x ch x ep
		if EEG.org_permute, dims = [dims(2) dims(1) dims(3)]; end % ch x tp x ep
		eEEG			=	reshape(eEEG, [], [dims(2)], [dims(3)]);
														% BA x tp -> BA x tp x ep
		if EEG.org_permute, eEEG = permute(eEEG,[2 1 3]); end %BA*tp*ep->tp*BA*ep
	else
		eEEG			=	shiftdim(eEEG, 1);			% BA x tp -> tp x BA
	end

	fprintf('\nStoring data for %s ', FILENAME);
	save(FILEPATH, 'eEEG', 'eMRK', 'eCHN', 'eFS', '-v7.3');

	% eConnectome 환경에의 적용을 위해서, 해당 포맷으로도 출력
	% 조사에 의하면, ROI time serise window 에서는 위에서 계산된 ROI time
	% 데이터를 import 할 수 있는 기능이 없음!
	% 따라서, 출력 생성 무의미
%{
	ROITS				=	struct;						% structure
	ROITS.labels		=	labels;			% array for ROITS ( from ROI.mat )
	ROITS.centers		=	centers;		% array for ROITS ( from ROI.mat )
	ROITS.vertices		=	vertices;		% array for ROITS ( from ROI.mat )
	ROITS.srate			=	EEG.srate;					% sampling rate
	ROITS.data			=	cell2mat(ROIdata);
	ROITS.individual	=	0;
	ROITS.cortext.Vertices			=	[20516 x 3 double];
	ROITS.cortext.Faces				=	[41136 x 3 double];
	ROITS.cortext.FaceVertexCData	=	[20516 x 3 double];
	[startepoch, endepoch]	=	deal(options.startepoch, options.endepoch);
	save( fullfile(srcDir, [SRCNAME '_eCon']), 'ROITS', '-v7.3');
%}
	toc

	clear eEEG eMRK ROIdata								% be clear for mem free
	delete(fullfile(srcDir, [FILENAME '_cplog' '.mat']));% cplog 제거
end		% for fold
end		% for sbj
end		% for cond
