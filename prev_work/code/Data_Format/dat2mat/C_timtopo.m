% C_timtopo ver 0.51
%% ERP ������ ��� time plot ����
% [Parameter] ----------
% Potn2D: timepoint * ch �� 2���� ������ -> �� ���� �ټ� �Է� ����
% PlotTp: plot�� �ð�����(ms): Potn2D timepoint���� ��ġ�ʿ�, %��:[-500,1500]
% CED	: topo�� ���� CED ���� path, [ ������ | ����� | ���ϸ� only ]
%		ex) ���ϸ� ǥ��� Ž������: ./ , ~minlab/Tools/MATLAB/
% Condi : text for condition information
% TopoTp: topo�� �ð� ��� : ���� Ȥ�� NaN �Է½� maximum(abs()) ����
%		Inf �Է½� maximum variance ����
%		NaN �� Inf ���� �Է½� Inf ���õ�.
% DispTp: display�� �ð� ��� : ������ �� ���� plot ���� : [ -500 1500 ]
% DispCh: display�� ä�� : ��ȣ �ش� ä�θ� ����, (�⺻: 0==���)
% DispPW: power(amp)�� ����: Y �� range ���� : [-5 5], (�⺻: 0==���)
% DispBar:colorbar�� ��,�� scale ���� : ��: [-1.5 1.5], �⺻: autoscale
% DispRatio: TF plot �� TOPO plot �� ũ�� ���� -> TF/TOPO -> 1>����(topoĿ��)
% Filter: ���͸� ���ļ� ����, ��: [0.5 30](band), [5 nan](high), �⺻:not
%
%% examples:	%-[
%% 1. Single ������ ��ü ä�� ����
%	C04timtopo_AmH(	Data2D, [-500 1500],	...
%		'/home2/minlab/Tools/MATLAB/EEG_32chan.ced',		...
%		'USHL',				[NaN | -200 100 300],	...
%		[ -300 800 ],		'',		[0 1],			...
%		[-1.5 1.5],			0.9)
%
%% 2. Single �������� Ư�� ä��
%	C04timtopo_AmH(	Data2D, [-500 1500],	...
%		'/home2/minlab/Tools/MATLAB/EEG_32chan.ced',		...
%		'USHL',				[NaN | -200 100 300],	...
%		[ -300 800 ],		'Cz',	[-5 5],			...
%		[-1.5 1.5],			0.9)
%
%% 3. Multi �������� �� : (��ü ä�����)
%	C04timtopo_AmH(	{Data2D_1 Data2D_2}, [-500 1500],	...
%		'/home2/minlab/Tools/MATLAB/EEG_32chan.ced',		...
%		{'USHL' 'MSAD'},	[NaN | 300],		...
%		[ -300 800 ],		'',		[-3 3],		...
%		[-1.5 1.5],			0.9)
%
%% 4. Multi �������� �� : (Ư�� ä��)
%	C04timtopo_AmH(	{Data2D_1 Data2D_2}, [-500 1500],	...
%		'/home2/minlab/Tools/MATLAB/EEG_32chan.ced',		...
%		{'USHL' 'MSAD'},	[NaN | 300],	...
%		[ -300 800 ],		'Cz',	[0 0],	...
%		[-1.5 1.5],			0.9)
%
%% 5. real ���� (4�� ����)
%	load '/home/minlab/Projects/SKK/SKK_3/GRD/Com_F___.mat'
%	load '/home/minlab/Projects/SKK/SKK_3/GRD/Com_U__D.mat'
%	load '/home/minlab/Projects/SKK/SKK_3/GRD/Com__AI_.mat'
%	load '/home/minlab/Projects/SKK/SKK_3/GRD/Com__A__.mat'
%	load '/home/minlab/Projects/SKK/SKK_3/GRD/Com__SH_.mat'
%	C04timtopo_AmH({ERP_F___ ERP_U__D ERP__AI_ ERP__A__ ERP__SH_}, ...
%		[-500 1500], '/home2/minlab/Tools/MATLAB/EEG_30chan.ced',	...
%		{'F___' 'U__D' '_AI_' '_A__' '_SH_'},		...
%		[NaN], [-300 800], '', [-1.5 1.5], 0.9)
%
%% 6. real ���� (5�� ����)
%	C04timtopo_AmH({ERP_F___ ERP_U__D ERP__AI_ ERP__A__ ERP__SH_}, ...
%		[-500 1500], '/home2/minlab/Tools/MATLAB/EEG_30chan.ced',	...
%		{'F___' 'U__D' '_AI_' '_A__' '_SH_'},		...
%		[NaN], [-300 800], '', [-1.5 1.5], 0.9,		...
%		[0.5 30])	% ���� ��� �߰�	%-]
%
% first created by tigoum 2015/11/01
% last  updated by tigoum 2016/05/03
% ver 0.51 : filter ���� ��, baseline correction ó��

