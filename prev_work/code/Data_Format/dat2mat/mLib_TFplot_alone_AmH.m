function [ ] = mLib_TFplot_alone_AmH(Potn3D, hEEG, MaxFq,MaxTp,MaxCh, JPG)
	%% ��� ä���� �����͸� overlap �Ͽ� ������
	% Potn3D : freq * timepoint * ch �� 2���� ������
	% hEEG	: eEEG�� header
	% MaxFq : Potn3D(?,:,:) ���� MaxFq ���ļ� ��ġ�� �ִ밪 ����
	% MaxTp : Potn3D(:,?,:) ���� MaxTp timpoint ��ġ�� �ִ밪 ����
	% MaxCh : Potn3D(:,:,?) ���� MaxCh ��ġ�� �ִ밪 ����
	% JPG : ������ �̹����� ���� �̸�

	if isnumeric(MaxFq)								%���ļ� ������ ���ڿ��� ��ȯ
		sMaxFq		=	sprintf('%4.1f Hz', MaxFq);
	elseif isstr(MaxFq)
		sMaxFq		=	MaxFq;
	else
		sMaxFq		=	'Unknown';
		fprintf('\nWarning : did not specified the frequency info.');
	end

	FreqParti		=	30;								% display ���� ��輱

%% Header %%
global	SRC_NAME;
global	NUMWORKERS;			%define global var for parallel tool box!!
global	WORKNAME;

%A_globals_AmH();%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@
%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
%	Freqs, fName, m, ki, cedPATH	]	=	A_globals_AmH();
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	Time				=	hEEG.Time;
	Freq				=	hEEG.Freq;
	tStep				=	Time.SmplIntrv;				%�ð� ����

%	liveChIdx			=	find( ~ismember(channame, removech) );	%aliveä�θ�
	Chan				=	hEEG.Chan;
%	Chan.idxLive;

	MaxValue			=	Potn3D(MaxFq, MaxTp, MaxCh);
%	mxChName			=	channame{MaxCh};
	mxChName			=	Chan.All{MaxCh};

%	selchan				=	channame;
	selchan				=	Chan.All;
	selchan{MaxCh}		=	[ '*' mxChName ];			% Max Ch�� '*' ǥ��
%	selchan				=	selchan(liveChIdx);			% EOG, NULL ����

	% F, T �� ���� peak ���� ���ؼ� ǥ������.
	%% potential ���� { positive, negative } peak �� ��� ���ؾ� �Ѵ�.
	%% �ϴ��� postitive peak �� ����.
	% -> 3D�� �ش��ϹǷ�, F�� ���� peak�� T�� ���� peak �� �����ϹǷ�,
	%	���������� ���ϴ� ����� �����ؾ� ��.
	%
	%���:
	%	x0. ��ä�� ���: ��� ä���� ��ճ���. -> ����� �� �� ��
	%	1. �� ���ļ���: / (sub)�� ä�ο� ����, time series ���� peak ���� ������
	%	2. ���ļ� ����: 0.5~30(FreqL), 30~80(FreqH) ����
	%	3. L���ļ�����: �� 1�� L���������� ������ peak�� �� > 3SD �� ���� ����
	%	4. H���ļ�����: �� 1�� H���������� ������ peak�� �� > 3SD �� ���� ����
	%%	5. !! MAX : �� �Ķ���Ϳ� ���� ������ ���� ��¥ max peak ���� ����!
	%	6. ���� > 3SD �� ���� �� ���ٸ�, 2SD ������ thre�� ���ߴ� �͵� ���
	%
	%����: -> ��� findpeaks �� ���� ����� �����ϳ�, max (== positive) ���⸸
	%	������ �ֹǷ�, min ������ �������� ������ �����Ϳ� ���� max �� ���� ��
	%	�ٽ� �����Ͽ� �ľ��ؾ� ��.

	% ���� �� ä�κ� max peak �� ����
	% ��!, �ݵ�� time 0 ���ĺ��� �����ؾ� ��.
	%% -> �ƴ� time 0 ������� ��� ���� �� ��.

	%%	1. ���ļ��� �����Ѵ�.
	Potn3D				=	double(Potn3D);				% findpeaks(double)!
	HPOTN3D				=	[];
	if size(Potn3D,1) ~= length(Freq.CurWin)			% ����ġ!!
		fprintf('\nWarning : a freq-range(%d) mismatch with param(%d)\n',	...
				size(Potn3D,1), length(Freq.CurWin));
		fprintf('SKIP   : TFtopo working.\n');
		return

	elseif min(Freq.CurWin)<=FreqParti && FreqParti< max(Freq.CurWin)
		% freq�� �뿪 �Ѿ� ��ġ�� ��� ����
		% 30 Hz �� �������� �ΰ��� ������ ���� image�� ��������, ��� �����
		% -> subplot �� �ۼ��� �� ������ ������, ����� ã�ƺ��� ��.
		fprintf('\nProcess : spliting frequency by %fHz based.\n', FreqParti);
		HPOTN3D			=	Potn3D(find( Freq.CurWin >  FreqParti), :,:);
		Potn3D			=	Potn3D(find( Freq.CurWin <= FreqParti), :,:);
