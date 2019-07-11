function [] = SJ_wavelet_plot(param, result)
ppt = actxserver('PowerPoint.Application');
ppt.Visible = 1;
ppt.WindowState = 2;
op = invoke(ppt.Presentations,'Open',param.clearppt);
slide_count = get(op.Slides,'Count');
if isfield(result, 'wavelet')
    title = 'Wavelet';
    for subjectGroupNum = 1:length(result.groupName)
        for conditionNum = 1:length(param.condition)
            for responseNum = 1:size(result.fileGroup, 3)
                for subConditionNum = 1:size(result.fileGroup, 5)
                    currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                    wavelet{responseNum, subConditionNum} = result.wavelet(logical(currentFile),:,:,:);
                end
            end
            title1 = strcat(title, '\n', result.groupName{subjectGroupNum}, '\t', param.condition{conditionNum});
            for interestChanNum = 1:length(param.interestChannel)
                title2 = strcat(title1, '\t',  param.interestChannel{interestChanNum});
                currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
                
                temp.interestLatencyRegion = (-param.zeroLatency+1/param.fs):(1/param.fs):(param.totalLength-param.zeroLatency);
                
                for freqNum = 1:length(param.freqName)
                    title3 = strcat(title2, '\t', param.freqName{freqNum});
                    
                    temp.interestFreqRegion = find(param.individualFreq{freqNum}(1)==param.freqs):find(param.individualFreq{freqNum}(2)==param.freqs);
                    temp.interestFreqPoint = 1:length(temp.interestFreqRegion);
                    
                    for responseNum = 1:size(result.fileGroup, 3)
                        for subConditionNum = 1:size(result.fileGroup, 5)
                            waveletData{responseNum, subConditionNum} = squeeze(mean(wavelet{responseNum, subConditionNum}(:, currentChanNum, :, temp.interestFreqPoint),1));
                        end
                    end
                    
                    [slide_count, new_slide] = newSlide(op, slide_count, title3);
                    waveletPlot(param, temp, waveletData, new_slide);
                    statisticResult.latencyAverageWavelet
                end
            end
            for latencyNum = 1:length(param.interestLatency)
                title2 = strcat(title1, '\n', param.interestLatencyName{latencyNum});
                
            end
            
        end
    end
end

invoke(op,'SaveAs',param.outfileppt,1);
invoke(op,'Close');
invoke(ppt,'Quit');
delete(ppt);
end

function [slide_count, new_slide] = newSlide(op, slide_count, title)
slide_count = int32(double(slide_count)+1);
new_slide = invoke(op.Slides, 'Add', slide_count, 11);
titletext = sprintf(title);
new_slide.Shapes.Title.TextFrame.TextRange.Text=titletext;
new_slide.Shapes.Title.TextFrame.TextRange.Font.Size=24;
new_slide.Shapes.Title.TextFrame.HorizontalAnchor = 'msoAnchorCenter';
end

function [] = waveletPlot(param, temp, waveletData, new_slide)
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
        
        
        % rectangle('position', pos)? ?? ?? ????
        
        saveas(gcf, param.picture);
        close;
        new_slide.Shapes.AddPicture(char(param.picture),'msoFalse','msoTrue', graphLocationX+graphSizeX*(second-1), graphLocationY+graphSizeY*(first-1), graphSizeX, graphSizeY);
    end
end
end
