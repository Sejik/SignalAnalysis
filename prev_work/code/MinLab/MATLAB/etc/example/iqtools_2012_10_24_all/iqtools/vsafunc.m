function result = vsafunc(vsaApp, fct, varargin)
result = [];
switch fct
    % attach to VSA session. If VSA is not running, start a new session
    % no additional arguments
    case 'open'
        mypath = [fileparts(which('vsafunc')) '\Interfaces\'];
        pathlist = { ...
%            'C:\Program Files (x86)\Agilent\89600B VSA 14.0\89601B VSA\Interfaces_v3.5\' ...
%            'C:\Program Files (x86)\Agilent\89600B VSA 14.2\89601B VSA\Interfaces_v3.5\' ...
%            'C:\Program Files (x86)\Agilent\89600B VSA 15.0\89601B VSA\Interfaces_v3.5\' ...
            mypath };
        asm1Name = 'Agilent.SA.Vsa.Interfaces.dll';
        asm2Name = 'Agilent.SA.Vsa.DigitalDemod.Interfaces.dll';
        asm3Name = 'Agilent.SA.Vsa.CustomOfdm.Interfaces.dll';
        found = 0;
        for i = 1:length(pathlist)
            try
                NET.addAssembly(strcat(pathlist{i}, asm1Name));
                NET.addAssembly(strcat(pathlist{i}, asm2Name));
                NET.addAssembly(strcat(pathlist{i}, asm3Name));
                found = 1;
                break;  % if execution is at this point, we found the DLLs
            catch e
            end
        end
        if (~found)
            errordlg('Can''t find VSA Interface DLLs');
            return;
        end
        import Agilent.SA.Vsa.*;
        % Attach to a running instance of VSA. If there no running instance, 
        % create one.
        vsaApp = ApplicationFactory.Create();
        if (isempty(vsaApp))
            hMsgBox = msgbox({'Starting VSA software...', 'Please wait, this can take up to 1 minute'});
            vsaApp = ApplicationFactory.Create(true, '', '', -1);
            close(hMsgBox);
        end
        if (isempty(vsaApp))
            errordlg('Can''t open VSA Software');
            return;
        end
        % Make VSA visible
        vsaApp.IsVisible = true;
        result = vsaApp;
        assignin('base', 'vsaApp', vsaApp);
%-------------------------------------------------------------------------        
    case 'preset'
        % set VSA default settings
        % no additional arguments
        vsaMeas = vsaApp.Measurements.SelectedItem;
        vsaDisp = vsaApp.Display;
        % Preset to defaults
        vsaDisp.Preset;
        vsaMeas.Preset;
        vsaMeas.Reset;
        try
            vsaMeas.WaitForMeasurementDone(5000);
            vsaMeas.Input.Analog.AutoRange;
            vsaMeas.WaitForMeasurementDone(5000);
        catch
        end
        vsaMeas.Pause();
%-------------------------------------------------------------------------        
    case 'autorange'
        % if an argument is given, then set the range to this value
        % otherwise: autorange
        vsaMeas = vsaApp.Measurements.SelectedItem;
        try
            if (length(varargin) >= 1)
                vsaAnalog = vsaMeas.Input.Analog;
                vsaAnalog.Range = varargin{1};
            else
                vsaMeas.WaitForMeasurementDone(5000);
                vsaMeas.Input.Analog.AutoRange;
                vsaMeas.WaitForMeasurementDone(5000);
            end
        catch
        end
%-------------------------------------------------------------------------        
    case 'load'
        % load a vector
        % argument 1: data vector
        % argument 2: sampleRate
        Y = reshape(varargin{1}, numel(varargin{1}), 1);
        % create a certain minimum number of samples so that VSA does not
        % complain about a record length being too short
        minLength = 1000000;
        if (length(Y) < minLength)
            Y = repmat(Y, ceil(minLength/length(Y)), 1);
        end
        % add a tiny bit of noise to make the VSA display look realistic ;-)
        Y = awgn(Y,300);
        XStart = 0;
        XDelta = 1/varargin{2};
        InputZoom = 1;
        file = [pwd '\vsatemp.mat'];
        save(file, 'Y', 'XStart', 'XDelta', 'InputZoom');
        vsaMeas = vsaApp.Measurements.SelectedItem;
        vsaMeas.Input.Recording.RecallFile(file, 'MAT');
        vsaInput = vsaMeas.Input;
        vsaInput.DataFrom = DataSource.Recording;
