function [new_gamma2] = ADTFsigvalues(ts,low_freq,high_freq,p,fs,shufftimes, siglevel, handle)
% ADTFsigvalues - compute statistical significance values for relative ADTF values
%
% Input: ts - the time series where each column is the temporal data from
%             a single channel.
%        low_freq - the lowest frequency to perform ADTF analysis.
%        high_freq - the highest frequency to perform ADTF analysis.
%        p - the order of the model.
%        fs - the sampling rate of the data.
%        siglevel - the significance level, default is 0.05.
%        shufftimes - the shuffling times, default is 1000.
%        handle - the handle of the uicontrol for displaying computation
%                 progress, the progress will be displayed in the command window 
%                 of MATLAB if handle = []. 
%
% Output: new_gamma2 - the significant points from the surrogate ADTF analysis
%
% Description: This function generates surrogate datasets by phase shifting
%              the original time series and then performs ADTF analysis on
%              these new time series for statistical testing. The output is
%              in the form new_gamma2(a,b,c,d), where a = the time point in a time series, 
%              b = the sink channel, c = the source channel, d = the frequency index.
%
% Program Author: Lei Ding and Christopher Wilke, University of Minnesota, USA
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
% Yakang Dai, 20-June-2010 00:56:30
% Release Version 1.0
%
% ==========================================

if nargin < 5
    fs = 400;
end

% Set the number of repetitions to 1000 if not defined
if nargin < 6
    nreps = 1000;
else
    nreps = shufftimes;
end

if isempty(siglevel)
    tvalue = 0.05;
else
    tvalue = siglevel;
end

% Number of channels in the time series
nchan = size(ts,2);

% Number of sample points in the time series
nsample = size(ts,1);

% Number of frequencies
nfreq = high_freq-low_freq+1;

sig_size = floor(tvalue * nreps)+1;
if sig_size==1
    fprintf(1, '%s\n', 'Surrogate repetition number too small!');
end
new_gamma2 = zeros(sig_size-1,nsample,nchan,nchan,nfreq);

% Number of surrogate datasets to generate
for i=1:nreps

    % Display the progress of the function on a uicontrol
    rate = round(100 * i / nreps);
    progress = ['Completing ' num2str(rate) '%'];
    if ~isempty(handle)
        set(handle, 'string',progress);
        drawnow;
    else
        fprintf('%s \n',['Completing ' num2str(rate) '%']);
    end
    
    % Generate a surrogate time series
    for j=1:nchan
        Y = fft(ts(:,j));
        Pyy = sqrt(Y.*conj(Y));
        Phyy = Y./Pyy;
        index = 1:size(ts,1);
        index = surrogate(index);
        Y = Pyy.*Phyy(index);
        newts(:,j) = real(ifft(Y));
    end
    
    % Compute the ADTF values for each surrogate time series
    gamma2_set = ADTF(newts,low_freq,high_freq,p,fs);
    
    %modified by YFLu, 02/08/2010
    % Save the surrogate ADTF values
    new_gamma2(sig_size,:,:,:,:) = gamma2_set;
    new_gamma2 = sort(new_gamma2,'descend');
    new_gamma2(sig_size,:,:,:,:) = [];
end
new_gamma2 = squeeze(new_gamma2(sig_size-1,:,:,:,:));
