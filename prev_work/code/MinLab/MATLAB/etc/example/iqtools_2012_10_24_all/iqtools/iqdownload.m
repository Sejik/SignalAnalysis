function result = iqdownload(iqdata, fs, varargin)
% Download a vector of I/Q samples to the configured AWG
% - iqdata - contains a row-vector of complex I/Q samples
%            additional columns may contain marker info
% - fs - sampling rate in Hz
% optional arguments are specified as attribute/value pairs:
% - 'segmentNumber' - specify the segment number to use (default = 1)
% - 'normalize' - auto-scale the data to max. DAC range (default = 1)
% - 'downloadToChannel - string that describes to which AWG channel
%              the data is downloaded. (see individual download routines)
% - 'sequence' - description of the sequence table 
% - 'marker' - vector of integers that must have the same length as iqdata
%              low order bits correspond to marker outputs
% - 'arbConfig' - struct as described in loadArbConfig (default: [])
% - 'keepOpen' - if set to 1, will keep the connection to the AWG open
%              after downloading the waveform
% - 'run' - determines if the AWG will be started immediately after
%              downloading the waveform/sequence. (default: 1)
%
% If arbConfig is not specified, the file "arbConfig.mat" is expected in
% the current directory.

%% parse optional arguments
segmNum = 1;
result = [];
keepOpen = 0;
normalize = 1;
downloadToChannel{1} = 'I+Q to channel 1+2';
sequence = [];
arbConfig = [];
marker = [];
run = 1;
for i = 1:nargin-2
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'segmentnumber';  segmNum = varargin{i+1};
            case 'keepopen'; keepOpen = varargin{i+1};
            case 'normalize'; normalize = varargin(i+1);
            case 'downloadtochannel'; downloadToChannel = varargin(i+1);
            case 'marker'; marker = varargin{i+1};
            case 'sequence'; sequence = varargin{i+1};
            case 'arbconfig'; arbConfig = varargin{i+1};
            case 'run'; run = varargin{i+1};
        end
    end
end

% if markers are not specified, generate square wave marker signal
if (isempty(marker))
    marker = [15*ones(floor(length(iqdata)/2),1); zeros(length(iqdata)-floor(length(iqdata)/2),1)];
end
% try to load the configuration from the file arbConfig.mat
arbConfig = loadArbConfig(arbConfig);

% make sure the data is in the correct format
if (isvector(iqdata) && size(iqdata,2) > 1)
    iqdata = iqdata.';
end

% normalize if required
if (normalize && ~isempty(iqdata))
    scale = max(max(abs(real(iqdata(:,1)))), max(abs(imag(iqdata(:,1)))));
    if (scale > 1)
        if (normalize)
            iqdata(:,1) = iqdata(:,1) / scale;
        else
            errordlg('Data must be in the range -1...+1', 'Error');
        end
    end
end

%% extract data
    numColumns = size(iqdata, 2);
    if (~isvector(iqdata) && numColumns >= 2)
        data = iqdata(:,1);
    else
        data = reshape(iqdata, numel(iqdata), 1);
    end
    if (isfield(arbConfig, 'amplitudeScaling') && arbConfig.amplitudeScaling ~= 1)
        data = data .* arbConfig.amplitudeScaling;
    end
%% extract markers - assume there are two markers per channel
    marker = reshape(marker, numel(marker), 1);
    marker1 = bitand(uint16(marker),3);
    marker2 = bitand(bitshift(uint16(marker),-2),3);
    
    len = length(data);
    if (mod(len, arbConfig.segmentGranularity) ~= 0)
        errordlg(['Segment length must be a multiple of ' num2str(arbConfig.segmentGranularity)], 'Error');
        return;
    elseif (len < arbConfig.minimumSegmentSize && len ~= 0)
        errordlg(['Segment size must be >= ' num2str(arbConfig.minimumSegmentSize)], 'Error');
        return;
    elseif (len > arbConfig.maximumSegmentSize)
        errordlg(['Segment size must be <= ' num2str(arbConfig.maximumSegmentSize)], 'Error');
        return;
    end
    if (isfield(arbConfig, 'interleaving') && arbConfig.interleaving)
        fs = fs / 2;
        data = real(data);                              % take the I signal
        data = complex(data(1:2:end), data(2:2:end));   % and split it into two channels
        marker1 = marker1(1:2:end);
        marker2 = marker2(1:2:end);
        downloadToChannel{1} = 'I+Q to channel 1+2';
    end
    
%% establish a connection and download the data
    switch (arbConfig.model)
        case { '81180A' '81180B' }
            result = iqdownload_81180A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, downloadToChannel, sequence);
        case { 'M8190A' 'M8190A_base' 'M8190A_14bit' 'M8190A_12bit' 'M8190A_DUC_x3' 'M8190A_DUC_x12' 'M8190A_DUC_x24' 'M8190A_DUC_x48' }
            result = iqdownload_M8190A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, downloadToChannel, sequence, run);
        case 'M8190A_prototype'
            f=fopen('c:\temp\data.csv', 'wt');
            fprintf(f, '%g\n', 0.999 * real(iqdata(:,1)));
            fclose(f);
            return;
        case 'M933xA'
            result = iqdownload_M933xA(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, downloadToChannel, sequence);
        case 'N824xA'
            result = iqdownload_N824xA(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, downloadToChannel, sequence);
        case { '81150A' '81160A' }
            result = iqdownload_81150A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, downloadToChannel, sequence);
        case { 'N51xxA (MXG)' }
            result = iqdownload_N51xxA(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, downloadToChannel, sequence);
        case 'AWG7xxx'
            result = iqdownload_AWG7xxx(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, downloadToChannel, sequence);
        otherwise
            error(['instrument model ' arbConfig.model ' is not supported']);
    end
end
