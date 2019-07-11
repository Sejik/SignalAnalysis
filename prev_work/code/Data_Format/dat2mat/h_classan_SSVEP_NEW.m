function [ hEEG ] = A_global_AmH()
%--------------------------------------------------------------------------------
%% project�� parameter�� ����: �����Ϳ��� feature, classification
%--------------------------------------------------------------------------------

	%% initialize variables
	% the experiment condition that is to be classified
	hEEG.Condi		=	{ 'TopDown', 'Intermediate', 'BottomUp', };
	%----------------------------------------------------------------------------
	hEEG.SmplRate	=	500;								% sampling rate
	fBin			=	1/2;
	hEEG.FreqBins	=	fBin;								% freq step

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
	%----------------------------------------------------------------------------
	% COI == class of interest, ( == stimulus frequency)
		COIbase1st	=	{ [5] [7] [6] [6] [7] [5] };
		COIbase2nd	=	{ [7.5] [5.5] [5.5] [7.5] [6.5] [6.5] };
%		COIbase		=	{ [5 7.5] [5.5 7] [5.5 6] [7.5 6] [6.5 7] [6.5 5] };
		COIbase		=	cellfun(@(x,y)({ [x y] }), COIbase1st, COIbase2nd);%����
		COIbaseBT	=	{ [5] [6] [7] [5.5] [6.5] [7.5] };			% bottom up��
%		COIsum		=	{ [5+7.5] [7+5.5] [6+5.5] [6+7.5] [7+6.5] [5+6.5] };
		COIsum		=	cellfun(@(x,y)({ [x+y] }), COIbase1st, COIbase2nd);%����
%		COIbs_sum	=	{ [5 7.5 5+7.5] [7 5.5 7+5.5] [6 5.5 6+5.5] ... %{base+%}
%						  [6 7.5 6+7.5] [7 6.5 7+6.5] [5 6.5 5+6.5] };	% harmon
%		COIBsSm		=	cellfun(@(x,y)({ [x y] }), COIbase, COIsum);  % base+sum
		COIharm1st	=	cellfun(@(x)({ x*2 }), COIbase1st);				% harmon
		COIharm2nd	=	cellfun(@(x)({ x*2 }), COIbase2nd);				% harmon
%		COIharm		=	cellfun(@(x)({ x*2 }), COIbase);				% harmon
		COIharm		=	cellfun(@(x,y)({ [x y] }), COIharm1st, COIharm2nd);%����
		COIharmBT	=	cellfun(@(x)({ x*2 }), COIbaseBT);				% harmon
		COIBsHm1st	=	cellfun(@(x,y)({ [x y] }), COIbase1st, COIharm1st);%1st��
		COIBsHm2nd	=	cellfun(@(x,y)({ [x y] }), COIbase2nd, COIharm2nd);%2nd��
		COIBsHm		=	cellfun(@(x,y)({ [x y] }), COIbase, COIharm); % base+harm
		COIBsHmBT	=	cellfun(@(x,y)({ [x y] }), COIbaseBT, COIharmBT);
		COIBsHmSm	=	cellfun(@(x,y,z)({ [x y z] }), COIbase, COIharm, COIsum);
	% COI�� �� ���� �ڱ� ������ŭ ��Ҹ� ��������. ���� 2���� cell type ����
%	hEEG.COI		=	{ COIBsHm };

	% 20160223A. CCA���� bottom-up�� �ѹ��� 1���� ���ļ�(1st harmonic�� �ش�
	%	���ļ���)�� �� �� ����. ���� ���, '��' �� ���� 5Hz(�׸��� 10) �� �� ��
	% �̿� ���� ������ ����, top down, intermediate, bottom up ���� COI�� ����
	%	�����ؾ� ��.
%		COI_topdown	=	{ COIBsHmSm };
%		COI_intermdt=	{ COIBsHmSm };
%		COI_bottomup=	{ COIBsHmBT  };
	% COI�� �� ���� �ڱ� ������ŭ ��Ҹ� �������ϰ�, ���� �������Ǻ��� ���� ����.
	% ���� 3���� cell type ����
