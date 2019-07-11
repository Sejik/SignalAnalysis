% tftopo()  - Generate a figure showing a selected or representative image (e.g.,
%             an ERSP, ITC or ERP-image) from a supplied set of images, one for each
%             scalp channel. Then, plot topoplot() scalp maps of value distributions
%             at specified (time, frequency) image points. Else, image the signed
%             (selected) between-channel std(). Inputs may be outputs of
%             timef(), crossf(), or erpimage().
% Usage:
%             >> tftopo(tfdata,times,freqs, 'key1', 'val1', 'key2', val2' ...)
% Inputs:
%   tfdata    = Set of time/freq images, one for each channel. Matrix dims:
%               (time,freq,chans). Else, (time,freq,chans,subjects) for grand mean
%               RMS plotting.
%   times     = Vector of image (x-value) times in msec, from timef()).
%   freqs     = Vector of image (y-value) frequencies in Hz, from timef()).
%
% Optional inputs:
%  'timefreqs' = Array of time/frequency points at which to plot topoplot() maps.
%                Size: (nrows,2), each row given the [ms Hz] location
%                of one point. Or size (nrows,4), each row given [min_ms
%                max_ms min_hz max_hz].
%  'showchan'  = [integer] Channel number of the tfdata to image. Else 0 to image
%                the (median-signed) RMS values across channels. {default: 0}
%  'chanlocs'  = ['string'|structure] Electrode locations file (for format, see
%                >> topoplot example) or EEG.chanlocs structure  {default: none}
%  'limits'    = Vector of plotting limits [minms maxms minhz maxhz mincaxis maxcaxis]
%                May omit final vales, or use NaN's to use the input data limits.
%                Ex: [nan nan -100 400];
%  'signifs'   = (times,freqs) Matrix of significance level(s) (e.g., from timef())
%                to zero out non-signif. tfdata points. Matrix size must be
%                         ([1|2], freqs, chans, subjects)
%                if using the same threshold for all time points at each frequency, or
%                         ([1|2], freqs, times, chans, subjects).
%                If first dimension is of size 1, data are assumed to contain
%                positive values only {default: none}
%  'sigthresh' = [K L] After masking time-frequency decomposition using the 'signifs'
%                array (above), concatenate (time,freq) values for which no more than
%                K electrodes have non-0 (significant) values. If several subjects,
%                the second value L is used to concatenate subjects in the same way.
%                {default: [1 1]}
%  'selchans'  = Channels to include in the topoplot() scalp maps (and image values)
%                {default: all}
%  'smooth'    = [pow2] magnification and smoothing factor. power of 2 (default: 1}.
%  'mode'      = ['rms'|'ave'] ('rms') return root-mean-square, else ('ave') average
%                power {default: 'rms' }
%  'logfreq'   = ['on'|'off'|'native'] plot log frequencies {default: 'off'}
%                'native' means that the input is already in log frequencies
%  'vert'      = [times vector] (in msec) plot vertical dashed lines at specified times
%                {default: 0}
%  'ylabel'    = [string] label for the ordinate axis. Default is
%                "Frequency (Hz)"
%  'shiftimgs' = [response_times_vector] shift time/frequency images from several
%                subjects by each subject's response time {default: no shift}
%  'title'     = [quoted_string] plot title (default: provided_string).
%  'cbar'      = ['on'|'off'] plot color bar {default: 'on'}
%  'cmode'     = ['common'|'separate'] 'common' or 'separate' color axis for each
%                topoplot {default: 'common'}
%  'plotscalponly' = [x,y] location (e.g. msec,hz). Plot one scalp map only; no
%                time-frequency image.
%  'events'    = [real array] plot event latencies. The number of event
%                must be the same as the number of "frequecies".
%  'verbose'   = ['on'|'off'] comment on operations on command line {default: 'on'}.
%  'axcopy'  = ['on'|'off'] creates a copy of the figure axis and its graphic objects in a new pop-up window
%                    using the left mouse button {default: 'on'}..
%  'denseLogTicks' = ['on'|'off'] creates denser labels on log freuqncy axis {default: 'off'}
%
%% 'tradeoff'  = value of real(float) for ratio of TFplot/TOPOplot {default: 1.0}
%%	appended by tigoum
%
% Notes:
%  1) Additional topoplot() optional arguments can be used.
%  2) In the topoplot maps, average power (not masked by significance) is used
%     instead of the (signed and masked) root-mean-square (RMS) values used in the image.
%  3) If tfdata from several subjects is used (via a 4-D tfdata input), RMS power is first
%     computed across electrodes, then across the subjects.
%
% Authors: Scott Makeig, Arnaud Delorme & Marissa Westerfield, SCCN/INC/UCSD, La Jolla, 3/01
%
% See also: timef(), topoplot(), spectopo(), timtopo(), envtopo(), changeunits()

% hidden parameter: 'shiftimgs' = array with one value per subject for shifting in time the
%                                 time/freq images. Had to be inserted in tftopo because
%                                 the shift happen after the smoothing

% Copyright (C) Scott Makeig, Arnaud Delorme & Marissa Westerfield, SCCN/INC/UCSD,
% La Jolla, 3/01
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% 01-25-02 reformated help & license -ad

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% edited by tigoum
% 20151201A : appended text "uV" to colorbar
% 20151202A : display chan info when "showchan>0" option
% 20151208A : control colorbar position with tfplot, not topoplot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ DominanceFreq, StrikeZone, ZsignifZone ]		=			...
				tftopo(tfdata,times,freqs,varargin);
%timefreqs,showchan,chanlocs,limits,signifs,selchans)

LINECOLOR= 'k';
LINEWIDTH = 1;
ZEROLINEWIDTH = 2.8;

if nargin<3
	help tftopo
	return
end
icadefs_flag = 1;
try
	icadefs;
catch
	warning('icadefs.m can not be located in the path');
	icadefs_flag = 0 ;
end
if ~icadefs_flag
	AXES_FONTSIZE = 10;
	PLOT_LINEWIDTH = 2;
end

% reshape tfdata
% --------------
if length(size(tfdata))==2
	if size(tfdata,1) ~= length(freqs), tfdata = tfdata'; end;
		nchans = round(size(tfdata,2)/length(times));
		tfdata = reshape(tfdata, size(tfdata,1), length(times), nchans);
elseif length(size(tfdata))>=3
	nchans = size(tfdata,3);
else
	help tftopo
	return
end
tfdataori = mean(tfdata,4); % for topoplot

