%%function [ DurationTime ]	=	L03Elec2eConBA_AmH( hEeg )
%% minlab scalp mat -> eConnectome -> BA level mat
% designed by Sejik Park, edited by tigoum
clearvars -except BBCI BTB hEeg
close all
%clc

%% set variable
basePATH	=	'/home/minlab/Tools/MATLAB/eConnectome++/';
%eEEGDir		=	[ basePATH 'eEEG' ];			% eEEG(minlab) ������
%rawDir		=	[ basePATH 'RAW' ];				% ERP(minlab) -> eCon ��ȯ�� raw
roiDir		=	[ basePATH 'ROI' ];				% BA ���� ROI ��ǥ ����� mat
%sourceDir	=	[ basePATH 'SRC' ];				% ���� ��� ���� ����

%% initialize
sProject			=	'SSVEP_NEW';
%sProject			=	'PFC_64';

if		strcmp(sProject, 'SSVEP_NEW')		%-[
dataPATH	=	[ '/home/minlab/Projects/' sProject '/SSVEP_3/' ];
condition	=	{ 'TopDown', };%'Intermediate', 'BottomUp' };
sbj_list	=	[ 1 ];%2 7 3 4 5 6 8:20 ];
fold_list	=	[ 1 ];	%1:4 ];	%-]
elseif	strcmp(sProject, 'PFC_64')		%-[
dataPATH	=	[ '/home/minlab/Projects/' sProject '/PFC_3/' ];
condition	=	{ '' };	%'TopDown', 'Intermediate', 'BottomUp' };
%sbj_format	=	'PFC_64_su%04d_%s.mat';
%sbj_list	=	[ arrayfun(@(x)({sprintf('su%04d',x)}), [1:29] ) 'GrdAvg' ]; %30
sbj_list	=	[ 12 24 3 4 5 7 9 14 15 16 19 27 26 30 ];	%[ 1:28 30 ];
fold_list	=	[ 1:7 ];
end		%-]

eEEGDir		=	[ dataPATH 'eEEG/eCon.test' ];			% eEEG ������
%srcDir		=	[ dataPATH 'sEEG' ];
DTFDir		=	[ dataPATH 'dEEG/eCon' ];
inpDir		=	eEEGDir;
%outDir		=	srcDir;
outDir		=	DTFDir;
if not(exist(outDir, 'dir')), mkdir(outDir); end
	outputDir	=	outDir;
sbj_format	=	[ sProject '_%s_%s' ];
CPgap		=	10;								% CP ��� ����: �� 10% ����

%% set important variable !!!	-> EEG �������� �� ������ ����ϴ� ������� ����!
%% ��ü ROI ������ �� -> BA10L, R �� Ȯ���Ѵ�.
%load(fullfile(roiDir, 'ROI100_BALx50_BARx50.mat'));	% BA �¿�42���� �� 84�� ��ǥ
%{
load(fullfile(roiDir, 'ROI82_BALx41_BARx41.mat'));	% BA �¿�42���� �� 84�� ��ǥ
ix			=	cellfun(@(x)( strcmp(x, 'BA10L') | strcmp(x, 'BA10R') ), labels);
labels		=	labels(ix);
centers		=	centers(ix,:);					% 2D
vertices	=	vertices(ix);
%}
load(fullfile(roiDir, 'Forensic_6ROI.mat'));		% BA �¿�11���� �� 22�� ��ǥ

%POOL				=	S06paraOpen_AmH(false, 4);	% ������ core 4��
%POOL				=	S_paraOpen(true);			% ������ restart
POOL				=	S_paraOpen();