function [ ] = C_timtopo(	Potn2D,	PlotTp, CED,					...
							Condi,	TopoTp,							...
							DispTp,	DispCh,	DispPW, DispBar,		...
							DispRatio,								...
							Filter)

% implementation: CED auto detector & loader : the rule for find CED file
% 0. detect channel size from Potn2D
% 1. find in current folder
% 2. find in Tools/MATLAB folder

%% setting %%
	if nargin < 3										% �ݵ�� CED������ !
		fprintf('\nError   : parameter missing.\n');
		return
	end

	if nargin <11,	Filter		=	[nan nan];		end	% ��� ����
	if nargin <10,	DispRatio	=	1.0;			end
	if nargin < 9,	DispBar		=	[ nan nan ];	end
	if nargin < 8,	DispPW		=	[ 0 0 ];		end
	if nargin < 7,	DispCh		=	0;				end
	if nargin < 6 | DispTp==0,	DispTp	=	[ PlotTp(1) PlotTp(2) ];	end
	if nargin < 5,	TopoTp		=	NaN;			end
	if nargin < 4,	Condi		=	'';				end

	% ä�� parameter �� ����
	[ChanNum ChanName]	=	mLib_load_CED_AmH(CED);		% CED ���� chan ��� ����

	if isnumeric(DispCh)								% index���ڸ� ���ڿ� Ȯ��
		if DispCh == 0 | isempty(DispCh), sCh	=	'All';
		else,			sCh	=	[char(ChanName{DispCh}) '(' int2str(DispCh) ')'];
		end
	elseif isempty(DispCh)								% '' ���� ���ڸ�
		sCh			=	'All';
		DispCh		=	find(strcmp(ChanName, sCh));	% ����ȭ
	else												% ���ڸ� index���� Ȯ��
		sCh			=	DispCh;
		DispCh		=	find(strcmp(ChanName, sCh));	% ����ȭ
	end

	if length(DispPW) == 1, DispPW = [ DispPW DispPW ]; end	% 2���� ���� �ʿ���

	% --------------------------------------------------
	% �ڵ� eFS ���
	% Potn2D ���� ���� ū ���� tp ��.
	% PlotTp �� ���� ��谪 ���� �߻� : 20160324A. ����
	% -500 ~ 1500 �� �ð��� �����ϴµ�, ���� �����ʹ� 1000�� ���,
	% [-500 , 1500) �� ��. ����, eFS ���� �������� �ƴ��� ���� �ʿ�
	if iscell(Potn2D),	nTp = max(cellfun(@(x)(length(x)), Potn2D));
	else,				nTp = length(Potn2D); end
	eFS				=	1000 * nTp / (PlotTp(2) - PlotTp(1)); %PlotTp==ms
	if int32(eFS) ~= eFS, error('ERROR   : eFS(%f) value not integer', eFS); end
	PlotTp			=	[ PlotTp(1) : 1000/eFS : PlotTp(2)-1 ];	% conv to vector

	% --------------------------------------------------
	% Baseline Correction �� Timewindow�� �����ϴ� �κ�.
	% ���� input data�� time point �� ���� (-) �ð�, �� prestimulus ������
	% �������� ���ϸ� baseline correction�� �� �� ����!
	ERP_blTimWin	=	[-500 -1];		% -500 ~ 0ms, (20151102A. ������ ����)
	TF_blTimWin 	=	[-400 -101];	% -400 ~ -100ms (TF ��)
	% -----
	ERP_blTimWix	=	find(ismember(PlotTp,			...
						[ERP_blTimWin(1):1000/eFS:ERP_blTimWin(2)]) );
	TF_blTimWix		=	find(ismember(PlotTp,			...
						[TF_blTimWin(1) :1000/eFS: TF_blTimWin(2)]) );

	% --------------------------------------------------
	% ���� ���ǿ� ����, ���͸��� �����Ѵ�.
