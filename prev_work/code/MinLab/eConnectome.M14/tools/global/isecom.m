function  ECOM = isecom(varargin)
% isecom - test if the input is a valid ECOM structure with data.
%
% Usage: ECOM = isecom(ECOM)
%               Input: ECOM - is a structure to be tested
%
%               Output: ECOM - is the returned structure after test.
%                            ECOM = ECOM if it is a valid ECOM structure, 
%                            otherwise ECOM = [].
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
% Yakang Dai, 10-Feb-2011 14:05:30
% Support MEG
%
% Yakang Dai, 01-Mar-2010 15:20:30
% Release Version 1.0 beta 
%
% ==========================================

len = length(varargin);
if len ~= 1
    ECOM = [];
    return;
end

inclass = class(varargin);
if isequal(inclass,'cell')
    ECOM = varargin{1};
else
    ECOM = varargin;
end

if isempty(ECOM)
    ECOM = [];
    return;
end  

if ~isfield(ECOM,'type')
    ECOM = [];
    return;   
else
    isvalid = isequal(upper(ECOM.type),'EEG') | isequal(upper(ECOM.type),'ECOG') | isequal(upper(ECOM.type),'MEG');
    if ~isvalid
        ECOM = [];
        return;
    end
end

if ~isfield(ECOM,'data')
    ECOM = [];
    return;   
else
    if isempty(ECOM.data)
        ECOM = [];
        return;   
    end
end
