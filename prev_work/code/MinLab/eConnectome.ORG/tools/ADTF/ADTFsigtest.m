function [gamma2] = ADTFsigtest(gamma2,gamma2_sig)
% ADTFsigtest - perform significance test for the calculated ADTF values.
%
% Input: gamma2 - the ADTF values calculated by the ADTF function and of
%                 dimensions (npts x nchan x nchan x nfreq)
%        gamma2_sig - the significant points from the surrogate ADTF analysis 
%                     by the ADTFsigvalues function and of dimensions 
%                     (npts x nchan x nchan x nfreq)
%
% Output: gamma2 - the significant ADTF values
%
% Description: This program takes an input of ADTF values and the significant 
%              points from the surrogate ADTF analysis and returns the 
%              ADTF values which are found to be statistically significant. 
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
% Yakang Dai, 20-June-2010 01:12:30
% Release Version 1.0
%
% ==========================================

npts = size(gamma2_sig,1);
nchan = size(gamma2_sig,2);
nfreq = size(gamma2_sig,4);

for t = 1:npts
    for i=1:nchan
        for j=1:nchan
            for k = 1:nfreq             
                if i~=j
                    if gamma2_sig(t,i,j,k) > gamma2(t,i,j,k)
                        gamma2(t,i,j,k) = 0;
                    end
                else
                    gamma2(t,i,j,k) = 0;
                end
            end
        end
    end
end

