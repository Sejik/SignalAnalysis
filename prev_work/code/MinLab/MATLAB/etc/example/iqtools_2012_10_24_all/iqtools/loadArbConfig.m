function varargout = loadArbConfig(arbConfig)
% Returns a struct with the AWG-specific parameters such as maximum sample
% rate, segment granularity, etc.
% If loadArbConfig is called with no arguments, it will load the AWG
% configuration from the file "arbConfig.mat", otherwise, it expects a
% struct with the following members:
%   model - AWG model (see switch statements below)
%   connectionType - 'tcpip' or 'visa'
%   visaAddr - string with the VISA Address (e.g. 'TCPIP0::xxx::INSTR')

    saConfig.connected = 0;
    if (~exist('arbConfig', 'var') || isempty(arbConfig))
        arbConfig.model = 'unknown';
        try
            load('arbConfig.mat');
        catch e
            errordlg('Can''t load configuration file. Please use "Configure Instrument Connection" to create it.', 'Error');
            error('Can''t load configuration file. Please use "Configure Instrument Connection" to create it.');
        end
    end
    switch arbConfig.model
        case { 'M933xA' 'N824xA' 'N603xA' }
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 1.25e9;
            arbConfig.maximumSampleRate = 1.25e9;
            arbConfig.minimumSampleRate = 1.25e9;
            arbConfig.minimumSegmentSize = 128;
            arbConfig.maximumSegmentSize = 32*1024*1024;
            arbConfig.segmentGranularity = 32;
            arbConfig.maxSegmentNumber = 65536;
        case { '81180A' '81180B' }
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 4e9;
            arbConfig.maximumSampleRate = 4.2e9;
            if (strcmp(arbConfig.model, '81180B'))
                arbConfig.maximumSampleRate = 4.6e9;
            end
            arbConfig.minimumSampleRate = 10e6;
            arbConfig.minimumSegmentSize = 384;
            arbConfig.maximumSegmentSize = 64*1024*1024;
            arbConfig.segmentGranularity = 32;
            arbConfig.maxSegmentNumber = 16384;
        case { 'M8190A' 'M8190A_base' }     % Rev. 1 version of M8190A
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 8e9;
            arbConfig.maximumSampleRate = 8e9;
            arbConfig.minimumSampleRate = 6.5e9;
            arbConfig.minimumSegmentSize = 4*48;
            arbConfig.maximumSegmentSize = 2*1024*1024*1024;
            arbConfig.segmentGranularity = 48;
            arbConfig.maxSegmentNumber = 1;
        case 'M8190A_14bit'                 % Rev. 2 of M8190A, 14 bit mode
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 8e9;
            arbConfig.maximumSampleRate = 8e9;
            arbConfig.minimumSampleRate = 125e6;
            arbConfig.minimumSegmentSize = 5*48;
            arbConfig.maximumSegmentSize = 2*1024*1024*1024;
            arbConfig.segmentGranularity = 48;
            arbConfig.maxSegmentNumber = 512*1024;
        case 'M8190A_12bit'                 % Rev. 2 of M8190A, 12 bit mode
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 12e9;
            arbConfig.maximumSampleRate = 12e9;
            arbConfig.minimumSampleRate = 125e6;
            arbConfig.minimumSegmentSize = 5*64;
            arbConfig.maximumSegmentSize = 3*512*1024*1024;
            arbConfig.segmentGranularity = 64;
            arbConfig.maxSegmentNumber = 512*1024;
        case { 'M8190A_DUC_x3' 'M8190A_DUC_x12' 'M8190A_DUC_x24' 'M8190A_DUC_x48' }  % M8190A with digital upconversion
            arbConfig.interpolationFactor = eval(arbConfig.model(13:end));
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 7.2e9 / arbConfig.interpolationFactor;
            arbConfig.maximumSampleRate = 7.2e9 / arbConfig.interpolationFactor;
            arbConfig.minimumSampleRate = 1e9 / arbConfig.interpolationFactor;
            arbConfig.minimumSegmentSize = 5*24;
            arbConfig.maximumSegmentSize = 3*512*1024*1024;
            arbConfig.segmentGranularity = 24;
            arbConfig.maxSegmentNumber = 512*1024;
        case 'M8190A_prototype'             % old prototype - lab use only
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 7.2e9;
            arbConfig.maximumSampleRate = 7.2e9;
            arbConfig.minimumSampleRate = 125e6;
            arbConfig.minimumSegmentSize = 96;
            arbConfig.maximumSegmentSize = 65536;
            arbConfig.segmentGranularity = 96;
            arbConfig.maxSegmentNumber = 1;
        case {'81150A' '81160A'}
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 2e9;
            arbConfig.maximumSampleRate = 2e9;
            arbConfig.minimumSampleRate = 2e9;
            arbConfig.minimumSegmentSize = 512;
            arbConfig.maximumSegmentSize = 512*1024;
            arbConfig.segmentGranularity = 2;
            arbConfig.maxSegmentNumber = 1;
        case {'N51xxA (MXG)'}
            arbConfig.fixedSampleRate = 1;
            arbConfig.defaultSampleRate = 125e6;
            arbConfig.maximumSampleRate = 125e6;
            arbConfig.minimumSampleRate = 1e6;
            arbConfig.minimumSegmentSize = 60;
            arbConfig.maximumSegmentSize = 16*1024*1024;
            arbConfig.segmentGranularity = 1;
            arbConfig.maxSegmentNumber = 1;
        case 'AWG7xxx'
            arbConfig.fixedSampleRate = 0;
            arbConfig.defaultSampleRate = 12e9;
            arbConfig.maximumSampleRate = 24e9;
            arbConfig.minimumSampleRate = 10e6;
            arbConfig.minimumSegmentSize = 4;
            arbConfig.maximumSegmentSize = 64*1024*1024;
            arbConfig.segmentGranularity = 4;
            arbConfig.maxSegmentNumber = 16384;
        otherwise
            errordlg('Unknown instrument model. Please use "Configure Instrument Connection" to set it.', 'Error');
            return;
    end
    % for interleaving, the waveform granularity doubles, because we will
    % split even and odd samples later on.
    % Also, the sampling rate range doubles, because one channel is
    % delayed by half a period
    if (isfield(arbConfig, 'interleaving') && arbConfig.interleaving)
        arbConfig.defaultSampleRate = 2 * arbConfig.defaultSampleRate;
        arbConfig.maximumSampleRate = 2 * arbConfig.maximumSampleRate;
        arbConfig.minimumSampleRate = 2 * arbConfig.minimumSampleRate;
        arbConfig.minimumSegmentSize = 2 * arbConfig.minimumSegmentSize;
        arbConfig.maximumSegmentSize = 2 * arbConfig.maximumSegmentSize;
        arbConfig.segmentGranularity = 2 * arbConfig.segmentGranularity;
    end
    % if output arguments are available, return arbConfig (and saConfig)
    % otherwise, set arbConfig and saConfig variables in caller's space
    if (nargout >= 2)
        varargout{1} = arbConfig;
        varargout{2} = saConfig;
    elseif (nargout >= 1)
        varargout{1} = arbConfig;
    else
        assignin('caller', 'arbConfig', arbConfig);
        assignin('caller', 'saConfig', saConfig);
    end
end
