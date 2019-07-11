% R_tfstat ver 0.40
%% [�� �м��� ��� ����, ���� Ư�� ����/ä�ε�/���Ǻ��� max/min/mean �� ����]
%
% [*Input Parameter]--------------------------------------------------
% LoadPath	: �����Ͱ� ����� folder -> data file�� *_wxyz.mat ���� ��������
% SbjList	: subject list, string cell = { '02_2', '04', '07', ... };
% VarName	: name of variable, string type = 'TFe' : CAUTION : must be 3D
% tInterval	: �ð� ����, = [ -50 150 ], eEEG(tp)ũ��� ���� �����ϸ� eFS����
% tWin		: ���� �ð� ����, = [ 70 120 ], must small than tInterval
% cWin		: ���� ä�� ���,
% fInterval	: ���ļ� ���� = [ 1/4 70 ], eEEG(fq)ũ��� ���� �����ϸ� fBin����
% fWin		: ���� ���ļ� ����, = [ 5 30 ], must small than fInterval
% CondComb	: ���� ���� ���
%	ex) 'F__L' �� ���� ��ĥ ������ '_'���� ǥ��
%	ex) { 'FSH_', 'MA__' }
% Operation	: ������ ���� ���, 'max' | 'min' | 'mean' | 'MAX' | 'MIN'
%	ex) max : local max only, if not, nothing : <- default
%	ex) MAX : local max first, if not, global max next
%	ex) mean: ��� = ��հ�, �ð�(��տ� ���� �ٻ�ġ ����), ���ļ�(�ٻ�ġ)
% SavePath	: ���(txt�� list)�� ���� ��� �� ���� ��� ��
% blWin		: baseline correction �� ����, = [-400 -100]
%
% [*Output Parameter]--------------------------------------------------
% SavePath �� txt ���ϵ��� ����
%
% ex)
%R_tfstat('/home/minlab/Projects/SKK/SKK_3/TF', { 'su33', 'su07' }, 'TFe', [-500 1500], [ 0 500 ], { 'O2','P8', 'PO10' }, [1/4 70], [8 13], { 'F___', 'M___', 'U___' }, 'max', '/home/minlab/Projects/SKK/SKK_3/SPSS/TF', [-400 -100]);
%
%------------------------------------------------------
% first created at 2016/04/15
% last  updated at 2016/06/02
% by Ahn Min-Hee::tigoum@naver.com, Korea Univ. MinLAB.
%.....................................................
% ver 0.20 : 20160512C. amp, lat ���� txt ������ �и��Ͽ� ������ ��
% ver 0.30 : 20160602A. FastPeakFind()�� �̿��Ͽ� ���� ������ peak ã��
% ver 0.40 : 20160602B. �� ä�κ� peaks(min, max ���) ���� ��, Ž���� �͸� ���
%------------------------------------------------------

function [ ] = R_tfstat(	LoadPath,	SbjList,	VarName,	...
							tInterval,	tWin,		cWin,		...
							fInterval,	fWin,		...
							CondComb,	...
							Operation,	...
							SavePath,	blWin)

POOL			=	S_paraOpen();

eCHNs	=	{		...		% 30 ä�ΰ� 63 ä�� label �̸� ����
		{	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',	...
			'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8',	...
					'CP5',	'CP1',	'CP2',	'CP6',			'P7',	'P3',	...
			'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' }, ...
			...
		{	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',	...
			'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8',	...
					'CP5',	'CP1',	'CP2',	'CP6',	'FCz',	'P7',	'P3',	...
			'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',  'PO10',	...
			'AF7',	'AF3',	'AF4',	'AF8',	'F5',	'F1',	'F2',	'F6',	...
			'FT9',	'FT7',	'FC3',	'FC4',	'FT8',	'FT10',	'C5',	'C1',	...
			'C2',	'C6',	'TP7',	'CP3',	'CPz',	'CP4',	'TP8',	'P5',	...
			'P1',	'P2',	'P6',	'PO7',	'PO3',	'POz',	'PO4',	'PO8' },...
			};