%	else					% all < 30 or 30 < all �̸�, Potn3D �� ó���ϸ� ��
	end

	%%	2. �� ���ļ���: / (sub)�� ä�ο� ����, time series ���� peak ���� ������
	lMxPks				=	zeros(size(Potn3D));
	lMxLoc				=	zeros(size(Potn3D));
	for f	= 1 : size(Potn3D, 1)						% ���ļ� ����
	for ch	= 1 : size(Potn3D, 3)						% ä�� ����
%		[pks loc]		=	findpeaks(Potn3D(f,:,ch), 1/tStep);%����tp��ġ by 2nd
		[pks loc]		=	findpeaks(Potn3D(f,:,ch));	%Live2D����:t*ch
%		lMxPks(f,:,ch)	=	pks';						% ä�� �� peak: ��->��
		lMxPks(f,loc,ch)=	pks';						% ä�� �� peak: ��->��
		lMxLoc(f,loc,ch)=	loc;						% ä�� �� pk ��ġ ����

		[pk loc]		=	max(pks);					% �ִ밪��:f,ch��� only1
		mxPeak(f,ch)	=	pk;
%		mxLocs(f,ch)	=	loc;						% time ��ġ
	end
	end

	hMxPks				=	zeros(size(HPOTN3D));
	hMxPks				=	zeros(size(HPOTN3D));
	for f	= 1 : size(HPOTN3D, 1)						% ���ļ� ����
	for ch	= 1 : size(HPOTN3D, 3)						% ä�� ����
%		[pks locs]		=	findpeaks(HPOTN3D(f,:,ch), 1/tStep);%Live2D����:t*ch
		[pks locs]		=	findpeaks(HPOTN3D(f,:,ch));	%Live2D����:t*ch
%		hMxPks(f,:,ch)	=	pks';						% ä�� �� peak: ��->��
		hMxPks(f,loc,ch)=	pks';						% ä�� �� peak: ��->��
		hMxLoc(f,loc,ch)=	loc;						% ä�� �� pk ��ġ ����

		[pk loc]		=	max(pks);					% �ִ밪��
		HmxPeak(f,ch)	=	pk;
%		HmxLocs(f,ch)	=	loc;						% time ��ġ
	end
	end

	%%	3. L���ļ�����: �� 1�� L���������� ������ peak�� �� > 3SD �� ���� ����
		% > 3SD �� �� ã��
		% u, SD�� �������. -> �� 0 ��(�� peak �ƴ� ��) �� �����ϵ��� ��ó!
		ixNon0			=	find(lMxPks(:) ~= 0);		% 0�� �ƴ� index
		NonZero			=	lMxPks( ixNon0 );			% 0�� �ƴ� ��
%		OrgNon0			=	Potn3D( ixNon0 );
%		all(all(all( OrgNon0 == NonZero )))
% lMxPks �� ����� pks���� Potn3D �� ���� ��ġ�� ����� �� �� �˻��
%		MN_FC			=	mean(lMxPks(:));			% 1Dȭ ������ ��ü���
%		SD_FC			=	std(lMxPks(:));				% SD(ǥ������)=sqrt(V)
		MN_FC			=	mean(NonZero);				% ��ü���
		SD_FC			=	std(NonZero);				% SD(ǥ������)=sqrt(V)

		% ��üdata�� ����ȭ ��, significant ���� ����->�׷��� idx ��Ȯ Ȯ�� ����
		Z				=	( lMxPks - MN_FC ) / SD_FC;	% Z== array
		ixSgnf			=	find( hEEG.Statistics.Z_threshold< abs(Z) );% SD>3 ��

	if ~isempty(ixSgnf)									% �߰�
		% �ʹ� ������ ����ϹǷ�, ���� ū�ͺ��� ���(thre ����) ����
		[lSgPks ix]		=	sort(abs(lMxPks(ixSgnf)), 'descend'); % �ִ밪 Ž��
		nLimit			=	min(length(lSgPks), hEEG.Statistics.Z_threshold+4);
		lSgPks			=	lSgPks(1:nLimit);			% ���� ��� : max 7

%		lMxLocSgnf		=	lMxLoc(ixSgnf);				% significant ���и�
%		lSgTp			=	lMxLocSgnf(ix(1:nLimit));	% tp �� ���

		% ix ���� lSgPks(==lMxPks(ixSgnf))�� �������� �� index �� ��� ����
		% ����, lMxPks �� ���� index �� ���ؾ� ��.
		[SgF, SgT, SgC]	=	ind2sub(size(lMxPks), ixSgnf(ix(1:nLimit)));%3D ��idx

		[imxF imxT imxC]=	deal( SgF(1), SgT(1), SgC(1) );	%�ִ� ��ġ
		mxPk			=	lMxPks( imxF, imxT, imxC );	% �ִ밪
%		imxT
%		imxT			=	lMxLoc(imxF, imxC)			% time ��ġ ȹ��

	else
		lSgPks			=	[];
