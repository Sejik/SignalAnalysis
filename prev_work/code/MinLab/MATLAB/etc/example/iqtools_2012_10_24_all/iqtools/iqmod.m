function iqdata = iqmod(varargin)
% Generate I/Q modulation waveform
% Parameters are passed as property/value pairs. Properties are:
% 'sampleRate' - sample rate in Hz
% 'numSymbols' - number of symbols
% 'modType' - modulation type (BPSK, QPSK, OQPSK, QAM4, QAM16, QAM64, QAM256)
% 'oversampling' - oversampling rate
% 'filterType' - pulse shaping filter ('Raised Cosine','Square Root Raised Cosine','Gaussian')
% 'filterNsym' - number of symbols for pulse shaping filter
% 'filterBeta' - Beta for pulse shaping filter
% 'carrierOffset' - frequency of carriers (can be a scalar or vector)
% 'magnitude' - relative magnitude (in dB) for the individual carriers
% 'newdata' - set to 1 if you want separate random bits to be generated for each carrier
% 'correction' - apply amplitude correction stored in 'ampCorr.mat'
%
% If called without arguments, opens a graphical user interface to specify
% parameters
%
% Agilent Technologies, Thomas Dippon, 2011

if (nargin == 0)
    iqmod_gui;
    return;
end
sampleRate = 4.2e9;
numSymbols = 256;
modType = 'QAM16';
oversampling = 4;
filterType = 'Square Root Raised Cosine';
filterNsym = 8;
filterBeta = 0.35;
carrierOffset = 0;
magnitude = 0;
newdata = 1;
correction = 0;
normalize = 1;
arbConfig = [];
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate';     sampleRate = varargin{i+1};
            case 'numsymbols';     numSymbols = varargin{i+1};
            case 'modtype';        modType = varargin{i+1};
            case 'oversampling';   oversampling = varargin{i+1};
            case 'filtertype';     filterType = varargin{i+1};
            case 'filternsym';     filterNsym = varargin{i+1};
            case 'filterbeta';     filterBeta = varargin{i+1};
            case 'carrieroffset';  carrierOffset = varargin{i+1};
            case 'magnitude';      magnitude = varargin{i+1};
            case 'newdata';        newdata = varargin{i+1};
            case 'correction';     correction = varargin{i+1};
            case 'normalize';      normalize = varargin{i+1};
            case 'arbconfig';      arbConfig = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end
offsetmod = 0;
switch upper(modType)
    case 'BPSK';   hmod = modem.pskmod(2);
    case 'BPSK_X'; hmod = modem.pskmod(2, pi/2);
    case 'QPSK';   hmod = modem.pskmod(4, pi/4);
    case 'OQPSK';  hmod = modem.pskmod(4, pi/4); offsetmod = 1;
    case 'QAM4';   hmod = modem.qammod(4);
    case 'QAM16';  hmod = modem.qammod(16);
    case 'QAM32';  hmod = modem.qammod(32);
    case 'QAM64';  hmod = modem.qammod(64);
    case 'QAM128'; hmod = modem.qammod(128);
    case 'QAM256'; hmod = modem.qammod(256);
    case 'QAM512'; hmod = modem.qammod(512);
    case 'QAM1024';hmod = modem.qammod(1024);
    case 'APSK16'
        r12 = 2.6;
        cst = [exp(j*2*pi*[0.5:1:3.5]/4) exp(j*2*pi*[0.5:1:11.5]/12)*r12];
        hmod = modem.genqammod('Constellation', cst, 'InputType', 'integer');
    case 'APSK32'
        r12 = 2.84; r13 = 5.27;
        cst = [exp(j*2*pi*[0.5:1:3.5]/4) exp(j*2*pi*[0.5:1:11.5]/12)*r12 ...
            exp(j*2*pi*[0:15]/16)*r13];
        hmod = modem.genqammod('Constellation', cst, 'InputType', 'integer');
    otherwise; error('unknown modulation type');
end

% use the same sequence every time so that results are comparable
randStream = RandStream('mt19937ar'); 
reset(randStream);

