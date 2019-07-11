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
	DstDir				=	fullfile(hEEG.PATH, hEEG.DstDir);	% log ���� ��ġ
	stdout				=	1;

	%POOL				=	S06paraOpen_AmH(false, 4);	% ������ core 4��
	%POOL				=	S_paraOpen(true);			% ������ restart
	POOL				=	S_paraOpen();

	% --------------------------------------------------
%for ixEP		=	1:EEG.epoch							% 2D �϶�, size()==1
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
	model.neighbors		=	load('neighbors.mat');		% �� ���ǵ� ��

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
	%% 20160707B. ����ȿ���� ���̷��� POOL.NumWorkers ���� ���� ���ຸ��
	% �� ����� �����ؾ� �������� ������带 �ּ�ȭ �� �����ٸ����� ������
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
	%%% 20160707A. parfor ���ο��� ����ü�� member ������ ����(���) �ϸ� lack!
	% ����, parfor ���ο��� �����ϴ� ��� ����ü member �� ���� ������ ����
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
	%% 20160706C. EEG.data �� ���� ���� index ��� -> ��� index ��� ��� ����!
	% StartTp �� ������� ���ÿ� ����, 1 Ȥ�� �� ū ���� �� �� �ִ�.
	% �׷���, ���� ����� ��� array �� index 1 ���� ���� ��Ƶ� �ȴ�.
	%% ����, loop �� ����Ǵ� �߰� �������� index �� 1 ���� ������ �� �ֵ���
	% EEG.data ���� ���� ����Ǵ� ������ �����Ͽ� �������.
	nROI				=	length(ROI.labels);
	WorkTp				=	StartTp;				% �۾����� epoch ����
	nTP					=	FinishTp -StartTp +1;	% ó���� �� tp ��
	% ���� cell ��� ������ ����(parfor ���ο��� data alloc �ϴ� ���� �ؼ�)
	% ���, ��ü ������ �� ���� ���� �� ó��, '1' �� ä��� ó���� �����Ϳ�
	% ���� �ȵ� ������ ������ ������ ������.
	% -> sparse matrix �� ����ϴ� ����� ���
%	SrcROI				=	cell(1, nTP);			% compute ROI time series
%	SrcROI				=	ones(nROI, nTP);		% compute ROI time series
%________________________________________________________________________________
	%% 20160320A. ��굵�� �����ھ� �� stall �Ǵ� core�� �۾� hold ���� ����
	%	����: �Ҹ�, �Ƹ��� 60000��(PFC_64)�� ���ϴ� epoch�� ó���ϴ� ����
	%		���� ������ resource deadlock �߻� ���ɼ� ����.
	%	����: ��������� �� 10% ���� checkpoint log ���
	%		���� ����� log ��Ͽ� ���� ������ ������ ������ load�Ͽ�
	%		�� �������� �簳(rollback) -> �Ź� ó������ �ٽý��� ���� ����
	if exist(fullfile(DstDir, [EEG.name '_cplog.mat']))% cplog����!
		fprintf('[Detect]   : checkpoint log data ! & analyzing...\n');
		load(fullfile(DstDir, [EEG.name '_cplog']));
		nCalcData		=	length(find(cellfun(@(x)(~isempty(x)), SrcROI)));
		
		% �о����� �����غ���.
		if strcmp(sFILE,EEG.name) & nROI == length(ROI.labels) &			...
			nTP == FinishTp -StartTp +1 & length(SrcROI) == nTP &			...
			nCalcData == WorkEnd
