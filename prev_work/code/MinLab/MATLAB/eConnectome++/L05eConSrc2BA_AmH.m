%%function [ ]	=	scalp2source( )
%% minlab scalp mat -> eConnectome -> source level mat
% designed by Sejik Park, edited by tigoum

%% set important variable !!!	-> EEG �������� �� ������ ����ϴ� ������� ����!
%startepoch	=	100; % 1;
%endepoch	=	200; % EEG.points;

%% set variable
basePATH	=	'/home/minlab/Tools/MATLAB/eConnectome++/';
eEEGDir		=	[ basePATH 'eEEG' ];			% eEEG(minlab) ������
rawDir		=	[ basePATH 'RAW' ];				% ERP(minlab) -> eCon ��ȯ�� raw
roiDir		=	[ basePATH 'ROI' ];				% BA ���� ROI ��ǥ ����� mat
sourceDir	=	[ basePATH 'SRC' ];				% ���� ��� ���� ����

%% initialize
%cd(rawDir);
%eeg_files	=	dir('*.mat');
%eeg_files	=	dir('COM_AI_EVK.mat');
sbjlist		=	{ 'PFC_64_su0001_1.mat' };
%ls([ LoadPath '*.dat' ], '-1')
%for eegFileNum	=	1:length(eeg_files)
%	eeg_info{eegFileNum, 1}	=	eeg_files(eegFileNum).name;
%end

%cd(roiDir);
load(fullfile(roiDir, 'ROI_BA09_BA46.mat'));	% BA9, BA46 ��ǥ ��� ROI �ε�

%% main
old_per		=	0;								% percentage ��ȭ �ǵ� �� ���
%for DataNum	=	1:length(eeg_info)
for sbj		=	sbjlist
	tic;
	fprintf('Loading data for %s\n', sbj{1});
%	curDir	=	pwd;
%	cd(rawDir);
%	pathstr	=	rawDir;
%	name	=	eeg_info{DataNum,1};
%	EEG		=	pop_matreader(name, pathstr); % read file
	EEG		=	pop_matreader(sbj{1}, fullfile(eEEGDir));	% read file
%	cd(curDir);
	% eegfc(EEG);
	% pop_sourceloc(EEG);

	% --------------------------------------------------
	fprintf('construct model for BEM / transfer eeg data to BEM matrix.\n');

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
	model.YI			=	model.italyskinxy.xy(model.interpk,2);
	%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	options.step			=	round(EEG.points/10);
	if options.step <= 0, options.step=	2; end
	options.vidx			=	EEG.vidx;
	options.currentpoint	=	1;
	options.auto			=	0;
	options.method			=	'mn';
	options.lamda			=	0;
	options.autocorner		=	1;
	options.threshold		=	0.0;
	options.HWHM			=	3;
%	options.startepoch		=	156;						% startepoch;
%	options.endepoch		=	468;						% endepoch;
	options.startepoch		=	1;							% startepoch;
	options.endepoch		=	EEG.points;					% endepoch;
	options.alpha			=	1;
	options.cutskin			=	0;
	options.labels			=	0;
	options.electrodes		=	0;
	options.sensorcaxis		=	'local';
	options.sensorminmax	=	[EEG.min, EEG.max];
	options.sourcecaxis		=	'local';
	options.sourceminmax	=	[realmax, realmin];
	options.usebem			=	0;
	options.currymatrix		=	0;

	% --------------------------------------------------
	[startepoch, endepoch]	=	deal(options.startepoch, options.endepoch);
	fprintf('Localizing epoch [%d:%d] on [Electrode] to [Source] level.\n',	...
			startepoch, endepoch);

% 	POOL				=	S05paraOpen_AmH(false, 4);	% ������ core 4��
 	POOL				=	S05paraOpen_AmH();			% ������ core 4��

	nROI				=	length(labels);
	nEpoch				=	endepoch -startepoch +1;
%	sensordata			=	cell(1, nEpoch);
	sourcedata			=	cell(1, nEpoch);			% compute SRC time series
%	ROIdata				=	zeros(nROI, nEpoch);		% compute ROI time series
	ROIdata				=	cell(1, nEpoch);			% compute ROI time series
	cortexVI			=	[];

%	for		ix	=	startepoch : endepoch
%	parfor	ix	=	1 : nEpoch
	% WORKER ������ ���� ������ �����ؾ� �����Ȳ�� �ĺ��� �� ����
	for		work		=	[startepoch : POOL.NumWorkers : endepoch]
		WorkStart		=	work -startepoch +1;		% ix �� 1���� �����ϰ�!
		WorkEnd			=	min(work+POOL.NumWorkers-1, endepoch) -startepoch +1;
		% �̰��, workend �� numworker�� ����� �ƴϸ�, ���� ���ڶ� �κ� ����
	parfor	ix			=	[WorkStart : WorkEnd]

