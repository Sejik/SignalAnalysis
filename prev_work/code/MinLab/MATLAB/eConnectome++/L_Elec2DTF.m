% L_Elec2DTF ver 0.2
%% [scalp/electrode ���ؿ��� source localization �� DTF ������ batch mode ����]
%
% [*Input Parameter]--------------------------------------------------
% Param_Script: �Ķ���� ������ ���Ե� script
%
% [*Output Parameter]--------------------------------------------------
% Duration: ����ð�
%
% ex) L_Elec2DTF( l_Elec2DTF_SSVEP_NEW )
%
%------------------------------------------------------
% first created at 2016/03/23
% last  updated at 2016/07/04
% by Ahn Min-Hee::tigoum@naver.com, Korea Univ. MinLAB.
%.....................................................
% ver 0.10 : 20160323. scalp -> source localization �ܰ���� �ۼ���
% ver 0.20 : 20160704. scalp -> source -> DTF ���� �Ϸ�. �ӵ�����(�ּ�5��)
%------------------------------------------------------

function [ DurationTime ]	=	L_Elec2DTF( A_global_AmH )
%% minlab scalp mat -> eConnectome -> BA level mat
% designed by Sejik Park, edited by tigoum
clearvars -except BBCI BTB A_global_AmH
close all
%clc

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%%�ֿ� ������ WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@@
%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%POOL		=	S06paraOpen_AmH(false, 4);			% ������ core 4��
%POOL		=	S_paraOpen(true);					% ������ restart
%POOL		=	S_paraOpen();
NumWorkers	=	20;

hEEG		=	A_global_AmH();						% param�� fnx ptr

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Total		=	tic;								%��ü ���� �ð�

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%% set important variable !!!	-> EEG �������� �� ������ ����ϴ� ������� ����!
load(fullfile(hEEG.RoiDir, hEEG.RoiName));
%{
%% ��ü ROI ������ �� -> BA10L, R �� Ȯ���Ѵ�.
ix			=	cellfun(@(x)( strcmp(x, 'BA10L') | strcmp(x, 'BA10R') ), labels);
labels		=	labels(ix);
centers		=	centers(ix,:);						% 2D
vertices	=	vertices(ix);
%}

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%% main
for ixCD	=	hEEG.Cond							% condition ���� ȹ��
	hEEG.CurCond		=	char(ixCD);				% ���� ���� ��� for �۾�

for ixSJ	=	1:length(hEEG.Inlier)
	tic;

	hEEG.CurixSJ		=	ixSJ;					% index for current sbj
	[ EEG hEEG ]		=	S_MATreader( hEEG );	% ���� sbj file ���
	if isempty(EEG),	continue; end				% skip this subject

	fprintf('\n--------------------------------------------------\n');
	fprintf('\n-Read & merge the input file----------------------\n');

%	sForm				=	[ '%' num2str(length( num2str(EEG.points) )) 'd' ];
%	sForm				=	[ '%' num2str( floor(log10(EEG.points))+1 ) 'd' ];
	sForm				=	S_form4len( EEG.points );
	DstDir				=	fullfile(hEEG.PATH, hEEG.DstDir);	% ���� ��ġ
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

	WorkTp				=	StartTp;				% �۾����� epoch ����
	nROI				=	length(labels);
	nTP					=	FinishTp -StartTp +1;
	SrcROI				=	cell(1, nTP);			% compute ROI time series
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
		if strcmp(sFILE,EEG.name) & nROI == length(labels) &				...
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
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

%	for		ix	=	StartTp : FinishTp
%	parfor	ix	=	1 : nTP
	% WORKER ������ ���� ������ �����ؾ� �����Ȳ�� �ĺ��� �� ����
%	for		work		=	[StartTp	: NumWorkers	: FinishTp]
	for		work		=	[WorkTp		: NumWorkers	: FinishTp]
		WorkStart		=	work -StartTp +1;		% ix �� 1���� �����ϰ�!
		WorkEnd			=	min(work+NumWorkers-1, FinishTp) -StartTp +1;
		% �̰��, workend �� numworker�� ����� �ƴϸ�, ���� ���ڶ� �κ� ����

		% ���� ��� �ǵ� �� ���
		fprintf(stdout,	['+ %s : COMPUTE Localizing for [' sForm ':' sForm ']'...
			' / %d = %6.3f%%\r'], char(hEEG.Inlier{ixSJ}{1}),				...
				WorkStart, WorkEnd, nTP, WorkEnd/nTP*100);

	for	ix			=	[WorkStart : WorkEnd]	%% why? parfor << for �� ����
%		electrodesV		=	EEG.data(options.vidx, ix);
		electrodesV		=	EEG.data(options.vidx, ix +StartTp -1); % ch x tp

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
		%
		if options.autocorner		%-[
			% 20160320A. l_curve() performance is depended by figure env!
			% time delay without	figure open : about 5.65 sec
			% time delay WITH		figure open : about 0.13 sec
			% performance ratio is awesome 43.4615 times!
%			tempfg		=	figure;						% IMPORTANT for speed!
%			lamda		=	l_curve(model.U,model.s,electrodesV,'tikh');
%			close(tempfg);
			lamda		=	l_curve2(model.U,model.s,electrodesV, 'tikh');
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
		end	% -]
		%% ����������� source 20516 voxel �����ʹ� ��� ������ ����
		% ������ loop�� �� voxel ���� smooth ó������

		%% 20160318B. ������, ����� source (0.068073��) ����,
		%%						�ϱ��� smooth (0.266356��) �� �� ����!

		% get smooth values on finer colin cortex
		%% 20160318C. trying to ROI's voxel only rather than all voxel
		% ��, �ϱ��� loop�� �� voxel ���� �����ϴ� ���̹Ƿ�, ROI �� ���ؼ���
		% ����ϸ� �� �ӵ� ���� ����!
		%% get smooth values on finer colin cortex FOR [compute ROI time series]
		roidata			=	zeros(nROI, 1);
		for	jx			=	1:nROI						% �� ROI �� ����
			ixRV		=	vertices{jx};

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
		end
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

	%% SL activity(voxel) -> BA activity(ROI) complete: currently, we needs!
	% BA activity ��� �Ϸ� ����. �̰��� �����ؼ� ����ϸ� ��

	% ---------------------------------------------------------------------------
	% re structuring ROI data to eEEG style : BA x tp(BA) -> tp x BA x ep
	% ����ϱ� ������, 2Dȭ�Ǿ� �ִ� ROI ����� eEEG ������� ����
	%	����, EEG.org_dims field�� ������ ��쿡 ���缭 �籸�� �� ����

%	eMRK				=	labels;
	%% 20160323A. �ߴ� ���� �߰�: marker�� �ݵ�� eEEG�� original�� �� ��!!!
	% ���� ����ó�� labels(==ROI name)�� ���� prediction�� �ƹ��� �ǹ̰� ����!
	% ��, ��� epoch ���� ������ ������ marker �� �־����� ���� �Ǳ� ����!
	%% �ݵ�� ���� ����������� ������ marker�� �״�� ����ؾ� ��Ȯ�� ���� ��
	if ~isfield(EEG, 'marker'), fprintf('Warning : MUST BE needs the marker');
	else,	eMRK		=	EEG.marker; end

	eCHN				=	labels;
	[eFS, srate]		=	deal(EEG.srate);

	eEEG				=	cell2mat(SrcROI);			% BA x tp
	if isfield(EEG, 'org_dims')
		dims			=	EEG.org_dims;				% tp x ch x ep
		if isfield(EEG, 'org_permute') & EEG.org_permute% ������ 3D �� ���
			dims		=	[dims(2) dims(1) dims(3)];	% ch x tp x ep
		end
		eEEG			=	reshape(eEEG, [], [dims(2)], [dims(3)]);
														% BA x tp -> BA x tp x ep
%		if EEG.org_permute, eEEG = permute(eEEG,[2 1 3]); end %BA*tp*ep->tp*BA*ep
%		eEEG			=	permute(eEEG, [2 1 3]);		% tp*BA*ep->BA*tp*ep
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
%	SRCTSS{ep}			=	SRCTS;

	% eConnectome ȯ�濡�� ������ ���ؼ�, �ش� �������ε� ���
	% ���翡 ���ϸ�, ROI time serise window ������ ������ ���� ROI time
	% �����͸� import �� �� �ִ� ����� ����!
	% ����, ��� ���� ���ǹ�
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
	ROITS.labels		=	labels;			% array for ROITS ( from ROI.mat )
	ROITS.centers		=	centers;		% array for ROITS ( from ROI.mat )
	ROITS.vertices		=	vertices;		% array for ROITS ( from ROI.mat )
	ROITS.srate			=	EEG.srate;					% sampling rate
	ROITS.data			=	cell2mat(SrcROI);
	ROITS.individual	=	0;
	ROITS.cortext.Vertices			=	[];	%[20516 x 3 double];
	ROITS.cortext.Faces				=	[];	%[41136 x 3 double];
	ROITS.cortext.FaceVertexCData	=	[];	%[20516 x 3 double];
%	save(fullfile(hEEG.PATH,hEEG.DstDir,[EEG.name '_ROITS.mat']),'ROITS');
%	ROITSS{ep}			=	ROITS;

%	fprintf('\nStoring data for %s ', EEG.name);
%	save(FILEPATH, 'eEEG', 'eMRK', 'eCHN', 'eFS', '-v7.3');