%		lSgLoc			=	[];

		% �ϴ� max ���� ������.
		[mxPk_c, imxC]	=	max(mxPeak, [], 2);			% ä�� �� �ִ�
		[mxPk,   imxF]	=	max(mxPk_c);				% ���ļ� �� �ִ�
		imxC			=	imxC(imxF);					% �� �ϳ��� ä��
		imxT			=	lMxLoc(imxF, imxC);			% time ��ġ Ȯ��
	end

	%%	4. H���ļ�����: �� 1�� H���������� ������ peak�� �� > 3SD �� ���� ����
	[ hSgPks HmxPk HimxF HimxT HimxC ] = deal([], 0, 0, 0, 0);			%-[
	if ~isempty(HPOTN3D) && ~isempty(hMxPks)			% high freq ������ ó��
		% > 3SD �� �� ã��
		% u, SD�� �������. -> �� 0 ��(�� peak �ƴ� ��) �� �����ϵ��� ��ó!
		NonZero			=	lMxPks( find(hMxPks(:) ~= 0) );	% 0�� �ƴ� ��
%		MN_FC			=	mean(hMxPks(:));			% 1Dȭ ������ ��ü���
%		SD_FC			=	std(hMxPks(:));				% SD(ǥ������)=sqrt(V)
		MN_FC			=	mean(NonZero);				% ��ü���
		SD_FC			=	std(NonZero);				% SD(ǥ������)=sqrt(V)

		% ��üdata�� ����ȭ ��, significant ���� ����->�׷��� idx ��Ȯ Ȯ�� ����
		Z				=	( hMxPks - MN_FC ) / SD_FC;	% Z== array
		ixSgnf			=	find( hEEG.Statistics.Z_threshold< abs(Z) );% SD>3 ��

	if ~isempty(ixSgnf)								% �߰�
		% �ʹ� ������ ����ϹǷ�, ���� ū�ͺ��� ���(thre ����) ����
		[hSgPks ix]		=	sort(abs(hMxPks(ixSgnf)), 'descend'); % �ִ밪 Ž��
		nLimit			=	min(length(lSgPks), hEEG.Statistics.Z_threshold+4);
		hSgPks			=	hSgPks(1:hEEG.Statistics.Z_threshold+2);% ���� ���

%		hMxLocSgnf		=	hMxLoc(ixSgnf);				% significant ���и�
%		lSgTp			=	hMxLocSgnf(ix(1:nLimit));	% tp �� ���
		[hSgF hSgT hSgC]=	ind2sub(size(hMxPks), ixSgnf(ix(1:nLimit)));%3D ��idx

		[HimxF HimxT HimxC]=	deal( hSgF(1), hSgT(1), hSgC(1) );	%�ִ� ��ġ
		mxPk			=	hMxPks( HimxF, HimxT, HimxC );	% �ִ밪
%		HimxT			=	hMxLoc(HimxF, HimxC);			% time ��ġ ȹ��

	else
		hSgPks			=	[];
%		hSgLoc			=	[];

		[HmxPk_c, HimxC]=	max(HmxPeak, [], 2);		% ä�� �� �ִ�
		[HmxPk,   HimxF]=	max(HmxPk_c);				% ���ļ� �� �ִ�
		HimxC			=	HimxC(HimxF);				% �� �ϳ��� ä��
		HimxT			=	hMxLoc(HimxF, HimxC);		% time ��ġ Ȯ��
	end
	end													%-]

	if isempty(lSgPks) && isempty(hSgPks)				% �ɰ�! ������ �� ����!
		fprintf('\nDiffcult: detection for a significant peaks\n');
		fprintf('SKIP   : TFtopo working.\n');
		return
	end

	%%	5. !! MAX : �� �Ķ���Ϳ� ���� ������ ���� ��¥ max peak ���� ����!
	if HmxPk==MaxValue && HimxF==MaxFq && HimxT==MaxTp && HimxC==MaxCh
		% H ���ļ� �������� param(MaxValue) ��ġ
		% L ������ signif ������ �����ؾ� �ϴ°�?(H ���� display �ǵ���...)

	elseif mxPk==MaxValue && imxF==MaxFq && imxF==MaxTp && imxC==MaxCh
		% L ���ļ� �������� param(MaxValue) ��ġ

	else												% ���� ����
		fprintf('\nWarning : inconsist with max peaks & param(MaxValue)\n');

	end

	%	6. ���� > 3SD �� ���� �� ���ٸ�, 2SD ������ thre�� ���ߴ� �͵� ���

	%%	7. ������ ������ �߰ߵǾ����Ƿ�, TF topo �ۼ�
	%	7-0. ������ ����(������ max peak ��)�� thre+4 �� �������� ������ ���
	%		-> ��ü Potn3D �� ������ �����Ƿ�, Ž���� ������ ���� ������ ����
	%
	%	���ļ���, L & H �� ���ҵǴ� ��쿡 subplot ���� ����� ã�ƺ� ��.
	%	-> ����� �Ʒ��� ��쿡 ����, �ϳ��� �ۼ�
	%	7-1. L, H ��� ����: L �� �ۼ�
	%	7-2. L�� ����: L �ۼ�
	%	7-3. H�� ����: H �ۼ�
	%	7-4. �Ѵ� N.S. : L �� �ۼ� -> �������� ������ max peak ã�Ƽ� ����

	CED				=	find( cellfun(@(x)(x{1}), Chan.CED) == size(Potn3D,3) );
	if isempty(CED)
		fprintf('\nError   : correct CED(%dch) not found\n', size(Potn3D,3));
	end
	CED					=	Chan.CED{CED}{2};		% path Ȯ��
	% ------------------
	% �����ϰų� Ȥ�� �ƴϴ��� peak�� ���� imxF, imxT, imxC, mxPk �� ������.
	sMaxFq				=	sprintf('%.2f Hz', Freq.CurWin(imxF));
	sMaxTp				=	sprintf('%d ms', Time.EpochRange(imxT));
	sMaxCh				=	Chan.All{imxC};
	title	=	sprintf('Freq: %s, Time: %s, Ch: %s', sMaxFq, sMaxTp, sMaxCh);
	%	7-1. L, H ��� ����: L �� �ۼ�
	%	7-2. L�� ����: L �ۼ�
	figure;	hold on;									% �ݵ�� �ڵ��� ������ ��
	if ~isempty(lSgPks) && ~isempty(hSgPks)									...
		| ~isempty(lSgPks)
