function result = iqcal(varargin)
% Generate amplitude correction vector from a multi-tone signal.
% Arguments are given as attrtibute/value pairs. Possible arguments:
%  - offset: frequency offset in Hz that is added to all tones before
%         taking a measurement (use offset when tones are upconverted)
%         if offset is negative, tone frequencies are subtracted
%  - tone: vector of tones at which measurement is performed.
%  - update: if set to 0, will not write the ampCorr file. (default = 1)
%  - plot: if set to 0, will not plot the result (default = 1)
%  - recalibrate: If set to 1, the list of frequencies is taken from
%          the existing amplitude correction file ('ampCorr.mat'). The
%          measurement is added to the existing correction in this case.

%% parse optional arguments
result = [];
tone = [];
offset = 0;
update = 1;
doPlot = 1;
recalibrate = 0;
interleaving = 0;
hMsgBox = [];
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'offset'; offset = varargin{i+1};
            case 'tone'; tone = varargin{i+1};
            case 'update'; update = varargin{i+1};
            case 'plot'; doPlot = varargin{i+1};
            case 'recalibrate'; recalibrate = varargin{i+1};
            case 'interleaving'; interleaving = varargin{i+1};
            case 'msgbox'; hMsgBox = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

% make sure tone vector is the correct shape (one column)
if (size(tone,2) > 1)
    tone = tone';
end
% if a list of frequencies is specified, use them as a starting point for a
% new correction. Otherwise use existing correction is used as a starting
% point. The measurement is added to the existing correction in this case.
if (recalibrate || isempty(tone))
    load('ampCorr.mat');
    if (~isequal(ampCorr(:,1), tone))
        errordlg('Frequency points must be identical for re-calibration. Please perform initial calibration first.');
        return;
    end
    oldCorr = ampCorr(:,2);
else
    oldCorr = zeros(length(tone),1);
end
% in interleaving mode, frequencies are doubled
origTone = tone;
if (interleaving)
    tone = 2 * tone;
end
%% establish a connection to spectrum analyzer
[arbConfig saConfig] = loadArbConfig();
if (~saConfig.connected)
    errordlg('Please use "Configure Instruments" to configure a spectrum analyzer connection');
    return;
end
f = iqopen(saConfig);
if (isempty(f))
    return;
end

%% call the appropriate routine for the type of spectrum analyzer
if (isfield(saConfig, 'useListSweep') && saConfig.useListSweep ~= 0)
    list = comp_ListSweep(f, abs(tone + offset));
elseif (isfield(saConfig, 'useMarker') && saConfig.useMarker ~= 0)
    list = comp_Marker(f, abs(tone + offset), hMsgBox);
else
    list = comp_ZeroSpan(f, abs(tone + offset), hMsgBox);
end
fclose(f);

%% calculate the new correction factors
% some sanity check
if (length(list) ~= length(tone) || min(list) < -80 || max(list) > 30)
    errordlg('Measurement aborted or unexpected spectrum analyzer result. Please check Fc parameter.');
    return;
end
% calculate deviation from average
meas = list - sum(list)/length(list);
% subtract from previous correction
newCorr = oldCorr - meas;
% use the orginal tone vector in the file
tone = origTone;
ampCorr = [tone newCorr];
% ...and save it to ampCorr.mat
if (update)
    save('ampCorr', 'ampCorr');
end

%% plot results
if (doPlot)
    figure(10);
    set(10,'Name','Flatness Correction');
    hold off;  plot(tone, meas, 'r.-');
    hold on; plot(tone, -1 * oldCorr, 'b.-');
    plot(tone, -1 * newCorr, 'k.-'); hold off;
    legend('measurement', 'old correction', 'new correction');
    xlabel('frequency (Hz)');
    ylabel('dB');
end
result = list;
end



