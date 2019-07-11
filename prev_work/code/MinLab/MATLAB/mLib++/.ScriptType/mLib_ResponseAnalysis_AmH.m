%% Script Type : source�� A_globals_AmH �κ��� ȹ��

%% Analyzer�� Vmrk ������ ���� subject�� Response�� ���� ����Ǵ� �ٽ�������
%% RT==Reaction Time �� Error Rate �� ����Ѵ�.

%%%% ��꿡 �ռ�!, Ʈ���� �ڵ� �� �������ڵ�(�ð������� �Ұ����ϰ� ��ŷ�Ǵ�)��
%% ���� �����ؾ� ��.
%% �̶�, PRT ��Ʈ���� 8bit 2������ �ڵ尪�� �����ʿ� ����, �� bit-field ��
%% time overap �� ���� �߻������� ���������� ���� reasonable �� ���� ����!

%% ------------------------------------------------------------------------------
% �ڵ� �����ϱ� �� �޸𸮸� ���� ��Ʈ���� �����ִ� �˾�â���� �ݴ� ����
%close -except Path4eeg, subj;
clearvars -except MarkerPath, Marker4Stimuli, Marker4Response, SavePath;

%% setting %%
path(localpathdef);	%<UserPath>�� �ִ� pathdef.m �� �����Ͽ� �߰����� path�� ���

%A_globals_AmH();%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@
%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki, cedPATH	]		=	A_globals_AmH();
	%Freqs, fName�� cell array �� ���: float vector�� ���� �ʿ�
	if iscell(Freqs)
		Freqs					=	Freqs{1};				% 1st �����͸� ����
		fName					=	fName{1};
	end
	if ~isfloat(Freqs)
		error('"Freqs" is not float data or vector\n');
	end
[mkStim		mkResp]	=	deal( trialname(1), trialname(2) );	% ��Ŀ �뵵�� reuse
[StartTp	FinishTp]=	deal( m, ki );						% Ÿ�̹� �뵵�� reuse
idxLive				=	find( ~ismember(channame, removech) );	%����ִ� ä�θ�
idxRemv				=	find( ismember(channame, removech) );	%����ִ� ä�θ�

Total				=	tic;		%��ü ���� �ð�

	lData			=	'';			%data���� �����Ǵ� data�� ���� ���
for datanumb=1:length(dataname)
%	for datanumb=1:length(dataname)
	if iscell(dataname),	sCondi	=	dataname{datanumb};
	else,					sCondi	=	num2str(dataname(datanumb));	end

	% 20151108A. trial�� �ɰ��� ��� ���� ��� ����Ͽ� �ڵ� ���յǴ� ��� �߰���
for subnumb=1:length(subname)
	BOOL			=	true;									% default return

%	FileInfo		=	hEEG.FileInfo;

%	SubjInfo		=	hEEG.SubjInfo;
%	lSubj			=	SubjInfo.Inlier{hEEG.SubjInfo.CurSubj};	% �迭 or ���ڿ�
	lSubj			=	subname{subnumb};	% �迭 or ���ڿ�

%	ChanInfo		=	hEEG.ChanInfo;
%	FreqDomain		=	hEEG.FreqDomain;

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
	fHeader			=	strsplit(fullPATH, '/');		% folder�� == header��
	FileInfo.Src	=	[ '/Raw Files/'	char(fHeader(end)) '_' ];
	FileInfo.sExt	=	'.eeg';
	FileInfo.Dest	=	[ '/RespAn/'	char(fHeader(end)) '_' ];
	FileInfo.dExt	=	'.xls';

	lSRCNAME		=	{};	% must be init!:�ƴϸ� �Ʒ� skip�� �ٸ����� ȥ�տ���!
	if iscell(lSubj) && length(lSubj)>=3
		% ���� ���ϵ��� ���ս��Ѿ� �Ѵ�. ���� �̸��� ó���� ��
		% �̶� ��Ұ����� �ּ� 3�� -> sub1(����), sub1_1(src), sub1_2(src)
		for s		=	2 : length(lSubj)				% 1:���� �̸�, 2:cut ����
			WORKNAME=[	char(lSubj{s}) Regulation sCondi	];
			lSRCNAME{s-1}=[	fullPATH FileInfo.Src WORKNAME FileInfo.sExt ]; %�迭
		end
		% �������� file���� ������
		WORKNAME	=[	char(lSubj{1}) Regulation sCondi	];

	elseif iscell(lSubj) && length(lSubj)<=2
		% ��� ������ 2����, ����=�ҽ� �̹Ƿ�, �׳� ���� ����ó�� ó�� ����
		WORKNAME	=[	char(lSubj{2}) Regulation sCondi	];
		lSRCNAME{1}	=[	fullPATH FileInfo.Src	WORKNAME FileInfo.sExt	];%only 1

		% �������� file���� ������
		WORKNAME	=[	char(lSubj{1}) Regulation sCondi	];

	else	%���� ���ϸ��� ���
		WORKNAME	=[	char(lSubj) Regulation sCondi	];
		lSRCNAME{1}	=[	fullPATH FileInfo.Src	WORKNAME FileInfo.sExt	];%only 1
	end

