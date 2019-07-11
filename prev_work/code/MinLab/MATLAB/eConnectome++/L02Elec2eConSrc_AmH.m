%%function [ DurationTime ]	=	L02Elec2eConSrc_AmH( hEeg )
%% minlab scalp mat -> eConnectome -> source level mat
% designed by Sejik Park, edited by tigoum
clearvars -except BBCI BTB hEeg
close all
%clc

%% set important variable !!!	-> EEG 데이터의 전 구간을 계산하는 방식으로 변경!
%StartTp	=	100; % 1;
%FinishTp	=	200; % EEG.points;

%% set variable
%basePATH	=	'/home/minlab/Tools/MATLAB/eConnectome++/';
%eEEGDir		=	[ basePATH 'eEEG' ];			% eEEG(minlab) 데이터
%rawDir		=	[ basePATH 'RAW' ];				% ERP(minlab) -> eCon 변환된 raw
%sourceDir	=	[ basePATH 'SRC' ];				% 연산 결과 저장 공간
sPRJ		=	'PFC_64';
dataPATH	=	[ '/home/minlab/Projects/' sPRJ '/PFC_3/' ];
eEEGDir		=	[ dataPATH 'eEEG' ];			% eEEG 데이터
srcDir		=	[ dataPATH 'sEEG' ];
if not(exist(srcDir, 'dir')), mkdir(srcDir); end

%% initialize
condition	=	{ '' };	%'TopDown', 'Intermediate', 'BottomUp' };
%sbj_format	=	'PFC_64_su%04d_%s.mat';
sbj_format	=	'PFC_64_%s_%s';
sbj_list	=	[ 1 : 20 ];
fold_list	=	[ 1:7 ];
CPgap		=	5;								% CP 기록 기준: 매 5% 마다

POOL				=	S06paraOpen_AmH(true);		% 강제로 restart
%{
NUMWORKERS	=	POOL.NumWorkers;
tic;
delete(gcp('nocreate'));
myCluster	=	parcluster('local');	% 신규 profile 작성
myCluster.NumWorkers=	NUMWORKERS;				%'Modified' property now TRUE
saveProfile(myCluster);							% 'local' profile now updated
POOL		=	parpool('local', NUMWORKERS);	% 최대 48 core 고려.
fprintf('\nPooling : the parpool worker''s setup completed. '); toc;
%}
%% main
for ixCD	=	condition
for ixSJ	=	sbj_list
for ixFL	=	fold_list
	tic;

	fprintf('\n--------------------------------------------------\n');