%        vsafunc(vsaApp, 'input', 1);    % set VSA to baseband
%-------------------------------------------------------------------------        
    case 'fromHW'
        vsaMeas = vsaApp.Measurements.SelectedItem;
        vsaInput = vsaMeas.Input;
        vsaInput.DataFrom = DataSource.Hardware;
%-------------------------------------------------------------------------        
    case 'input'
        % argument 1: center frequency
        vsaMeas = vsaApp.Measurements.SelectedItem;
        vsaInput = vsaMeas.Input;
        logicalChTypes = NET.createArray('Agilent.SA.Vsa.LogicalChannelType', 1);
        if (varargin{1} == 0)
            logicalChTypes(1) = Agilent.SA.Vsa.LogicalChannelType.IQ;
        else
            logicalChTypes(1) = Agilent.SA.Vsa.LogicalChannelType.Baseband;
        end
        try
            vsaInput.ChangeLogicalChannels(logicalChTypes);
        catch ex
            errordlg('Can not set the input channels. Please connect VSA to the appropriate analyzer hardware, then try again.','Error')  
        end
%-------------------------------------------------------------------------        
    case 'start'
        % start measurement
        % argument 1: continuous(1) or single(0) (optional)
        vsaMeas = vsaApp.Measurements.SelectedItem;
        if (length(varargin) >= 1)
            vsaMeas.IsContinuous = (varargin{1} ~= 0);
        end
        vsaMeas.Restart();
        try
            vsaMeas.WaitForMeasurementDone(5000);
        catch
        end
%-------------------------------------------------------------------------        
    case 'freq'
        % set center and span
        % argument 1: center frequency
        % argument 2: span (optional)
        % argument 3: points (optional)
        % argument 4: windowType (optional)
        % argument 5: average (optional)
        vsaMeas = vsaApp.Measurements.SelectedItem;
        vsaFreq = vsaMeas.Frequency;
        vsaFreq.Center = varargin{1};
        if (length(varargin) >= 2)
            vsaFreq.Span = varargin{2};
        end
        if (length(varargin) >= 3)
            vsaFreq.Points = varargin{3};
        end
        if (length(varargin) >= 4)
            vsaFreq.Window = varargin{4};
        end
        if (length(varargin) >= 5)
            average = vsaMeas.Average;
            if (varargin{5} > 0)
                average.Style = Agilent.SA.Vsa.AverageStyle.RmsExponential;
                average.Count = varargin{5};
                average.IsFast = false;
                average.IsRepeat = false;
            else
                average.Style = Agilent.SA.Vsa.AverageStyle.Off;
            end
        end
        if (length(varargin) >= 6)
            vsaTime = vsaMeas.Time;
            vsaTime.Length = varargin{6};
        end
