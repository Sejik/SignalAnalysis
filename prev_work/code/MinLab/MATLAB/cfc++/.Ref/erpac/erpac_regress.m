function [pac_R, pac_F, pac_p, pac_errorvar] = erpac_regress(data, srate, events, timeWindow, lo_freq_phase, hi_freq_phase, lo_freq_amp, hi_freq_amp)

%
% function [pac_R, pac_F, pac_p, pac_errorvar] = erpac_regress(data, srate, events, timeWindow, lo_freq_phase, hi_freq_phase, lo_freq_amp, hi_freq_amp)
% Usage: erpac_regress(data, 1000, events, [-100 1000], 4, 8, 80, 150)
%
% This script calculates the event-related phase amplitude coupling (ERPAC) between two pass bands across trials.
%
% This function requires 8 inputs:
% data: a single channel of continuous time-series data
% srate: sampling rate of the input data
% events: a vector of event onset times where each number is the datapoint in data when the event of interest occured
% timeWindow: two numbers indicating the onset and offsets (in ms) of the time window of interet around the events
% lo_freq_phase: lower frequency bound for the phase bandpass
% hi_freq_phase: upper frequency bound for the phase bandpass
% lo_freq_amp: lower frequency bound for the amplitude bandpass
% hi_freq_amp: upper frequency bound for the amplitude bandpass
%
% The function returns the R2 statistic, the F statistic and its p value, and an estimate of the error variance.
%
% Bradley Voytek
% Copyright (c) 2011
% University of California, San Francisco
% Department of Neurology

% filter
phasedata = eegfilt(data, srate, lo_freq_phase, []);
phasedata = eegfilt(phasedata, srate, [], hi_freq_phase);
phasedata = angle(hilbert(phasedata)); % phase

ampdata = eegfilt(data, srate, lo_freq_amp, []);
ampdata = eegfilt(ampdata, srate, [], hi_freq_amp);
ampdata = abs(hilbert(ampdata)); % amplitude

% extract events
[foo, phaseDat] = ERP(phasedata, srate, events, timeWindow(1), timeWindow(2), 1); clear foo;
[foo, ampDat] = ERP(ampdata, srate, events, timeWindow(1), timeWindow(2), 1); clear foo;

% initialize
pac_R = zeros([1 size(phaseDat, 2)]);
pac_F = zeros([1 size(phaseDat, 2)]);
pac_p = zeros([1 size(phaseDat, 2)]);
pac_errorvar = zeros([1 size(phaseDat, 2)]);
% for each time point calculate the across-trial PAC for each type of trial
for t = 1:size(phaseDat, 2)
    dep = (ampDat(:, t))';
    ind = [ones([1 length(events)]); cos(phaseDat(:, t))'; sin(phaseDat(:, t)')]; % cos and sin components of phase
    [b, bint, r, rint, stats] = regress(dep', ind'); clear b bint r rint
    pac_R(t) = stats(1);
    pac_F(t) = stats(2);
    pac_p(t) = stats(3);
    pac_errorvar(t) = stats(4);
    clear stats ind dep
end
clear t