%		electrodesV		=	EEG.data(options.vidx, ix);
		electrodesV		=	EEG.data(options.vidx, ix +startepoch -1);

		% compute map for sensor space
%		sensor.data(ix -startepoch +1)	=							...
%		sensordata(ix)	=	...
%			{ griddata(model.X, model.Y, electrodesV, model.XI, model.YI,'v4') };
		%% 20160315A. CAUTION: ix�� startepoch(~=1)�� ���� -> sensor �մ� ����ȭ
		% ����, ���� �����͸� ���� -> source.data �� ���ؼ��� ��������!!!

		% compute sources on cortex
		if options.autocorner
			lamda		=	l_curve(model.U,model.s,electrodesV,'tikh');
		else
			lamda		=	options.lamda;
		end
		%% compute sources on cortex
		if isequal(options.method,'mn')
			cortexVI	=	tikhonov(model.U,model.s,model.V,electrodesV,lamda);
		elseif isequal(options.method,'wmn')
			cortexVI	=	tikhonov(model.U,model.s,model.V,electrodesV,lamda);
			cortexVI	=	cortexVI ./ model.W';
		end
		if options.currymatrix == 1
			cortexVI(length(cortexVI)+1:options.cortexnumverts)	=	0;
		end
		%% ����������� source 20516 voxel �����ʹ� ��� ������ ����
		% ������ loop�� �� voxel ���� smooth ó������

		%% 20160318B. ������, ����� source (0.068073��) ����,
		%%						�ϱ��� smooth (0.266356��) �� �� ����!

		% get smooth values on finer colin cortex
%{
		len				=	length(model.neighbors.neighbors.idx);	%-[
		cortexV			=	zeros(len, 1);
		for	jx		=	1:len
			values		=	cortexVI(model.neighbors.neighbors.idx{jx});
			weight		=	model.neighbors.neighbors.weight{jx};
%			cortexV(jx,:)=	sum(weight .* values);
			cortexV(jx)	=	sum(weight .* values);		% sum() == scalar
			%% 20160316A sum(weight .* values) ��Һ� �� & ��ü �� -> ��İ� ��ü
			% ���� ��� �������̰� ���� ����, ������� double �϶� �ٸ�!
			%	-> single �϶��� ����. ���κҸ�Ȯ
%			cortexV(jx)	=	weight' * values;
		end
		%% 20160316A. ������, parfor �� ����ص� �������̰� ����
		% �Ƹ���, �ܼ� ������ �����ϱ� ������ loop�� �����ϴ� �Ͱ� ���̰� ���� ��
		% ��, �������� �������� loop unroll�� �� ����� cortexV �� �ٽ� local-
		% ization�ϴ� �ð��� �� ū ������ �ǹ����� ������ ��.
		%% ���� ������ ����, matrix ����ȭ�� ���

%		source.data(ix -startepoch +1)	=	{cortexV};
		sourcedata(ix)	=	{cortexV};
		%% 20160315A. CAUTION: ix�� startepoch(~=1)�� ����->source�մ� ����ȭ%-]
%}
		%% 20160318C. trying to ROI's voxel only rather than all voxel
		% ��, �ϱ��� loop�� �� voxel ���� �����ϴ� ���̹Ƿ�, ROI �� ���ؼ���
		% ����ϸ� �� �ӵ� ���� ����!
		% get smooth values on finer colin cortex FOR [compute ROI time series]
		roidata			=	zeros(nROI, 1);
		for	jx			=	1:nROI						% �� ROI �� ����
			ixRV		=	vertices{jx};

			ROIvts		=	zeros(length(ixRV), 1);
			for kx		=	1:length(ixRV)				% 1 ROI �����ϴ� �� voxel
				rx		=	ixRV(kx);
				values	=	cortexVI(model.neighbors.neighbors.idx{rx});%�迭����
				weight	=	model.neighbors.neighbors.weight{rx};

				ROIvts(kx)	=	sum(weight .* values);	% sum() == scalar
%				ROIvts(jx)	=	weight' * values;
			end
			%% 20160316A sum(weight .* values) ��Һ� �� & ��ü �� -> ��İ� ��ü
			% ���� ��� �������̰� ���� ����, ������� double �϶� �ٸ�!
			%	-> single �϶��� ����. ���κҸ�Ȯ
			roidata(jx)	=	mean(ROIvts);				% �� ROI ���� activity
		end
		ROIdata(ix)		=	{roidata};

		% �Ʒ� min, max ����� loop �ۿ��� ���� �����ص� ��.	%-[
		% ���� loop�� ���ؼ��� voxel ��길 ��Ȯ�� �����Ͽ� source.data �� ����
		% ����, source.data ���� min, max ���� �ϸ� ��.
%{
		% update absolute min and max values
		abscortexV		=	abs(cortexV);
		dmin			=	min(abscortexV);
		dmax			=	max(abscortexV);
		if dmin < options.sourceminmax(1)
			options.sourceminmax(1)	=	dmin;
		end
		if dmax > options.sourceminmax(2)
			options.sourceminmax(2)	=	dmax;
		end
%}
		%-]
