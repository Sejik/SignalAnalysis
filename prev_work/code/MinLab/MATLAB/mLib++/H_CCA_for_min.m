function [ ] = H03CCA_for_min( )
%% test for CCA

	verbose			=	1;

	%----------------------------------------------------------------------------
	%% COI == CCA freq. Of Interesting
	%% COI�� �� ���� �ڱ� ������ŭ ��Ҹ� ��������. ���� 2���� cell type ����
	%% �Ʒ��� 3�ٸ� �����ϸ� ��. ���Ĵ� �ڵ����� �����ϴ� �ڵ�.
	COIbase1st		=	{ [5]	[7]   [6]	[6]   [7]   [5] };		% top/inter��
	COIbase2nd		=	{ [7.5] [5.5] [5.5] [7.5] [6.5] [6.5] };	% top/inter��
	COIbaseBT		=	{ [5] [6] [7] [5.5] [6.5] [7.5] };			% bottom up��

%		COIbase		=	{ [5 7.5] [5.5 7] [5.5 6] [7.5 6] [6.5 7] [6.5 5] };
		COIbase		=	cellfun(@(x,y)({ [x y] }), COIbase1st, COIbase2nd);%����
%		COIsum		=	{ [5+7.5] [7+5.5] [6+5.5] [6+7.5] [7+6.5] [5+6.5] };
		COIsum		=	cellfun(@(x,y)({ [x+y] }), COIbase1st, COIbase2nd);%����
%		COIbs_sum	=	{ [5 7.5 5+7.5] [7 5.5 7+5.5] [6 5.5 6+5.5] ... %{base+%}
%						  [6 7.5 6+7.5] [7 6.5 7+6.5] [5 6.5 5+6.5] };	% harmon
%		COIBsSm		=	cellfun(@(x,y)({ [x y] }), COIbase, COIsum);  % base+sum
		COIharm1st	=	cellfun(@(x)({ x*2 }), COIbase1st);				% harmon
		COIharm2nd	=	cellfun(@(x)({ x*2 }), COIbase2nd);				% harmon
		COIharm		=	cellfun(@(x,y)({ [x y] }), COIharm1st, COIharm2nd);%����
		COIharmBT	=	cellfun(@(x)({ x*2 }), COIbaseBT);				% harmon
		COIBsHm1st	=	cellfun(@(x,y)({ [x y] }), COIbase1st, COIharm1st);%1st��
		COIBsHm2nd	=	cellfun(@(x,y)({ [x y] }), COIbase2nd, COIharm2nd);%2nd��
		COIBsHm		=	cellfun(@(x,y)({ [x y] }), COIbase, COIharm); % base+harm
		COIBsHmBT	=	cellfun(@(x,y)({ [x y] }), COIbaseBT, COIharmBT);
		COIBsHmSm	=	cellfun(@(x,y,z)({ [x y z] }), COIbase, COIharm, COIsum);

	% COI�� �� ���� �ڱ� ������ŭ ��Ҹ� �������ϰ�, ���� �������Ǻ��� ���� ����.
	% ���� 3���� cell type ����
	COILIST			=	{ COIBsHmSm, COIBsHmSm, COIBsHmBT };% top, int, bot ����
	%----------------------------------------------------------------------------
	SmplRate		=	500;								% sampling rate
%	FreqWindow		=	[min([4 cell2mat(BOI)]), max([30 cell2mat(BOI)])];
	FreqWindow		=	[4, 30];
	TimeWindow		=	[0, 5000];			% 0~5000sec
%	OverlapWin		=	0;	% 200, �� ��ȣ�� �� ��ȣ ������ ��ħ time point ����
	%----------------------------------------------------------------------------
	nFolds			=	4;									% 7 session
	nChannel		=	30;									% ���� �� �� ä�� ��

	ChRemv			={		'not',	...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
						'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',							'PO10' };
				% O1, Oz, O2 ��� ����, ������ ��� ����(�� ó���� �� 'not' �ޱ�)
	ChSide			=	{	'EOG'	};						% �ΰ����� �м���
	%----------------------------------------------------------------------------
	PATH			=	'/home/minlab/Projects/SSVEP_NEW/SSVEP_2';
	[Head, Common, lAllSubject] = S03sbjlist_AmH([PATH '/eEEG.Inlier/']);
	Head			=	Head;
	Allier			=	cellfun(@(x)({x{1}}), lAllSubject);	% 1st ��Ҹ� ����
	Outlier			=	{ };	% { 'su0002', };
	Inlier			=	Allier(find(~ismember(Allier, Outlier)));
	%----------------------------------------------------------------------------
	Condi			=	{ 'TopDown', 'Intermediate', 'BottomUp', };

	%% ���ǿ� ���� CCA �м� ����
for cond			=	1 : length(Condi)
	fprintf('COI for %s : -----\n', Condi{cond});
	cellfun(@(u,v)(fprintf('\t%d: %s\n', u, v)), arrayfun(@(x)({x}), [1:6]),...
	cellfun(@(x)({strjoin(arrayfun(@(y)({num2str(y)}),x),', ')}),COILIST{cond}));
	pause(1);												% 1�ʰ� ���
	sCondi			=	Condi{cond};

	%% data�� loading & concatination
	epos			=	cell(1,length(Inlier));				% data ����
	parfor ix 	= 1:length(Inlier)
		fprintf('loading subject %s\n', Inlier{ix})

		epos{ix}	=	load_Min_KU_data_new_format( PATH,					...
						Head,		Inlier{ix},		sCondi,					...
						nFolds,		FreqWindow,		TimeWindow,				...
						SmplRate,	nChannel,		verbose);

		% take only the scalp channels, remove EOG channels
		% ��쿡 ���󼭴� EOG �����Ͽ� ���
		epos{ix}	=	proc_selectChannels(epos{ix}, ChRemv);

		% high pass filter
		db_attenuation	=	30;
		hp_cutoff	=	1;
		[z,p,k]	=	cheby2(4, db_attenuation, hp_cutoff/(epos{ix}.fs/2),'high');
		epos{ix}	=	proc_filt(epos{ix}, z,p,k);
	end

	%----------------------------------------------------------------------------
	% the experiment cond that is to be classified
	sbj_list	=	Inlier;
	n_subjects	=	length(sbj_list);
	save_figs	=	1; % save figures or not

	%% �Ķ���ͷ� ���� �����Ͱ� EOG�� ������ �������� ���, EOG �����͸� �и��ؼ�
	%	������ ������ ��. ���� ���� �����Ϳ��� EOG�� ���� �� ��.
	if length(find( ismember(epos{1}.clab, ChSide) )) > 0	% EOG �߰� ��.
		SdPos	=	find( ismember(epos{1}.clab, ChSide));
		ChPos	=	find(~ismember(epos{1}.clab, ChSide));

		eOrg	=	epos;
		eSide	=	eOrg;

		for sbj_idx=1:n_subjects
		eSide{sbj_idx}.clab	=	ChSide;						% label ����
		eSide{sbj_idx}.x	=	epos{sbj_idx}.x(:,SdPos,:);	% EOG �����͸�

		epos{sbj_idx}.clab	=	eOrg{sbj_idx}.clab(ChPos);	% EOG ����
		epos{sbj_idx}.x		=	eOrg{sbj_idx}.x(:,ChPos,:);	% EOG ���� data
		end

		clear eOrg
	end

	%% compute canonical correlation analysis (CCA) accuracy
	fprintf('\n\n --- starting canonical correlation analysis ---\n\n')

	%condition�� ����, COI�� �����ؼ� �����ؾ� ��
%	ixCond		=	find(ismember(Condi, cond));
%	loss_cca	=	zeros(1,n_subjects);

	for sbj_idx = 1:n_subjects
		fprintf('processing sbj %02d/%02d\n', sbj_idx, n_subjects)

%		[ loss_cca(sbj_idx), ~, ~]	=	H03CCA_AmH(epos{sbj_idx}.x,			...
%						epos{sbj_idx}.fs, epos{sbj_idx}.mrkseq, COI{ixCond});

%		fprintf(' -> loss CCA = %g\n', loss_cca(sbj_idx))
%	end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	%% CCA �� �����Ͽ� AllBOI{B} �� ���� ���ļ��� �����ϴ� ��Ī ���� �ľ�
	%% classes �� �ִ밪�� marker �� ��ġ�� ������ ���� accuracy ���
	x				=	epos{sbj_idx}.x;
	fs				=	epos{sbj_idx}.fs;					% sampling rate
	MRKseq			=	epos{sbj_idx}.mrkseq;
	COI				=	COILIST{cond};
	
%function [ loss, loss4Chan, corr4Chan ] = H03CCA_AmH(x, fs, MRKseq, COI)
% ���	: SSVEP, PFC ���� ���� canonical corelation analysis ����
% param	: x(tp x ch x ep), twin, marker_seq, cell(stim), cell(class of interest)
% return:	loss ( loss rate)
%			loss4Chan ( loss rate for each channel * epoch dimension )
%			corr4Chan ( class marker for each channel * epoch dimension )

	%% marker�� �����ϴ� ���ļ��� stimulus �� ��������.
	% eEEG(x) ����: tp x ch x epoch