%-------------------------------------------------------------------------        
    case 'trace'
        % set layout and trace contents
        % argument 1: trace layout (2=2, 4=2x2, 6=2x3)
        % argument 2: 'DigDemod' or 'Chirp' (optional)
        vsaDisp = vsaApp.Display;
        vsaTraces = vsaDisp.Traces;
        switch varargin{1}
            case 1; 
                vsaTraces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.HorizontalOrientation,1,1);
            case 2;
                vsaTraces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.HorizontalOrientation,1,2);
            case 4;
                vsaTraces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.FillAll,2,2);
                vsaTraces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.HorizontalOrientation,2,2);
            case 6;
                vsaTraces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.FillAll,2,3);
                vsaTraces.ArrangeWindows(Agilent.SA.Vsa.ArrangeWindowHints.HorizontalOrientation,2,3);
        end
        for i = varargin{1}:(vsaTraces.Count - 1)
            tr = vsaTraces.Item(i);
            tr.IsVisible = false;
        end
        if (length(varargin) >= 2)
            switch varargin{2}
                case 'Tones'
                    tr = vsaTraces.Item(0); tr.DataName = 'Spectrum1';
                case 'DigDemod'
                    tr = vsaTraces.Item(0); tr.DataName = 'IQ Meas Time1';
                    tr = vsaTraces.Item(1); tr.DataName = 'Spectrum1';
                      tr.Format = Agilent.SA.Vsa.TraceFormatType.LogMagnitude;
                    tr = vsaTraces.Item(2); tr.DataName = 'Error Vector Time1'; 
                    tr = vsaTraces.Item(3); tr.DataName = 'Syms/Errs1';
                    if (varargin{1} == 6)
                        tr = vsaTraces.Item(4); tr.DataName = 'Ch Frequency Response1';
                          tr.Format = Agilent.SA.Vsa.TraceFormatType.Real;
                        tr = vsaTraces.Item(5); tr.DataName = 'Ch Frequency Response1';
                          tr.Format = Agilent.SA.Vsa.TraceFormatType.Imaginary;
                    end
                case 'CustomOFDM'
                     tr = vsaTraces.Item(0); tr.DataName = 'IQ Meas1';
                     tr = vsaTraces.Item(1); tr.DataName = 'Spectrum1';
                      tr.Format = Agilent.SA.Vsa.TraceFormatType.LogMagnitude;
                    tr = vsaTraces.Item(2); tr.DataName ='RMS Error Vector Spectrum1'; 
                    tr = vsaTraces.Item(3); tr.DataName = 'OFDM Error Summary1';
                    if (varargin{1} == 6)
                        tr = vsaTraces.Item(4); tr.DataName = 'Ch Frequency Response1';
                          tr.Format = Agilent.SA.Vsa.TraceFormatType.Real;
                        tr = vsaTraces.Item(5); tr.DataName = 'Ch Frequency Response1';
                          tr.Format = Agilent.SA.Vsa.TraceFormatType.Imaginary;
                    end
                case 'Chirp'
                    tr = vsaTraces.Item(0);
                    tr.DataName = 'Spectrum1';
                    tr.Format = Agilent.SA.Vsa.TraceFormatType.LogMagnitude;
                    tr = vsaTraces.Item(1);
                    tr.DataName = 'Main Time1';
                    tr.Format = Agilent.SA.Vsa.TraceFormatType.LogMagnitude;
                    tr = vsaTraces.Item(2);
                    tr.DataName = 'Main Time1';
                    tr.Format = Agilent.SA.Vsa.TraceFormatType.UnwrapPhase;
                    tr = vsaTraces.Item(3);
                    tr.DataName = 'Main Time1';
                    tr.Format = Agilent.SA.Vsa.TraceFormatType.GroupDelay;
            end
        end
%-------------------------------------------------------------------------        
    case 'autoscale'
        % autoscale the selected traces
        vsaDisp = vsaApp.Display;
        vsaTraces = vsaDisp.Traces;
        if (length(varargin) < 1)
            items = 1:vsaTraces.Count;
        else
            for i=1:length(varargin)
                items(i) = varargin{i};
            end
        end
        for i=1:length(items)
            tr = vsaTraces.Item(items(i)-1);
            tr.YScaleAuto();
        end