%{
%for f			=	1 : length(hEEG.Trial.Window)
for c			=	1 : length(hEEG.Trial.AllCond)
for s			=	1 : length(hEEG.Subj.Inlier)
%		[hEEG.Trial.CurCond, hEEG.Subj.CurSubj]	=	deal( c, s );
%[hEEG.Freq.CurWin, hEEG.Trial.CurCond, hEEG.Subj.CurSubj] = deal(stFreq.Window{1}, 3, 5);
	[hEEG.Freq.CurWin, hEEG.Trial.CurCond, hEEG.Subj.CurSubj]	=		...
		deal(stFreq.Window{1}, c, s );			% ������ ���Ͽ� ���� ����
	%-----
	stFreq		=	hEEG.Freq;					% ����
	
	[eEEG hEEG BOOL]	=	S03importDat_AmH(hEEG);	% �ش� ������ ������
	if ~BOOL,	continue;	end					% BOOL==false, then SKIP
%	if ~BOOL,	return;	end						% BOOL==false, then SKIP

	stChan		=	hEEG.Chan;
	MxCh		=	size(eEEG, 3);				% length(stChan.idxLive);

	if		length(stChan.idxLive) < MxCh		% ������ ä�μ��� �� ����
		fprintf('Warning : \n');
	elseif	length(stChan.idxLive) > MxCh		% ������ ä�μ��� ����
		fprintf('FatalErr: \n');
%	else		% ==	% ���� �� �� ����
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
	FILENAME			=	regexprep(FILENAME, '_{2}+', '_');	% '_' 2�� �̻�
	FILENAME			=	regexprep(FILENAME, '_$', '');	% ���� '_'
	FILEPATH			=	fullfile(outDir, FILENAME);
	fprintf('\nChecking: Resulted output file: ''%s''... ', FILEPATH);
	if exist([FILEPATH '.mat'], 'file') > 0			% exist !!
		fprintf('exist! & SKIP this\n');
		continue;									% skip, ���� subject
	else
		fprintf('NOT & Continue\n');
	end
	% -----
%	FILENAME			=	sprintf(sbj_format, char(ixSJ), char(ixCD));
%	FILENAME			= [sPRJ '_' char(ixSJ) '_' char(ixCD) '_' num2str(ixFL)];
%	FILENAME			=	regexprep(FILENAME, '_$', '');	% ���� '_'
	fprintf('Loading data for %s\n', FILENAME);
	% -----
	EEG					=	pop_matreader(FILENAME, fullfile(inpDir));	% read
%	sForm				=	[ '%' num2str(length( num2str(EEG.points) )) 'd' ];
	sForm				=	[ '%' num2str( floor(log10(EEG.points))+1 ) 'd' ];
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
	if exist(fullfile(outDir, [FILENAME '_cplog' '.mat']))	% cplog ����! ����
		fprintf('[Detect]   : checkpoint log data ! & analyzing...\n');
		load(fullfile(outDir, [FILENAME '_cplog']));
		nCalcData		=	length(find(cellfun(@(x)(~isempty(x)), SrcROI)));
		
		% �о����� �����غ���.
		if strcmp(sFILE,FILENAME) & nROI == length(labels) &				...
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
%	for		work		=	[StartTp	: POOL.NumWorkers	: FinishTp]
	for		work		=	[WorkTp		: POOL.NumWorkers	: FinishTp]
		WorkStart		=	work -StartTp +1;		% ix �� 1���� �����ϰ�!
		WorkEnd			=	min(work+POOL.NumWorkers-1, FinishTp) -StartTp +1;
		% �̰��, workend �� numworker�� ����� �ƴϸ�, ���� ���ڶ� �κ� ����

		% ���� ��� �ǵ� �� ���
		fprintf(stdout,	['+ %s : COMPUTE Localizing for [' sForm ':' sForm ']'...
	' / %d = %6.3f%%\r'],	regexprep(FILENAME, [sProject '_(.+)'], '$1'),	...
							WorkStart, WorkEnd, nTP, WorkEnd/nTP*100);

	for	ix			=	[WorkStart : WorkEnd]
%		electrodesV		=	EEG.data(options.vidx, ix);
		electrodesV		=	EEG.data(options.vidx, ix +StartTp -1);

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
		if nTP >= 1000 & mod( round(WorkEnd / nTP * 100, 1), CPgap) == 0
		% epoch ���� 1000 �� �̻��� �� cp ��� ����: �Ҽ� 2�ڸ� ����: 5% Ȯ��
			sFILE		=	FILENAME;
			save(fullfile(outDir, [FILENAME '_cplog']), 'sFILE',			...
				'nROI', 'nTP', 'WorkStart', 'WorkEnd', 'SrcROI');
			clear sFILE
		end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	end		% for work

%	options.sourceminmax(1)	=	min( cellfun(@(x)( min(x(:)) ), sourcedata) );
%	options.sourceminmax(2)	=	max( cellfun(@(x)( max(x(:)) ), sourcedata) );

	%% SL activity(voxel) -> BA activity(ROI) complete: currently, we needs!
	% BA activity ��� �Ϸ� ����. �̰��� �����ؼ� ����ϸ� ��

%{
	% Source Data structure
	sourcedata	: {1x2500 cell}
	srate		: 500
	startepoch	: 1
	endepoch	: 2500
%}
%{
	sourcedata			=	SrcROI;
	srate				=	EEG.srate;
	startepoch			=	options.startepoch;
	endepoch			=	options.endepoch;
	save([ FILEPATH '.source' ],	'sourcedata', 'srate',					...
									'startepoch', 'endepoch', '-v7.3');
%}
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
%	save( [ FILEPATH '_ROITS.mat' ], 'ROITS', '-v7.3');

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
			eEEG		=	reshape(eEEG, [], [dims(2)], [dims(3)]);
%		elseif ndims(EEG.org_dims) == 2					% ������ 2D �� ���
%			dims(3) = 1;								% 2D�Ƿ�, ep==1 ����
		end
														% BA x tp -> BA x tp x ep
%		if EEG.org_permute, eEEG = permute(eEEG,[2 1 3]); end %BA*tp*ep->tp*BA*ep
%		eEEG			=	permute(eEEG, [2 1 3]);		% tp*BA*ep->BA*tp*ep
	else
		eEEG			=	shiftdim(eEEG, 1);			% BA x tp -> tp x BA
	end

%	fprintf('\nStoring data for %s ', FILENAME);
%	save(FILEPATH, 'eEEG', 'eMRK', 'eCHN', 'eFS', '-v7.3');

%	clear eEEG eMRK SrcROI								% be clear for mem free
%%	delete(fullfile(outDir, [FILENAME '_cplog' '.mat']));% cplog ����

	% --------------------------------------------------
	fprintf('\nMigration to DTF calculation for %s.', FILENAME);

%	load(fullfile(inpDir, FILENAME));					% eEEG : tp x BA x ep
%	eMRK				=	EEG.marker;
%	eCHN				=	labels;
%	labels				=	eCHN;
%	[eFS, srate]		=	deal(EEG.srate);
%	srate				=	eFS;

	dtflowfedit			=	5;
	dtfhighfedit		=	14;
	optimalorder		=	4;

%	dtfmatrixs			=	zeros(length(eCHN), length(eCHN), 0, size(eEEG,3));
	dtfmatrixs			=	[;;;;];						% dummy 4D
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

	output				=	dtf_computation(TS, startpoint, endpoint,		...
								dtflowfedit, dtfhighfedit, optimalorder);
	% output.dtfmatrixs : BA x BA x freq

%	dtfmatrixs = output.dtfmatrixs;
%	dtfmatrixs = mean(dtfmatrixs,3);

	dtfmatrixs(:,:,:,ep)	=	output.dtfmatrixs;
	end	% for ix = ep

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
	DTF.matrix			=	dtfmatrixs;		% 4D
	DTF.dims			=	{ 'channel', 'channel', 'frequency', 'epoch' };
	DTF.labels			=	eCHN;
	DTF.locations		=	centers;		% array for ROITS ( from ROI.mat )
	DTF.frequency		=	[dtflowfedit dtfhighfedit];
	DTF.type			=	'ROI';
	DTF.isadtf			=	0;
	DTF.srate			=	srate;
	DTF.vertices		=	vertices;
	save(FILEPATH, 'DTF', '-v7.3');
	delete(fullfile(outDir, [FILENAME '_cplog' '.mat']));% cplog ����

	toc
end		% for fold
end		% for sbj
end		% for cond