% test inputs
% -----------
% 'key' 'val' sequence
fieldlist = {	...
'chanlocs'	{'string','struct'}	[]						'' ;
'limits'		'real'			[]					[nan nan nan nan nan nan];
'logfreq'		'string'		{'on','off','native'}	'off';
'cbar'			'string'		{'on','off' }			'on';
'mode'			'string'		{ 'ave','rms' }			'rms';
'title'			'string'		[]						'';
'verbose'		'string'		{'on','off' }			'on';
'axcopy'		'string'		{'on','off' }			'on';
'cmode'			'string'		{'common','separate'}	'common';
'selchans'		'integer'		[1 nchans]				[1:nchans];
'shiftimgs'		'real'			[]						[];
'plotscalponly' 'real'			[]						[];
'events'		'real'			[]						[];
'showchan'		'integer'		[0 nchans]				0 ;
'signifs'		'real'			[]						[];
'sigthresh'		'integer'		[1 Inf]					[1 1];
'smooth'		'real'			[0 Inf]					1;
'timefreqs'		'real'			[]						[];
'ylabel'		'string'		{}						'Frequency (Hz)';
'vert'			'real'			[times(1) times(end)]	[min(max(0, times(1)), times(end))];
'denseLogTicks'	'string'		{'on','off'}			'off'
'tradeoff'		'real'			[0.5 2]					1;		% by tigoum
};

[g varargin] = finputcheck( varargin, fieldlist, 'tftopo', 'ignore');
if isstr(g), error(g); end;

	% setting more defaults
	% ---------------------
	if length(times) ~= size(tfdata,2)
		fprintf('tftopo(): tfdata columns must be a multiple of the length of times (%d)\n',...
		length(times));
		return
end
if length(g.showchan) > 1
	error('tftopo(): showchan must be a single number');
end;
if length(g.limits)<1 | isnan(g.limits(1))
	g.limits(1) = times(1);
end
if length(g.limits)<2 | isnan(g.limits(2))
	g.limits(2) = times(end);
end
if length(g.limits)<3 | isnan(g.limits(3))
	g.limits(3) = freqs(1);
end
if length(g.limits)<4 | isnan(g.limits(4))
	g.limits(4) = freqs(end);
end
if length(g.limits)<5 | isnan(g.limits(5)) % default caxis plotting limits
	g.limits(5) = -max(abs(tfdata(:)));
	mincax = g.limits(5);
end
if length(g.limits)<6 | isnan(g.limits(6))
	defaultlim = 1;
	if exist('mincax')
		g.limits(6) = -mincax; % avoid recalculation
	else
		g.limits(6) = max(abs(tfdata(:)));
	end
else
	defaultlim = 0;
end
if length(g.sigthresh) == 1
	g.sigthresh(2) = 1;
end;
if g.sigthresh(1) > nchans
	error('tftopo(): ''sigthresh'' first number must be less than or equal to the number of channels');
end;
if g.sigthresh(2) > size(tfdata,4)
	error('tftopo(): ''sigthresh'' second number must be less than or equal to the number of subjects');
end;
if ~isempty(g.signifs)
	if size(g.signifs,1) > 2 | size(g.signifs,2) ~= size(tfdata,1)| ...
			(size(g.signifs,3) ~= size(tfdata,3) & size(g.signifs,4) ~= size(tfdata,3))
			fprintf('tftopo(): error in ''signifs'' array size not compatible with data size, trying to transpose.\n');
			g.signifs = permute(g.signifs, [2 1 3 4]);
			if size(g.signifs,1) > 2 | size(g.signifs,2) ~= size(tfdata,1)| ...
				(size(g.signifs,3) ~= size(tfdata,3) & size(g.signifs,4) ~= size(tfdata,3))
				fprintf('tftopo(): ''signifs'' still the wrong size.\n');
				return
		end;
	end
end;
if length(g.selchans) ~= nchans,
	 selchans_opt = { 'plotchans' g.selchans };
else selchans_opt = { };
end;

% topoplot 용 option을 모두 하나로 묶는다
if ~isempty(varargin)
%	topoargs	=	{ topoargs{:} 'electrodes','on', selchan_opt{:} };
	topoargs	=	{ 'electrodes','on', selchans_opt{:} };
else
%	topoargs	=	{ topoargs{:} 'electrodes','on', selchan_opt{:} varargin{:}};
	topoargs	=	{ 'electrodes','on', selchans_opt{:} varargin{:}};
end

% only plot one scalp map
% -----------------------
if ~isempty(g.plotscalponly)
	[tmp fi] = min(abs(freqs-g.plotscalponly(2)));		% plotscalponly(2) == Hz
	[tmp ti] = min(abs(times-g.plotscalponly(1)));		% plotscalponly(1) == ms
	scalpmap = squeeze(tfdataori(fi, ti, :));

%	if ~isempty(varargin)
%		topoplot(scalpmap,g.chanlocs,'electrodes','on', selchans_opt{:}, varargin{:});
%	else
%		topoplot(scalpmap,g.chanlocs,'electrodes','on', selchans_opt{:});
%	end;
	% 'interlimits','electrodes')
	topoplot(scalpmap, g.chanlocs, topoargs{:});

	axis square;
	hold on
