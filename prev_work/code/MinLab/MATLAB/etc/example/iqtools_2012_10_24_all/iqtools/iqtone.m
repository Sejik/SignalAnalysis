function iqdata = iqtone(varargin)
% Generate an IQ multitone waveform
% Parameters are passed as property/value pairs. Properties are:
% 'sampleRate' - sample rate in Hz
% 'numSamples' - number of samples in IQ waveform (optional)
% 'tone' - vector of tone frequencies in Hz
% 'magnitude' - vector of relative magnitudes in dB
% 'phase' - vector of phases in rad or 'Random', 'Zero', 'Increasing',
%          'Parabolic'
% 'normalize' - if set to 1 will normalize the output to [-1 ... +1]
% 'correction' - if set to 1 will apply predistortion
% 'arbConfig' - struct as created by iqconfig
%
% If called without arguments, opens a graphical user interface to specify
% parameters.
%
% Agilent Technologies, Thomas Dippon, 2011

%% parse arguments
if (nargin == 0)
    iqtone_gui;
    return;
end
% some default parameters
sampleRate = 8e9;
numSamples = 0;
tone = linspace(-250e6, 250e6, 21);
magnitude = [];
phase = 'random';
normalize = 1;
correction = 0;
arbConfig = [];
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate';   sampleRate = varargin{i+1};
            case 'numsamples';   numSamples = varargin{i+1};
            case 'tone';         tone = varargin{i+1};
            case 'magnitude';    magnitude = varargin{i+1};
            case 'phase';        phase = varargin{i+1};
            case 'normalize';    normalize = varargin{i+1};
            case 'correction';   correction = varargin{i+1};
            case 'arbconfig';    arbConfig = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

arbConfig = loadArbConfig(arbConfig);
numTones = length(tone);
if (isempty(magnitude))
    magnitude = zeros(numTones, 1);
end
magnitude = fixlength(magnitude, length(tone));
if (ischar(phase))
    switch lower(phase)
        case 'random'
            % use the same sequence every time so that results are comparable
            randStream = RandStream('mt19937ar'); 
            reset(randStream);
            phase = randStream.rand(1,numTones) * 2 * pi;
            delete(randStream);
        case 'random-no-seed'
            phase = rand(1,numTones) * 2 * pi;
        case 'zero'
            phase = zeros(1,numTones);
        case 'increasing'
            phase = pi * linspace(-1, 1 - 1/numTones, numTones);
        case 'parabolic'
            phase = cumsum(pi * linspace(-1, 1 - 1/numTones, numTones));
        otherwise
            error(['invalid phase: ' phase]);
    end
end
phase = fixlength(phase, length(tone));
% apply flatness correction based on an array of
% frequency(Hz)/amplitude(dB) correction values
if (correction)
    try
        load('ampCorr.mat');
        freq = ampCorr(:,1);
        corr = ampCorr(:,2);
    catch ex
        warndlg('No correction file available. Please use "Calibrate" to create it', 'Warning', 'modal');
    end
    magnitude = reshape(magnitude, 1, length(magnitude));
    magnitude = magnitude + reshape(interp1(freq, corr, tone, 'cubic', 0), 1, length(magnitude));
end


%% determine the best number of samples if numSamples == 0
if (numSamples == 0)
    if (isempty(tone))
        iqdata = zeros(1, arbConfig.minimumSegmentSize);
        return;
    end
    [n,d] = rat(tone - round(tone));
    mult = 2*d(1);
    for i = 2:numTones
        mult = lcm(mult, d(i));
        if (mult > 1e4)     % if numbers grow too big it does not make sense to find a common multiple...
            break;
        end
    end
    div = sampleRate;
    for i = 1:numTones
        div = gcd(div, round(tone(i) * mult));
    end
    numSamples = round(sampleRate / div * mult);
    numSamples = lcm(numSamples, arbConfig.segmentGranularity);
    while (numSamples < arbConfig.minimumSegmentSize)
        numSamples = 2 * numSamples;
    end
    if (numSamples > arbConfig.maximumSegmentSize)
        numSamples = arbConfig.maximumSegmentSize - mod(arbConfig.maximumSegmentSize, arbConfig.segmentGranularity);
    end
    % limit the number of samples to a reasonable value in case of odd
    % frequency combinations (to keep calculation time within limits)
    maxSpl = 4*1024*1024;
    if (numSamples > maxSpl)
        numSamples = maxSpl - mod(maxSpl, arbConfig.segmentGranularity);
    end
end

%% generate signal in frequency domain
magSignal = zeros(1,numSamples);
phaseSignal = zeros(1,numSamples);
freqToPoints = numSamples / sampleRate;

% Place tones in frequency domain (with wrap-around)
tonePtExact = mod(tone * freqToPoints + numSamples/2, numSamples) + 1;
% round to next frequency bin
tonePoint = round(tonePtExact);
% allow some floating point inaccuracy
if (max(abs(tonePoint - tonePtExact)) > 1e-12)
    warndlg('Some tone frequencies were rounded - consider adjusting Start/Stop frequency and number of tones', 'Warning');
end
magSignal(tonePoint) = 10.^(magnitude./20);     % Convert from dB to linear
phaseSignal(tonePoint) = phase;
% generate complex frequency domain signal
fSignal = magSignal .* exp(j * phaseSignal);
% and convert into time domain
iqdata = numSamples * ifft(fftshift(fSignal));
% normalize
if (normalize)
    scale = max(max(abs(real(iqdata))), max(abs(imag(iqdata))));
    iqdata = iqdata / scale;
end

end

function x = fixlength(x, len)
x = reshape(x, 1, length(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
end