%	sigLen			=	size(x, 1)*size(x, 3);	% tp * epoch
	class			=	sort(unique(reshape(MRKseq, [1], [])));

	%% do check equality b/w # of class and # of COI
	if length(class) ~= length(COI)
		fprintf('Warning  : mismatch length b/w class(%d) & stimulus(%d)\n', ...
				length(class), length(COI));
	end

	%% reference �ۼ�
	t				=	[1/fs : 1/fs : size(x,1)/fs];	% time series of 1 epoch
	wvPacket		=	zeros(length(class), 2*length(COI{1}), length(t));

	for c = 1 : length(class)							% class ��
	for f = 1 : length(COI{c})							% stim freq ��
		fprintf('Stimulus: freq(%5.2f) for %dth class & %dth stim\n',		...
				COI{c}(f), c, f);
		wvPacket(c,f*2-1,:) =	sin(2*pi * COI{c}(f) * t);
		wvPacket(c,f*2-0,:) =	cos(2*pi * COI{c}(f) * t);
	end
	end

	%% reshape proper structure for x data
	eEEG			=	reshape(x, [length(t)],[]);	% tp(1time) x alldata

	%% run CCA for all time
	% ��ü ch*ep(== whole tp) ������ ���� CCA�� �����Ѵ�.
	dataLen			=	size(x, 2) * size(x, 3);
	corr			=	zeros(length(class), dataLen);	%st x (ch*ep)
	for c = 1 : length(class)						% �� class(�ڱ�)
		CCAdata		=	zeros(1, [ size(corr, 2) ]);		% 1D data
	parfor d = 1 : dataLen									% ch * ep��, ��data
