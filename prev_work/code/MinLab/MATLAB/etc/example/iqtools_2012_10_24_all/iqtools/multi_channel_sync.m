function result = multi_channel_sync(varargin)
% Set up two M8190A modules to run in sync. This function is typically
% called from the multi_channel_sync_gui, but it can also be called from
% other MATLAB functions.
% Parameters are passed as name/value pairs. The following parameter names
% are supported:
% 'sampleRate' - the samplerate that will be used by both M8190A modules
% 'cmd' - can be 'manualDeskew', 'autoDeskew', 'start', 'stop'
% 'arbConfig' - a struct with two arbConfig structs that describes the
%               connection to the two M8190A's
% 'scopeConfig' - struct that describes the access to the scope
% 'useMarkers' - set to 1 if the channel 1 sample markers are used for
%               deskewing instead of the ch1 outputs of each module
% 'slaveClk' - 'extClk' (external sample clock), 'axiRef' (AXI reference clock)
%              or 'extRef' (external reference clock)
% 'triggered' - if set to 1, will generate a single waveform on every
%              trigger event, otherwise will generate continuous signal
% 'waveformID' - see popupmenuWaveform in multi_channel_sync_gui

result = [];
if (nargin == 0)
    multi_channel_sync_gui;
    return;
end
% set default values - will be overwritten by arguments
cmd = '';
sampleRate = 8e9;
clear cfgs;
cfgs{1}.model = 'M8190A_14bit';
cfgs{2}.model = 'M8190A_14bit';
cfgs{1}.connectionType = 'visa';
cfgs{2}.connectionType = 'visa';
cfgs{1}.visaAddr = 'TCPIP0::localhost::hislip4::INSTR';
cfgs{2}.visaAddr = 'TCPIP0::localhost::hislip5::INSTR';
scopeCfg = [];
useMarkers = 0;
slaveClk = 'axiRef';
refSource = 'AXI';
triggered = 0;
waveformID = 1;
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate';     sampleRate = varargin{i+1};
            case 'cmd';            cmd = varargin{i+1};
            case 'arbconfig';      cfgs = varargin{i+1};
            case 'scopeconfig';    scopeCfg = varargin{i+1};
            case 'usemarkers';     useMarkers = varargin{i+1};
            case 'slaveclk';       slaveClk = varargin{i+1};
            case 'triggered';      triggered = varargin{i+1};
            case 'waveformid';     waveformID = varargin{i+1};
            otherwise; error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

% define how to access the two AWG modules in structs awg1 and awg2
% awg1 is the "master" (supplying the sample clock)
% awg2 is the "slave" (receiving the external sample clock from awg1)
awg1 = cfgs{1};
awg2 = cfgs{2};
switch lower(slaveClk)
    case {'extclk' 'external sample clock' }
        awg2.extClk = 1;   % ARB #2 is the slave and will run on external clock
    case {'axiref' 'axi reference clock' }
        refSource = 'AXI';
        awg2.extClk = 0;
    case {'extref' 'external reference clock' }
        refSource = 'EXTernal';
        awg2.extClk = 0;
    otherwise
        error(['unexpected slaveClk parameter: ' slaveClk]);
end

% common sample rate for both AWGs
fs = sampleRate;

switch (cmd)
    case 'manualDeskew'
        result = manualDeskew(fs, awg1, awg2, 1, refSource, useMarkers, 0, 2);
    case 'autoDeskew'
        result = manualDeskew(fs, awg1, awg2, 1, refSource, useMarkers, 0, 2);
        if (isempty(result))
            autoDeskew(awg1, awg2, scopeCfg);
        end
    case 'start'
        result = manualDeskew(fs, awg1, awg2, 0, refSource, useMarkers, triggered, waveformID);
        if (~isempty(scopeCfg))
            setupScope(scopeCfg, waveformID, triggered);
        end
    case 'stop'
        result = doStop(awg1, awg2);
    otherwise
        error('unknown cmd');
end


function result = doStop(awg1, awg2)
% open the connection to the AWGs
f1 = iqopen(awg1);
f2 = iqopen(awg2);
% stop both of them
fprintf(f1, ':abort');
fprintf(f2, ':abort');
fclose(f1);
fclose(f2);
result = [];



function setupScope(scopeCfg, waveformID, triggered)
% connect to scope
fscope = iqopen(scopeCfg);
if (isempty(fscope))
    return;
end
xfprintf(fscope, ':meas:clear');
if (waveformID == 3)
    if (triggered)
        xfprintf(fscope, sprintf(':timebase:scal %g', 5e-6));
    else
        xfprintf(fscope, sprintf(':timebase:scal %g', 50e-9));
    end
end
fclose(fscope);


