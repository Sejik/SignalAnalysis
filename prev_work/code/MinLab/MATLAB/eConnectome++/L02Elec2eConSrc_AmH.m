%%function [ DurationTime ]	=	L02Elec2eConSrc_AmH( hEeg )
%% minlab scalp mat -> eConnectome -> source level mat
% designed by Sejik Park, edited by tigoum
clearvars -except BBCI BTB hEeg
close all
%clc

%% set important variable !!!	-> EEG �������� �� ������ ����ϴ� ������� ����!
%StartTp	=	100; % 1;
%FinishTp	=	200; % EEG.points;

%% set variable
%basePATH	=	'/home/minlab/Tools/MATLAB/eConnectome++/';
%eEEGDir		=	[ basePATH 'eEEG' ];			% eEEG(minlab) ������
%rawDir		=	[ basePATH 'RAW' ];				% ERP(minlab) -> eCon ��ȯ�� raw
%sourceDir	=	[ basePATH 'SRC' ];				% ���� ��� ���� ����
sPRJ		=	'PFC_64';
dataPATH	=	[ '/home/minlab/Projects/' sPRJ '/PFC_3/' ];
eEEGDir		=	[ dataPATH 'eEEG' ];			% eEEG ������
srcDir		=	[ dataPATH 'sEEG' ];
if not(exist(srcDir, 'dir')), mkdir(srcDir); end

%% initialize
condition	=	{ '' };	%'TopDown', 'Intermediate', 'BottomUp' };
%sbj_format	=	'PFC_64_su%04d_%s.mat';
sbj_format	=	'PFC_64_%s_%s';
sbj_list	=	[ 1 : 20 ];
fold_list	=	[ 1:7 ];
CPgap		=	5;								% CP ��� ����: �� 5% ����

POOL				=	S06paraOpen_AmH(true);		% ������ restart
%{
NUMWORKERS	=	POOL.NumWorkers;
tic;
delete(gcp('nocreate'));
myCluster	=	parcluster('local');	% �ű� profile �ۼ�
myCluster.NumWorkers=	NUMWORKERS;				%'Modified' property now TRUE
saveProfile(myCluster);							% 'local' profile now updated
POOL		=	parpool('local', NUMWORKERS);	% �ִ� 48 core ���.
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
	FILENAME			=	regexprep(FILENAME, '_{2}+', '_');	% '_' 2�� �̻�
	FILENAME			=	regexprep(FILENAME, '_$', '');	% ���� '_'
	FILEPATH			=	fullfile(srcDir, FILENAME);
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

	WorkTp				=	StartTp;				% �۾����� epoch ����
	nTP					=	FinishTp -StartTp +1;
	sourcedata			=	cell(1, nTp);			% compute SRC time series
%________________________________________________________________________________
	%% 20160320A. ��굵�� �����ھ� �� stall �Ǵ� core�� �۾� hold ���� ����
	%	����: �Ҹ�, �Ƹ��� 60000��(PFC_64)�� ���ϴ� epoch�� ó���ϴ� ����
	%		���� ������ resource deadlock �߻� ���ɼ� ����.
	%	����: ��������� �� 10% ���� checkpoint log ���
	%		���� ����� log ��Ͽ� ���� ������ ������ ������ load�Ͽ�
	%		�� �������� �簳(rollback) -> �Ź� ó������ �ٽý��� ���� ����
	if exist(fullfile(srcDir, [FILENAME '_cplog' '.mat']))	% cplog ����! ����
		fprintf('[Detect]   : checkpoint log data ! & analyzing...\n');
		load(fullfile(srcDir, [FILENAME '_cplog']));
		nCalcData		=	length(find(cellfun(@(x)(~isempty(x)), sourcedata)));

		% �о����� �����غ���.
		if strcmp(sFILE,FILENAME) &											...
			nTP == FinishTp -StartTp +1 & length(sourcedata) == nTP &		...
			length(find(cellfun(@(x)(~isempty(x)), sourcedata))) == WorkEnd
%			length(find(cellfun(@(x)(~isempty(x)), ROIdata))) == work-StartTp+1	
			WorkTp		=	WorkEnd + StartTp;			% rollback & restart ����
			fprintf('[Recovery] : Rollback & Redo from %d to %d epoch\n',	...
					StartTp, WorkTp);
		elseif nCalcData ==		...		% ó������ ���ӵ� data�� �������
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

	% WORKER ������ ���� ������ �����ؾ� �����Ȳ�� �ĺ��� �� ����
%	for		work		=	[StartTp	: POOL.NumWorkers	: FinishTp]
	for		work		=	[WorkTp		: POOL.NumWorkers	: FinishTp]
		WorkStart		=	work -StartTp +1;		% ix �� 1���� �����ϰ�!
		WorkEnd			=	min(work+POOL.NumWorkers-1, FinishTp) -StartTp +1;
		% �̰��, workend �� numworker�� ����� �ƴϸ�, ���� ���ڶ� �κ� ����

		% ���� ��� �ǵ� �� ���
		fprintf(stdout,	['+ %s : COMPUTE Localizing for [' sForm ':' sForm ']'...
	' / %d = %6.3f%%\r'],	FILENAME, WorkStart, WorkEnd, nTP, WorkEnd/nTP*100);


	parfor	ix			=	[WorkStart : WorkEnd]

		electrodesV		=	EEG.data(options.vidx, ix +StartTp -1);

		% compute map for sensor space
%		sensordata(ix)	=	...
%			{ griddata(model.X, model.Y, electrodesV, model.XI, model.YI,'v4') };
		%% 20160315A. CAUTION: ix�� StartTp(~=1)�� ���� -> sensor �մ� ����ȭ
		% ����, ���� �����͸� ���� -> source.data �� ���ؼ��� ��������!!!

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
		%% ����������� source 20516 voxel �����ʹ� ��� ������ ����
		% ������ loop�� �� voxel ���� smooth ó������

		%% 20160318B. ������, ����� source (0.068073��) ����,
		%%						�ϱ��� smooth (0.266356��) �� �� ����!

		% get smooth values on finer colin cortex
		len				=	length(model.neighbors.neighbors.idx);	%-[
		cortexV			=	zeros(len, 1);
		for	jx			=	1:len
			values		=	cortexVI(model.neighbors.neighbors.idx{jx});
			weight		=	model.neighbors.neighbors.weight{jx};
%			cortexV(jx,:)=	sum(weight .* values);
			cortexV(jx)	=	sum(weight .* values);		% sum() == scalar
		end
		%% ���� ������ ����, matrix ����ȭ�� ���

		sourcedata(ix)	=	{cortexV};
		%% 20160315A. CAUTION: ix�� StartTp(~=1)�� ����->source�մ� ����ȭ%-]

%		fprintf('+ Localizing for [%05.3f%%] (%d / %d)\n',					...
%					ix / nTp *100, ix, nTp);
	end		% for parfor (tp)
%________________________________________________________________________________
		%% 20160320A. �̽��� ���� ������ log ���� ���
		if nTP >= 10000 & mod( round(WorkEnd / nTP * 100, 1), CPgap) == 0
		% epoch ���� 10000 �� �̻��� �� cp ��� ����: �Ҽ� 2�ڸ� ����: 5% Ȯ��
			sFILE		=	FILENAME;
			save(fullfile(srcDir, [FILENAME '_cplog']), 'sFILE',			...
				'nTP', 'WorkStart', 'WorkEnd', 'sourcedata');
			clear sFILE
		end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	end		% for work

	options.sourceminmax(1)	=	min( cellfun(@(x)( min(x(:)) ), sourcedata) );
	options.sourceminmax(2)	=	max( cellfun(@(x)( max(x(:)) ), sourcedata) );

%% �־��� epoch �������� 20516 voxel / 1 epoch ��� �Ϸ�!

	srate				=	EEG.srate;

	fprintf('\nStoring data for %s ', FILENAME);
	save(FILEPATH,	'sourcedata', 'startepoch', 'endepoch', 'srate', '-v7.3');

	toc

	clear sourcedata									% be clear for mem free
	delete(fullfile(srcDir, [FILENAME '_cplog' '.mat']));% cplog ����
end		% for fold
end		% for sbj
end		% for cond