function list = comp_ListSweep(f, tone)
% determine power for a list of tones in MXA - using LIST SWEEP
    xfprintf(f, ':INST:SEL SA');
    old_freq = query(f, ':FREQ:CENT?');
    old_span = query(f, ':FREQ:SPAN?');
    old_bw   = query(f, ':BWID?');
    old_vbw  = query(f, ':BWID:VID?');
    old_ref  = query(f, ':DISP:WIND:TRAC:Y:RLEV?');
    old_pdiv = query(f, ':DISP:WIND:TRAC:Y:PDIV?');
    xfprintf(f, ':INIT:CONT OFF');
    xfprintf(f, ':CONF:LIST');
    cmd = sprintf(':LIST:FREQ %g', tone(1));
    for i = 2:length(tone)
        cmd = sprintf('%s,%g', cmd, tone(i));
    end
    xfprintf(f, cmd);
    xfprintf(f, ':LIST:BAND:RES:TYPE FLAT');
    xfprintf(f, ':LIST:BAND:RES 100 kHz');
    xfprintf(f, ':LIST:BAND:VID 100 kHz');
    xfprintf(f, ':LIST:SWE:TIME 40e-3');
    xfprintf(f, ':LIST:TRIG:DEL 0');
    xfprintf(f, ':LIST:DET RMS');
    xfprintf(f, ':LIST:TRIG:SOUR IMM');
    xfprintf(f, ':INIT:LIST');
    res = query(f, ':FETCH:LIST?');
 %   disp(res);
    xfprintf(f, ':INIT:SAN');
    xfprintf(f, ':INIT:CONT ON');
    % extract numeric values
    res = strrep(res, ',', ' ');
    list = sscanf(res, '%g');
    % back to continuous sweep mode
    xfprintf(f, sprintf(':FREQ:CENT %s', old_freq));
    xfprintf(f, sprintf(':FREQ:SPAN %s', old_span));
    xfprintf(f, sprintf(':BWID %s', old_bw));
    xfprintf(f, sprintf(':BWID:VID %s', old_vbw));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:RLEV %s', old_ref));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:PDIV %s', old_pdiv));
    xfprintf(f, ':INIT:CONT ON');
end


function list = comp_ZeroSpan(f, tone, hMsgBox)
% determine power for a list of tones using zero span measurement
    bw = abs(min(diff(tone)) / 2);
    span = 0;
    bw = min(bw, 500e3);
    xfprintf(f, ':INST SA');
    old_freq = query(f, ':FREQ:CENT?');
    old_span = query(f, ':FREQ:SPAN?');
    old_bw   = query(f, ':BWID?');
    old_vbw  = query(f, ':BWID:VID?');
    old_ref  = query(f, ':DISP:WIND:TRAC:Y:RLEV?');
    old_pdiv = query(f, ':DISP:WIND:TRAC:Y:PDIV?');
    xfprintf(f, '*RST');
    xfprintf(f, ':INIT:CONT OFF');
    xfprintf(f, sprintf(':FREQ:SPAN %.15g', span));
    if (span == 0)
        xfprintf(f, sprintf(':BWID %g', bw));
    else
        xfprintf(f, ':BWID:AUTO ON');
    end
    xfprintf(f, ':BWID:VID:AUTO ON');
    xfprintf(f, ':DISP:WIND:TRAC:Y:RLEV -10 dBm');
    xfprintf(f, ':DISP:WIND:TRAC:Y:PDIV 10 dB');
    xfprintf(f, ':CALC:MARK1:STAT ON');
    xfprintf(f, ':CALC:MARK1:MODE POS');
    for i = 1:length(tone)
        % update the progress bar and break the loop if user has pressed
        % the cancel button
        if (~isempty(hMsgBox))
            try
                ch = get(hMsgBox, 'Children');
                set(get(ch(1), 'Children'), 'String', sprintf('Performing Calibration (%d %%)', round(i/length(tone)*100)));
                pause(0.001);
            catch ex
                break;
            end
        end
        fprintf(f, sprintf(':FREQ:CENT %.15g', tone(i)));
        fprintf(f, ':INIT:IMM');
        while (query(f, '*OPC?') == 0)
            pause(0.05); % don't hit it too often
        end
        m1 = getPeak(f);
        mmeas(i) = m1;
        if (mmeas < -80)
            break;
        end
    end
    % back to continuous sweep mode
    xfprintf(f, sprintf(':FREQ:CENT %s', old_freq));
    xfprintf(f, sprintf(':FREQ:SPAN %s', old_span));
    xfprintf(f, sprintf(':BWID %s', old_bw));
    xfprintf(f, sprintf(':BWID:VID %s', old_vbw));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:RLEV %s', old_ref));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:PDIV %s', old_pdiv));
    xfprintf(f, ':INIT:CONT ON');
    list = mmeas';
