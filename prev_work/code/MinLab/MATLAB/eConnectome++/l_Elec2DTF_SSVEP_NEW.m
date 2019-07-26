%% SSVEP�� ���� ����: 6�ڱ� * 10�� * 4ȸ * 3����
%% �����䱸: ���Ǵ� 4�� ����, ��, ���Ǻ� 4ȸ �����ϹǷ�, �� �������� ����ȭ
%%	����, 1 ���Ͽ��� 6�ڱ� * 10�� �� �����Ͱ� �ð��帧 �״�� ����� ��.
%%	1�ڱؿ� ���� segment�� 5�� �̹Ƿ�, 1 ���Ͽ��� 60��*5��=300�� �� ������
% BA������ segmentation�� ����(top-down, intermediate, bottom-up)���� �и�
%	�ϴ� ���� ����������, �̷��� segment �� ���� �ٽ� 300�о� ���� ���� �ȵ�.
%	�׷���, ���Ǻ� segmentation�� �� ��, matlab �ڵ忡�� �и��ϱ�� ��.

%{
function [	fullPATH, Regulation,							...		%-[
			hEEG.Chan, hEEG.ChRemv, dataname, trialname, subname				...
			Freqs, fName, m, ki, cedPATH,	FileExt	]	=	A_globals_AmH( )
%--------------------------------------------------------------------------------
%% �� m ���ϵ��� ����ϴ� ���������� �����ϵ��� �����Ѵ�.
%--------------------------------------------------------------------------------

%global	NUMWORKERS;			%define global var for parallel tool box!!

% ���� �ϳ��� ���̴� ��� �ڵ忡 �����ϰ� ����/���̱� �س��� ���� ���մϴ�.
%
% hEEG.Chan: 1�� ���� 32�� ���� ���� ��ȣ�� �°� ä���̸� ����. �м��� ���������� �ʿ������� ������ ����ϴ� �����Ͱ�
% ��� ä�ο��� �Դ��� Ȯ���ϰų� ���÷����� �� ���� �˴ϴ�.
%
% dataname, trialname: ���� �з����ӿ� ���� �˸°� ���������� �ٲ��ָ� �˴ϴ�.
%
% subname: ������ ����Ʈ. Outlier�� ���� ��� �� ����Ʈ������ ���ָ� �˴ϴ�.

%NUMWORKERS	=	20;
%fullPATH	=	'/home/minlab/PLV_theta';
%fullPATH	=	'/home/minlab/Projects/SSVEP_NEW/SSVEP_2';	% nothing, PURE!
fullPATH	=	'/home/minlab/Projects/SSVEP_NEW/SSVEP_3';	% ocular corr ONLY
Regulation	=	'_';	%'Condi'; %'BaselineCorrection_Imagery';
hEEG.Chan	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
hEEG.ChRemv	={	'NULL'	};	%������ ä��
%selchan		={};				%hEEG.Chan - hEEG.ChRemv
%{
subname		={																...
				{ 'su0001',		'su0001', 'su0001_01', 'su0001_02', },	...
				{ 'su0002',		'su0002', 'su0002_topdown', },			...
				{ 'su0003',		'su0003_01', },						...
				{ 'su0004',		'su0004', },							...
				{ 'su0005',		'su0005', },							...
				{ 'su0006',		'su0006', 'su0006_2', },				...
				{ 'su0007',		'su0007', },							...
				{ 'su0008',		'su0008', },							...
				{ 'su0009',		'su0009', 'su0009_2', },				...
				{ 'su0010',		'su0010', 'su0010_2', },				...
				{ 'su0011',		'su0011', },							...
				{ 'su0012',		'su0012', 'su0012_2', },				...
				{ 'su0013',		'su0013', },							...
				{ 'su0014',		'su0014', },							...
				{ 'su0015',		'su0015', },							...
				{ 'su0016',		'su0016', },							...
				{ 'su0017',		'su0017', },							...
				{ 'su0018',		'su0018', 'su0018_2', },				...
				{ 'su0019',		'su0019', },							...
				{ 'su0020',		'su0020', },							...
				{ 'su0021',		'su0021', },							...
				{ 'su0022',		'su0022', },							...
				{ 'su0023',		'su0023', },							...
				{ 'su0024',		'su0024', },							...
				{ 'su0025',		'su0025', },							...
				{ 'su0026',		'su0026', },							...
				{ 'su0027',		'su0027', 'su0027_2', 'su0027_3', },	...
				{ 'su0028',		'su0028', 'su0028_2', },	...
				{ 'su0029',		'su0029', },							...
				{ 'su0030',		'su0030', },							...
				{ 'su0031',		'su0031', },							...
				{ 'su0032',		'su0032', },							...
				{ 'su0033',		'su0033', },							...
			};
%}
%subname		={	{ 'su0004', 'su0004', },	};
[Head, Common, subname, FileExt]	=	S_sbjlist([ fullPATH '/Export/' ]);
%dataname	=[	11:16 21:26 31:36	];				% trial �׷���: �� 6 * 3 ��
dataname	={	'TopDown', 'Intermediate', 'BottomUp' };	% original ���� ����
trialname	=[	6, 10, 4	];				%6�ڱ�, 10��, 4ȸ, 3����(�� dataname)

Freqs		=[	1:1/2:50	];				% �� �뿪�� ��´�: step 0.5
fName		=AmHlib_get_freqname(Freqs);	% ���ļ� �뿪�� �̸��� �ĺ�
m	=	7;	ki	=	5;						% wavelet �м��� ���� default ��

%cedPATH		=	[ fullPATH '/../MATLAB/Standard-10-10-Cap32.ced' ];
%cedPATH		=	[ fullPATH '/../MATLAB/EEG_32chan.ced' ];
					% cedPATH�� �ٸ� �뵵(blCUT)�� ����Ѵ�.
					% blCUT: �����Ͱ� �ʹ� �� ��, ���� ����(f) �ϴ� ��츸 ǥ��
cedPATH			={									...
					{ 'su0002', 'f', },				...
					{ 'su0012', 'f', },				...
					{ 'su0018', 'f', },				...
					{ 'su0027', 'f', },				...
					};										% �� �� ����	%-]
%}
function [ hEEG ] = A_global_AmH()
%--------------------------------------------------------------------------------
%% project�� parameter�� ����: �����Ϳ��� feature, classification
%--------------------------------------------------------------------------------

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% �⺻ ������ �� '��' ���� ���ο� ���ο� ���� �ٸ� ���ļ��� �Ҵ��ϰ� ������
%		������
%		������
%		������
% �� �׸��� ���� �Ʒ��� ���� ���ļ��� �����.
%
%%		5.5 6.5 7.5
%%		|	|	|
%% 5.0- ��  ��  ��	R1
%% 6.0- ��  ��  ��	R2
%% 7.0- ��  ��  ��	R3
%%		C1	C2	C3
%
% �̸� �������� �Ʒ��� ���� �����Ǵ� ���ں��� ���ļ� ����(harmonic)�� ������
% tgr	R/C		char	R-freq	C-freq
% 1x1	R1C3	(��)	5.0 Hz	7.5 Hz
% 1x2	R3C1	(��)	7.0 Hz	5.5 Hz
% 1x3	R2C1	(��)	6.0 Hz	5.5 Hz
% 1x4	R2C3	(��)	6.0 Hz	7.5 Hz
% 1x5	R3C2	(��)	7.0 Hz	6.5 Hz
% 1x6	R1C2	(��)	5.0 Hz	6.5 Hz
%	-> tgr 1x. ���� x == 1(top down), 2(intermediate), 3(bottom up)
%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	hEEG.Version	=	3;									% version !!!

	%% initialize variables
	% the experiment hEEG.Cond that is to be classified
	hEEG.Cond		=	{ 'TopDown', };	%'Intermediate', 'BottomUp', };
	hEEG.nStimuli	=	6;									% 6�� �ڱ� / ���� ��
	hEEG.nPresent	=	10;									% 10�� ����/ �ڱ� ��
	hEEG.nSession	=	4;									% 4ȸ ���� / ���� ��

	hEEG.CPgap		=	5;							% CP ��� ����: �� 5% ����

	hEEG.fgSplitSession=false;	% �������� �� session ���� ����, false �� Epoch��
	hEEG.fgSplitEpoch=	true;	% epoch�� ����, false== Session��
								%% �Ѵ� false: single ���Ϸ� ���
								%% -> eCon ���: single �����̸� grand avg ó��
	hEEG.fgReorder	=	true;	% ��Ŀ��� epoch ���� sorting
	hEEG.fgSplitCond=	false;	% �� hEEG.Cond ���� dir ���� ����
	hEEG.fgSplitSbj	=	true;	% �� sbj ���� directory ���� ���� ����
	hEEG.fgExportTxt=	false;								% txt ���Ϸ� ����

	hEEG.fgDelTailName=	false;	% ���� �̸����� su00xx ������ ����, �� tail ����
	hEEG.fgRename	=	true;	% rename table �� ������� ������ -> ����� ����
	hEEG.fgInvTime	=	false;								% �ð����� ��迭
	hEEG.fgReject	=	false;	% brain an���� arti-rejection �� ���� epoch ���

	hEEG.fgAvgDTF	=	true;	% DTF �� ���ļ� ������ ��� �� ���� ����
	hEEG.fgSaveDTF	=	true;	% DTF �����͸� ����
	hEEG.fgSaveROI	=	true;	% ROI TS �����͸� ����
	hEEG.fgSaveSRC	=	true;	% SRC TS �����͸� ����

	% ���� ���ǹ��� flag�� �����ϰ� �����Ǿ������� ����: �����ʿ� ����
	if hEEG.fgSplitSession & hEEG.fgSplitEpoch
		error('It is impossible splitting that both true of Session & Epoch');
	end
	if hEEG.fgExportTxt & ~hEEG.fgSplitEpoch				% txt �� 2D �� ����
		hEEG.fgSplitSession	=	false;
		hEEG.fgSplitEpoch	=	true;
	end

	%----------------------------------------------------------------------------
