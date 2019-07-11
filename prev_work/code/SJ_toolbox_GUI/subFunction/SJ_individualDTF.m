function [individualDTFResult] = SJ_individualDTF(param, data)
for individualFreqNum = 1:length(param.individualFreq)
    startTemp = param.interestFreq(1):param.individualFreq{individualFreqNum}(1);
    endTemp = param.interestFreq(1):param.individualFreq{individualFreqNum}(2);
    startFreq = length(startTemp);
    endFreq = length(endTemp);
    tempIndividualDTFResult(:,:,:,:, individualFreqNum) = squeeze(mean(data(:,:,startFreq:endFreq,:,:),3));
end
individualDTFResult = permute(tempIndividualDTFResult, [1 2 5 3 4]);
end