%			length(find(cellfun(@(x)(~isempty(x)), SrcROI))) == work-StartTp+1	
			WorkTp		=	WorkEnd + StartTp;			% rollback & restart ����
			fprintf('[Recovery] : Rollback & Redo from %d to %d epoch\n',	...
					StartTp, WorkTp-1);
		elseif nCalcData ==		...		% ó������ ���ӵ� data�� �������
			length(find(cellfun(@(x)(~isempty(x)), SrcROI(1:nCalcData))))
			WorkTp		=	nCalcData + StartTp;
			fprintf('[Recovery] : Rollback & Redo from %d to %d epoch\n',	...
					StartTp, WorkTp-1);
		else
			fprintf('[Sorry]    : inconsist current metadata, so NEW Start\n');
		end
		clear sFILE;
	end

	if ~exist('SrcROI', 'var'), SrcROI = cell(1,nTP); end	% log ���и� �ű�

%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	%% 20160706A. �������� cell �� ���� loop ��ü�� matrix ���� ��� ����
	%% version 3: �Ʒ� parfor�� (���� ���) 2�� loop ��� ����!
		ixRV			=	ROI.vertices;				% (n, 1) ����: col ����-[
		ixLen			=	cellfun(@length, ixRV)';	%% ���� ���� vector
		MX_RV			=	max(cellfun(@length, ixRV));
		ixRV			=	cellfun(@(x) {[x' zeros(1,MX_RV-length(x))]}, ixRV);
		ixRV			=	cell2mat(ixRV');			% col �迭ȭ�ؾ� ����ȯ
		ixZR			=	find(ixRV == 0);			% '0'��ġ Ȯ��(���� ��ó)
		ixRV(ixZR)		=	1;							% idx �Ƿ� �ּҰ��� 1

		%% model(������ ��)�� �ִ� neighbor�� index �� weight (��������)��
		% �����Ͽ� �������̷� ��ȯ���� -> matrix ������ ���� �����غ�
		% ���������̹Ƿ�, ���� �� �迭���� ���� tail part�� zero/one padding ����
		%
		% ��, model ���� �����ϴ� idx�� tikhonov()���� ȹ���� cortex source
		% ��ǥ���� ���� index �� ���ǹǷ�, 0 ���� index �� ���� �� �����Ƿ�
		% one padding�� �ؾ� �Ѵ�.
		%% �ݸ�, weight �� index �� �ƴϸ�, �ٷ� ����(matrix product)�� ����
		% �ǹǷ�, �� ������ ������, ������ ���Ե��� �ʵ��� 0 �� �����ؾ� ��.
		% ��, zero padding �ϸ� �ȴ�.
		%
		%% ����, �̷��� ���� index �� scalp �����Ϳ� ���� �������� fixed ��
		% �̹Ƿ�, ���� loop �ۿ��� �̸� ���صΰ� loop ���ο����� ��븸 ��!
		Weight			=	model.neighbors.neighbors.weight(ixRV);
		MXLEN			=	max(cellfun(@length, Weight(:)));	% only 1 max
		Weight			=	cellfun(@(x) {[x' zeros(1,MXLEN-length(x))]},Weight);
		Weight			=	cell2mat(Weight);			% ����! -> roi_ix*vxl
		Weight			=	reshape(Weight, nROI, MXLEN, MX_RV);% roi * ix * vxl
		Weight			=	permute(Weight, [ 1 3 2 ]);			% roi * vxl * ix
		Weight			=	reshape(Weight, [], MXLEN);			% roi_vxl * ix
		Weight(ixZR,:)	=	0;							% set to '0' by ixRV
		Weight			=	reshape(Weight, nROI, MX_RV, []); % roi * vxl * ix

		ixMdl			=	model.neighbors.neighbors.idx(ixRV); % �������� cell
		MXLEN			=	max(cellfun(@length, ixMdl(:)));
		ixMdl			=	cellfun(@(x) {[x'  ones(1,MXLEN-length(x))]}, ixMdl);
		ixMdl			=	cell2mat(ixMdl);			% roi*vxl*ix->roi_ix*vxl
		ixMdl			=	reshape(ixMdl, nROI, MXLEN, MX_RV);	% roi * ix * vxl
		ixMdl			=	permute(ixMdl, [ 1 3 2 ]);			% roi * vxl * ix
		% the end of common code (fixed/non-vary index)	%-]
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	%% 20160706B. �Ʒ� parfor �� for ���� ���� ���� �Ը�!
	% ���� ����: EEG.data �� ���ؼ� ���ÿ� ���� ���μ����� ���� �Կ� ����
	% ��ȣ���� ��� ���� overhead ��!
	% ����, �����͸� tp ������ ��� �ɰ��� cell �� ��������.
%		electrodesV		=	EEG.data(options.vidx, ix +WorkStart -1); % ch x tp
	% ��, ���� ��꿡 ���� �����͸� �����ؼ� ��������: ch x tp(*ep) -> tp{ch}
	cEEG				=	mat2cell(	EEG.data(:, StartTp:FinishTp),	...
										size(EEG.data,1), ones(1,nTP) );
%	cEEG				=	EEG.data(:, StartTp:FinishTp);
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	S_showStatus(0, 0, nTP, 0);							% init for progress
	AllPar				=	tic;
	NumWorkers			=	options.step;				% ����ȭ ���
%	for		ix	=	StartTp : FinishTp
%	parfor	ix	=	1 : nTP
	% WORKER ������ ���� ������ �����ؾ� �����Ȳ�� �ĺ��� �� ����
%	for		work		=	[StartTp	: NumWorkers	: FinishTp]
%	for		work		=	[WorkTp		: POOL.NumWorkers	: FinishTp]
%		WorkStart		=	work -StartTp +1;		% ix �� 1���� �����ϰ�!
%		WorkEnd			=	min(work+POOL.NumWorkers-1, FinishTp) -StartTp +1;
	for		work		=	[WorkTp		: NumWorkers	: FinishTp]
		WorkStart		=	work -StartTp +1;			% ix �� 1���� �����ϰ�!
		WorkEnd			=	min(work+NumWorkers-1, FinishTp) -StartTp +1;
		% �̰��, workend �� numworker�� ����� �ƴϸ�, ���� ���ڶ� �κ� ����

		% ���� ��� �ǵ� �� ���
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
%	parfor	ix			=	[1 : NumWorkers]		%% why? parfor << for �� ����
	parfor	ix			=	[WorkStart : WorkEnd]		%% parfor ���� ���� �ؼ�!
%	parfor	ix			=	[WorkTp : FinishTp]			%% parfor ���� ���� �ؼ�!
%		electrodesV		=	EEG.data(options.vidx, ix);
%		electrodesV		=	EEG.data(options.vidx, ix +StartTp -1); % ch x tp
%		electrodesV		=	EEG.data(options.vidx, ix +WorkStart -1); % ch x tp
		electrodesV		=	cEEG{ix}(o_vidx);			% tp series ���ο� ch����
%		electrodesV		=	cEEG(:, ix);				% tp series ���ο� ch����

		% compute map for sensor space
%		sensor.data(ix -StartTp +1)	=							...
%		sensordata(ix)	=	...
%			{ griddata(model.X, model.Y, electrodesV, model.XI, model.YI,'v4') };
		%% 20160315A. CAUTION: ix�� StartTp(~=1)�� ���� -> sensor �մ� ����ȭ
		% ����, ���� �����͸� ���� -> source.data �� ���ؼ��� ��������!!!

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
		% �ӽ� ���� cortexVI�� parfor�� �� �ݺ��� ���۵� �� �������ϴ�!
		cortexVI		=	[];	 % -[
		if isequal(o_method,'mn')
			cortexVI	=	tikhonov(U, s, V, electrodesV, lamda);
		elseif isequal(o_method, 'wmn')
			cortexVI	=	tikhonov(U, s, V, electrodesV, lamda);
			cortexVI	=	cortexVI ./ W';
		end
		if o_curry==1,cortexVI(length(cortexVI)+1 : o_cortexnumverts) = 0; end%-]

		%% ����������� source 20516 voxel �����ʹ� ��� ������ ����
		% ������ loop�� �� voxel ���� smooth ó������

		%% 20160318B. ������, ����� source (0.068073��) ����,
		%%						�ϱ��� smooth (0.266356��) �� �� ����!

		%% version 1: 2�� loop ��� scalp -> source ��ȯ -----------------------
		% get smooth values on finer colin cortex
		%% 20160318C. trying to ROI's voxel only rather than all voxel
		% ��, �ϱ��� loop�� �� voxel ���� �����ϴ� ���̹Ƿ�, ROI �� ���ؼ���
		% ����ϸ� �� �ӵ� ���� ����!
		%% get smooth values on finer colin cortex FOR [compute ROI time series]
%{
		roidata			=	zeros(nROI, 1);				%-[
		for	jx			=	1:nROI						% �� ROI �� ����
			ixRV		=	ROI.vertices{jx};

			ROIvts		=	zeros(length(ixRV), 1);
			for kx		=	1:length(ixRV)				% 1 ROI �����ϴ� �� voxel
				rx		=	ixRV(kx);
				values	=	cortexVI(model.neighbors.neighbors.idx{rx});%�迭����
				weight	=	model.neighbors.neighbors.weight{rx};

%				ROIvts(kx)	=	sum(weight .* values);	% sum() == scalar
				ROIvts(kx)	=	weight' * values;
			end
			%% 20160316A sum(weight .* values) ��Һ� �� & ��ü �� -> ��İ� ��ü
			% ���� ��� �������̰� ���� ����, ������� double �϶� �ٸ�!
			%	-> single �϶��� ����. ���κҸ�Ȯ
			roidata(jx)	=	mean(ROIvts);				% �� ROI ���� activity
		end	%-]
%}
		%% version 2: ����� 2�� loop �� ���� loop ���� ------------------------
		%% 20160705B. �������� cell �� ���� ���� loop ��ü�� matrix ����� ����
		%% model(������ ��)�� �ִ� neighbor�� index �� weight (��������)��
		% �����Ͽ� �������̷� ��ȯ���� -> matrix ������ ���� �����غ�
		% ���������̹Ƿ�, ���� �� �迭���� ���� tail part�� zero/one padding ����
		%
		% ��, model ���� �����ϴ� idx�� tikhonov()���� ȹ���� cortex source
		% ��ǥ���� ���� index �� ���ǹǷ�, 0 ���� index �� ���� �� �����Ƿ�
		% one padding�� �ؾ� �Ѵ�.
		%% �ݸ�, weight �� index �� �ƴϸ�, �ٷ� ����(matrix product)�� ����
		% �ǹǷ�, �� ������ ������, ������ ���Ե��� �ʵ��� 0 �� �����ؾ� ��.
		% ��, zero padding �ϸ� �ȴ�.
%{
		roidat2			=	zeros(nROI, 1);				%-[
		for	jx			=	1:nROI						% �� ROI �� ����
			ixRV		=	ROI.vertices{jx};

			Weight		=	model.neighbors.neighbors.weight(ixRV);
			MXLEN		=	max(cellfun(@length, Weight));
			Weight		=	cellfun(@(x) {[x' zeros(1,MXLEN-length(x))]},Weight);
			Weight		=	cell2mat(Weight');

			ixMdl		=	model.neighbors.neighbors.idx(ixRV); % �������� cell
			MXLEN		=	max(cellfun(@length, ixMdl));
			ixMdl		=	cellfun(@(x) {[x' ones(1,MXLEN-length(x))]}, ixMdl);
			ixMdl		=	cell2mat(ixMdl');			% col �迭ȭ�ؾ� ����ȯ

			Values		=	cortexVI(ixMdl);			% cortexVI�� idx�ش� ��

%			ROIvts		=	Weight' * Values;			% matrix ���� -> Ʋ����!
			ROIvts		=	sum(Weight .* Values, 2);	% vector ����

			roidat2(jx)	=	mean(ROIvts);				% �� ROI ���� activity
		end	%-]
%}
		%% version 3: ����� 2�� loop ��� ����! -------------------------------
		%% 20160706A. �������� cell �� ���� loop ��ü�� matrix ���� ��� ����
%{
		ixRV			=	ROI.vertices;				% (n, 1) ����: col ����-[
		ixLen			=	cellfun(@length, ixRV)';	%% ���� ���� vector
		MX_RV			=	max(cellfun(@length, ixRV));
		ixRV			=	cellfun(@(x) {[x' zeros(1,MX_RV-length(x))]}, ixRV);
		ixRV			=	cell2mat(ixRV');			% col �迭ȭ�ؾ� ����ȯ
		ixZR			=	find(ixRV == 0);			% '0'��ġ Ȯ��(���� ��ó)
		ixRV(ixZR)		=	1;							% idx �Ƿ� �ּҰ��� 1

		%% model(������ ��)�� �ִ� neighbor�� index �� weight (��������)��
		% �����Ͽ� �������̷� ��ȯ���� -> matrix ������ ���� �����غ�
		% ���������̹Ƿ�, ���� �� �迭���� ���� tail part�� zero/one padding ����
		%
		% ��, model ���� �����ϴ� idx�� tikhonov()���� ȹ���� cortex source
		% ��ǥ���� ���� index �� ���ǹǷ�, 0 ���� index �� ���� �� �����Ƿ�
		% one padding�� �ؾ� �Ѵ�.
		%% �ݸ�, weight �� index �� �ƴϸ�, �ٷ� ����(matrix product)�� ����
		% �ǹǷ�, �� ������ ������, ������ ���Ե��� �ʵ��� 0 �� �����ؾ� ��.
		% ��, zero padding �ϸ� �ȴ�.
		%
		%% ����, �̷��� ���� index �� scalp �����Ϳ� ���� �������� fixed ��
		% �̹Ƿ�, ���� loop �ۿ��� �̸� ���صΰ� loop ���ο����� ��븸 ��!
		Weight			=	model.neighbors.neighbors.weight(ixRV);
		MXLEN			=	max(cellfun(@length, Weight(:)));	% only 1 max
		Weight			=	cellfun(@(x) {[x' zeros(1,MXLEN-length(x))]},Weight);
		Weight			=	cell2mat(Weight);			% ����! -> roi_ix*vxl
		Weight			=	reshape(Weight, nROI, MXLEN, MX_RV);% roi * ix * vxl
		Weight			=	permute(Weight, [ 1 3 2 ]);			% roi * vxl * ix
		Weight			=	reshape(Weight, [], MXLEN);			% roi_vxl * ix
		Weight(ixZR,:)	=	0;							% set to '0' by ixRV
		Weight			=	reshape(Weight, nROI, MX_RV, []); % roi * vxl * ix

		ixMdl			=	model.neighbors.neighbors.idx(ixRV); % �������� cell
		MXLEN			=	max(cellfun(@length, ixMdl(:)));
		ixMdl			=	cellfun(@(x) {[x'  ones(1,MXLEN-length(x))]}, ixMdl);
		ixMdl			=	cell2mat(ixMdl);			% roi*vxl*ix->roi_ix*vxl
		ixMdl			=	reshape(ixMdl, nROI, MXLEN, MX_RV);	% roi * ix * vxl
		ixMdl			=	permute(ixMdl, [ 1 3 2 ]);			% roi * vxl * ix
		% the end of common code (fixed/non-vary index)	%-]
%}
		% ----------------------------------------------------------------------
		%% ���⼭�� �� ��(loop ��)���� �̸� ���ص� weight, ixmdl �� source data
		% �� ���� ��ٷ� ���븸 �ϸ� ��!!

		Values			=	cortexVI(ixMdl);			% cortexVI�� idx�ش� ��

		%%% ���� �����̹Ƿ�, ���� ���� ����(0��)���� ��� �Ǹ� �ȵ�!
%		ROIvts			=	sum(Weight .* Values, 3);	% reduce to roi * vxl
%		roidat3			=	sum(ROIvts, 2);				% reduce -> vector ȭ
%		roidat3			=	roidat3 ./ ixLen;			%% ���� ���̷� ���!
		roidata			=	sum(sum(Weight .* Values, 3), 2) ./ ixLen;	%% ���!

		%% ��� ����!
		SrcROI(ix)		=	{roidata};

%		fprintf('+ Localizing for [%05.3f%%] (%d / %d)\n',					...
%					ix / nTP *100, ix, nTP);
	end		% parfor
%________________________________________________________________________________
		%% 20160320A. �̽��� ���� ������ log ���� ���
		if nTP >= 1000 & mod( round(WorkEnd / nTP * 100, 2), hEEG.CPgap) == 0
		% epoch ���� 1000 �� �̻��� �� cp ��� ����: �Ҽ� 2�ڸ� ����: 5% Ȯ��
			if not(exist(DstDir, 'dir')), mkdir(DstDir); end	% ������ ����

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
	persistent pTime;								% ���۽ð�

	% pre process
	if nargin == 1 & ~isempty(mode)					% �ʱ� | ����
		if mode == 0,	Prgs	=	Total;		% finish
%		else, [Total Prgs Last pTime]=deal(mode,0,0,Par(mode)); Par.tic; % init
		else, [Total Prgs Last]	=	deal(mode,0,0); % init
		end

		Toc				=	0;
	elseif nargin < 1 | isempty(mode)				% progress
		Prgs			=	Prgs + 1;				% 1ȸ ȣ��ø��� 1���
		Toc				=	Toc.ItStop - Toc.ItStart;
	end

	% check display condition
	if		Prgs==0, S_showStatus(0); return;		% �ʱ� ȭ��
	elseif	(Prgs - Last) < Total / 1000, return;	% less 0.1% accumulation
	end

	% display progress bar to console
	Perc				=	Prgs / Total * 100		% calc percentage
	Last				=	Prgs					% update
%	timeElapsed			=	toc(fTime);		% get spended time
	timeElapsed			=	Toc					% get spended time
%	timeRemained		=	timeElapsed * (Total/Prgs-1);	% ���� �ð��̴ϱ� -1
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
	useJava				=	usejava('Desktop');				% matlab GUI ���==1

% <--------status message----------->_[<------progress bar----->]
% Wait for 001:28:36.7, completed 38% [========>                ]
% Wait for 01:28:36.7, completed [    23:    27]/212543= 38% [========>       ]

	% ȭ�� ��¿� ���� ����
	WaitMsg				=	'Wait for ';
	DoneMsg				=	', completed ';
	barMrk				=	'>';
	Format				=[	WaitMsg '%02d:%02d:%04.1f' DoneMsg	...	% hh:mm:ss.s
							CntrMsg '%3.0f%%'			...		% 4 char wide %
							' [%-' num2str(barWid) 's]'	];		% bar: ===>
	FormZero			=[	WaitMsg '--:--:--.-' DoneMsg	...	% hh:mm:ss.s
							CntrMsg '%3.0f%%'			...		% 4 char wide %
							' [%-' num2str(barWid) 's]'	];		% bar: ===>

	% ���� �ð��� �������.
	Perc				=	Fin / Total * 100;				% calc percentage
%	timeRemained		=	timeElapsed * (Total/Prgs-1);	% ���� �ð��̴ϱ� -1
	timeRem				=	timeElapsed * (100/Perc-1);% estimate the remain time

	% ������� ǥ���� bar ���̸� �������.
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
		%% ������ �𸣰�����, Matlab GUI ��忡���� '\b'�� 1�� �� ����� ��Ȯ
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
