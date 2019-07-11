%%function [ DurationTime ]	=	L03Elec2eConBA_AmH( hEeg )
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
sbj_list	=	[ 1 2 7 3 4 5 6 8:20 ];
fold_list	=	[ 1:4 ];	%-]
elseif	strcmp(sProject, 'PFC_64')		%-[
dataPATH	=	[ '/home/minlab/Projects/' sProject '/PFC_3/' ];
condition	=	{ '' };	%'TopDown', 'Intermediate', 'BottomUp' };
%sbj_format	=	'PFC_64_su%04d_%s.mat';
%sbj_list	=	[ arrayfun(@(x)({sprintf('su%04d',x)}), [1:29] ) 'GrdAvg' ]; %30
sbj_list	=	[ 12 24 3 4 5 7 9 14 15 16 19 27 26 30 ];	%[ 1:28 30 ];
fold_list	=	[ 1:7 ];
end		%-]

eEEGDir		=	[ dataPATH 'eEEG' ];					% eEEG 데이터
srcDir		=	[ dataPATH 'sEEG' ];
DTFDir		=	[ dataPATH 'dEEG' ];
inpDir		=	srcDir;
outDir		=	DTFDir;
if not(exist(outDir, 'dir')), mkdir(outDir); end
	outputDir	=	outDir;
sbj_format	=	[ sProject '_%s_%s' ];
CPgap		=	5;										% CP기록 기준: 매 5% 마다

%% set important variable !!!	-> EEG 데이터의 전 구간을 계산하는 방식으로 변경!
%% 전체 ROI 데이터 중 -> BA10L, R 만 확보한다.
%load(fullfile(roiDir, 'ROI100_BALx50_BARx50.mat'));	% BA 좌우42개씩 총 84개 좌표
%{
load(fullfile(roiDir, 'ROI82_BALx41_BARx41.mat'));	% BA 좌우42개씩 총 84개 좌표
ix			=	cellfun(@(x)( strcmp(x, 'BA10L') | strcmp(x, 'BA10R') ), labels);
labels		=	labels(ix);
centers		=	centers(ix,:);					% 2D
vertices	=	vertices(ix);
%}
load(fullfile(roiDir, 'EMO_11ROI.mat'));			% BA 좌우11개씩 총 22개 좌표

%POOL				=	S_paraOpen(true);				% 강제로 restart
POOL				=	S_paraOpen();					% 알아서 restart

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
	FILEPATH			=	fullfile(outDir, FILENAME);
	fprintf('\nChecking: Resulted output file: ''%s''... ', FILEPATH);
	if exist([FILEPATH '.mat'], 'file') > 0				% exist !!
		fprintf('exist! & SKIP this\n');
		continue;										% skip, 다음 subject
	else
		fprintf('NOT & Continue\n');
	end
	% -----
%	FILENAME			=	sprintf(sbj_format, char(ixSJ), char(ixCD));
%	FILENAME			= [sPRJ '_' char(ixSJ) '_' char(ixCD) '_' num2str(ixFL)];
%	FILENAME			=	regexprep(FILENAME, '_$', '');	% 끝에 '_'
	fprintf('Loading Source(BA) data for %s\n', FILENAME);
	% -----
%	EEG					=	pop_matreader(FILENAME, fullfile(inpDir));	% read
%	sForm				=	[ '%' num2str(length( num2str(EEG.points) )) 'd' ];
	stdout				=	1;

	% --------------------------------------------------
	load(fullfile(inpDir, FILENAME));					% eEEG : tp x BA x ep
%	eMRK				=	EEG.marker;
%	eCHN				=	labels;
	labels				=	eCHN;
%	[eFS, srate]		=	deal(EEG.srate);
	srate				=	eFS;

	dtflowfedit			=	1;
	dtfhighfedit		=	10;
	optimalorder		=	4;

%	dtfmatrixs			=	zeros(length(eCHN), length(eCHN), 0, size(eEEG,3));
	dtfmatrixs			=	[;;;;];						% dummy 4D
	eEEG				=	permute(eEEG, [2 1 3]);		% tp*BA*ep->BA*tp*ep
%	eEEG				=	reshape(eEEG, size(eEEG,1), []);	% 2D
	for ep = 1:size(eEEG, 3)
		fprintf('\nCalculate DTF of epoch [%d/%d] on [Brodmann] level.\n',	...
				ep,size(eEEG,3));

	% 이 시점에서 voxel 단위로 계산된 source 값을 BA 단위로 계산(즉 평균)
	%% -> 그런데, 앞서 저장된 eEEG 는 이미 BA 단위로 계산된 값이므로 여기선 생략
%{
	sourcedata			=	mat2cell(	squeeze(eEEG(:,:,ep)),... % BA x tp
										size(eEEG,1), ones(1,size(eEEG,2))	);
%	sourcedata			=	SrcROI;
	points				=	length(sourcedata);			% tp length
%	srate				=	EEG.srate; % sampling rate
%	len					=	length(sourcedata{1});		% ROI length
%	model.cortex		=	model.cortex.colincortex;
%	num_verts			=	length(model.cortex.Vertices);

	ROI.labels			=	labels;			% array for ROI
	ROI.centers			=	centers;		% array for ROI
	ROI.vertices		=	vertices;		% array for ROI ( from ROI.mat )

	nroi				=	length(ROI.labels);
	sel					=	1:nroi;
	ROI.selected		=	sel;

	% compute ROI time series.
	roidata				=	zeros(nroi,points);
	for i = 1:nroi
		roi_vert_idx	=	ROI.vertices{sel(i)};
		for j = 1:points
			currentdata	=	sourcedata{j};
			if length(currentdata) == 0
				roidata(i,j)	=	0;
			else
				roidata(i,j)	=	mean(currentdata(roi_vert_idx));
			end
		end
	end
%}
	%% 그래서, 여기서는 바로 roidata 에 대한 이후 연산 진행
	roidata				=	squeeze(eEEG(:,:,ep));		% BA x tp

	% setting info to TS
	TS.data				=	roidata;
	TS.srate			=	srate;
	[TS.nbchan TS.points]	=	size(TS.data);

	startpoint			=	1;
	endpoint			=	TS.points;

	output				=	dtf_computation(TS, startpoint, endpoint,		...
								dtflowfedit, dtfhighfedit, optimalorder, srate);
	% output.dtfmatrixs : BA x BA x freq

%	dtfmatrixs = output.dtfmatrixs;
%	dtfmatrixs = mean(dtfmatrixs,3);

	dtfmatrixs(:,:,:,ep)	=	output.dtfmatrixs;
	end

	save(FILEPATH, 'dtfmatrixs', '-v7.3');

	toc
end
end
end
