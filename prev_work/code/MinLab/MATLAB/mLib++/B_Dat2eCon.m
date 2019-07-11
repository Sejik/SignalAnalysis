% B_Dat2eCon ver 0.25
% - export �� *.dat�� eConnectome�� ������ 2D �����ͷ� Grand Avg ����
%
% usage: B_Dat2eCon( @b_Dat2MAT_SSVEP_NEW )
%	-> param is must be function pointer ! :: attach to '@' first
%
% first created by tigoum 2016/04/01
% last  updated by tigoum 2016/04/23

function [ BOOL ] = B_Dat2eCon( A_global_AmH )
% ver 0.25 : rename this function

%% �ڵ� �����ϱ� �� �޸𸮸� ���� ��Ʈ���� �����ִ� �˾�â���� �ݴ� ����
clearvars -except A_global_AmH;
%close all;

%% setting %%

%% Header %%
global	SRC_NAME;
global	WORKNAME;
% ���� �ϳ��� ���̴� ��� �ڵ忡 �����ϰ� ����/���̱� �س��� ���� ���մϴ�.
%
% hEEG.Chan: 1�� ���� 32�� ���� ���� ��ȣ�� �°� ä���̸� ����. �м��� ���������� �ʿ������� ������ ����ϴ� �����Ͱ�
% ��� ä�ο��� �Դ��� Ȯ���ϰų� ���÷����� �� ���� �˴ϴ�.
%
% hEEG.Cond, hEEG.Cond: ���� �з����ӿ� ���� �˸°� ���������� �ٲ��ָ� �˴ϴ�.
%
% hEEG.Inlier: ������ ����Ʈ. Outlier�� ���� ��� �� ����Ʈ������ ���ָ� �˴ϴ�.

%A_globals_AmH();%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@
%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@@
%[	hEEG.PATH, Regulation, hEEG.Chan, hEEG.ChRemv, hEEG.Cond, trialname, hEEG.Inlier,	...
%	Freqs, fName, m, ki, cedPATH, sExt	]		=	A_global_AmH();

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%POOL				=	S_paraOpen();
hEEG				=	A_global_AmH();						% param�� fnx ptr

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Total				=	tic;		%��ü ���� �ð�

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
LocCUT				=	hEEG.LocCUT;
sExt				=	hEEG.ExtName;

%% file loading ������ process:
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

	lData			=	'';			%data���� �����Ǵ� data�� ���� ���
for cond=1:length(hEEG.Cond)
%	for cond=1:length(hEEG.Cond)
%�۾�����	%-[
	%1. bdf reader ����
	%2. bdf reader�� ���� ���� data �� �߰������� ���� epoching
	%	-> Ư�� fs���� ������� �Ͽ� ��Ȯ�� �ð� ���� Ȯ�� ��
	%	-> all(bdf_file.Head.SampleRate(1:65) == fs)	%-]
	if iscell(hEEG.Cond),	sCond	=	hEEG.Cond{cond};
	else,					sCond	=	num2str(hEEG.Cond(cond));	end
	% ���ſ� ���ڿ��� ��� 4���� ���ɼ��� �ִ�.
	% ~					:	�׳� �� ���ڸ� �����ϸ� ��
	% head~REMOVE~other	:	~ ���� ~ ������ REMOVE�ش� string�� ������
	% ~REMOVE			:	~ ������ ��� string ����
	% head~REMOVE		:	~ ������ ��� string ����
	ssCond			=	regexprep(sCond,'\s*~[^~]*~\s*','');	%'~'��������
	ssCond			=	regexprep(ssCond,'\s*~\s*[^~]*$','');	%'~'��������

	Grand			=	[];							% sbj ��տ�

	% 20151108A. trial�� �ɰ��� ��� ���� ��� ����Ͽ� �ڵ� ���յǴ� ��� �߰���
for sbj_idx=1:length(hEEG.Inlier)
	BOOL			=	true;						% default return

%	hEEG		=	hEEG.hEEG;

%	SubjInfo		=	hEEG.SubjInfo;
%	lSubj			=	SubjInfo.Inlier{hEEG.SubjInfo.CurSubj};	% �迭 or ���ڿ�
	lSubj			=	hEEG.Inlier{sbj_idx};	% �迭 or ���ڿ�

%	ChanInfo		=	hEEG.ChanInfo;
%	FreqDomain		=	hEEG.FreqDomain;

	lSRCNAME		=	{};	% must be init!:�ƴϸ� �Ʒ� skip�� �ٸ����� ȥ�տ���!
	if iscell(lSubj) && length(lSubj)>=3
		% ���� ���ϵ��� ���ս��Ѿ� �Ѵ�. ���� �̸��� ó���� ��
		% �̶� ��Ұ����� �ּ� 3�� -> sub1(����), sub1_1(src), sub1_2(src)
		for s		=	2 : length(lSubj)				% 1:���� �̸�, 2:cut ����
			WORKNAME=[	char(lSubj{s}) hEEG.Common '_' sCond	];
%			lSRCNAME{s-1}=[	hEEG.PATH hEEG.Src	WORKNAME sExt	]; %�迭
			lSRCNAME{s-1}=fullfile(hEEG.PATH,[hEEG.Src WORKNAME sExt]);%�迭
		end
		% �������� file���� ������
		WORKNAME	=[	char(lSubj{1}) '_' ssCond	];
	elseif iscell(lSubj) && length(lSubj)<=2
		% ��� ������ 2����, ����=�ҽ� �̹Ƿ�, �׳� ���� ����ó�� ó�� ����
		WORKNAME	=[	char(lSubj{2}) hEEG.Common '_' sCond	];
%		lSRCNAME{1}	=[	hEEG.PATH hEEG.Src	WORKNAME sExt	];%only 1
		lSRCNAME{1}	=fullfile(hEEG.PATH,[hEEG.Src WORKNAME sExt]);%only 1

		% �������� file���� ������
		WORKNAME	=[	char(lSubj{1}) '_' ssCond	];

	else	%���� ���ϸ��� ���
		WORKNAME	=[	char(lSubj) hEEG.Common '_' sCond	];
%		lSRCNAME{1}	=[	hEEG.PATH hEEG.Src	WORKNAME sExt	];%only 1
		lSRCNAME{1}	=fullfile(hEEG.PATH,[hEEG.Src WORKNAME sExt]);%only 1
	end

%		hEEG.hEEG.WORK	=	WORKNAME;		% �����̸� �� ����

	% ���� ��� ���ϸ� ����
%		OUT_NAME	=[	hEEG.PATH hEEG.Dest	WORKNAME '.mat' ];
		WORKNAME	=	regexprep(WORKNAME, '[_]+$', '');		% '_' �� ����
%		OUT_NAME	=[	hEEG.PATH hEEG.Dest	WORKNAME '_1.mat' ];
%		OUT_NAME	=	fullfile(hEEG.PATH,[hEEG.Dest WORKNAME '_1.mat']);
%		hEEG.hEEG.OutFile	=	OUT_NAME;
		OUT_NAME	= fullfile(hEEG.PATH,[hEEG.Dest WORKNAME '_' hEEG.eConTag]);
		OUT_NAME	=	regexprep(OUT_NAME, hEEG.OutRemv, ''); % filter

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%check result file & skip analysis if aleady exists.
%	if	hEEG.fgRename & isfield(hEEG, 'lRename')		% renaming
	if	hEEG.fgRename									% renaming
		su	=	regexp(OUT_NAME, 'su[0-9]{4}', 'match');% extract
%		re	=	hEEG.lRename(cellfun(@(x)( strcmp(x{1},su) ), hEEG.lRename));
%		OUT_NAME=regexprep(OUT_NAME, su, re{1}{2});		% mapping new name
		re	=	sprintf('su%04d', sbj_idx);
		OUT_NAME=regexprep(OUT_NAME, su, re);			% mapping new name
	end
%	fprintf('\nChecking: Analyzed result file: ''%s''...',[OUT_IMAG '.jpg']);
	fprintf('\nChecking: Analyzed result file: ''%s''...', [OUT_NAME '*.*t']);
%	if exist([OUT_IMAG '.jpg'], 'file') > 0				%exist !!
	try, EXIST = ls([OUT_NAME '*.*t'], '-1'); catch, EXIST = 0; end