%{
%% ex: timef(), computing time-frequency decomposition for all electrodes	%-[
for elec = 1:EEG.nbchan
	[ersp,itc,powbase,times,freqs,erspboot,itcboot] =				...
	timef(EEG, ...
	1, elec, [EEG.xmin EEG.xmax]*1000, [3 0.5], 'maxfreq', 50, 'padratio', 4, ...
	'plotphase', 'off', 'timesout', 60, ...
	'alpha', .05, 'plotersp','off', 'plotitc','off');
	if elec == 1
		allersp     = zeros([ size(ersp)     EEG.nbchan]);
		allitc      = zeros([ size(itc)      EEG.nbchan]);
		allpowbase  = zeros([ size(powbase)  EEG.nbchan]);
		alltimes    = zeros([ size(times)    EEG.nbchan]);
		allfreqs    = zeros([ size(freqs)    EEG.nbchan]);
		allerspboot = zeros([ size(erspboot) EEG.nbchan]);
		allitcboot  = zeros([ size(itcboot)  EEG.nbchan]);
	end;
	allersp     (:,:,elec) = ersp;
	allitc      (:,:,elec) = itc;
	allpowbase  (:,:,elec) = powbase;
	alltimes    (:,:,elec) = times;
	allfreqs    (:,:,elec) = freqs;
	allerspboot (:,:,elec) = erspboot;
	allitcboot  (:,:,elec) = itcboot;
end;	%-]
%% doc: tftopo(), ����	%-[
tftopo() -	Generate a figure showing a selected or representative image (e.g.,
			an ERSP, ITC or ERP-image) from a supplied set of images,
			one for each scalp channel. Then, plot topoplot() scalp maps of
			value distributions at specified (time, frequency) image points.
			Else, image the signed (selected) between-channel std().
			Inputs may be outputs of timef(), crossf(), or erpimage().
Usage:
			>> tftopo(tfdata,times,freqs, 'key1', 'val1', 'key2', val2' ...)
Inputs:
tfdata	= Set of time/freq images, one for each channel. Matrix dims:
			(time,freq,chans). Else, (time,freq,chans,subjects) for grand mean
			RMS plotting.
times		= Vector of image (x-value) times in msec, from timef()).
freqs		= Vector of image (y-value) frequencies in Hz, from timef()).

Optional inputs:
'timefreqs'	= Array of time/frequency points at which to plot topoplot() maps.
				Size: (nrows,2), each row given the [ms Hz] location
				of one point. Or size (nrows,4), each row given [min_ms
				max_ms min_hz max_hz].
'showchan'	= [integer] Channel number of the tfdata to image. Else 0 to image
				the (median-signed) RMS values across channels. {default: 0}
'chanlocs'	= ['string'|structure] Electrode locations file (for format, see
				>> topoplot example) or EEG.chanlocs structure  {default: none}
'limits'	=Vector of plotting limits[minms maxms minhz maxhz mincaxis maxcaxis]
				May omit final vales, or use NaN's to use the input data limits.
				Ex: [nan nan -100 400];
'signifs'	= (times,freqs) Matrix of significance level(s) (e.g., from timef())
				to zero out non-signif. tfdata points. Matrix size must be
						([1|2], freqs, chans, subjects)
				if using the same threshold for all time points at each freq., or
						([1|2], freqs, times, chans, subjects).
				If first dimension is of size 1, data are assumed to contain
				positive values only {default: none}
'sigthresh'	= [K L] After masking time-freq. decomposition using the 'signifs'
				array (above), concatenate (time,freq) values for which no more
				than K electrodes have non-0 (significant) values. If several
				subjects, the second value L is used to concatenate subjects in
				the same way. {default: [1 1]}
'selchans'	= Channels to include in the topoplot() scalp maps (and image values)
				{default: all}
'smooth'	= [pow2] magnification and smoothing factor. power of 2 (default: 1}.
'mode'		= ['rms'|'ave'] ('rms') return root-mean-square, else ('ave') average
				power {default: 'rms' }
'logfreq'	= ['on'|'off'|'native'] plot log frequencies {default: 'off'}
				'native' means that the input is already in log frequencies
'vert'		= [times vector] (in msec) plot vertical dashed lines at specified
				times {default: 0}
'ylabel'	= [string] label for the ordinate axis. Default is
				"Frequency (Hz)"
'shiftimgs' = [response_times_vector] shift time/frequency images from several
				subjects by each subject's response time {default: no shift}
'title'		= [quoted_string] plot title (default: provided_string).
'cbar'		= ['on'|'off'] plot color bar {default: 'on'}
'cmode'		= ['common'|'separate'] 'common' or 'separate' color axis for each
				topoplot {default: 'common'}
'plotscalponly' = [x,y] location (e.g. msec,hz). Plot one scalp map only; no
				time-frequency image.
'events'	= [real array] plot event latencies. The number of event
				must be the same as the number of "frequecies".
'verbose'	= ['on'|'off'] comment on operations on command line {default: 'on'}.
'axcopy'	= ['on'|'off'] creates a copy of the figure axis and its graphic
				objects in a new pop-up window using the left mouse button
				{default: 'on'}..
'denseLogTicks'= ['on'|'off'] creates denser labels on log freuqncy axis
				{default: 'off'}

Notes:
1) Additional topoplot() optional arguments can be used.
2) In the topoplot maps, average power (not masked by significance) is used
	instead of the (signed and masked) root-mean-square (RMS) values used in
	the image.
