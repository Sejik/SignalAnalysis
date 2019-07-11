function time_frequency(ts, srate, starttime, pos, figname)
% time_frequency - compute and visualize the average time-frequency of the
%                             multi-channel time series.
%
% Usage:  time_frequency(ts, srate, starttime, pos, figname)
%
%  Input:    ts - ts(i, j) means point j in the time series of channel i.
%              srate - sampling rate of the time series.
%              starttime - the start time of the time series. 
%              pos - the position for the time frequency visualization figure.
%              figname - name for the time frequency visualization figure.
%
% Program Author: Yakang Dai, University of Minnesota, USA
%
% User feedback welcome: e-mail: econnect@umn.edu
%

% License
% ==============================================================
% This program is part of the eConnectome.
% 
% Copyright (C) 2010 Regents of the University of Minnesota. All rights reserved.
% Correspondence: binhe@umn.edu
% Web: econnectome.umn.edu
%
% This program is free software for academic research: you can redistribute it and/or modify
% it for non-commercial uses, under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see http://www.gnu.org/copyleft/gpl.html.
%
% This program is for research purposes only. This program
% CAN NOT be used for commercial purposes. This program 
% SHOULD NOT be used for medical purposes. The authors 
% WILL NOT be responsible for using the program in medical
% conditions.
% ==========================================

% Revision Logs
% ==========================================
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ==========================================

low = 1; 
spacing = 0.1;
high = 30;
prompt = {['Enter low frequency (>=' num2str(0.1) '):'], 'Enter spacing (>0)', ['Enter high frequency (<=' num2str(srate/2) '):']};
dlg_title = 'Frequency band and spacing for time frequency';
num_lines = 1;
def = {num2str(low), num2str(spacing), num2str(high)};
opt.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,opt);

if ~isempty(answer)
    low = str2num(answer{1});
    spacing = str2num(answer{2});
    high = str2num(answer{3});
end

if isempty(low) | isempty(spacing) | isempty(high)
    warndlg('Input must be numeric!');
    return;
end

high = max(min(high,srate/2),0.1);
low = max(min(low,srate/2),0.1);

if low >= high
    warndlg('Low must be < High!');
    return;
end

if spacing <=0.0
    warndlg('Spacing must be > 0!');
    return;    
end

if spacing >= high - low
    warndlg('Input spacing must be < high-low !');
    return;   
end

% freqVec = [2 : 0.05 : 15];
freqVec = [low: spacing: high];

[TFR,timeVec,freqVec] = morletTFR(ts,freqVec,srate,7);
x = timeVec + starttime;
y = freqVec;
[X,Y] = meshgrid(x,y);
Z = zeros(size(X));

figname = ['Time Frequency - ' char(upper(figname))];
hfig = figure('name',figname,'NumberTitle','off','visible','off');

if ~isempty(pos)
    figure_position = get(hfig,'position');
    figure_position(1:2) = pos - [figure_position(3)/2, figure_position(4)/2];
    set(hfig,'position',figure_position);
end
set(hfig,'visible','on');

haxes = axes;
set(haxes,'color',get(hfig,'color'));
xnum = length(x);
ynum = length(y);
set(haxes,'Xlim',[x(1), x(xnum)],'Ylim',[y(1), y(ynum)]);
xlabel('Time (s)');
ylabel('Frequency (Hz)');
axis on;
cla;
hold on;
surface(X,Y,Z,TFR,'EdgeColor','none','FaceColor','interp');
contour(X,Y,TFR,6,'k');
colorbar;
