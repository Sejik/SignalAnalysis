function [TFR,timeVec,freqVec] = morletTFR(S,freqVec,Fs,width)
% morletTFR - return the average time-frequency of the multi-channel time series.
%
% Usage: [TFR,timeVec,freqVec] = morletTFR(S,freqVec,Fs,width)
% 
% Input: S(i,j) - means point j in the time series of channel i.
%           freqVec - is specified frequency vector (e.g. [2 : 0.05 : 15]).
%           Fs - is the sampling rate of the time series (e.g. 300 Hz).
%           width - is the convolution scope (e.g. 7).
%
% Output: TFR - the average time-frequency.
%              timeVec - a vector for the time points.
%              freqVec - a vector for the frequency points.
%
% Program Author: Lei Qin, University of Minnesota, USA
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

timeVec = (1:size(S,2))/Fs;
B = zeros(length(freqVec),size(S,2));
for i=1:size(S,1)
    for j=1:length(freqVec)
       B(j,:) = energyvec(freqVec(j),detrend(S(i,:),'linear'),Fs,width) + B(j,:);
    end
end
TFR = B/size(S,1);

function y = energyvec(f,s,Fs,width)
dt = 1/Fs;
sf = f/width;
st = 1/(2*pi*sf);
t=-3.5*st:dt:3.5*st;
m = morlet(f,t,width);
y = conv(s,m);
y = (2*abs(y)/Fs).^2;
y = y(ceil(length(m)/2):length(y)-floor(length(m)/2));

function y = morlet(f,t,width)
sf = f/width;
st = 1/(2*pi*sf);
A = 1/(st*sqrt(2*pi));
y = A*exp(-t.^2/(2*st^2)).*exp(i*2*pi*f.*t);
return;