3) If tfdata from several subjects is used (via a 4-D tfdata input),
	RMS power is first computed across electrodes, then across the subjects.

Authors: Scott Makeig, Arnaud Delorme & Marissa Westerfield, SCCN/INC/UCSD,
			La Jolla, 3/01

See also: timef(), topoplot(), spectopo(), timtopo(), envtopo(), changeunits()%-]
%}
	% Potn2D�� ��Ȯ�� ä�μ��� ��ġ�ϴ� CED �� ã�ƾ� ��.
%%		tftopo(blTFe, 1:2:2000, 0.5:1/2:80, 'mode', 'ave', 'limits', [nan nan nan 35 -1.5 1.5], 'timefreqs', [500 5; 600 5.5; 700 6; 800 6.5], 'chanlocs', '/home/minlab/MATLAB/EEG_30chan.ced');
		TITLE =	sprintf('Sgnf. Max: %.3f, %s', Potn3D(imxF, imxT, imxC), title)

		% SgT, SgF ���� Potn3D �迭�� �ε����� ��� �ֱ� ������, �̸� �����ؾ� ��
		% ��, EpochRange, CurWin�� ������ ������ �ʿ���.
		tftopo(Potn3D, Time.EpochRange, Freq.CurWin,						...
			'title',		TITLE,											...
			'mode',			'ave',											...
			'limits',		[nan nan nan nan nan nan],						...
			'timefreqs',	[Time.EpochRange(SgT); Freq.CurWin(SgF)]',		...
			'showchan',		imxC,											...
			'chanlocs',		CED);
			% signifs	: ( time, freq ) ���� ����
			% sigthresh	: ( K:�ִ� ����, L:���� subj ) ���� ����

	%	7-3. H�� ����: H �ۼ�
	elseif ~isempty(hSgPks)
		TITLE =	sprintf('Sgnf. Max: %.3f, %s', HPOTN3D(imxF, imxT, imxC), title);

		tftopo(HPOTN3D, Time.EpochRange, Freq.CurWin,						...
			'title',		TITLE,											...
			'mode',			'ave',											...
			'timefreqs',	[Time.EpochRange(hSgT); Freq.CurWin(hSgF)]',	...
			'showchan',		imxC,											...
			'signifs', ones(length(Time.EpochRange),length(Freq.CurWin))*0.05,...
			'sigthresh',	[5 1],											...
			'chanlocs',		CED);

	%	7-4. �Ѵ� N.S. : L �� �ۼ� -> �������� ������ max peak ã�Ƽ� ����
	else
		TITLE =	sprintf('N.S. Max: %.3f, %s', Potn3D(imxF, imxT, imxC), title);

		tftopo(Potn3D, Time.EpochRange, Freq.CurWin,						...
			'title',		TITLE,											...
			'mode',			'ave',											...
			'timefreqs',	[Time.EpochRange(imxT); Freq.CurWin(imxF)]',	...
			'showchan',		imxC,											...
			'chanlocs',		CED);
	end