[NONE, HIGH, LOW, BAND]	=	deal(0, 1, 2, 3);			% nmemonic
	if length(find(~isnan(Filter))) >= 2				% bandpass �� ���� ��ġ
		% Butterworth Filtering �κ�.
%		[bbb, aaa]	=	butter(1, [0.5 30]/(eFS/2),'bandpass');
		nOrder		=	Filter / (eFS/2);
		[bbb, aaa]	=	butter(1, nOrder, 'bandpass');	% zero-phase filtering
		fgFilter	=	BAND;

	elseif ~isnan(Filter(1)) % & isnan(Filter(2))		% highpass
		nOrder		=	Filter(1) / (eFS/2);
		[bbb, aaa]	=	butter(1, nOrder, 'high');
		fgFilter	=	HIGH;

	elseif ~isnan(Filter(2)) % & isnan(Filter(1))		% lowpass
		nOrder		=	Filter(2) / (eFS/2);
		[bbb, aaa]	=	butter(1, nOrder, 'low');
		fgFilter	=	LOW;

	else												% �ƹ��͵� ���ص� ��
		fgFilter	=	NONE;
	end

	% ���� data �� ��Ŀ��� �� ������ matrix�� ������ 2D�� �ʰ��ϴ��� ����
if isempty(Potn2D)
	error('Error   : data''s empty, please check parameter.');

elseif iscell(Potn2D)									% ���� data ����
	for dim = 1 : length(Potn2D)
		if 2 < length(size(Potn2D{dim}))
			error('Error   : %dth data''s dimension too more than 2D',dim);
		end
		if size(Potn2D{dim},1) ~= length(PlotTp)		% index �ʰ� -> ��� ���
			error('Warning : TIME index(%d) mismath with data(%d)',	...
					length(PlotTp), size(Potn2D{dim},2));
		end

		% ���� �� data�� dimention �� ũ�Ⱑ �ٸ��ٸ� ���� ���� ������ ���� ��Ŵ
	end

	% ���� data �� ��Ŀ��� matrix�� ������ 2D�� �ʰ��ϴ��� ����
	nSize				=	cellfun(@(x)({ size(x) }), Potn2D);	% size ���
	nDim				=	shiftdim(reshape(cell2mat(nSize), 2,[]), 1);%��������
	mnDim				=	min(nDim);					% �ּ� ũ�� ���� ����

	% ���� �ּ� ������ ���� ������ array���� ũ�� ����
	Index				=	sprintf('1:%d,1:%d', mnDim);% �ε��� ����
	eval(['Potn2D		=	cellfun(@(x)({ double(x(' Index ')) }), Potn2D);']);

	Index				=	sprintf('%d, %d', mnDim);	% �ε��� ����
	eval(['Potn2D		=	reshape(cell2mat(Potn2D),' Index ',[]);']);%��������!

%	if fgFilter
%		Potn2D			= arrayfun(@(x)({filtfilt(bbb, aaa, Potn2D(:,:,x))}),...
%								[1:size(Potn2D,3)] );
%		Potn2D			=	reshape(cell2mat(Potn2D),					...
%								[size(Potn2D{1},1)], [size(Potn2D{1},2)], [] );
%		Potn2D			=	filtfilt(bbb, aaa, Potn2D);
%	end % zero-phase: tp x ch * cond

