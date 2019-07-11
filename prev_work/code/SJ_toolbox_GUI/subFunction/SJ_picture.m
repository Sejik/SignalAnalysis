function [] = SJ_picture(param, result)
if isfield(result, 'fft') && isfield(result, 'fftIndividualFreq')
    title = 'FFT';
    for subjectGroupNum = 1:length(result.groupName)
        for conditionNum = 1:length(param.condition)
            for responseNum = 1:size(result.fileGroup, 3)
                for subConditionNum = 1:size(result.fileGroup, 5)
                    currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                    fftRaw{responseNum, subConditionNum} = result.fft(logical(currentFile),:,:,:);
                end
            end
            title1 = strcat(title, '_', result.groupName{subjectGroupNum}, '_', param.condition{conditionNum});
            for latencyNum = 1:length(param.interestLatency)
                title2 = strcat(title1, '_', param.interestLatencyName{latencyNum});
                for interestChanNum = 1:length(param.interestChannel)
                    title3 = strcat(title2, '_',  param.interestChannel{interestChanNum});
                    currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
                    
                    temp.interestRegion = param.freqs;
                    temp.interestPoint = 1:length(param.freqs);
                    
                    for responseNum = 1:size(result.fileGroup, 3)
                        for subConditionNum = 1:size(result.fileGroup, 5)
                            graphData{responseNum, subConditionNum} = squeeze((fftRaw{responseNum, subConditionNum}(:, currentChanNum, latencyNum, temp.interestPoint)));
                        end
                    end
                    
                    titleFirst = strcat(title3, '_FirstPlot');
                    titleSecond = strcat(title3, '_SecondPlot');
                    twoDimensionPlot(param, temp, graphData, titleFirst, titleSecond);
                end
            end
        end
    end
end
end

function [] = twoDimensionPlot(param, temp, graphData,  titleFirst, titleSecond)
temp.interestRegion = param.freqs;
temp.interestPoint = 1:length(param.freqs);
% subject * frequency
graphMean = [graphData{1,1}; graphData{1,2}; graphData{2,1}; graphData{2,2}]; % graphData{1,3}; graphData{2,1}; graphData{2,2}; graphData{2,3}];
graphMeanMax = max(graphMean(:)) + std(graphMean(:)) * 3;
graphMeanMin = min(graphMean(:)) - std(graphMean(:)) * 3;

x = temp.interestRegion;
for first = 1:size(graphData,1)
    figure('OuterPosition', [750 500 1000 500]);
    subplot('position', [0.1 0.1 0.8 0.8]);
    hold on
    for second = 1:size(graphData,2)
        if second == 1
            lineStyle = {'-r', 'lineWidth', 3.0};
        elseif second == 2
            lineStyle = {'-g', 'lineWidth', 3.0};
        else
            lineStyle = {'-k', 'lineWidth', 3.0};
        end
        y = graphData{first, second};
        shadedErrorBar(x,y,{@mean,@std},lineStyle,1);
        xlim([x(1) x(end)]);
        ylim([graphMeanMin graphMeanMax]);
    end
    hold off
    saveas(gcf, strcat(titleFirst, '_', param.subCondition{first}, '.png'));
    close;
end

for second = 1:size(graphData,2)
    figure('OuterPosition', [750 500 1000 500]);
    subplot('position', [0.1 0.1 0.8 0.8]);
    hold on
    for first = 1:size(graphData,1)
        if first == 1
            lineStyle = {'-r', 'lineWidth', 3.0};
        elseif first == 2
            lineStyle = {'-g', 'lineWidth', 3.0};
        else
            lineStyle = {'-k', 'lineWidth', 3.0};
        end
        y = graphData{first, second};
        shadedErrorBar(x,y,{@mean,@std},lineStyle,1);
        xlim([x(1) x(end)]);
        ylim([graphMeanMin graphMeanMax]);
    end
    hold off
    saveas(gcf, strcat(titleSecond, '_', num2str(second), '.png'));
    close;
end
end