%		[A, B, corr(c,d), U, V] = canoncorr(eEEG(:,d), wvPacket(c,:,:)');
%		wvUnit		=	squeeze(wvPacket(c,:,:));			% stim x tp(1time)
		[~,~,CCAdata(d),~,~] = canoncorr(eEEG(:,d), squeeze(wvPacket(c,:,:))');
	end
		corr(c,:)	=	CCAdata;
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% �� ��������, corr ���� �� class(stimulus)���� ��ü ch*ep ���� �� ix��
	% CCA ���� �غ�Ǿ� �ִ�. �׷���, ���� �������� ����, �� ch(�� tp����)�� ����
	% �� �ϳ��� stimulus�� �־��� ���̱� ������, ���� ���� class �� �ϳ�����
	% �����ؾ� �Ѵ�.
	% 1. ����, �ִ밪�� ���� class�� ��������.
	%	�׸���, �� �� ���õ� class�� ��ü �� ep ix ���� �ٸ� �� �ִ�.
	%	�ֳ��ϸ�, �� ep ix ���� ����� �ٸ� �ڱ��� randome�ϰ� �־��� �����̴�.
	% 2. ��, �� ä�θ��� �ٸ� class�� ������ ���� �����̹Ƿ�, �� ep ix�� ����
	%	ä�� ��ü�� ���� �ִ�󵵷� ������ class�� ���� �����ؾ� �Ѵ�.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% ä�� �и� ���� 2D -> 3D
	mxClsf			=	reshape(corr, length(class),size(x,2),[]);

	%% investigate matching rate b/w each classes & marker
	% 1st: average all chan
	% 2nd: calc max for one of classes
	% 3rd: match classes vs marker

%	mxClsf			=	mxClsf(:,[20 21 22 23],:);			% Ư�� ä�θ� ����

	%% �� ep ix(tp ����) �� ���� ä�κ� �ִ밪 CCA ���
	% ������� ��� : mxClsf ���� : 6 x 30 x 240 -> 30 x 240
	[mxCCAch mxChIx]=	max(mxClsf, [], 1);					% class ���� ��� max
	[mxCCAch mxChIx]=	deal(squeeze(mxCCAch), squeeze(mxChIx));	% ���� ����
	% �̶�, mxIx ���� �� ch*ep ix ���� �ִ밪�� ������ class ��, marker�� ����!
	% ix ���� 1 ~ 6���� ��ġ�� �ٵ�, �̰��� marker�� naming ������ ��ġ��.
	corr4Chan		=	mxCCAch;

	%% ix �� marker ���� ������ ���� hit ���� ���
	mrkseq			=	mod(MRKseq, 10);						% 1�ڸ��� ����
	mrkseqCh		=	repmat(mrkseq, [ size(mxChIx, 1) ], 1); %ch��ŭ Ȯ��
	loss4Chan		=	mean(mxChIx(:) ~= mrkseqCh(:));		% 1D ���� miss��
	fprintf('%s/%s have accuracy(chan) = ', Condi{cond}, Inlier{sbj_idx});
	fprintf('%f\n', 1 - loss4Chan);

	%% ���� �� ep ix ���� ���� class (ä�� ��ü ������ �ִ밪) �� ����
	[mxCCA mxIx]	=	max(mxCCAch, [], 1);				% chan ���� ��� max
	[mxCCA mxIx]	=	deal(squeeze(mxCCA), squeeze(mxIx));% ���� ����
%	for x = 1:length(mxIx), mxIx2(x) = mxChIx(mxIx(x), x); end % ep�� mx ch�� cl
	mxIx			=	arrayfun(@(x,y)( mxChIx(x,y) ), mxIx, [1:length(mxIx)]);
	loss			=	mean(mxIx ~= mrkseq);				% 1D ���� miss��
	fprintf('%s/%s have accuracy( all) = ', Condi{cond}, Inlier{sbj_idx});
	fprintf('%f\n\n', 1 - loss);

	end
end

	return

%--------------------------------------------------------------------------------

function epo = load_Min_KU_data_new_format(path, com, sbj, cond,			...
								n_blocks, fwin, twin, fs, nchan, verbose)	%-[
% Loads all trials of the requested condition (1, 2, or 3) of the data provided
% by Byoung-Kyong Min from Korea University (KU).

%% params

% HERE YOU HAVE TO SPECIFY THE FOLDER THAT CONTAINS THE SUBJECT DATA
%data_folder = '/home/sven/data/Data/BBCI_data/SSVEP_Min/SSVEP_NEW_Format/';
data_folder = [ path '/eEEG.Inlier/' ];

if nargin < 4,	verbose = 0; end
if ~isempty(com) & isempty(regexp(com,  '.*_$')), com =[ com   '_']; end % ��'_'+
if ~isempty(cond)&isempty(regexp(cond,'.*_$')), cond=[cond '_']; end

%% load the data
epo = [];
for block_idx=1:n_blocks

    %% create the filename and load the data of the current block
%	file_name = sprintf('SSVEP_NEW_su%04d_%s_%d.mat', ...
%						sbj, cond, block_idx);
	file_name = sprintf('%s%s_%s%d.mat', com, sbj, cond, block_idx);
%	sbj_folder = sprintf('su%02d', sbj);

    if verbose
        fprintf('loading %s\n', file_name)
    end
%    dat = load(fullfile(data_folder, sbj_folder, file_name));
    dat = load(fullfile(data_folder, file_name));

    %% create class labels that match the BBCI toolbox format
    y = dat.eMRK;
    unique_markers = unique(y);
    n_classes = length(unique_markers);
    n_trials = length(y);
    labels = zeros(n_classes, n_trials);
    className = cell(1,n_classes);
    for c=1:n_classes
        labels(c, y==unique_markers(c) ) = 1;
        className{c} = sprintf('stimulus %d',c);
    end

    %% create the epoched data structure that matches the BBCI format
if nchan + 1 == 31					% 30 + EOG
	clab	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',			'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
elseif nchan + 1 == 64				% 63 + EOG
	clab	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'FCz',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',  'PO10',...
				'AF7',	'AF3',	'AF4',	'AF8',	'F5',	'F1',	'F2',	'F6', ...
				'FT9',	'FT7',	'FC3',	'FC4',	'FT8',	'FT10',	'C5',	'C1', ...
				'C2',	'C6',	'TP7',	'CP3',	'CPz',	'CP4',	'TP8',	'P5', ...
				'P1',	'P2',	'P6',	'PO7',	'PO3',	'POz',	'PO4',	'PO8' };
end

%--------------------------------------------------------------------------------
	epo_tmp				= [];
	epo_tmp.clab		= clab;
%	epo_tmp.band		= [4, 50];
%	epo_tmp.band		= [ 5, 7.5 ];	%[ 11.5, 13.5 ], [ 33, 45.5], [4, 50];
%	epo_tmp.band		= [ 11.5, 13.5 ];		%, [ 33, 45.5], [4, 50];
%	epo_tmp.band		= [ 33, 45.5];
	epo_tmp.band		= fwin;
	epo_tmp.fs			= fs;

	tidx				= [twin(1)*(fs/1000)+1:twin(2)*(fs/1000)];	%index����
%	epo_tmp.t			= (1:2500)/500;
	epo_tmp.t			= tidx / fs;			% index �������� ���ø� �ð� ����
												% (1:2500)/500 , (1001:3000)/500;

%	epo_tmp.mrkseq		= dat.eMRK;				% eEEG�� epoch ���� ����
	epo_tmp.className	= className;			% �ڱ� ����
%	epo_tmp.x			= dat.eEEG;
	epo_tmp.x			= dat.eEEG(tidx,:,:);	% ��ȿdata�� ����, tp x ch x ep
	epo_tmp.y			= labels;				% class * trial

	mrkseq				=	dat.eMRK;
	if isfield(epo, 'mrkseq')					% marker �� append ����� ��
		mrkseq			=	[ epo.mrkseq mrkseq ];	% append
	end

	epo = proc_appendEpochs(epo, epo_tmp);
	epo.mrkseq			=	mrkseq;				% �߰� �� append �� ����
end

	return	%-]