%		hEEG.FileInfo.WORK	=	WORKNAME;		% �����̸� �� ����

	% ���� ��� ���ϸ� ����
%		OUT_NAME	=[	fullPATH FileInfo.Dest	WORKNAME '.mat' ];
		OUT_NAME	=[	fullPATH FileInfo.Dest	WORKNAME					...
						'_' num2str(MkStim) '_' num2str(mkResp) '.txt' ];
%		hEEG.FileInfo.OutFile	=	OUT_NAME;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%check result file & skip analysis if aleady exists.
%	fprintf('\nChecking: Analyzed result file: ''%s''...',[OUT_IMAG '.jpg']);
	fprintf('\nChecking: Analyzed result file: ''%s''...', OUT_NAME);
%	if exist([OUT_IMAG '.jpg'], 'file') > 0					%exist !!
	if exist(OUT_NAME, 'file') > 0							%exist !!
		fprintf('exist! & SKIP analyzing this\n');
		continue;											%skip
	else
		fprintf('NOT & Continue the Analyzing\n');
	end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	AllTime			=	tic;		%������ preparing �ð��� �����Ѵ�.
	fprintf('--------------------------------------------------\n');
	fprintf('Convert : %s''s [VMRK] to Response on WORKSPACE.\n', WORKNAME);
	%'\n'���ϴ� ������ �Ʒ��� toc ����� ���� �پ���� �Ϸ���.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% merging ���: ���� SubjInfo.Inlier �� �� cell�� �ټ� ���� subj 
%	�̸��� ��� �ִٸ�, �̵��� ������� �о, �ϳ��� �����ͷ� ��ħ
%	epoch �������� concatenate �ؾ� ��.
	eMRK			=	{;};								% empty 2D array
	eEEG			=	[;;];								% empty 3D array
	for s			= 1 : length(lSRCNAME)					% �ݵ�� cell array��
		SRC_NAME	=	lSRCNAME{s};
		hEEG.FileInfo.InFile	=	SRC_NAME;

		%check & auto skip if not exist a 'dat file.
		fprintf('Checking: Source file: ''%s''... ', SRC_NAME);
		if exist(SRC_NAME, 'file') <= 0						%skip
			fprintf('not! & SKIP converting this\n\n');
			continue;										%exist !!
		else
			fprintf('EXIST & Continue the converting\n\n');
		end

%%-------------------------------------------------------------------------------
% Convert: VMRK@EEG -> Response
% -------------------------------------------------------------------------------
		% VMRK ������ �����Ѵ�.
		fVmrk		=	regexprep(SRC_NAME, '.[A-Za-z]*$', '.vmrk');
