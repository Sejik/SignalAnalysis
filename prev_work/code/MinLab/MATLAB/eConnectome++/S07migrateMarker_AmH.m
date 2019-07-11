%% minlab scalp mat marker -> eConnectome -> BA marker
% designed by Sejik Park, edited by tigoum
clearvars -except BBCI BTB hEeg
close all
clc

%% set variable
sPRJ		=	'PFC_64';
dataPATH	=	[ '/home/minlab/Projects/' sPRJ '/PFC_3/' ];
eEEGDir		=	[ dataPATH 'eEEG' ];			% eEEG 데이터
srcDir		=	[ dataPATH 'sEEG' ];
mrkDir		=	[ dataPATH 'mEEG' ];
if not(exist(srcDir, 'dir')), mkdir(srcDir); end
if not(exist(mrkDir, 'dir')), mkdir(mrkDir); end

%% initialize
condition	=	{ '' };	%'TopDown', 'Intermediate', 'BottomUp' };
%sbj_format	=	'PFC_64_su%04d_%s.mat';
sbj_format	=	'PFC_64_%s_%s';
%sbj_list	=	[ arrayfun(@(x)({sprintf('su%04d',x)}), [1:29] ) 'GrdAvg' ]; %30
sbj_list	=	[ 1:3 ];
fold_list	=	[ 1:7 ];
CPgap		=	5;								% CP 기록 기준: 매 5% 마다

%% set important variable !!!	-> EEG 데이터의 전 구간을 계산하는 방식으로 변경!
%% 전체 ROI 데이터 중 -> BA10L, R 만 확보한다.

%POOL				=	S06paraOpen_AmH(true);		% 강제로 restart

% main
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
	if ~exist([FILEPATH '.mat'], 'file') > 0		% not exist !!
		fprintf('NOT & SKIP this\n');
		continue;									% skip, 다음 subject
	else
		fprintf('EXIST! & Continue\n');
	end
	% -----
	fprintf('Loading eEEG data for %s\n', FILENAME);
	EEG					=	pop_matreader(FILENAME, fullfile(eEEGDir));	% read
	% -----
	fprintf('Loading BA data for %s\n', FILENAME);
	load(FILEPATH);			% read

%	eMRK				=	labels;
	%% 20160323A. 중대한 문제발견: marker는 반드시 eEEG의 original을 쓸 것!!!
	% 만약 기존처럼 labels(==ROI name)을 쓰면 prediction시 아무런 의미가 없음!
	% 즉, 모든 epoch 에서 완전히 동일한 marker 가 주어지는 셈이 되기 때문!
	%% 반드시 원래 실험시점에서 측정된 marker를 그대로 사용해야 정확한 제시 됨
	if ~isfield(EEG, 'marker'), error('FATAL   : MUST BE needs the marker'); end

	fprintf('\nMigration marker for %s ', FILENAME);
	if length(EEG.marker) == size(eEEG, 3)
		fprintf('\n[Nice] marker size b/w eEEG(%d) vs BA(%d)', ...
				length(EEG.marker), size(eEEG, 3));
	else
		error('\nERROR   : mismatch marker size b/w eEEG(%d) vs BA(%d)',	...
				length(EEG.marker), size(eEEG, 3));
	end

	eMRK				=	EEG.marker;
	eFS					=	EEG.srate;
%	eEEG				=	cell2mat(ROIdata);			% BA x tp

	fprintf('\nStoring BA data including MARKER(eMRK) for %s ', FILENAME);
	FILEMARK			=	fullfile(mrkDir, FILENAME);
	save(FILEMARK, 'eEEG', 'eMRK', 'eFS', '-v7.3');

	toc
end		% for fold
end		% for sbj
end		% for cond