%-------------------------------------------------------------------------        
    case 'DigDemod'
        % set Digital Demod parameters
        % argument 1: modulation type
        % argument 2: symbol rate
        % argument 3: filter type (optional)
        % argument 4: filter beta (optional)
        % argument 5: result length (optional)

        vsaDemod = getDigDemod(vsaApp);
        %Set the VSA measurement parameters
        switch varargin{1}
            case 'BPSK';   format = Agilent.SA.Vsa.DigitalDemod.Format.Bpsk;
            case 'BPSK_X'; format = Agilent.SA.Vsa.DigitalDemod.Format.Bpsk;
            case 'QPSK';   format = Agilent.SA.Vsa.DigitalDemod.Format.Qpsk;
            case 'OQPSK';  format = Agilent.SA.Vsa.DigitalDemod.Format.OffsetQpsk;
            case 'QAM4';   format = Agilent.SA.Vsa.DigitalDemod.Format.Qpsk;
            case 'QAM16';  format = Agilent.SA.Vsa.DigitalDemod.Format.Qam16;
            case 'QAM32';  format = Agilent.SA.Vsa.DigitalDemod.Format.Qam32;
            case 'QAM64';  format = Agilent.SA.Vsa.DigitalDemod.Format.Qam64;
            case 'QAM128'; format = Agilent.SA.Vsa.DigitalDemod.Format.Qam128;
            case 'QAM256'; format = Agilent.SA.Vsa.DigitalDemod.Format.Qam256;
            case 'QAM512'; format = Agilent.SA.Vsa.DigitalDemod.Format.Qam512;
            case 'QAM1024'; format = Agilent.SA.Vsa.DigitalDemod.Format.Qam1024;
            case 'APSK16'; format = Agilent.SA.Vsa.DigitalDemod.Format.Apsk16;
                vsaDemod.ApskRing2Ratio = 2.6;
            case 'APSK32'; format = Agilent.SA.Vsa.DigitalDemod.Format.Apsk32;
                vsaDemod.ApskRing2Ratio = 2.84;
                vsaDemod.ApskRing3Ratio = 5.27;
            otherwise; errordlg(['unknown format: ' varargin{1}]);
        end
        vsaDemod.Format = format;
        vsaDemod.SymbolRate = varargin{2};
        vsaDemod.IsFrequencyMirrored = false;
        vsaDemod.IsPulseSearchEnabled = false;
        if (length(varargin) >= 3)
            switch varargin{3}
                case 'Square Root Raised Cosine'; filter = Agilent.SA.Vsa.DigitalDemod.MeasurementFilter.RootRaisedCosine;
                case 'Raised Cosine'; filter = Agilent.SA.Vsa.DigitalDemod.MeasurementFilter.RaisedCosine;
                case 'Gaussian'; filter = Agilent.SA.Vsa.DigitalDemod.MeasurementFilter.Gaussian;
                case 'Rectangular'; filter = Agilent.SA.Vsa.DigitalDemod.MeasurementFilter.Rectangular;
            end
            vsaDemod.MeasurementFilter = filter;
        end
        if (length(varargin) >= 4)
            vsaDemod.FilterAlphaBT = varargin{4};
        end
        if (length(varargin) >= 5)
            vsaDemod.ResultLength = varargin{5};
        end
%-------------------------------------------------------------------------        
    case 'trigger'
        % set Trigger
        % argument 1: trigger mode ('FreeRun' or 'Channel')
        % argument 2: Level
        % argument 3: Delay
        % argument 4: Holdoff
        vsaMeas = vsaApp.Measurements.SelectedItem;
        vsaInput = vsaMeas.Input;
        vsaTrigger = vsaInput.Recording.Trigger;
        switch varargin{1}
            case 'FreeRun'
                vsaTrigger.Style = Agilent.SA.Vsa.TriggerStyle.Auto;
            case 'Channel'
                vsaTrigger.Style = Agilent.SA.Vsa.TriggerStyle.Level;
        end
        vsaTrigger.Level = varargin{2};
        vsaTrigger.Delay = varargin{3};
        vsaTrigger.Holdoff = varargin{4};
        vsaTrigger = vsaInput.Trigger;
        switch varargin{1}
            case 'FreeRun'
                vsaTrigger.Style = Agilent.SA.Vsa.TriggerStyle.Auto;
            case 'Channel'
                vsaTrigger.Style = Agilent.SA.Vsa.TriggerStyle.Level;
        end
        vsaTrigger.Level = varargin{2};
        vsaTrigger.Delay = varargin{3};
        vsaTrigger.Holdoff = varargin{4};
%-------------------------------------------------------------------------        
    case 'equalizer'
        % set up equalizer
        % argument 1: on/off (1/0)
        % argument 2: filterLength (optional)
        % argument 3: convergence (optional)
        vsaDemod = getDigDemod(vsaApp);
        vsaDemod.IsEqualized = varargin{1};
        if (length(varargin) >= 2)
            vsaDemod.EqualizerFilterLength = varargin{2};
        end
        if (length(varargin) >= 3)
            vsaDemod.EqualizerConvergence = varargin{3};
        end