if nargin <12,	blWin		=	[];	end
if nargin <11,	SavePath	=	'.';	end			% ���� folder
if nargin <10,	Operation	=	'max';	end			% �⺻ �ִ밪
if nargin < 9,	CondComb	=	{'____'};	end		% �⺻ �ִ밪
if nargin < 6,	cWin		=	eCHNs{1};	end		% ��� ä��
%if nargin < 5,	tWin		=	tInterval;	end		% interval �� �����ϰ�.
if 1<= nargin & nargin <=5,	error('# of parameter not enough');	end	% �ʹ� ����!
if nargin < 1										% �Ķ���� ������ �ڵ�����
%{
	LoadPath	=	'/home/minlab/Projects/SKK/SKK_3/TF';
%	LoadPath	=	'x:/Projects/SKK/SKK_3/TF';							%windows
	SbjList		=	{'su01','su02_2','su04_2','su06','su07', };
%	SbjList		=	{ '01', '02_2', '04_2', '06', '07', };
	VarName		=	'TFi';
	tInterval	=	[ -500, 1500 ];
	tWin		=	[ 0 1500 ];
	cWin		=	{ 'O1', 'Oz', 'O2' };
	fInterval	=	[ 1/4, 70 ];
	fWin		=	[ 5 13 ];
	CondComb	=	{ 'FSH_', 'MA__' };
	Operation	=	'max';
%	SavePath	=	'x:/Projects/SKK/SKK_3/Statis';						%windows
	SavePath	=	'/home/minlab/Projects/SKK/SKK_3/Statis/tfstat';
	blWin		=	[ -500 0 ];						% ERP: �Ϲ������� -500
%}
	LoadPath	=	'/home/minlab/Projects/EMO_NEW/EMO_1/TF';
	SbjList		=	{'su0027','su0029','su0030','su0037','su0039', };
	VarName		=	'TFe_bl';
	tInterval	=	[ -500, 2000 ];
	tWin		=	[ 0 500 ];
	cWin		=	{ 'O1', 'Oz', 'O2' };
	fInterval	=	[ 1/4, 70 ];
	fWin		=	[ 4 13 ];
	CondComb	=	{ 'R_H', 'WN_' };
	Operation	=	'max';
	SavePath	=	'/home/minlab/Projects/EMO_NEW/EMO_1/Statis/tfstat';
	blWin		=	[ -500 0 ];						% ERP: �Ϲ������� -500
end

clearvars -except	LoadPath SbjList VarName tInterval tWin cWin		...
					fInterval fWin CondComb Operation SavePath blWin eCHNs
close all;

%% notify %%
if exist('blWin', 'var') & ~isempty(blWin)			% �ɼǿ��� ���
	fprintf('+Option   : [%d ~ %d] baseline correction\n', blWin(1), blWin(2));
end

%% setting %%
% FSHL
% If there is no node, it should work.
% ���� ���������� �䱸�� �� �����Ƿ�, param�� type�� �ǵ��ؾ� ��.
if ~iscell(CondComb), CondComb	=	{ CondComb }; end
nCond			=	length(CondComb{1});			% ������ ����
SaveDir			=	regexprep(SavePath, '[^/]+$', '');	% dir �� ����
if ~exist(SaveDir, 'dir'), mkdir(SaveDir); end		% dir ���� ���� Ȯ��
% 20160411A. amp, lat ���� ������ ���� �ۼ��� ��.
% 20160512C. �� ���� ���� ����.
dtType			=	{ 'Pwr', 'Lat', 'Fq', };
%OUTNAME			=	sprintf('_[%s]Sbj%d,Cond%s.txt',			...
%							Operation, length(SbjList), strjoin(CondComb, ',') );
%OUTNAME			=	cellfun(@(x)({ sprintf('_Sbj%d-Cond%s-%s.txt',			...
%						length(SbjList), strjoin(CondComb, ','), x) }), dtType);
OUTNAME			=	cellfun(@(x)({ sprintf('_Sbj%d-%s.txt',			...
						length(SbjList), x) }), dtType);
%FP				=	fopen([SavePath OUTNAME], 'wt');% ���� ����
FP				=	cellfun(@(x)( fopen([SavePath x], 'wt') ), OUTNAME);%���ϻ���

% ȭ�鿡 �����͸� ����ؾ� �ϹǷ�, �켱 subject ���� ���� �Ѵ�.
%fprintf(FP,		'Subjects(%s)\t', Operation);		% ����ҿ� title ����
%fprintf(FP,		'%s', strjoin(	...
%cellfun(@(x)({sprintf('%-7s\t%-7s\t%-7s',[x '_pwr'],[x '_lat'],[x '_fq'])}), ...
%					CondComb), '\t') );
arrayfun(@(x)  ( fprintf(x, 'Subjects(%s)\t', Operation) ), FP);	% ���Ϻ� ���
arrayfun(@(x,y)( fprintf(x, '%s', strjoin(	...			% ���Ϻ�
	cellfun(@(x)({sprintf('%-7s',[x dtType{y}])}),CondComb),'\t'))), FP, [1:3]);
	%-----
