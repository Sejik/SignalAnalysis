function k = m_dsearchn(X, XI)
% m_dsearchn - get the index of the closest point in X for each point in XI.
%
% Usage: k = m_dsearchn(X, XI)
%
% Input: X - is a 2D location array (M * 3).
%        XI - is a 2D location array (N * 3).
%
% Output: k - is a vector (1 * N) for the indices of the closest points
%             in X for points in XI.
%
% m_dsearchn supposes X and XI have the same origin, and uses the minmum 
% vector angle to decide the closest point.
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


szX = size(X);
szXI = size(XI);
if szX(2)~=3 | szXI(2)~=3
    errordlg('Input dimensions of coordinates must be M*3 !');
    k = [];
    return;
end

normX = zeros(szX(1),3);
for i = 1:szX(1)
    normX(i,:) = X(i,:)/norm(X(i,:));
end

for i = 1:szXI(1)
    normXI = XI(i,:)/norm(XI(i,:));
    cos_X_XI = normX * normXI';
    [C,idx] = max(cos_X_XI);
    k(i) = idx;
end
return;
