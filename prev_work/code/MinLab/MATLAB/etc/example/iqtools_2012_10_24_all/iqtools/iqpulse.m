function varargout = iqpulse(varargin)
% Generate I/Q samples for a pulse with given parameters.
% Parameters are passed as property/value pairs. Properties are:
% 'sampleRate' - sampleRate in Hz
% 'PRI' - pulse repetition interval in seconds (can be scalar or vector)
% 'PW' - pulse width in seconds (can be a scalar or vector)
% 'riseTime' - rise time in seconds (can be a scalar or vector)
% 'fallTime' - fall time in seconds (can be a scalar or vector)
% 'delay' - initial delay before the pulse starts (scalar or vector)
% 'phase' - initial phase in degrees
% 'pulseShape' - pulse shape ('Raised Cosine', 'Trapezodial', 'Zero signal during rise time')
% 'amplitude' - relative amplitude in dB (scalar or vector)
% 'span' - frequency span for the chirp (can be scalar or vector)
% 'offset' - frequency offset (can be scalar or vector)
% 'chirpType' - type of chirp ('None','Increasing','Decreasing','V-shape',
%                     'Inverted V','Barker-11','Barker-13','User defined')
% 'fmFormula' - formula for FM of the i-th pulse as a function of vector x
% 'pmFormula' - formula for PM of the i-th pulse as a function of vector x
% 'correction' - correction matrix: row1=frequency, row2=correction in dB
% If 'iqpulse' is called without arguments, opens a graphical user interface
% to specify parameters
%
% Agilent Technologies, Thomas Dippon, 2011

if (nargin == 0)
    iqpulse_gui;
    return;
end
% assign default parameters
sampleRate = 8e9;
pri = 6e-6;
pw = 2e-6;
riseTime = 0;
fallTime = 0;
delay = 0;
phase = 0;
pulseShape = 'Raised Cosine';
amplitude = 0;
span = 1e9;
offset = 0;
chirpType = 'Increasing';
fmFormula = 'cos(pi*(x-1))';
pmFormula = 'zeros(1,length(x))';
correction = [];
arbConfig = [];
for i = 1:2:nargin
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate';   sampleRate = varargin{i+1};
            case 'pri';          pri = varargin{i+1};
            case 'pw';           pw = varargin{i+1};
            case 'risetime';     riseTime = varargin{i+1};
            case 'falltime';     fallTime = varargin{i+1};
            case 'delay';        delay = varargin{i+1};
            case 'phase';        phase = varargin{i+1};
            case 'pulseshape';   pulseShape = varargin{i+1};
            case 'fmformula';    fmFormula = varargin{i+1};
            case 'pmformula';    pmFormula = varargin{i+1};
            case 'amplitude';    amplitude = varargin{i+1};
            case 'span';         span = varargin{i+1};
            case 'offset';       offset = varargin{i+1};
            case 'chirptype';    chirpType = varargin{i+1};
            case 'correction';   correction = varargin{i+1};
            case 'arbconfig';    arbConfig = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    end
end

arbConfig = loadArbConfig(arbConfig);
% number of pulses to generate = length of longest parameter vector
numPulse = max([length(pri) length(delay) length(phase) length(pw) length(riseTime) length(fallTime) length(span) length(offset) length(amplitude)]);
% extend all the other parameter vectors to match the number of pulses
pri = fixlength(pri, numPulse);
pw  = fixlength(pw, numPulse);
riseTime = fixlength(riseTime, numPulse);
fallTime = fixlength(fallTime, numPulse);
delay = fixlength(delay, numPulse);
phase = fixlength(phase, numPulse);
span = fixlength(span, numPulse);
offset = fixlength(offset, numPulse);
amplitude = fixlength(amplitude, numPulse);
% make sure the total number of samples is a multiple of the granularity
% this simplifies the situation in a demo application like this
[pri numSamples] = checkGranularity(pri, delay, pw, riseTime, fallTime, sampleRate, arbConfig);
% now calculate the pulse
envelope = calcPulseShape(numSamples, pri, delay, riseTime, pw, fallTime, sampleRate, pulseShape, amplitude);
[sig mag] = calcPhase(numSamples, pri, delay, riseTime, pw, fallTime, sampleRate, phase, span, offset, chirpType, fmFormula, pmFormula, correction);
iqdata = envelope .* exp(j * sig);
iqdata = power(10,(mag/20)) .* iqdata;
% create a marker with the duration of the first pulse (+ its delay)
mTime = round((delay(1) + riseTime(1) + pw(1) + fallTime(1)) * sampleRate);
marker = 15*[ones(1,mTime) zeros(1,numSamples - mTime)];

% normalize amplitude
scale = max(max(abs(real(iqdata))), max(abs(imag(iqdata))));
if (scale > 1)
    iqdata = iqdata / scale;
end
if (nargout >= 1)
    varargout{1} = iqdata;
end
if (nargout >= 2)
    varargout{2} = marker;
end
end


function [pri numSamples] = checkGranularity(pri, delay, pw, riseTime, fallTime, sampleRate, arbConfig)
% check that the total length matches the required segment granularity.
% if necessary adjust PRI's by stretching them equally
% In a real application, this has to be solved changing the delay of
% subsequent pulses - but this is not possible here
    offTime = pri - delay - pw - riseTime - fallTime;
    if (min(offTime) < 0)
        errordlg('delay + pulse width + risetime + falltime > repeat interval');
    end
    % round pri to full ps to reduce the chance of floating point rounding errors
    spri = round(sum(pri) * 1e12);
    numSamples = ceil(spri * sampleRate / 1e12);
    % round PRI's to match the segment granularity
    % always round UP, to avoid negativ off-times
    modval = mod(numSamples, arbConfig.segmentGranularity);
    if (modval ~= 0)
        corr = arbConfig.segmentGranularity - modval;
        pri = pri .* (corr + numSamples) / numSamples;
        % note the use of round() here to avoid a "jump" to the next integer
        numSamples = round(sum(pri) * sampleRate);
    end
