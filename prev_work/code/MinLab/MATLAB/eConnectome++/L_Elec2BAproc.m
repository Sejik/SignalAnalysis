% DTFsigvalues - compute statistical significance values for relative DTF values
%
% Input:	ts - the time series where each column is the temporal data from a single trial.
%
% Output:	new_gamma2 - the significant points from the surrogate DTF analysis
%
% Description: This function generates surrogate datasets by phase shifting
%
% Program Author: Christopher Wilke, University of Minnesota, USA
%
% User feedback welcome: e-mail: econnect@umn.edu
%

% License
% ==============================================================
% This program is part of the eConnectome.
% 
% Copyright (C) 2010 Regents of the University of Minnesota. All rights reserved.
% Correspondence: binhe@umn.edu
% Web: econnectome.umn.edu
% ==========================================

% Revision Logs
% ==========================================
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ==========================================


function [SrcROI options] = L_Elec2BAproc(EEG,hEEG, ROI, StartPoint,FinishPoint)

	% Default sampling rate is 400 Hz
	if nargin < 2, error('parameter not enough'); end
	if nargin < 3, ROI			=	load(fullfile(hEEG.RoiDir,hEEG.RoiName)); end
	if nargin < 4, StartPoint	=	1; end
	if nargin < 5, FinishPoint	=	size(EEG.data,2); end

%	sForm				=	[ '%' num2str(length( num2str(EEG.points) )) 'd' ];
%	sForm				=	[ '%' num2str( floor(log10(EEG.points))+1 ) 'd' ];
%	sForm				=	S_form4len( EEG.points );
	DstDir				=	fullfile(hEEG.PATH, hEEG.DstDir);	% log 저장 위치
	stdout				=	1;

	%POOL				=	S06paraOpen_AmH(false, 4);	% 강제로 core 4개
	%POOL				=	S_paraOpen(true);			% 강제로 restart
	POOL				=	S_paraOpen();

	% --------------------------------------------------
%for ixEP		=	1:EEG.epoch							% 2D 일땐, size()==1
%	fprintf('\nCalculate DTF of epoch [%d/%d] on [Brodmann] level.\n',	...
%			ixEP, size(eEEG,3));

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
	model.neighbors		=	load('neighbors.mat');		% 기 정의된 값

	transmatrix			=	load('LargeTransMatrix.mat'); % large transfer matrix for colin BEM skin and cortex 
	k					=	cell2mat({EEG.locations(EEG.vidx).colinbemskinidx});
	model.transmatrix	=	double(transmatrix.TransMatrix(k,:)); % get transfer matrix for the electrodes
	[model.U, model.s, model.V]	=	csvd(model.transmatrix);
	[model.U, model.s, model.V]	=	deal(double(model.U), double(model.s),	...
										double(model.V));

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
	%% 20160707B. 병렬효과를 높이려면 POOL.NumWorkers 갯수 단위 수행보다
	% 그 배수로 구동해야 내부적인 오버헤드를 최소화 및 스케줄링으로 개선됨
%	options.step		=	round(EEG.points/100);		% '1%' step	%-[
	options.step		=	round((FinishPoint-StartPoint+1)/100);	% '1%' step
	if isfield(EEG, 'org_dims')
		options.step	=	max(EEG.org_dims(1), options.step); % tp step vs '1%'
	end
	if options.step <= 0, options.step=	2; end
	options.vidx		=	EEG.vidx;
	options.currentpoint=	1;
	options.auto		=	0;
	options.method		=	'mn';
	options.lamda		=	274.082947;
	options.autocorner	=	1;
	options.threshold	=	0.0;
	options.HWHM		=	3;
%	options.startepoch	=	156;						% startepoch;
%	options.endepoch	=	468;						% endepoch;
%	options.endepoch	=	156+10000;					% endepoch;
	options.startepoch	=	StartPoint;					% startepoch;
	options.endepoch	=	FinishPoint;				% endepoch;
	options.alpha		=	1;
	options.cutskin		=	0;
	options.labels		=	0;
	options.electrodes	=	0;
	options.sensorcaxis	=	'local';
	options.sensorminmax=	[EEG.min, EEG.max];
	options.sourcecaxis	=	'local';
	options.sourceminmax=	[realmax, realmin];
	options.usebem		=	0;
	options.currymatrix	=	0;						%-]

