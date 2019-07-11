function result = iqdownload_M8190A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, downloadToChannel, sequence, run)
% Download a waveform to the M8190A
% It is NOT intended that this function be called directly, only via iqdownload

% determine to which channel the real and imaginary parts of the signal
% will be loaded. Zero means ignore that part of the waveform.
% For DUC mode, determine in which channels to load the BB signal.
    result = [];
    realCh = 0;
    imagCh = 0;
    % just in case "downloadToChannel" is given as a string
    if (~iscell(downloadToChannel))
        downloadToChannel = { downloadToChannel };
    end
    switch (downloadToChannel{1})
    % values for direct mode
        case 'I+Q to channel 1+2'
            realCh = 1; imagCh = 2;
        case 'I+Q to channel 2+1'
            realCh = 2; imagCh = 1;
        case 'I to channel 1'
            realCh = 1; imagCh = 0;
        case 'I to channel 2'
            realCh = 2; imagCh = 0;
        case 'Q to channel 1'
            realCh = 0; imagCh = 1;
        case 'Q to channel 2'
            realCh = 0; imagCh = 2;
    % values for DUC modes. Note that the variable names 'realCh' and
    % 'imagCh' are misleading here but it makes the following code much
    % simpler to use the same variables as in direct mode
        case 'RF to channel 1'
            realCh = 1; imagCh = 0;
        case 'RF to channel 2'
            realCh = 0; imagCh = 2;
        case 'RF to channel 1+2'
            realCh = 1; imagCh = 2;
        otherwise
            error(['unexpected value for downloadToChannel argument: ' downloadToChannel{1}]);
    end

    % set to 1 if this is a Revision 2 module
    isRev2 = 0;
    % interpolation factor for digital upconversion modes
    interpolationFactor = 1;
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    result = f;
    % find out if we have a one-channel or two channel instrument.
    opts = query(f, '*opt?');
    if (~isempty(strfind(opts, '001')))
        numChannels = 1;
        % be graceful with one-channel instruments and ignore anything
        % that deals with the second channel
        if (realCh == 2); realCh = 0; end;
        if (imagCh == 2); imagCh = 0; end;
    else
        numChannels = 2;
    end
    % treat sequence setup completely separate from waveform download
    if (~isempty(sequence))
        result = setupSequence(f, sequence, realCh, imagCh, run);
    else
        % perform instrument reset if it is selected in the configuration
        if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
            if (realCh == 0 || imagCh == 0)
                warndlg({'You have chosen to send a "*RST" command and you are downloading a' ...
                         'waveform to only one channel. This will delete the waveform on the' ...
                         'other channel. If you want to keep the previous waveform, please' ...
                         'un-check the "send *RST" checkbox in the Configuration window.'});
            elseif (segmNum ~= 1)
                warndlg({'You have chosen to send a "*RST" command and you are downloading a' ...
                         'waveform to segment number greater than 1. This will delete all other' ...
                         'waveform segments. If you want to keep the previous waveform, please' ...
                         'un-check the "send *RST" checkbox in the Configuration window.'});
            end
            xfprintf(f, '*RST');
        end
        % stop waveform output
        for i = 1:numChannels
            if (realCh == i || imagCh == i); xfprintf(f, sprintf(':ABORt%d', i)); end
        end
        % determine which version of the instrument we have and set parameters
        % accordingly
        switch (arbConfig.model)
            case 'M8190A_12bit'
                isRev2 = 1;
                dwid = 'WSPeed';
            case 'M8190A_14bit'
                isRev2 = 1;
                dwid = 'WPRecision';
            case { 'M8190A_DUC_x3' 'M8190A_DUC_x12' 'M8190A_DUC_x24' 'M8190A_DUC_x48' }
                isRev2 = 1;
                interpolationFactor = eval(arbConfig.model(13:end));
                fs = fs * interpolationFactor;
                dwid = sprintf('INTX%d', interpolationFactor);
            otherwise
                dwid = [];
                % older instrument - do not send any command
        end
        % set frequency, int/ext and precision in a single command to avoid out-of-range
        % errors
        if (fs ~= 0)
            for i = 1:numChannels
                if (realCh == i || imagCh == i);
                    if (isfield(arbConfig, 'extClk') && arbConfig.extClk)
                        cmd = sprintf(':FREQuency:RASTer:SOURce%d EXTernal; :FREQuency:RASTer:EXTernal %.15g;', i, fs);
                    else
                        cmd = sprintf(':FREQuency:RASTer:SOURce%d INTernal; :FREQuency:RASTer %.15g;', i, fs);
                    end
                    if (~isempty(dwid))
                        cmd = sprintf('%s :TRACe%d:DWIDth %s;', cmd, i, dwid);
                    end
                    % if we get an error when setting the mode, don't attempt to
                    % do anything else - it will not work
                    if (xfprintf(f, cmd) ~= 0)
                        return;
                    end
                end
            end
        end
        if (interpolationFactor ~= 1)
            % DUC mode waveform download
            gen_arb_IQ_M8190A(arbConfig, isRev2, f, realCh, data, marker1, segmNum);
            gen_arb_IQ_M8190A(arbConfig, isRev2, f, imagCh, data, marker2, segmNum);
        else
            % direct mode waveform download
            gen_arb_M8190A(arbConfig, isRev2, f, realCh, real(data), marker1, segmNum);
            gen_arb_M8190A(arbConfig, isRev2, f, imagCh, imag(data), marker2, segmNum);
        end
        if (isfield(arbConfig,'skew') && isfloat(arbConfig.skew))
            % in arbConfig, there is no separate skew value for ch1 and
            % ch2. Positive values mean Ch1 is delayed, negative values
            % mean that Ch2 is delayed
            skew = arbConfig.skew;
            ch = 1;
            if (skew < 0)
                skew = -1 * skew;
                ch = 2;
            end
            if (arbConfig.skew > 30e-12)
                xfprintf(f, sprintf(':ARM:CDELay%d %.12g', ch, skew));
                xfprintf(f, sprintf(':ARM:DELay%d 0', ch));
                if (numChannels > 1)
                    xfprintf(f, sprintf(':ARM:CDELay%d %.12g', 3-ch, 0));
                    xfprintf(f, sprintf(':ARM:DELay%d 0', 3-ch));
                end
            else
                xfprintf(f, sprintf(':ARM:CDELay%d 0', ch));
                xfprintf(f, sprintf(':ARM:DELay%d %.12g', ch, arbConfig.skew));
                if (numChannels > 1)
                    xfprintf(f, sprintf(':ARM:CDELay%d 0', 3-ch));
                    xfprintf(f, sprintf(':ARM:DELay%d %.12g', 3-ch, 0));
                end
            end
        end
        if (isRev2)
            % turn on channel coupling only if download to both channels
            % otherwise keep the previous setting. If the user wants de-coupled
            % channels, he has to do that in the SFP or outside this script
            if (realCh + imagCh == 3)
                xfprintf(f, ':INSTrument:COUPle:STATe ON');
            end
            if (run)
                % setting ARB mode is now done in gen_arb function
                for i = 1:numChannels
                    if (realCh == i || imagCh == i); xfprintf(f, sprintf(':INIT:IMMediate%d', i)); end
                end
            end
        else
            % in Rev1 instruments, channels are always coupled
            if (run)
                xfprintf(f, ':INIT:IMMediate');
            end
        end
    end
    if (~exist('keepOpen', 'var') || keepOpen == 0)
        fclose(f);
    end;