%	hEEG.COI		=	{ COI_topdown, COI_intermdt, COI_bottomup };
	hEEG.COI		=	{ COIBsHmSm, COIBsHmSm, COIBsHmBT };

	%----------------------------------------------------------------------------
	% FOI == band of interest
		%% 10:0.5:15 �� first harmonic && ���ο� ������ ���ļ� �� ����!
		%% �ٸ� ���: ����+���� ���ļ� �� only , �׸��� �� only
	if isfield(hEEG, 'COI')									% COI ����->��� ����
		%%[20160221A ����] COI�� CCA�� ���� �����Ǵ� ���̱⵵ �ϸ�, �� ���,
		% �� marker�� �����ϴ� freq�� �Ҵ�ǹǷ�, f ������ marker ���� ��ġ�Ѵ�.
		% -> ��, sparse ���ļ� �м��� ����
		% �̿� �޸�, LDA ������ ���� ���ļ� ������ �Ҵ� �� �� �����Ƿ�,
		% - �׷��� � ���ļ��� ����� �ִ��� ���� ���� �ϴ�.
		% -> sparse �Ӹ� �ƴ϶�, whole ���ļ� �м��� �����ϴ�.
		%
		% �̷� ������, COI�� ������ ���� �м���, LDA�� sparse �м��� ������
		%	COI�� 2D ������ cell �̹Ƿ�, flatten ���Ѿ� ��.
%		hEEG.FOI=cellfun(@(x)({unique(table2array(cell2table(x)))}),hEEG.COI{1});
		% sparse COI : whole FOI ����
%		hEEG.FOI	=	{ [min(hEEG.FOI{1}):fBin:max(hEEG.FOI{1})] };

		% FOI�� COIó�� ���Ǻ��� ���� ����
%		hEEG.FOI		=	cellfun(@(y)({	...
%			cellfun(@(x)({unique(table2array(cell2table(x)))}),y) }), hEEG.COI);
		% sparse COI : whole FOI ����, 2D cell ����
%		hEEG.FOI	=	cellfun(@(y)({	...
%			cellfun(@(x)({ [min(x):fBin:max(x)] }), y) }), hEEG.FOI);

		hEEG.FOI	=	{ [5:fBin:13.5] };
	else
		FOIbase		=	[ 5:fBin:7.5 ];
		FOIsum		=	[ 5+7.5 5.5+7 5.5+6 7.5+6 6.5+7 6.5+5 ];
		FOIharmonic	=	[ FOIbase(1)*2:fBin:FOIbase(end)*2 ];
		FOIcombi	=	[ FOIbase*2 FOIsum ];
		FOIext		=	[ FOIbase FOIsum];
		FOImul		=	[ 5*7.5 5.5*7 5.5*6 7.5*6 6.5*7 6.5*5 ];
%		FOImul		=	[ 20 22 24 26 28 30 ];
%		hEEG.FOI	=	[ unique(FOIsum) unique(FOImul) ];
%		hEEG.FOI	=	{ [FOIbase] [unique(FOIsum)] [unique(FOImul)] };
%		hEEG.FOI	=	{ [FOIbase] [unique(FOIsum)] };
%		hEEG.FOI	=	{ [FOIbase] };
%		hEEG.FOI	=	{ [unique(FOIharmonic)] };
%		hEEG.FOI	=	{ [FOIbase] [unique(FOIcombi)] };
%		hEEG.FOI	=	{ [FOIbase] [unique(FOIext)] };
%		hEEG.FOI	=	{ [FOIbase] [unique(FOIsum)] [unique([FOIbase FOIsum])]};
		hEEG.FOI	=	{ [unique([FOIbase FOIsum])] [5:fBin:13.5] };
		% FOI�� COIó�� ���Ǻ��� ���� ����
%		hEEG.FOI	={	{ [unique([FOIbase FOIsum])] [5:fBin:13.5] } ...
%						{ [unique([FOIbase FOIsum])] [5:fBin:13.5] } ...
%						{ [unique([FOIbase FOIsum])] [5:fBin:13.5] } };
						% 3rd cell: 5 ~ 13.5Hz �� ����ü�� : 20160201A
	end
	%----------------------------------------------------------------------------
	hEEG.sFOI		=	{							...
'over stimulation frequencies',						...
'over sum combination of stimulation frequencies',	...
'over base+sum combination of stimulation frequencies',	...
						};		% FOI matched string
%'over first harmonics of stimulation frequencies',	...
%'over multiple combination of stimulation frequencies',	...
%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%	hEEG.FreqWindow	=	[2, 50];							% or [4, 30]
	hEEG.FreqWindow	=[min([4 cell2mat(hEEG.FOI)]), max([30 cell2mat(hEEG.FOI)])];
