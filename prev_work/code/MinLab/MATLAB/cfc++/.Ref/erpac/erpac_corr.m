function [pac_value, pac_z, pac_sig] = erpac_corr(data, srate, events, timeWindow, lo_freq_phase, hi_freq_phase, lo_freq_amp, hi_freq_amp, surrogate_runs)

%
% function [pac_value, pac_z, pac_sig] = erpac_corr(data, srate, events, timeWindow, lo_freq_phase, hi_freq_phase, lo_freq_amp, hi_freq_amp, surrogate_runs)
% Usage: erpac_corr(data, 1000, events, [-100 1000], 4, 8, 80, 150, 1000)
%
% This script calculates the event-related phase amplitude coupling (ERPAC) between two pass bands across trials.
%
% This function requires 8 inputs, but can take 9:
% data: a single channel of continuous time-series data
% srate: sampling rate of the input data
% events: a vector of event onset times where each number is the datapoint in data when the event of interest occured
% timeWindow: two numbers indicating the onset and offsets (in ms) of the time window of interet around the events
% lo_freq_phase: lower frequency bound for the phase bandpass
% hi_freq_phase: upper frequency bound for the phase bandpass
% lo_freq_amp: lower frequency bound for the amplitude bandpass
% hi_freq_amp: upper frequency bound for the amplitude bandpass
% surrogate_runs: the number of surrogate runs used to calculate statistical significance of the PAC value (optional)
%
% The function returns the PAC value (between 0 and 1) for each time point. If surrogate_runs is include, the z-score
% and associated significance of the PAC value compared to surrogate temporal shifting between the phase and amplitude
% series. Resampling is done at each time point to control for the effects of event-related changes in amplitude or
% phase-locking.
%
% Bradley Voytek
% Copyright (c) 2011
% University of California, San Francisco
% Department of Neurology

% error checking
if (nargout > 1) && (nargin < 9)
    error('number of surrogate runs need to be defined to calculate z-score and surrogate p-value!');
end

% filter
phasedata = eegfilt(data, srate, lo_freq_phase, []);
phasedata = eegfilt(phasedata, srate, [], hi_freq_phase);
phasedata = angle(hilbert(phasedata)); % phase

ampdata = eegfilt(data, srate, lo_freq_amp, []);
ampdata = eegfilt(ampdata, srate, [], hi_freq_amp);
ampdata = abs(hilbert(ampdata)); % amplitude

% extract events
[foo, phasedata] = ERP(phasedata, srate, events, timeWindow(1), timeWindow(2), 1); clear foo;
[foo, ampdata] = ERP(ampdata, srate, events, timeWindow(1), timeWindow(2), 1); clear foo;

% for each time point calculate the across-trial PAC
for t = 1:size(phasedata, 2)
    pac_value(t) = circ_corrcl(phasedata(:, t), ampdata(:, t));
end
clear t

% resampling stats
if nargin > 8
    surrr = zeros([surrogate_runs length(pac_value)]); % initialize
    for s = 1:surrogate_runs
        disp(['surrogate run: ' num2str(s)]);
        a = ampdata(randperm(length(events)), :);
        for t = 1:size(a, 2)
            surrr(s, t) = circ_corrcl(phasedata(:, t), a(:, t));
        end
        clear t a
    end
    clear s surr p

    % z-score
    pac_z = zeros([1 length(pac_value)]); % initialize
    for t = 1:length(pac_value)
        pac_z(t) = (pac_value(t) - mean(surrr(:, t))) ./ std(surrr(:, t));
    end
    clear t

    pac_sig = z2p(pac_z); % p-value from z-score
end