%	Potn2D				=	shiftdim(Potn2D,2);			% 1st �� array ����
%	Potn2D				=	permute(Potn2D, [2 1 3]);	% t*c*condi->c*t*condi
	% ���� 3������ �����Ͱ� ������.
%{
	% ���� �����͸� �Ķ���� ���տ� ���� �ٽ� ���� 2D �� �����ͷ� ����! %-[
	% 1. DispCh == 0 (��� ä��) �� ���
	%	-> �� array���� ch ������ ��ճ���.
	%	-> �� array���� time vector�� ���´�.
	%	-> �� array �����͸� ch ���� ������ ó�� �ϳ��� ��ħ
	% 2. DispCh == 'Cz' (Ư�� ä�� ����) �� ���
	%	-> �� array���� �ش� ä�θ� �����.
	%	-> �� array���� time vector�� ���´�.
	%	-> �� array �����͸� ch ���� ������ ó�� �ϳ��� ��ħ

	if DispCh == 0										% �� ���� 1 ��Ȳ
		Potn2D			=	arrayfun(@(x)( squeeze(mean(x,3)) ), Potn2D); %ch���
	else												% �� ���� 2 ��Ȳ
		DispCh			=	0;							% ch param ������ ����
		Potn2D(:,:, find(~ismember(ChanNum, DispCh)) ) = [];	% ������ ch ����
		Potn2D			=	squeeze(Potn2D);			% 2D ����
	end
		Potn2D			=	shiftdim(Potn2D,1);			% time ��ġ�� 1st �� -]
	% �� ����� timtopo ���� topo �ۼ��� ���ؼ��� �������� ���ٹ���.
%}

	% �׸��� ���� �������� ���, TopoTp �� ������ ������ ���� ������ ����
	if any(isnan(TopoTp))
		TopoTp			=	NaN;
	else
		TopoTp			=	ones(1, size(Potn2D,1)) * TopoTp(1);
	end

%--------------------------------------------------------------------------------
else													% ���� data ǥ����
	%% 3D ��, condi ������ 1�� ���, squeeze �� ��.

	if 3 <= length(size(Potn2D))							% ���� ����
		error('\nError   : the dimension too more than 2D\n\n');
%{
		% time �� ch �� dim �� ã�� ��, ������ ������ mean ó��.	%-[
		lenTp				=	length(PlotTp);
		lenCh				=	length(ChanNum);
		ixTp				=	find(size(Potn2D) == lenTp);
		ixCh				=	find(size(Potn2D) == lenCh);
		if ixTp < ixCh,
			Potn2D			=	reshape(Potn2D, [], lenTp, lenCh);	%3D ����ȭ
		else
			Potn2D			=	reshape(Potn2D, [], lenCh, lenTp);	%3D ����ȭ
		end
		Potn2D				=	squeeze(mean(Potn2D, 1));			% 2D ���� -]
%}
	end

%	if fgFilter, Potn2D	=	filtfilt(bbb, aaa, Potn2D);	end % zero-phase: tp x ch
end
%{
	if length(TopoFq) ~= length(TopoTp)					% ���� ����ġ -> ���
		fprintf('\nWarning : differ a numbers of Topo(F:%d,T:%d)\n\n',		...
				length(TopoFq), length(TopoTp));
	end
%}
	if fgFilter
		Potn2D		=	filtfilt(bbb, aaa, Potn2D);		% zero-phase: 2D or 3D

		% ���ͽ��� �Ŀ���, ���� baseline correction�� ������ ��
		Potn2D=Potn2D-repmat(mean(Potn2D(ERP_blTimWix,:,:)),size(Potn2D,1),1,1);
	end

	% --------------------------------------------------
	% ��ȿ�� �����͸� cutting
	[ixTpStart ixTpFinish]	=	deal(	find(PlotTp == DispTp(1)),			...
										find(PlotTp == DispTp(2)) );
	if isempty(ixTpFinish), ixTpFinish = find(PlotTp == PlotTp(end)); end
