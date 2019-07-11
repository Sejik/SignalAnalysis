function ECOM_Butterfly(ts, srate, starttime, pos)
% ECOM_Butterfly - compute and visualize the butterfly waveforms 
%                              and global field power of the multi-channel time series.
%
% Usage:  ECOM_Butterfly(ts, srate, starttime, pos)
%
%  Input:    ts - ts(i, j) indicates the value at the point j in the time series of channel i.
%              srate - sampling rate of the time series.
%              starttime - the start time of the time series. 
%              pos - the position for the butterfly/GFP visualization figure.
%
%  The calculation of global field power (GFP) refers to
%  D. Lehmann and W. Skrandies. Electroencephalography and Clinical Neurophysiology.
%  Volume 48, Issue 6, June 1980, Pages 609-621. 
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
% Yakang Dai, 27-Jan-2011 17:10:30
% Release Version 2.0 beta
%
% ==========================================

[chans, points] = size(ts);

% draw butterfly
ref = mean(ts);
tsp = ts - repmat(ref,chans,1);
figname = 'Butterfly/GFP';
hfig = figure('name',figname,'NumberTitle','off','visible','off');

if ~isempty(pos)
    figure_position = get(hfig,'position');
    figure_position(1:2) = pos - [figure_position(3)/2, figure_position(4)/2];
    set(hfig,'position',figure_position);
end
set(hfig,'visible','on');

haxes = axes;
set(haxes,'color',get(hfig,'color'));
t = [1:points]/srate + starttime;
xlabel('Time (s)');
axis on;
box on;
cla;
hold on;

for n = 1:chans
    plot(t,tsp(n,:),'color',[0,0,0]);
end

Butterfly.starttime = starttime;
Butterfly.srate = srate; 
Butterfly.points = points;
setappdata(hfig, 'Butterfly', Butterfly);

% draw global field power
gfp = zeros(1,points);
for n = 1:points
    % RMS with reference-free
    u = ts(:,n);
    s = 0;
    for i = 1:chans
        for j = 1: chans
            power = (u(i)-u(j))^2;
            s = s + power;
        end
    end
    gfp(1,n) = sqrt(s/(chans*2));
end

min_gfp = min(gfp);
max_gfp = max(gfp);
mintsp = min(min(tsp));
maxstp = max(max(tsp));
scale = maxstp-mintsp;
coef = scale/(max_gfp-min_gfp);
gfp = mintsp+gfp*coef;
gfp = 2*(gfp+scale)/3;
plot(t,gfp);

set(hfig,'windowbuttonmotionfcn', @mousemotionCallback);


% -------------------------------------------------------------------------
function mousemotionCallback(src, evnt) 
hfig = gcf;
haxes = gca;
     
currentxlim = get(haxes, 'Xlim');
currentylim = get(haxes, 'Ylim');
mousepos = get(haxes, 'currentpoint');
if isempty(mousepos)
    return;
end

% if the mouse is not in the viewing window, do nothing.
if mousepos(1,1) <= currentxlim(1,1) | mousepos(1,1) >= currentxlim(1,2)  | ...
   mousepos(1,2) <= currentylim(1,1) | mousepos(1,2) >= currentylim(1,2) 
    return;
end

Butterfly = getappdata(hfig,'Butterfly');
point = round((mousepos(1,1)-Butterfly.starttime) * Butterfly.srate);
point = max(1,min(Butterfly.points,point));
posx = point/Butterfly.srate+Butterfly.starttime;
pnt = round(posx*Butterfly.srate);

% display the time information associated with the cursor
xpos = [posx, posx];
ypos = [currentylim(1,1),  currentylim(1,2)];
tmpcolor = [0.0,0.0,1.0];
linehandle = findobj(hfig,'tag','linetag');
if isempty(linehandle)
    plot(xpos, ypos, 'color', tmpcolor, 'clipping','on','EraseMode', 'xor', 'tag', 'linetag');
else
    set(linehandle,'xdata',xpos,'ydata',ypos);
    drawnow;
end
title(['Time ', num2str(posx), ' s, ' 'Point ' num2str(pnt)]);