function result = manualDeskew(fs, awg1, awg2, doDeskew, refSource, useMarkers, triggered, waveformID)
dummySegNum = 2;
testSegNum = 1;
% open the connection to the AWGs
f1 = iqopen(awg1);
f2 = iqopen(awg2);
% turn channel coupling on (in case it is not already on)
fprintf(f1, ':inst:coup:stat1 on');
fprintf(f2, ':inst:coup:stat1 on');
% stop both of them
fprintf(f1, ':abort');
fprintf(f2, ':abort');
fprintf(f2, sprintf(':ROSCillator:FREQuency %g', 100e6));
fprintf(f2, sprintf(':ROSCillator:SOURce %s', refSource));
% set marker levels if we are using markers
if (useMarkers && doDeskew)
    fprintf(f1, sprintf(':MARKer1:SAMPle:VOLTage:OFFSet %g; AMPLitude %g', 0, 0.5));
    fprintf(f2, sprintf(':MARKer1:SAMPle:VOLTage:OFFSet %g; AMPLitude %g', 0, 0.5));
end

% switch AWG2 to internal clock temporarily to avoid clock loss
% but only if we actually perform deskew - not for simple start/stop
if (doDeskew)
    fprintf(f2, sprintf(':FREQuency:RASTer:SOURce INTernal; :FREQuency:RASTer %.15g', fs));
end

%% set up AWG #1 -------------------------------------------------------
% delete all waveform segments
if (waveformID ~= 1)
    iqseq('delete', [], 'arbConfig', awg1, 'keepOpen', 1);
end
% create a "dummy" segment, that compensates the trigger delay.
% Fine delay can be adjusted using the Soft Front Panel
% (Ultimately, the deskew process should be automated)
% Trigger delay will be approx. 160 sequence clock cycles plus 
% some fixed delay due to the trigger cable
% One sequence clock cycle is 48 resp. 64 sample clocks.
% We also have have to take care of the linear playtime restriction
% of >256 sequence clock cycles.
fixDelay = 24e-9;
n1 = 257 * awg1.segmentGranularity;
n2 = n1 + (160 + round(fixDelay * fs / awg1.segmentGranularity)) * awg1.segmentGranularity;
dummySegment = zeros(1, n2);
% now create the real waveform segment, resp. the "test" segment which
% can be used to measure the skew
switch (waveformID)
    case 1  % use exising segment #1
        testSegment1 = [];
        testSegment2 = [];
    case 2  % test segment
        t1 = iqpulsegen('arbConfig', awg1, 'sampleRate', fs, 'pw', 240, 'rise', 0, 'fall', 0, 'off', [0 19200], 'high', [-1 1], 'low', 0);
        testSegment1 = complex(real(t1), real(t1));
        testSegment2 = testSegment1;
    case 3  % pulse followed by sinewave
        n = 192;
        clear t;
        for i=1:4
            t(i,:) = [-1*ones(1,n) ones(1,n) zeros(1,i*n) sin(2*pi*(1:n)/n) zeros(1,(6-i)*n)];
        end
        testSegment1 = complex(t(1,:), t(2,:));
        testSegment2 = complex(t(3,:), t(4,:));
    case 4  % sine waves with different phases
        clear t;
        for i=1:4
            t(i,:) = iqpulse('sampleRate', fs, 'pri', 4e-6, 'pw', 2e-6, 'phase', 45*i, 'offset', 200e6, 'span', 300e6);
        end
        testSegment1 = complex(real(t(1,:)), real(t(2,:)));
        testSegment2 = complex(real(t(3,:)), real(t(4,:)));
    otherwise
        error(['unexpected waveformID: ' num2str(waveformID)]);
end
% download the waveforms into AWG1, but don't start the AWG yet (run=0)
% also, keep the connection open to speed up the download process
if (~isempty(testSegment1))
    iqdownload(testSegment1, fs, 'arbConfig', awg1, 'keepOpen', 1, 'run', 0, 'segmentNumber', testSegNum);
end
iqdownload(dummySegment, fs, 'arbConfig', awg1, 'keepOpen', 1, 'run', 0, 'segmentNumber', dummySegNum);

%% set up ARB #2 -------------------------------------------------------
% delete all segments
if (waveformID ~= 1)
    iqseq('delete', [], 'arbConfig', awg2, 'keepOpen', 1, 'run', 0);
end
% shorter dummy segment in the second AWG because by the time it receives
% the trigger, the first AWG was already running for some time
dummySegment = zeros(1, n1);
if (~isempty(testSegment2))
    iqdownload(testSegment2, fs, 'arbConfig', awg2, 'keepOpen', 1, 'run', 0, 'segmentNumber', testSegNum);