%{
	%% drawing 2D graph for signal T * ch : checking for noise or spike
%	tStep				=	length(tRng) / size(Potn3D,1);	%�ð� ���� ���
%	tStep				=	tRng(2)-tRng(1);			%�ð� ����
	% 2D Plot
	figure,
%	plot(tRng, Potn3D(:,liveChIdx)); hold on;			% EOG, NULL ����
%	plot(Time.EpochRange, Potn3D); hold on;				% EOG, NULL -> �̹� ����
	%% peak ���� ���ؼ�, �ش� ������ ���� topo ���� ������ ��.
	% ���ļ� ������ ���� ���, 30Hz ���� �߶� �и��Ͽ� �����ؾ� ��.
%%	tftopo(blTFe, 1:2:2000, 0.5:1/2:80, 'mode', 'ave', 'limits', [nan nan nan 35 -1.5 1.5], 'timefreqs', [500 5; 600 5.5; 700 6; 800 6.5], 'chanlocs', '/home/minlab/MATLAB/EEG_30chan.ced');

	YLim				=	get(gca, 'YLim');
	tWin				=	Time.WinStart : Time.WinFinish;	% �ð� ����
%	if tWin ~= 0										% 0 �̸� time win ǥ�� X
	rectangle('EdgeColor','r', 'LineWidth',2,							...
		'Position',[tWin(1),YLim(1),tWin(end)-tWin(1),YLim(2)-YLim(1)]); hold on;
%	end
	legend(selchan, 'Location','eastoutside', 'Orientation','vertical');
	xlabel('t(ms)');		ylabel(sprintf('%d of ch', length(selchan)));
	title(sprintf('Max Value: %f, Freq: %s, Time: %d ms, Ch: %s',			...
		MaxValue, sMaxFq, MaxTp *tStep +Time.Start, mxChName));
%	ylim([-0.1 1.2]);
	grid on;

	% �ִ밪 ��ġ�� marker ǥ��
	plot(MaxTp *tStep +Time.Start, MaxValue, 'ro','MarkerSize',10,'LineWidth',1);
%}
	%% saving 2D to jpeg ------------------------------
	fprintf('\nWrites  : Graph to JPEG file : ''%s''... ', JPG);
	print('-djpeg', JPG);
	close all;

%end function