%		fprintf('+ Localizing for [%05.3f%%] (%d / %d)\n',					...
%					ix / nEpoch *100, ix, nEpoch);
	end		% parfor
		% ���� ��� �ǵ� �� ���
		fprintf('+ Localizing for [%d:%d] / %d = %05.3f%%\n',				...
					WorkStart, WorkEnd, nEpoch, WorkEnd / nEpoch *100);
	end		% for work

%{
		% update absolute min and max values	%-[
		abscortexV		=	abs(cortexV);
		dmin			=	min(abscortexV);
		dmax			=	max(abscortexV);
		if dmin < options.sourceminmax(1)
			options.sourceminmax(1)	=	dmin;
		end
		if dmax > options.sourceminmax(2)
			options.sourceminmax(2)	=	dmax;
		end	%-]
%}
%{
	options.sourceminmax(1)	=	min( cellfun(@(x)( min(x(:)) ), sourcedata) );%-[
	options.sourceminmax(2)	=	max( cellfun(@(x)( max(x(:)) ), sourcedata) );

%	SourceROI.data			=	source.data;% critical source data
%	SourceROI.data			=	sourcedata;	% �Ʒ��� �ڵ�� pass: mem ����
	SourceROI.srate			=	EEG.srate;	% sampling rate
	SourceROI.ROI.labels	=	labels;		% array for ROI ( from ROI.mat )
	SourceROI.ROI.centers	=	centers;	% array for ROI ( from ROI.mat )
	SourceROI.ROI.vertices	=	vertices;	% array for ROI ( from ROI.mat )
%	load('colincortex.mat');
%	SourceROI.Cortex.Vertices=	colincortex.Vertices;
%	SourceROI.Cortex.Faces	= colincortex.Faces;
%	SourceROI.Cortex.FaceVertexCData=	colincortex.FaceVertexCData;
	SourceROI.Cortex.Vertices=	model.cortex.colincortex.Vertices;
	SourceROI.Cortex.Faces	=	model.cortex.colincortex.Faces;
	SourceROI.Cortex.FaceVertexCData=	model.cortex.colincortex.FaceVertexCData;
	SourceROI.usebem		=	0;
%% �־��� epoch �������� 20516 voxel / 1 epoch ��� �Ϸ�!

%% 20516 voxel (epoch��) ���� ROI ��ġ activity ���� -------------------------
	% pop_roits(SourceROI);
	fprintf('compute epoch [%d:%d] on [Source] level to [Brodmann Area] .\n',...
			startepoch, endepoch);

%	sourcedata		=	SourceROI.data;		% ���ʿ��� pass ����: mem ����
	srate			=	SourceROI.srate;
	save( fullfile(sourceDir, 'PFC_64_su0001_SRC_1.mat'),					...
		'sourcedata', 'startepoch', 'endepoch', 'srate', '-v7.3');

	points			=	length(sourcedata);	% epoch ����
	len				=	length(sourcedata{1});	% voxel ����
	model.cortex	=	model.cortex.colincortex;
	num_verts		=	length(model.cortex.Vertices);
	ROI				=	SourceROI.ROI;
	ROI.srate		=	srate;
	nroi			=	length(ROI.labels);
%	sel				=	1:nroi;
%	ROI.selected	=	sel;
	[sel, ROI.selected]	=	deal( 1:nroi );

	% compute ROI time series.
	ROIdata	=	zeros(nroi,points);
	for i	=	1:nroi
		roi_vert_idx	=	ROI.vertices{sel(i)};
		for j	=	1:points
			currentdata	=	sourcedata{j};	% == SourceROI.data == source.data
			if length(currentdata) == 0
				ROIdata(i,j)	=	0;
			else
				ROIdata(i,j)	=	mean(currentdata(roi_vert_idx));
			end
		end
	end	%-]
%}
%{
	xlimit	=	points;	%-[
	xlabelstep	=	round(xlimit/10);

	% x labels
	xlabelpositions	=	[0:xlabelstep:xlimit];
	xlabels	=	[0:xlabelstep:xlimit];
	xlabels	=	xlabels / srate;
	xlabels	=	num2str(xlabels');

	% y labels
	channelmaxs	=	max(ROIdata,[ ],2);
	channelmins	=	min(ROIdata,[ ],2);    
	spacing	=	mean(channelmaxs-channelmins);  
	ylimit	=	(nroi+1)*spacing;
	ylabelpositions	=	[0:spacing:nroi*spacing];    
	YLabels	=	ROI.labels(sel);
	YLabels	=	strvcat(YLabels); 
	YLabels	=	flipud(str2mat(YLabels,' '));	%-]
%}
	ROI.labels		=	labels;		% array for ROI ( from ROI.mat )
	ROI.centers		=	centers;	% array for ROI ( from ROI.mat )
	ROI.vertices	=	vertices;	% array for ROI ( from ROI.mat )
	ROI.srate		=	EEG.srate;	% sampling rate

	% mean values for the current window
%	meandata		=	mean(ROIdata,2);

	ROI.data		=	cell2mat(ROIdata);
	%% SL activity(voxel) -> BA activity(ROI) complete: currently, we needs!
	% BA activity ��� �Ϸ� ����. �̰��� �����ؼ� ����ϸ� ��

	% re structuring ROI data to eEEG style : tp x ch x ep
	% ������� ������, 2Dȭ�Ǿ� �ִ� ROI ����� eEEG ������� ����
	%	����, EEG.org_dims field�� ������ ��쿡 ���缭 �籸�� �� ����

	save( fullfile(sourceDir,'PFC_64_su0001_ROI_BA09_BA46_4.mat'),'ROI','-v7.3');
	toc
%{
	% ---------------------------------------------------------------------- -[
	% It is conectivity computation

	% output	=	pop_dtf_computation(ROI.data, srate);
	TS.data		=	ROI.data;
	TS.srate	=	srate;
	[TS.nbchan, TS.points]	=	size(TS.data);

	startpoint	=	1;
	endpoint	=	2000;
	if endpoint > TS.points
		endpoint	=	TS.points;
	end

	deltaT	=	1/TS.srate;
	starttime	=	startpoint*deltaT;
	endtime	=	endpoint*deltaT;

	maxf	=	num2str(round(TS.srate/2));
	options.siglevel	=	0.05;
	options.shufftimes	=	1000;

	startpoint	=	round(startpoint);
	endpoint	=	round(endpoint);

	startpoint	=	max(1,min(startpoint, TS.points));
	endpoint	=	max(1,min(endpoint, TS.points));

	if startpoint > endpoint
		tmp	=	endpoint;
		endpoint	=	startpoint;
		startpoint	=	tmp;
	end

	ts	=	TS.data(:,startpoint:endpoint)';

	% frequecny limit
	lowf	=	1;
	highf	=	100;

	lowf	=	round(lowf);
	highf	=	round(highf);
	maxf	=	TS.srate/2;
	lowf	=	max(1,min(lowf, maxf));
	highf	=	max(1,min(highf, maxf));

	optimalorder	=	4;
	optimalorder	=	round(optimalorder);
	optimalorder	=	max(1,min(optimalorder, 20));

	[n, m]	=	size(ts); 

	options.shufftimes	=	1000;
	options.siglevel	=	0.05;



	% compute the DTF/ADTF values
	options = getappdata(handles.dtfcomputation,'options');
	rb_dtf = get(handles.rb_dtf,'value');
	if rb_dtf
		output.isadtf = 0;
		output.srate = TS.srate;
		output.frequency = [lowf highf];
		output.dtfmatrixs = DTF(ts,lowf,highf,optimalorder,TS.srate);

		sigtest = get(handles.sursig,'value');
		if sigtest
			sig_dtfmatrix = DTFsigvalues(ts, lowf, highf, optimalorder, TS.srate, options.shufftimes, options.siglevel, handles.completetext);    % calculate surrogated DTF values
			output.dtfmatrixs = DTFsigtest(output.dtfmatrixs, sig_dtfmatrix);        % get the new DTF value after statistical analysis
		end
	else
		output.isadtf = 1;
		output.srate = TS.srate;
		output.frequency = [lowf highf];
		output.dtfmatrixs = ADTF(ts,lowf,highf,optimalorder,TS.srate);    
		
		sigtest = get(handles.sursig,'value');
		if sigtest
			sig_dtfmatrix = ADTFsigvalues(ts, lowf, highf, optimalorder, TS.srate, options.shufftimes, options.siglevel, handles.completetext);    % calculate surrogated ADTF values
			output.dtfmatrixs = ADTFsigtest(output.dtfmatrixs, sig_dtfmatrix);        % get the new ADTF value after statistical analysis
		end
	end



	% Set the diagonal elements to zeros, and normalize the DTF/ADTF values.
	if output.isadtf
		for i	=	1:m
			output.dtfmatrixs(:,i,i,:)	=	0;
		end
		scale	=	max(max(max(max(output.dtfmatrixs))));
	else
		for i	=	1:m
			output.dtfmatrixs(i,i,:)	=	0;
		end
		scale	=	max(max(max(output.dtfmatrixs)));
	end
	if scale == 0
		scale	=	1;
	end
	output.dtfmatrixs	=	output.dtfmatrixs / scale;	%-]
%}

end