%	hEEG.SmplRate	=	500;								% sampling rate
%	hEEG.FreqWindow	=	[5, 13.5];							% ���� �� ����
	hEEG.FreqWindow	=	[5, 14];							% ���� �� ����
%	hEEG.FreqWindow	=	[];									% no filt �� ��
	hEEG.FreqBins	=	1/2;								% freq step

	%----------------------------------------------------------------------------
%	hEEG.DataPoint	=	5000 * nFolds * Stimulus;			% �������� �� ����
%	hEEG.TimeWindow	=	[0, 5000];			% 0~5000msec
	hEEG.tInterval	=	[-2000, 5000];						% input ����
%%	hEEG.tInterval	=	[0, 5000];							% 0 ~ 5000msec
	hEEG.blTimeWin	=	[-2000, -1500];						% baseline correction
	% ��'��'�ڰ� �ռ��� ������ ������ flickering ����ؼ� -1500���� ����
%	hEEG.TimeWindow	=	[-2000, 5000];						% output ����
	hEEG.TimeWindow	=	[0, 5000];							% 0 ~ 5000msec
%	hEEG.OverlapWin	=	0;	% 200, �� ��ȣ�� �� ��ȣ ������ ��ħ time point ����

	%----------------------------------------------------------------------------
%	hEEG.lFolds		=	{ [1:hEEG.nSession] };				% 4 session cat
%%	hEEG.lFolds		=	{ [1 2] [3 4] };					% 4 session 2 cat
%	hEEG.lFolds		=	{ [1] [2] [3] [4] };				% 4 session each
%%	hEEG.lFolds		=	arrayfun(@(x)({ [x] }), [1:4]);		% 4 session each
	hEEG.lFolds		=	[1:hEEG.nSession];					% 4 session cat
	%% 20160302A. ���ο� �õ��� ���� ���� ������ fold data ������
	%				�м� �Ķ���ͷμ��� nfold ���� �и��Ͽ� ����
	hEEG.nFolds		=	hEEG.nSession;						% 4 session