%	clear eEEG eMRK SrcROI								% be clear for mem free
%%	delete(fullfile(hEEG.Dst, [EEG.name '_cplog' '.mat']));% cplog ����

	% --------------------------------------------------
	fprintf('\nMigration to DTF calculation for %s.', EEG.name);
POOL		=	S_paraOpen();

%	load(fullfile(hEEG.Src, EEG.name));					% eEEG : tp x BA x ep
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
%	eEEG				=	permute(eEEG, [2 1 3]);		% tp*BA*ep->BA*tp*ep
%	eEEG				=	reshape(eEEG, size(eEEG,1), []);	% 2D
	%% eEEG dims : BA * tp * ep
	for ep = 1:size(eEEG, 3)							% 2D �϶�, size()==1
		fprintf('\nCalculate DTF of epoch [%d/%d] on [Brodmann] level.\n',	...
				ep,size(eEEG,3));

	% �� �������� voxel ������ ���� source ���� BA ������ ���(�� ���)
	%% -> �׷���, �ռ� ����� eEEG �� �̹� BA ������ ���� ���̹Ƿ� ���⼱ ����
	%% �׷���, ���⼭�� �ٷ� roidata �� ���� ���� ���� ����
	roidata				=	squeeze(eEEG(:,:,ep));		% BA x tp

	% setting info to TS
	TS.data				=	roidata;
	TS.srate			=	srate;
	[TS.nbchan TS.points]	=	size(TS.data);

	startpoint			=	1;
	endpoint			=	TS.points;

%	output				=	dtf_computation(TS, startpoint, endpoint,		...
%								dtflowfedit, dtfhighfedit, srate, optimalorder);
	% output.dtfmatrixs : BA x BA x freq
	output				=	dtf_computation(TS, startpoint, endpoint,		...
								hEEG.FreqWindow(1), hEEG.FreqWindow(2));
	% output.dtfmatrixs : BA x BA x freq

%	dtfmatrixs = output.dtfmatrixs;
%	dtfmatrixs = mean(dtfmatrixs,3);
%	dtfmatrixs(:,:,:,ep)	=	output.dtfmatrixs;
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
%	DTF.matrix			=	dtfmatrixs;					% 4D : BA x BA x fq x ep
	DTF.matrix			=	output.dtfmatrixs;			% 3D : BA x BA x fq
%	DTF.dims			=	{ 'channel', 'channel', 'frequency' };
	DTF.labels			=	eCHN;
	DTF.locations		=	centers;		% array for ROITS ( from ROI.mat )
	DTF.frequency		=	hEEG.FreqWindow;	%[dtflowfedit dtfhighfedit];
	DTF.type			=	'ROI';
	DTF.isadtf			=	0;
	DTF.srate			=	srate;
	DTF.vertices		=	vertices;
%	save(FILEPATH, 'DTF', '-v7.3');

	DTFS{ep}			=	DTF;
	end	% for ix = ep


	fprintf('\n');
%	S_DTFwriter(hEEG, DTFS, ROITS, SRCTS);				% ���� ����غ���
	S_DTFwriter(hEEG, DTFS, [], []);					% ���� ����غ���

	delete(fullfile(hEEG.PATH,hEEG.DstDir,[EEG.name '_cplog.mat'])); toc % ����
	fprintf('\nComplete: %s''s processing :: ',char(hEEG.Inlier{ixSJ}{1}) );
	fprintf('\n==================================================\n');
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
%		lSBJ	: individual (�� ��) �� electrode data file ���
%
%	output:
%		EEG		: structure
%		hEEGo	: ������ hEEG
%			+ (�ʼ�) OutName : ���ο��� (�Է� �̸� �ľ� ��) ���� ������ ���path
%			+ (�ʼ�) eMRK	: marker
%
function [ EEG hEEGo ] = S_MATreader( hEEG, lSBJ )	% ���� sbj file ���

	EEG				=	[];								% �ʱ�ȭ
	hEEGo			=	hEEG;							% return ���

	sCond			=	hEEG.CurCond;					% condition ���� ȹ��
	% ���ſ� ���ڿ��� ��� 4���� ���ɼ��� �ִ�.
	% ~					:	�׳� �� ���ڸ� �����ϸ� ��
	% head~REMOVE~other	:	~ ���� ~ ������ REMOVE�ش� string�� ������
	% ~REMOVE			:	~ ������ ��� string ����
	% head~REMOVE		:	~ ������ ��� string ����
	ssCond			=	regexprep(sCond,'\s*~[^~]*~\s*','');		%'~'��������
	ssCond			=	regexprep(ssCond,'\s*~\s*[^~]*$','');		%'~'��������
	sExt			=	hEEG.ExtName;

	%% 1�� �ܰ�: �Է������� ��ϵ��� hEEG.Inlier ����Ʈ���� �����Ѵ�
%	PrjName			=	strsplit(hEEG.PATH, '/');				% ������Ʈ �̸���
%	PrjName			=	char(PrjName(end-1));					% except Method
	% 1. Inlier ����� ��Ұ� cell ���̸� ��ü ���ϸ��� �����Ͽ� �迭�� ���
	% 2. �ƴϸ� �׳� �� ���ϸ��� ���
	%
	% 3. dest(result) ������ ���縦 ����
	% 4. src ���ϵ�(1,2���� ����� ���ϵ� ���)�� ���縦 ����
	%
	% 5. Inlier ����� ��Ұ� cell ���̸� �����ؾ� �ϴ� ������
	% 5-1. ��� �� 2��°~�� �׸��� ��� load�ؼ� �ϳ��� ����
	% 5-2. ù��° �̸����� WORKNAME ����
	% 6. �ƴϸ� �׳� �� �̸����� WORKNAME ����
	lSBJ			=	hEEG.Inlier{hEEG.CurixSJ};
	lSRCNAME		=	{};	% must be init!:�ƴϸ� �Ʒ� skip�� �ٸ����� ȥ�տ���!
	if iscell(lSBJ) && length(lSBJ)>=3
		% ���� ���ϵ��� ���ս��Ѿ� �Ѵ�. ���� �̸��� ó���� ��
		% �̶� ��Ұ����� �ּ� 3�� -> sub1(����), sub1_1(src), sub1_2(src)
		for s		=	2 : length(lSBJ)				% 1:���� �̸�, 2:cut ����
			WORKNAME=[	char(lSBJ{s}) hEEG.Common '_' sCond	];
%			lSRCNAME{s-1}=[	hEEG.PATH hEEG.Src	WORKNAME sExt	]; %�迭
			lSRCNAME{s-1}=fullfile(hEEG.PATH,[hEEG.Src WORKNAME sExt]);%�迭
		end
		% �������� file���� ������
		WORKNAME	=[	char(lSBJ{1}) '_' ssCond	];

	elseif iscell(lSBJ) && length(lSBJ)<=2
		% ��� ������ 2����, ����=�ҽ� �̹Ƿ�, �׳� ���� ����ó�� ó�� ����
		WORKNAME	=[	char(lSBJ{2}) hEEG.Common '_' sCond	];
%		lSRCNAME{1}	=[	hEEG.PATH hEEG.Src	WORKNAME sExt	];%only 1
		lSRCNAME{1}	=fullfile(hEEG.PATH,[hEEG.Src WORKNAME sExt]);%only 1

		% �������� file���� ������
		WORKNAME	=[	char(lSBJ{1}) '_' ssCond	];

	else	%���� ���ϸ��� ���
		WORKNAME	=[	char(lSBJ) hEEG.Common '_' sCond	];
%		lSRCNAME{1}	=[	hEEG.PATH hEEG.Src	WORKNAME sExt	];%only 1
		lSRCNAME{1}	=fullfile(hEEG.PATH,[hEEG.Src WORKNAME sExt]);%only 1
	end

	%% 2�� �ܰ�, ������ �Է� ��Ͽ� ����, Fold ����� �߰��Ͽ�, Ȯ�� �����Ѵ�.
	if length(lSRCNAME) == 1 & isfield(hEEG, 'lFolds')	% 1�� �϶��� foldó������
		[PT NM EX]	=	fileparts(lSRCNAME{1});
		lSRCNAME	=	{};
	for ixFL		=	hEEG.lFolds
		lSRCNAME{end+1}=	fullfile(PT, [NM '_' num2str(ixFL) EX]);
	end
	end

	% ���� ��� ���ϸ� ����
%		OUT_NAME	=[	hEEG.PATH hEEG.Dst	WORKNAME '.mat' ];
		WORKNAME	=	regexprep(WORKNAME, '[_]+$', '');		% '_' �� ����
%		OUT_NAME	=[	hEEG.PATH hEEG.Dst	WORKNAME '_1.mat' ];
%		OUT_NAME	=	fullfile(hEEG.PATH,[hEEG.Dst WORKNAME '_1.mat']);
%		hEEG.FileInfo.OutFile	=	OUT_NAME;
		OUT_NAME	=	fullfile(hEEG.PATH, [hEEG.Dst WORKNAME '_']);
		OUT_NAME	=	regexprep(OUT_NAME, hEEG.OutRemv, ''); % filter
		if	~hEEG.fgSplitSession & ~hEEG.fgSplitEpoch			% single���� case
			OUT_NAME=	regexprep(OUT_NAME, '[_]+$', '');		% �� '_' ����
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
	[DIR, OUT, Ext]	=	fileparts(OUT_NAME);			% ������� ���� Ȯ�ο�
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

	else												% Retain/Rework ���Ҽ�
		fprintf('exist! & SKIP analyzing this\n');
		return;											% skip
	end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%	AllTime			=	tic;		%������ preparing �ð��� �����Ѵ�.
	fprintf('--------------------------------------------------\n');
	fprintf('Convert : %s''s DAT to RAW for [ %s ]\n', WORKNAME,			...
			[ regexprep(OUT_NAME, '.*(su[0-9]{4}.*)$', '$1') '*' Ext ]);
	%'\n'���ϴ� ������ �Ʒ��� toc ����� ���� �پ���� �Ϸ���.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% merging ���: ���� SubjInfo.Inlier �� �� cell�� �ټ� ���� subj 
%	�̸��� ��� �ִٸ�, �̵��� ������� �о, �ϳ��� �����ͷ� ��ħ
%	epoch �������� concatenate �ؾ� ��.
%	eMRK			=	{;};							% empty 2D array
	eMRK			=	[];								% empty 2D array
	eEEG			=	[;;];							% empty 3D array
	for s			= 1 : length(lSRCNAME)				% �ݵ�� cell array ��!
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

		%% �ش� subject �� ���� data �� loading �Ѵ�
		if strcmp(hEEG.ExtName, '.dat')
%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% Convert: DAT -> eEEG...mat
% -------------------------------------------------------------------------------
		ChanLive	=	hEEG.Chan(hEEG.ixLive);			% only live
		ixLive		=	hEEG.ixLive;
		ixRemv		=	hEEG.ixRemv;

		[eCHN,SDP,eFS,Orient]	=	S_importVHDR(SRC_NAME);
%		eCHN		=	upper(eCHN);
		MxCh		=	length(eCHN);					% eCHN : ä�� ���
		hEEG.SmplRate=	eFS;

		% cell array�� ���� �� (ex: ch 	== label) �� �� �����Ƿ� ���� ����ȭ
%		incorrect	=	find( cellfun(@strcmp, hEEG.Chan, eCHN) == 0 );
		incorrect	=	find( ~ismember(ChanLive, eCHN) );
		if length(incorrect) > 0						% Ʋ�� index �� ����
			fprintf('Warning : mismatch channels b/w script & VHDR\n');
		for err 	= 1 : length(incorrect)
			idx		=	incorrect(err);
			fprintf('  + #%03d: %s <-> %s\n', idx, ChanLive{idx}, eCHN{idx});
		end
			fprintf('Replace : using VHDR(%d) rather than script(%d)\n',	...
					MxCh, length(ChanLive));
			ChanInfo.All=	eCHN;
			ixLive	=	find(~ismember(eCHN, hEEG.ChRemv) ); %����
			ixRemv	=	find( ismember(eCHN, hEEG.ChRemv) ); %����
		end

		% -----	������ ������ ����, ��Ŀ ���̰� �ٸ� �� �����Ƿ�, ������ ���
		nMRK		=	3;								% maximum len is 3
		VMRK		=	{;};
		while isempty(VMRK) & nMRK > 0
			[ VMRK ]=	S_importVMRK(SRC_NAME, nMRK);% load a marker
			nMRK	=	nMRK - 1;						%% change len of marker
		end
		VMRK		=	VMRK{1};							% only marker ����

		% --------------------------------------------------
