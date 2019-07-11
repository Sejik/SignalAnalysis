function sig = catv(varargin)
% Demonstrate CATV signal generation using the M8190A
% with CW tones on analog channels and 256QAM signals on digital channels.
%
% Signals can either be generated on a single M8190A output channel or
% distributed to two channels
% Adjustable parameters include: frequencies, tilt, modulation scheme,
% filter, etc.etc.

if (nargin == 0)
    catv_gui;
    return;
end

% define channel frequencies for NTSC - modify as needed
%band1 = [55.25 61.25 67.25 77.25 83.25];
band2 = 91.25:6:115.25;
%band3 = 121.25:6:145.25;
band4 = 151.25:6:169.25;
%band5 = 175.25:6:211.25;
band6 = 217.25:6:541.25;
band8 = 547.25:6:997.25;
freqList = 1e6*[band2 band4 band6 band8];
% digital channels above this frequency
freqDigAbove = 547e6;

% set this to true to get a modulation on the digital channels.
% if set to false, digital channels will be just CW
digWithMod = true;
% set this to true to generate a signal on a single M8190A channel with
% both the digital and analog carriers.  If set to false, it will generate
% the analog signals on one channel and digital on the other and you have
% to use an external combiner to bring them together (=more complicated
% setup but better S/N).
sameChannel = true;

% tilt in dB across the whole frequency range (analog+digital)
tilt = 15;
% attenuation of the digital channels vs. analog channels
digOffset = 6;
% Parameters for the digital channels
symbolRate = 5e6;
numSymbols = 300;   % number of symbols that are transmitter
modType = 'QAM256'; % modulation scheme
filterNSym = 20;    % filter length in symbols
filterBeta = 0.12;  % filter roll-off
dropList = 5:5:76;  % drop a few carriers, so that S/N can be seen. Set to [] if unused
% calculate a sample rate that makes oversampling an integer

i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'freqlist';       freqList = varargin{i+1};
            case 'freqdigabove';   freqDigAbove = varargin{i+1};
            case 'droplist';       dropList = varargin{i+1};
            case 'tilt';           tilt = varargin{i+1};
            case 'digoffset';      digOffset = varargin{i+1};
            case 'digwithmod';     digWithMod = varargin{i+1};
            case 'samechannel';    sameChannel = varargin{i+1};
            case 'symbolrate';     symbolRate = varargin{i+1};
            case 'numsymbols';     numSymbols = varargin{i+1};
            case 'modtype';        modType = varargin{i+1};
            case 'oversampling';   oversampling = varargin{i+1};
            case 'filtertype';     filterType = varargin{i+1};
            case 'filternsym';     filterNSym = varargin{i+1};
            case 'filterbeta';     filterBeta = varargin{i+1};
            case 'correction';     correction = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end
sampleRate = symbolRate * oversampling;

% remove the carriers in the droplist
dropList(dropList>length(freqList)) = [];
freqList(dropList) = [];

%% generate digitally modulated carriers
f_digital = freqList(freqList > freqDigAbove);
mag = (f_digital - min(freqList)) * tilt / (max(freqList) - min(freqList)) - digOffset;
if (digWithMod)
    sigDigital = iqmod('sampleRate', sampleRate, 'oversampling', oversampling, 'modType', modType, ...
        'numSymbols', numSymbols, 'filterNsym', filterNSym, 'filterBeta', filterBeta, ...
        'carrierOffset', f_digital, 'filterType', filterType, 'correction', correction, ...
        'magnitude', mag, 'normalize', 0);
    numCarrier = length(f_digital);
    rmsTotal = norm(sigDigital) / sqrt(length(sigDigital));
    rmsAvg = rmsTotal / sqrt(numCarrier);   % this is amplitude, not power!
    sigDigital = sigDigital ./ rmsAvg * 10;
else
    sigDigital = iqtone('sampleRate', sampleRate, 'tone', f_digital, 'magnitude', mag, ...
        'numSamples', 0, 'normalize', 0);
end
numSamples = length(sigDigital);


%% generate tones on analog carriers
% use same number of samples as above, so the vectors can be added
f_analog = freqList(freqList <= freqDigAbove);
mag = (f_analog - min(freqList)) * tilt / (max(freqList) - min(freqList));
sigAnalog = iqtone('sampleRate', sampleRate, 'tone', f_analog, 'magnitude', mag, ...
    'numSamples', numSamples, 'normalize', 0, 'correction', correction);
sigAnalogPlusDigital = sigAnalog + sigDigital;


%% generate tones on analog and digital carriers
if (~digWithMod)
    mag = (freqList - min(freqList)) * tilt / (max(freqList) - min(freqList));
    mag = mag - digOffset*(freqList > 547e6);
    sigAnalogPlusDigital = iqtone('sampleRate', sampleRate, 'tone', freqList, 'magnitude', mag, ...
        'normalize', 0, 'correction', correction);
end

% build a complex vector, since iqdownload will load the real part
% in channel 1 and the complex part in channel 2
if (sameChannel)
    sig = complex(real(sigAnalogPlusDigital), real(sigAnalogPlusDigital));
else
    sig = complex(real(sigDigital), real(sigAnalog));
end
end