%	if exist(OUT_NAME, 'file') > 0						%exist !!
	% ��� ������ ������ ���, �����ϰ� ����� �� ������, skip ���� �����.
	if ~EXIST											% no exist, let's go
		fprintf('NOT & Continue the Analyzing\n');

	elseif isfield(hEEG, 'Retain') & any(ismember(hEEG.Retain, lSubj{1}))
		fprintf('exist! & SKIP analyzing this, Retaining\n');
		continue;										% skip
	
	elseif isfield(hEEG, 'Rework') & any(ismember(hEEG.Rework, lSubj{1}))
		fprintf('exist, BUT Continue the Analyzing\n');

	else												% Retain/Rework ���Ҽ�
		fprintf('exist! & SKIP analyzing this\n');
		continue;										% skip
	end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	AllTime			=	tic;		%������ preparing �ð��� �����Ѵ�.
	fprintf('--------------------------------------------------\n');
	fprintf('Convert : %s''s DAT to RAW for [ %s ]\n', WORKNAME,			...
			[ regexprep(OUT_NAME, '.*(su[0-9]{4}.*)$', '$1') '*.*t' ]);
	%'\n'���ϴ� ������ �Ʒ��� toc ����� ���� �پ���� �Ϸ���.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% merging ���: ���� SubjInfo.Inlier �� �� cell�� �ټ� ���� subj 
%	�̸��� ��� �ִٸ�, �̵��� ������� �о, �ϳ��� �����ͷ� ��ħ
%	epoch �������� concatenate �ؾ� ��.
	eMRK			=	{;};							% empty 2D array
	eEEG			=	[;;];							% empty 3D array
	for s			= 1 : length(lSRCNAME)				% �ݵ�� cell array ��!
		SRC_NAME	=	regexprep(lSRCNAME{s}, '_([.][a-zA-Z]+)$', '$1'); % trim

		%check & auto skip if not exist a 'dat file.
		fprintf('Checking: Source file: ''%s''... ', SRC_NAME);
		if exist(SRC_NAME, 'file') <= 0					%skip
			fprintf('not! & SKIP converting this\n\n');
			continue;									%exist !!
		else
			fprintf('EXIST & Continue the converting\n\n');
		end

%%-------------------------------------------------------------------------------
% Convert: DAT -> eEEG...mat
% -------------------------------------------------------------------------------
		ChanLive	=	hEEG.Chan(hEEG.ixLive);			% only live
		ixLive		=	hEEG.ixLive;
		ixRemv		=	hEEG.ixRemv;

		[eCHN,SDP,eFS,Orient]	=	S_importVHDR(SRC_NAME);
%		eCHN		=	upper(eCHN);
		MxChn		=	length(eCHN);					% eCHN : ä�� ���
%		hEEG.SmplRate=	eFS;

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
					MxChn, length(ChanLive));
