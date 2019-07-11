function seqtest1()
% Demonstration of M8190A sequencing capabilities
% with focus on time domain. Output is best viewed on an oscilloscope.
% This demo can also be used to show dynamic sequencing (see line 66)
%
% Instrument Configuration has to be set up using IQtools config dialog

% make sure that we can connect to the M8190A and have the right licenses
if (~iqoptcheck([], 'bit', 'SEQ'))
    return;
end
f = iqopen();
fprintf(f, ':abort');

% define the sample rate
fs = 8e9;
% set up a couple of waveform segments
% single pulse
s1 = iqpulsegen('pw', 1920, 'off', 1920, 'rise', 0, 'fall', 0);
% noise
s2 = rand(3840, 1) - 0.5;
% a triangle waveform
s3 = iqpulsegen('pw', 0, 'off', 0, 'rise', 960, 'fall', 960, 'high', [0.5 -0.5], 'low', 0);
% a sinusoidal waveform
s4 = 0.75*sin(2*pi*(1:3840)/3840);

loadSegments = 1;
if (loadSegments)
    % start from scratch and delete all segments
    iqseq('delete', [], 'keepOpen', 1);
    % download the waveform segments - identical data on channel 1 and 2
    iqdownload(complex(real(s1), real(s1)), fs, 'segmentNumber', 1, 'keepOpen', 1, 'run', 0);
    iqdownload(complex(real(s2), real(s2)), fs, 'segmentNumber', 2, 'keepOpen', 1, 'run', 0);
    iqdownload(complex(real(s3), real(s3)), fs, 'segmentNumber', 3, 'keepOpen', 1, 'run', 0);
    iqdownload(complex(real(s4), real(s4)), fs, 'segmentNumber', 4, 'keepOpen', 1, 'run', 0);
end

setupSequence = 1;
if (setupSequence)
    % and set up the sequence
    advanceMode = 'Auto';       % replace 'Auto' with 'Conditional' to show
                                % how the sequencer can wait for an event.
                                % You can press the "Force Event" button
                                % or apply a signal to the Event input
                                % to trigger the event
    clear seq;
    seq(1).segmentNumber = 1;
    seq(1).segmentLoops = 1;
    seq(1).markerEnable = true;
    seq(1).segmentAdvance = advanceMode;
    
    seq(2).segmentNumber = 2;
    seq(2).segmentLoops = 3;
    seq(2).segmentAdvance = advanceMode;
    
    seq(3).segmentNumber = 3;
    seq(3).segmentLoops = 3;
    seq(3).segmentAdvance = advanceMode;
    
    seq(4).segmentNumber = 4;
    seq(4).segmentLoops = 3;
    seq(4).segmentAdvance = advanceMode;
    iqseq('define', seq, 'keepOpen', 1);
end

dyn = 1;    % set dyn=1 to enable dynamic switching between segments
if (dyn)
    fprintf(f, ':abort');
    fprintf(f, ':func1:mode arb');
    fprintf(f, ':func2:mode arb');
    fprintf(f, ':stab1:dyn on');
    fprintf(f, ':stab2:dyn on');
    fprintf(f, ':init:imm');
    % select a couple of segments - alternatively, use dynamic sequence
    % control connector
    fprintf(f, ':stab:dyn:sel 2');
    pause(2);
    fprintf(f, ':stab:dyn:sel 1');
    pause(2);
    fprintf(f, ':stab:dyn:sel 0');
    pause(2);
    fprintf(f, ':stab:dyn:sel 3');
end

%fprintf(sprintf('Result = %s', query(f, ':syst:err?')));
fclose(f);
end