stdout			=	1;								% ȭ�鿡 ���
fprintf(stdout, 'Subjects(%s)\t', Operation);
fprintf(stdout, '%s', strjoin(	...
cellfun(@(x)({sprintf('||%-7s\t| %-7s\t| %-7s',[x '_pwr'],[x '_lat'],[x '_fq']...
			)}),	CondComb), '\t') );
fprintf('\n--------------------------------------------------------------------------------');

Total			=	tic;							%��ü ���� �ð�
% ===============================================================================
	Statis		=	zeros(length(SbjList), length(CondComb));	% 2D
	Latency		=	zeros(length(SbjList), length(CondComb));	% 2D
	Frequency	=	zeros(length(SbjList), length(CondComb));	% 2D
for ixSJ		=	1 : length(SbjList)				% working base: subject
%	fprintf(FP,		'\n%-10s\t', sprintf('%s', SbjList{ixSJ}));	% ȭ�� ���
	arrayfun(@(x)( fprintf(x, '\n%-10s\t', sprintf('%s',SbjList{ixSJ})) ), FP);
	fprintf(stdout,	'\n%-10s\t', sprintf('%s', SbjList{ixSJ}));	% ȭ�� ���
%	FILENAME	=	sprintf('*_su%s_*.mat', SbjList{ixSJ});	% base form
	FILENAME	=	sprintf('*_%s_*.mat', SbjList{ixSJ});	% base form

% load path �� �ִ� ��� data�� �б� ����, �켱 condition �� ���ϸ� Ȯ��
	fName		=	ls(fullfile(LoadPath, FILENAME),'-1');%�ϳ��� ���ڿ��� �ö��
	fName		=	regexprep(fName, '[ ]+', '\n');	% ����и� �׸��� ���α���
	fName		=	strsplit(fName, '\n');			% ���Ϻ��� �и�
%	fName		=	dir([ LoadPath '/*_*.mat' ]);	% �ϳ��� ���ڿ��� �ö��
%	fName		=	struct2cell(fName);
%	fName		=	fName(1, :);					% �����̸���

% ===============================================================================
for ixCD		=	1 : length(CondComb)
	sCondi		=	CondComb{ixCD};					% ��ü ���� �� ���� ����

	% scondi �� �ش��ϴ� ���ϸ�ϸ� ����
%	rCondi		=	regexprep(sCondi, '[_]', '.');	% '_' -> '.' ���� ����
	rCondi		=	regexprep(sCondi, '[_]', '[^_]');	% '_' -> '.'(_ �ȵ�) ����
	ix			=	regexp(fName, ['.*_' rCondi '[.]mat'], 'match'); % match ����
	ix			=	cellfun(@(x)( ~isempty(x) ), ix);	% �� ������ �������
	ix			=	find( ix );						% ������ �ִ� ���� index ��
	GetName		=	fName( ix );					% �ش� ���ϸ� Ȯ��

	if isempty(GetName)								% ���� ������ ó�� skip
%		error('No File : exist for condition [%s] & SKIP this.\n', sCondi);
%		return %continue
		% ���� ��� ��� -> �� �ٷ� ǥ��
%		fprintf(FP, '%7s\t%-7s\t%-7s\t',	'       ', '       ', '       ');
		arrayfun(@(x)( fprintf(x, '%7s\t', '       ') ), FP);	% ���Ϻ� ���
		fprintf('||%7s\t| %-7s\t| %-7s\t',	'       ', '       ', '       ');

		continue
	end

AllTime			=	tic;		%���Ǻ� �ش� ��ü ���� ���� �ð�
% ===============================================================================
Data			=	cell(1,	length(GetName));		% ����ó���� data �����
parfor f = 1 : length(GetName)						% F___�� �����ϴ� data
%	load( GetName{f} );								% ���� �б�
	Data{f}		=	load(GetName{f}, [VarName '*']);% ���� �б�
%	fprintf('Loading : file from %s\n', GetName{f});	% notify file name
end	% parfor