%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	%%% 20160707A. parfor 내부에서 구조체의 member 변수를 참조(사용) 하면 lack!
	% 따라서, parfor 내부에서 참조하는 모든 구조체 member 를 개별 변수로 추출
	[o_vidx o_lamda o_method o_curry] =	deal(options.vidx, options.lamda,	...
											options.method, options.currymatrix);
	if o_curry == 1, o_cortex = options.cortexnumverts; end

	if isequal(o_method, 'mn')
		[U s V W]		=	deal(model.U, model.s, model.V, 1);
	elseif isequal(o_method, 'wmn')
		[U s V W]		=	deal(model.U, model.s, model.V, model.W);
	end
	[StartTp, FinishTp]	=	deal(options.startepoch, options.endepoch);
	fprintf('Localizing epoch [%d:%d] on [Electrode] to [Brodmann] level.\n', ...
			StartTp, FinishTp);

	% --------------------------------------------------
	%% 20160706C. EEG.data 에 대한 절대 index 방식 -> 상대 index 방식 계산 변경!
	% StartTp 는 사용자의 선택에 의해, 1 혹은 더 큰 값이 될 수 있다.
	% 그런데, 최종 출력이 담긴 array 는 index 1 부터 값을 담아도 된다.
	%% 따라서, loop 에 적용되는 중간 변수들이 index 가 1 부터 시작할 수 있도록
	% EEG.data 에서 실제 적용되는 범위만 추출하여 사용하자.
	nROI				=	length(ROI.labels);
	WorkTp				=	StartTp;				% 작업시작 epoch 지점
	nTP					=	FinishTp -StartTp +1;	% 처리할 총 tp 수
	% 기존 cell 방식 저장을 지양(parfor 내부에서 data alloc 하는 문제 해소)
	% 대신, 전체 데이터 블럭 사전 생성 후 처리, '1' 로 채우면 처리된 데이터와
	% 아직 안된 데이터 영역의 구분이 용이함.
	% -> sparse matrix 를 사용하는 방법도 고려
%	SrcROI				=	cell(1, nTP);			% compute ROI time series
%	SrcROI				=	ones(nROI, nTP);		% compute ROI time series
%________________________________________________________________________________
	%% 20160320A. 계산도중 병렬코어 중 stall 되는 core로 작업 hold 상태 유발
	%	원인: 불명, 아마도 60000개(PFC_64)에 달하는 epoch을 처리하는 과정
	%		에서 모종의 resource deadlock 발생 가능성 추측.
	%	대응: 수행과정의 매 10% 마다 checkpoint log 기록
	%		새로 실행시 log 기록에 의해 마지막 수행기록 시점을 load하여
	%		그 시점부터 재개(rollback) -> 매번 처음부터 다시시작 문제 대응
	if exist(fullfile(DstDir, [EEG.name '_cplog.mat']))% cplog존재!
		fprintf('[Detect]   : checkpoint log data ! & analyzing...\n');
		load(fullfile(DstDir, [EEG.name '_cplog']));
		nCalcData		=	length(find(cellfun(@(x)(~isempty(x)), SrcROI)));
		
		% 읽었으면 조사해보자.
		if strcmp(sFILE,EEG.name) & nROI == length(ROI.labels) &			...
			nTP == FinishTp -StartTp +1 & length(SrcROI) == nTP &			...
			nCalcData == WorkEnd