%	hEEG.nFolds		=	16;									% �ι�� ����
%	hEEG.fgFolds	=	0;									% ���� ��� ��ħ?
	hEEG.ChAll		=	{		...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
%	hEEG.ChRemv		=	{	'not',	'NULL',	};				% ���ʿ� ä��
	hEEG.ChRemv		=	{	'not',	'NULL',	'EOG'	};		% ���ʿ� ä��
	hEEG.ixLive		=	find(~ismember(hEEG.ChAll, hEEG.ChRemv) );%����ִ� ch
	hEEG.ixRemv		=	find( ismember(hEEG.ChAll, hEEG.ChRemv) );%�׾��ִ� ch
	hEEG.Chan		=	hEEG.ChAll( hEEG.ixLive );			% collect live only

%	hEEG.PATH		=	'/home/minlab/Projects/SSVEP_NEW/SSVEP_3';
	hEEG.PATH = ['/home/minlab/Projects/SSVEP_NEW/SSVEP_' num2str(hEEG.Version)];
	hEEG.PrjName	=	strsplit(hEEG.PATH, '/');			% ������Ʈ �̸���
	hEEG.PrjName	=	char(hEEG.PrjName(end-1));			% except Method
%	hEEG.SrcDir		=	'eEEG/eCon.test';
%	hEEG.SrcDir		=	'eEEG/eEEG.epoch';
%	hEEG.SrcDir		=	'eEEG/eEEG.epoch.0~5000ms';
	hEEG.SrcDir		=	'eEEG';
	hEEG.DstDir		=	'dEEG/eCon4';
	hEEG.Src		=	fullfile(hEEG.SrcDir, [hEEG.PrjName '_' ]);
	hEEG.Dst		=	fullfile(hEEG.DstDir, [hEEG.PrjName '_' ]);

	hEEG.RoiDir		=	[ '/home/minlab/Tools/MATLAB/eConnectome++/ROI' ];
%	hEEG.RoiName	=	'ROI100_BALx50_BARx50';				% ��/�� �� 50, �� 100
%	hEEG.RoiName	=	'ROI82_BALx41_BARx41';				% ��/�� �� 41, �� 82
	hEEG.RoiName	=	'Forensic_6ROI';					% ��/�� ��  6, �� 12

%	hEEG.eConTag	=	'eCon';								% eConnectome�� tag
%	rawDir			=	[ basePATH 'RAW' ];		% ERP(minlab) -> eCon ��ȯ�� raw

%{
elseif	strcmp(sProject, 'PFC_64')		%-[
dataPATH	=	[ '/home/minlab/Projects/' sProject '/PFC_3/' ];
hEEG.Cond	=	{ '' };	%'TopDown', 'Intermediate', 'BottomUp' };
%sbj_format	=	'PFC_64_su%04d_%s.mat';
%sbj_list	=	[ arrayfun(@(x)({sprintf('su%04d',x)}), [1:29] ) 'GrdAvg' ]; %30
sbj_list	=	[ 12 24 3 4 5 7 9 14 15 16 19 27 26 30 ];	%[ 1:28 30 ];
hEEG.lFolds	=	[ 1:7 ];
end		%-]
%}