%	ixTime					=	PlotTp(ixTpStart:ixTpFinish);

	if 3 <= length(size(Potn2D)) %iscell(Potn2D)
%		Potn2D		=	cellfun(@(x)({ x(ixTpStart:ixTpFinish, :) }), Potn2D);
%		Potn2D		=	cellfun(@(x)({ shiftdim(x,1) }), Potn2D);	% t*c->c*t
%		Potn2D		=	Potn2D(:, ixTpStart:ixTpFinish, :);	% cond * t * c
		Potn2D		=	Potn2D(ixTpStart:ixTpFinish, :, :);	% t * c * cond
		Potn2D		=	permute(Potn2D, [2 1 3]);		% t*c *cond->c*t *cond
	else
		Potn2D		=	Potn2D(ixTpStart:ixTpFinish, :);
		Potn2D		=	shiftdim(Potn2D,1);				% t*c->c*t
	end

	% --------------------------------------------------
%	FreqCutoff		=	30;								% display ���� ��輱
%	tStep			=	PlotTp(2) - PlotTp(1);			%�ð� ����

	%% drawing 2D graph for ERP data
	if ~isempty(Condi)
		if iscell(Condi)
			sCond	=	strjoin(Condi, ', ');
			nCond	=	length(Condi);
		else
			sCond	=	Condi;
			nCond	=	1;
		end
		title		=	sprintf('Condition(%s)''s ERP plot(Ch:%s)', sCond, sCh);
%		title		=	sprintf('%d Condition''s ERP plot(Ch:%s)', nCond, sCh);
	else
		title		=	sprintf('ERP plot(Ch:%s) & Topography', sCh);
	end

	figure,
%{
%>> help timtopo															%-[
  timtopo()   - plot all channels of a data epoch on the same axis 
                and map its scalp map(s) at selected latencies.
  Usage:
   >> timtopo(data, chan_locs);
   >> timtopo(data, chan_locs, 'key', 'val', ...);
  Inputs:
   data       = (channels,frames) single-epoch data matrix
   chan_locs  = channel location file or EEG.chanlocs structure. 
                See >> topoplot example for file format.
 
  Optional ordered inputs:
   'limits'    = [minms maxms minval maxval] data limits for latency (in ms) and y-values
                  (assumes uV) {default|0 -> use [0 npts-1 data_min data_max]; 
                  else [minms maxms] or [minms maxms 0 0] -> use
                 [minms maxms data_min data_max]
   'plottimes' = [vector] latencies (in ms) at which to plot scalp maps 
                 {default|NaN -> latency of maximum variance}
  'title'      = [string] plot title {default|0 -> none}
  'plotchans'  = vector of data channel(s) to plot. Note that this does not
                 affect scalp topographies {default|0 -> all}
  'voffsets'   = vector of (plotting-unit) distances vertical lines should extend 
                 above the data (in special cases) {default -> all = standard}
 
  Optional keyword, arg pair inputs (must come after the above):
  'topokey','val' = optional topoplot() scalp map plotting arguments. See >> help topoplot 
 
  Author: Scott Makeig, SCCN/INC/UCSD, La Jolla, 1-10-98 
 
  See also: envtopo(), topoplot()											%-]

	timtopo(Potn2D,			CED,											...
			'title',		title,											...
			'plottimes',	TopoTp,											...
			'plotchans',	DispCh,											...
			'limits',		[ixTime(1) ixTime(end) DispPW DispBar],			...
			'tradeoff',		DispRatio );
%}
	timtopo(Potn2D,			CED,											...
			'title',		title,											...
			'plottimes',	TopoTp,											...
			'plotchans',	DispCh,											...
			'limits',	[PlotTp(ixTpStart) PlotTp(ixTpFinish) DispPW DispBar],...
			'tradeoff',		DispRatio );

	fname			=	[sCond '_' sCh '.jpg'];
	print('-djpeg', fname);

	return
%end function

