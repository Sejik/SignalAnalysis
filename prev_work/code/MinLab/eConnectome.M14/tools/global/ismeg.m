function  MEG = ismeg(varargin)
% ismeg - test if the input is a valid MEG structure with data.
%
% Usage: MEG = ismeg(ECOM)
%               Input: ECOM - is a structure to be tested
%
%               Output: MEG - is the returned structure after test.
%                            MEG = ECOM if it is a valid MEG structure, 
%                            otherwise MEG = [].
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
% Yakang Dai, 01-Feb-2010 15:56:30
% Release Version 2.0 beta
%
% ==========================================

len = length(varargin);
if len ~= 1
    MEG = [];
    return;
end

inclass = class(varargin);
if isequal(inclass,'cell')
    MEG = varargin{1};
else
    MEG = varargin;
end

if isempty(MEG)
    MEG = [];
    return;
end  

if ~isfield(MEG,'type')
    MEG = [];
    return;   
else
    if ~isequal(MEG.type,'MEG')
        MEG = [];
        return;
    end
end

if ~isfield(MEG,'data')
    MEG = [];
    return;   
else
    if isempty(MEG.data)
        MEG = [];
        return;   
    end
end