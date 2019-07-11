function [pac_value, pac_sig] = pac(data, srate, lo_freq_phase, hi_freq_phase, lo_freq_amp, hi_freq_amp, surrogate_runs)

%
% function [pac_value, pac_sig] = pac(data, srate, lo_freq_phase, hi_freq_phase, lo_freq_amp, hi_freq_amp, surrogate_runs)
% Usage: pac(data, 1000, 4, 8, 80, 150, 1000)
%
% This script calculates the phase amplitude coupling (PAC) between two pass bands.
%
% This function requires 7 inputs:
% data: a single channel of continuous time-series data
% srate: sampling rate of the input data
% lo_freq_phase: lower frequency bound for the phase bandpass
% hi_freq_phase: upper frequency bound for the phase bandpass
% lo_freq_amp: lower frequency bound for the amplitude bandpass
% hi_freq_amp: upper frequency bound for the amplitude bandpass
% surrogate_runs: the number of surrogate runs used to calculate statistical significance of the PAC value.
%
% The function returns the PAC value (between 0 and 1) as well as the significance of that value compared to
% surrogate temporal shifting between the phase and amplitude series.
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
ampdata = eegfilt(ampdata, srate, lo_freq_phase, []);
ampdata = eegfilt(ampdata, srate, [], hi_freq_phase);
ampdata = angle(hilbert(ampdata)); % phase modulation of amplitude

pac_value = abs(sum(exp(1i * (phasedata - ampdata)), 'double')) / length(data); % pac calculation

spac = zeros([1 surrogate_runs]); % initialize
permarray = randperm(length(data));
permarray = permarray(1:surrogate_runs);
% surrogate analyses for significance testing
for si = 1:length(permarray)
    spac(si) = abs(sum(exp(1i * (circshift(phasedata, [-1 permarray(si)]) - ampdata)), 'double')) / length(data); % shift phase series
end
pac_sig = normcdf(-abs((pac_value - mean(spac)) / std(spac)), 0, 1) .* 2;

clear data srate lo_freq_phase hi_freq_phase lo_freq_amp hi_freq_amp surrogate_runs phasedata ampdata spac permarray si