%			hEEG.Chan=	eCHN;
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

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		%% Subjects_All Epochs_bl
%		eval(['BAdat		=	importdata(''' SRC_NAME ''');']);
		BAdat		=	importdata( SRC_NAME );
		%*.dat ������ ù �ٿ� ����� ä�� ������ Ȯ���� ���ƾ� ��!
		if ~isstruct(BAdat),	BAdat	=	struct('data', BAdat); end

%		B			=	BAdat.data;
%		B			=	shiftdim(B, 1);
%		eBLK		=	reshape(B, 1000, [], 32);
%		eBLK		=	reshape(BAdat.data, 1000, [], 32);
%%		eBLK		=	reshape(BAdat.data, SDP, [], MxChn); %% time * ep * ch

		%% 20151117A. BA�� export �ɼǿ� ����, import *.dat reshape ���� �߰�
		% Wavelet�� ����� �� ������ Ÿ���� �׻� (timepoint x epochs x channels)
		% ���� �� ��! ������, ��쿡 ����, Brain Analyzer�� export�κ���
		% ���� �ٸ� ������ dat format �� load �� �� ����.
		% DataOrientation=MULTIPLEXED: �� ��� [data point seriese] x [ch] ����
		% DataOrientation=VECTORIZED : �� ��� [ch] x [data point seriese] ����
		% ����, orientation �� ���� �ٸ� ó�� ������ ����, �������� eEEG ����
		% Ȯ���� �����ؾ� ��.
		% eEEG ����: timepoint x epoch x ch
		if	s > 1 & ~isempty(eEEG) & MxChn ~= size(eEEG, 3)	% ���� blk�� ����ġ
			error('Error   : channel size mismatch of (%d : %d)\n',			...
				size(eEEG,3), MxChn);

		elseif		strcmp(Orient,'VECTORIZED') &&	size(BAdat.data,1)==MxChn
			eBLK=	reshape(BAdat.data, MxChn, SDP, []);	%% ch * time * ep
			eBLK=	shiftdim(eBLK, 1);						% tm x ep x ch

		elseif	strcmp(Orient,'MULTIPLEXED') &&	size(BAdat.data,2)==MxChn
			eBLK=	reshape(BAdat.data, SDP, [], MxChn);	%% time * ep * ch

		end

%		clear B BAdat
		clear BAdat

%		eBLK(:,:,17)=	NaN;	% EOG
%		eBLK(:,:,22)=	NaN;	% NULL
%		eBLK(:,:,find(ismember(eCHN,'EOG')) )	=	0;	% EOG

%%		save([hEEG.PATH '/skk_data/skk_' SRC_NAME], 'eBLK');	% eBLK array ����

		nMRK		=	size(VMRK, 1);
		eMRK(end+1:end+nMRK,:)	=	VMRK;			% horzcat or vertcat

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
	if isempty(eEEG), continue; end					% data ������ ���� subj��!
	%% ----------

%% ------------------------------------------------------------------------------
%% 20150517B. eEEG �����Ϳ� ���� �⺻���� ó��/���� ����� �ʿ���.	%-[
	%��, �����Ͱ� �ƴ� ����ä���� �����ؾ� �Ѵ�.
	% ch17= EOG, ch22=NULL, ���� �κ� ����. �ڿ��� ���� ������ ����� ó����.
	% -> 20150517C. ���� �� ������ ��������. �տ������� ������� ���� ����

	tic; fprintf('\nFinding : & remove a dummy channels on eEEG array.\n');
	eEEG(:,:,[ ixRemv ])	=	[];					% remove ä�� ����

	% eCHN ������ live ä�θ� ���� �α�� �Ѵ�.
	eCHN		=	eCHN([ ixLive ]);				% live �� ����

	%% marker�� ������ ��Ȯ���� ����
	fprintf('Search  : consistency a triggering marker vs eEEG data\n');
	if size(eEEG,2) ~= size(eMRK,1)					% trial �� == ��Ŀ ��?
		fprintf('Warning : not consist the number of (%.1f : %.1f)\n',	...
				size(eEEG,2), size(eMRK,1));

		% �� ���, eMRK �� �� �� time point ���̿� ����ġ �ϴ� ���� ����
		% �켱, ����ġ �ϴ� ��(tp�� ����� �ƴ� ��)�� ������ ���� ����,
		% ��ġ����(tp�� ��� �� ��)�� eEEG epoch ���� ������ �� ����.
		lMod0	=	find( mod((cell2mat(eMRK(:,3))-eMRK{1,3}), size(eEEG,1))==0);
		if length(lMod0) == size(eEEG,2)			% ����!
			lModNo0=find( mod( (cell2mat(eMRK(:,3)) - 1), size(eEEG,1) ) ~= 0);
			fprintf('Matching: success removing the garbage MARKERs(#%s)\n', ...
			strjoin(cellfun(@(x)( {sprintf('%d',x)} ), eMRK(lModNo0,3)),', '));
			eMRK=	eMRK(lMod0,:);					% ��ġ �Ǵ°� �� ����
		else										% ������ ���� ����!
			fprintf('Error   : not consist number of (%.1f : %.1f)\n',		...
					size(eEEG,2), size(eMRK,1));
			ERROR;
		end
	end
	for m = 1 : size(eEEG,2)						% epoch���� �����ϴ� ��Ŀ����
		if size(eEEG,1)*(m-1)+eMRK{1,3} ~= eMRK{m,3}% ��Ŀ����(1����Ŀ)�� sync
			fprintf('Warning : not consist at time point(%.1f : %.1f)\n',	...
						size(eEEG,1)*(m-1)+1, eMRK{m,3});
		end
	end % for

	%eEEG ������ �� NaN �� ���� ������, �ش� ���� ���� ä�ΰ��� �񱳿���
	%�Ź� ������ ���� �����ϸ�, ���ʿ��� ������ ������ �� ����.
	%����, �� ���� ���� ä���� �ִٸ�, Notify �ؾ� ��!!
	%eEEG �Ը� ������ �� ���, �ð��� �ҿ� �� ���� ������ ������ ��.
	fprintf('Search  : a NaN value on eEEG array\n');
	flagNaN			=	0;
	[ rNaN cNaN ]	=	find(isnan(eEEG));			% 2D �������� ��ġ ã��
	Linear			=	sub2ind(size(eEEG), rNaN, cNaN);	% eEEG 1D�� index
	if length(Linear)								% ���� ���� ����
		fprintf('Notify  : eEEG(%s) have %d of NaNs\n', WORKNAME,length(Linear));
		flagNaN		=	1;
%		eEEG(Linear)=	0.0;						% all NaN -> 0.0
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

	%% ���翡�� ����������, eEEG �� 32��° ä�ο� ��Ŀ ������ ������!
%	eEEG(1,:,end+1)	=	cell2mat(eMRK(:,2));		% ��Ŀ��->eEEG �߰�ä��
	% ��Ŀ�� �Ѱ��� ���̹Ƿ�, time point �� 1���� ����, 2:end==0 ��
%	clear eMRK

%% ------------------------------------------------------------------------------
	%% �߿�: ����Ƚ�� ��� �ʰ��ϴ� ������ �� ��Ŀ�� �ǵ�&���� ü��
	%% epoch�� ���� ����� �����ϴ��� Ȯ�κ��� ���� �ؾ� ��!

	fprintf('--------------------------------------------------\n');
	nIter			=	hEEG.nPresent;				% �ڱش� Ƚ��
	nTrial			=	hEEG.nStimuli * nIter;		% �ڱؼ� * �ڱش� Ƚ��
	nTry			=	hEEG.nSession;				% �õ� Ƚ��
	nMarker			=	nIter * nTry;				% �õ�*�ڱ�Ƚ��=�� �ڱ� �Ѽ�

	eMRKa			=	cell2mat(squeeze(eMRK(:,2)))';	% ��Ŀ���� ����
	if nTrial*nTry < size(eEEG, 2)	% nTrial�� ����, �̺��� ũ�� ����!	%-[
		fprintf('Warning : trial size(%d) is too big than %d*%d\n',			...
				size(eEEG,2), nTrial, nTry);

		% trial ������ �ݵ�� �¾ƾ� �ϹǷ�, �� trigger ������ ���,
		% ���ذ� ���, "���� ��", "���� ��" "���� ��"�� ã�ƾ� ��.
		cMRK		=	unique(eMRKa);				% catch a trigger code
		nMRK		=	arrayfun(@(x)(length(find(eMRKa==x))), cMRK);

%		CeqMRK		=	cMRK( find(nMRK == nMarker) );% ���� ������ �� == code
%		CgtMRK		=	cMRK( find(nMRK >  nMarker) );% �� ���� ��
%		CltMRK		=	cMRK( find(nMRK <  nMarker) );% �� ���� ��
		CeqMRK		=	cMRK( nMRK == nMarker );	% ���� ������ �� == code
		CgtMRK		=	cMRK( nMRK >  nMarker );	% �� ���� ��
		CltMRK		=	cMRK( nMRK <  nMarker );	% �� ���� ��

		NeqMRK		=	nMRK( arrayfun(@(x)( find(cMRK==x) ), CeqMRK) ); %����
		NgtMRK		=	nMRK( arrayfun(@(x)( find(cMRK==x) ), CgtMRK) ); %����
		NltMRK		=	nMRK( arrayfun(@(x)( find(cMRK==x) ), CltMRK) ); %����

		% gt �� �߻��ϸ�, �̸� �����ؾ� �� -> eEEG �� eMRK ���� ��� !
		if isempty(NltMRK) && ~isempty(NgtMRK)			%% gt ����!
			IgtMRK	=	arrayfun(@(x)( {find(eMRKa==x)} ), CgtMRK);%��ü�� ��ġ��

			ixCUT	=	find(cellfun(@(x)(strcmp(char(x{1}),lSubj{1})),LocCUT));
			if isempty(ixCUT) | LocCUT{ixCUT}{2}=='l'				%��� no ����
				IgtMRK=	cellfun(@(x)( {x(nMarker+1:end)} ), IgtMRK);%�ʰ� ��ġ��
			elseif LocCUT{ixCUT}{2}=='f'
				IgtMRK=	cellfun(@(x)( {x(1:length(x)-nMarker)} ), IgtMRK);%ó��
			end
			ixgtMRK	=	cell2mat(IgtMRK);

			% �ʰ� ��ġ�� �Ĺݺη� �������, �̵��� eEEG �� eMRK �� �����ϸ� ��
			% IgtMRK ���� cell�� �迭�� �� �����Ƿ�, �̸� vector�� �����ʿ�
			% �̶�, �� ��Ŀ�� ������ ��ġ�� �����ϹǷ�, �ߺ����� ���� ����
%			xCgtMRK	=	arrayfun(@(x,y)( {repmat(x, [length(y{:}) 1])} ),	...
%						CgtMRK, IgtMRK);			% �ڵ带 ��ġ���� ��ŭ ����
			SgtMRK	=	cellfun(@(x)( { strjoin(		...
							arrayfun(@(y)( {num2str(y)}), x) , ',')}		...
									), IgtMRK);		% gt��Ŀ�� ��ġ��->���ڿ�����

			eMRK(	[ ixgtMRK ], :)	=	[];			% gt ���� ����
			eEEG(:,	[ ixgtMRK ], :)	=	[];			% gt ���� ����

			fprintf('Control : removing the over Marker: %s\n',				...
strjoin(arrayfun(@(x,y)( {sprintf('%d(#%s)',x,char(y))} ), CgtMRK,SgtMRK),', '));

		%% ::::::::::::::::::::::::::::::::::::::::::::::::::
		% ���� ���� ������ ������! lt->eq�� ����� ����, gt�� ����� ��.
		% lt �� gt �� ����: n(lt) < n(gt) ���� ��. -> �ƴϸ� FAULT!
		%% �ϴ��� �̷� ��Ȳ ��ü�� ������ ��ó�ϴ� ���� ����!!!
		%% ����� ������ ��.
		elseif ~isempty(NltMRK) && sum(NltMRK) <= sum(NgtMRK)	%-[
			%% �����ϰ� ���ؼ�, sum(NltMRK) == sum(NgtMRK) �� �߻� �Ұ���
			% �ֳ��ϸ�, ���� �����̸� total sum = nTrial*nTry == size(eEEG, 2) !
			% ����, sum(NltMRK) < sum(NgtMRK) �� ��츸 ��� �ϸ� ��

			error(['FAULT  : matching #Marker irregularities : '			...
					'lt{%s} < gt{%s}\n'],									...
strjoin(arrayfun(@(x,y)( {sprintf('%d(#%d)', x,y)} ), CltMRK, NltMRK),', '), ...
strjoin(arrayfun(@(x,y)( {sprintf('%d(#%d)', x,y)} ), CgtMRK, NgtMRK),', ') );%-]
		elseif ~isempty(NltMRK)	% &&i sum(NltMRK) > sum(NgtMRK)	%-[
			fprintf(['FAULT  : matching #Marker irregularities : '			...
					'lt{%s} > gt{%s}\n'],									...
strjoin(arrayfun(@(x,y)( {sprintf('%d(#%d)', x,y)} ), CltMRK, NltMRK),', '), ...
strjoin(arrayfun(@(x,y)( {sprintf('%d(#%d)', x,y)} ), CgtMRK, NgtMRK),', ') );%-]
		%% ::::::::::::::::::::::::::::::::::::::::::::::::::
		end	%-]
%	elseif nTrial > size(eEEG, 2)	% nTrial�� ����,�̺��� �۾Ƶ� ����
%		fprintf('Warning : trial size(%d) is too small than %d\n',		...
%				size(eEEG,2), nTrial);
	elseif ~hEEG.fgReject & nTrial*nTry > size(eEEG, 2)	% nTrial���� ���� ����
		error('\nFATAL   : trial size(%d) is too small than %d*%d\n\n',	...
				size(eEEG,2), nTrial, nTry);

	elseif nTrial*nTry > size(eEEG, 2)	% nTrial�� ����, �̺��� �۾Ƶ� ����
		fprintf('\nWarning : trial size(%d) is too small than %d*%d\n\n',	...
				size(eEEG,2), nTrial, nTry);
	end

%% ------------------------------------------------------------------------------
	% �̾ �����Ϳ� ��Ŀ�� ����Ƚ��(nTry)�� �����Ͽ� �߶� ���Ϻ��� ����

	fprintf('--------------------------------------------------\n');
	tic; fprintf('Write   : 3D data to a MAT file\n');

	%% try ���� ���� ���Ϸ� ����ؾ� ��.
	% eEEG ���� ����: timepoint x epoch x ch -> tp x ch x ep
	eMRKa			=	cell2mat(squeeze(eMRK(:,2)))';	% ��Ŀ���� ����
%	eEEGa			=	permute(eEEG, [1, 3, 2]);	% 2���� 3�� ���� �ٲٱ�
%	eEEGb			=	permute(eEEGa,[1, 3, 2]);	% �ٽ� �ٲٱ�(��Ȯ�� �����)
%	if isequal(eEEGb, eEEG)		%all(all(all(eEEGb == eEEG)))
%		fprintf('Swapping: a location b/w epoch & chan\n');
%	else
%		error('Swapping: FAILURE! b/w epoch & chan\n');
%	end

	%% �������� �Ʒ��� process�� ���� �����͸� �����Ѵ�.
	% 1. 3D eEEG�� 2D ������ ����
	% 2. ���ļ� ���� 5.0 ~ 13.5 Hz filtering <- t x ch ������! (base: t-vector��)
	% 3. 2D ������ 3D ������ ����
	% 4. baseline correction
	% 5. artifact rejection
	% 6. voltage signal -> power signal
	% 7. time window ���� ����
	% 8. inverse time ó�� : �ð��� �������� ��迭
	% 9. average trial
	%10. convert eConnectome format

	% 1. reshape to 2D
	reEEG			=	reshape(eEEG, [], size(eEEG,3));% ( tp x ep ) x ch

	% 2. filter
	% Butterworth Filtering �κ�.
%	fSmpl			=	500;
%	[bbb, aaa]		=	butter(1, [0.5 30]/(fSmpl/2),'bandpass');
	if ~isempty(hEEG.FreqWindow)
		nOrder		=	hEEG.FreqWindow / (eFS/2);
		[bbb, aaa]	=	butter(1, nOrder, 'bandpass');

		flEEG		=	filtfilt(bbb, aaa, reEEG);	% zero-phase: (tp x ep) x ch
	else
		flEEG		=	reEEG;						% �׳� ���� (���� ����)
	end

	% 3. reshape to 3D
	reEEG			=	reshape(flEEG, [size(eEEG)]);	% tp x ep x ch

	% 4. baseline correction : must have ! eEEG(tp, ep, ch)
	ix = ismember(	hEEG.tInterval(1) :1000/eFS :hEEG.tInterval(2)-1,		...
					hEEG.blTimeWin(1) :1000/eFS :hEEG.blTimeWin(2)-1 );
	blEEG			=	reEEG -repmat(mean(reEEG(ix,:,:)), [size(reEEG,1),1,1]);

	% 5. artifact rejection
	% ��ȣũ�Ⱑ +-100 �Ѿ�� ���� ����
	ix				=	find( abs(blEEG) > 100);	% seq ������ ����
	[~,ep,~]		=	ind2sub(size(blEEG), ix);	% �ش� epoch ����
	ep				=	unique(ep);
	arEEG			=	blEEG;						% �ϴ� ����
	arEEG(:,ep,:)	=	[];							% �ش� epoch �� ����
	fprintf('[Artifact Rejection] remove %d trial & kept %d trial\n',		...
				length(ep), size(arEEG,2));

	% 6. power
	arEEG			=	arEEG .^ 2;					% bl ��, envelop ��ƾ� !

	% 7. window ������ ����
	ix = ismember(	hEEG.tInterval(1) :1000/eFS :hEEG.tInterval(2)-1,		...
					hEEG.TimeWindow(1):1000/eFS :hEEG.TimeWindow(2)-1 );
	gEEG			=	arEEG(ix, :, :);			% window ������ ���

	% 8. inverse time ó�� : �ð��� �������� ��迭
	% �����Ϳ� ���� ���˰� ������ �Ϸ�Ǿ� clean �����̹Ƿ�, ���� time inverse
	% �� ��������. (���� flag option�� �ִٸ�)
	% data �� marker ��� �ð��� ���� inverse ���Ѿ� ��.
	% -> ���: data�� 3D -> 2D �� ������� ȯ���ؼ� ���� �� 3D ��ȯ
	% gEEG ����: timepoint x epoch x ch
	if hEEG.fgInvTime
%		gEEG2		=	reshape(gEEG, [], [MxCh]);	% 2D�� ��ȯ
%		gEEG2		=	gEEG2([size(gEEG2,1):-1:1], :);	% inverse ordering tp
%		gEEG2		=	reshape(gEEG2, [size(gEEG,1)], [], [MxCh]); %3D
		% 2D��ȯ�� inverse�� 3D �״�� inverse �� ��� �񱳿��
%		gEEG3		=	gEEG([size(gEEG,1):-1:1], [size(gEEG,2):-1:1], :);
%		isequal(gEEG2, gEEG3)
		gEEGa		=	gEEG ([size(gEEG, 1):-1:1], [size(gEEG, 2):-1:1], :);
		gEEGb		=	gEEGa([size(gEEGa,1):-1:1], [size(gEEGa,2):-1:1], :);
		if isequal(gEEGb, gEEG)
		fprintf('[Pass]  : inversion data equal than origins...\n');
		else
		fprintf('Warning : inversion data mismatch than original data...\n');
		end
		gEEG		=	gEEGa;

		clear gEEGa gEEGb
	end

	% 9. average
	gEEG			=	squeeze(mean(gEEG, 2));		% average for ep -> tp x ch

	%10. convert eEEG to eCon structure
	SAVEeEEG2eCon( hEEG, OUT_NAME, gEEG, eCHN, eFS );

	%%------------------------------
	Grand(sbj_idx,:,:)	=	gEEG;					% grand average ���� ����
	%%------------------------------
	clear eEEG flEEG gEEG EEG	% eEEGa eEEGb;

	%%==================================================
	fprintf('\nComplete: %s''s processing :: ',WORKNAME);	toc(AllTime);
	fprintf('==================================================\n');

end		%for sub

	if isempty(Grand),	continue;	end
	Grand			=	squeeze(mean(Grand, 1));	% sbj �� ���� ���
	SAVEeEEG2eCon(hEEG,regexprep(OUT_NAME,'su[0-9]{4}','GrdAvg'),Grand,eCHN,eFS);

end		%for data

fprintf('\nFinished: total time is ');	toc(Total);

	return

%--------------------------------------------------------------------------------
function [ BOOL ] = SAVEeEEG2eCon( hEEG, OUT_NAME, eEEG, eCHN, eFS )
	EEG				=	struct;

	EEG.name		=	OUT_NAME;					% the name for the EEG data
	EEG.org_dims	=	size(eEEG);					% ���� ����: dp x ch
	EEG.data		=	permute(eEEG, [2 1]);		% chan x data(dp)
%	EEG.data		=	reshape(EEG.data, EEG.org_dims(2), []);	% ch x (tr x dp)
		% a 2D array ([m,n]) for EEG time series where m = nbchan and n = points
	EEG.type		=	'EEG';	% the type of data, 'EEG'(����X), 'ECOG' or 'MEG'
	EEG.unit		=	'uV^2';						% data�� ����
	EEG.nbchan		=	EEG.org_dims(2);			% the number of channels
	EEG.points		=	size(EEG.data, 2);			% # of sampling points
	EEG.srate		=	eFS;						% sampling rate
	EEG.labeltype	=	'standard';					% channel location
													% 10-10, 10-20: 'standard'
													% �̿��� ��� 'custom' ǥ��
	EEG.labels		=	eCHN';						% a cell array of chan labels
				% channel name(������ ����ϴ� �� ���� �η��� �ƴ� �� ���� �Է�)
%	EEG.marker		=	eeg.eMRK';					% append by tigoum

	PATH	=	regexprep(fullfile(hEEG.PATH, hEEG.Dest), '/[^/]+$', '');
%	if not(exist(fullfile(hEEG.PATH, hEEG.Dest), 'dir'))
	if not(exist(PATH, 'dir')), mkdir(PATH); end

	% �����Ŀ� ����: Ȯ����, ���嵥���� ����, ������ ���� ����Ͽ� ���
	save([OUT_NAME '.mat'],'EEG', '-v7.3'); % ȣȯ��!

	BOOL			=	true;
	return

