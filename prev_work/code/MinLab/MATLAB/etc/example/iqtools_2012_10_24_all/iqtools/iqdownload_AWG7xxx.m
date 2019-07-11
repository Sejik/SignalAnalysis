function f = iqdownload_AWG7xxx(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, downloadToChannel, sequence)
% download an IQ waveform to the AWG7xxx
    if (~isempty(sequence))
        errordlg('Sequence mode is not yet implemented for the AWG 7xxx');
        f = [];
        return;
    end
    ch1on = 0;
    ch2on = 0;
    f = iqopen(arbConfig);
    if (isempty(f))
        return;
    end
    xfprintf(f, '*cls');
    xfprintf(f, ':awgc:stop');
    if (fs ~= 0)
        xfprintf(f, sprintf(':sour:freq %.12g\n', fs));
    end
    if (isfield(arbConfig,'do_rst') && arbConfig.do_rst)
        xfprintf(f, '*rst');
    end
    if (isfield(arbConfig,'extClk') && arbConfig.extClk)
        xfprintf(f, ':awgc:clock:sour ext');
    else
        xfprintf(f, ':awgc:clock:sour int');
    end
    switch (downloadToChannel{1})
        case 'I+Q to channel 1+2'
            gen_arb_AWG7xxx(arbConfig, f, 1, real(data), marker1, fs, segmNum);
            ch1on = 1;
            if (fs <= 12e9)
                gen_arb_AWG7xxx(arbConfig, f, 2, imag(data), marker2, fs, segmNum);
                ch2on = 1;
            end
        case 'I+Q to channel 2+1'
            gen_arb_AWG7xxx(arbConfig, f, 1, imag(data), marker1, fs, segmNum);
            ch1on = 1;
            if (fs <= 12e9)
                gen_arb_AWG7xxx(arbConfig, f, 2, real(data), marker2, fs, segmNum);
                ch2on = 1;
            end
        case 'I to channel 1'
            gen_arb_AWG7xxx(arbConfig, f, 1, real(data), marker1, fs, segmNum);
            ch1on = 1;
        case 'I to channel 2'
            gen_arb_AWG7xxx(arbConfig, f, 2, real(data), marker1, fs, segmNum);
            ch2on = 1;
        case 'Q to channel 1'
            gen_arb_AWG7xxx(arbConfig, f, 1, imag(data), marker1, fs, segmNum);
            ch1on = 1;
        case 'Q to channel 2'
            gen_arb_AWG7xxx(arbConfig, f, 2, imag(data), marker1, fs, segmNum);
            ch2on = 1;
    end
    if (isfield(arbConfig,'skew') && isfloat(arbConfig.skew))
        if (arbConfig.skew >= 0)
            xfprintf(f, sprintf(':sour1:del %.12g', arbConfig.skew));
            xfprintf(f, sprintf(':sour2:del %.12g', 0));
        else
            xfprintf(f, sprintf(':sour1:del %.12g', 0));
            xfprintf(f, sprintf(':sour2:del %.12g', -1.0 * arbConfig.skew));
        end
    end
    xfprintf(f, ':awgc:rmode cont');
    xfprintf(f, ':awgc:run');
    if (ch1on) xfprintf(f, ':outp1 on'); end
    if (ch2on) xfprintf(f, ':outp2 on'); end
    if (~exist('keepOpen') || keepOpen == 0)
        fclose(f);
    end;
end


function gen_arb_AWG7xxx(arbConfig, f, chan, data, marker, fs, segm_num)
% download an arbitrary waveform signal to a given channel and segment
% number. Set the sampling rate to fs
    % segment definition
    segm_len = length(data);
    if (segm_len > 0)
        % delete the current waveform segment, but ignore errors
        cmd = sprintf(':wlist:wav:del "data%d_%d"\n', chan, segm_num);
        fprintf(f, cmd);
        xfprintf(f, '*cls');
        cmd = sprintf(':wlist:wav:new "data%d_%d",%d,INTEGER\n', chan, segm_num, segm_len);
        xfprintf(f, cmd);    
        % scale to DAC values - data is assumed to be -1 ... +1
        data = uint16(round(8191 * data) + 8192);
        if (~isempty(marker))
            data = data + bitshift(uint16(marker(:,1)), 14);
            if (size(marker,2) >= 2)
                data = data + bitshift(uint16(marker(:,2)), 15);
            end
            xfprintf(f, sprintf(':sour%d:dac:res 8', chan));
        else
            xfprintf(f, sprintf(':sour%d:dac:res 10', chan));
        end
        % swap MSB and LSB bytes in case of TCP/IP connection
        if (strcmp(f.type, 'tcpip'))
            data = swapbytes(data);
        end
        % download the arbitrary waveform
        offset = 0;
        while (offset < segm_len)
            len = min(segm_len - offset, 1024000);
            cmd = sprintf(':wlist:wav:data "data%d_%d",%d,%d,', chan, segm_num, offset, len);
            binblockwrite(f, data(1+offset:offset+len), 'uint16', cmd);
            %slen = sprintf('%d', 2*len);
            %sllen = sprintf('%d', length(slen));
            %ds(2,:) = bitand(data(1+offset:offset+len), 255);
            %ds(1,:) = bitshift(data(1+offset:offset+len), -8);
            %cmd = [ cmd '#' sllen slen ds(1:end)];
            %fwrite(f, cmd);
            %%%%
            xfprintf(f, '\n');
            offset = offset + len;
        end
        query(f, '*opc?\n');
%        if (isfield(arbConfig, 'ampType'))
%            xfprintf(f, [':outp:coup ' arbConfig.ampType]);
%        end
    end
    if (isfield(arbConfig,'amplitude'))
        xfprintf(f, sprintf(':sour%d:volt:ampl %g', chan, arbConfig.amplitude(chan)));    
    end
    if (isfield(arbConfig,'offset'))
        xfprintf(f, sprintf(':sour%d:volt:offs %g', chan, arbConfig.offset(chan)));    
    end
    xfprintf(f, sprintf(':sour%d:wav "data%d_%d"', chan, chan, segm_num));
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
    if (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12) && ~strncmp(result, '1', 1))
        errordlg(sprintf('Instrument returns error on cmd "%s". Result = %s\n', s, result));
    end
end


