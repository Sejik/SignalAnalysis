function [pacA, pacB, zdiff, pdiff] = erpac_corr2(data, srate, eventsA, eventsB, timeWindow, lo_freq_phase, hi_freq_phase, lo_freq_amp, hi_freq_amp)

%
% function [pacA, pacB, zdiff, pdiff] = erpac_corr2(data, srate, eventsA, eventsB, timeWindow, lo_freq_phase, hi_freq_phase, lo_freq_amp, hi_freq_amp)
% Usage: erpac_corr2(data, 1000, eventsA, eventsB, [-100 1000], 4, 8, 80, 150)
%
% This script calculates the two-item event-related phase amplitude coupling (ERPAC) between two pass bands across trials.
%
% For each event type (A and B) the ERPAC is calculated. Since these are correlation (r) values, for each time point we can calucate the
% significant difference between r-values.
%
% This function requires 9 inputs:
% data: a single channel of continuous time-series data
% srate: sampling rate of the input data
% eventsA: a vector of event onset times where each number is the datapoint in data when the event of interest occured
% eventsB: same as eventsA, but for a different set of trials (i.e., a different experimental condition)
% timeWindow: two numbers indicating the onset and offsets (in ms) of the time window of interet around the events
% lo_freq_phase: lower frequency bound for the phase bandpass
% hi_freq_phase: upper frequency bound for the phase bandpass
% lo_freq_amp: lower frequency bound for the amplitude bandpass
% hi_freq_amp: upper frequency bound for the amplitude bandpass
%
% The function returns the PAC value (between 0 and 1) for each time point for each condition, as well as the significant difference between
% the two values at each time point.
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
[foo, phaseA] = ERP(phasedata, srate, eventsA, timeWindow(1), timeWindow(2), 1); clear foo;
[foo, ampA] = ERP(ampdata, srate, eventsA, timeWindow(1), timeWindow(2), 1); clear foo;

[foo, phaseB] = ERP(phasedata, srate, eventsB, timeWindow(1), timeWindow(2), 1); clear foo;
[foo, ampB] = ERP(ampdata, srate, eventsB, timeWindow(1), timeWindow(2), 1); clear foo;

% initialize
pacA = zeros([1 size(phaseA, 2)]);
pacB = zeros([1 size(phaseA, 2)]);
zdiff = zeros([1 size(phaseA, 2)]);
pdiff = zeros([1 size(phaseA, 2)]);
% for each time point calculate the across-trial PAC for each type of trial
for t = 1:size(phaseA, 2)
    pacA(t) = circ_corrcl(phaseA(:, t), ampA(:, t));
    pacB(t) = circ_corrcl(phaseB(:, t), ampB(:, t));
    [zdiff(t), pdiff(t)] = corrdiff(pacA(t), pacB(t), length(eventsA), length(eventsB));
end
clear t




