function [A] = matrix_former(ts,p_max)
% matrix_former - create Multivariate (Vector) adaptive AR model with 
%                           maximum order p_max for the time series ts. 
%
% Usage: A = matrix_former(ts,p_max);
%
% Input: ts - the time series where each column is the temporal data from a
%                 single channel
%           p_max - the maximum order of the MVAAR model
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
% Yakang Dai, 29-June-2010 16:55:30
% Release Version 1.0
%
% ==========================================

nchan = size(ts,2);
[x,e,Kalman,Q2] = mvaar(ts,p_max);

num_points = size(x,1);
A = cell(num_points,1);

for z=1:num_points
    for i=1:nchan
        for p=1:p_max
            B(i,:,p+1) = x(z,(i-1)*nchan*p_max+nchan*(p-1)+1:(i-1)*nchan*p_max+nchan*p);
        end
    end
    B(:,:,1) = -eye(nchan);
    A{z} = B;
end

