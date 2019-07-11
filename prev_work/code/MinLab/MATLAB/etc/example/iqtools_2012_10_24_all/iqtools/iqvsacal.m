function result = iqvsacal(varargin)
% iqvsacal generates a calibration file for pre-distortion by reading the
% channel response from the VSA software
% usage: iqvsacal('param_name', value, 'param_name', value, ...)
% valid parameter names are:
%   symbolRate - symbol rate in Hz
%   modType - modulation type ('BPSK', 'QPSK', 'QAM4', 'QAM16', etc.)
%   filterType - type of pulse shaping filter
%   filterBeta - beta value of pulse shaping filter
%   carrierOffset - center frequency in Hz (0 in case of baseband data)
%   recalibrate - add new corr values to existing file
%
% iqvsacal looks for a variable called hVsaApp in the base MATLAB context.
% If it exists, it is assumed to be a handle to an instance of the VSA
% software. If it does not exist, it opens a new instance

result = -1;
symbolRate = 1e9;
modType = 'QAM16';
filterType = 'Square Root Raised Cosine';
filterBeta = 0.35;
carrierOffset = 2e9;
fc = 2e9;
filterLength = 99;
convergence = 1e-7;
resultLength = 256;
recalibrate = 0;
performAutorange = 0;
measure_Q = 0;          % "special" modulation type to measure the "Q" portion of the signal
interleaving = 0;
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'symbolrate';     symbolRate = varargin{i+1};
            case 'modtype';        modType = varargin{i+1};
            case 'filtertype';     filterType = varargin{i+1};
            case 'filterbeta';     filterBeta = varargin{i+1};
            case 'carrieroffset';  carrierOffset = varargin{i+1};
            case 'fc';             fc = varargin{i+1};
            case 'filterlength';   filterLength = varargin{i+1};
            case 'convergence';    convergence = varargin{i+1};
            case 'resultlength';   resultLength = varargin{i+1};
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
result = vsaCal(symbolRate, modType, filterType, filterBeta, carrierOffset, fc, filterLength, convergence, resultLength, recalibrate, interleaving);
end


function result = vsaCal(symbolRate, modType, filterType, filterBeta, carrierOffset, fc, filterLength, convergence, resultLength, recalibrate, interleaving)
    result = -1;
    if (interleaving)
        symbolRate = 2 * symbolRate;
        carrierOffset = 2 * carrierOffset;
    end
    vsaApp = vsafunc([], 'open');
    if (~isempty(vsaApp))
        hMsgBox = msgbox('Configuring VSA software. Please wait...');
        vsafunc(vsaApp, 'preset');
        vsafunc(vsaApp, 'fromHW');
        vsafunc(vsaApp, 'input', fc);
        vsafunc(vsaApp, 'DigDemod', modType, symbolRate, filterType, filterBeta, resultLength);
        vsafunc(vsaApp, 'freq', abs(fc), symbolRate * 1.6, 102401, Agilent.SA.Vsa.WindowType.FlatTop, 3);
        vsafunc(vsaApp, 'trace', 6, 'DigDemod');
        vsafunc(vsaApp, 'start', 1);
        vsafunc(vsaApp, 'equalizer', true, filterLength, convergence);
        vsafunc(vsaApp, 'autoscale');
        try
            close(hMsgBox);
        catch
        end
        res = questdlg('VSA measurement running. Please press OK when Equalizer has stabilized. (Don''t forget to check input range...)','VSA Calibration','OK','Cancel','OK');
        if (~strcmp(res, 'OK'))
            return;
        end
        result = vsafunc(vsaApp, 'readEqData', recalibrate, abs(fc)-carrierOffset, interleaving);
        if (result == 0)
            iqshowcorr();
        end
        vsafunc(vsaApp, 'equalizer', false, filterLength, convergence);
        vsafunc(vsaApp, 'trace', 4, 'DigDemod');
        vsafunc(vsaApp, 'start', 1);
    end
end


function result = vsaCalOld(symbolRate, modType, filterType, filterBeta, carrierOffset, fc, filterLength, convergence, resultLength, recalibrate)
result = -1;
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
        if (exist('hMsgBox'))
            close(hMsgBox);
        end
        result = -2;
        return;
    end
end

% set inputs
hInputs = get(hMeas, 'Inputs');
hInputs.set('DataFrom', 'vsaInpsDataFromHardware');
if (fc == 0) % --> IQ
    hInputs.set('ChannelConfig', 'vsaInpsChanCnfIQ');
else
    hInputs.set('ChannelConfig', 'vsaInpsChanCnf1');
end
hInputChans = get(hInputs, 'InpChannels');

% set frequency
hFreq = get(hMeas,'Frequency');
hFreq.set('GateWindow', 'vsaFrqWndUniform');
hFreq.set('Points', 102401);
hFreq.set('Center', abs(fc));
hFreq.set('Span', 1.6 * symbolRate);

% set averaging
hAvg = get(hMeas, 'Average');
hAvg.set('Style', 'vsaAvgStyleRmsExp');
hAvg.set('Count', 5);
hAvg.set('Fast', 0);
hAvg.set('Repeat', 0);
    
% turn on Digital Demodulation
hDigDemod = get(hMeas, 'DigDemod');
hMeas.set('DemodConfig', 'vsaMeasDemodCnfDigital');
% Format
if (strcmp(modType, 'BPSK_X'))
    modType = 'BPSK';
    measure_Q = 1;
end
if (strcmp(modType, 'QAM4'))
    modType = 'QPSK';