end
iqdownload(dummySegment, fs, 'arbConfig', awg2, 'keepOpen', 1, 'run', 0, 'segmentNumber', dummySegNum);

%% now set up the sequence table (the same table will be used for both
% modules).  Data is entered into a struct and then passed to iqseq()
clear seq;
% dummy segment once
i = 1;
seq(i).segmentNumber = dummySegNum;
seq(i).segmentLoops = 1;
seq(i).markerEnable = 1;    % marker to start the slave module
i = i + 1;
% the test segment
seq(i).segmentNumber = testSegNum;
seq(i).segmentLoops = 1;
seq(i).markerEnable = 1;
if (triggered)
    seq(i).segmentAdvance = 'Auto';
else
    seq(i).segmentAdvance = 'Conditional';
end
i = i + 1;
% the dummy segment
seq(i).segmentNumber = dummySegNum;
seq(i).segmentLoops = 1;
seq(i).segmentAdvance = 'Auto';
iqseq('define', seq, 'arbConfig', awg1, 'keepOpen', 1, 'run', 0);
iqseq('define', seq, 'arbConfig', awg2, 'keepOpen', 1, 'run', 0);

% set AWG #1 to triggered or continuous - depending on user selection
iqseq('triggerMode', triggered, 'arbConfig', awg1, 'keepopen', 1);
% turn on triggered mode in AWG #2 in any case
iqseq('triggerMode', 'triggered', 'arbConfig', awg2, 'keepopen', 1);
% and run (i.e. wait for trigger)
iqseq('mode', 'STS', 'arbConfig', awg2, 'keepopen', 1);
% wait until AWG #2 has started (make sure it is ready to respond to the trigger)
query(f2, '*opc?');
% now start AWG #1 which will generate a SYNC marker and trigger AWG #2
iqseq('mode', 'STS', 'arbConfig', awg1, 'keepopen', 1);

fclose(f1);
fclose(f2);
result = [];


function result = autoDeskew(awg1, awg2, scopeCfg)
result = [];
% connect to AWGs
f1 = iqopen(awg1);
f2 = iqopen(awg2);
% connect to scope
fscope = iqopen(scopeCfg);
if (isempty(fscope))
    result = 'can''t connect to scope';
    return;
end

% define on which channels the scope should compare signals
ch = [1 2];
% scope timebase scales for the three successive measurements
timebase = [100e-9 100e-12 20e-12];
% delay (in sec) to allow scope to take sufficient number of measurements
measDelay = [.1 2 1];
if (isempty(initScopeMeasurement(fscope, ch)))
    return;
end
% start with a default fine delay of 15ps so that it can be adjusted in
% either direction
defaultCdel = 0;
defaultFdel = 15e-12;
% initialize AWG delay
setAWGDelay(f1, defaultCdel, defaultFdel);
setAWGDelay(f2, defaultCdel, defaultFdel);
% perform first measurement to determine coarse delay
cdel = doScopeMeasurement(fscope, ch, timebase(1), measDelay(1));
if (isempty(cdel))
    return;
end
if (abs(cdel) + abs(defaultCdel) > 10e-9)
    errordlg({sprintf('Skew is too large for the built-in delay line (%g).', abs(cdel)) ...
            'Please make sure that you have connected the AWG outputs' ...
            'to the scope according to the connection diagram.'});
    return;
end
% determine which channel to delay
if (cdel < 0)
    cdel1 = defaultCdel;
    cdel2 = defaultCdel - cdel;
else
    cdel1 = defaultCdel + cdel;
    cdel2 = defaultCdel;
end
setAWGDelay(f1, cdel1, defaultFdel);
setAWGDelay(f2, cdel2, defaultFdel);
% now measure again with higher resolution
fdel = doScopeMeasurement(fscope, ch, timebase(2), measDelay(2));
if (isempty(fdel))
    return;
end
if (abs(fdel) > 15e-12)
    errordlg(sprintf('Delay after first correction too large: %g', fdel));
    return;
end
% apply the fine delay to the same module that carries the coarse delay
if (cdel < 0)
    fdel1 = defaultFdel;
    fdel2 = defaultFdel - fdel;
else
    fdel1 = defaultFdel + fdel;
    fdel2 = defaultFdel;
end
setAWGDelay(f1, cdel1, fdel1);
setAWGDelay(f2, cdel2, fdel2);
% measure again to verify that the remaining delay is neglectable
result = doScopeMeasurement(fscope, ch, timebase(3), measDelay(3));
xfprintf(fscope, sprintf(':acquire:average off'));
%if (~isempty(result) && result < 10e-12)
%    msgbox(sprintf('Successfully deskewed - remaining skew: %g ps', result * 1e12));
%end



