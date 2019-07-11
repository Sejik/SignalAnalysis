function [individualFreqResult] = SJ_individualFreq(param, data)
for individualFreqNum = 1:length(param.individualFreq)
    startTemp = param.interestFreq(1):param.freqStep:param.individualFreq{individualFreqNum}(1);
    endTemp = param.interestFreq(1):param.freqStep:param.individualFreq{individualFreqNum}(2);
    startFreq = length(startTemp);
    endFreq = length(endTemp);
    individualFreqResult(:,:,:,individualFreqNum) = max(data(:,:,:,startFreq:endFreq),[], 4);
end
end