end


function gen_arb_M8190A(arbConfig, isRev2, f, chan, data, marker, segm_num)
% download an arbitrary waveform signal to a given channel and segment
    if (~chan)
        return;
    end
    segm_len = length(data);
    if (segm_len > 0)
        % Try to delete the segment, but ignore errors if it does not exist
        % Another approach would be to first find out if it exists and only
        % then delete it, but that takes much longer
        xfprintf(f, sprintf(':TRACe%d:DELete %d', chan, segm_num), 1);
        xfprintf(f, sprintf(':TRACe%d:DEFine %d,%d', chan, segm_num, segm_len));
        % scale to DAC values - data is assumed to be -1 ... +1
        data = int16(round(8191 * data) * 4);
        if (~isempty(marker))
            if (length(marker) ~= length(data))
                errordlg('length of marker vector and data vector must be the same');
            else
                data = data + int16(bitand(uint16(marker), 3));
            end
        end
        % swap MSB and LSB bytes in case of TCP/IP connection
        if (strcmp(f.type, 'tcpip'))
            data = swapbytes(data);
        end
        % Download the arbitrary waveform. 
        % Split large waveform segments in reasonable chunks
        use_binblockwrite = 1;
        offset = 0;
        while (offset < segm_len)
            if (use_binblockwrite)
                len = min(segm_len - offset, 523200);
                cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segm_num, offset);
                binblockwrite(f, data(1+offset:offset+len), 'int16', cmd);
                xfprintf(f, '');
            else
                len = min(segm_len - offset, 4800);
                cmd = sprintf(':TRACe%d:DATA %d,%d', chan, segm_num, offset);
                cmd = [cmd sprintf(',%d', data(1+offset:offset+len)) '\n'];
                xfprintf(f, cmd);
            end
            offset = offset + len;
        end
        query(f, '*opc?\n');
        if (isRev2)
            xfprintf(f, sprintf(':TRACe%d:SELect %d', chan, segm_num));
        end
    end
    if (isRev2 && isfield(arbConfig, 'ampType'))
        xfprintf(f, sprintf(':OUTPut%d:ROUTe %s', chan, arbConfig.ampType));
    end
    if (isfield(arbConfig,'amplitude'))
        xfprintf(f, sprintf(':VOLTage%d:AMPLitude %g', chan, arbConfig.amplitude(chan)));    
    end
    if (isfield(arbConfig,'offset'))
        xfprintf(f, sprintf(':VOLTage%d:OFFSet %g', chan, arbConfig.offset(chan)));    
    end
    xfprintf(f, sprintf(':FUNCtion%d:MODE ARBitrary', chan));
    xfprintf(f, sprintf(':OUTPut%d ON', chan));