% adjust number of samples to match AWG limitations
arbConfig = loadArbConfig(arbConfig);
numSamples = lcm(numSymbols * oversampling, arbConfig.segmentGranularity);
while (numSamples < arbConfig.minimumSegmentSize)
    numSamples = 2 * numSamples;
end
numSymbols = round(numSamples / oversampling);

%% create a filter for pulse shaping
if (oversampling <= 1)  % avoid error when creating a filter when there is nothing to filter
    filterType = 'None';
end
filt = [];
filterParams = [];
switch (filterType)
    case 'None'
        filt.Numerator = 1;
    case 'Rectangular'
        filt.Numerator = ones(1, oversampling) / oversampling;
    case 'Square Root Raised Cosine'
        filterParams = 'Nsym,Beta';
    case 'Raised Cosine'
        filterParams = 'Nsym,Beta';
    case 'Gaussian'
        filterParams = 'Nsym,BT';
    otherwise
        error(['unknown filter type: ' filterType]);
end
if (isempty(filt))
    try
        fdes = fdesign.pulseshaping(oversampling, filterType, filterParams, filterNsym, filterBeta);
        filt = design(fdes);
    catch ex
        errordlg({'Error during filter design. Please verify that' ...
            'you have the "Signal Processing Toolbox" installed' ...
            'MATLAB error message:' ex.message}, 'Error');
    end
end

%% calculate the relative magnitudes of each carrier in a multi-carrier case
if (isempty(magnitude))
    magnitude = 0;
end
if (length(magnitude) < length(carrierOffset))
    magnitude = reshape(magnitude, length(magnitude), 1);
    magnitude = repmat(magnitude, ceil(length(carrierOffset) / length(magnitude)), 1);
end

% now generate first carrier
iqdata = iqmod_gen(hmod, numSymbols, oversampling, filt, offsetmod, randStream);

%% calculate carrier offsets
len = length(iqdata);
result = zeros(1,len);
linmag = 10.^(magnitude./20);
for i = 1:length(carrierOffset)
    cy = round(len * carrierOffset(i) / sampleRate);
    shiftSig = exp(j * 2 * pi * cy * (linspace(0, 1 - 1/len, len) + randStream.rand(1)));
    if (newdata)
        iqdata = iqmod_gen(hmod, numSymbols, oversampling, filt, offsetmod, randStream);
    end
    result = result + linmag(i) * (iqdata .* shiftSig);
end
iqdata = result;

%% apply amplitude correction if necessary
if (correction)
    iqdata = iqcorrection(iqdata, sampleRate);
end

%% normalize the output
if (normalize)
    scale = max(max(abs(real(iqdata))), max(abs(imag(iqdata))));
    iqdata = iqdata / scale;
end

delete(randStream);
end


%% generate a modulated signal
function iqdata = iqmod_gen(hmod, numSymbols, oversampling, filt, offsetmod, randStream)
k = length(hmod.Constellation);         % number of constellation points
sym = generate_sym(numSymbols, k, offsetmod, randStream);
rawIQ = upsample(modulate(hmod, sym), oversampling);
len = length(rawIQ);
nfilt = length(filt.Numerator);
% apply the filter to the raw signal with some wrap-around to avoid glitches
wrappedIQ = [rawIQ(end-mod(nfilt,len)+1:end) repmat(rawIQ, 1, floor(nfilt/len)+1)];
%tmp = filter(filt.Numerator, 1, wrappedIQ);
tmp = fftfilt(filt.Numerator, wrappedIQ);
iqdata = tmp(nfilt+1:end);
end

%% generate random data stream
function sym = generate_sym(numSymbols, k, offsetmod, randStream)
if (offsetmod)
    % generate symbols that have a distance of no more than +/- 1
    offset = randStream.randi([-1 1], 1, numSymbols);
    sym = mod(cumsum(offset), k);
    % make sure that the wrap around difference is no more than 1
    while (abs(sym(1) - sym(end)) > 1)
        idx = randStream.randi(numSymbols);
        offset(idx) = ~offset(idx);
        sym = mod(cumsum(offset), k);
    end
else
    % generate random symbols
    sym = randStream.randi([0 k-1], 1, numSymbols);
end
end