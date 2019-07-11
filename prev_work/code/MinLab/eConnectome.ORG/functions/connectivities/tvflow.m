function tvflow(TVFLOW)
% tvflow - plot the multichannel time-varying outflows/inflows.
%
% Usage: tvflow(TVFLOW)
%
% Input: TVFLOW - the structure for the multichannel time-varying outflows/inflows
%               - TVFLOW.name is the string of the title displayed in the figure window.
%               - TVFLOW.labels is the array for the labels of the channels.
%               - TVFLOW.flows is the multichannel time-varying outflows/inflows matrix,
%                 where TVFLOW.flows(i,j) is the outflow/inflow value for the channel j 
%                 at the time point i. 
%               - TVFLOW.type is 'outflow' or 'inflow'.
%               - TVFLOW.srate is the sampling rate of the time series.
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
% Yakang Dai, 19-June-2010 16:26:30
% Release Version 1.0
%
% ==========================================

if isempty(TVFLOW)
    return;
end

% test the fields
fields = isfield(TVFLOW, {'name', 'labels', 'flows', 'type', 'srate'});
if ~all(fields)
    return;
end

% set up the figure
hfig = figure('name', TVFLOW.name, 'NumberTitle','off');
setappdata(hfig,'TVFLOW',TVFLOW);
nbchan = size(TVFLOW.flows,2);
nbpoints = size(TVFLOW.flows,1);

% set up the axis
haxes = axes;
cla;
hold on;
xlabel('Second');
if isequal(TVFLOW.type,'outflow')
    ylabel('Outflow');
else
    ylabel('Inflow');
end

% plot the multichannel time-varying outflows/inflows
lineclr = [0.5, 0.8, 0.5];
x = [1:nbpoints] / TVFLOW.srate;
for i = 1: nbchan
    plot(x, TVFLOW.flows(:,i), 'color', lineclr,'LineWidth',1);
end

% highlight the channel with the maximum time-varying outflows/inflows
avrg = mean(TVFLOW.flows);
[maxv, idx] = max(avrg);
lineclr = [0.0, 0.0, 1.0];
i = idx(1);
plot(x, TVFLOW.flows(:,i), 'color', lineclr,'LineWidth',2);
x = round(nbpoints/2);
y = TVFLOW.flows(x, i);
x = x / TVFLOW.srate;
text(x,y,char(TVFLOW.labels(i)),'VerticalAlignment', 'bottom','FontSize',18,'color',lineclr);      
setappdata(hfig,'currentchannel',i);

% set up the title
title(['channel ', TVFLOW.labels{i}, ', ', 'time ', num2str(0), ', ' , TVFLOW.type, ' ', num2str(0)]);

set(hfig,'windowbuttonmotionfcn', @mousemotionCallback);
set(hfig,'WindowButtonDownFcn', @mousedownCallback);

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

TVFLOW = getappdata(hfig,'TVFLOW');
nbpoints = size(TVFLOW.flows,1);
point = round(mousepos(1,1) * TVFLOW.srate);
point = max(1,min(nbpoints,point));
flow = TVFLOW.flows(point,:);
dis = abs(flow - mousepos(1,2));
[minv, chan] = min(dis);
pos = [point/TVFLOW.srate, flow(chan)];

% display the channel and time information associated with the cursor
pointhandle = findobj(hfig,'tag','pointtag');
if isempty(pointhandle)
    plot(pos(1),pos(2),'mo','MarkerFaceColor',[0.49,1.0,0.63],'MarkerSize',8,'EraseMode', 'xor','tag', 'pointtag');
else
    set(pointhandle,'xdata',pos(1),'ydata',pos(2));
    drawnow;
end
title(['channel ', TVFLOW.labels{chan}, ', ', 'time ', num2str(pos(1)), ', ' , TVFLOW.type, ' ', num2str(pos(2))]);

% -------------------------------------------------------------------------
function mousedownCallback(src, evnt) 
hfig = gcf;
haxes = gca;

selectype = lower(get(hfig,'SelectionType'));

% 'alt': right click - select the channel to be highlighted
if ~strcmp(selectype,'alt')    
    return;
end

TVFLOW = getappdata(hfig,'TVFLOW');

default = [];
% [sel,ok] = listdlg('ListString',TVFLOW.labels,'Name','Channel Selection','InitialValue',default,'SelectionMode','single');
[sel,ok] = listdlg('ListString',TVFLOW.labels,'Name','Channel Selection','InitialValue',default);
if ok == 0 | isempty(sel)
    return;
end

% if length(sel) ~= 1
%     helpdlg('Please select only one channel!');
%     return;
% end
len = length(sel);

axes(haxes);
cla;
hold on;

nbchan = size(TVFLOW.flows,2);
nbpoints = size(TVFLOW.flows,1);

lineclr = [0.5, 0.8, 0.5];
x = [1:nbpoints] / TVFLOW.srate;
for i = 1: nbchan
    plot(x,TVFLOW.flows(:,i), 'color', lineclr,'LineWidth',1);
end

% lineclr = [0.0, 0.0, 1.0];
if len == 1
    lineclr = [0.0, 0.0, 1.0];
    x1 = round(nbpoints/2);
    y1 = TVFLOW.flows(x1, sel(1));
    x1 = x1 / TVFLOW.srate;
    text(x1,y1,char(TVFLOW.labels(sel(1))),'VerticalAlignment','bottom','FontSize',18,'color',lineclr);  
elseif len == 2
    lineclr(1,:) = [0.0, 0.0, 1.0];
    lineclr(2,:) = [1.0, 0.0, 0.0];
elseif len == 3
    lineclr(1,:) = [0.0, 0.0, 1.0];
    lineclr(2,:) = [1.0, 0.0, 0.0];
    lineclr(3,:) = [0.0, 1.0, 0.0];
else
    lineclr = jet(len);
end

for j = 1:len
    i = sel(j);
    plot(x,TVFLOW.flows(:,i), 'color', lineclr(j,:),'LineWidth',2);
end

setappdata(hfig,'currentchannel',sel(1));