Var				=	cell(1,	length(GetName));		% ����ó���� �߰� ����
parfor f = 1 : length(GetName)						% F___�� �����ϴ� data
	% ����: �о�� ������ ������ �ϳ��� ���Ͽ� ������ �����Ƿ�,
	% �� �� VarName �� �ش��ϴ� �͸� ã�Ƽ� ���
	% n varible / 1 file -> find 1 variable in [VarName]:
%{
%	eval( [ 'VAR = whos(''-regexp'', ''[A-Z]{3}_' rCondi ''');' ] ); % ��� ����
%	eval( [ 'VAR = whos(''-regexp'', ''' VarName '*'');' ] ); % ��� ����
	eval( [ 'VAR = whos(''-regexp'', ''' VarName ''');' ] ); % ��� ����
	VAR			=	struct2cell(VAR);				% ��������
	vName		=	VAR(1, :);						% ������ ����
	vSize		=	VAR(2, :);						% ũ�⸸ ����

	eval( [ 'Var{f} = ' vName{ixVar} ';' ]);		% �� ��������
	eval( [ 'clear ' vName{ixVar} ]);				% remove variable
%}
	VAR			=	regexp(fieldnames(Data{f}), [VarName '.*'], 'match'); %��ġ��
	VAR			=	VAR(cellfun(@(x)( ~isempty(x) ), VAR));	% �ʵ��� ����ġ ����
	vName		=	table2cell(cell2table(VAR));	% ���� cell ���� flatten
	vSize		=	cellfun(@(x)({ size(Data{f}.(x)) }), vName); % Data �ʵ� ref

	%% ���������δ� �� ó�� �߰ߵ� �������� �����ϰ� ��.
	%% �׷��� �̰��� �ݵ�� �䱸�� ������� Ȯ���� �����?
	if length(vName) >= 2
		ixVar	=	find(ismember(vName, VarName));	% ��Ȯ�� ���� idx ã��
		if ixVar <= 0, ixVar=	1;	end				% �� ã��, 1st ����
	else
		ixVar	=	1;
	end

	Var{f}		=	Data{f}.( vName{ixVar} );		% �� ��������
	Var{f}		=	double(Var{f});					% �ݵ�� type ����!

	nDim		=	length( vSize{ixVar} );			% ������ ���� ����
	% �翬�� 2������ �ϰ�, ������ tp x ch
	if nDim ~= 3, error('Error   : a dimension size(%d) not 3D', nDim); end

	% �ֿ켱������, sampling rate ���� ���Ѵ�.
	eFS			= 1000*size(Var{f},1)/(tInterval(2)-1-tInterval(1)+1);%SmplRate
	if int32(eFS) ~= eFS, error('ERROR   : eFS(%f) value not integer', eFS); end
	% baseline correction : must have ! eEEG(tp, ep, ch)
	% ���� ���� �����͸� ���ļ�, �� �������� ERP_filt_bl ���� �ٸ� ���̱� ����
	if ~isempty(blWin)
		ix		=	ismember(	tInterval(1):1000/eFS :tInterval(2)-1,	...
								blWin(1)	:1000/eFS :blWin(2)-1 );
		% mean()���� f x 1 x ch -> t �� n�� Ȯ�� : f x t x ch (���� % ũ��ȭ)
		Var{f} = Var{f}-repmat(mean(Var{f}(:,ix,:),2),[1,size(Var{f},2),1]);
	end

	fData(f, :, :, :)=	Var{f};					% �� ���Ǻ� 3D ������
end	% for each data

	eEEG		=	squeeze(mean(fData, 1));	% mean(F111,F112,..)->F___
	clear Data Var nDim VAR vName vSize GetName fData	% garbage ���� ���� ����

% ===============================================================================
	% ���� ���տ� �ش��ϴ� ��� ���ϵ��� ������ �ջ��Ͽ����Ƿ�:

	% 3D �����Ϳ� ���ؼ��� baseline correction �� �� �ʿ䰡 ����.
	% �ֳ��ϸ�, eveke, total activity ���� power ���̱� ����.

	% ä�ο� ���� filter �� ��������
	switch size(eEEG, 3)
	case 30, eCHN	=	eCHNs{1};
	case 63, eCHN	=	eCHNs{2};
	otherwise, error('Error   : incorrect channel size(%d)', size(eEEG,3));
	end
%	eEEG		=	eEEG(:, ismember(eCHN, cWin));	% ���ϴ� ä�θ�

	% 20160602B. �� ä�ο� ���� �������� operation�� ������ �� mean ó����.
	%	������ �̸� ä�� ��� �� �����, no peaks �� ��찡 �ʹ� ����.
	%	�׷���, �־��� ä�ο� ���� �������� peaks ������, Ž���� �͸����� ���!
	ixCh		=	find( ismember(eCHN, cWin) );	% extract for cWin
	eEEG		=	eEEG(:, :, ixCh);				% ���ϴ� ä�θ�
%	eEEG		=	squeeze( mean(eEEG, 3) );		% ä�� ��� == 2D (fq x tp)

	eFS			=	1000 *size(eEEG,2) /(tInterval(2)-1-tInterval(1)+1);%SmplRate
	if int32(eFS) ~= eFS, error('ERROR   : eFS(%f) value not integer', eFS); end
	tBin		=	1000 / eFS;
	tIntrV		=	[ tInterval(1) : tBin : tInterval(2)-1 ];	% vector
	tWinV		=	[ tWin(1) : tBin : tWin(2)-1 ];	% vector
	ixTp		=	find( ismember(tIntrV, tWinV) );% get index

	% fBin�� �����̹Ƿ�, ���� �糡 ���� ���� �������� 1 ����
	fBin		=	1 / ((size(eEEG,1)-1) / (fInterval(2)-fInterval(1)) );%fq����
	fIntrV		=	[ fInterval(1) : fBin : fInterval(2) ];		% vector
	fWinV		=	[ fWin(1) : fBin : fWin(2) ];	% vector
	ixFq		=	find( ismember(fIntrV, fWinV) );% get index

	Stat		=	zeros(1, length(cWin));			% ����ó�� + op ��� ��
	Lat			=	zeros(1, length(cWin));			% ����ó�� + time
	Freq		=	zeros(1, length(cWin));			% ����ó�� + freq
parfor c = 1 : length(cWin)							% ä�ο� �����ϴ� data
	eEEGp		=	squeeze(eEEG(ixFq, ixTp, c));	% ���ϴ� ���ļ�, �ð�

% ===============================================================================
	% 1D eEEG�� ���� operation�� ��������
	% local max , min , mean
	[VL ixF ixT]=	deal( NaN, NaN, NaN );			% �ʱⰪ

	switch Operation
	case 'max'										%% local max �� ã��
		[MX MI]	=	S_localpeaks(eEEGp, 'max');		% 2D max ã��
	if ~isempty(MX) & ~isempty(MI)
		[VL ixF ixT]=	deal( MX, MI(1), MI(2) );
	else
		[VL ixF ixT]=	deal( NaN, NaN, NaN );		% �� ã���� null
	end

	case 'MAX'							% local max ���� ã��, ������, global max
%{
		[MX MI]	=	findpeaks( eEEGp(:) );			% 1D ��� ���
	if ~isempty(MX) & ~isempty(MI)
		[VL IX]	=	max(MX);						% �ִ밪 �� latency
		IX		=	MI(IX);							% eEEGp �� �ش��ϴ� idx Ȯ��
	else											% not found local max
		[VL IX]	=	max( eEEGp(:) );				% substitute global max
	end
		[ixF ixT]=	ind2sub( size(eEEGp), IX);		% 2D ������ �����ϴ� idx ã��
%}
		[MX MI]	=	S_localpeaks(eEEGp, 'max');		% 2D max ã��
	if ~isempty(MX) & ~isempty(MI)
		[VL ixF ixT]=	deal( MX, MI(1), MI(2) );
	else											% not found local max
		[VL IX]	=	max( eEEGp(:) );				% substitute global max
		[ixF ixT]=	ind2sub( size(eEEGp), IX);		% 2D ������ �����ϴ� idx ã��
	end

	case 'min'										%% local min �� ã��
		[MN MI]	=	S_localpeaks(-eEEGp, 'min');		% 2D max ã��
	if ~isempty(MN) & ~isempty(MI)
		[VL ixF ixT]=	deal(-MN, MI(1), MI(2) );
	else											% not found local max
		[VL ixF ixT]=	deal( NaN, NaN, NaN );		% �� ã���� null
	end

	case 'MIN'							% local min ���� ã��, ������, global min
%{
		[MN MI]	=	findpeaks( -eEEGp(:) );
	if ~isempty(MN) & ~isempty(MI)
		[VL IX]	=	min(-MN);						% �ּҰ� �� latency
		IX		=	MI(IX);							% eEEGp �� �ش��ϴ� idx Ȯ��
	else											% not found local min
		[VL IX]	=	min( eEEGp(:) );				% substitute global min
	end
		[ixF ixT]=	ind2sub( size(eEEGp), IX);		% 2D ������ �����ϴ� idx ã��
%}
		[MN MI]	=	S_localpeaks(-eEEGp, 'min');		% 2D max ã��
	if ~isempty(MN) & ~isempty(MI)
		[VL ixF ixT]=	deal(-MN, MI(1), MI(2) );
	else											% not found local min
		[VL IX]	=	min( eEEGp(:) );				% substitute global min
		[ixF ixT]=	ind2sub( size(eEEGp), IX);		% 2D ������ �����ϴ� idx ã��
	end

	case 'mean'
		% ��ü ���, �ð���� ���, ���ļ���� ����� ���ؼ� ���
		VL		=	mean( eEEGp(:) );
		[NEAR IX]=	min(abs(eEEGp(:) - VL));		% ���� �ٻ簪 ã��
		[ixF ixT]=	ind2sub( size(eEEGp), IX);		% 2D ������ �����ϴ� idx ã��

	otherwise
		[VL ixF ixT]	=	deal( NaN, NaN, NaN );	% default index
	end

% ===============================================================================
	% register for condition ���� ����ҿ� ����
	Stat(c)		=	VL;

	% latency �������: ���idx(IX) -> ����idx -> ���time -> ����time
	TM			=	( ixT +ixTp(1) -1 ) * 1000/eFS + (tInterval(1) - 1000/eFS);
%	TM			=	tIntrV( find(eEEG == VL ) );	% �ٸ� ��� ���
	Lat(c)		=	TM;

	% freq �������: ���idx(IX) -> ����idx -> ���freq -> ����freq
	FQ			=	( ixF +ixFq(1) -1 ) * fBin + (fInterval(1) - fBin);
%	[FQ TM]		=	ind2sub(size(eEEG), find(eEEG == VL));	% �ٸ� ��� ���
%	[FQ TM]		=	deal( fIntrV(FQ), tIntrV(TM) );	% freq, time ���� ����!
	Freq(c)		=	FQ;

%	clear eEEGp
end	% parfor c
	clear eEEG										% garbage ���� ���� ����

% ===============================================================================
	% NaN�� �ƴ� ���� �����͸� ����
	Stat		=	mean(Stat(~isnan(Stat)));		% ��ȿ�� ���� ��� ���
	Lat			=	mean(Lat(~isnan(Lat)));			% ��ȿ�� ���� ��� ���
	Freq		=	mean(Freq(~isnan(Freq)));		% ��ȿ�� ���� ��� ���

% ===============================================================================
	% ���� ��� ��� -> �� �ٷ� ǥ��
%	fprintf(FP, '%7.3f\t%-7d\t%-7.3f\t',	Statis(ixSJ, ixCD),		...
%									Latency(ixSJ, ixCD), Frequency(ixSJ, ixCD));
	FPRINTF		=	@(fp, form, dat) ~isnan(dat) &&	fprintf(fp,form,dat) ||	...
													fprintf(fp,'%7s\t','');
	arrayfun(@(x, y) FPRINTF(x, '%7.3f\t', y),	FP, [Stat, Lat, Freq]);	% ���Ϻ�
	FPRINTF		=	@(form, dat)	~isnan(dat) &&	fprintf(form, dat)	||	...
													fprintf('%7s\t', '');
	cellfun(@(x, y) FPRINTF(x, y),	{'||%7.3f\t', '| %-7.3f\t|', ' %-7.3f\t'},...
									{Stat, Lat, Freq} );

% ===============================================================================
	% register for condition ���� ����ҿ� ����
	Statis(ixSJ,ixCD)	=	Stat;
	Latency(ixSJ,ixCD)	=	Lat;
	Frequency(ixSJ,ixCD)=	Freq;
end	% for condi

end	% for sbj
%fclose(FP);
arrayfun(@(x)( fclose(x) ),	FP);
fprintf('\n================================================================================');
fprintf('\n\nFinished: total time is ');	toc(Total);

% ===============================================================================

	return
