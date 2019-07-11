function result = iqvsamtone(varargin)
% iqvsamtone generates a calibration file for pre-distortion by 
% measuring the magnitude of the tones in a multi-tone signal
% usage: iqvsacal_mtone('param_name', value, 'param_name', value, ...)
% valid parameter names are:
%   tone - array of frequencies to be measured
%   fc - center frequency in Hz (0 in case of baseband data)
%   recalibrate - add new corr values to existing file
%
% iqvsamtone looks for a variable called hVsaApp in the base MATLAB context.
% If it exists, it is assumed to be a handle to an instance of the VSA
% software. If it does not exist, it opens a new instance

result = [];
tone = [];
fc = 0;
interleaving = 0;
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'tone';           tone = varargin{i+1};
            case 'fc';             fc = varargin{i+1};
            case 'recalibrate';    recalibrate = varargin{i+1};
            case 'interleaving';   interleaving = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
        return;
    end
    i = i+2;
end
% make sure tone vector is the correct shape
if (size(tone,2) > 1)
    tone = tone';
end
result = newVSACal(tone, fc, recalibrate, interleaving);
%result = oldVSACal(tone, fc, recalibrate, interleaving);
end

function result = newVSACal(tone, fc, recalibrate, interleaving)
    result = [];
    origTone = tone;
    if (interleaving)
        tone = 2 * tone;
    end
    ifc = fc;
    if (min(tone) > 0 && fc == 0)
        ifc = 1;
    end
    vsaFc = fc + (max(tone) + min(tone)) / 2;
    vsaSpan = (max(tone) - min(tone)) * 1.01;
    if (vsaSpan < 10e6)
        vsaSpan = 10e6;
    end
    vsaApp = vsafunc([], 'open');
    if (~isempty(vsaApp))
        hMsgBox = msgbox('Configuring VSA software. Please wait...');
        vsafunc(vsaApp, 'preset');
        vsafunc(vsaApp, 'fromHW');
        vsafunc(vsaApp, 'input', ifc);
        vsafunc(vsaApp, 'freq', vsaFc, vsaSpan, 6401, Agilent.SA.Vsa.WindowType.FlatTop, 3);
        vsafunc(vsaApp, 'trace', 1, 'Tones');
        vsafunc(vsaApp, 'start', 1);
        vsafunc(vsaApp, 'autoscale');
        res = questdlg('Please check input range and press OK to start calibration.','VSA Calibration','OK','Cancel','OK');
        if (~strcmp(res, 'OK'))
            return;
        end
        result = vsafunc(vsaApp, 'mtone', origTone, fc, recalibrate, interleaving);
        try
            close(hMsgBox);
        catch
        end
        if (~isempty(result))
            iqshowcorr();
        end
    end
end

function result = oldVSACal(tone, fc, recalibrate, interleaving)
performAutorange = 1;
% connect to VSA software
try
    % use the existing instance of VSA if possible
    hVsaApp = evalin('base', 'hVsaApp');
    hMeas = get(hVsaApp, 'Measurement');
    hDisp = get(hVsaApp, 'Display');
catch e
    try
        %answer = inputdlg('Enter hostname or IP address where VSA software will be launched', 'VSA Calibration', 1, {'localhost'});
        answer = 'localhost';
        if (isempty(answer))
            return;
        end
        hMsgBox = msgbox({'Starting VSA software...', 'Please wait, this can take up to 1 minute'});
        hVsaApp = actxserver('AgtVsaVector.Application', 'machine', answer);
        assignin('base', 'hVsaApp', hVsaApp);

        % make it visible
        set(hVsaApp, 'Visible', -1);

        % get interfaces to major items
        hMeas = get(hVsaApp, 'Measurement');
        hDisp = get(hVsaApp, 'Display');

        %set to defaults
        invoke(hDisp,'Default');
        invoke(hMeas,'Default');
        invoke(hMeas,'Reset');
        % set initial input range
        hInputs = get(hMeas, 'Inputs');
        hInputChans = get(hInputs, 'InpChannels');
        set(get(hInputChans, 'Item', 1), 'Range', 0.25);
        performAutorange = 1;
        close(hMsgBox);
    catch e
        errordlg('Can not create VSA session', 'Error');
        if (exist('hMsgBox', 'var'))
            close(hMsgBox);
        end
        return;
    end
end

% set inputs
hInputs = get(hMeas, 'Inputs');
hInputs.set('DataFrom', 'vsaInpsDataFromHardware');
if (fc == 0 && min(tone) < 0 && max(tone) > 0) % --> IQ
    hInputs.set('ChannelConfig', 'vsaInpsChanCnfIQ');
else
    hInputs.set('ChannelConfig', 'vsaInpsChanCnf1');
