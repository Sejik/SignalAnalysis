function  EEG = iseeg(varargin)
% iseeg - test if the input is a valid EEG structure with data.
%
% Usage: EEG = iseeg(ECOM)
%               Input: ECOM - is a structure to be tested
%
%               Output: EEG - is the returned structure after test.
%                            EEG = ECOM if it is a valid EEG structure, 
%                            otherwise EEG = [].
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

len = length(varargin);
if len ~= 1
    EEG = [];
    return;
end

inclass = class(varargin);
if isequal(inclass,'cell')
    EEG = varargin{1};
else
    EEG = varargin;
end

if isempty(EEG)
    EEG = [];
    return;
end  

if ~isfield(EEG,'type')
    EEG = [];
    return;   
else
    if ~isequal(EEG.type,'EEG')
        EEG = [];
        return;
    end
end

if ~isfield(EEG,'data')
    EEG = [];
    return;   
else
    if isempty(EEG.data)
        EEG = [];
        return;   
    end
end