%	all_list		=	1:33;							% list of subject indices
%	if exist([ hEEG.PATH '/eEEG.Inlier' ])
%[Head, Common, lAllSbj, FileExt]=S_sbjlist([hEEG.PATH '/eEEG.Inlier/']);
%	else
	[lAllSbj, Head, Common, FileExt] = S_sbjlist([hEEG.PATH '/' hEEG.SrcDir]);
%	end
	hEEG.HeadName	=	Head;
	% folder ��, ���� cond(��,TopDown) ������, �̰��� common ���� ����->�����ʿ�
	if length(hEEG.Cond)==1&strcmp(['_' char(hEEG.Cond{1})],Common),Common='';end
	hEEG.Common		=	Common;								% common name
	hEEG.OutRemv	=	Common;								% remove on out_name
	hEEG.ExtName	=	FileExt;

	hEEG.Allier		=	cellfun(@(x)({x{1}}), lAllSbj);	% 1st ��Ҹ� ����
%exc_list	=	[ 2 5 7 9 14 15 16 17 21 25 26 27 28 32 ];	% list for exclude
	hEEG.Outlier	=	{							...
					'su0021',						...
					'su0025',						...
					'su0026',						...
					'su0027',						...
					'su0028',						...
					'su0032',						...
					};
	% renaming table
