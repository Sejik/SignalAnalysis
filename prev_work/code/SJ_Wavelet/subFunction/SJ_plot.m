function [] = SJ_plot(param, result)
if isfield(result, 'wavelet')
    title = 'Wavelet';
    for subjectGroupNum = 1:length(result.groupName)
        for conditionNum = 1:length(param.condition)
            for responseNum = 1:size(result.fileGroup, 3)
                for subConditionNum = 1:size(result.fileGroup, 5)
                    currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                    wavelet{responseNum, subConditionNum} = result.raw(logical(currentFile),:,:,:);
                end
            end
            
            title1 = strcat(title, '\n', result.groupName{subjectGroupNum}, '\t', param.condition{conditionNum});
            for interestChanNum = 1:length(param.interestchannel)
                title2 = strcat(title1, '\t',  param.interestChannel{interestChanNum});
                for responseNum = 1:size(result.fileGroup, 3)
                    for subConditionNum = 1:size(result.fileGroup, 5)
                        waveletData{responseNum, subConditionNum} = squeeze(mean(wavelet{responseNum, subConditionNum}(:, currentChanNum, :, :),1));
                        
                    end
                end
                
            end
            
            waveletPlot(param, temp, waveletData, title4);
        end
    end
end
end

function [] = waveletPlot(param, temp, waveletData, name)
waveletMean = [waveletData{1,1}; waveletData{1,2}; waveletData{1,3}; waveletData{2,1}; waveletData{2,2}; waveletData{2,3}];
waveletMeanMax = mean(waveletMean(:)) + std(waveletMean(:));
waveletMeanMin = min(waveletMean(:));

graphLocationX = 25;
graphLocationY = 120;
graphSizeX = 900/size(waveletData,2);
graphSizeY = 400/size(waveletData,1);

T = temp.interestLatencyRegion;
F = temp.interestFreqRegion';

for first = 1:size(waveletData,1)
    for second = 1:size(waveletData,2)
        S = shiftdim(waveletData{first, second},1);
        helperCWTTimeFreqPlot(S,T,F, 'surf', 'waveletResult', 'Seconds', 'Hz');
        set(gca, 'CLim', [waveletMeanMin waveletMeanMax]);
        
        saveas(gcf, param.picture);
        close;
        new_slide.Shapes.AddPicture(char(param.picture),'msoFalse','msoTrue', graphLocationX+graphSizeX*(second-1), graphLocationY+graphSizeY*(first-1), graphSizeX, graphSizeY);
    end
end
end