%		eval(['BAdat		=	importdata(''' SRC_NAME ''');']);


		%% pop_matreader ���� *.dat format �� loading �ϵ��� �����ؾ� ��.
		%	-> pop_matreader �� vidx, StdLocation �� source ��ȯ�� �ʿ���
		%		������ ��������� �ϱ� ����.
		%% ������ �ð��������� ó�� ����!
		BAdat		=	importdata( SRC_NAME );
		%*.dat ������ ù �ٿ� ����� ä�� ������ Ȯ���� ���ƾ� ��!
		if ~isstruct(BAdat),	BAdat	=	struct('data', BAdat); end

%		B			=	BAdat.data;
%		B			=	shiftdim(B, 1);
%		eBLK		=	reshape(B, 1000, [], 32);
%		eBLK		=	reshape(BAdat.data, 1000, [], 32);
%%		eBLK		=	reshape(BAdat.data, SDP, [], MxCh); %% time * ep * ch

		%% 20151117A. BA�� export �ɼǿ� ����, import *.dat reshape ���� �߰�
		% Wavelet�� ����� �� ������ Ÿ���� �׻� (timepoint x epochs x channels)
		% ���� �� ��! ������, ��쿡 ����, Brain Analyzer�� export�κ���
		% ���� �ٸ� ������ dat format �� load �� �� ����.
		% DataOrientation=MULTIPLEXED: �� ��� [data point seriese] x [ch] ����
		% DataOrientation=VECTORIZED : �� ��� [ch] x [data point seriese] ����
		% ����, orientation �� ���� �ٸ� ó�� ������ ����, �������� eEEG ����
		% Ȯ���� �����ؾ� ��.
		% eEEG ����: timepoint x epoch x ch
%%		if		strcmp(Orient,'VECTORIZED') &&	size(BAdat.data,1)==MxCh
%%			eBLK	=	reshape(BAdat.data, MxCh, SDP, []);	%% ch * time * ep
%%			eBLK	=	shiftdim(eBLK, 1);				% tm x ep x ch

%%		elseif	strcmp(Orient,'MULTIPLEXED') &&	size(BAdat.data,2)==MxCh
			eBLK	=	reshape(BAdat.data, SDP, [], MxCh);	%% time * ep * ch

			% 20160430A.simulating for confused data as VECTORIZED->MULTIPLEXED
%			eBLK	=	shiftdim(eBLK, 2);				% ch * time * ep
%			eBLK	=	reshape(eBLK, SDP, [], MxCh);	% time * ep * ch
%%		end

%		clear B BAdat
		clear BAdat

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		elseif strcmp(hEEG.ExtName, '.mat')			% eEEG ��� mat ����
		[DIR, OUT]	=	fileparts(SRC_NAME);		% ������� ���� Ȯ�ο�
%		EEG			=	load( SRC_NAME );			% ���� data -> EEG struct
		EEG			=	pop_matreader(OUT, fullfile(DIR), hEEG.Chan);	% read
%		clear EEG

		% EEG.data�� 3D ����(���� ����)�� �纯�� �Ѵ�: �μ����� �۾� ����
		% ����: ch x tp(x ep) -> ch x tp x ep
		if isfield(EEG, 'marker')					% ch x tp -> ch x tp x ep
			[eBLK VMRK]=deal(EEG.data, EEG.marker);	% ����
			eBLK	=	reshape(eBLK, EEG.nbchan, [], [length(EEG.marker)]);
		else
			[eBLK VMRK]=deal(EEG.data, []);			% ����
			eBLK	=	reshape(eBLK, EEG.nbchan, [], [1]);
		end
			eBLK	=	permute(eBLK, [ 2 3 1 ]);	% -> tp x ep x ch
		end

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%		eBLK(:,:,17)=	NaN;	% EOG
%		eBLK(:,:,22)=	NaN;	% NULL
%		eBLK(:,:,find(ismember(eCHN,'EOG')) )	=	0;	% EOG

%%		save([hEEG.PATH '/skk_data/skk_' SRC_NAME], 'eBLK');	% eBLK array ����

		nMRK		=	size(VMRK, 1);
%		eMRK(end+1:end+nMRK,:)	=	VMRK;			% horzcat or vertcat
		eMRK(end+1:end+nMRK)	=	VMRK;			% horzcat or vertcat

		%% ���� eEEG (*.mat) �� 3D ������ ����,
		% pop_matreader() �� ���� ������ EEG.data�� 2D ��ȯ �� �����̰�,
		% �׷���, 2��° ������ tp x ep �� 1D �� sequence �ϰ� ������ ������.
		% �̰͵��� �Ʒ��� ���� concatenate �ϸ�, 2��° ���� �� append ��
		% �׽�Ʈ ���, �� ����� ���� reshape�ϸ� ����3D�� epoch�� ����
		% concatenate �� �Ͱ� ������!
		s1EEG		=	strjoin(arrayfun(@num2str, size(eEEG), 'unif', 0), '*');
		eEEG		=	[ eEEG eBLK ];				% horzcat or vertcat
		seBLK		=	strjoin(arrayfun(@num2str, size(eBLK), 'unif', 0), '*');
		s2EEG		=	strjoin(arrayfun(@num2str, size(eEEG), 'unif', 0), '*');
		if s > 1 && length(eEEG) > 0				% 2��° ������ merging ��
			fprintf(['Merging : eEEG(%s:%s) = eEEG(%s) + Part(%s:%s) '		...
					'based EPOCHs.\n'], WORKNAME,s2EEG, s1EEG, SRC_NAME,seBLK);
		end

		clear eBLK, VMRK;
	end;
	%% ----------
	if isempty(eEEG), return; end					% data ������ ���� subj��!
	%% ----------

%% ------------------------------------------------------------------------------
%% 20150517B. eEEG �����Ϳ� ���� �⺻���� ó��/���� ����� �ʿ���.	%-[
	%��, �����Ͱ� �ƴ� ����ä���� �����ؾ� �Ѵ�.
	% ch17= EOG, ch22=NULL, ���� �κ� ����. �ڿ��� ���� ������ ����� ó����.
	% -> 20150517C. ���� �� ������ ��������. �տ������� ������� ���� ����

	tic; fprintf('\nFinding : & remove a dummy channels on eEEG array.\n');
	%% it must be consider to hEEG.ixLive with EEG.vidx index!
%	hEEG.ixLive		=	find(~ismember(EEG.labels,hEEG.ChRemv) );%����ִ� ä�θ�
%	hEEG.ixRemv		=	find( ismember(EEG.labels,hEEG.ChRemv) );%�׾��ִ� ä�θ�

	% eCHN ������ live ä�θ� ���� �α�� �Ѵ�.
%	eEEG([ hEEG.ixRemv ],:,:)	=	[];				% remove ä�� ����
%	EEG.labels		=	EEG.labels([ hEEG.ixLive ]);% live �� ����
%	EEG.nbchan		=	length(EEG.labels);			% update

	%eEEG ������ �� NaN �� ���� ������, �ش� ���� ���� ä�ΰ��� �񱳿���
	%�Ź� ������ ���� �����ϸ�, ���ʿ��� ������ ������ �� ����.
	%����, �� ���� ���� ä���� �ִٸ�, Notify �ؾ� ��!!
	%eEEG �Ը� ������ �� ���, �ð��� �ҿ� �� ���� ������ ������ ��.
	fprintf('Search  : a NaN value on eEEG array\n');
%	[ rNaN cNaN ]	=	find(isnan(eEEG));			% 2D �������� ��ġ ã��
%	Linear			=	sub2ind(size(eEEG), rNaN, cNaN);	% eEEG 1D�� index
	Linear			=	find(isnan(eEEG(:)));		% 1D �������� ã��
	if ~isempty(Linear)								% ���� ���� ����
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
	if flagNaN,		%NaN �� �߰�!
		fprintf('Press CTRL+C to stop or AnyKey to continue\n');
		pause;
	end
%}
	fprintf('\nSearch  : completed. ');	toc;		% �۾� ����ð� ���	%-]

%% ------------------------------------------------------------------------------
	% tp �� ���� time window �����ؾ� ��.
	%% �ʿ��� ������ capture, tp x ep x ch
	eFS				=	EEG.srate;					% sample rate
	% interval param �� eFS �� eEEG tp length �� ������ �����ϴ��� ����
	tIntr			=	[hEEG.tInterval(1) :1000/eFS: hEEG.tInterval(2)-1];
	tWin			=	[hEEG.TimeWindow(1):1000/eFS: hEEG.TimeWindow(2)-1];
	if length(tIntr)~=size(eEEG,1) error('Mismatch [Interval] for Data'); end
	eEEG			=	eEEG(ismember(tIntr, tWin), :, :);	% window ������ ���
	fprintf('\nModulate: TIME window [%d] -> [%d]\n',length(tIntr),size(eEEG,1));

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 20160426A. flag�� ���� [original ����] Ȥ�� [sort �籸�� ����] �ؼ� ����Ѵ�
%%_______________________________________________________________________________
	if ~isempty(eMRK) & isfield(hEEG, 'fgReorder') & hEEG.fgReorder	% mrk�� sort
%		eMRKa		=	cell2mat(squeeze(eMRK(:,2)))';	% ��Ŀ���� ����
%		[~, ix]		=	sort(eMRKa);				% ����� ix �� Ȯ��
		[eMRK ix]	=	sort(eMRK);					% ����� ix �� Ȯ��
		eEEG		=	eEEG(:, ix, :);				% epoch ����
	elseif isempty(eMRK)
		eMRK		=	ones(1,size(eEEG,2));		% �⺻�� ����
	end

	%% ���� ����� 3D -> 2D �� �ٽ� ���� �� EEG �� update (��Ŀ��)
%	EEG.org_dims	=	size(eEEG);
	EEG.org_dims(1)	=	size(eEEG,1);				% tp
	EEG.org_dims(2)	=	size(eEEG,3);				% ch
	EEG.org_dims(3)	=	size(eEEG,2);				% ep

%	eEEG			=	reshape(eEEG,EEG.nbchan,EEG.points,[]); % ch*tp->ch*tp*ep
	eEEG			=	permute(eEEG, [ 3 1 2 ]);	% tp*ep*ch -> ch*tp*ep
	EEG.org_permute	=	true;						% using shiftdim()
	EEG.data		=	reshape(eEEG, EEG.nbchan, []);	% ch x tp x ep -> ch x tp
	EEG.points		=	size(EEG.data, 2);
	EEG.marker		=	eMRK;
	hEEGo.eMRK		=	eMRK;
	[~, OUT]		=	fileparts(OUT_NAME);		% ������� ����
	EEG.name		=	regexprep(OUT, '_$', '');
	hEEGo.OutName	=	OUT_NAME;					% ����

	vdata			=	EEG.data(EEG.vidx,:);		% �ӽ�, ����ä�� �����͸�
    EEG.min			=	min(EEG.data(:));
    EEG.max			=	max(EEG.data(:));

	%%==================================================

%% -----------------------------------------------------------------------------
% This is local function
%...............................................................................
%
%	input :
%		hEEG	: project header structure
%			+ (�ʼ�) OutName
%			+ (�ʼ�) eMRK
%
%		(*) data ����: electrode (�����Է�) -> SOURCE -> ROITS -> DTF
%		DTF		: Direct Transfer Function, BA x BA x freq x epoch
%		ROITS	: ROI Time Series, BA x tp x epoch
%		SRCTS	: Source Localization, VX x tp x epoch
%
%	output:
%		BOOL	: ���� ���� ����
%
function [ BOOL ] = S_DTFwriter( hEEG, DTFS, ROITSS, SRCTSS )
	% ��Ŀ�� �̹� reader �� ���� ���ĵǾ� �����Ƿ�, ���⼭�� ��Ŀ �׷캰��
	% �з� (���� ����) �ؼ� ����ϴ� �۾� ����.
	% ��Ŀ ���� ������ �� epoch�� ��ȣ�� �����̸� ���� �ο���
	fprintf('--------------------------------------------------\n');
	fprintf('Write   : DTF to file by each epoch\n');

	sFrom			=	S_form4len( length(hEEG.eMRK), true );
	for ixEP		=	1:length(hEEG.eMRK);			% ep �� == ��Ŀ ��

		[DIR, OUT]	=	fileparts(hEEG.OutName);		% ������� ���� Ȯ�ο�
		if isfield(hEEG, 'fgSplitSbj')  & hEEG.fgSplitSbj	% subject �� �и�
			sbj		=	char(regexp(OUT, 'su[0-9]{4}', 'match'));	% extract
			DIR		=	fullfile(DIR, sbj);
		end
		if isfield(hEEG, 'fgSplitCond') & hEEG.fgSplitCond	% cond �� �и�
			DIR		=	fullfile(DIR, hEEG.CurCond);	% ���� '' �̸� ����
		end
		if hEEG.fgSplitEpoch & hEEG.fgReorder			% ��Ŀ�� �и�
%			DIR		=	[ DIR '_' num2str(hEEG.eMRK(ixEP)) ]; % ������ ��Ŀ�߰�
			DIR		=	fullfile(DIR, num2str(hEEG.eMRK(ixEP)));
		end
		if not(exist(DIR, 'dir')), mkdir(DIR); end		% ������ ���� ����

		% ������ ������ epoch ������ ����
%		[DTF ROITS SRCTS]=deal(DTFS(:,:,ixEP),ROITSS(:,:,ixEP),SRCTSS(:,:,ixEP));
		DTF			=	DTFS{ixEP};

		% DTF�� frequency dimension�� ��ճ��� ������ ������ ��ó
		if hEEG.fgAvgDTF, DTF.matrix=squeeze(mean(DTF.matrix,3)); end %freq����X

		% ������ ������ ������ ���� flag �� ��������, ���Ͽ� �����͸� ����
		OUT_NAME	=	fullfile(DIR, sprintf(['%s_' sFrom], OUT, ixEP));% ���ϸ�
		OUT_NAME	=	regexprep(OUT_NAME, '_{2,}', '_'); % del 2 more '_'
		Var			=	{};
		if hEEG.fgSaveDTF, Var{end+1} = 'DTF'; end		% ���庯�� ��Ͽ� �߰�
%		if hEEG.fgSaveROI, Var{end+1} = 'ROITS'; end	% ���庯�� ��Ͽ� �߰�
%		if hEEG.fgSaveSRC, Var{end+1} = 'SRCTS'; end	% ���庯�� ��Ͽ� �߰�

		% ���� ��������.
		eval(['save(''' OUT_NAME ''',''' strjoin(Var,''',''') ''',''-v7.3'');']);
	end	% for ixEP


%% -----------------------------------------------------------------------------
% This is local function
%...............................................................................
%
%	input :
%		scalar	: any scalar
%
%	output:
%		strForm	: string form , ex) '%04d'
%
function [ strForm ] = S_form4len( scalar, zero )
	if nargin < 2, zero = false; end
	if zero, ZERO = '0'; else ZERO = ''; end			% '%02d' or '%2d'

	strForm			=	[ '%' ZERO num2str( floor(log10(scalar))+1 ) 'd' ];