end


function envelope = calcPulseShape(numSamples, pri, delay, riseTime, pw, fallTime, sampleRate, pulseShape, amplitude)
% calculate the pulse envelope
    envelope = zeros(1, numSamples);
    % remember where we are in time at the beginning of the pulse
    priSoFar = 0;
    % create the envelope for each pulse in turn
    for i = 1:length(pri)
        linamp = 10^(amplitude(i)/20);
        % points in time on the pulse
        t(1) = priSoFar + delay(i);
        t(2) = t(1) + riseTime(i);
        t(3) = t(2) + pw(i);
        t(4) = t(3) + fallTime(i);
        ih = ceil(t * sampleRate);
        % index range of rise, pulse and fall times
        ridx = (ih(1):ih(2)-1);
        pidx = (ih(2):ih(3)-1);
        fidx = (ih(3):ih(4)-1);
        % arguments for rise and falltime, scaled to [0...1] interval
        if (t(2) > t(1))    % avoid division by zero
            rr = (ridx ./ sampleRate - t(1)) / (t(2) - t(1));
        else
            rr = [];
        end
        if (t(4) > t(3))
            fr = (fidx ./ sampleRate - t(3)) / (t(4) - t(3));
        else
            fr = [];
        end
        switch lower(pulseShape)
            case 'raised cosine'
                rise_wave = (cos(pi * (rr - 1)) + 1) / 2;
                fall_wave = (cos(pi * (fr)) + 1) / 2;
            case 'trapezodial'
                rise_wave = rr;
                fall_wave = 1 - fr;
            case 'zero signal during rise time'
                rise_wave = zeros(1, length(rr));
                fall_wave = zeros(1, length(fr));
            otherwise
                error(['undefined pulse shape: ' pulseShape]);
        end
        if (~isempty(rr))
            envelope(ridx+1) = linamp .* rise_wave;
        end
        envelope(pidx+1) = linamp;
        if (~isempty(fr))
            envelope(fidx+1) = linamp .* fall_wave;
        end
        priSoFar = priSoFar + pri(i);
    end
end


function [pm mag] = calcPhase(numSamples, pri, delay, riseTime, pw, fallTime, sampleRate, phase, span, offset, chirpType, fmFormula, pmFormula, correction)
% calculate the phase based on span and offset
    fm = zeros(1, numSamples);
    pm = zeros(1, numSamples);
    try
        eval(['fm_fct = @(x,i) ' fmFormula ';']);
        eval(['pm_fct = @(x,i) ' pmFormula ';']);
    catch ex
        errordlg(ex.message);
    end
    priSoFar = 0;
    for i = 1:length(pri)
        % points in time on the pulse
        t(1) = priSoFar + delay(i);
        t(2) = t(1) + riseTime(i) + pw(i) + fallTime(i);
        ih = ceil(t * sampleRate);
        % index for pulse
        pidx = (ih(1):ih(2)-1);
        pr = (pidx ./ sampleRate - t(1)) / (t(2) - t(1));
        fm_on = zeros(1, length(pr));
        pm_on = zeros(1, length(pr));
        switch lower(chirpType)
            case 'none'
                % nothing to do - use the default
            case 'increasing'
                fm_on = 2 * pr - 1;
            case 'decreasing'
                fm_on = 1 - 2 * pr;
            case 'v-shape'
                fm_on = 2*abs(2 * pr - 1) - 1;
            case 'inverted v'
                fm_on = -2*abs(2 * pr - 1) + 1;
            case 'barker-11'
                tmp = [+1 +1 +1 -1 -1 -1 +1 -1 -1 +1 -1]; % from http://en.wikipedia.org/wiki/Barker_code
                tmp = repmat(tmp, ceil(length(pr) / 11), 1);
                pm_on = 90 * tmp(1:length(pr));
            case 'barker-13'
                tmp = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1]; % from http://en.wikipedia.org/wiki/Barker_code
                tmp = repmat(tmp, ceil(length(pr) / 13), 1);
                pm_on = 90 * tmp(1:length(pr));
            case 'user defined'
                x = pr;
                try
                    fm_on = fixlength(fm_fct(x,i),length(pr));
                    pm_on = fixlength(pm_fct(x,i),length(pr));
                catch ex
                    errordlg(ex.message);
                end
            otherwise
                error('undefined chirp type');
        end
        % scale frequency modulation to +/- span/2 and shift by offset
        fmTmp = (span(i)/2 * fm_on) + offset(i);
        % FM should start with 0, so the best I can think of is to insert a
        % zero at tbe beginning and ignore the last sample
        fmTmp = [0 fmTmp(1:end-1)];
        % store frequency for amplitude correction
        fm(pidx+1) = fmTmp;
        % convert FM to PM  (in units of rad/(2*pi))
        pmTmp = cumsum(fmTmp) / sampleRate;
        % initial phase need to reflect the offset of the first sample from
        % the "ideal" pulse starting point
        dT = pidx(1) / sampleRate - t(1);   % delta time
        pOffset = phase(i)/360 - fmTmp(2) * dT;   % corrected phase
        % add FM, PM and initial phase
        pm(pidx+1) = 2 * pi * (pmTmp + pm_on/360 + pOffset);
        priSoFar = priSoFar + pri(i);
    end %for
    % finally, add correction depending on FM
    if (length(correction) > 2)
        mag = interp1(correction(:,1), correction(:,2), fm, 'linear', 0);
    else
        mag = zeros(1,length(fm));
    end
end


function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, length(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);
end
