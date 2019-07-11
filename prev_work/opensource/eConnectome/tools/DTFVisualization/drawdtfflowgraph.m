function drawdtfflowgraph(flows, roiPos, inopt)
% drawdtfconngraph - draw outflow/inflow connectivity patterns of multiple channels.
% 
% Usage: drawdtfconngraph(flows, roiPos, inopt)
%
% Input: flows - a vector storing outflow/inflow values, where flows(i)
%                means the outflow/inflow value of channel i.
%        roiPos - a 2D array (N * 3) for the locations of the channels.
%        inopt - a structure stores options for drawing the flow patterns.
%                It has 5 fields:
%                inopt.Channels - number of flow patterns to display.
%                                 including 'all', 'single' and 'none'.
%                inopt.Whichchannel - the flow pattern of the channel (e.g. i) to display. 
%                                     It is valid for 'single' flow only.
%                inopt.ValLim - limits for displaying the flow patterns.
%                               Only the flow patterns relative to the flow values in 
%                               [min, max] scope will be displayed.
%                inopt.ArSzLt - the limits of the arrow size ([min, max]).
%                               It is not valid for drawing flow patterns.
%                inopt.SpSzLt - the limits of the sphere size ([min, max]).
%
% Reference for drawdtfflowgraph() (please cite):
% Babiloni F, Cincotti F, Babiloni C, Carducci F, Mattia D, Astolfi L, Basilisco A, Rossini PM, 
% Ding L, Ni Y, Cheng J, Christine K, Sweeney J, He B. Neuroimage. 2005 Jan 1;24(1):118-31. 
% Estimation of the cortical functional connectivity with the multimodal integration of high-resolution 
%  EEG and fMRI data by directed transfer function.
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


SphereSizeLimit = inopt.SpSzLt;
RAG=1.0;

nRois = max(size(flows));

sphereH = -ones(1, nRois);

mat = flows;
% mat(~mat) = nan;
valmax = max(mat);
valmin = min(mat);
    
dispmin = inopt.ValLim(1);
dispmax = inopt.ValLim(2);

cmap = colormap; 
cnum = size(cmap,1);
maxmin = valmax-valmin;
if ~maxmin
    maxmin = 1.0;
end

hold on;

if isequal(inopt.Channels,'none')
    return;
elseif isequal(inopt.Channels,'single')        
    rr = inopt.Whichchannel;   
    if flows(rr) < dispmin - 1e-6 |  flows(rr) > dispmax + 1e-6 % do not display connectivity values outside the limit.
        return;
    end

    if flows(rr) <= 0.0 % do not display zero connectivity values.
        return;
    end    
    
    normVal=(flows(rr) - valmin)/maxmin;
    normVal = min(max(0, normVal), 1);
    siz = SphereSizeLimit(1) + diff(SphereSizeLimit) * normVal;
    % siz = (SphereSizeLimit(1) + SphereSizeLimit(2))/3; % for fixed size
        
    colidx = round(normVal*(cnum-1)+1);
    col = cmap(colidx,:);

    [hx3d, hy3d, hz3d] = sphere(50);
    hx3d = siz * hx3d + RAG*roiPos(rr,1);
    hy3d = siz * hy3d + RAG*roiPos(rr,2);
    hz3d = siz * hz3d + RAG*roiPos(rr,3);
    sphereH = surf(hx3d, hy3d, hz3d, 'EdgeColor', 'none', 'FaceColor', 'r','FaceLighting', 'phong');
    set(sphereH, 'faceColor', col);
else %'all'
    for rr=[1:nRois]                           
        if flows(rr) < dispmin - 1e-6 |  flows(rr) > dispmax + 1e-6 % do not display connectivity values outside the limit.
            continue;
        end

        if flows(rr) <= 0.0 % do not display zero connectivity values.
            continue;
        end            
        
        normVal=(flows(rr) - valmin)/maxmin;
        normVal = min(max(0, normVal), 1);
        siz = SphereSizeLimit(1) + diff(SphereSizeLimit) * normVal;
        % siz = (SphereSizeLimit(1) + SphereSizeLimit(2))/3; % for fixed size
        
        colidx = round(normVal*(cnum-1)+1);
        col = cmap(colidx,:);

        [hx3d, hy3d, hz3d] = sphere(50);
        hx3d = siz * hx3d + RAG*roiPos(rr,1);
        hy3d = siz * hy3d + RAG*roiPos(rr,2);
        hz3d = siz * hz3d + RAG*roiPos(rr,3);
        sphereH = surf(hx3d, hy3d, hz3d, 'EdgeColor', 'none', 'FaceColor', 'r','FaceLighting', 'phong');
        set(sphereH, 'faceColor', col);
        
    end% for rr    
end