end
hDigDemod.set('Format', ['vsaDigDemFmt' modType]);
hDigDemod.set('SymbolRate', symbolRate);
hDigDemod.set('ResultLen', resultLength);
hDigDemod.set('GainImbQuadSkewPPSCoupled', 0);
% Filter
if (strcmp(filterType, 'Square Root Raised Cosine'))
    hDigDemod.set('MeasFilter', 'vsaDigDemMeasFiltRootRaisedCosine');
elseif (strcmp(filterType, 'Root Raised Cosine'))
    hDigDemod.set('MeasFilter', 'vsaDigDemMeasFiltRaisedCosine');
else
    % default for everything else
    hDigDemod.set('MeasFilter', 'vsaDigDemMeasFiltRootRaisedCosine');
end
hDigDemod.set('RefFilter', 'vsaDigDemRefFiltRaisedCosine');
hDigDemod.set('FilterAlpha', filterBeta);
% Search
hDigDemod.set('PulseSearch', 0);
hDigDemod.set('SyncSearch', 0);
hFreq.set('Span', 1.6 * symbolRate);

% configure the traces
hTraces = get(hDisp, 'Traces');
hTraces.set('Layout', 'vsaTrcLytGrid2x3');
%hTraces.set('Layout', 'vsaTrcLytQuad4');
hTrace1 = get(hTraces, 'Item', 3);
hTrace2 = get(hTraces, 'Item', 5);
hTrace3 = get(hTraces, 'Item', 6);
hTrace1.set('DataName', 'Ch Frequency Response1');
hTrace2.set('DataName', 'Ch Frequency Response1');
hTrace3.set('DataName', 'Ch Frequency Response1');
hTrace1.set('Format', 'vsaTrcFmtLogMag');
hTrace2.set('Format', 'vsaTrcFmtReal');
hTrace3.set('Format', 'vsaTrcFmtImag');
    
% set for continuous measurement
set(hMeas, 'Continuous', 1);
% run measurement to allow equalizer to adapt
invoke(hMeas, 'Start');

if (performAutorange)
% TBD: implement a routine to find optimal range
end

% Turn Equalizer on
hDigDemod.set('Equalize', 1);
hDigDemod.set('EqAdaptive', 1);
hDigDemod.set('EqFilterLen', filterLength);
hDigDemod.set('EqConvergence', convergence);
hDigDemod.set('Normalize', 1);
if (fc >= 0)
    hDigDemod.set('MirrorFreq', 0);
else
    hDigDemod.set('MirrorFreq', 1);
end
invoke(hDigDemod, 'EqReset');

res = questdlg('VSA measurement running. Please press OK when Equalizer has stabilized. (Don''t forget to check input range...)','VSA Calibration','OK','Cancel','OK');
if (~strcmp(res, 'OK'))
    result = -5;
    return;
end
% set for single measurement
set(hMeas, 'Continuous', 0);
% wait for meas done
invoke(hMeas, 'WaitForMeasDone', 15000);
% pretty up the display
invoke(hTrace1, 'YScaleAuto');
invoke(hTrace2, 'YScaleAuto');
invoke(hTrace3, 'YScaleAuto');
    
% get data
corrData = get(hTrace1, 'Data', 5, 2, 0)';  % 5=double, 2=Y_values
realData = get(hTrace2, 'Data', 5, 2, 0)';  % 5=double, 2=Y_values
imagData = get(hTrace3, 'Data', 5, 2, 0)';  % 5=double, 2=Y_values
% get x axis data (frequencies)
xVal = get(hTrace3, 'Data', 5, 1, 0)';   % 5=double, 1=X_values
% shift the frequency vector back to baseband
xVal = xVal - (abs(fc) - carrierOffset);

% back continuous mode
set(hMeas, 'Continuous', 1);
hDigDemod.set('Equalize', 0);
invoke(hMeas, 'Start');
% back to "pretty" display
hTraces.set('Layout', 'vsaTrcLytQuad4');
hTrace1.set('DataName', 'Error Vector Time1');

% calculate the complex correction vector
corrCplx = 1./complex(realData, imagData);
% and the magnitude in dB (for backward compatibility)
corrLog = 20 * log10(abs(corrCplx));
% if this is a re-calibration or measuring the Q-component, load the
% previous calibration values
if (recalibrate || measure_Q)
    load('ampCorr');
    if (~isequal(ampCorr(:,1), xVal))
        errordlg('Frequency points must be identical for re-calibration. Please perform initial calibration first.');
        result = -9;
        return;
    end
end
% if this is a re-calibration, then add/multiply new cal values with old ones
if (recalibrate)
    ampCorr(:,2) = ampCorr(:,2) + corrLog;
    ampCorr(:,3 + measure_Q) = ampCorr(:,3 + measure_Q) .* corrCplx;
else
    ampCorr(:,1) = xVal;
    ampCorr(:,2) = corrLog;
    ampCorr(:,3 + measure_Q) = corrCplx;
end
% write the cal file
save('ampCorr', 'ampCorr');

% plot frequency response
doPlot = 1;
if (doPlot)
    figure(10);
    set(10, 'Name', 'Correction');
    xlabel('Frequency (Hz)');
    ylabel('dB');
    hold off;
    plot(xVal, corrData, 'b.-');
    hold on;
    plot(xVal, -20*log10(abs(ampCorr(:,3))), 'k.-');
    if (size(ampCorr,2)>=4)
        plot(xVal, -20*log10(abs(ampCorr(:,4))), 'r.-');
        legend('new measurement', 'I-correction', 'Q-correction');
    else
        legend('new measurement', 'new correction');
    end
    hold off;
    grid;
end
% return a success result
result = 0;
end