%	hEEG.FreqWindow	=	cellfun(@(y)({	...
%arrayfun(@(x)({[min([4 cell2mat(x)]),max([30 cell2mat(x)])]}), y) }), hEEG.FOI);
	%----------------------------------------------------------------------------
%	hEEG.DataPoint	=	5000 * nFolds * Stimulus;			% �������� �� ����
%	hEEG.TimeWindow	=	[0, 5000];			% 0~5000msec
	hEEG.tInterval	=	[-2000, 5000];						% -2000~5000msec
%%	hEEG.tInterval	=	[0, 5000];							% 0 ~ 5000msec
	hEEG.TimeWindow	=	[0, 5000];							% 0 ~ 5000msec
%	hEEG.OverlapWin	=	0;	% 200, �� ��ȣ�� �� ��ȣ ������ ��ħ time point ����
	%----------------------------------------------------------------------------
	hEEG.fFolds		=	{ [1:4] };							% 4 session file
%%	hEEG.fFolds		=	{ [1 2] [3 4] };					% 4 session 2 cat
%	hEEG.fFolds		=	{ [1] [2] [3] [4] };				% 4 session each
%%	hEEG.fFolds		=	arrayfun(@(x)({ [x] }), [1:4]);		% 4 session each
	%% 20160302A. ���ο� �õ��� ���� ���� ������ fold data ������
	%				�м� �Ķ���ͷμ��� nfold ���� �и��Ͽ� ����
	hEEG.nFolds		=	10;									% 4 session
%	hEEG.nFolds		=	16;									% �ι�� ����
%	hEEG.fgFolds	=	0;									% ���� ��� ��ħ?
	hEEG.nChannel	=	30;									% ���� �� �� ä�� ��
	hEEG.ChSide		=	{	'EOG'	};						% �ΰ����� �м���
	hEEG.Chan		=	{	'O1',	'Oz',	'O2',	hEEG.ChSide{:},	};
%{
	hEEG.ChRemv		=	{	'not',	'NULL*',	};			% ���ʿ� ä��
	hEEG.ChRemv		=	{	'not',	'NULL*',	'*EOG*'	};	% ���ʿ� ä��
	hEEG.ChRemv={		'not',	...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
						'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
				% EOG �� ��� ����, �������� ��� ���� (�� ó���� �� 'not' �ޱ�)
	hEEG.ChRemv={		'not',	...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
						'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',			'O2',	'PO10' };
				% Oz ��� ����, ������ ��� ����(�� ó���� �� 'not' �ޱ�)
	hEEG.ChRemv={		'not',	...
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
						'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',							'PO10' };
				% O1, Oz, O2 ��� ����, ������ ��� ����(�� ó���� �� 'not' �ޱ�)
%}

	hEEG.PATH		=	'/home/minlab/Projects/SSVEP_NEW/SSVEP_3';
	hEEG.Src		=	'eEEG';
	hEEG.Dest		=	fullfile(hEEG.PATH, 'Results');
	% accuracy : hEEG.Dest/decoding_accuracy/ �� ���
	% pattern  : hEEG.Dest/classifier_patterns/ �� ���
	% fft power: hEEG.Dest/power_spectra/ �� ���

%	all_list		=	1:33;							% list of subject indices
	if exist(fullfile(hEEG.PATH, hEEG.Src))
%		[lAllSbj, Head, Common]=S05sbjlist_AmH([hEEG.PATH '/eEEG.Inlier/']);
%		[lAllSbj, Head, Common, FileExt]=S05sbjlist_AmH([hEEG.PATH '/eEEG/']);
	[lAllSbj, Head,Common, FileExt] = S_sbjlist(fullfile(hEEG.PATH, hEEG.Src));
	else
	[lAllSbj, Head,Common, FileExt] = S_sbjlist(fullfile(hEEG.PATH, '/Export/'));
	end
	hEEG.Head		=	Head;
	hEEG.Allier		=	cellfun(@(x)({x{1}}), lAllSbj);	% 1st ��Ҹ� ����
%exc_list	=	[ 2 5 7 9 14 15 16 17 21 25 26 27 28 32 ];	% list for exclude
	hEEG.Outlier	=	{ };	% { 'su0002', };
	hEEG.Inlier		=	hEEG.Allier(find(~ismember(hEEG.Allier, hEEG.Outlier)));
%		Allier	: ��� ������ ���, ex:{ { 'su0001, 'su0001, 'su0001_1' },...}
%		Outlier	: ���� ���, ex: { 'su0001', 'su0002', ... }

	return