end

function mag = getPeak(f)
% turn marker on in normal mode, perform peak search and return frequency
% and power at the marker location
    fprintf(f, ':CALC:MARK1:STAT ON');
    fprintf(f, ':CALC:MARK1:MODE POS');
    %fprintf(f, ':CALC:MARK1:MAX');
    %freq_s = query(f, 'CALC:MARK1:X?');
    mag_s = query(f, 'CALC:MARK1:Y?');
    %freq = sscanf(freq_s, '%g');
    mag = sscanf(mag_s, '%g');
%    fprintf(f, ':CALC:MARK1:STAT OFF');
end


function list = comp_Marker(f, tone, hMsgBox)
% measure power for a list of tones using a marker.
% This routine assumes that the user has set up the
% spectrum analyzer to show the list of tones.
    list = zeros(length(tone), 1);
    span = max(tone) - min(tone);
    center = (max(tone) + min(tone))/2;
    xfprintf(f, ':INST SA');
    old_freq = query(f, ':FREQ:CENT?');
    old_span = query(f, ':FREQ:SPAN?');
    old_bw   = query(f, ':BWID?');
    old_vbw  = query(f, ':BWID:VID?');
    old_ref  = query(f, ':DISP:WIND:TRAC:Y:RLEV?');
    old_pdiv = query(f, ':DISP:WIND:TRAC:Y:PDIV?');
% uncomment this to set the spectrum analyzer center & span
%    xfprintf(f, sprintf(':FREQ:CENT %.15g', center));
%    xfprintf(f, sprintf(':FREQ:SPAN %.15g', span));
    % set the number of points large enough to capture all frequencies
    xfprintf(f, ':SWE:POIN 40001');
    xfprintf(f, ':INIT:CONT OFF');
    xfprintf(f, ':INIT:IMM');
    while (query(f, '*OPC?') == 0)
        pause(0.05); % don't hit it too often
    end
    xfprintf(f, ':CALC:MARK1:STAT ON');
    xfprintf(f, ':CALC:MARK1:MODE POS');
    for i = 1:length(tone);
        % update the progress bar and break the loop if user has pressed
        % the cancel button
        if (~isempty(hMsgBox))
            try
                ch = get(hMsgBox, 'Children');
                set(get(ch(1), 'Children'), 'String', sprintf('Performing Calibration (%d %%)', round(i/length(tone)*100)));
                pause(0.001);
            catch ex
                list = [];
                break;
            end
        end
        xfprintf(f, sprintf('CALC:MARK1:X %.15g', tone(i)));
        pause(0.02);
        mag_s = query(f, 'CALC:MARK1:Y?');
        list(i) = sscanf(mag_s, '%g');
        if (list(i) < -80)
            break;
        end
    end
    fprintf(f, ':CALC:MARK1:STAT OFF');
    % back to continuous sweep mode
    xfprintf(f, sprintf(':FREQ:CENT %s', old_freq));
    xfprintf(f, sprintf(':FREQ:SPAN %s', old_span));
    xfprintf(f, sprintf(':BWID %s', old_bw));
    xfprintf(f, sprintf(':BWID:VID %s', old_vbw));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:RLEV %s', old_ref));
    xfprintf(f, sprintf(':DISP:WIND:TRAC:Y:PDIV %s', old_pdiv));
    xfprintf(f, ':INIT:CONT ON');
end

function xfprintf(f, s)
% Send the string s to the instrument object f
% and check the error status

% un-comment the following line to see a trace of commands
%    fprintf('cmd = %s\n', s);
    fprintf(f, s);
    res = query(f, ':syst:err?');
    if (length(res) == 0)
        fclose(f);
        error(':syst:err query failed');
    end
    if (~strcmp(res, ['+0,"No error"' 10]))
        fprintf('cmd = %s / result = %s', s, res);
    end
end

