%% minlab scalp mat marker -> eConnectome -> BA marker
% designed by Sejik Park, edited by tigoum
clearvars -except BBCI BTB hEeg
close all
clc

%% set variable
sPRJ		=	'PFC_64';
dataPATH	=	[ '/home/minlab/Projects/' sPRJ '/PFC_3/' ];
eEEGDir		=	[ dataPATH 'eEEG' ];			% eEEG ������
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
CPgap		=	5;								% CP ��� ����: �� 5% ����

%% set important variable !!!	-> EEG �������� �� ������ ����ϴ� ������� ����!
%% ��ü ROI ������ �� -> BA10L, R �� Ȯ���Ѵ�.

%POOL				=	S06paraOpen_AmH(true);		% ������ restart

% main
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
	if ~exist([FILEPATH '.mat'], 'file') > 0		% not exist !!
		fprintf('NOT & SKIP this\n');
		continue;									% skip, ���� subject
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
	%% 20160323A. �ߴ��� �����߰�: marker�� �ݵ�� eEEG�� original�� �� ��!!!
	% ���� ����ó�� labels(==ROI name)�� ���� prediction�� �ƹ��� �ǹ̰� ����!
	% ��, ��� epoch ���� ������ ������ marker �� �־����� ���� �Ǳ� ����!
	%% �ݵ�� ���� ����������� ������ marker�� �״�� ����ؾ� ��Ȯ�� ���� ��
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

