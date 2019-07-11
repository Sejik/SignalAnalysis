% H_classan ver 0.50
%% �ڵ� ���� main(): ��� - ���� EEG feature extraction & classification
%
% usage: H_classan( @h_classan_SSVEP_NEW )
%	-> param is must be function pointer ! :: attach to '@' first
%
% first created by tigoum 2015/11/18
% last  updated by tigoum 2016/04/23

function [ ] = H_classan( A_global_AmH )

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% setting environment
%path(localpathdef);	% startup_bbci_toolbox@startup.m ���� path ������
POOL				=	S_paraOpen();
hEEG				=	A_global_AmH();						% param�� fnx ptr
verbose				=	1;

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
for condi			=	1 : length(hEEG.Condi)
	hEEG.CurCond	=	hEEG.Condi{condi};

	% ___________________________________________________________________________
	%% 20160229A. ���� �������� ��ħ or �и� ��� ��� ����
%{
if		~isfield(hEEG, 'fgFolds') | hEEG.fgFolds == 1
	FoldsLoop		=	1;									% ���� ������ ��ħ!
	Folds			=	{ [1:hEEG.lFolds] };				% ���� ����
else
	FoldsLoop		=	length(hEEG.lFolds);				% vector ������ ���
	Folds			=	arrayfun(@(x)({ [x] }), [1:hEEG.lFolds]);
end
%}
%for fd				=	1 : FoldsLoop
for foldfile		=	hEEG.fFolds							% assign like foreach
	% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
%	if length(hEEG.fFolds) > 1,	hEEG.CurFold = foldfile{1}; end	% seperated only!
	hEEG.CurFold	=	foldfile{1};

	% --------------------------------------------------
	epos			=	cell(1,length(hEEG.Inlier));		% data ����
	parfor ix 	= 1:length(hEEG.Inlier)
		fprintf('loading subject %s\n', hEEG.Inlier{ix})

%		epos{ix}	= load_Min_KU_data_new_format(fullfile(hEEG.PATH,'eEEG'), ...
%			hEEG.Head,			hEEG.Inlier{ix},	sCondi,		foldfile{1}, ...
%			hEEG.FreqWindow,	hEEG.tInterval,		hEEG.TimeWindow,		...
%			hEEG.nChannel,		verbose);
%		hEEG.CurSbj	=	hEEG.Inlier{ix};					% parfor:hEEG�����Ұ�
		epos{ix}	=	B_eEEG2epo( hEEG, ix );

		% take only the scalp channels, remove EOG channels
		% ��쿡 ���󼭴� EOG �����Ͽ� ���
		if isfield(hEEG, 'Chan')
			epos{ix}=	proc_selectChannels(epos{ix}, hEEG.Chan);	% �ʿ� ����
		else
			epos{ix}=	proc_selectChannels(epos{ix}, hEEG.ChRemv);	% ���ʿ� ����
		end

		% high pass filter
		db_attenuation	=	30;
		hp_cutoff	=	1;
		[z,p,k]	=	cheby2(4, db_attenuation, hp_cutoff/(epos{ix}.fs/2),'high');
		epos{ix}	=	proc_filt(epos{ix}, z,p,k);
%		epos{ix}.clab
%		size(epos{ix}.x)
	end
%	save(['/home/tigoum/epos_alls.mat'], 'epos', '-v7.3');

	%% calculation for accuracy ----------------------------------------
	Cnt= investigate_spectral_classification_NewFormat( hEEG, epos, verbose );
	%	return : ��� ó�� �ߴ���, �ο��� ����

	%% drawing for spectra ----------------------------------------
	Cnt= viz_spectra_NewFormat( hEEG, epos, verbose );

	%% drawing for pattern ----------------------------------------
	Cnt= viz_classifier_pattern_NewFormat( hEEG, epos, verbose );

end		% for fd
end		% for cond