%	tl=title([int2str(g.plotscalponly(2)),' ms, ',int2str(g.plotscalponly(1)),' Hz']);
	tl=title([num2str(g.plotscalponly(2)),' ms, ',num2str(g.plotscalponly(1)),' Hz']);
	set(tl,'fontsize',AXES_FONTSIZE+3); % 13
	return;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Zero out non-significant image features
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
range = g.limits(6)-g.limits(5);
cc = jet(256);
if ~isempty(g.signifs)
	if strcmpi(g.verbose, 'on')
		fprintf('Applying ''signifs'' mask by zeroing non-significant values\n');
	end
	for subject = 1:size(tfdata,4)
		for elec = 1:size(tfdata,3)

			if size(g.signifs,1) == 2
				if ndims(g.signifs) > ndims(tfdata)
					tmpfilt = (tfdata(:,:,elec,subject) >= squeeze(g.signifs(2,:,:,elec, subject))') | ...
					(tfdata(:,:,elec,subject) <= squeeze(g.signifs(1,:,:,elec, subject))');
				else
					tmpfilt = (tfdata(:,:,elec,subject) >= repmat(g.signifs(2,:,elec, subject)', [1 size(tfdata,2)])) | ...
					(tfdata(:,:,elec,subject) <= repmat(g.signifs(1,:,elec, subject)', [1 size(tfdata,2)]));
				end;
			else
				if ndims(g.signifs) > ndims(tfdata)
					tmpfilt = (tfdata(:,:,elec,subject) >= squeeze(g.signifs(1,:,:,elec, subject))');
				else
					tmpfilt = (tfdata(:,:,elec,subject) >= repmat(g.signifs(1,:,elec, subject)', [1 size(tfdata,2)]));
				end;
			end;
			tfdata(:,:,elec,subject) = tfdata(:,:,elec,subject) .* tmpfilt;
		end;
	end;
end;

%%%%%%%%%%%%%%%%
% magnify inputs
%%%%%%%%%%%%%%%%
if g.smooth ~= 1
	if strcmpi(g.verbose, 'on'),
		fprintf('Smoothing...\n');
	end
	for index = 1:round(log2(g.smooth))
		[tfdata times freqs] = magnifytwice(tfdata, times, freqs);
	end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%
% Shift time/freq images
%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(g.shiftimgs)
	timestep = times(2) - times(1);
	for S = 1:size(tfdata,4)
		nbsteps = round(g.shiftimgs(S)/timestep);
		if strcmpi(g.verbose, 'on'),
			fprintf('Shifing images of subect %d by %3.3f ms or %d time steps\n', S, g.shiftimgs(S), nbsteps);
		end
		if nbsteps < 0,  tfdata(:,-nbsteps+1:end,:,S) = tfdata(:,1:end+nbsteps,:,S);
		else             tfdata(:,1:end-nbsteps,:,S)  = tfdata(:,nbsteps+1:end,:,S);
		end;
	end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%
% Adjust plotting limits
%%%%%%%%%%%%%%%%%%%%%%%%%
[tmp minfreqidx] = min(abs(g.limits(3)-freqs)); % adjust min frequency
g.limits(3) = freqs(minfreqidx);
[tmp maxfreqidx] = min(abs(g.limits(4)-freqs)); % adjust max frequency
g.limits(4) = freqs(maxfreqidx);

[tmp mintimeidx] = min(abs(g.limits(1)-times)); % adjust min time
g.limits(1) = times(mintimeidx);
[tmp maxtimeidx] = min(abs(g.limits(2)-times)); % adjust max time
g.limits(2) = times(maxtimeidx);

mmidx = [mintimeidx maxtimeidx minfreqidx maxfreqidx];	% 조정된 t, f 구간

colormap('jet');								% revived by tigoum
%c = colormap;
%cc = zeros(256,3);
%if size(c,1)==64
%    for i=1:3
%       cc(:,i) = interp(c(:,i),4);
%    end
%else
%    cc=c;
%end
%cc(find(cc<0))=0;
%cc(find(cc>1))=1;

%if exist('g.signif')
%  minnull = round(256*(g.signif(1)-g.limits(5))/range);
%  if minnull<1
%    minnull = 1;
%  end
%  maxnull = round(256*(g.signif(2)-g.limits(5))/range);
%  if maxnull>256
%    maxnull = 256;
%  end
%  nullrange = minnull:maxnull;
%  cc(nullrange,:) = repmat(cc(128,:),length(nullrange),1);
%end

%
%%%%%%%%%%%%%%%%  Compute title and axes font sizes %%%%%%%%%%%%%%%
%
pos = get(gca,'Position');							% topo 위치 계산 위한 포석
axis('off')
cla % clear the current axes
%{
if pos(4)>0.70
   titlefont= 16;
   axfont = 16;
elseif pos(4)>0.40
   titlefont= 14;
   axfont = 14;
elseif pos(4)>0.30
   titlefont= 12;
   axfont = 12;
elseif pos(4)>0.22
   titlefont= 10;
   axfont = 10;
else
   titlefont= 8;
   axfont = 8;
end
%}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot tfdata image for specified channel or selchans std()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
axis off;
%colormap(cc);									% remarked by tigoum
curax = gca; % current plot axes to plot into
tfpoints	=	size(g.timefreqs,1);			% ==0 if g.timefreqs == []
if tfpoints	~=	0
	plotdim = max(1+floor(tfpoints/2),4); % number of topoplots on top of image
	imgax=sbplot(plotdim,plotdim,[plotdim*(plotdim-1)+1,2*plotdim-1],'ax',curax);
else
	imgax = curax;
end;
tftimes = mmidx(1):mmidx(2);						% 실제 display 용 time idx
tffreqs = mmidx(3):mmidx(4);						% 실제 display 용 freq idx
if g.showchan>0 % -> image showchan data
	tfave = tfdata(tffreqs, tftimes, g.showchan);
else % g.showchan==0 -> image std() of selchans
	tfdat = tfdata(tffreqs, tftimes, g.selchans,:);

	% average across electrodes
	if strcmpi(g.verbose, 'on'),
		fprintf('Applying RMS across channels (mask for at least %d non-zeros values at each time/freq)\n', g.sigthresh(1));
	end
	tfdat = avedata(tfdat, 3, g.sigthresh(1), g.mode);

	% if several subject, first (RMS) averaging across subjects
	if size(tfdata,4) > 1
		if strcmpi(g.verbose, 'on'),
			fprintf('Applying RMS across subjects (mask for at least %d non-zeros values at each time/freq)\n', g.sigthresh(2));
		end
		tfdat = avedata(tfdat, 4, g.sigthresh(2), g.mode);
	end;
	tfave = tfdat;
end
if defaultlim										% 꼭 현재값 기반 한계 계산
	g.limits(6) = max(max(abs(tfave)));
	g.limits(5) = -g.limits(6);						% make symmetrical
end;

if ~isreal(tfave(1)), tfave = abs(tfave); end;

if strcmpi(g.logfreq, 'on'),
	PL	=	logimagesc(times(tftimes),freqs(tffreqs),tfave);
	axis([g.limits(1) g.limits(2) log(g.limits(3)), log(g.limits(4))]);
elseif strcmpi(g.logfreq, 'native'),
	PL	=	imagesc(times(tftimes),log(freqs(tffreqs)),tfave);
	axis([g.limits(1:2) log(g.limits(3:4))]);

	if g.denseLogTicks
		minTick = min(ylim);
		maxTick = max(ylim);
		set(gca,'ytick',linspace(minTick, maxTick,50));
	end;

	tmpval = get(gca,'yticklabel');
	if iscell(tmpval)
		ft = str2num(cell2mat(tmpval)); % MATLAB version >= 8.04
	else
		ft = str2num(tmpval);           % MATLAB version <  8.04
	end

	ft = exp(1).^ft;
	ft = unique_bc(round(ft));
	ftick = get(gca,'ytick');
	ftick = exp(1).^ftick;
	ftick = unique_bc(round(ftick));
	ftick = log(ftick);
	inds = unique_bc(round(exp(linspace(log(1), log(length(ft))))));
	set(gca,'ytick',ftick(inds(1:2:end)));
	set(gca,'yticklabel', num2str(ft(inds(1:2:end))));
else
	PL	=	imagesc(times(tftimes),freqs(tffreqs),tfave);	%tp(mn:mx), fq(mn:mx)
	axis([g.limits(1:4)]);
end;
caxis([g.limits(5:6)]);
hold on;
% ------------------------------
%% tf plot 중 가장 강한 power 가 있는 region을 찾아서 strike 존으로 boxing 함 %-[
% ------------------------------
	%% [peaks 기준] ..................................................
	ixORG		=	'tfave';
	ixREAD		=	[ ixORG '(:)' ];					% eval 위해 문자열
%	ixWRITE		=	'g.timefreqs(r,:) = [times(ixT) freqs(ixF)];'; % NaN 대체

	eval(['TFmx		=	max( findpeaks('  ixREAD '));']);
	eval(['TFmn		=	min(-findpeaks(-' ixREAD '));']);
	if TFmx >= abs(TFmn), TFpk = TFmx;	else, TFpk = TFmn; end% 절대값 기준
%	eval(['[ixF ixT] = ind2sub(size(' ixORG '), find(' ixREAD '==TFpk ));']);

%	eval([ ixWRITE ]);
	DominanceFreq=	TFpk;								% 중심 주파수

	%% 찾아진 point 에서 그 주변으로 경계(뚜렷한 차이가 나는) 범위 찾기
	[l, b, r, t]=	findbound(tfave, TFpk, 0.05);
	StrikeZone	=	[l, b, r, t];						% 스트라이크 zone
%{
	% 위치를 찾았음: 이 값들이 boxing 범위임
	BOX		=	rectangle(	'EdgeColor','r', 'LineWidth',2,			...
		'Position',[times(l), freqs(b), times(r)-times(l), freqs(t)-freqs(b)]);
%}
	%% [Z score 기준] ..................................................
	ixORG		=	'Z';
	ixREAD		=	[ 'reshape(Z(:,ixT0:end), numel(Z(:,ixT0:end)), 1)' ];%1D
%	ixWRITE		=	'g.timefreqs(r,:) = [times(ixT0+ixT-1) freqs(ixF)];';

	[~, ixT0]	=	min(abs( times-0 ));				% 시간 0 해당 idx

	Z			=	zscore( tfave );					% freq, tp 에 대해
	eval(['[Zmx, Zmn] = deal(max(' ixREAD '),min(' ixREAD '));']); %max,min
%	if Zmx >= abs(Zmn), Zpk = Zmx;	else, Zpk = Zmn; end% 절대값 기준
	if 0 <= TFpk,	Zpk	=	Zmx; else, Zpk = Zmn; end
%	eval(['[ixF ixT] = ind2sub(size(' ixORG '), find(' ixREAD '==Zpk ));']);
	% 참고: 만약 3 < Zpk (99%), 2 < Zpk (95%), 2 >= Zpk (그냥 max) 임.

%	eval([ ixWRITE ]);

	%% 찾아진 point 에서 그 주변으로 경계(뚜렷한 차이가 나는) 범위 찾기
	[l, b, r, t]=	findbound(Z, Zpk, 0.05);
	Zsignif_Zone=	[l, b, r, t];						% Z-value zone
%{
	BOX		=	rectangle(	'EdgeColor','b', 'LineWidth',2,			...
		'Position',[times(l), freqs(b), times(r)-times(l), freqs(t)-freqs(b)]);
%}
hold on;	%-]

% ------------------------------
TF_TP	=	g.tradeoff;	%0.8;			% TF/TP = 0.9
tfpos	=	get(gca, 'Position');		% appended by tigoum
set(gca,'Position',[tfpos(1) tfpos(2)+.05 tfpos(3)*TF_TP tfpos(4)*TF_TP]);% by tg
tfpos	=	get(gca, 'Position');		% update by tigoum

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process time/freq data points
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%----------------------------------------------------------------------
	%% nan값 기반 자동탐색 지시: tfave 기반 탐색을 하되, peaks의 max, min 찾음%-[
	%----------------------------------------------------------------------
	tf_nan			=	isnan( g.timefreqs );				% NaN 여부만 식별
if tfpoints == 0 | any(isnan(g.timefreqs(:)))	% nan 포함이면 정리 필요
	% g.timefreqs 의 어느 위치에 NaN 이 포함되었느냐에 따라 각기 다른 기능 구현
	% case1) [ 200 4 ; NaN   5 ; 500 6 ] : freq=5Hz 에서, max peak 있는 time 은 ?
	% case2) [ 200 4 ; 230 NaN ; 500 6 ] : time=230 에서, max peak 있는 freq 는 ?
	% case3) [ 200 4 ; NaN NaN ; 500 6 ] : TF전체에서 max peak 있는 time,freq는 ?

	if tfpoints == 0,	g.timefreqs	=	[ NaN NaN ];	end	% peaks 구하도록!

for r = 1 : size(g.timefreqs, 1)							% row 를 따라가자
	if		~isnan(g.timefreqs(r,1)) & ~isnan(g.timefreqs(r,2))	% [normal]
		continue;											% must!아래 공통실행X

	elseif	isnan(g.timefreqs(r,1)) & ~isnan(g.timefreqs(r,2))	% [case1: tp?]
		ixORG		=	'tfave(ix, :)';
		ixREAD		=	ixORG;								% eval 위해 문자열
		ixWRITE		=	'g.timefreqs(r,1) = times(ixT);';	% NaN->time 대체

%		[~, ix]		=	min(abs(times-g.timefreqs(r,1)));	% 시간 해당 idx
		[~, ix]		=	min(abs(freqs-g.timefreqs(r,2)));	% 주파수 해당 idx

	elseif	~isnan(g.timefreqs(r,1)) & isnan(g.timefreqs(r,2))	% [case2: fq?]
		ixORG		=	'tfave(:, ix)';
		ixREAD		=	ixORG;								% eval 위해 문자열
		ixWRITE		=	'g.timefreqs(r,2) = freqs(ixF);';	% NaN->freq 대체

		[~, ix]		=	min(abs(times-g.timefreqs(r,1)));	% 시간 해당 idx
%		[~, ix]		=	min(abs(freqs-g.timefreqs(r,2)))	% 주파수 해당 idx

	elseif	isnan(g.timefreqs(r,1)) &  isnan(g.timefreqs(r,2))	% [case3: t?f?]
		ixORG		=	'tfave';
		ixREAD		=	[ ixORG '(:)' ];					% eval 위해 문자열
		ixWRITE		=	'g.timefreqs(r,:) = [times(ixT) freqs(ixF)];'; % NaN 대체
	end

	% 추가적인 공통작업 수행
%		eval(['[TFmx, TFmn] = deal(max(' ixREAD '),min(' ixREAD '));']); %max,min
		eval(['TFmx		=	max( findpeaks('  ixREAD '));']);	% local max
		eval(['TFmn		=	min(-findpeaks(-' ixREAD '));']);	% local min

	% 20160406A. ! |local max|(==local min/max) 없다면? |global max| 를 구함
	if isempty(TFmx) & isempty(TFmn)
		eval(['TFmx		=	max(' ixREAD ');']);				% global max
		eval(['TFmn		=	min(' ixREAD ');']);				% global min
	end

		if TFmx >= abs(TFmn), TFpk = TFmx;	else, TFpk = TFmn; end% 절대값 기준
%		[ixF ixT]	=	ind2sub(ixSIZE, find( tfave(:) == TFpk ));
		eval(['[ixF ixT] = ind2sub(size(' ixORG '), find(' ixREAD '==TFpk ));']);

		eval([ ixWRITE ]);									% 최종 결과 저장

end	% for
end	% if	%-]

	%----------------------------------------------------------------------
	%% inf값 기반 자동탐색 지시: Z 기반 탐색을 하되, max, min 값을 찾음 %-[
	%----------------------------------------------------------------------
	tf_inf			=	isinf( g.timefreqs );				% inf 여부만 식별
	tf_Zpk			=	zeros( size(g.timefreqs,1) );		% inf 여부만 식별
if any(isinf(g.timefreqs(:)))	% inf 포함이면 정리 필요: 반드시 tp:0 이후 탐색
	% g.timefreqs 의 어느 위치에 inf 이 포함되었느냐에 따라 각기 다른 기능 구현
	% case1) [ 200 4 ; inf   5 ; 500 6 ] : freq=5hz 에서, max peak 있는 time 은 ?
	% case2) [ 200 4 ; 230 inf ; 500 6 ] : time=230 에서, max peak 있는 freq 는 ?
	% case3) [ 200 4 ; inf inf ; 500 6 ] : tf전체에서 max peak 있는 time,freq는 ?

for r = 1 : size(g.timefreqs, 1)							% row 를 따라가자
	if		~isinf(g.timefreqs(r,1)) & ~isinf(g.timefreqs(r,2))	% [normal]
		continue;

	elseif	isinf(g.timefreqs(r,1)) & ~isinf(g.timefreqs(r,2))	% [case1: tp?]
%		[~, ix]		=	min(abs(times-g.timefreqs(r,1)));	% 시간 해당 idx
		[~, ix]		=	min(abs(freqs-g.timefreqs(r,2)));	% 주파수 해당 idx
		ixORG		=	'Z(ix, ixT0:end)';					% 주파수는 항상 >0
		ixREAD		=	ixORG;								% eval 위해 문자열
		ixWRITE		=	'g.timefreqs(r,1) = times(ixT0+ixT-1);'; % inf->time 대체

	elseif	~isinf(g.timefreqs(r,1)) & isinf(g.timefreqs(r,2))	% [case2: fq?]
		ixORG		=	'Z(:, max(ixT0,ix))';				% 0 이상에서 탐색
		ixREAD		=	ixORG;								% eval 위해 문자열
		ixWRITE		=	'g.timefreqs(r,2) = freqs(ixF);';	% inf->freq 대체

		[~, ix]		=	min(abs(times-g.timefreqs(r,1)));	% 시간 해당 idx
%		[~, ix]		=	min(abs(freqs-g.timefreqs(r,2)))	% 주파수 해당 idx

	elseif	isinf(g.timefreqs(r,1)) &  isinf(g.timefreqs(r,2))	% [case3: t?f?]
		ixORG		=	'Z';
		ixREAD		=	[ 'reshape(Z(:,ixT0:end), numel(Z(:,ixT0:end)), 1)' ];%1D
		ixWRITE		=	'g.timefreqs(r,:) = [times(ixT0+ixT-1) freqs(ixF)];';
	end

	% 추가적인 공통작업 수행
		[~, ixT0]	=	min(abs( times-0 ));				% 시간 0 해당 idx

		Z			=	zscore( tfave );					% freq, tp 에 대해
		eval(['[Zmx, Zmn] = deal(max(' ixREAD '),min(' ixREAD '));']); %max,min

		if Zmx >= abs(Zmn), Zpk = Zmx;	else, Zpk = Zmn; end% 절대값 기준
%		[ixF ixT]	=	ind2sub(size(Z), find( Z(:) == Zpk ));
		eval(['[ixF ixT] = ind2sub(size(' ixORG '), find(' ixREAD '==Zpk ));']);
		% 참고: 만약 3 < Zpk (99%), 2 < Zpk (95%), 2 >= Zpk (그냥 max) 임.

		eval([ ixWRITE ]);
		tf_Zpk(r)	=	Zpk;								% Zpk 를 기억해야 함.

end	% for
end	% if	%-]

	%----------------------------------------------------------------------
if ~isempty(g.timefreqs)	% 위에서 정리했으므로, 여기서는 반드시 not empty 임!
	if size(g.timefreqs,2) == 2
		g.timefreqs(:,3) = g.timefreqs(:,2);				% 이중화 : 아래 예시
		g.timefreqs(:,4) = g.timefreqs(:,2);				% [ t1 t1 f1 f1 ]
		g.timefreqs(:,2) = g.timefreqs(:,1);				% [ t2 t2 f2 f2 ]
	end;
	if isempty(g.chanlocs)
		error('tftopo(): ''chanlocs'' must be defined to plot time/freq points');
	end;
	if min(min(g.timefreqs(:,[3 4])))<min(freqs)
		fprintf('tftopo(): selected plotting frequency %g out of range.\n',min(min(g.timefreqs(:,[3 4]))));
		return
	end
	if max(max(g.timefreqs(:,[3 4])))>max(freqs)
		fprintf('tftopo(): selected plotting frequency %g out of range.\n',max(max(g.timefreqs(:,[3 4]))));
		return
	end
	if min(min(g.timefreqs(:,[1 2])))<min(times)
		fprintf('tftopo(): selected plotting time %g out of range.\n',min(min(g.timefreqs(:,[1 2]))));
		return
	end
	if max(max(g.timefreqs(:,[1 2])))>max(times)
		fprintf('tftopo(): selected plotting time %g out of range.\n',max(max(g.timefreqs(:,[1 2]))));
		return
	end

	if 1 % USE USER-SUPPLIED SCALP MAP ORDER. A GOOD ALGORITHM FOR SELECTING
		 % g.timefreqs POINT ORDER GIVING MAX UNCROSSED LINES IS DIFFICULT!
		 [tmp tfi] = sort(g.timefreqs(:,1)); % sort on times
		 [tmp tm2 tm3 tm4] = deal(g.timefreqs, tf_nan, tf_inf, tf_Zpk);
		 for t=1:size(g.timefreqs,1)
			g.timefreqs	(t,:)	=	tmp(tfi(t),:);
			tf_nan		(t,:)	=	tm2(tfi(t),:);
			tf_inf		(t,:)	=	tm3(tfi(t),:);
			tf_Zpk		(t)		=	tm4(tfi(t));
		end
	end

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Compute timefreqs point indices
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	tfpoints = size(g.timefreqs,1);
	for f=1:tfpoints
		[tmp fi1] = min(abs(freqs-g.timefreqs(f,3)));
		[tmp fi2] = min(abs(freqs-g.timefreqs(f,4)));
		freqidx{f}=[fi1:fi2];							% g.timefreqs대응 실제idx
	end
	for f=1:tfpoints
		[tmp fi1] = min(abs(times-g.timefreqs(f,1)));	% 값 말고, idx 만 취함
		[tmp fi2] = min(abs(times-g.timefreqs(f,2)));
		timeidx{f}=[fi1:fi2];
	end
%else
%	tfpoints = 0;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Title and vertical lines
%%%%%%%%%%%%%%%%%%%%%%%%%%
axes(imgax)
%{
xl=xlabel('Time (ms)');
set(xl,'fontsize',AXES_FONTSIZE + 2);%12
set(gca,'yaxislocation','left')
%if g.showchan>0						% remarked by tigoum
	% tl=title(['Channel ',num2str(g.showchan)]);
	% set(tl,'fontsize',14);
%else
	if isempty(g.title)
		if strcmpi(g.mode, 'rms')
			tl=title(['Signed channel rms']);
		else
			tl=title(['Signed channel average']);
		end;
	else
		tl = title(g.title);
	end
	set(tl,'HorizontalAlignment','left');
	set(tl,'fontsize',AXES_FONTSIZE + 2); %12
	set(tl,'fontweight','normal');
	set(tl,'Interpreter','none');		% off for text processing
	set(tl,'Position',[pos(1) -3.1]);	% 밑바닥에 출력 -> tftopo 도 수정할 것!
	set(tl,'Visible','off');
%end
%}
% 20160407A. title 위치 TF graph plot(아래) 의 xlabel 밑 배열 난항 해법
% -> title을 별도의 title 명령으로 처리하지 말고, xlabel 에 속한 성분으로 처리
xl		=	xlabel([ 'Time (ms)' '/ ' g.title ]);
set(xl,'fontsize',AXES_FONTSIZE + 2);%12
set(xl,'Interpreter','none');			% off for text processing
set(gca,'yaxislocation','left')
%fpos	=	get(gcf,'units','points','position');
%set(gcf,'units','points','position', [fpos(1:3) fpos(4)+0.5] );

yl		=	ylabel(g.ylabel);
set(yl,'fontsize',AXES_FONTSIZE + 2);  %12

set(gca,'fontsize',AXES_FONTSIZE + 2); %12
set(gca,'ydir','normal');

for indtime = g.vert
	tmpy = ylim;
	htmp = plot([indtime indtime],tmpy,[LINECOLOR ':']);
	set(htmp,'linewidth',PLOT_LINEWIDTH)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot topoplot maps at specified timefreqs points
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(g.events)
	tmpy = ylim;
	yvals = linspace(tmpy(1), tmpy(2), length(g.events));
	plot(g.events, yvals, 'k', 'linewidth', 2);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute topoplot head width and separation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
head_sep = 0.1;
%topowidth = pos(3)/((6*tfpoints-1)/5); % width of each topoplot
topowidth	=	pos(3)/((6*tfpoints-1)/5) * (1/TF_TP);	% changed by tigoum
if topowidth> 0.25*pos(4) % dont make too large (more than 1/4 of axes width)!
	topowidth = 0.25*pos(4);
end

halfn = floor(tfpoints/2);
if rem(tfpoints,2) == 1  % odd number of topos
	topoleft = pos(3)/2 - (tfpoints/2+halfn*head_sep)*topowidth;
else % even number of topos
	topoleft = pos(3)/2 - ((halfn)+(halfn-1)*head_sep)*topowidth;
end
topoleft = topoleft - 0.01; % adjust left a bit for colorbar
%{
if max(plotframes) > frames |  min(plotframes) < 1
	fprintf('Requested map frame %d is outside data range (1-%d)\n',max(plotframes),frames);
	return
end
%}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot topoplot maps at specified timefreqs points, also oblique line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(g.timefreqs)							% 위의 조처로, 절대 not empty
	wholeax			=	sbplot(1,1,1,'ax',curax);
	topoaxes		=	zeros(1,tfpoints);
%%	pldm2			=	plotdim*TF_TP;				% plotdim==# of horiz topo: 4
	for n=1:tfpoints								% topo 작성
		if n<=plotdim								% tigoum rem: horiz direct.
			topoaxes(n)=sbplot(plotdim,plotdim,n,'ax',curax);
%			topoaxes(n)=sbplot(size, posi, N th, 'ax', curax);
%			topoaxes(n)	=sbplot(pldm2,plotdim,n,'ax',curax);
		else										% tigoum rem: vert direct.
			topoaxes(n)=sbplot(plotdim,plotdim,plotdim*(n+1-plotdim),'ax',curax);
%			topoaxes(n)	=sbplot(pldm2,plotdim,plotdim*(n+1-plotdim),'ax',curax);
		end

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Plot connecting lines using changeunits()
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		tmpTF = [ mean(g.timefreqs(n,[1 2])) mean(g.timefreqs(n,[3 4])) ]; %t x f
		if strcmpi(g.logfreq, 'off')
			from	=	changeunits(tmpTF,imgax,wholeax);			% 그래프 위치
		else
			from	=	changeunits([tmpTF(1) log(tmpTF(2))],imgax,wholeax);
		end;
%		to			=	changeunits([0.5,0.5],topoaxes(n),wholeax);
		to			=	changeunits([0.5,(TF_TP-1)/10],topoaxes(n),wholeax);%topo

		axes(wholeax);
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% move topo to plot's X position, if # of topo == 1 (갯수가 1개면 조정)
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		if tfpoints == 1
			to(1)	=	from(1);									% 수평일치
%			to(1)	=	0.1;
			tppos	=	get(topoaxes(n), 'Position');
			set(topoaxes(n), 'Position',[to(1)-0.0175*TF_TP^2	 ... % 미세조정
										tppos(2) tppos(3) tppos(4)]);
		end

		OL(n)		=	plot([from(1) to(1)],	[from(2) to(2)], ... % grp->topo
								[LINECOLOR ':'], 'linewidth',LINEWIDTH);
		hold on														% 위는 line
		MK(n)		=	plot(from(1), from(2),	[LINECOLOR 'o'],			...
						'markersize',3, 'markerfacecolor',LINECOLOR); % o 마커
%		set(MK,'markerfacecolor',LINECOLOR);
		axis([0 1 0 1]);
		axis off;
	end

%	endcaxis = 0;									% remarked by tigoum
	for n=1:tfpoints								% topo 작성
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Plot scalp map using topoplot()
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		axes(topoaxes(n));
		scalpmap = squeeze(mean(mean(tfdataori(freqidx{n},timeidx{n},:),1),2));

		%topoplot(scalpmap,g.chanlocs,'maplimits',[g.limits(5) g.limits(6)],...
		%            'electrodes','on');

%		if ~isempty(varargin)
%			topoplot(scalpmap,g.chanlocs,'electrodes','on', selchans_opt{:}, varargin{:});
%		else
%			topoplot(scalpmap,g.chanlocs,'electrodes','on', selchans_opt{:});
%		end;
		% 'interlimits','electrodes')
		topoplot(scalpmap, g.chanlocs, topoargs{:});

		axis square;
		hold on
		if g.timefreqs(n,1) == g.timefreqs(n,2)		% 특정 시점 지정 시

			% NaN에 의해 최대값 추출한 경우, 반드시 표기해 줄 것!
			sAdd	=	'';
			if		~tf_nan(n,1) & ~tf_nan(n,2),;
			elseif	tf_nan(n,1) & ~tf_nan(n,2),	sAdd = '(Max/Time)';
			elseif	~tf_nan(n,1) & tf_nan(n,2),	sAdd = '(Max/Freq)';
			elseif	tf_nan(n,1) & tf_nan(n,2),	sAdd = '(Max/T&F)';
			end
			% inf에 의해 Z기반 유의한 값 추출한 경우, 반드시 표기해 줄 것!
			if		~tf_inf(n,1) & ~tf_inf(n,2),;
			elseif	tf_inf(n,1) & ~tf_inf(n,2),
				sAdd=	['(' sprintf('%.2f',tf_Zpk(n)) ';Sg./Time)'];
			elseif	~tf_inf(n,1) & tf_inf(n,2),
				sAdd=	['(' sprintf('%.2f',tf_Zpk(n)) ';Sg./Freq)'];
			elseif	tf_inf(n,1) & tf_inf(n,2),
				sAdd=	['(' sprintf('%.2f',tf_Zpk(n)) ';Sg./T&F)'];
			end
			tl		=	title({	...
			[num2str(g.timefreqs(n,1)),'ms, ' num2str(g.timefreqs(n,3)),'Hz'];...
			[sprintf('%.3f',tfave(freqidx{n}, timeidx{n})) '\muV^2' sAdd]	});

		else										% 범위형식으로 지정 시
			tl		=	title(	...
			[num2str(g.timefreqs(n,1)) '-' num2str(g.timefreqs(n,2)) 'ms, ' ...
			num2str(g.timefreqs(n,3)) '-' num2str(g.timefreqs(n,4)) ' Hz']);
		end;
		set(tl,'fontsize',AXES_FONTSIZE + 3); %13
%		endcaxis = max(endcaxis,max(abs(caxis)));	% remarked by tigoum
		caxis([g.limits(5:6)]);						% important/revived by tg
	end;
	if strcmpi(g.cmode, 'common')
	for n=1:tfpoints								% topo 작성
		axes(topoaxes(n));
%		caxis([-endcaxis endcaxis]);
		limits		=	caxis;
		if n==tfpoints & strcmpi(g.cbar, 'on') % & (mod(tfpoints,2)~=0) % image color bar by last map
			cb		=	cbar;
			BS		=	0.08;						% appended by tigoum
%			set(cb,	'Position',		[pos(1:2) 0.023 pos(4)]); % with topo
			set(cb,	'Position',[tfpos(1)+tfpos(3)+0.005 BS+.05 BS/4 tfpos(4)]);
									% modified a axis with tfplot
			set(cb,	'fontsize',AXES_FONTSIZE + 2); %12
			set(cb,	'YLimMode',		'manual');		% appended by tigoum
			set(cb,	'YLim',			[limits]);		% appended by tigoum

			cbyl	=	get(cb, 'YTickLabel');		% cbar의 수치 목록 받기
			ix		=	find(strcmp(cbyl, '0'));	% '0' 의 index 찾기
			cbyl{ix}=	['0' ' ' '\muV^2'];			% 단위 추가
			set(cb, 'YTickLabel', cbyl);			% 재등록
		end
		drawnow
	end
	end;
end;

if g.showchan>0 & ~isempty(g.chanlocs)		% 마우스 event 시 지워지는 현상!
	sb		=	sbplot(4,4,1,'ax',imgax);
	axis('square');
	sbpos	=	get(sb, 'Position');
	tc		=	topoplot(g.showchan,g.chanlocs,'electrodes','off', ...
		'style', 'blank', 'emarkersize1chan', 10 );
	set(sb, 'Position', [sbpos(1) sbpos(2)+0.01 sbpos(3) sbpos(4)]); % 약간 위로

	sb		=	sbplot(4,4,5,'ax',imgax);			% 아래편 공간에 title 출력
	set(sb, 'Visible', 'off');						% topo 아래 subplot 내용 끔
	set(get(sb,'Title'),'Visible','on');			% 단, title만 살림
	sCh		=	regexprep(g.title, '.*TF \(Ch:([A-Za-z0-9]+)\).*', '$1');
	ttl		=	title(['[' sCh ']'],	'VerticalAlignment','bottom',	...
										'fontsize',AXES_FONTSIZE+2); % 12
end
%{
if strcmpi(g.axcopy, 'on')				% g.axcopy 가 정의 되어 있지 않음!
	if strcmpi(g.logfreq, 'native'),
		com = [ 'ft = str2num(get(gca,''''yticklabel''''));' ...
		'ft = exp(1).^ft;' ...
		'ft = unique_bc(round(ft));' ...
		'ftick = get(gca,''''ytick'''');' ...
		'ftick = exp(1).^ftick;' ...
		'ftick = unique_bc(round(ftick));' ...
		'ftick = log(ftick);' ...
		'set(gca,''''ytick'''',ftick);' ...
		'set(gca,''''yticklabel'''', num2str(ft));' ];
		axcopy(gcf, com); % turn on axis copying on mouse click
	else
		axcopy; % turn on axis copying on mouse click
	end;
end
%}
%
% Turn on axcopy()
%

% clicking on TF pop_up topoplot
% -------------------------------
disp('Click on TF waveform to show scalp map at specific latency');

dat.tf			=	tfdataori;		% for scalp(topo plot)
dat.ave			=	tfave;			% for imagesc(TF plot)
dat.times		=	times;									% 시간 all
dat.freqs		=	freqs;									% 주파수 all
dat.ixtimes		=	tftimes;								% 시간 disp
dat.ixfreqs		=	tffreqs;								% 주파수 disp
dat.logfreq		=	g.logfreq;								% log 취하는 여부
dat.chanlocs	=	g.chanlocs;
dat.options		=	topoargs;
dat.trate		=	(size(tfdataori,2)-1)/(times(end)-times(1))*1000;
dat.frate		=	(size(tfdataori,1)-1)/(freqs(end)-freqs(1))*1;
dat.oline		=	OL;										% oblique line
dat.mline		=	MK;										% marker
%dat.xline		=	XL;										% tp 상의 수직선
dat.limits		=	g.limits(5:6);							% color limit
dat.axesA		=	wholeax;								% 전체 좌표계
dat.axesD		=	imgax;									% plot 좌표계
dat.axes		=	topoaxes;								% 각 topo의 좌표

%{
	'olX		=	get(DATA.xline, ''XData'');'							...
	'olX(1)		=	tmppos(1);'												...
	'olX(2)		=	tmppos(1);'												...
	'set(DATA.xline, ''XData'', olX);'									...
	'set(DATA.xline, ''Visible'', ''on'');'								...
	'	'																	...
%		scalpmap = squeeze(tfdataori(fi, ti, :));
%}
cb_code			=	[		...
	'POS		=	get(gca, ''currentpoint'');'							...
	'DATA		=	get(gcf, ''userdata'');'								...
	'	'																	...
	'if strcmpi(DATA.logfreq, ''off''),'									...
	'	from	=changeunits([POS(1,1)		POS(1,2)],DATA.axesD,DATA.axesA);'...
	'else,'																	...
	'	from	=changeunits([POS(1,1) log(POS(1,2))],DATA.axesD,DATA.axesA);'...
	'end;'																	...
	'	'																	...
	'axes(DATA.axesA);'														...
	'	'																	...
	'olX		=	get(DATA.oline(end), ''XData'');'						...
	'olY		=	get(DATA.oline(end), ''YData'');'						...
	'olX(1)		=	from(1);'												...
	'olY(1)		=	from(2);'												...
	'set(DATA.oline(end), ''XData'', olX);'									...
	'set(DATA.oline(end), ''YData'', olY);'									...
	'	'																	...
	'olX		=	get(DATA.mline(end), ''XData'');'						...
	'olY		=	get(DATA.mline(end), ''YData'');'						...
	'olX(1)		=	from(1);'												...
	'olY(1)		=	from(2);'												...
	'set(DATA.mline(end), ''XData'', olX);'									...
	'set(DATA.mline(end), ''YData'', olY);'									...
	'	'																	...
	'hold on;'																...
	'	'																	...
	'set(DATA.oline, ''Visible'', ''on'');'									...
	'set(DATA.mline, ''Visible'', ''on'');'									...
	'	'																	...
	'axes(DATA.axes(end)); cla;'											...
	'timepoint	=	round((POS(1,1)-DATA.times(1))/1000	*DATA.trate);'		...
	'freqpoint	=	round((POS(1,2)-DATA.freqs(1))/1	*DATA.frate);'		...
	'title({[sprintf(''%.0fms, %.0fHz'', POS(1,1), POS(1,2))];'				...
	'		[sprintf(''%.5f'', DATA.ave(freqpoint,timepoint)) ''\muV^2'']});' ...
	'scalpmap	= squeeze(mean(mean(DATA.tf(freqpoint,timepoint,:),1),2));' ...
	'topoplot(scalpmap, DATA.chanlocs, DATA.options{:});'					...
	'caxis([DATA.limits]);'													...
	'	'																	...
	'clear olY olX from timepoint freqpoint DATA POS;'						...
					];
axcopy;

set(gcf,	'userdata', dat);
set(imgax,	'ButtonDownFcn', cb_code); %windowbuttondownfcn', cb_code);
set(PL,		'ButtonDownFcn', cb_code);
%}

%axcopy(gcf, cb_code);

%%%%%%%%%%%%%%%%%%%%%%%% embedded functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tfdat = avedata(tfdat, dim, thresh, mode)
tfsign  = sign(mean(tfdat,dim));
tfmask  = sum(tfdat ~= 0,dim) >= thresh;
if strcmpi(mode, 'rms')
		tfdat   = tfmask.*tfsign.*sqrt(mean(tfdat.*tfdat,dim)); % std of all channels
	else
		tfdat   = tfmask.*mean(tfdat,dim); % std of all channels
	end;

	function [tfdatnew, times, freqs] = magnifytwice(tfdat, times, freqs);
	indicetimes = [floor(1:0.5:size(tfdat,1)) size(tfdat,1)];
	indicefreqs = [floor(1:0.5:size(tfdat,2)) size(tfdat,2)];
	tfdatnew = tfdat(indicetimes, indicefreqs, :, :);
	times = linspace(times(1), times(end), size(tfdat,2)*2);
	freqs = linspace(freqs(1), freqs(end), size(tfdat,1)*2);

	% smoothing
	gauss2 = gauss2d(3,3);
	for S = 1:size(tfdat,4)
		for elec = 1:size(tfdat,3)
			tfdatnew(:,:,elec,S) = conv2(tfdatnew(:,:,elec,S), gauss2, 'same');
		end;
	end;
	%tfdatnew = convn(tfdatnew, gauss2, 'same'); % is equivalent to the loop for slowlier

% ------------------------------
function [l, b, r, t] = findbound(Z, Zpk, VAR)
%% 찾아진 point 에서 그 주변으로 경계(뚜렷한 차이가 나는) 범위를 찾아야 함
% 방법:
%	1. ixF, ixT 지점의 Z score와 0.05 이하로 차이가 나는 가장 먼 t, f 인덱스
%	2. ixF, ixT 지점부터 box를 키워가며 그 내부값의 평균이 ixF, ixT 지점 Z
%		값과 0.05 이상 벌어질 때까지 확장
%	3. 이때, 한쪽 방향으로만 추적하고, 나머지 방향에 대한 값은 초기값 유지!
% ------------------------------
% param@	Z		: 대상 data matrix
%			Zpk		: Z 에 존재하는 최대값
%			color	: box color
% ------------------------------
	[ixF ixT]	=	ind2sub(size(Z), find( Z(:) == Zpk ));

%	for l = ixT-1:-1:1			% Z 에는 +,- 값 혼재 -> all + 후 평균 취해야 함
	for l = ixT:-1:1 %ixT==1고려% Z 에는 +,- 값 혼재 -> all + 후 평균 취해야 함
		if mean(abs(reshape(Z(ixF,l:ixT)-Zpk, ixT-l+1, 1)))>=VAR, break; end
	end

	for r = ixT+0 : size(Z,2)	% ixT == size(Z,2)
%		Zbox		=	Z(ixF, ixT:r) - Z(ixF, ixT);
%		if mean(abs(Zbox(:))) >= VAR, break; end
		if mean(abs(reshape(Z(ixF,ixT:r)-Zpk, r-ixT+1, 1)))>=VAR, break; end
	end

%	for b = ixF-1:-1:1
	for b = ixF:-1:1			% ixT==1고려
%		Zbox		=	Z(b:ixF, ixT) - Z(ixF, ixT);
%		if mean(abs(Zbox(:))) >= VAR, break; end
		if mean(abs(reshape(Z(b:ixF,ixT)-Zpk, ixF-b+1, 1)))>=VAR, break; end
	end

	for t = ixF+0 : size(Z,1)					% 주파수 축(세로)의 위 방향
%		Zbox		=	Z(ixF:t, ixT) - Z(ixF, ixT);
%		if mean(abs(Zbox(:))) >= VAR, break; end
		if mean(abs(reshape(Z(ixF:t,ixT)-Zpk, t-ixF+1, 1)))>=VAR, break; end
	end

	return