end


function gen_arb_IQ_M8190A(arbConfig, isRev2, f, chan, data, marker, segm_num)
% download an IQ waveform to a given channel and segment number.
% Set the sampling rate to fs
    if (~chan)
        return;
    end
    segm_len = length(data);
    if (segm_len > 0)
        % Try to delete the segment, but ignore errors if it does not exist
        % Another approach would be to first find out if it exists and only
        % then delete it, but that takes much longer
        xfprintf(f, sprintf(':TRACe%d:DELete %d', chan, segm_num), 1);
        xfprintf(f, sprintf(':TRACe%d:DEFine %d,%d', chan, segm_num, segm_len));
        % split into I & Q
        dacData(1,:) = real(data);
        dacData(2,:) = imag(data);
        % scale to DAC values - data is assumed to be -1 ... +1
        dacData = int16(round(16383 * dacData) * 2);
        % insert marker data
        if (~isempty(marker))
            if (length(marker) ~= segm_len)
                errordlg('length of marker vector and data vector must be the same');
            else
                dacData(1,:) = dacData(1,:) + int16(bitget(uint16(marker'), 1));  % sample marker
                dacData(2,:) = dacData(2,:) + int16(bitget(uint16(marker'), 2));  % sync marker
            end
        end
        % merge I & Q into a vector
        data = dacData(:);        
        segm_len = length(data);
        % swap MSB and LSB bytes in case of TCP/IP connection
        if (strcmp(f.type, 'tcpip'))
            data = swapbytes(data);
        end
        % Download the arbitrary waveform. 
        % Split large waveform segments in reasonable chunks
        use_binblockwrite = 1;
        offset = 0;
        while (offset < segm_len)
            if (use_binblockwrite)
                len = min(segm_len - offset, 523200);
                cmd = sprintf(':TRACe%d:DATA %d,%d,', chan, segm_num, offset/2);
                binblockwrite(f, data(1+offset:offset+len), 'int16', cmd);
                xfprintf(f, '');
            else
                len = min(segm_len - offset, 4800);
                cmd = sprintf(':TRACe%d:DATA %d,%d', chan, segm_num, offset/2);
                cmd = [cmd sprintf(',%d', data(1+offset:offset+len)) '\n'];
                xfprintf(f, cmd);
            end
            offset = offset + len;
        end
        query(f, '*OPC?\n');
        if (isRev2)
            xfprintf(f, sprintf(':TRACe%d:SELect %d', chan, segm_num));
        end
    end
    if (isfield(arbConfig,'carrierFrequency'))
        xfprintf(f, sprintf(':CARRier%d:FREQuency %.0f,%g', ...
            chan, floor(arbConfig.carrierFrequency), arbConfig.carrierFrequency - floor(arbConfig.carrierFrequency)));
    end
    if (isRev2 && isfield(arbConfig, 'ampType'))
        xfprintf(f, sprintf(':OUTPut%d:ROUte %s', chan, arbConfig.ampType));
    end
    if (isfield(arbConfig,'amplitude'))
        xfprintf(f, sprintf(':VOLTage%d:AMPLitude %g', chan, arbConfig.amplitude(chan)));    
    end
    if (isfield(arbConfig,'offset'))
        xfprintf(f, sprintf(':VOLTage%d:OFFSet %g', chan, arbConfig.offset(chan)));    
    end
    xfprintf(f, sprintf(':FUNCtion%d:MODE ARBitrary', chan));
    xfprintf(f, sprintf(':OUTPut%d ON', chan));
end


function result = setupSequence(f, seqcmd, realCh, imagCh, run)
% Perform sequencer-related functions. The format of "seqcmd" is described
% in iqseq.m
% check what to do: seqcmd.cmd contains the function to perform and
% seqcmd.sequence contains the parameter(s)
    result = [];
    switch (seqcmd.cmd)
        case 'list'
            s = sscanf(query(f, sprintf(':TRACe%d:CATalog?', max(realCh, imagCh))), '%d,');
            s = reshape(s,2,length(s)/2);
            if (s(1,1) == 0)
                errordlg({'There are no segments defined.' ...
                    'Please load segments before calling this function and make sure' ...
                    'that the "send *RST" checkbox in the config window is un-checked'} );
            else
                errordlg(sprintf('The following segments are defined:%s', ...
                    sprintf(' %d', s(1,:))));
                result = s(1,:);
            end
        case 'delete'
            for i = [realCh imagCh]
                if (i)
                    xfprintf(f, sprintf(':ABORt%d', i));
                    xfprintf(f, sprintf(':TRACe%d:DELete:ALL', i));
                    xfprintf(f, sprintf(':STABle%d:RESET', i));
                end
            end
        case 'event'
            xfprintf(f, ':TRIGger:ADVance:IMMediate');
        case 'trigger'
            xfprintf(f, ':TRIGger:BEGin:IMMediate');
        case 'define'
            defineSequence(f, seqcmd, realCh, imagCh, run);
        case 'amplitudeTable'
            list = seqcmd.sequence;
            for i = [realCh imagCh]
                if (i)
                    xfprintf(f, sprintf(':ABORt%d', i));
                    binary = 0;
                    if (binary)
                        list = 32767 * int32(list);
                        binblockwrite(f, list, 'int32', sprintf(':ATABle%d:DATA 0,', i));
                        xfprintf(f, '');
                    else
                        cmd = sprintf(',%g', list);
                        xfprintf(f, sprintf(':ATABle%d:DATA 0%s', i, cmd));
                    end
                end
            end
        case 'frequencyTable'
            list = seqcmd.sequence;
            % convert frequencies into integral & fractional part
            list2 = zeros(1, 2*length(list));
            for i=1:length(list)
                list2(2*i-1) = floor(list(i));
                list2(2*i) = list(i) - floor(list(i));
            end
            for i = [realCh imagCh]
                if (i)
                    xfprintf(f, sprintf(':ABORt%d', i));
                    binary = 0;
                    if (binary)
                        binblockwrite(f, list2, 'float32', sprintf(':FTABle%d:DATA 0,', i));
                        xfprintf(f, '');
                    else
                        cmd = sprintf(',%.15g', list2);
                        xfprintf(f, sprintf(':FTABle%d:DATA 0%s', i, cmd));
                    end
                end
            end
        case 'actionDefine'
            list = seqcmd.sequence;
            for i = [realCh imagCh]
                if (i)
                    xfprintf(f, sprintf(':ABORt%d', i));
                    result = str2double(query(f, sprintf(':ACTion%d:DEFine:NEW?', i)));
                end
            end
            seqcmd.cmd = 'actionAppend';
            seqcmd.sequence = [ result list ];
            setupSequence(f, seqcmd, realCh, imagCh, run);
        case 'actionAppend'
            list = seqcmd.sequence;
            for i = [realCh imagCh]
                if (i)
                    for j = 2:2:length(list)
                        if (isempty(list{j+1}))
                            % no parameter e.g.      SRUN
                            xfprintf(f, sprintf(':ACTion%d:APPend %d,%s', ...
                                i, list{1}, list{j}));
                        elseif (isscalar(list{j+1}))
                            % single parameter e.g.   PBUMp, 0.4
                            if (strncmpi(list{j}, 'CFR', 3) || strncmpi(list{j}, 'SRAT', 4))
                                % for CFrequency and SRate, use the integral/fractional split
                                xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g,%.15g', ...
                                    i, list{1}, list{j}, floor(list{j+1}), list{j+1}-floor(list{j+1})));
                            else
                                xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g', ...
                                    i, list{1}, list{j}, list{j+1}));
                            end
                        else
                            % dual parameter e.g.   CFRequency, 100e6, 0.5
                            xfprintf(f, sprintf(':ACTion%d:APPend %d,%s,%.15g,%.15g', ...
                                i, list{1}, list{j}, list{j+1}));
                        end
                    end
                end
            end
        case 'actionDelete'
            for i = [realCh imagCh]
                if (i)
                    xfprintf(f, sprintf(':ABORt%d', i));
                    xfprintf(f, sprintf(':ACTion%d:DELete %d', i, seqcmd.sequence));
                end
            end
        case 'actionDeleteAll'
            for i = [realCh imagCh]
                if (i)
                    xfprintf(f, sprintf(':ABORt%d', i));
                    xfprintf(f, sprintf(':ACTion%d:DELete:ALL', i));
                end
            end
        case 'dynamic'
            for i = [realCh imagCh]
                if (i)
                    xfprintf(f, sprintf(':ABORt%d', i));
                    xfprintf(f, sprintf(':STABle%d:DYNamic %d', i, seqcmd.sequence));
                end
            end
        case 'mode'
            for i = [realCh imagCh]
                if (i)
                    xfprintf(f, sprintf(':ABORt%d', i));
                    xfprintf(f, sprintf(':FUNCtion%d:MODE %s', i, seqcmd.sequence));
                end
            end
            if (run)
                for i = [realCh imagCh]
                    if (i)
                        xfprintf(f, sprintf(':INIT:IMMediate%d', i));
                    end
                end
            end
        case 'triggerMode'
            switch seqcmd.sequence
                case {1 'triggered'}
                    s = '0';
                case {0 'continuous'}
                    s = '1';
                otherwise
                    error('unknown triggerMode');
            end
            for i = [realCh imagCh]
                if (i)
                    xfprintf(f, sprintf(':INIT:CONTinuous%d %s', i, s));
                end
            end
        case 'stop'
            for i = [realCh imagCh]
                if (i)
                    xfprintf(f, sprintf(':ABORt%d', i));
                end
            end
        otherwise
            errordlg(['undefined sequence command: ' seqcmd.cmd]);
    end
end


function defineSequence(f, seqcmd, realCh, imagCh, run)
% define a new sequence table
    xfprintf(f, ':ABORt');
    seqtable = seqcmd.sequence;
% check if only valid fieldnames are used (typo?)
    fields = fieldnames(seqtable);
    fields(find(strcmp(fields, 'segmentNumber'))) = [];
    fields(find(strcmp(fields, 'segmentLoops'))) = [];
    fields(find(strcmp(fields, 'segmentAdvance'))) = [];
    fields(find(strcmp(fields, 'sequenceAdvance'))) = [];
    fields(find(strcmp(fields, 'sequenceLoops'))) = [];
    fields(find(strcmp(fields, 'markerEnable'))) = [];
    fields(find(strcmp(fields, 'sequenceInit'))) = [];
    fields(find(strcmp(fields, 'sequenceEnd'))) = [];
    fields(find(strcmp(fields, 'scenarioEnd'))) = [];
    fields(find(strcmp(fields, 'amplitudeInit'))) = [];
    fields(find(strcmp(fields, 'amplitudeNext'))) = [];
    fields(find(strcmp(fields, 'frequencyInit'))) = [];
    fields(find(strcmp(fields, 'frequencyNext'))) = [];
    fields(find(strcmp(fields, 'actionID'))) = [];
    if (~isempty(fields))
        disp('The following field names are unknown:');
        disp(fields);
        error('unknown field names');
    end
% check if all the segments are defined
    s = sscanf(query(f, sprintf(':trac%d:cat?', max(realCh, imagCh))), '%d,');
    s = reshape(s,2,length(s)/2);
    notDef = [];
    for i = 1:length(seqtable)
        if (isempty(find(s(1,:) == seqtable(i).segmentNumber, 1)))
            notDef = [notDef seqtable(i).segmentNumber];
        end
    end
    notDef = notDef(notDef > 0);    % ignore zero and negative numbers, they are special commands
    if (~isempty(notDef))
        errordlg({ sprintf('The following segments are used in the sequence but not defined:%s.', ...
            sprintf(' %d', notDef)) ...
            'Please load segments before calling this function and make sure' ...
            'that the "send *RST" checkbox in the config window is un-checked'} );
        return;
    end
% download the sequence table
    seqData = uint32(zeros(6 * length(seqtable), 1));
    for i = 1:length(seqtable)
            seqTabEntry = calculateSeqTableEntry(seqtable(i), i, length(seqtable));
            seqData(6*i-5:6*i) = seqTabEntry;
    end
    % swap MSB and LSB bytes in case of TCP/IP connection
    if (strcmp(f.type, 'tcpip'))
        seqData = swapbytes(seqData);
    end
    for i = [realCh imagCh]
        if (i)
            binblockwrite(f, seqData, 'uint32', sprintf(':STABle%d:DATA 0,', i));
            xfprintf(f, '');
            % if the variable 'debugSeq' exists in the base workspace,
            % print out the sequence table as hex numbers
            if (evalin('base', 'exist(''debugSeq'', ''var'')'))
                fprintf(sprintf('sequence channel %d\n', i));
                for k=1:6:length(seqData)
                    fprintf(sprintf('%08x ', seqData(k:k+5)));
                    fprintf('\n');
                end
            end
%            cmd = sprintf(',%.0f', seqData);
%            xfprintf(f, sprintf(':STABle%d:DATA 0%s', i, cmd));
            xfprintf(f, sprintf(':STABle%d:SEQuence:SELect %d', i, 0));
            xfprintf(f, sprintf(':STABle%d:DYNamic:STATe 0', i));
            xfprintf(f, sprintf(':FUNCtion%d:MODE STSequence', i));
        end
    end
    if (run)
        for i = [realCh imagCh]
            if (i)
                xfprintf(f, sprintf(':INIT:IMMediate%d', i));
            end
        end
    end

end

function seqTabEntry = calculateSeqTableEntry(seqline, currLine, numLines)
% calculate the six 32-bit words that make up one sequence table entry.
% For details on the format, see user guide section 4.20.6
%
% The content of the six 32-bit words depends on the type of entry:
% Data Entry: Control / Seq.Loops / Segm.Loops / Segm.ID / Start Offset / End Offset
% Idle Cmd:   Control / Seq.Loops / Cmd Code(0) / Idle Sample / Delay / Unused
% Action:     Control / Seq.Loops / Cmd Code(1) + Act.ID / Segm.ID / Start Offset / End Offset
    cbitCmd = 32;
    cbitEndSequence = 31;
    cbitEndScenario = 30;
    cbitInitSequence = 29;
    cbitMarkerEnable = 25;
    cbitAmplitudeInit = 16;
    cbitAmplitudeNext = 15;
    cbitFrequencyInit = 14;
    cbitFrequencyNext = 13;
    cmaskSegmentAuto = hex2dec('00000000');
    cmaskSegmentCond = hex2dec('00010000');
    cmaskSegmentRept = hex2dec('00020000');
    cmaskSegmentStep = hex2dec('00030000');
    cmaskSequenceAuto = hex2dec('00000000');
    cmaskSequenceCond = hex2dec('00100000');
    cmaskSequenceRept = hex2dec('00200000');
    cmaskSequenceStep = hex2dec('00300000');
    seqLoopCnt = 1;

    ctrl = uint32(0);
    seqTabEntry = uint32(zeros(6, 1));        % initialize the return value
    if (seqline.segmentNumber == 0)           % segment# = 0 means: idle command
        ctrl = bitset(ctrl, cbitCmd);         % set the command bit
        seqTabEntry(3) = 0;                   % Idle command code = 0
        seqTabEntry(4) = 0;                   % Sample value
        if (isfield(seqline, 'segmentLoops') && ~isempty(seqline.segmentLoops))
            seqTabEntry(5) = seqline.segmentLoops;  % use segment loops as delay
        else
            seqTabEntry(5) = 1;
        end
        seqTabEntry(6) = 0;                   % unused
    else
        if (isfield(seqline, 'actionID')&& ~isempty(seqline.actionID) && seqline.actionID >= 0)
            % if it is an actionID, set the command bit and action Cmd Code
            % and store actionID in 24 MSB of word#3.
            % The segment will not be repeated. segmentLoops is ignored
            ctrl = bitset(ctrl, cbitCmd);
            seqTabEntry(3) = 1 + bitshift(uint32(seqline.actionID), 16);
            if (isfield(seqline, 'segmentLoops') && ~isempty(seqline.segmentLoops) && seqline.segmentLoops > 1)
                errordlg(['segmentLoops will be ignored when an actionID is specified (Seq.ID ' num2str(currLine-1) ')']);
            end
        else
            % normal data entries have the segment loop count in word#3
            if (~isempty(seqline.segmentLoops))
                seqTabEntry(3) = seqline.segmentLoops;
            else
                seqTabEntry(3) = 1;
            end
        end
        seqTabEntry(4) = seqline.segmentNumber;
        seqTabEntry(5) = 0;                   % start pointer
        seqTabEntry(6) = hex2dec('ffffffff'); % end pointer
        if (isfield(seqline, 'segmentAdvance') && ~isempty(seqline.segmentAdvance))
            switch (seqline.segmentAdvance)
                case 'Auto';        ctrl = bitor(ctrl, cmaskSegmentAuto);
                case 'Conditional'; ctrl = bitor(ctrl, cmaskSegmentCond);
                case 'Repeat';      ctrl = bitor(ctrl, cmaskSegmentRept);
                case 'Stepped';     ctrl = bitor(ctrl, cmaskSegmentStep);
            end
        end
        if (isfield(seqline, 'markerEnable') && ~isempty(seqline.markerEnable) && seqline.markerEnable)
            ctrl = bitset(ctrl, cbitMarkerEnable);
        end
    end
    % set the amplitude and frequency table flags
    if (isfield(seqline, 'amplitudeInit') && ~isempty(seqline.amplitudeInit) && seqline.amplitudeInit)
        ctrl = bitset(ctrl, cbitAmplitudeInit);
    end
    if (isfield(seqline, 'amplitudeNext') && ~isempty(seqline.amplitudeNext) && seqline.amplitudeNext)
        ctrl = bitset(ctrl, cbitAmplitudeNext);
    end
    if (isfield(seqline, 'frequencyInit') && ~isempty(seqline.frequencyInit) && seqline.frequencyInit)
        ctrl = bitset(ctrl, cbitFrequencyInit);
    end
    if (isfield(seqline, 'frequencyNext') && ~isempty(seqline.frequencyNext) && seqline.frequencyNext)
        ctrl = bitset(ctrl, cbitFrequencyNext);
    end
    % if the sequence fields exist, then set the sequence control bits
    % according to those fields
    if (isfield(seqline, 'sequenceInit'))
        if (seqline.sequenceInit)  % init sequence flag
            ctrl = bitset(ctrl, cbitInitSequence);
        end
        if (isfield(seqline, 'sequenceEnd')&& ~isempty(seqline.sequenceEnd) && seqline.sequenceEnd)
            ctrl = bitset(ctrl, cbitEndSequence);
        end
        if (isfield(seqline, 'sequenceLoops') && ~isempty(seqline.sequenceLoops))
            seqLoopCnt = seqline.sequenceLoops;
        end
        if (isfield(seqline, 'sequenceAdvance') && ~isempty(seqline.sequenceAdvance))
            switch (seqline.sequenceAdvance)  % sequence advance mode
                case 'Auto';        ctrl = bitor(ctrl, cmaskSequenceAuto);
                case 'Conditional'; ctrl = bitor(ctrl, cmaskSequenceCond);
                case 'Repeat';      ctrl = bitor(ctrl, cmaskSequenceRept);
                case 'Stepped';     ctrl = bitor(ctrl, cmaskSequenceStep);
            end
        end
        if (isfield(seqline, 'scenarioEnd') && ~isempty(seqline.scenarioEnd) && seqline.scenarioEnd)
            ctrl = bitset(ctrl, cbitEndScenario);
        end
    else
        % otherwise assume a single sequence and set start and
        % end of sequence flags automatically
        if (currLine == 1)
            ctrl = bitset(ctrl, cbitInitSequence);
        end
        if (currLine == numLines)
            ctrl = bitset(ctrl, cbitEndSequence);
            ctrl = bitset(ctrl, cbitEndScenario);
        end
    end
    seqTabEntry(1) = ctrl;                % control word
    seqTabEntry(2) = seqLoopCnt;          % sequence loops
end


function retVal = xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status
% if ignoreError is set, the result of :syst:err is ignored
% returns 0 for success, -1 for errors

    retVal = 0;
% un-comment the following line to see a trace of commands
    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        fprintf('cmd = %s\n', s);
    end
    fprintf(f, s);
    result = query(f, ':syst:err?');
    if (isempty(result))
        fclose(f);
        errordlg({'The M8190A firmware did not respond to a :SYST:ERRor query.' ...
            'Please check that the firmware is running and responding to commands.'}, 'Error');
        retVal = -1;
        return;
    end
    if (~exist('ignoreError', 'var') || ignoreError == 0)
        if (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
            errordlg({'M8190A firmware returns an error on command:' s 'Error Message:' result});
            retVal = -1;
        end
    end
end
