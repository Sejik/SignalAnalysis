function [samples, sampleRate] = iserial(varargin)
% This function generates an serial data stream with distortions
% Parameters are passed as property/value pairs. Properties are:
% 'dataRate' - data rate in bits/s
% 'transitionTime' - rise/fall time in UI (default: 0.5)
% 'numBits' - number of bits to be generated (default: 128)
% 'data' - can be 'clock', 'random', 'MLT-3', 'PAM3', 'PAM4', 'PAM5'
%          or a vector of binary values
% 'noise' - in percent (default = 0)
% 'isi' - in percent (default = 0)
% 'SJfreq' - sinusoidal jitter frequency in Hz (default: no jitter)
% 'SJpp' - sinusoidal jitter in UI
% 'RJpp' - 6-sigma value in UI
% 'sampleRate' - sample rate in Hz (default: max. sample rate)
% 'amplitude' - data will be in the range (-ampl...+ampl) + noise
%
% If called without arguments, opens a graphical user interface to specify
% parameters

%% parse arguments
if (nargin == 0)
    iserial_gui;
    return;
end
dataRate = 1e9;
ttUI = .5;
numBits = 128;
data = 'random';
isi = 0;
SJfreq = 10e6;
SJpp = 0.5;
RJpp = 0;
noise = 0;
sampleRate = 0;
amplitude = 1;
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'datarate';     dataRate = varargin{i+1};
            case 'transitiontime'; ttUI = varargin{i+1};
            case 'numbits';      numBits = varargin{i+1};
            case 'data';         data = varargin{i+1};
            case 'isi';          isi = varargin{i+1};
            case 'noise';        noise = varargin{i+1};
            case 'sjfreq';       SJfreq = varargin{i+1};
            case 'sjpp';         SJpp = varargin{i+1};
            case 'rjpp';         RJpp = varargin{i+1};
            case 'samplerate';   sampleRate = varargin{i+1};
            case 'amplitude';    amplitude = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

arbConfig = loadArbConfig();
if (sampleRate ~= 0)
    fsApprox = sampleRate;
else
    fsApprox = arbConfig.defaultSampleRate;
end

% use the same sequence every time so that results are comparable
randStream = RandStream('mt19937ar'); 
reset(randStream);

if (ischar(data))
    switch(lower(data))
        case 'clock'
            if (mod(numBits, 2) ~= 0)
                errordlg('Clock pattern requires an even number of bits');
            end
            data = repmat([0 1], 1, ceil(numBits / 2));
        case 'random'
            data = randStream.rand(1,numBits) < 0.5;
        case 'mlt-3'
            mltCode = [.5 0 .5 1];
            data = mltCode(mod(cumsum(randStream.randi([0 1], 1, numBits)), 4) + 1);
        case 'pam3'
            data = floor(3 * randStream.rand(1,numBits)) / 2;
        case 'pam4'
            data = floor(4 * randStream.rand(1,numBits)) / 3;
        case 'pam5'
            data = floor(5 * randStream.rand(1,numBits)) / 4;
        case 'prbs7'
            h = commsrc.pn('GenPoly', [7 6 0], 'NumBitsOut', numBits);
            data = h.generate()';
        case 'prbs9'
            h = commsrc.pn('GenPoly', [9 5 0], 'NumBitsOut', numBits);
            data = h.generate()';
        case 'prbs11'
            h = commsrc.pn('GenPoly', [11 9 0], 'NumBitsOut', numBits);
            data = h.generate()';
        case 'prbs15'
            h = commsrc.pn('GenPoly', [15 14 0], 'NumBitsOut', numBits);
            data = h.generate()';
        otherwise
            errordlg(['undefined data pattern: ' data]);
    end
elseif (isvector(data))
    numBits = length(data);
    % make sure the data is in the correct format
    if (isvector(data) && size(data,1) > 1)
        data = data.';
    end
else
    error('data must be ''clock'', ''random'' or a vector of bits');
end

spbApprox = fsApprox / dataRate;  % approx. number of samples per bit
% calculate the number of samples to match segment granularity
numSamples = round((spbApprox * numBits) / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
% rounding might bring the the sample rate above the maximum
if (numSamples / numBits * dataRate > arbConfig.maximumSampleRate)
    numSamples = numSamples - arbConfig.segmentGranularity;
end
if (numSamples < arbConfig.minimumSegmentSize)
    errordlg('waveform too short - adjust number of bits');
end
if (numSamples > arbConfig.maximumSegmentSize)
    errordlg('waveform too long - adjust number of bits');
end
% calculate exact spb (will likely be NOT an integer value)
spb = numSamples / numBits;
if (sampleRate == 0)
    sampleRate = spb * dataRate;
end
% convert transition time in number of samples
tt = ttUI * spb;
% define jitter as a function of sample position
SJcycles = round(SJfreq * numBits / dataRate);   % jitter cycles
if (SJpp ~= 0 && SJfreq ~= 0 && SJcycles == 0)
    warndlg(['SJ frequency too low for the given number of bits. Minimum is: ' ...
        sprintf('%g', (dataRate / numBits)) ' Hz'], 'Warning', 'modal');
end
% define SJ and RJ functions. The functions will be called with a vector of
% transition times (in units of samples) and are expected to return the
% deviation in units of samples
SJfct = @(x) SJpp / 2 * spb * sin(SJcycles * 2*pi*x/numSamples);
RJfct = @(x) RJpp / 2 * spb * (sum(randStream.rand(6,length(x)))/6-0.5)*2;
noiseFct = @() noise * (sum(randStream.rand(6,numSamples))/6-0.5)*2;
% the transition function will be called with values between 0 and 1 and is
% expected to return a value between 0 and 1
TTfct = @(x) (cos(pi*(x-1))+1)/2;   % raised cosine
%TTfct = @(x) x;   % straight line

% calculate transition positions (start with first half bit to get the
% complete transition, add 1 because of array indices)
dpos = find(diff([data data(1)]));
ptx = spb * (dpos - 0.5) + 1;
% add jitter to the transition points
pt = ptx + SJfct(ptx) + RJfct(ptx);

% now calculate the actual samples
samples = zeros(1,numSamples);
numPts = length(pt);
pt(numPts + 1) = numSamples + tt;   % add one more point at the end to avoid overflow
dpos(end+1) = 1;                    % dito
k = 1;                              % k counts transitions
lev = data(dpos(1)+1);                % start with the first data value
oldlev = data(1);                   % remember the previous level in transitions
i = 1;                              % i counts samples
while i <= numSamples
    if (i <= pt(k)-tt/2)            % before transition
        samples(i) = oldlev;        %   set to current level
        i = i + 1;                  %   and go to next sample
    elseif (i >= pt(k)+tt/2)        % after transition
        k = k + 1;                  %   check next transition (don't increment sample ptr!)
        oldlev = lev;               %   remember previous level
        lev = data(mod(dpos(k),numBits)+1);  %   load new level
    else                            % during the transition
        m = (i - (pt(k)-tt/2)) / tt;
        samples(i) = oldlev + TTfct(m) * (lev - oldlev);
        i = i + 1;
    end
end
pt(numPts + 1) = [];                % remove temporary transition point

% add ISI
tmp = repmat(samples, 1, 2);
tmp = filter([1-isi 0], [1 -1*isi], tmp);
samples = tmp(numSamples+1:end);

% shift from [0...1] to [-1...+1]
samples = (2*samples - 1);
% add noise
samples = samples + noiseFct();
% set range to [-ampl...+ampl]
samples = samples * amplitude;

delete(randStream);

