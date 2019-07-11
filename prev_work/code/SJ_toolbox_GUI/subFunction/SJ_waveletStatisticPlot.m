function [] = SJ_waveletStatisticPlot(param, result)
cd(param.pptDir);
title1 = 'Wavelet';
for subjectGroupNum = 1:length(result.groupName)
    title2 = strcat(title1, '_', result.groupName{subjectGroupNum});
    for conditionNum = 1:length(param.condition)
        title3 = strcat(title2, '_', param.condition{conditionNum});
        for responseNum = 1:size(result.fileGroup, 3)
            title4 = strcat(title3, '_', num2str(responseNum));
            for subConditionNum = 1:size(result.fileGroup, 5)
                title5 = strcat(title4, '_', param.subCondition{subConditionNum});
                currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                wavelet = result.wavelet(logical(currentFile),:,:,:);
                for interestChanNum = 1:length(param.interestChannel)
                    title6 = strcat(title5, '_', param.interestChannel{interestChanNum}, '.png');
                    currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
                    waveletData = squeeze(mean(wavelet(:, currentChanNum, :, :),1));
                    waveletOnePlot(param, title6, waveletData);
                end
            end
        end
    end
end
close();
end

function [] = waveletOnePlot(param, fileName, waveletData)
T = (-param.zeroLatency):(1/param.fs):(param.totalLength-param.zeroLatency);
F = param.interestFreq(1):param.freqStep:param.interestFreq(2);
S = shiftdim(waveletData, 1);
figure(1);
helperCWTTimeFreqPlot(S,T,F, 'surf', 'waveletResult', 'Seconds', 'Hz');
saveas(gcf, fileName);
end