%	FILENAME			=	sprintf(sbj_format, char(ixSJ), [char(ixCD), '_BA']);
	FILENAME			=	[sPRJ	'_' sprintf('su%04d', char(ixSJ))		...
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
	fprintf('construct model for BEM / transfer eeg data to BEM matrix.\n'); % -[

	% basic varible
	model.italyskin		=	load('italyskin.mat');
	model.cutskin		=	load('cutskin.mat');
	model.italyskinxy	=	load('italyskin-in-xy.mat');
	model.italyskinxyz	=	load('italyskin-in-xyz.mat');
	model.colinbemskin	=	load('colinbemskin.mat');
	model.cortex		=	load('colincortex.mat');
	model.bemcortex		=	load('colinbemcortex.mat');
	model.neighbors		=	load('neighbors.mat');

	transmatrix			=	load('LargeTransMatrix.mat');
			% large transfer matrix for colin BEM skin and cortex 
	k					=	cell2mat({EEG.locations(EEG.vidx).colinbemskinidx});
	model.transmatrix	=	transmatrix.TransMatrix(k,:);
			% get transfer matrix for the electrodes
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
	model.YI			=	model.italyskinxy.xy(model.interpk,2);	%-]
	%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	options.step		=	round(EEG.points/10);		% -[
	if options.step <= 0, options.step=	2; end
	options.vidx		=	EEG.vidx;
	options.currentpoint=	1;
	options.auto		=	0;
	options.method		=	'mn';
	options.lamda		=	0;
	options.autocorner	=	1;
	options.threshold	=	0.0;
	options.HWHM		=	3;
	options.StartTp		=	1;							% StartTp;
	options.FinishTp	=	EEG.points;					% FinishTp;
	options.alpha		=	1;
	options.cutskin		=	0;
	options.labels		=	0;
	options.electrodes	=	0;
	options.sensorcaxis	=	'local';
	options.sensorminmax=	[EEG.min, EEG.max];
	options.sourcecaxis	=	'local';
	options.sourceminmax=	[realmax, realmin];
	options.usebem		=	0;
	options.currymatrix	=	0;		% -]

	% --------------------------------------------------
	[StartTp, FinishTp]	=	deal(options.StartTp, options.FinishTp);
	fprintf('Localizing epoch [%d:%d] on [Electrode] to [Source] level.\n',	...
			StartTp, FinishTp);

	WorkTp				=	StartTp;				% 작업시작 epoch 지점
	nTP					=	FinishTp -StartTp +1;
	sourcedata			=	cell(1, nTp);			% compute SRC time series
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
		nCalcData		=	length(find(cellfun(@(x)(~isempty(x)), sourcedata)));

		% 읽었으면 조사해보자.
		if strcmp(sFILE,FILENAME) &											...
			nTP == FinishTp -StartTp +1 & length(sourcedata) == nTP &		...
			length(find(cellfun(@(x)(~isempty(x)), sourcedata))) == WorkEnd
%			length(find(cellfun(@(x)(~isempty(x)), ROIdata))) == work-StartTp+1	
			WorkTp		=	WorkEnd + StartTp;			% rollback & restart 시점
			fprintf('[Recovery] : Rollback & Redo from %d to %d epoch\n',	...
					StartTp, WorkTp);
		elseif nCalcData ==		...		% 처음부터 연속된 data면 살려보자
			length(find(cellfun(@(x)(~isempty(x)), sourcedata(1:nCalcData))))
			WorkTp		=	nCalcData + StartTp;
			fprintf('[Recovery] : Rollback & Redo from %d to %d epoch\n',	...
					StartTp, WorkTp);
		else
			fprintf('[Sorry]    : inconsist current metadata, so NEW Start\n');
		end
		clear sFILE;
	end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	% WORKER 단위로 블럭을 나눠서 수행해야 진행상황을 식별할 수 있음
%	for		work		=	[StartTp	: POOL.NumWorkers	: FinishTp]
	for		work		=	[WorkTp		: POOL.NumWorkers	: FinishTp]
		WorkStart		=	work -StartTp +1;		% ix 가 1부터 시작하게!
		WorkEnd			=	min(work+POOL.NumWorkers-1, FinishTp) -StartTp +1;
		% 이경우, workend 가 numworker의 배수가 아니면, 끝에 모자란 부분 감안

		% 진행 경과 판독 및 출력
		fprintf(stdout,	['+ %s : COMPUTE Localizing for [' sForm ':' sForm ']'...
	' / %d = %6.3f%%\r'],	FILENAME, WorkStart, WorkEnd, nTP, WorkEnd/nTP*100);


	parfor	ix			=	[WorkStart : WorkEnd]

		electrodesV		=	EEG.data(options.vidx, ix +StartTp -1);

		% compute map for sensor space
%		sensordata(ix)	=	...
%			{ griddata(model.X, model.Y, electrodesV, model.XI, model.YI,'v4') };
		%% 20160315A. CAUTION: ix가 StartTp(~=1)서 시작 -> sensor 앞단 공백화
		% 따라서, 실제 데이터만 저장 -> source.data 에 대해서도 마찬가지!!!

		% compute parameter for sources on cortex
		if options.autocorner		%-[
			% 20160320A. l_curve() performance is depended by figure env!
			% time delay without	figure open : about 5.65 sec
			% time delay WITH		figure open : about 0.13 sec
			% performance ratio is awesome 43.4615 times!
			tempfg		=	figure;						% IMPORTANT for speed!
			lamda		=	l_curve(model.U,model.s,electrodesV,'tikh');
			close(tempfg);
%			if single(options.lamda) ~= single(lamda)
%				fprintf('\nERROR : lamda(%f) vs org(%f)\n', lamda,options.lamda);
%			end
		else
			lamda		=	options.lamda;
		end		%-]

		%% compute sources on cortex
		cortexVI		=	[];	% -[
		if isequal(options.method,'mn')
			cortexVI	=	tikhonov(model.U,model.s,model.V,electrodesV,lamda);
		elseif isequal(options.method,'wmn')
			cortexVI	=	tikhonov(model.U,model.s,model.V,electrodesV,lamda);
			cortexVI	=	cortexVI ./ model.W';
		end
		if options.currymatrix == 1
			cortexVI(length(cortexVI)+1:options.cortexnumverts)	=	0;
		end	%-]
		%% 현재시점에서 source 20516 voxel 데이터는 모두 구해진 상태
		% 이하의 loop는 각 voxel 별로 smooth 처리수행

		%% 20160318B. 조사결과, 상기의 source (0.068073초) 보다,
		%%						하기의 smooth (0.266356초) 가 더 느림!

		% get smooth values on finer colin cortex
		len				=	length(model.neighbors.neighbors.idx);	%-[
		cortexV			=	zeros(len, 1);
		for	jx			=	1:len
			values		=	cortexVI(model.neighbors.neighbors.idx{jx});
			weight		=	model.neighbors.neighbors.weight{jx};
%			cortexV(jx,:)=	sum(weight .* values);
			cortexV(jx)	=	sum(weight .* values);		% sum() == scalar
		end
		%% 성능 개선을 위해, matrix 구조화가 요망

		sourcedata(ix)	=	{cortexV};
		%% 20160315A. CAUTION: ix가 StartTp(~=1)서 시작->source앞단 공백화%-]

%		fprintf('+ Localizing for [%05.3f%%] (%d / %d)\n',					...
%					ix / nTp *100, ix, nTp);
	end		% for parfor (tp)
%________________________________________________________________________________
		%% 20160320A. 이슈에 의해 구성된 log 저장 기능
		if nTP >= 10000 & mod( round(WorkEnd / nTP * 100, 1), CPgap) == 0
		% epoch 수가 10000 개 이상일 때 cp 기능 수행: 소수 2자리 버림: 5% 확정
			sFILE		=	FILENAME;
			save(fullfile(srcDir, [FILENAME '_cplog']), 'sFILE',			...
				'nTP', 'WorkStart', 'WorkEnd', 'sourcedata');
			clear sFILE
		end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	end		% for work

	options.sourceminmax(1)	=	min( cellfun(@(x)( min(x(:)) ), sourcedata) );
	options.sourceminmax(2)	=	max( cellfun(@(x)( max(x(:)) ), sourcedata) );

%% 주어진 epoch 구간에서 20516 voxel / 1 epoch 계산 완료!

	srate				=	EEG.srate;

	fprintf('\nStoring data for %s ', FILENAME);
	save(FILEPATH,	'sourcedata', 'startepoch', 'endepoch', 'srate', '-v7.3');

	toc

	clear sourcedata									% be clear for mem free
	delete(fullfile(srcDir, [FILENAME '_cplog' '.mat']));% cplog 제거
end		% for fold
end		% for sbj
end		% for cond