%		eval(['Fp	=	fopen(''' fVmrk ''',''r'');']);
%		if Fp < 0, ChanList = []; SDP = 0; fSmpl = 0; return; end
%		fprintf('Generating VHDR file to %s\n', fvhdr);

		lTGR		=	bva_readmarker(fVmrk);

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%%%% ��꿡 �ռ�!, Ʈ���� �ڵ� �� �������ڵ�(�ð������� �Ұ����ϰ� ��ŷ�Ǵ�)��
%% ���� �����ؾ� ��.
%% �̶�, PRT ��Ʈ���� 8bit 2������ �ڵ尪�� �����ʿ� ����, �� bit-field ��
%% time overap �� ���� �߻������� ���������� ���� reasonable �� ���� ����!

		% 20151204A. ��� �������ڵ带 reasonable �� ��Ȳ�Ͽ��� �ǵ��� �� ��.
		%	1. �ð����� �Ұ��ɼ� ����� ��.
		%	2. bit-field ���տ��� �ǵ��� ��.
		% lTGR�� ����: (a,b) = ( marker, time )

		% ��Ŀ�� stim vs resp �� �������� �����鼭, �ð������� �Ұ����� ��� ����
		% �� ������ ������ �ΰ��� marker �̸�, stim�� 2�ڸ�+, resp�� 1 �ڸ� ��.
		if isnan(lTGR(1,1)), lTGR(1,1) = 0; end	% ù��° marker�� NaN ��!
%{
		Rm4Over		=	zeros(0);				% bit-field overalp ���� %-[
		Rm4Time		=	zeros(0);				% ���� ����
		for m = 2 : size(lTGR, 2)-1				% �� ó���� NaN !
		if 10 <= lTGR(1,m) & lTGR(1,m+1) <= 9	% stim 2�ڸ�+, resp 1�ڸ�
			if lTGR(2,m+1) - lTGR(2,m) <= 10	% ������ 10ms �̳�?
			% -----
			if bitor(lTGR(1,m-1), lTGR(1,m+1)) == lTGR(1,m) %bit�ʵ� overlap ����
				Rm4Over(end+1)	=	m;			% ������ �ε���
			elseif 10 <= lTGR(1,m-1)			% overlap����, �� �յ� stim ���
				Rm4Time(end+1)	=	m;			% ������ �ε���
			else								% overlap �ƴϰ�, �յ� stim X ?
				error('Error');
			end

%			else								% ���������� ���
%				lTGR(:,n+0)	=	lTGR(:,m-0);
%				lTGR(:,n+1)	=	lTGR(:,m+1);
			end

		end	% if stim ~ resp �ڸ���
		end	% for	%-]
%}
		% detection �Լ� ����
		fEpoch		=	@(m) ( 10 <= lTGR(1,m) & lTGR(1,m+1) <= 9 ); % stim~resp
		fNarrow		=	@(m) ( lTGR(2,m+1) - lTGR(2,m) <= 10 );	% ���� 10ms �̳�
		fOverlap	=	@(m) ( bitor(lTGR(1,m-1), lTGR(1,m+1)) == lTGR(1,m) );
		fContStim	=	@(m) ( 10 <= lTGR(1,m-1) & 10 <= lTGR(1,m) ); % ����stim

		m			=	2:size(lTGR, 2)-1;				% ��Ŀ �� ����

		Rm4Over		=	arrayfun(@(x) ( fEpoch(x)*fNarrow(x)*fOverlap(x) ), m);
		Rm4Over		=	find(Rm4Over)+1;				% m == 2 ���� ����

		Rm4Time		=	arrayfun(@(x) ( fEpoch(x)*fNarrow(x)*fContStim(x) ), m);
		Rm4Time		=	find(Rm4Time)+1;				% m == 2 ���� ����
		Rm4Time		=	find(~ismember(Rm4Over, Rm4Time));	% �ߺ� ����

		if length(Rm4Over) > 1
			fprintf('Detect  : #%d of MARKERs for bit-field overaping.\n',	...
				length(Rm4Over));
		end
		if length(Rm4Time) > 1
			fprintf('Detect  : #%d of MARKERs for too short timing.\n',		...
				length(Rm4Time));
		end
		lTgr		=	lTGR;
		lTgr(:,[ Rm4Over Rm4Time ] )	=	[];			% ������ ��Ŀ ����

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		% lTgr�� �����Ǿ����Ƿ�, stim ~ resp ��Ŀ ������ ��ü������ ã�Ƴ���.
		RT			=	bva_rt(lTgr, mkStim, mkResp, Freqs);	% reaction time

		% --------------------------------------------------
%		Timing		=	squeeze(lTgr(2,:));		% �ð������� ����
		lMkXResp	=	find(lTgr(1,:) <= 9 & lTgr(1,:) ~= mkResp);	% Ʋ��|miss
		lMkXResp	=	lTgr(1, lMkXResp);		%  ��Ŀ ��ȣ
%		InCr		=	bva_rt(lTgr, mkStim, mkInCr, Freqs);	% reaction time
%		Miss		=	bva_rt(lTgr, mkStim, mkMiss, Freqs);	% reaction time
		XRT			=	arrayfun(@(x)({bva_rt(lTgr,mkStim,x,Freqs)}), lMkXResp);
		XRT			=	cell2mat(XRT);
%		[RT, SD, n]	=	RT(mrk, [101 1], [13 ...])

		% --------------------------------------------------
%		ER			=	ErrRt(lTgr, [101 1], [2,3,...]); % [ ]��: % incor, miss
		% ����: correct / (correct + incorrect + missing )
		%		correct: [ 101 1 ]
		%		incor  : [ 101 2 ]
		%		missing: [ 101 3 ]
		ER			=	length(RT) / (length(RT) + sum(XRT));

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		% RT, ER �� �������Ƿ�, ������ ������� �������.
		fprintf(['Results : %s''s Reaction Time(s:%d vs r:%d) = #%d\n',		...
				'& Error Rate = %.2f\n\n'],OUT_NAME,mkStim,mkResp,length(RT),ER);
%		for r = 1 : length(RT), fprintf('%3dth Trial''s RT = %4d\n',r,RT(r)); end

		XLS			=	fopen(OUT_NAME, 'w');			% txt �� ���
		for r = 1 : length(RT)
			fprintf(XLS, '%d\n', RT(r));
		end
			fprintf(XLS, '%f\n', ER);
		fclose(XLS);

	end % for s

end	% for sub
end	% for data