end
hInputChans = get(hInputs, 'InpChannels');

% set frequency
hFreq = get(hMeas,'Frequency');
hFreq.set('GateWindow', 'vsaFrqWndUniform');
hFreq.set('Points', 51201);

% set averaging
hAvg = get(hMeas, 'Average');
hAvg.set('Style', 'vsaAvgStyleRmsExp');
hAvg.set('Count', 3);
hAvg.set('Fast', 0);
hAvg.set('Repeat', 0);
    
% turn off Digital Demodulation
hDigDemod = get(hMeas, 'DigDemod');
hMeas.set('DemodConfig', 'vsaMeasDemodCnfNone');

% configure the traces
hTraces = get(hDisp, 'Traces');
hTraces.set('Layout', 'vsaTrcLytSingle');
hTrace1 = get(hTraces, 'Item', 1);
hTrace1.set('DataName', 'Spectrum1');
hTrace1.set('Format', 'vsaTrcFmtLogMag');
hTrace1.set('Active', 1);
hMarker = get(hTrace1, 'Marker');
hMarker.set('Visible', 1);

% if a list of frequencies is specified, use them as a starting point for a
% new correction. Otherwise use existing correction is used as a starting
% point. The measurement is added to the existing correction in this case.
if (recalibrate || isempty(tone))
    load('ampCorr.mat');
    tone = ampCorr(:,1);
    oldCorr = ampCorr(:,2);
else
    oldCorr = zeros(length(tone),1);
end

span = min(diff(tone)) / 2;  % assumes >= 2 tones in ascending order
tmin = tone(1) + fc;
tmax = tone(end) + fc;
hFreq.invoke('SetStartStop', true, tmin, tmax);
set(hMeas, 'Continuous', 1);
invoke(hMeas, 'Start');

try
if (performAutorange)
    range = get(get(hInputChans, 'Item', 1), 'Range');
    invoke(hMeas, 'WaitForMeasDone', 5000);
    overflow = bitand(uint32(hTrace1.get('RawDataStatus')), 4);
    while (~overflow && range >= 0.1)
        range = range / sqrt(2);
        set(get(hInputChans, 'Item', 1), 'Range', range);
        invoke(hMeas, 'WaitForMeasDone', 25000);
        overflow = bitand(uint32(hTrace1.get('RawDataStatus')), 4);
    end
    while (overflow && range < 5)
        range = range * sqrt(2);
        set(get(hInputChans, 'Item', 1), 'Range', range);
        invoke(hMeas, 'WaitForMeasDone', 25000);
        overflow = bitand(uint32(hTrace1.get('RawDataStatus')), 4);
    end
end
catch e
end

res = questdlg('Please check input range and press OK to start calibration.','VSA Calibration','OK','Cancel','OK');
if (~strcmp(res, 'OK'))
    return;
end
mag = zeros(length(tone),1);
measureAllAtOnce = 1;
if (measureAllAtOnce)
    for i = 1:length(tone)
        hMarker.set('Value', tone(i) + fc);
        mag(i) = hMarker.get('Y');
    end
else
    set(hMeas, 'Continuous', 0);
    for i = 1:length(tone)
        hFreq.set('Center', tone(i) + fc);
        hFreq.set('Span', span);
        hFreq.set('ResBW', span/300);
        % run a single measurement
        invoke(hMeas, 'Start');
        % wait for meas done
        invoke(hMeas, 'WaitForMeasDone', 5000);
        hMarker.invoke('MoveTo', 'vsaMkrMovePeak');
        mag(i) = hMarker.get('Y');
    end
    % set for continuous measurement
    set(hMeas, 'Continuous', 1);
    invoke(hMeas, 'Start');
    % set span to see all tones
    tmin = tone(1) + fc;
    tmax = tone(end) + fc;
    hFreq.invoke('SetStartStop', true, tmin, tmax);
    hFreq.set('ResBW', (tmax - tmin)/300);
end
hMarker.set('Visible', 0);

% some sanity check
if (length(mag) ~= length(tone) || min(mag) < -80 || max(mag) > 30)
    errordlg('unexpected measurement result');
    return;
end
% calculate deviation from average
meas = mag - sum(mag)/length(mag);
% subtract from previous correction
newCorr = oldCorr - meas;
ampCorr = [tone newCorr];
% ...and save it to ampCorr.mat
save('ampCorr', 'ampCorr');

%% plot results
doPlot = 1;
if (doPlot)
    iqshowcorr();
    figure(10);
    hold on;
    plot(tone, meas, 'r.-');
    plot(tone, -1 * oldCorr, 'b.-');
    legend('new correction', 'measurement', 'old correction');
end
result = mag;
end