%-------------------------------------------------------------------------        
    case 'readEqData'
        % get equalizer data and write ampCorr file
        % argument 1: add new measurement to existing correction (re-calibration) (Optional)
        % argument 2: carrierOffset to be subtracted from measurements (Optional)
        % argument 3: interleaving
        result = -1;
        interleaving = 0;
        if (length(varargin) >= 3)
            interleaving = varargin{3};
        end
        vsaDisp = vsaApp.Display;
        vsaTraces = vsaDisp.Traces;
        tr = vsaTraces.Item(4);
        x = (tr.DoubleData(TraceDataSelect.X, false).double)';
        if (length(varargin) >= 2)
            x = x - varargin{2};
        end
        yreal = (tr.DoubleData(TraceDataSelect.Y, false).double)';
        tr = vsaTraces.Item(5);
        yimag = (tr.DoubleData(TraceDataSelect.Y, false).double)';
        y = 1 ./ complex(yreal, yimag);
        ydB = 20 * log10(abs(y));
        if (interleaving)
            x = x / 2;
        end
        ampCorr = [x zeros(length(x),1) ones(length(x),1)];
        if (length(varargin) >= 1 && varargin{1} ~= 0)
            try
                load('ampCorr');
                if (~isequal(ampCorr(:,1), x))
%                    errordlg('Frequency points must be identical for re-calibration. Please perform initial calibration first.');
%                    return;
                    % if the list of frequencies does not match,
                    % interpolate the existing correction values
                    newCol2 = interp1(ampCorr(:,1), ampCorr(:,2), x, 'cubic', 0);
                    if (size(ampCorr,2) >= 3)
                        newCol3 = interp1(ampCorr(:,1), ampCorr(:,3), x, 'cubic', 1);
                    else
                        newCol3 = ones(length(x),1);
                    end
                    ampCorr = [x newCol2 newCol3];
                end
            catch
            end
        end
        ampCorr = [x (ampCorr(:,2)+ydB) (ampCorr(:,3).*y)];
        save('ampCorr', 'ampCorr');
        result = 0;
%-------------------------------------------------------------------------        
    case 'mtone'
        % measure magnitude of tones
        % argument 1: vector of tones
        % argument 2: fc
        % argument 3: recalibrate
        % argument 4: interleaving
        result = [];
        tones = varargin{1};
        fc = varargin{2};
        recal = varargin{3};
        interleaving = varargin{4};
        origTones = tones;
        if (interleaving)
            tones = 2 * tones;
        end
        vsaDisp = vsaApp.Display;
        vsaTraces = vsaDisp.Traces;
        tr = vsaTraces.Item(0);
        marker = tr.Markers.Item(0);
        marker.IsVisible = true;
        mag = zeros(length(tones),1);
        for i=1:length(tones)
            marker.XData = tones(i) + fc;
            mag(i) = marker.Y;
        end
        marker.IsVisible = false;
        mag = mag - sum(mag)/length(mag);
        ampCorr = [origTones zeros(length(tones),1)];
        if (recal)
            try
                load('ampCorr');
                if (~isequal(ampCorr(:,1), origTones))
                    errordlg('Frequency points must be identical for re-calibration. Please perform initial calibration first.');
                    return;
                end
            catch
            end
        end
        ampCorr = [origTones (ampCorr(:,2)-mag)];
        save('ampCorr', 'ampCorr');
        result = 0;
%-------------------------------------------------------------------------        
    otherwise
        error(['unknown vsafunc: ' fct]);
end
end

function vsaDemod = getDigDemod(vsaApp)
        vsaMeas = vsaApp.Measurements.SelectedItem;
        %switch to VSA Measurement (here I have an Error)
        DigDemodType = Agilent.SA.Vsa.DigitalDemod.MeasurementExtension.ExtensionType;
        DigDemodMeasExt = vsaMeas.SetMeasurementExtension(DigDemodType);
        vsaDemod = Agilent.SA.Vsa.DigitalDemod.MeasurementExtension.CastToExtensionType(DigDemodMeasExt);
        % [Start workaround for Matlab defect]
        vsaDemod.delete;
        DigDemodMeasExt = vsaMeas.SetMeasurementExtension(DigDemodType);
        vsaDemod = Agilent.SA.Vsa.DigitalDemod.MeasurementExtension.CastToExtensionType(DigDemodMeasExt);
        % [End workaround for Matlab defect]
end