%			length(find(cellfun(@(x)(~isempty(x)), SrcROI))) == work-StartTp+1	
			WorkTp		=	WorkEnd + StartTp;			% rollback & restart 시점
			fprintf('[Recovery] : Rollback & Redo from %d to %d epoch\n',	...
					StartTp, WorkTp-1);
		elseif nCalcData ==		...		% 처음부터 연속된 data면 살려보자
			length(find(cellfun(@(x)(~isempty(x)), SrcROI(1:nCalcData))))
			WorkTp		=	nCalcData + StartTp;
			fprintf('[Recovery] : Rollback & Redo from %d to %d epoch\n',	...
					StartTp, WorkTp-1);
		else
			fprintf('[Sorry]    : inconsist current metadata, so NEW Start\n');
		end
		clear sFILE;
	end

	if ~exist('SrcROI', 'var'), SrcROI = cell(1,nTP); end	% log 실패면 신규

%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	%% 20160706A. 가변길이 cell 에 대한 loop 대체용 matrix 연산 방법 개발
	%% version 3: 아래 parfor의 (기존 방식) 2중 loop 모두 제거!
		ixRV			=	ROI.vertices;				% (n, 1) 구조: col 방향-[
		ixLen			=	cellfun(@length, ixRV)';	%% 개별 길이 vector
		MX_RV			=	max(cellfun(@length, ixRV));
		ixRV			=	cellfun(@(x) {[x' zeros(1,MX_RV-length(x))]}, ixRV);
		ixRV			=	cell2mat(ixRV');			% col 배열화해야 정상변환
		ixZR			=	find(ixRV == 0);			% '0'위치 확보(나중 조처)
		ixRV(ixZR)		=	1;							% idx 므로 최소값은 1

		%% model(기정의 값)에 있는 neighbor의 index 와 weight (가변길이)를
		% 추출하여 고정길이로 변환하자 -> matrix 연산을 위한 사전준비
		% 가변길이이므로, 가장 긴 배열길이 맞춰 tail part는 zero/one padding 하자
		%
		% 단, model 에서 추출하는 idx는 tikhonov()에서 획득한 cortex source
		% 좌표값에 대한 index 로 사용되므로, 0 값이 index 로 쓰일 수 없으므로
		% one padding을 해야 한다.
		%% 반면, weight 는 index 가 아니며, 바로 연산(matrix product)에 적용
		% 되므로, 각 성분의 곱셈시, 값으로 포함되지 않도록 0 을 설정해야 함.
		% 즉, zero padding 하면 된다.
		%
		%% 또한, 이렇게 구한 index 는 scalp 데이터에 대해 독립적인 fixed 값
		% 이므로, 연산 loop 밖에서 미리 구해두고 loop 내부에서는 사용만 함!
		Weight			=	model.neighbors.neighbors.weight(ixRV);
		MXLEN			=	max(cellfun(@length, Weight(:)));	% only 1 max
		Weight			=	cellfun(@(x) {[x' zeros(1,MXLEN-length(x))]},Weight);
		Weight			=	cell2mat(Weight);			% 주의! -> roi_ix*vxl
		Weight			=	reshape(Weight, nROI, MXLEN, MX_RV);% roi * ix * vxl
		Weight			=	permute(Weight, [ 1 3 2 ]);			% roi * vxl * ix
		Weight			=	reshape(Weight, [], MXLEN);			% roi_vxl * ix
		Weight(ixZR,:)	=	0;							% set to '0' by ixRV
		Weight			=	reshape(Weight, nROI, MX_RV, []); % roi * vxl * ix

		ixMdl			=	model.neighbors.neighbors.idx(ixRV); % 가변길이 cell
		MXLEN			=	max(cellfun(@length, ixMdl(:)));
		ixMdl			=	cellfun(@(x) {[x'  ones(1,MXLEN-length(x))]}, ixMdl);
		ixMdl			=	cell2mat(ixMdl);			% roi*vxl*ix->roi_ix*vxl
		ixMdl			=	reshape(ixMdl, nROI, MXLEN, MX_RV);	% roi * ix * vxl
		ixMdl			=	permute(ixMdl, [ 1 3 2 ]);			% roi * vxl * ix
		% the end of common code (fixed/non-vary index)	%-]
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	%% 20160706B. 아래 parfor 가 for 보다 느린 이유 규명!
	% 단일 변수: EEG.data 에 대해서 동시에 여러 프로세스가 접근 함에 따른
	% 상호배제 제어에 의한 overhead 임!
	% 따라서, 데이터를 tp 단위로 모두 쪼개어 cell 에 저장하자.
%		electrodesV		=	EEG.data(options.vidx, ix +WorkStart -1); % ch x tp
	% 단, 실제 계산에 사용될 데이터만 추출해서 적용하자: ch x tp(*ep) -> tp{ch}
	cEEG				=	mat2cell(	EEG.data(:, StartTp:FinishTp),	...
										size(EEG.data,1), ones(1,nTP) );
%	cEEG				=	EEG.data(:, StartTp:FinishTp);
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	S_showStatus(0, 0, nTP, 0);							% init for progress
	AllPar				=	tic;
	NumWorkers			=	options.step;				% 병렬화 배수
%	for		ix	=	StartTp : FinishTp
%	parfor	ix	=	1 : nTP
	% WORKER 단위로 블럭을 나눠서 수행해야 진행상황을 식별할 수 있음
%	for		work		=	[StartTp	: NumWorkers	: FinishTp]
%	for		work		=	[WorkTp		: POOL.NumWorkers	: FinishTp]
%		WorkStart		=	work -StartTp +1;		% ix 가 1부터 시작하게!
%		WorkEnd			=	min(work+POOL.NumWorkers-1, FinishTp) -StartTp +1;
	for		work		=	[WorkTp		: NumWorkers	: FinishTp]
		WorkStart		=	work -StartTp +1;			% ix 가 1부터 시작하게!
		WorkEnd			=	min(work+NumWorkers-1, FinishTp) -StartTp +1;
		% 이경우, workend 가 numworker의 배수가 아니면, 끝에 모자란 부분 감안

		% 진행 경과 판독 및 출력
%%		fprintf(stdout,	['+ %s : COMPUTE Localizing for [' sForm ':' sForm ']'...
%%			' / %d = %6.3f%%\r'], char(hEEG.Inlier{hEEG.CurixSJ}{1}),		...
%%				WorkStart, WorkEnd, nTP, WorkEnd/nTP*100);
		S_showStatus(WorkStart, WorkEnd, nTP, toc(AllPar));

	%	%-[
	% EXAMPLE: 
	%           targetCount = 100;
	%           barWidth= targetCount/2;
	%           p = TimedProgressBar( targetCount, barWidth, ...
	%                                 'Computing, please wait for ', ...
	%                                 ', already completed ', ...
	%                                 'Concluded in ' );
	%           parfor i=1:targetCount
	%              pause(rand);     % Replace with real code
	%              p.progress;      % Also percent = p.progress;
	%           end
	%           p.stop;             % Also percent = p.stop;
	%
	% To get percentage numbers from progress and stop methods call them like:
	%       percent = p.progress;
	%       percent = p.stop;
	%
	% console print:
	% <--------status message----------->_[<------progress bar----->]
	% Wait for 001:28:36.7, completed 38% [========>                ]	%-]
%	parfor	ix			=	[1 : NumWorkers]		%% why? parfor << for 더 빠름
	parfor	ix			=	[WorkStart : WorkEnd]		%% parfor 느린 이유 해소!
%	parfor	ix			=	[WorkTp : FinishTp]			%% parfor 느린 이유 해소!
%		electrodesV		=	EEG.data(options.vidx, ix);
%		electrodesV		=	EEG.data(options.vidx, ix +StartTp -1); % ch x tp
%		electrodesV		=	EEG.data(options.vidx, ix +WorkStart -1); % ch x tp
		electrodesV		=	cEEG{ix}(o_vidx);			% tp series 내부에 ch묶음
%		electrodesV		=	cEEG(:, ix);				% tp series 내부에 ch묶음

		% compute map for sensor space
%		sensor.data(ix -StartTp +1)	=							...
%		sensordata(ix)	=	...
%			{ griddata(model.X, model.Y, electrodesV, model.XI, model.YI,'v4') };
		%% 20160315A. CAUTION: ix가 StartTp(~=1)서 시작 -> sensor 앞단 공백화
		% 따라서, 실제 데이터만 저장 -> source.data 에 대해서도 마찬가지!!!

		% compute sources on cortex
		% tigoum's think: For makeing dedicated proc, merge several functions
		%%case 1: [autocorner]: l_curve's lambda -> tikhonov== l_curve_tikhonov
		% case 2: [non auto]  : options.lambda -> tikhonov  == tikhonov
		if options.autocorner		%-[
			% 20160320A. l_curve() performance is depended by figure env!
			% time delay without	figure open : about 5.65 sec
			% time delay WITH		figure open : about 0.13 sec
			% performance ratio is awesome 43.4615 times!
%			tempfg		=	figure;						% IMPORTANT for speed!
%			lamda		=	l_curve(model.U,model.s,electrodesV,'tikh');
%			close(tempfg);
%%			lamda		=	l_curve2(model.U,model.s,electrodesV, 'tikh');
			lamda		=	l_curve2(U, s, electrodesV, 'tikh');
		else
%%			lamda		=	options.lamda;
			lamda		=	o_lamda;
		end		%-]

		%% compute sources on cortex
		% 임시 변수 cortexVI는 parfor의 각 반복이 시작될 때 지워집니다!
		cortexVI		=	[];	 % -[
		if isequal(o_method,'mn')
			cortexVI	=	tikhonov(U, s, V, electrodesV, lamda);
		elseif isequal(o_method, 'wmn')
			cortexVI	=	tikhonov(U, s, V, electrodesV, lamda);
			cortexVI	=	cortexVI ./ W';
		end
		if o_curry==1,cortexVI(length(cortexVI)+1 : o_cortexnumverts) = 0; end%-]

		%% 현재시점에서 source 20516 voxel 데이터는 모두 구해진 상태
		% 이하의 loop는 각 voxel 별로 smooth 처리수행

		%% 20160318B. 조사결과, 상기의 source (0.068073초) 보다,
		%%						하기의 smooth (0.266356초) 가 더 느림!

		%% version 1: 2중 loop 기반 scalp -> source 변환 -----------------------
		% get smooth values on finer colin cortex
		%% 20160318C. trying to ROI's voxel only rather than all voxel
		% 즉, 하기의 loop는 각 voxel 별로 연산하는 것이므로, ROI 에 대해서만
		% 계산하면 더 속도 개선 가능!
		%% get smooth values on finer colin cortex FOR [compute ROI time series]
%{
		roidata			=	zeros(nROI, 1);				%-[
		for	jx			=	1:nROI						% 각 ROI 별 수행
			ixRV		=	ROI.vertices{jx};

			ROIvts		=	zeros(length(ixRV), 1);
			for kx		=	1:length(ixRV)				% 1 ROI 구성하는 각 voxel
				rx		=	ixRV(kx);
				values	=	cortexVI(model.neighbors.neighbors.idx{rx});%배열리턴
				weight	=	model.neighbors.neighbors.weight{rx};

%				ROIvts(kx)	=	sum(weight .* values);	% sum() == scalar
				ROIvts(kx)	=	weight' * values;
			end
			%% 20160316A sum(weight .* values) 요소별 곱 & 전체 합 -> 행렬곱 대체
			% 조사 결과 성능차이가 거의 없고, 결과값이 double 일때 다름!
			%	-> single 일때는 같음. 원인불명확
			roidata(jx)	=	mean(ROIvts);				% 각 ROI 수준 activity
		end	%-]
%}
		%% version 2: 상기의 2중 loop 중 내부 loop 제거 ------------------------
		%% 20160705B. 가변길이 cell 에 대한 내부 loop 대체용 matrix 연산법 개발
		%% model(기정의 값)에 있는 neighbor의 index 와 weight (가변길이)를
		% 추출하여 고정길이로 변환하자 -> matrix 연산을 위한 사전준비
		% 가변길이이므로, 가장 긴 배열길이 맞춰 tail part는 zero/one padding 하자
		%
		% 단, model 에서 추출하는 idx는 tikhonov()에서 획득한 cortex source
		% 좌표값에 대한 index 로 사용되므로, 0 값이 index 로 쓰일 수 없으므로
		% one padding을 해야 한다.
		%% 반면, weight 는 index 가 아니며, 바로 연산(matrix product)에 적용
		% 되므로, 각 성분의 곱셈시, 값으로 포함되지 않도록 0 을 설정해야 함.
		% 즉, zero padding 하면 된다.
%{
		roidat2			=	zeros(nROI, 1);				%-[
		for	jx			=	1:nROI						% 각 ROI 별 수행
			ixRV		=	ROI.vertices{jx};

			Weight		=	model.neighbors.neighbors.weight(ixRV);
			MXLEN		=	max(cellfun(@length, Weight));
			Weight		=	cellfun(@(x) {[x' zeros(1,MXLEN-length(x))]},Weight);
			Weight		=	cell2mat(Weight');

			ixMdl		=	model.neighbors.neighbors.idx(ixRV); % 가변길이 cell
			MXLEN		=	max(cellfun(@length, ixMdl));
			ixMdl		=	cellfun(@(x) {[x' ones(1,MXLEN-length(x))]}, ixMdl);
			ixMdl		=	cell2mat(ixMdl');			% col 배열화해야 정상변환

			Values		=	cortexVI(ixMdl);			% cortexVI서 idx해당 값

%			ROIvts		=	Weight' * Values;			% matrix 생성 -> 틀렸음!
			ROIvts		=	sum(Weight .* Values, 2);	% vector 생성

			roidat2(jx)	=	mean(ROIvts);				% 각 ROI 수준 activity
		end	%-]
%}
		%% version 3: 상기의 2중 loop 모두 제거! -------------------------------
		%% 20160706A. 가변길이 cell 에 대한 loop 대체용 matrix 연산 방법 개발
%{
		ixRV			=	ROI.vertices;				% (n, 1) 구조: col 방향-[
		ixLen			=	cellfun(@length, ixRV)';	%% 개별 길이 vector
		MX_RV			=	max(cellfun(@length, ixRV));
		ixRV			=	cellfun(@(x) {[x' zeros(1,MX_RV-length(x))]}, ixRV);
		ixRV			=	cell2mat(ixRV');			% col 배열화해야 정상변환
		ixZR			=	find(ixRV == 0);			% '0'위치 확보(나중 조처)
		ixRV(ixZR)		=	1;							% idx 므로 최소값은 1

		%% model(기정의 값)에 있는 neighbor의 index 와 weight (가변길이)를
		% 추출하여 고정길이로 변환하자 -> matrix 연산을 위한 사전준비
		% 가변길이이므로, 가장 긴 배열길이 맞춰 tail part는 zero/one padding 하자
		%
		% 단, model 에서 추출하는 idx는 tikhonov()에서 획득한 cortex source
		% 좌표값에 대한 index 로 사용되므로, 0 값이 index 로 쓰일 수 없으므로
		% one padding을 해야 한다.
		%% 반면, weight 는 index 가 아니며, 바로 연산(matrix product)에 적용
		% 되므로, 각 성분의 곱셈시, 값으로 포함되지 않도록 0 을 설정해야 함.
		% 즉, zero padding 하면 된다.
		%
		%% 또한, 이렇게 구한 index 는 scalp 데이터에 대해 독립적인 fixed 값
		% 이므로, 연산 loop 밖에서 미리 구해두고 loop 내부에서는 사용만 함!
		Weight			=	model.neighbors.neighbors.weight(ixRV);
		MXLEN			=	max(cellfun(@length, Weight(:)));	% only 1 max
		Weight			=	cellfun(@(x) {[x' zeros(1,MXLEN-length(x))]},Weight);
		Weight			=	cell2mat(Weight);			% 주의! -> roi_ix*vxl
		Weight			=	reshape(Weight, nROI, MXLEN, MX_RV);% roi * ix * vxl
		Weight			=	permute(Weight, [ 1 3 2 ]);			% roi * vxl * ix
		Weight			=	reshape(Weight, [], MXLEN);			% roi_vxl * ix
		Weight(ixZR,:)	=	0;							% set to '0' by ixRV
		Weight			=	reshape(Weight, nROI, MX_RV, []); % roi * vxl * ix

		ixMdl			=	model.neighbors.neighbors.idx(ixRV); % 가변길이 cell
		MXLEN			=	max(cellfun(@length, ixMdl(:)));
		ixMdl			=	cellfun(@(x) {[x'  ones(1,MXLEN-length(x))]}, ixMdl);
		ixMdl			=	cell2mat(ixMdl);			% roi*vxl*ix->roi_ix*vxl
		ixMdl			=	reshape(ixMdl, nROI, MXLEN, MX_RV);	% roi * ix * vxl
		ixMdl			=	permute(ixMdl, [ 1 3 2 ]);			% roi * vxl * ix
		% the end of common code (fixed/non-vary index)	%-]
%}
		% ----------------------------------------------------------------------
		%% 여기서는 저 위(loop 밖)에서 미리 구해둔 weight, ixmdl 을 source data
		% 에 대해 곧바로 적용만 하면 됨!!

		Values			=	cortexVI(ixMdl);			% cortexVI서 idx해당 값

		%%% 가변 갯수이므로, 원래 없던 성분(0값)까지 계수 되면 안됨!
%		ROIvts			=	sum(Weight .* Values, 3);	% reduce to roi * vxl
%		roidat3			=	sum(ROIvts, 2);				% reduce -> vector 화
%		roidat3			=	roidat3 ./ ixLen;			%% 개별 길이로 계산!
		roidata			=	sum(sum(Weight .* Values, 3), 2) ./ ixLen;	%% 계산!

		%% 계산 저장!
		SrcROI(ix)		=	{roidata};

%		fprintf('+ Localizing for [%05.3f%%] (%d / %d)\n',					...
%					ix / nTP *100, ix, nTP);
	end		% parfor
%________________________________________________________________________________
		%% 20160320A. 이슈에 의해 구성된 log 저장 기능
		if nTP >= 1000 & mod( round(WorkEnd / nTP * 100, 2), hEEG.CPgap) == 0
		% epoch 수가 1000 개 이상일 때 cp 기능 수행: 소수 2자리 버림: 5% 확정
			if not(exist(DstDir, 'dir')), mkdir(DstDir); end	% 없으면 생성

			sFILE		=	EEG.name;
			save(fullfile(DstDir, [EEG.name '_cplog']),'sFILE', ...
				'nROI', 'nTP', 'WorkStart', 'WorkEnd', 'SrcROI');
			clear sFILE
		end

%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	end		% for work

%	options.sourceminmax(1)	=	min( cellfun(@(x)( min(x(:)) ), sourcedata) );
%	options.sourceminmax(2)	=	max( cellfun(@(x)( max(x(:)) ), sourcedata) );

%end	% ixEP
end	% function
%{
function [] = S_TimedProgressBar( mode, Toc )	%number==init, 0==fin, empty=progress
	persistent Total;
	persistent Prgs;
	persistent Last;
	persistent pTime;								% 시작시간

	% pre process
	if nargin == 1 & ~isempty(mode)					% 초기 | 종료
		if mode == 0,	Prgs	=	Total;		% finish
%		else, [Total Prgs Last pTime]=deal(mode,0,0,Par(mode)); Par.tic; % init
		else, [Total Prgs Last]	=	deal(mode,0,0); % init
		end

		Toc				=	0;
	elseif nargin < 1 | isempty(mode)				% progress
		Prgs			=	Prgs + 1;				% 1회 호출시마다 1계수
		Toc				=	Toc.ItStop - Toc.ItStart;
	end

	% check display condition
	if		Prgs==0, S_showStatus(0); return;		% 초기 화면
	elseif	(Prgs - Last) < Total / 1000, return;	% less 0.1% accumulation
	end

	% display progress bar to console
	Perc				=	Prgs / Total * 100		% calc percentage
	Last				=	Prgs					% update
%	timeElapsed			=	toc(fTime);		% get spended time
	timeElapsed			=	Toc					% get spended time
%	timeRemained		=	timeElapsed * (Total/Prgs-1);	% 남은 시간이니까 -1
	timeRemained		=	timeElapsed * (100/Perc-1);% estimate the remain time

	S_showStatus(Perc, timeRemained);

end	% function
%}
function [] = S_showStatus(Go, Fin, Total, timeElapsed, barWid, barMrk)

	persistent	LastLength;

	if nargin < 3, error('Parameter not enough'); end
	sForm				=	S_form4len( Total );
	CntrMsg				=	['[' sForm ':' sForm ']/' sForm '='];% [go:fin]/tot=
	CntrMsg				=	sprintf(CntrMsg, Go,Fin,Total);		% gen string

	if nargin < 4, timeElapsed	= 0; end
	if nargin < 5, barMrk		= '>'; end
	if nargin < 6, barWid		= 42-length(CntrMsg); end

	stdout				=	1;
	useJava				=	usejava('Desktop');				% matlab GUI 모드==1

% <--------status message----------->_[<------progress bar----->]
% Wait for 001:28:36.7, completed 38% [========>                ]
% Wait for 01:28:36.7, completed [    23:    27]/212543= 38% [========>       ]

	% 화면 출력용 형식 구성
	WaitMsg				=	'Wait for ';
	DoneMsg				=	', completed ';
	barMrk				=	'>';
	Format				=[	WaitMsg '%02d:%02d:%04.1f' DoneMsg	...	% hh:mm:ss.s
							CntrMsg '%3.0f%%'			...		% 4 char wide %
							' [%-' num2str(barWid) 's]'	];		% bar: ===>
	FormZero			=[	WaitMsg '--:--:--.-' DoneMsg	...	% hh:mm:ss.s
							CntrMsg '%3.0f%%'			...		% 4 char wide %
							' [%-' num2str(barWid) 's]'	];		% bar: ===>

	% 남은 시간을 계산하자.
	Perc				=	Fin / Total * 100;				% calc percentage
%	timeRemained		=	timeElapsed * (Total/Prgs-1);	% 남은 시간이니까 -1
	timeRem				=	timeElapsed * (100/Perc-1);% estimate the remain time

	% 진행과정 표기할 bar 길이를 계산하자.
	x					=	round( Perc * barWid / 100 );
	if x < barWid,	bar	=	[ repmat( '=', 1, x ), barMrk ];
	else,			bar	=	[ repmat( '=', 1, x ) ]; end

	if Perc == 0 & timeElapsed == 0
		statusLine		=	sprintf( FormZero, Perc, bar );
	else
		hh				=	fix( timeRem / 3600 );
		mm				=	fix( ( timeRem - hh * 3600 ) / 60 );
%		ss				=	max( ( timeRem - hh * 3600 - mm * 60 ), 0.1 );
		ss				=	fix( ( timeRem - hh * 3600 - mm * 60 ) );
		statusLine		=	sprintf( Format, hh,mm,ss, Perc, bar );
	end

	if Perc > 0 && Perc < 100
		%% 이유는 모르겠으나, Matlab GUI 모드에서는 '\b'을 1개 더 해줘야 정확
		cursorRewinder	=	repmat( char(8), [1], [useJava+LastLength] );
		disp( [ cursorRewinder, statusLine ] );
	elseif Perc == 100
		cursorRewinder	=	repmat( char(8), [1], [useJava+LastLength] );
		disp( [ cursorRewinder, statusLine ] );
	else    % Perc == 0
		disp( [ statusLine ] );
	end
	LastLength			=	length( statusLine );

end	% function