%{
	SSVEP_NEW_su0001	->	SSVEP_NEW_su0001
	SSVEP_NEW_su0003	->	SSVEP_NEW_su0002
	SSVEP_NEW_su0004	->	SSVEP_NEW_su0003
	SSVEP_NEW_su0006	->	SSVEP_NEW_su0004
	SSVEP_NEW_su0008	->	SSVEP_NEW_su0005
	SSVEP_NEW_su0010	->	SSVEP_NEW_su0006
	SSVEP_NEW_su0011	->	SSVEP_NEW_su0007
	SSVEP_NEW_su0012	->	SSVEP_NEW_su0008
	SSVEP_NEW_su0013	->	SSVEP_NEW_su0009
	SSVEP_NEW_su0018	->	SSVEP_NEW_su0010
	SSVEP_NEW_su0019	->	SSVEP_NEW_su0011
	SSVEP_NEW_su0020	->	SSVEP_NEW_su0012
	SSVEP_NEW_su0022	->	SSVEP_NEW_su0013
	SSVEP_NEW_su0023	->	SSVEP_NEW_su0014
	SSVEP_NEW_su0024	->	SSVEP_NEW_su0015
	SSVEP_NEW_su0029	->	SSVEP_NEW_su0016
	SSVEP_NEW_su0030	->	SSVEP_NEW_su0017
	SSVEP_NEW_su0031	->	SSVEP_NEW_su0018
	SSVEP_NEW_su0033	->	SSVEP_NEW_su0019
	SSVEP_NEW_su0034	->	SSVEP_NEW_su0020
%}
%	hEEG.Inlier		=	{
%					'su0001',						...
%					};
	%% inlier Ȥ�� outlier �� �̹� ������, �̰��� ����ڰ� ���ϴ� ����� ������
	%	������ ���̹Ƿ�, �����Ͽ� lAllSbj (�������) ���� ���� list ������ ��!
	if isfield(hEEG, 'Inlier') & isfield(hEEG, 'Outlier')	% �̹� ������ ����
%		hEEG.Inlier	=	hEEG.Allier(find(~ismember(hEEG.Allier, hEEG.Outlier)));
%		hEEG.Inlier	=	hEEG.Allier(~ismember(hEEG.Allier, hEEG.Outlier));
		hEEG.Inlier	=	lAllSbj( ismember(hEEG.Allier, hEEG.Inlier) &		...
								~ismember(hEEG.Allier, hEEG.Outlier));
	elseif isfield(hEEG, 'Inlier')							% �̹� ������ ����
		hEEG.Inlier	=	lAllSbj( ismember(hEEG.Allier, hEEG.Inlier));
	elseif isfield(hEEG, 'Outlier')							% �̹� ������ ����
		hEEG.Inlier	=	lAllSbj(~ismember(hEEG.Allier, hEEG.Outlier));
	end
%		Allier	: ��� ������ ���, ex:{ { 'su0001, 'su0001, 'su0001_1' },...}
%		Outlier	: ���� ���, ex: { 'su0001', 'su0002', ... }

	hEEG.LocCUT		={								...		% data �ʰ�: ������ġ
					{ 'su0002', 'f', },				...
					{ 'su0012', 'f', },				...
					{ 'su0018', 'f', },				...
					{ 'su0027', 'f', },				...
					};										% �� �� ����

	% data ������ �̹� �ִ���, �ٽ� �۾��ؼ� rewrite �� subject ��� ����
%	hEEG.Rework		={								...		% ���۾� ���
%					'su0001',						...
%					};
%	hEEG.Rework		=	cellfun(@(x)({x{1}}), hEEG.Inlier);	% 1st ��Ҹ� ����
	% Rework�� �ݴ��, �̹� �ִ� data ������ ������ subject ��� ����
	% -----
	%% ����, Rework�� Retain �� ���� subject�� �ߺ��Ǹ�, Retain �켱����!
%	hEEG.Retain		={								...		% Rework �ݴ� ���
%					'su0001',						...
%					};
%%	hEEG.Retain		=	cellfun(@(x)({x{1}}), hEEG.Inlier);	% 1st ��Ҹ� ����
	%% ����, Rework�� Retain ��� ����: Retain�� ��� sbj �Ҵ��� ��ó�� �۵�

	return
