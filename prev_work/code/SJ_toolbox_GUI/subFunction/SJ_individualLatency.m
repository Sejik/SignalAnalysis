function [individualLatencyResult] = SJ_individualLatency(param, data)
for individualFreqNum = 1:length(param.individualFreq)
    startTemp = param.interestFreq(1):param.freqStep:param.individualFreq{individualFreqNum}(1);
    endTemp = param.interestFreq(1):param.freqStep:param.individualFreq{individualFreqNum}(2);
    startFreq = length(startTemp);
    endFreq = length(endTemp);
    [~, individualLatencyResult(:,:,individualFreqNum)] = ...
            max(max(data(:,:,:,startFreq:endFreq), [], 4), [], 3);
    % individualLatencyResult(:,:,individualFreqNum) = ...
            % mean(mean(data(:,:,:,startFreq:endFreq), 4), 3);
end
individualLatencyResult = individualLatencyResult/param.fs - param.zeroLatency;
end