function setAWGDelay(f, cdel, fdel)
xfprintf(f, sprintf(':arm:cdel1 %g', cdel));
xfprintf(f, sprintf(':arm:del1 %g', fdel));
xfprintf(f, sprintf(':arm:cdel2 %g', cdel));
xfprintf(f, sprintf(':arm:del2 %g', fdel));


function result = initScopeMeasurement(fscope, ch)
result = [];
xfprintf(fscope, '*rst');
xfprintf(fscope, ':syst:head off');
for i = 1:length(ch)
    xfprintf(fscope, sprintf(':chan%d:disp on', ch(i)));
end
offch = setdiff([1 2 3 4], ch);
for i = 1:length(offch)
    xfprintf(fscope, sprintf(':chan%d:disp off', offch(i)));
end
timebase = 10e-9;
xfprintf(fscope, sprintf(':timebase:scal %g', timebase));
offs = 0;
scale = 200e-3;
for i = 1:length(ch)
    xfprintf(fscope, sprintf(':chan%d:offs %g', ch(i), offs));
    xfprintf(fscope, sprintf(':chan%d:scale %g', ch(i), scale));
end
trigLev = 0;
xfprintf(fscope, sprintf(':trig:mode edge'));
xfprintf(fscope, sprintf(':trig:edge:slope positive'));
xfprintf(fscope, sprintf(':trig:lev chan1,%g', trigLev));
xfprintf(fscope, ':run');
res = query(fscope, 'ader?');
if (eval(res) ~= 1)
    % try one more time
    res = query(fscope, 'ader?');
    if (eval(res) ~= 1)
        res = questdlg('Please verify that the scope captures the waveform correctly and press OK','Scope','OK','Cancel','OK');
        if (~strcmp(res, 'OK'))
            fclose(fscope);
            return;
        end
    end
end
xfprintf(fscope, ':meas:deltatime:def rising,1,middle,rising,1,middle');
xfprintf(fscope, sprintf(':meas:thresholds:absolute chan%d,+0.1,0,-0.1', ch(1)));
xfprintf(fscope, sprintf(':meas:thresholds:absolute chan%d,+0.1,0,-0.1', ch(2)));
xfprintf(fscope, sprintf(':meas:thresholds:method chan%d,absolute', ch(1)));
xfprintf(fscope, sprintf(':meas:thresholds:method chan%d,absolute', ch(2)));
%xfprintf(fscope, sprintf(':acquire:average:count 8'));
%xfprintf(fscope, sprintf(':acquire:average on'));
result = 1;



function result = doScopeMeasurement(fscope, ch, timebase, measDelay)
result = [];
xfprintf(fscope, sprintf(':timebase:scal %g', timebase));
doMeasAgain = 1;
while (doMeasAgain)
    xfprintf(fscope, sprintf(':meas:clear'));
    xfprintf(fscope, sprintf(':meas:deltatime chan%d,chan%d', ch(1), ch(2)));
    xfprintf(fscope, sprintf(':meas:stat on'));
    pause(measDelay);
    query(fscope, 'ader?');
    measStr = query(fscope, ':meas:results?');
    measList = eval(['[' measStr(11:end-1) ']']);
%    fprintf(sprintf('Result: %s\n', measStr));
    meas = measList(4);   % mean
    if (abs(meas) > 1e37)
        errordlg({'Invalid scope measurement: ' measStr ' ' ...
            'Please make sure that you have connected the AWG outputs' ...
            'to the scope according to the connection diagram.'});
        return;
    end
    if (abs(measList(3) - measList(2)) > 100e-12)   % max - min
        res = questdlg({'The scope returns delta time measurements with large variations.' ...
                       'Please verify that the slave clock source is set correctly and the' ...
                       'scope shows a steady waveform. Then press OK' },'Scope','OK','Cancel','OK');
        if (~strcmp(res, 'OK'))
            fclose(fscope);
            return;
        end
    else
        doMeasAgain = 0;
    end
    result = meas;
end



function retVal = xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status
% if ignoreError is set, the result of :syst:err is ignored
% returns 0 for success, -1 for errors
    retVal = 0;
    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        fprintf('cmd = %s\n', s);
    end
    fprintf(f, s);
    result = query(f, ':syst:err?');
    if (isempty(result))
        fclose(f);
        errordlg({'The instrument did not respond to a :SYST:ERRor query.' ...
            'Please check that the firmware is running and responding to commands.'}, 'Error');
        retVal = -1;
        return;
    end
    if (~exist('ignoreError', 'var') || ignoreError == 0)
        if (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12) && ~strncmp(result, '0', 1))
            errordlg({'Instrument returns an error on command:' s 'Error Message:' result});
            retVal = -1;
        end
    end

