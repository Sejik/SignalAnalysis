function f = iqdownload_81150A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, downloadToChannel, sequence)
% download an IQ waveform to the 81150A
    if (~isempty(sequence))
        errordlg('Sequence mode is not available for the 81150A / 81160A');
        f = [];
        return;
    end
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
        xfprintf(f, '*rst');
    end
    % couple both channels
    xfprintf(f, ':trac:chan1 off');
    % set the skew - depending on whether it is positive or negative, it
    % has to be set on channel1 or channel2. The other one is always zero.
    if (isfield(arbConfig,'skew') && isfloat(arbConfig.skew))
        if (arbConfig.skew >= 0)
            xfprintf(f, sprintf(':puls:del1 %.12g', arbConfig.skew));
            xfprintf(f, sprintf(':puls:del2 %.12g', 0));
        else
            xfprintf(f, sprintf(':puls:del1 %.12g', 0));
            xfprintf(f, sprintf(':puls:del2 %.12g', -1.0 * arbConfig.skew));
        end
    end
    switch (downloadToChannel{1})
        case 'I+Q to channel 1+2'
            gen_arb_81150A(arbConfig, f, 1, real(data), marker1, fs, segmNum);
            gen_arb_81150A(arbConfig, f, 2, imag(data), marker2, fs, segmNum);
        case 'I+Q to channel 2+1'
            gen_arb_81150A(arbConfig, f, 1, imag(data), marker1, fs, segmNum);
            gen_arb_81150A(arbConfig, f, 2, real(data), marker2, fs, segmNum);
        case 'I to channel 1'
            gen_arb_81150A(arbConfig, f, 1, real(data), marker1, fs, segmNum);
        case 'I to channel 2'
            gen_arb_81150A(arbConfig, f, 2, real(data), marker1, fs, segmNum);
        case 'Q to channel 1'
            gen_arb_81150A(arbConfig, f, 1, imag(data), marker1, fs, segmNum);
        case 'Q to channel 2'
            gen_arb_81150A(arbConfig, f, 2, imag(data), marker1, fs, segmNum);
    end
    xfprintf(f, ':trac:chan1 on');
    if (~exist('keepOpen') || keepOpen == 0)
        fclose(f);
    end;
end



function gen_arb_81150A(arbConfig, f, chan, data, marker, fs, segm_num)
% download an arbitrary waveform signal to a given channel and segment
% number. Set the sampling rate to fs
    xfprintf(f, ':func user');      % switch to arb mode
    segm_len = length(data);
    if (fs ~= 0 && segm_len ~= 0)
        xfprintf(f, sprintf(':freq%d %.15g', chan, fs/segm_len));
    end
    % segment definition
    if (segm_len > 0)
        % data is assumed to be -1 ... +1
        data = round(8191 * data);

        % make 16-bit integers
        data = int16(data);

        % swap MSB and LSB bytes in case of TCP/IP connection
        if (strcmp(f.type, 'tcpip'))
            xfprintf(f, ':form:bord norm');
        else
            xfprintf(f, ':form:bord swap');
        end

        % download an arbitrary waveform
        % the built-in binblockwrite command does not work correctly with the 81180A
        % binblockchunkwrite is a replacement for it.
        cmd = sprintf(':data%d:dac volatile,', chan);
        binblockwrite(f, data, 'int16', cmd);
        fprintf(f, '');                      % seems to be required to terminate the binary transfer
        query(f, '*opc?');
    end
    if (isfield(arbConfig,'amplitude'))
        xfprintf(f, sprintf(':volt%d:ampl %g', chan, arbConfig.amplitude(chan)));    
    end
    if (isfield(arbConfig,'offset'))
        xfprintf(f, sprintf(':volt%d:offs %g', chan, arbConfig.offset(chan)));    
    end
    xfprintf(f, ':func:user volatile'); % use VOLATILE waveform
    xfprintf(f, sprintf(':outp%d on', chan));             % turn output on
end


function xfprintf(f, s)
% Send the string s to the instrument object f
% and check the error status

% un-comment the following line to see a trace of commands
%    fprintf('cmd = %s\n', s);
    fprintf(f, s);
    result = query(f, ':syst:err?');
    if (length(result) == 0)
        fclose(f);
        errordlg('Instrument did not respond to :SYST:ERR query. Check the instrument.', 'Error');
        error(':syst:err query failed');
    end
    if (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
        errordlg(sprintf('Instrument returns error on cmd "%s". Result = %s\n', s, result));
    end
end
