% timtopo()   - plot all channels of a data epoch on the same axis 
%               and map its scalp map(s) at selected latencies.
% Usage:
%  >> timtopo(data, chan_locs);
%  >> timtopo(data, chan_locs, 'key', 'val', ...);
% Inputs:
%  data       = (channels,frames) single-epoch data matrix
%  chan_locs  = channel location file or EEG.chanlocs structure. 
%               See >> topoplot example for file format.
%
% Optional ordered inputs:
%ORG: 'limits'    = [minms maxms minval maxval]
%NEW: 'limits'    = [minms maxms minval maxval mintopo maxtopo] %edited by tigoum
%					data limits for latency (in ms) and y-values
%					(assumes uV) {default|0 -> use [0 npts-1 data_min data_max];
%					else [minms maxms] or [minms maxms 0 0] -> use
%					[minms maxms data_min data_max min_for_topo max_for_topo]
%
% 'plottimes'  = [vector] latencies (in ms) at which to plot scalp maps 
%                {default|NaN -> latency of maximum variance}
% 'title'      = [string] plot title {default|0 -> none}
% 'plotchans'  = vector of data channel(s) to plot. Note that this does not
%                affect scalp topographies {default|0 -> all}
% 'voffsets'   = vector of (plotting-unit) distances vertical lines should extend
%                above the data (in special cases) {default -> all = standard}
%
%% 'tradeoff'  = value of real(float) for ratio of TFplot/TOPOplot {default: 1.0}
%%	appended by tigoum
%
% Optional keyword, arg pair inputs (must come after the above):
% 'topokey','val' = optional topoplot() scalp map plotting arguments. See >> help topoplot 
%
% Author: Scott Makeig, SCCN/INC/UCSD, La Jolla, 1-10-98 
%
% See also: envtopo(), topoplot()

% Copyright (C) 1-10-98 Scott Makeig, SCCN/INC/UCSD, scott@sccn.ucsd.edu
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

% 5-31-00 added o-time line and possibility of plotting 1 channel -sm & mw
% 11-02-99 added maplimits arg -sm
% 01-22-01 added to help message -sm
% 01-25-02 reformated help & license, added link -ad 
% 03-15-02 add all topoplot options -ad

function M = timtopo(data, chan_locs, varargin)

MAX_TOPOS = 24;

if nargin < 1 %should this be 2?
   help timtopo;
   return
end

if 3 <= length(size(data)), fCond	=	true; else fCond = false; end % add by tg

if fCond
	[chans,frames,condi]=	size(data);	% all data element matrix size is same!
else
	[chans,frames]		=	size(data);
end
icadefs;

% 
% if nargin > 2
%     if ischar(limits)
%         varargin = { limits,plottimes,titl,plotchans,voffsets varargin{:} };
%         
%     else
%         varargin = { 'limits' limits 'plottimes' plottimes 'title' titl 'plotchans' plotchans 'voffsets' voffsets varargin{:} };        
%     end;
% end;

if nargin > 2 && ~ischar(varargin{1})
   options = {};
   if length(varargin) > 0, options = { options{:} 'limits'    varargin{1}}; end;
   if length(varargin) > 1, options = { options{:} 'plottimes' varargin{2}}; end;
   if length(varargin) > 2, options = { options{:} 'title'     varargin{3}}; end;
   if length(varargin) > 3, options = { options{:} 'plotchans' varargin{4}}; end;
   if length(varargin) > 4, options = { options{:} 'voffsets'  varargin{5}}; end;
   if length(varargin) > 5, options = { options{:} varargin{6:end} }; end;
else
   options = varargin;
end;

fieldlist={	'limits'		'real'		[]			0;
			'plottimes'		'real'		[]			[];
			'title'			'string'	[]			'';
			'plotchans'		'integer'	[1:chans]	0;
			'tradeoff'		'real'		[0.5 2]		1;	% by tigoum
			'minmax'		'integer'	[1 3]		1;	% 1=min, 2=max, 3=minmax
			'voffsets'		'real'		[]			[] ;};
[g topoargs] = finputcheck(options, fieldlist, 'timtopo', 'ignore');

if ischar(g), error(g); end;
%Set Defaults
if isempty(g.title), g.title = ''; end;
if isempty(g.voffsets) || g.voffsets == 0, g.voffsets = zeros(1,MAX_TOPOS); end;
if isempty(g.plotchans) || isequal(g.plotchans,0), g.plotchans = 1:chans; end;
plottimes_set	=	1;	% flag variable
if isempty(g.plottimes) || any(isnan(g.plottimes)) || any(isinf(g.plottimes)),...
	plottimes_set = 0;	end;
limitset		=	0;	%flag variable
if isempty(g.limits), g.limits = 0; end;
if length(g.limits)>1, limitset = 1; end;

% if nargin < 7 | voffsets == 0
%   voffsets = zeros(1,MAX_TOPOS);
% end
% 
% if nargin < 6
%    plotchans = 0;
% end
% 
% if plotchans==0
%    plotchans = 1:chans;
% end
% 
% if nargin < 5,
%    titl = '';     % DEFAULT NO TIXLE
% end
% 
% plottimes_set=1;   % flag variable
% if nargin< 4 | isempty(plottimes) | any(isnan(plottimes))
%    plottimes_set = 0;
% end
% 
% limitset = 0;
% if nargin < 3,
%     limits = 0;
% elseif length(limits)>1
%     limitset = 1;
% end

if nargin < 2 %if first if-statement is changed to 2 should this be 3?
    chan_locs = 'chan.locs';  % DEFAULT CHAN_FILE
end
if isnumeric(chan_locs) && chan_locs == 0,
    chan_locs = 'chan.locs';  % DEFAULT CHAN_FILE
end


	%
	%%%%%%%%%%%%%%%%%%%%%% Read and adjust limits %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% data == 3D 구조면 신경 써야 함.
	%
	% defaults: limits == 0 or [0 0 0 0]
	if (length(g.limits)==1&g.limits==0) | (length(g.limits)>=4&~any(g.limits))
		xmin		=	0;
		xmax		=	frames-1;
		ymin		=	min(data(:));	%min(min(data));
		ymax		=	max(data(:));	%max(max(data));
		g.limits(3)	=	ymin;
		g.limits(4)	=	ymax;
		g.limits(5)	=	ymin;
		g.limits(6)	=	ymax;
	elseif length(g.limits) == 2  % [minms maxms] only
		xmin		=	g.limits(1);
		xmax		=	g.limits(2);
		ymin		=	min(data(:));	%min(min(data));
		ymax		=	max(data(:));	%max(max(data));
		g.limits(3)	=	ymin;
		g.limits(4)	=	ymax;
		g.limits(5)	=	ymin;
		g.limits(6)	=	ymax;
	elseif length(g.limits) >= 4							% edited by tigoum
		xmin		=	g.limits(1);
		xmax		=	g.limits(2);
		if any(g.limits([3 4]))
			ymin	=	g.limits(3);
			ymax	=	g.limits(4);
		else % both 0
			ymin	=	min(data(:));	%min(min(data));
			ymax	=	max(data(:));	%max(max(data));
		g.limits(3)	=	ymin;
		g.limits(4)	=	ymax;
		end

		if (length(g.limits) == 5 & ~any(g.limits(5))) |	...
			length(g.limits) == 6 & ~any(g.limits([5 6]))	% appended by tigoum
		g.limits(5)	=	ymin;
		g.limits(6)	=	ymax;
		end
	else
		fprintf('timtopo(): limits format not correct. See >> help timtopo.\n');
		return
	end;

  if xmax == 0 & xmin == 0,
    x = (0:1:frames-1);
    xmin = 0;
    xmax = frames-1;
  else
    dx = (xmax-xmin)/(frames-1);
    x=xmin*ones(1,frames)+dx*(0:frames-1); % compute x-values
  end;
  if xmax<=xmin,
      fprintf('timtopo() - in limits, maxms must be > minms.\n')
      return
  end

  if ymax == 0 & ymin == 0,
      ymax=max(max(data(:)));
      ymin=min(min(data(:)));
  end
  if ymax<=ymin,
      fprintf('timtopo() - in limits, maxval must be > minmval.\n')
      return
  end

sampint = (xmax-xmin)/(frames-1); % sampling interval = 1000/srate;
x = xmin:sampint:xmax;   % make vector of x-values

%
%%%%%%%%%%%%%%% Preparing plot data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 이제 데이터를 파라미터 조합에 맞춰 다시 단일 2D 형 데이터로 가공!
% 1. DispCh == 0 (모든 채널) 인 경우
%	-> 각 array별로 ch 차원을 평균낸다.
%	-> 각 array별로 time vector만 남는다.
%	-> 각 array 데이터를 ch 들의 데이터 처럼 하나로 합침
if fCond											% appended by tigoum
	if g.plotchans == 0
		target	=	squeeze(mean(data,1));			% ch 차원의 평균 -> 2D 축약

	else	%if length(g.plotchans) == 1
	% 2. DispCh == 'Cz' ... (특정 채널 1 or 다수 지정) 인 경우
	%	-> 각 array별로 해당 채널의 평균을 수행
	%	-> 각 array별로 time vector만 남는다.
	%	-> 각 array 데이터를 ch 들의 데이터 처럼 하나로 합침
		target	=	squeeze(mean(data(g.plotchans,:,:),1));	% ch단일화 -> 2D축약
	end
else
	target		=	[];								% fCond 아니면 []
end

%
%%%%%%%%%%%%%%% Compute plot times/frames %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
fgPeakOfMax				=	2~=g.minmax;			% max값(min 아님) 기준 peak
fgPeakOfMin				=	1~=g.minmax;			% min값(max 아님) 기준 peak
fgSingleMax				=	false;					% false : fCond & 개별 max
if plottimes_set == 0
	[g.plottimes mxplottime]=S_calcMinMax(x,data, g.plottimes, fCond,target, ...
										fgPeakOfMax, fgPeakOfMin, fgSingleMax);

	if ~isempty(g.plottimes), plottimes_set=1; end	% param으로 [] 올 때는 존중
else
	mxplottime			=	[];	%g.plottimes(1);					% 최대값 기억
end

if plottimes_set == 1
	if fCond										% if it includeded condition
		ntopos = size(data,3);						% 조건만큼 topo 생성
	else
		ntopos = length(g.plottimes);				% 단일 array 면 기본 방식
	end

	if ntopos > MAX_TOPOS
		fprintf(['timtopo(): too many plottimes - only first %d will be'	...
				'shown!\n'], MAX_TOPOS);
		g.plottimes = g.plottimes(1:MAX_TOPOS);
		ntopos = MAX_TOPOS;
	end

	if max(g.plottimes) > xmax | min(g.plottimes)< xmin
		fprintf(['timtopo(): at least one plottimes value outside of epoch' ...
				'latency range - cannot plot.\n']);
		return
	end

	if ~fCond, g.plottimes = sort(g.plottimes); end	% 20160704A. 교정!
	% put map latencies in ascending order, else map lines would cross.

	xshift = [x(2:frames) xmax+1]; % 5/22/2014 Ramon: '+1' was added to avoid errors when time== max(x) in line 231
	plotframes = ones(size(g.plottimes));			% topo별 plot 인덱스 목록
	for t = 1:ntopos
		time = g.plottimes(t);
		plotframes(t) = find(time>=x & time < xshift);
	end
else
	ntopos	=	0;
end

vlen = length(g.voffsets); % extend voffsets if necessary
i=1;
while vlen< ntopos
	g.voffsets = [g.voffsets g.voffsets(i)];
	i=i+1;
	vlen=vlen+1;
end

%
%%%%%%%%%%%%%%%%  Compute title and axes font sizes %%%%%%%%%%%%%%%
%
pos = get(gca,'Position');
axis('off')
cla % clear the current axes
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

%
%%%%%%%%%%%%%%%% Compute topoplot head width and separation %%%%%%%%%%%%%%%
%
TM_TP		=	g.tradeoff;	%0.8;						% TM/TP = 0.9
head_sep = 0.1;
%topowidth = pos(3)/((6*ntopos-1)/5); % width of each topoplot
topowidth	=	pos(3)/((6*ntopos-1)/5) * (1/TM_TP);	% changed by tigoum
if topowidth> 0.25*pos(4) % dont make too large (more than 1/4 of axes width)!
  topowidth = 0.25*pos(4);
end

halfn = floor(ntopos/2);
if rem(ntopos,2) == 1  % odd number of topos
   topoleft = pos(3)/2 - (ntopos/2+halfn*head_sep)*topowidth;
else % even number of topos
   topoleft = pos(3)/2 - ((halfn)+(halfn-1)*head_sep)*topowidth;
end
topoleft = topoleft - 0.01; % adjust left a bit for colorbar

if 0 < ntopos & (max(plotframes) > frames | min(plotframes) < 1)
    fprintf('Requested map frame %d is outside data range (1-%d)\n',max(plotframes),frames);
    return
end

%
%%%%%%%%%%%%%%%%%%%% Print times and frames %%%%%%%%%%%%%%%%%%%%%%%%%%
%

fprintf('Scalp maps will show latencies: ');
for t=1:ntopos
  fprintf('%4.0f ',g.plottimes(t));
end
fprintf('\n');
fprintf('                     at frames: ');
for t=1:ntopos
  fprintf('%4d ',plotframes(t));
end
fprintf('\n');

%
%%%%%%%%%%%%%%%%%%%%%%% Plot the data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
%%%%%%%%%%%% site the plot at bottom of the figure %%%%%%%%%%%%%%%%%%
%
axdata	=	axes('Units','Normalized',				...
			'Position',[pos(1) pos(2)+.05 pos(3) 0.6*pos(4)],		...
			'FontSize',axfont);			% 바닥에 title 표시 위해 plot 을 띄움
set(axdata,'Color',BACKCOLOR);

%g.limits = get(axdata,'Ylim')			% remarked by tigoum
set(axdata,'GridLineStyle',':')
set(axdata,'Xgrid','off')
set(axdata,'Ygrid','on')
axes(axdata)
axcolor	=	get(gcf,'Color');
set(axdata,'Color',BACKCOLOR);

if fCond
	target		=	shiftdim(target,1);		% condi(like ch.) x time
	PL			=	plot(x, target');		% 전체 plot

	% legend 출력해서 condi 들 구분
	sCondi		=	regexprep(g.title, 'Condition\((.*)\)''s.*', '$1');
	sCondi		=	strsplit(sCondi, ', ');	% return as cell
%	legend(sCondi, 'Location','eastoutside', 'Orientation','vertical');%바깥
	legend(sCondi, 'Location','northwest', 'Orientation','vertical'); % 좌상단
	g.title		=	regexprep(g.title, '(Condition)\(.*\)(''s.*)',	...
								[num2str(length(sCondi)) ' $1$2']);

else
	PL			=	plot(x, data(g.plotchans,:)');			% plot the data
	if length(g.plotchans)==1
		set(PL,'color','k');
		set(PL,'linewidth',2);
	end
end

xl = xlabel('Latency (ms)');
set(xl,'FontSize',axfont);
yl = ylabel('Potential (\muV)');
set(yl,'FontSize',axfont,'FontAngle','normal');
axis([xmin xmax ymin ymax]);
hold on
%
plpos	=	get(gca, 'Position');		% appended by tigoum
set(gca, 'Position', [plpos(1) plpos(2) plpos(3)*TM_TP plpos(4)*TM_TP]); % by tg
%tmpos	=	get(gca, 'Position');		% updated by tigoum
%
%%%%%%%%%%%%%%%%%%%%%%%%% Plot zero time line %%%%%%%%%%%%%%%%%%%%%%%%%%
%
lwidth = 1.0;	%1.5;  % increment line thickness

if xmin<0 & xmax>0
  plot([0 0],[ymin ymax],'k:', 'linewidth',lwidth);
else
  fprintf('xmin %g and xmax %g do not cross time 0.\n',xmin,xmax)
end

if ymin<0 & ymax>0
  plot([xmin xmax],[0 0],'k:', 'linewidth',lwidth);
else
  fprintf('ymin %g and ymax %g do not cross time 0.\n',ymin,ymax)
end
%
%%%%%%%%%%%%%%%%%%%%%%%%% Plot max time line %%%%%%%%%%%%%%%%%%%%%%%%%%
% max 값 가지는 timepoint 에 수직선으로 표기
if plottimes_set
if fCond
	XL		=	plot([g.plottimes(1)		g.plottimes(1)],				...
					[ymin ymax], 'r:', 'linewidth',lwidth);
	set(XL, 'Visible', 'off');				% make this-figure invisible
else
	XL		=	plot([g.plottimes(ntopos)	g.plottimes(ntopos)],			...
					[ymin ymax], 'r:', 'linewidth',lwidth);
	set(XL, 'Visible', 'off');				% make this-figure invisible
end
end
%
%%%%%%%%%%%%%%%%%%%%%%%%% Draw vertical lines %%%%%%%%%%%%%%%%%%%%%%%%%%
%	-> 'plottime' 에 명시된 시간에서, 2D 그래프 상의 line 수직 위치로 푸른 직선
width  = xmax-xmin;
height = ymax-ymin;

if plottimes_set & fCond % multi cond 방식: 단 1개의 tp 에서만 직선 그어주면 됨
	%% topo 는 조건 갯수 만큼 그릴 거지만, 2D 상에 수직 라인 표기는 1개만!
	% line 383 에서 구해놓은 target(== condi x timepoint) 을 사용한다.
	pt			=	g.plottimes(1);
	pf			=	plotframes(1);
%	if g.voffsets(1) | length(g.plotchans)>1

		% display에서 mouse 클릭시, 표기해야 할 수직선을 미리 구성해 둠
		%	-> 설정과정이 복잡하므로, mouse 클릭시 최소 설정만 해도 되도록 준비
		% red line
		VL		=	plot([pt pt],	[min(target(:,pf))						...
			max(target(:,pf))+g.voffsets(1)],'r', 'linewidth', lwidth);
		set(VL, 'Visible', 'off');			% make this-figure invisible

		% 최대값 위치에 수직 bar 표기
		% white underline behind
		WL		=	plot([pt pt],	[min(target(:,pf))						...
			max(target(:,pf))+g.voffsets(1)],'w', 'linewidth', lwidth*2);
		%----------
		% blue line
		BL		=	plot([pt pt],	[min(target(:,pf))						...
			max(target(:,pf))+g.voffsets(1)],'b', 'linewidth', lwidth);
%	end
	clear pf pt;

else		% 단일 조건(1 data) 에선 'plottimes'에 명시된 갯수 대로 라인 표시
	VL			=	[];						% 초기상태는 empty
	for t=1:ntopos % draw vertical lines through the data at topoplot frames
	 if length(g.plotchans)>1 | g.voffsets(t)
		% --------------------------------------------------
		if t == ntopos						% 맨 마지막 위치가 max 임
		% display에서 mouse 클릭시, 표기해야 할 수직선을 미리 구성해 둠
		%	-> 설정과정이 복잡하므로, mouse 클릭시 최소 설정만 해도 되도록 준비
		% red line
			VL	=	plot([g.plottimes(t) g.plottimes(t)],					...
				[min(data(g.plotchans,plotframes(t)))						...
				max(data(g.plotchans,plotframes(t))) + g.voffsets(t)], 'r',	...
				'linewidth', lwidth);
			set(VL, 'Visible', 'off');		% make this-figure invisible
		end
		% --------------------------------------------------

		% white underline behind
		WL		=	plot([g.plottimes(t) g.plottimes(t)],					...
			[min(data(g.plotchans,plotframes(t)))				...
			max(data(g.plotchans,plotframes(t)))+g.voffsets(t)],'w',		...
			'linewidth',lwidth*2);
		% blue line
		BL		=	plot([g.plottimes(t) g.plottimes(t)],					...
			[min(data(g.plotchans,plotframes(t)))				...
			max(data(g.plotchans,plotframes(t)))+g.voffsets(t)],'b',		...
			'linewidth',lwidth);
	 end
	end
end
if plottimes_set
	set(WL, 'Visible', 'off');	% 20160405B. make this-figure invisible, forever
	set(BL, 'Visible', 'off');	% 20160405B. make this-figure invisible, forever
end
%
%%%%%%%%%%%%%%%%%%%%%%%%% Draw oblique lines %%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 20160405A. 변경: color->block, line -> dot
axall = axes('Position',pos,...
             'Visible','Off','FontSize',axfont);   % whole-gca invisible axes
axes(axall)
set(axall,'Color',BACKCOLOR);
axis([0 1 0 1])
%axes(axall)
%axis([0 1 0 1]);
set(gca,'Visible','off'); % make whole-figure axes invisible

for t=1:ntopos % draw oblique lines through to the topoplots 
	% 20160322A. plot 대상이 전체 채널이 아닌, 특정 채널에 국한될 경우, 표기방법
	% max 전체 채널 대상으로 찾되, 반드시 해당 채널(disp 아님)을 표기해 줄 것
%timetext=	sprintf('%s(%.0fms)', char(sCondi(t)), g.plottimes(t));
%mxplottime == g.plottimes(t)
	if fCond										% 조건별 max 존재!
%		maxdata = max(target(t, plotframes(t)));	% max value at (cond,plotfrm)

		% select case by case : parameter [nan] or [350 250 300]
		maxdata = target(t, plotframes(t));			% value at (cond,plotfrm)
	else
		[maxdata, ix] = max(abs(data(:,plotframes(t)))); % |max| val at plotframe
		maxdata	=	data(ix, plotframes(t));		% 절대값 기준 -> 실제값
		if ix ~= g.plotchans, MxOtherCh = ix; end	% 다른채널에서 max, 별도 기억

		if length(g.plotchans) == 1	% | g.voffsets(t)	% 단일채널이면 reload
			maxdata = data(g.plotchans,plotframes(t));	% 선택 채널 값에 ob 지시
		end
	end

	axtp = axes('Units','Normalized','Position',...
		[topoleft+pos(1)-0.03+(t-1)*(1+head_sep)*topowidth	...
			pos(2)+0.03+0.66*pos(4)						...
				topowidth									...
					topowidth*(1+head_sep)]);	% this will be the topoplot axes
						% topowidth]);			% this will be the topoplot axes
	axis([-1 1 -1 1]);
	from	=	changeunits([g.plottimes(t),maxdata],axdata,axall); % data axes
	to		=	changeunits([0,-0.74],axtp,axall);			% topoplot axes
	delete(axtp);

	axes(axall);											% whole figure axes
%	ol(t)	=	plot([from(1) to(1)], [from(2) to(2)], '.');
	ol(t)	=	plot([from(1) to(1)], [from(2) to(2)], 'k:');
	set(ol(t),'linewidth',lwidth);

	hold on
	set(axall,'Visible','off');
	axis([0 1 0 1]);
end
%
%%%%%%%%%%%%%%%%%%%%%%%%% Plot the topoplots %%%%%%%%%%%%%%%%%%%%%%%%%%
%
topoaxes	=	zeros(1,ntopos);				% topo 의 배치 위치
for t=1:ntopos
	% [pos(3)*topoleft+pos(1)+(t-1)*(1+head_sep)*topowidth ...
	axtp = axes('Units','Normalized','Position',							...
		[topoleft-0.03+pos(1)+(t-1)*(1+head_sep)*topowidth					...
			pos(2)+0.05+0.66*pos(4)											...
				topowidth													...
					topowidth*(1+head_sep)]);
	axes(axtp)												% topoplot axes
	topoaxes(t)		=	axtp;								% save axes handles
	cla														% clear

	if topowidth<0.12
		topoargs	=	{ topoargs{:} 'electrodes' 'off' };
	end
	if fCond
		topoplot( data(:,plotframes(t),t), chan_locs, topoargs{:} );
	else
		topoplot( data(:,plotframes(t)), chan_locs, topoargs{:} );
	end

	% Else make a 3-D headplot
	%
	% headplot(data(:,plotframes(t)),'chan.spline'); 

%	timetext = [num2str(g.plottimes(t),'%4.0f')];			% remarked by tigoum
	if fCond												% 조건별로 mx 존재!
%		if t==1
			timetext=	{	sprintf('%s',		char(sCondi(t))),	...
							sprintf('(%.0fms)', g.plottimes(t))		};
%		else
%			timetext=	sCondi(t);							% line 439 에서 정의
%		end
	elseif mxplottime == g.plottimes(t)
		timetext	=	[num2str(g.plottimes(t),'%.0f') '(Max)'];
		if exist('MxOtherCh', 'MxMn')
			timetext=	{ timetext ['(max Ch=' num2str(MxOtherCh) ')'] };
		end
	else
		timetext	=	[num2str(g.plottimes(t),'%.0fms')];	% add ' ms'
		if exist('MxOtherCh', 'MxMn')
			timetext=	[ timetext '(max Ch=' num2str(MxOtherCh) ')'];
		end
	end
	text(0.00,0.72,timetext,'FontSize',axfont-4,	...
		'HorizontalAlignment','Center',				...
		'Interpreter','none');						% off for text processing
		% ,'fontweight','bold');

	% !!! important !!!, must be set for each topo
	caxis([g.limits(5:6)]);				% important/revived by tigoum
end

%
%%%%%%%%%%%%%%%%%%% Plot a topoplot colorbar %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if plottimes_set
%mnmx	=	max(abs(ymin), abs(ymax));	% absulte max y

%axcb = axes('Position',[pos(1)+pos(3)*0.995 pos(2)+0.62*pos(4) pos(3)*0.02 pos(4)*0.09]);
axes(topoaxes(ntopos));					% set position with last topo's position
%h		=	cbar(axcb);					% draw colorbar on axes position
h		=	cbar;						% construct colorbar to refered by axes()
cpos	=	get(h,'Position');
BS		=	0.08;						% appended by tigoum
set(h,'Position',[cpos(1) cpos(2) BS/4 cpos(4)]);	% by tigoum
%set(h,'Ytick',[]);
set(h,	'YLimMode',		'manual');		% appended by tigoum
set(h,	'YLim',			g.limits(5:6));	% appended by tigoum
xlabel(h, '\muV');						% appended by tigoum
%xlabh	=	get(gca,'XLabel');			% appended by tigoum
%set(xlabh,'Position', get(xlabh,'Position') - [0 .175 0]); % down

axes(axall)
set(axall,'Color',axcolor);
end
%
%%%%%%%%%%%%%%%%%%%%% Plot the color bar '+' and '-' %%%%%%%%%%%%%%%%%%%%%%%%%%
%
%text(0.986,0.695,'+','FontSize',axfont,'HorizontalAlignment','Center');
%text(0.986,0.625,'-','FontSize',axfont,'HorizontalAlignment','Center');

%
%%%%%%%%%%%%%%%%%%%%%%%%% Plot the plot title if any %%%%%%%%%%%%%%%%%%%%%%%%%%
%
% plot title between data panel and topoplots (to avoid crowding at top of
% figure), on the left
%ttl	=	text(0.03, 0.635,		g.title,	'FontSize',titlefont,		...
ttl		=	text(0.00, 0.635*TM_TP,	g.title,	...
			'FontSize',titlefont,				...
			'HorizontalAlignment','left'); % 'FontWeight','Bold'); % edited by tg
set(ttl, 'Interpreter','none');			% off for text processing
set(ttl, 'Position', [pos(1) -0.1]);	% 밑바닥에 출력 -> tftopo 도 수정할 것!

% textent = get(ttl,'extent');
% titlwidth = textent(3);
%ttlpos	=	get(ttl,'position');
%set(ttl,'position',[ttlpos(1), 0]);

% put on global title
%ax=axes('Units','Normal','Position',[.075 .075 .85 .85],'Visible','off');
%set(get(ax,'Title'),'Visible','on');
%title(	ttl );


axes(axall)
set(axall,'layer','top'); % bring component lines to top
for t = 1:ntopos
  set(topoaxes(t),'layer','top'); % bring topoplots to very top
end

  if ~isempty(varargin)
    try,
	if ~isempty( strmatch( 'absmax', varargin))
		text(0.86,0.624,'0','FontSize',axfont,'HorizontalAlignment','Center');
	end;
	catch, end;
  end

%
% Turn on axcopy()
%

% clicking on ERP pop_up topoplot
% -------------------------------
if plottimes_set
disp('Click on ERP waveform to show scalp map at specific latency');

DATA.times		=	x;
DATA.erp		=	data;					%% erp @@ data : ch * tp * condi
DATA.target		=	target;					%% target @@ data : condi * tp
DATA.plottimes	=	g.plottimes;							% plot 용 tp 모음
DATA.plotchans	=	g.plotchans;							% disp chan
DATA.chanlocs	=	chan_locs;
DATA.options	=	topoargs;
DATA.srate		=	(size(data,2)-1)/(x(end)-x(1))*1000;
DATA.voffsets	=	g.voffsets(ntopos);
%DATA.axes		=	axtp;
DATA.line		=	ol;
DATA.vline		=	VL;										% 그래프 상의 수직선
DATA.xline		=	XL;										% tp 상의 수직선
DATA.limits		=	g.limits(5:6);							% appended by tigoum
DATA.axesA		=	axall;									% 전체 좌표계
DATA.axesD		=	axdata;									% plot 좌표계
DATA.axes		=	topoaxes;								% line 519 에서 정의
DATA.fCond		=	fCond;
DATA.PeakOfMax	=	fgPeakOfMax;					% max값(min 아님) 기준 peak
DATA.PeakOfMin	=	fgPeakOfMin;					% min값(max 아님) 기준 peak
DATA.SingleMax	=	fgSingleMax;					% false : fCond & 개별 max

if fCond
DATA.sCondi		=	sCondi;									% line 394 에서 정의
%{
cb_code			=	[		...				%-[
'tmppos		=	get(gca, ''currentpoint'');'								...
'DATA		=	get(gcf, ''userdata'');'									...
	'latpoint	=	round((tmppos(1)-DATA.times(1))/1000*DATA.srate);'		...
	'	'																	...
	'olX		=	get(DATA.vline, ''XData'');'							...
	'olY		=	get(DATA.vline, ''YData'');'							...
	'olX(1)		=	tmppos(1);'												...
	'olY(1)		=	min(DATA.target(:, latpoint));'							...
	'olX(2)		=	tmppos(1);'												...
	'olY(2)		=	max(DATA.target(:, latpoint)) + DATA.voffsets;'			...
	'set(DATA.vline, ''XData'', olX);'										...
	'set(DATA.vline, ''YData'', olY);'										...
	'set(DATA.vline, ''Visible'', ''off'');'								...
	'	'																	...
	'olX		=	get(DATA.xline, ''XData'');'							...
	'olX(1)		=	tmppos(1);'												...
	'olX(2)		=	tmppos(1);'												...
	'set(DATA.xline, ''XData'', olX);'										...
	'set(DATA.xline, ''Visible'', ''on'');'									...
	'	'																	...
'for t = 1 : length(DATA.axes),'											...
	'	'																	...
	'from		=	changeunits([tmppos(1), DATA.target(t, latpoint)],'		...
	'							DATA.axesD, DATA.axesA);'					...
	'	'																	...
	'axes(DATA.axesA);'														...
	'	'																	...
	'olX		=	get(DATA.line(t), ''XData'');'							...
	'olY		=	get(DATA.line(t), ''YData'');'							...
	'olX(1)		=	from(1);'												...
	'olY(1)		=	from(2);'												...
	'set(DATA.line(t), ''XData'', olX);'									...
	'set(DATA.line(t), ''YData'', olY);'									...
	'	'																	...
	'hold on;'																...
	'set(DATA.axesA, ''Visible'', ''off'');'								...
	'	'																	...
	'set(DATA.line, ''Visible'', ''on'');'									...
	'	'																	...
	'axes(DATA.axes(t)); cla;'												...
	'topoplot(DATA.erp(:,latpoint,t), DATA.chanlocs, DATA.options{:});'		...
	'	'																	...
	'if t == 1,'															...
		'tl=title(sprintf(''%s(%.0fms)'',char(DATA.sCondi(t)),tmppos(1)));' ...
	'else,'																	...
		'tl=title(char(DATA.sCondi(t)));'									...
	'end;'																	...
	'set(tl,''Interpreter'',''none'');'										...
	'caxis([DATA.limits]);'													...
'end;'																		...
'clear olY olX from latpoint DATA;'											...
					];	%-]
%}
else
%DATA.axes		=	axtp;
%{
cb_code			=	[		...				%-[
	'tmppos		=	get(gca, ''currentpoint'');'							...
	'DATA		=	get(gcf, ''userdata'');'								...
	'	'																	...
	'latpoint	=	round((tmppos(1)-DATA.times(1))/1000*DATA.srate);'		...
	'	'																	...
	'olX		=	get(DATA.vline, ''XData'');'							...
	'olY		=	get(DATA.vline, ''YData'');'							...
	'olX(1)		=	tmppos(1);'												...
	'olY(1)		=	min(DATA.erp(:, latpoint));'							...
	'olX(2)		=	tmppos(1);'												...
	'olY(2)		=	max(DATA.erp(:, latpoint)) + DATA.voffsets;'			...
	'set(DATA.vline, ''XData'', olX);'										...
	'set(DATA.vline, ''YData'', olY);'										...
	'set(DATA.vline, ''Visible'', ''on'');'									...
	'	'																	...
	'olX		=	get(DATA.xline, ''XData'');'							...
	'olX(1)		=	tmppos(1);'												...
	'olX(2)		=	tmppos(1);'												...
	'set(DATA.xline, ''XData'', olX);'										...
	'set(DATA.xline, ''Visible'', ''on'');'									...
	'	'																	...
	'from		=	changeunits([tmppos(1),'								...
	'							max(DATA.erp(DATA.plotchans, latpoint))],'	...
	'							DATA.axesD, DATA.axesA);'					...
	'	'																	...
	'axes(DATA.axesA);'														...
	'	'																	...
	'olX		=	get(DATA.line(end), ''XData'');'						...
	'olY		=	get(DATA.line(end), ''YData'');'						...
	'olX(1)		=	from(1);'												...
	'olY(1)		=	from(2);'												...
	'set(DATA.line(end), ''XData'', olX);'									...
	'set(DATA.line(end), ''YData'', olY);'									...
	'	'																	...
	'hold on;'																...
	'set(DATA.axesA, ''Visible'', ''off'');'								...
	'	'																	...
	'set(DATA.line, ''Visible'', ''on'');'									...
	'	'																	...
	'axes(DATA.axes(end)); cla;'											...
	'topoplot(DATA.erp(:,latpoint), DATA.chanlocs, DATA.options{:});'		...
	'title(sprintf(''%.0f ms'', tmppos(1)));'								...
	'caxis([DATA.limits]);'													...
	'clear olY olX from latpoint DATA;'										...
					];	%-]
%}
end
%{
axcopy;

set(gcf,	'userdata', dat);
set(axdata,	'ButtonDownFcn', cb_code); %windowbuttondownfcn', cb_code);
set(PL,		'ButtonDownFcn', cb_code);
%}
%axcopy(gcf, cb_code);

	% IMPORTANT:
	%	left mouse button : process the masking ( filtering )
	%	rght mouse button : rollback the result ( recovery )
	set(gcf,'userdata', DATA);
	set(PL,	'ButtonDownFcn', @clickPoint_Callback); % callback when mouse click

	% --------------------------------------------------
	% list박스 설치: max / min / minmax 선택용
	G.txMxMn	=	uicontrol('Style','text', 'String','[Find Peaks]',... %text
						'Unit','pix',										...
						'Position',[10 15 80 25],							...
						'Fontsize',10,										...
						'HorizontalAlignment','center');
	set(G.txMxMn,'backgroundcolor',get(gcf,'color'))
	G.MxMn		=	uicontrol('style','pop',					...	% sel MxMn
						'unit','pix',										...
						'position',[10 5 80 20],							...
						'fontsize',10,										...
						'fontweight','bold',								...
						'HorizontalAlignment', 'center',					...
						'string',{'Max';'Min';'MinMax';'User'},				...
						'value',g.minmax,									...
						'callback',{@MxMn_call, gcf});

	G.xline		=	uicontrol('style','push',					...	%toggle xline
						'unit','pix',										...
						'position',[10 45 40 20],							...
						'fontsize',10,										...
						'fontweight','bold',								...
						'string','xLine',									...
						'callback',{@xline_call, gcf});

	guidata(gcf, G)									% 구동
%	movegui('center')								% 한 가운데 배치
%	uiwait(G.hF);									% polling

end	% if plottimes_set
end	% function


%% It is function.
% This is part @ timtopo : callback for graph & topo processing

%	input : callback handle & event
%	output:
%
% Additionally, using VIM's regular-expression for more fast working.
% ts = 4
% first created by tigoum 2016/07/07
% last  updated by tigoum 2016/07/07

% The Start ==================================================


function [plottimes mxplottime]=S_calcMinMax(x,data, plottimeI, fCond,target, ...
										fgPeakOfMax, fgPeakOfMin, fgSingleMax)
plottimes				=	plottimeI;						% 리턴값 준비
[chans,frames,condi]	=	size(data);	% all data element matrix size is same!

if fgPeakOfMax & fgPeakOfMin	%% min/max 합쳐 최대 절대 크기 구하는 방식 (종전)
	if fCond										% appended by tigoum %-[
		% default plotting frame has max peak
		peaks			=	arrayfun(@(x)({findpeaks(target(:,x))}), [1:condi]);
													% 조건별로 peak찾기
		mxpk			=	cellfun(@(x)({max(x)}), peaks);	% 조건별 최대 peak

		% 이번엔 - 값에 대한 pk 구하자
		peaks			=	arrayfun(@(x)({-findpeaks(-target(:,x))}),[1:condi]);
		mnpk			=	cellfun(@(x)({min(x)}), peaks);	% 조건별 최대 peak
			% 단, 음수값에 대해 부호 역전시켜 구한 후 다시 부호 복원
if fgSingleMax										% 조건중 제일 큰것 tp 맞춤
		mxpk(cellfun(@(x)( isempty(x) ), mxpk))	=	[];		% empty 는 지움
		mnpk(cellfun(@(x)( isempty(x) ), mnpk))	=	[];		% empty 는 지움

		% 20160406B. 만약 |local max|가 없다면 |global max|를 구해야 한다.
	if isempty(mxpk) & isempty(mnpk) % globa 은 무조건 있음! (peaks 아니니까)
		mxpk			=	arrayfun(@(x)({max(target(:,x))}), [1:condi]);
		mnpk			=	arrayfun(@(x)({min(target(:,x))}), [1:condi]);
	end

		% 각각에서 최고값 구하기
		ALLPK			=	[ cell2mat(mxpk) cell2mat(mnpk) ]; % 하나로 통합
		[~, IXPK]		=	max(abs(ALLPK));		% 절대값 기준 mx 구하기
		MXPK			=	ALLPK(IXPK);			% 정확한 값(음수 가능성)

		% 이제 tp 추적하자. data2d = tp x cond
		[mxixplot, mxixcond] =	ind2sub(size(target), find(target(:) == MXPK));
else
		% 구한 값 중 empty가 있을 경우
		% 임의의 조건 중 한개만 empty 인 경우를 검토해야 함
		mxix			=	cellfun(@isempty, mxpk);		% 0 or 1
		mnix			=	cellfun(@isempty, mnpk);		% 0 or 1

		mxmx			=	arrayfun(@(x)({ max(target(:,x)) }), [1:condi]);
		mnmx			=	arrayfun(@(x)({ min(target(:,x)) }), [1:condi]);

		mxpk(mxix)		=	{0};		mnpk(mnix)		=	{0};	% set null
		mxmx(~mxix)		=	{0};		mnmx(~mnix)		=	{0};	% set null

		mxpk			=	cellfun(@(x,y)({ x+y }), mxpk, mxmx);	% combine!
		mnpk			=	cellfun(@(x,y)({ x+y }), mnpk, mnmx);	% combine!

		% 각 조건별로 |max| 구하기
		MXPK			=	cellfun(@(x,y)({ [x y] }), mxpk, mnpk);	% pair
		MXPK			=	cellfun(@(x)( x( abs(x)==max(abs(x))) ), MXPK);%|max|
%		MXPK			=	arrayfun(@(x)( x{1}(1) ), MXPK);		% select 1st
		% 이제 MXPK 에는 조건별로 mxpk 가 구해짐
		mxixplot		=arrayfun(@(x)( find(target(:,x)==MXPK(x)) ), [1:condi]);
		[~, mxixcond]	=	max(abs(MXPK));			% 그중 |max| 인 조건
end
		% --------------------------------------------------
		% additional plotting frame has max variance
		[mxls mxframes]	=	max(sum(data.*data));	% mxframes is list for condi
		[mx plotcondi]	=	max(mxls);				% find maximum power
		mxvrplot		=	mxframes(plotcondi);	% find final tp

		if		find(isnan(plottimes)),				% peak 조사 명령 있음
			plottimes	=	ones(1,condi) .* x(mxixplot);	% 조건 만큼 복제
%			mxplottime	=	x(mxixplot);			% 최대 peak 기억
			mxplottime	=	ones(1,condi) .* x(mxixplot);	% 조건 만큼 복제
		elseif	find(isinf(plottimes)),			% mx variance 조사 명령 있음
			plottimes	=	ones(1,condi) .* x(mxvrplot);	% 조건 만큼 복제
%			mxplottime	=	x(mxvrplot);			% 최대편차 기억
			mxplottime	=	ones(1,condi) .* x(mxvrplot);	% 조건 만큼 복제
		end
	% ======================================================================
	else
		% default plotting frame has max peak
		peaks			=	arrayfun(@(x)({findpeaks(data(x,:))}), [1:chans]);
													% 조건별로 peak찾기
		mxpk			=	cellfun(@(x)({max(x)}), peaks);	% 조건별 최대 peak

		% 이번엔 - 값에 대한 pk 구하자
		peaks			=	arrayfun(@(x)({-findpeaks(-data(x,:))}),[1:chans]);
		mnpk			=	cellfun(@(x)({min(x)}), peaks);	% 조건별 최대 peak
			% 단, 음수값에 대해 부호 역전시켜 구한 후 다시 부호 복원

		mxpk(cellfun(@(x)( isempty(x) ), mxpk))	=	[];		% empty 는 지움
		mnpk(cellfun(@(x)( isempty(x) ), mnpk))	=	[];		% empty 는 지움

		% 20160406B. 만약 |local max|가 없다면 |global max|를 구해야 한다.
	if isempty(mxpk) & isempty(mnpk) % global 은 무조건 있음! (peaks 아니니까)
		mxpk			=	arrayfun(@(x)({max(data(x,:))}), [1:chans]);
		mnpk			=	arrayfun(@(x)({min(data(x,:))}), [1:chans]);
	end

%		mxpk			=	findpeaks(data(:));		% 1D 관점에서 최대peak 추출
%		mnpk			=	-findpeaks(-data(:));	% 1D 관점에서 최소peak 추출
%		ALLPK			=	[ mxpk' mnpk' ];		% 하나로 통합
		ALLPK			=	[ cell2mat(mxpk) cell2mat(mnpk) ]; % 하나로 통합
		[~, IXPK]		=	max(abs(ALLPK));		% 절대값 기준 mx 구하기
		MXPK			=	ALLPK(IXPK);			% 정확한 값(음수 가능성)

		% 이제 tp 추적하자. data = ch x tp
		[mxixch, mxixplot]	=	ind2sub(size(data), find(data(:) == MXPK));
		% --------------------------------------------------
		% additional plotting frame has max variance
		[mx mxvrplot]	=	max(sum(data.*data));	% 채널차원 소멸, tp 유지
		% sum : summation for 1st dim(==ch) -> resulted time vector
		% max : find max { val & time point } on time vector

		if nargin< 4 | isempty(plottimes)
			plottimes	=	x(mxixplot);
		elseif	find(isnan(plottimes)),			% peak 조사 명령 있음
			plottimes(find(isnan(plottimes))) = x(mxixplot);%idx for mx pk
			mxplottime	=	x(mxixplot);			% 최대 peak 기억
		elseif	find(isinf(plottimes)),			% mx variance 조사 명령 있음
			plottimes(find(isinf(plottimes))) = x(mxvrplot);%idx for mx MxMn
			mxplottime	=	x(mxvrplot);			% 최대편차 기억
		end
	end	% if fCond	%-]
elseif fgPeakOfMax	%% 20160705A. 옵션따라 max 또는 min 택일 peak 구하는 방식
	if fCond										% appended by tigoum %-[
		% default plotting frame has max peak
		peaks			=	arrayfun(@(x)({findpeaks(target(:,x))}), [1:condi]);
													% 조건별로 peak찾기
		mxpk			=	cellfun(@(x)({max(x)}), peaks);	% 조건별 최대 peak

if fgSingleMax
		mxpk(cellfun(@(x)( isempty(x) ), mxpk))	=	[];		% empty 는 지움

		% 20160406B. 만약 |local max|가 없다면 |global max|를 구해야 한다.
	if isempty(mxpk)		% global 은 무조건 있음! (peaks 아니니까)
		mxpk			=	arrayfun(@(x)({max(target(:,x))}), [1:condi]);
	end

		% 각각에서 최고값 구하기
		ALLPK			=	cell2mat(mxpk);			% 하나로 통합
		[~, IXPK]		=	max(abs(ALLPK));		% 절대값 기준 mx 구하기
		MXPK			=	ALLPK(IXPK);			% 정확한 값(음수 가능성)

		% 이제 tp 추적하자. data2d = tp x cond
		[mxixplot, mxixcond] =	ind2sub(size(target), find(target(:) == MXPK));
else
		% 구한 값 중 empty가 있을 경우
		% 임의의 조건 중 한개만 empty 인 경우를 검토해야 함
		mxix			=	cellfun(@isempty, mxpk);		% 0 or 1
		mxmx			=	arrayfun(@(x)({ max(target(:,x)) }), [1:condi]);
		mxpk(mxix)		=	{0};					% set null
		mxmx(~mxix)		=	{0};					% set null
%		mxpk			=	cellfun(@(x,y)({ x+y }), mxpk, mxmx);	% combine!

		% 각 조건별로 |max| 구하기
%%		MXPK			=	cellfun(@(x,y)({ [x y] }), mxpk, mnpk);	% pair
%%		MXPK			=	cellfun(@(x)( x( abs(x)==max(abs(x))) ), MXPK);%|max|
%		MXPK			=	arrayfun(@(x)( x{1}(1) ), MXPK);		% select 1st

		MXPK			=	cellfun(@(x,y)([ x+y ]), mxpk, mxmx);	% combine!
		% 이제 MXPK 에는 조건별로 mxpk 가 구해짐
		mxixplot		=arrayfun(@(x)( find(target(:,x)==MXPK(x)) ), [1:condi]);
		[~, mxixcond]	=	max(abs(MXPK));			% 그중 |max| 인 조건
end
		% --------------------------------------------------
		% additional plotting frame has max variance
		[mxls mxframes]	=	max(sum(data.*data));	% mxframes is list for condi
		[mx plotcondi]	=	max(mxls);				% find maximum power
		mxvrplot		=	mxframes(plotcondi);	% find final tp

		if		find(isnan(plottimes)),				% peak 조사 명령 있음
			plottimes	=	ones(1,condi) .* x(mxixplot);	% 조건 만큼 복제
%			mxplottime	=	x(mxixplot);			% 최대 peak 기억
			mxplottime	=	ones(1,condi) .* x(mxixplot);	% 조건 만큼 복제
		elseif	find(isinf(plottimes)),			% mx variance 조사 명령 있음
			plottimes	=	ones(1,condi) .* x(mxvrplot);	% 조건 만큼 복제
%			mxplottime	=	x(mxvrplot);			% 최대편차 기억
			mxplottime	=	ones(1,condi) .* x(mxvrplot);	% 조건 만큼 복제
		end
	% ======================================================================
	else
		% default plotting frame has max peak
		peaks			=	arrayfun(@(x)({findpeaks(data(x,:))}), [1:chans]);
													% 조건별로 peak찾기
		mxpk			=	cellfun(@(x)({max(x)}), peaks);	% 조건별 최대 peak

		mxpk(cellfun(@(x)( isempty(x) ), mxpk))	=	[];		% empty 는 지움

		% 20160406B. 만약 |local max|가 없다면 |global max|를 구해야 한다.
	if isempty(mxpk)		% global 은 무조건 있음! (peaks 아니니까)
		mxpk			=	arrayfun(@(x)({max(data(x,:))}), [1:chans]);
	end

%		mxpk			=	findpeaks(data(:));		% 1D 관점에서 최대peak 추출
%		mnpk			=	-findpeaks(-data(:));	% 1D 관점에서 최소peak 추출
%		ALLPK			=	[ mxpk' mnpk' ];		% 하나로 통합
		ALLPK			=	[ cell2mat(mxpk) ];		% 하나로 통합
		[~, IXPK]		=	max(abs(ALLPK));		% 절대값 기준 mx 구하기
		MXPK			=	ALLPK(IXPK);			% 정확한 값(음수 가능성)

		% 이제 tp 추적하자. data = ch x tp
		[mxixch, mxixplot]	=	ind2sub(size(data), find(data(:) == MXPK));
		% --------------------------------------------------
		% additional plotting frame has max variance
		[mx mxvrplot]	=	max(sum(data.*data));	% 채널차원 소멸, tp 유지
		% sum : summation for 1st dim(==ch) -> resulted time vector
		% max : find max { val & time point } on time vector

		if nargin< 4 | isempty(plottimes)
			plottimes	=	x(mxixplot);
		elseif	find(isnan(plottimes)),			% peak 조사 명령 있음
			plottimes(find(isnan(plottimes))) = x(mxixplot);%idx for mx pk
			mxplottime	=	x(mxixplot);			% 최대 peak 기억
		elseif	find(isinf(plottimes)),			% mx variance 조사 명령 있음
			plottimes(find(isinf(plottimes))) = x(mxvrplot);%idx for mx MxMn
			mxplottime	=	x(mxvrplot);			% 최대편차 기억
		end
	end	% if fCond	%-]
elseif fgPeakOfMin	%% 20160705A. 옵션따라 max 또는 min 택일 peak 구하는 방식
	if fCond										% appended by tigoum %-[
		% default plotting frame has max peak
		% 이번엔 - 값에 대한 pk 구하자
		peaks			=	arrayfun(@(x)({-findpeaks(-target(:,x))}),[1:condi]);
		mnpk			=	cellfun(@(x)({min(x)}), peaks);	% 조건별 최대 peak
			% 단, 음수값에 대해 부호 역전시켜 구한 후 다시 부호 복원
if fgSingleMax
		mnpk(cellfun(@(x)( isempty(x) ), mnpk))	=	[];		% empty 는 지움

		% 20160406B. 만약 |local max|가 없다면 |global max|를 구해야 한다.
	if isempty(mnpk) % globa 은 무조건 있음! (peaks 아니니까)
		mnpk			=	arrayfun(@(x)({min(target(:,x))}), [1:condi]);
	end

		% 각각에서 최고값 구하기
		ALLPK			=	[ cell2mat(mnpk) ];		% 하나로 통합
		[~, IXPK]		=	max(abs(ALLPK));		% 절대값 기준 mx 구하기
		MXPK			=	ALLPK(IXPK);			% 정확한 값(음수 가능성)

		% 이제 tp 추적하자. data2d = tp x cond
		[mxixplot, mxixcond] =	ind2sub(size(target), find(target(:) == MXPK));
else
		% 구한 값 중 empty가 있을 경우
		% 임의의 조건 중 한개만 empty 인 경우를 검토해야 함
		mnix			=	cellfun(@isempty, mnpk);		% 0 or 1
		mnmx			=	arrayfun(@(x)({ min(target(:,x)) }), [1:condi]);
		mnpk(mnix)		=	{0};					% set null
		mnmx(~mnix)		=	{0};					% set null
%		mnpk			=	cellfun(@(x,y)({ x+y }), mnpk, mnmx);	% combine!

		% 각 조건별로 |max| 구하기
%%		MXPK			=	cellfun(@(x,y)({ [x y] }), mxpk, mnpk);	% pair
%%		MXPK			=	cellfun(@(x)( x( abs(x)==max(abs(x))) ), MXPK);%|max|
%		MXPK			=	arrayfun(@(x)( x{1}(1) ), MXPK);		% select 1st

		MXPK			=	cellfun(@(x,y)([ x+y ]), mnpk, mnmx);	% combine!
		% 이제 MXPK 에는 조건별로 mxpk 가 구해짐
		mxixplot		=arrayfun(@(x)( find(target(:,x)==MXPK(x)) ), [1:condi]);
		[~, mxixcond]	=	max(abs(MXPK));			% 그중 |max| 인 조건
end
		% --------------------------------------------------
		% additional plotting frame has max variance
		[mxls mxframes]	=	max(sum(data.*data));	% mxframes is list for condi
		[mx plotcondi]	=	max(mxls);				% find maximum power
		mxvrplot		=	mxframes(plotcondi);	% find final tp

		if		find(isnan(plottimes)),				% peak 조사 명령 있음
			plottimes	=	ones(1,condi) .* x(mxixplot);	% 조건 만큼 복제
%			mxplottime	=	x(mxixplot);			% 최대 peak 기억
			mxplottime	=	ones(1,condi) .* x(mxixplot);	% 조건 만큼 복제
		elseif	find(isinf(plottimes)),			% mx variance 조사 명령 있음
			plottimes	=	ones(1,condi) .* x(mxvrplot);	% 조건 만큼 복제
%			mxplottime	=	x(mxvrplot);			% 최대편차 기억
			mxplottime	=	ones(1,condi) .* x(mxvrplot);	% 조건 만큼 복제
		end
	% ======================================================================
	else
		% default plotting frame has max peak
		% 이번엔 - 값에 대한 pk 구하자
		peaks			=	arrayfun(@(x)({-findpeaks(-data(x,:))}),[1:chans]);
		mnpk			=	cellfun(@(x)({min(x)}), peaks);	% 조건별 최대 peak
			% 단, 음수값에 대해 부호 역전시켜 구한 후 다시 부호 복원

		mnpk(cellfun(@(x)( isempty(x) ), mnpk))	=	[];		% empty 는 지움

		% 20160406B. 만약 |local max|가 없다면 |global max|를 구해야 한다.
	if isempty(mxpk) & isempty(mnpk) % global 은 무조건 있음! (peaks 아니니까)
		mnpk			=	arrayfun(@(x)({min(data(x,:))}), [1:chans]);
	end

%		mxpk			=	findpeaks(data(:));		% 1D 관점에서 최대peak 추출
%		mnpk			=	-findpeaks(-data(:));	% 1D 관점에서 최소peak 추출
%		ALLPK			=	[ mxpk' mnpk' ];		% 하나로 통합
		ALLPK			=	[ cell2mat(mnpk) ];		% 하나로 통합
		[~, IXPK]		=	max(abs(ALLPK));		% 절대값 기준 mx 구하기
		MXPK			=	ALLPK(IXPK);			% 정확한 값(음수 가능성)

		% 이제 tp 추적하자. data = ch x tp
		[mxixch, mxixplot]	=	ind2sub(size(data), find(data(:) == MXPK));
		% --------------------------------------------------
		% additional plotting frame has max variance
		[mx mxvrplot]	=	max(sum(data.*data));	% 채널차원 소멸, tp 유지
		% sum : summation for 1st dim(==ch) -> resulted time vector
		% max : find max { val & time point } on time vector

		if nargin< 4 | isempty(plottimes)
			plottimes	=	x(mxixplot);
		elseif	find(isnan(plottimes)),			% peak 조사 명령 있음
			plottimes(find(isnan(plottimes))) = x(mxixplot);%idx for mx pk
			mxplottime	=	x(mxixplot);			% 최대 peak 기억
		elseif	find(isinf(plottimes)),			% mx variance 조사 명령 있음
			plottimes(find(isinf(plottimes))) = x(mxvrplot);%idx for mx MxMn
			mxplottime	=	x(mxvrplot);			% 최대편차 기억
		end
	end	% if fCond	%-]
end	% if fgPeakOf...

return
end	% function

function clickPoint_Callback(hObject, eventdata,	...	% 정규call은 2개 param만
							handles, fgPeakOfMax, fgPeakOfMin, fgSingleMax)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

DATA			=	get(gcf, 'userdata');
if nargin==2 & ~isempty(hObject) & ~isempty(eventdata)			% 정규 callback
	tmppos		=	get(gca, 'currentpoint');
	tmppos		=	ones(1, length(DATA.axes)) * tmppos(1);		% topo 갯수만큼
	fgPeakOfMax	=	DATA.PeakOfMax;
	fgPeakOfMin	=	DATA.PeakOfMin;
	fgSingleMax	=	true;							% 단일 시간으로 topo 처리
elseif isempty(hObject) & isempty(eventdata) & ~isempty(handles)% user가 호출시
	tmppos		=	handles;						% handles ==plottimes 리스트
%	fgSingleMax	=	false;							% 단일 시간으로 topo 처리
end

if DATA.fCond
	getValue	=	@(data, LatPt) ( @(x) data.target(x, ...	% 조건별 값 추출
						round((LatPt(x)-data.times(1))/1000*data.srate)) );
	target		=	arrayfun(getValue(DATA, tmppos), [1:length(tmppos)]);
	if fgPeakOfMax & fgPeakOfMin	%% min/max 합쳐 최대절대크기 구하는 방식
		[~, ix1st]=	max(abs(target));
	elseif fgPeakOfMax	%% 20160705A. 옵션따라 max|min 택일 peak 구하는 방식
		[~, ix1st]=	max(target);
	elseif fgPeakOfMin	%% 20160705A. 옵션따라 max|min 택일 peak 구하는 방식
		[~, ix1st]=	min(target);
	end	% if DATA.PeakOf...
	ix1st		=	tmppos(ix1st(1));				% 최종 index 확보

	ixLat	=	round((ix1st-DATA.times(1))/1000*DATA.srate);

	olX			=	get(DATA.vline, 'XData');
	olY			=	get(DATA.vline, 'YData');
	olX(1)		=	ix1st;
	olY(1)		=	min(DATA.target(:, ixLat));
	olX(2)		=	ix1st;
	olY(2)		=	max(DATA.target(:, ixLat)) + DATA.voffsets;
	set(DATA.vline, 'XData', olX);
	set(DATA.vline, 'YData', olY);
	set(DATA.vline, 'Visible', 'off');

	olX			=	get(DATA.xline, 'XData');
	olX(1)		=	ix1st;
	olX(2)		=	ix1st;
	set(DATA.xline, 'XData', olX);
%	set(DATA.xline, 'Visible', 'on');				% xline_call() 에서 제어함

for t = 1 : length(DATA.axes),
	ixLat	=	round((tmppos(t)-DATA.times(1))/1000*DATA.srate);

	from		=	changeunits([tmppos(t), DATA.target(t, ixLat)],	...
								DATA.axesD, DATA.axesA);

	axes(DATA.axesA);

	olX			=	get(DATA.line(t), 'XData');
	olY			=	get(DATA.line(t), 'YData');
	olX(1)		=	from(1);
	olY(1)		=	from(2);
	set(DATA.line(t), 'XData', olX);
	set(DATA.line(t), 'YData', olY);

	hold on;
	set(DATA.axesA, 'Visible', 'off');

	set(DATA.line, 'Visible', 'on');

	axes(DATA.axes(t)); cla;
	topoplot(DATA.erp(:,ixLat,t), DATA.chanlocs, DATA.options{:});

	if ~fgSingleMax | t == 1
		tl=title(sprintf('%s(%.0fms)',char(DATA.sCondi(t)),tmppos(t)));
	else
		tl=title(char(DATA.sCondi(t)));
	end;
	set(tl,'Interpreter','none');
	caxis([DATA.limits]);
end;
clear olY olX from ixLat DATA;

else
%dat.axes		=	axtp;
%	tmppos		=	get(gca, 'currentpoint');
%	DATA		=	get(gcf, 'userdata');

	getValue	=	@(data, LatPt) ( @(x) data.erp(x, ...
						round((LatPt(x)-data.times(1))/1000*data.srate)) );
	erp			=	arrayfun(getValue(DATA, tmppos), [1:length(tmppos)]);
	if fgPeakOfMax & fgPeakOfMin	%% min/max 합쳐 최대절대크기 구하는 방식
		[~, ix1st]=	max(abs(erp));
	elseif fgPeakOfMax	%% 20160705A. 옵션따라 max|min 택일 peak 구하는 방식
		[~, ix1st]=	max(erp);
	elseif fgPeakOfMin	%% 20160705A. 옵션따라 max|min 택일 peak 구하는 방식
		[~, ix1st]=	min(erp);
	end	% if fgPeakOf...
	ix1st		=	tmppos(ix1st(1));				% 최종 index 확보

	ixLat	=	round((ix1st-DATA.times(1))/1000*DATA.srate);

	olX			=	get(DATA.vline, 'XData');
	olY			=	get(DATA.vline, 'YData');
	olX(1)		=	ix1st;
	olY(1)		=	min(DATA.erp(:, ixLat));
	olX(2)		=	ix1st;
	olY(2)		=	max(DATA.erp(:, ixLat)) + DATA.voffsets;
	set(DATA.vline, 'XData', olX);
	set(DATA.vline, 'YData', olY);
	set(DATA.vline, 'Visible', 'on');

	olX			=	get(DATA.xline, 'XData');
	olX(1)		=	ix1st;
	olX(2)		=	ix1st;
	set(DATA.xline, 'XData', olX);
%	set(DATA.xline, 'Visible', 'on');

	from		=	changeunits([ix1st,								...
								max(DATA.erp(DATA.plotchans, ixLat))], ...
								DATA.axesD, DATA.axesA);

	axes(DATA.axesA);

	olX			=	get(DATA.line(end), 'XData');
	olY			=	get(DATA.line(end), 'YData');
	olX(1)		=	from(1);
	olY(1)		=	from(2);
	set(DATA.line(end), 'XData', olX);
	set(DATA.line(end), 'YData', olY);

	hold on;
	set(DATA.axesA, 'Visible', 'off');

	set(DATA.line, 'Visible', 'on');

	axes(DATA.axes(end)); cla;
	topoplot(DATA.erp(:,ixLat), DATA.chanlocs, DATA.options{:});
	title(sprintf('%.0f ms', ix1st));
	caxis([DATA.limits]);
	clear olY olX from ixLat DATA;
end

	return
end

function []	=	MxMn_call(src, evt, hF)						% built-in callback
	G			=	guidata(gcf);							% GUI 핸들
%	MxMn		=	get(G.MxMn, {'string','value'});			% 변수명 선택
	MxMn		=	get(G.MxMn, 'value');					% 변수명 선택
	fgPeakOfMax	=	2~=MxMn;						% max값(min 아님) 기준 peak
	fgPeakOfMin	=	1~=MxMn;						% min값(max 아님) 기준 peak

	tmppos		=	get(gca, 'currentpoint');
	DATA		=	get(gcf, 'userdata');

	x			=	DATA.times;
	data		=	DATA.erp;					%% erp @@ data : ch * tp * condi
	target		=	DATA.target;				%% target @@ data : condi * tp
	plottimes	=	DATA.plottimes;							% plot 용 tp 모음
	fCond		=	DATA.fCond;
	fgSingleMax	=	DATA.SingleMax;				% false : fCond & 개별 max

	% 선택 조건(max, min, minmax)에 따라, 값 재계산, topo & oblique line re draw
	% 단, 현재 시점에서는 target 의 dim 순서가 swap 된 상태: cont x tp
	% 그런데, S_calcMinMax 는 tp x cond 를 다룸
	if MxMn < 4,											% find min/max...
		[plottimes, ~] = S_calcMinMax(x, data, [NaN], fCond, target', ...
										fgPeakOfMax, fgPeakOfMin, fgSingleMax);
%		set(gcf,'userdata', DATA);							% 수정값 update
	else	%% MxMn == 4										% by user specify
		%% direct display using user specified plottime param.
	end

	% 계산 다 됐으면, re drawing
	clickPoint_Callback([], [], plottimes, fgPeakOfMax,fgPeakOfMin,fgSingleMax);
end	% func
%{
function []	=	dim_call(src, evt, hF)			% built-in callback
	G		=	guidata(hF);					% GUI 핸들
	dim		=	get(G.dim, {'string','value'});	% 차원 선택
	if ~isempty(dim{1}) & ~isempty(dim{2})		% 값 존재 == 3차원 이상
	Dim		=	str2double(dim{1}(dim{2}));		% 값 추적 == dim 최대크기

	sIntv	=	arrayfun(@(x) {num2str(x)}, [1:Dim]);
	intv	=	get(G.intv,{'string','value'});	% 차원내 범위 선택
%		Intv	=	str2double(intv{1}(intv{2}));
	if 0<src,Intv=str2double(intv{1}(intv{2})); else,Intv=G.glIntv; end
	if isempty(Intv), Intv = 1; end				% 초기값 설정
	if any(Dim<Intv), Intv(~ismember(Intv,[1:Dim]))=[]; end %초과
				set(G.intv, 'max',length(sIntv), 'min',1);
				set(G.intv, 'string',sIntv);	% 범위 등록
				set(G.intv, 'value', Intv);		% 범위 선택
	else
				set(G.intv, 'string',{});		% 2차원은 공백!
				set(G.intv, 'value', []);		% 범위 선택
	end	% if ~isempty
%		guidata(hF, G);								% 갱신
end	% func
%}
function []	=	xline_call(src, evt, hF)					% built-in callback
	G			=	guidata(gcf);							% GUI 핸들
	DATA		=	get(gcf, 'userdata');

	fgOnOff		=	get(DATA.xline, 'Visible');
	if strcmp(fgOnOff, 'on'), fgOnOff = 'off'; else fgOnOff = 'on'; end % toggle
	set(DATA.xline, 'Visible', fgOnOff);
end	% func
% The End. ==================================================

