function [gamma2_set] = ADTF(ts,low_freq,high_freq,p,fs)
% ADTF - perform Adaptive Directed Transfer Function analysis among multi-channel time series. 
%
% Usage: gamma2_set = ADTF(ts,low_freq,high_freq,p,fs)
%
% Input: ts - the time series where each column is the temporal data from a
%             single channel
%        low_freq - the lowest frequency to perform DTF analysis
%        high_freq - the highest frequency to perform DTF analysis
%        p - the order of the MVAAR model
%        fs - the sampling frequency 
%
% Output: gamma2_set - the DTF values from the points in the time series
%
% Description: This function performs DTF analysis on a time series using
%              an adaptive MVAR model (MVAAR). The MVAAR model generates an
%              updated coefficient matrix for each time point which is then
%              used in the DTF calculations. The output is in the form
%              gamma2_set(a,b,c,d) where a = the time point, b = the sink
%              channel, c = the source channel, d = the index for the
%              frequency value.
%
% Program Author: Christopher Wilke, University of Minnesota, USA
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
% Yakang Dai, 19-June-2010 23:50:30
% Release Version 1.0
%
% ==========================================

% Creates the MVAAR model
h = waitbar(0.5,'Creating the MVAAR model, please wait...');
A = matrix_former(ts,p);
close(h);

% Computes the DTF values from the MVAAR model
h = waitbar(0,'Computing ADTF values, please wait...');
total = size(A,1);
thr = round(0.1*total);
ct = 0;
for i = 1:total
    gamma2 = DTFvalue(A{i},low_freq,high_freq,fs);
    gamma2_set(i,:,:,:) = gamma2;
    
    ct = ct + 1; 
    if ~mod(ct, thr)
       waitbar(ct/total);
    end
end

close(h);
