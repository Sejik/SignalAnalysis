function [] = SJ_plot(param, result)
ppt = actxserver('PowerPoint.Application');
ppt.Visible = 1;
ppt.WindowState = 2;
op = invoke(ppt.Presentations,'Open',param.clearppt);
slide_count = get(op.Slides,'Count');

if isfield(result, 'raw') && isfield(result, 'erp')
    title = 'ERP';
    if param.plotERPfilter
        [b a] = butter(8, param.plotERPfilter/(param.fs/2));
    end    
    for subjectGroupNum = 1:length(result.groupName)
        for conditionNum = 1:length(param.condition)
            for responseNum = 1:size(result.fileGroup, 3)
                for subConditionNum = 1:size(result.fileGroup, 5)
                    currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                    erp{responseNum, subConditionNum} = result.erp(logical(currentFile),:,:);
                    raw{responseNum, subConditionNum} = result.raw(logical(currentFile),:,:);
                end
            end
            title1 = strcat(title, '\n', result.groupName{subjectGroupNum}, '\t', param.condition{conditionNum});
            for latencyNum = 1:length(param.interestLatency)
                title2 = strcat(title1, '\n', param.interestLatencyName{latencyNum});
                [slide_count, new_slide] = newSlide(op, slide_count, title2);
                temp.barLocationX = 500;
                temp.barLocationY = 140;
                temp.graphLocationX = 300;
                temp.graphLocationY = 120;
                for responseNum = 1:size(result.fileGroup, 3)
                    for subConditionNum = 1:size(result.fileGroup, 5)
                        mappingData{responseNum, subConditionNum} = mean(erp{responseNum, subConditionNum}(:,1:length(param.rawChannel),latencyNum),1);
                    end
                end
                mappingDataTotal = [mappingData{1,1}; mappingData{1,2}; mappingData{1,3}; mappingData{2,1}; mappingData{2,2}; mappingData{2,3}];
                temp.mappingMean = mean(mappingDataTotal(:), 'omitnan');
                temp.mappingSTD = std(mappingDataTotal(:), 'omitnan');
                mappingPlot(param, temp, mappingData, new_slide);
                for interestChanNum = 1:length(param.interestChannel)
                    title3 = strcat(title2, '\t',  param.interestChannel{interestChanNum});
                    currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
                    
                    temp.interestRegion = (param.interestLatency{latencyNum}(1)+1/param.fs):(1/param.fs):param.interestLatency{latencyNum}(2);
                    temp.interestPoint = ((param.zeroLatency+param.interestLatency{latencyNum}(1))*param.fs+1):((param.zeroLatency+param.interestLatency{latencyNum}(2))*param.fs);
                    
                    for responseNum = 1:size(result.fileGroup, 3)
                        for subConditionNum = 1:size(result.fileGroup, 5)
                            if param.plotERPfilter
                                graphData{responseNum, subConditionNum} = filtfilt(b,a,squeeze(mean(raw{responseNum, subConditionNum}(:, currentChanNum, temp.interestPoint),1)));
                            else
                                graphData{responseNum, subConditionNum} = squeeze(mean(raw{responseNum, subConditionNum}(:, currentChanNum, temp.interestPoint),1));
                            end
                        end
                    end
                    
                    [slide_count, new_slide] = newSlide(op, slide_count, title3);
                    twoDimensionFirstPlot(param, temp, graphData, new_slide);
                    
                    [slide_count, new_slide] = newSlide(op, slide_count, title3);
                    twoDimensionSecondPlot(param, temp, graphData, new_slide);
                end
            end
        end
    end
end

if isfield(result, 'fft') && isfield(result, 'fftIndividualFreq')
    title = 'FFT';
    for subjectGroupNum = 1:length(result.groupName)
        for conditionNum = 1:length(param.condition)
            for responseNum = 1:size(result.fileGroup, 3)
                for subConditionNum = 1:size(result.fileGroup, 5)
                    currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                    fftIndividualFreq{responseNum, subConditionNum} = result.fftIndividualFreq(logical(currentFile),:,:,:);
                    fftRaw{responseNum, subConditionNum} = result.fft(logical(currentFile),:,:,:);
                end
            end
            title1 = strcat(title, '\n', result.groupName{subjectGroupNum}, '\t', param.condition{conditionNum});
            for latencyNum = 1:length(param.interestLatency)
                title2 = strcat(title1, '\n', param.interestLatencyName{latencyNum});
                for freqNum = 1:length(param.freqName)
                    title3 = strcat(title2, '\t', param.freqName{freqNum});
                    [slide_count, new_slide] = newSlide(op, slide_count, title3);
                    temp.barLocationX = 500;
                    temp.barLocationY = 140;
                    temp.graphLocationX = 300;
                    temp.graphLocationY = 120;
                    for responseNum = 1:size(result.fileGroup, 3)
                        for subConditionNum = 1:size(result.fileGroup, 5)
                            mappingData{responseNum, subConditionNum} = mean(fftIndividualFreq{responseNum, subConditionNum}(:,1:length(param.rawChannel),latencyNum, freqNum),1);
                        end
                    end
                    mappingDataTotal = [mappingData{1,1}; mappingData{1,2}; mappingData{1,3}; mappingData{2,1}; mappingData{2,2}; mappingData{2,3}];
                    temp.mappingMean = mean(mappingDataTotal(:), 'omitnan');
                    temp.mappingSTD = std(mappingDataTotal(:), 'omitnan');
                    mappingPlot(param, temp, mappingData, new_slide);
                end
                for interestChanNum = 1:length(param.interestChannel)
                    title3 = strcat(title2, '\t',  param.interestChannel{interestChanNum});
                    currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
                    
                    temp.interestRegion = param.freqs;
                    temp.interestPoint = 1:length(param.freqs);
                    
                    for responseNum = 1:size(result.fileGroup, 3)
                        for subConditionNum = 1:size(result.fileGroup, 5)
                            
                            graphData{responseNum, subConditionNum} = squeeze(mean(fftRaw{responseNum, subConditionNum}(:, currentChanNum, latencyNum, temp.interestPoint),1));
                        end
                    end
                    
                    [slide_count, new_slide] = newSlide(op, slide_count, title3);
                    twoDimensionFirstPlot(param, temp, graphData, new_slide);
                    
                    [slide_count, new_slide] = newSlide(op, slide_count, title3);
                    twoDimensionSecondPlot(param, temp, graphData, new_slide);
                end
            end
        end
    end
end

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
            for latencyNum = 1:length(param.interestLatency)
                title2 = strcat(title1, '\n', param.interestLatencyName{latencyNum});
                for interestChanNum = 1:length(param.interestChannel)
                    title3 = strcat(title2, '\t',  param.interestChannel{interestChanNum});
                    currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
                    
                    temp.interestLatencyRegion = (param.interestLatency{latencyNum}(1)+1/param.fs):(1/param.fs):param.interestLatency{latencyNum}(2);
                    temp.interestLatencyPoint = ((param.zeroLatency+param.interestLatency{latencyNum}(1))*param.fs+1):((param.zeroLatency+param.interestLatency{latencyNum}(2))*param.fs);
                    
                    for freqNum = 1:length(param.freqName)
                        title4 = strcat(title3, '\t', param.freqName{freqNum});
                        
                        temp.interestFreqRegion = find(param.individualFreq{freqNum}(1)==param.freqs):find(param.individualFreq{freqNum}(2)==param.freqs);
                        temp.interestFreqPoint = 1:length(temp.interestFreqRegion);
                        
                        for responseNum = 1:size(result.fileGroup, 3)
                            for subConditionNum = 1:size(result.fileGroup, 5)
                                waveletData{responseNum, subConditionNum} = squeeze(mean(wavelet{responseNum, subConditionNum}(:, currentChanNum, temp.interestLatencyPoint, temp.interestFreqPoint),1));
                            end
                        end
                        
                        [slide_count, new_slide] = newSlide(op, slide_count, title4);
                        waveletPlot(param, temp, waveletData, new_slide);
                    end
                end
            end
        end
    end
end

if isfield(result, 'dipole')
    title = 'Dipole';
    for subjectGroupNum = 1:length(result.groupName)
        for conditionNum = 1:length(param.condition)
            for responseNum = 1:size(result.fileGroup, 3)
                for subConditionNum = 1:size(result.fileGroup, 5)
                    currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                    dipole{responseNum, subConditionNum} = result.dipole(logical(currentFile),:,:,:);
                end
            end
            title1 = strcat(title, '\n', result.groupName{subjectGroupNum}, '\t', param.condition{conditionNum});
            for latencyNum = 1:length(param.interestLatency)
                title2 = strcat(title1, '\n', param.interestLatencyName{latencyNum});
                
                for responseNum = 1:size(result.fileGroup, 3)
                    for subConditionNum = 1:size(result.fileGroup, 5)
                        allDipoleData{responseNum, subConditionNum} = squeeze(dipole{responseNum, subConditionNum}(:, latencyNum, :, :));
                    end
                end
                
                [slide_count, new_slide] = newSlide(op, slide_count, title2);
                
                allDipolePlot(param, allDipoleData, new_slide);
                
                for responseNum = 1:size(result.fileGroup, 3)
                    for subConditionNum = 1:size(result.fileGroup, 5)
                        dipoleData{responseNum, subConditionNum} = squeeze(mean(dipole{responseNum, subConditionNum}(:, latencyNum, :, :),1));
                    end
                end
                
                [slide_count, new_slide] = newSlide(op, slide_count, title2);
                
                dipolePlot(param, dipoleData, new_slide);
            end
        end
    end
end

if isfield(result, 'cfc')
    title = 'CFC';
    for subjectGroupNum = 1:length(result.groupName)
        for conditionNum = 1:length(param.condition)
            for responseNum = 1:size(result.fileGroup, 3)
                for subConditionNum = 1:size(result.fileGroup, 5)
                    currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                    cfc{responseNum, subConditionNum} = result.cfc(logical(currentFile),:,:,:,:);
                end
            end
            title1 = strcat(title, '\n', result.groupName{subjectGroupNum}, '\t', param.condition{conditionNum});
            for latencyNum = 1:length(param.interestLatency)
                title2 = strcat(title1, '\n', param.interestLatencyName{latencyNum});
                for interestChanNum = 1:length(param.interestChannel)
                    title3 = strcat(title2, '\t',  param.interestChannel{interestChanNum});
                    currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
                    
                    for responseNum = 1:size(result.fileGroup, 3)
                        for subConditionNum = 1:size(result.fileGroup, 5)
                            cfcData{responseNum, subConditionNum} = squeeze(mean(cfc{responseNum, subConditionNum}(:, currentChanNum, latencyNum, :, :),1, 'omitnan'));
                        end
                    end
                    
                    [slide_count, new_slide] = newSlide(op, slide_count, title3);
                    cfcPlot(param, cfcData, new_slide);
                end
            end
        end
    end
end

if isfield(result, 'dtf')
    title = 'DTF';
    for subjectGroupNum = 1:length(result.groupName)
        for conditionNum = 1:length(param.condition)
            for responseNum = 1:size(result.fileGroup, 3)
                for subConditionNum = 1:size(result.fileGroup, 5)
                    currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                    dtf{responseNum, subConditionNum} = result.dtf(logical(currentFile),:,:,:,:);
                end
            end
            title1 = strcat(title, '\n', result.groupName{subjectGroupNum}, '\t', param.condition{conditionNum});
            for latencyNum = 1:length(param.interestLatency)
                title2 = strcat(title1, '\n', param.interestLatencyName{latencyNum});
                for freqNum = 1:length(param.freqName)
                    title3 = strcat(title2, '\t', param.freqName{freqNum});
                    minf = param.individualFreq{freqNum}(1) - param.interestFreq(1) + 1;
                    maxf = param.individualFreq{freqNum}(2) - param.interestFreq(1) + 1;
                    for responseNum = 1:size(result.fileGroup, 3)
                        for subConditionNum = 1:size(result.fileGroup, 5)
                            dtfData{responseNum, subConditionNum} = squeeze(mean(mean(dtf{responseNum, subConditionNum}(:, latencyNum, minf:maxf, :,:),1, 'omitnan'),3, 'omitnan'));
                            dtfData{responseNum, subConditionNum}(isnan(dtfData{responseNum, subConditionNum})) = 0;
                        end
                    end
                    [slide_count, new_slide] = newSlide(op, slide_count, title3);
                    dtfPlot(param, dtfData, result.roi, new_slide);
                end
            end
        end
    end
end

if isfield(result, 'dtf') && param.averageDTF
    title = 'averageDTF';
    for subjectGroupNum = 1:length(result.groupName)
        for conditionNum = 1:length(param.condition)
            for responseNum = 1:size(result.fileGroup, 3)
                for subConditionNum = 1:size(result.fileGroup, 5)
                    currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                    raw{responseNum, subConditionNum} = result.raw(logical(currentFile),:,:);
                end
            end
            title1 = strcat(title, '\n', result.groupName{subjectGroupNum}, '\t', param.condition{conditionNum});
            for latencyNum = 1:length(param.interestLatency)
                title2 = strcat(title1, '\n', param.interestLatencyName{latencyNum});                
                temp.currentLatency = floor((param.interestLatency{latencyNum} + param.zeroLatency) * param.fs);
                temp.currentLatency(1) = temp.currentLatency(1) + 1;
                
                for responseNum = 1:size(result.fileGroup, 3)
                    for subConditionNum = 1:size(result.fileGroup, 5)
                        graphData{responseNum, subConditionNum} = mean(raw{responseNum, subConditionNum}(:, (length(param.wholeChannel)-(length(param.roi)-1:-1:0)), temp.currentLatency(1):temp.currentLatency(2)),1);
                        if isnan(graphData{responseNum, subConditionNum})
                            dtf{responseNum, subConditionNum} = nan(size(dtf{responseNum,1}));
                        else
                            temp.dtf(:, :, :, :, latencyNum) = SJ_dtf(param, graphData{responseNum, subConditionNum});
                            dtf{responseNum, subConditionNum} = permute(temp.dtf, [1 5 2 3 4]);
                        end                        
                    end
                end
                
                for freqNum = 1:length(param.freqName)
                    title3 = strcat(title2, '\t', param.freqName{freqNum});
                    minf = param.individualFreq{freqNum}(1) - param.interestFreq(1) + 1;
                    maxf = param.individualFreq{freqNum}(2) - param.interestFreq(1) + 1;
                    for responseNum = 1:size(result.fileGroup, 3)
                        for subConditionNum = 1:size(result.fileGroup, 5)
                            dtfData{responseNum, subConditionNum} = squeeze(mean(mean(dtf{responseNum, subConditionNum}(:, latencyNum, minf:maxf, :,:),1, 'omitnan'),3, 'omitnan'));
                            dtfData{responseNum, subConditionNum}(isnan(dtfData{responseNum, subConditionNum})) = 0;
                        end
                    end
                    [slide_count, new_slide] = newSlide(op, slide_count, title3);
                    dtfPlot(param, dtfData, result.roi, new_slide);
                end
            end
        end
    end
end

if isfield(result, 'questionnaire') && isfield(result, 'questionnaireList') && isfield(result, 'questionnaireName')
    title = 'Questionnaire';
    if isfield(result, 'raw')
        title1 = strcat(title, '\t', 'ERP');
        for questionNum = 1:size(result.questionnaire,2)
            title2 = strcat(title1, '\n', result.questionnaireName{questionNum});
            
            for questionResponseNum = 1:length(result.questionnaireList{questionNum})
                for subConditionNum = 1:length(param.subCondition)
                    currentFile = squeeze(result.questionnaire(:, questionNum, questionResponseNum, subConditionNum));
                    raw{questionResponseNum, subConditionNum} = result.raw(logical(currentFile),:,:);
                end
            end
            
            for latencyNum = 1:length(param.interestLatency)
                title3 = strcat(title2, '\t', param.interestLatencyName{latencyNum});
                for interestChanNum = 1:length(param.interestChannel)
                    title4 = strcat(title3, '\n', param.interestChannel{interestChanNum});
                    
                    temp.interestRegion = (param.interestLatency{latencyNum}(1)+1/param.fs):(1/param.fs):param.interestLatency{latencyNum}(2);
                    temp.interestPoint = ((param.zeroLatency+param.interestLatency{latencyNum}(1))*param.fs+1):((param.zeroLatency+param.interestLatency{latencyNum}(2))*param.fs);
                    
                    for questionResponseNum = 1:length(result.questionnaireList{questionNum})
                        for subConditionNum = 1:length(param.subCondition)
                            questionnaireData(questionResponseNum, subConditionNum,:) = squeeze(mean(raw{questionResponseNum, subConditionNum}(:,interestChanNum,temp.interestPoint),1));
                        end
                    end
                    
                    [slide_count, new_slide] = newSlide(op, slide_count, title4);
                    questionnairePlot(param, temp, questionnaireData, result.questionnaireList{questionNum}, new_slide)
                    
                    clear questionnaireData;
                end
            end
        end
    end
    if isfield(result, 'fft')
        title1 = strcat(title, '\t', 'FFT');
        for questionNum = 1:size(result.questionnaire,2)
            title2 = strcat(title1, '\n', result.questionnaireName{questionNum});
            
            for questionResponseNum = 1:length(result.questionnaireList{questionNum})
                for subConditionNum = 1:length(param.subCondition)
                    currentFile = squeeze(result.questionnaire(:, questionNum, questionResponseNum, subConditionNum));
                    fftResult{questionResponseNum, subConditionNum} = result.fft(logical(currentFile),:,:,:);
                end
            end
            
            for latencyNum = 1:length(param.interestLatency)
                title3 = strcat(title2, '\t', param.interestLatencyName{latencyNum});
                for interestChanNum = 1:length(param.interestChannel)
                    title4 = strcat(title3, '\n', param.interestChannel{interestChanNum});
                    
                    temp.interestRegion = param.freqs;
                    temp.interestPoint = 1:length(param.freqs);
                    
                    for questionResponseNum = 1:length(result.questionnaireList{questionNum})
                        for subConditionNum = 1:length(param.subCondition)
                            questionnaireData(questionResponseNum, subConditionNum,:) = squeeze(mean(fftResult{questionResponseNum, subConditionNum}(:,interestChanNum, latencyNum, temp.interestPoint),1));
                        end
                    end
                    
                    [slide_count, new_slide] = newSlide(op, slide_count, title4);
                    questionnairePlot(param, temp, questionnaireData, result.questionnaireList{questionNum}, new_slide)
                    
                    clear questionnaireData;
                end
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

function [] = mappingPlot(param, temp, mappingData, new_slide)
figure('OuterPosition', [750 500 300 700]);
positionVector = [0.1, 0.1, 0.8, 0.8];
subplot('Position',positionVector);
colorbar('Location', 'East')
axis off;
lowThreshold = temp.mappingMean-temp.mappingSTD/2;
highThreshold = temp.mappingMean+temp.mappingSTD/2;
caxis([lowThreshold, highThreshold]);
saveas(gcf, param.picture);
close;
new_slide.Shapes.AddPicture(char(param.picture),'msoFalse','msoTrue', temp.barLocationX, temp.barLocationY, 200, 400);

temp.graphSizeX = 130;
temp.graphSizeY = 130;

for first = 1:size(mappingData,1)
    for second = 1:size(mappingData,2)
        currentMappingData = mappingData{first, second};
        if ~isnan(currentMappingData)
            figure('OuterPosition', [750 500 250 300]);
            positionVector = [0.1, 0.1, 0.8, 0.8];
            subplot('Position',positionVector);
            mappingView(currentMappingData, lowThreshold, highThreshold);
            saveas(gcf, param.picture);
            close;
            new_slide.Shapes.AddPicture(char(param.picture),'msoFalse','msoTrue', ...
                temp.graphLocationX+temp.graphSizeX*(first-1), ...
                temp.graphLocationY+temp.graphSizeY*(second-1), ...
                temp.graphSizeX, temp.graphSizeY);
        end
    end
end
end

function [] = mappingView(data, lowThreshold, highThreshold)
load('pos.mat');
load('opt.mat');
load('chanName.mat');

chanX = pos(:,1);
chanY = pos(:,2);

hold on;
ft_plot_topo(chanX, chanY, data, opt{:});
text(chanX, chanY, chanName, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

axis off;

caxis([lowThreshold, highThreshold]);
end

function [] = twoDimensionFirstPlot(param, temp, graphData, new_slide)
graphMean = [graphData{1,1}; graphData{1,2}; graphData{1,3}; graphData{2,1}; graphData{2,2}; graphData{2,3}];
graphMeanMax = max(graphMean(:)) * 5;
graphMeanMin = min(graphMean(:)) * 5;

graphLocationX = 30;
graphLocationY = 120;
graphSizeX = 900;
graphSizeY = 400/size(graphData,1);

x = temp.interestRegion;
for first = 1:size(graphData,1)
    for second = 1:size(graphData,2)
        if second == 1
            y{first} = graphData{first, second};
        else
            y{first} = [y{first}, graphData{first, second}];
        end
    end
end

for first = 1:size(graphData,1)
    figure('OuterPosition', [750 500 1000 500]);
    subplot('position', [0.1 0.1 0.8 0.8]);
    p = plot(x, y{first}); % (:,1:2));
    for second = 1:size(graphData,2)
        p(second).Color = param.color{second, 1};
        p(second).LineWidth = param.lineWidth;
    end
    xlim([x(1) x(end)]);
    ylim([graphMeanMin graphMeanMax]);
    legend(strcat(param.subCondition, '-', num2str(first)), 'Location','southoutside','Orientation','horizontal');
    saveas(gcf, param.picture);
    close;
    new_slide.Shapes.AddPicture(char(param.picture),'msoFalse','msoTrue', graphLocationX, graphLocationY+graphSizeY*(first-1), graphSizeX, graphSizeY);
end
end

function [] = twoDimensionSecondPlot(param, temp, graphData, new_slide)
graphMean = [graphData{1,1}; graphData{1,2}; graphData{1,3}; graphData{2,1}; graphData{2,2}; graphData{2,3}];
graphMeanMax = max(graphMean(:)) * 5;
graphMeanMin = min(graphMean(:)) * 5;

graphLocationX = 30;
graphLocationY = 120;
graphSizeX = 900/size(graphData,2);
graphSizeY = 300;

x = temp.interestRegion;
for second = 1:size(graphData,2)
    for first = 1:size(graphData,1)
        if first == 1
            y{second} = graphData{first, second};
        else
            y{second} = [y{second}, graphData{first, second}];
        end
    end
end

for second = 1:size(graphData,2)
    figure('OuterPosition', [750 500 1000 500]);
    subplot('position', [0.1 0.1 0.8 0.8]);
    p = plot(x, y{second});
    for first = 1:size(graphData,1)
        p(first).Color = param.color{second, first};
        p(first).LineWidth = param.lineWidth;
    end
    xlim([x(1) x(end)]);
    ylim([graphMeanMin graphMeanMax]);
    legend(strcat(param.subCondition{second}, '-', num2str(1:size(graphData,1))), 'Location','southoutside','Orientation','horizontal');
    saveas(gcf, param.picture);
    close;
    new_slide.Shapes.AddPicture(char(param.picture),'msoFalse','msoTrue', graphLocationX+graphSizeX*(second-1), graphLocationY, graphSizeX, graphSizeY);
end
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
        
        saveas(gcf, param.picture);
        close;
        new_slide.Shapes.AddPicture(char(param.picture),'msoFalse','msoTrue', graphLocationX+graphSizeX*(second-1), graphLocationY+graphSizeY*(first-1), graphSizeX, graphSizeY);
    end
end
end

function [] = allDipolePlot(param, dipoleData, new_slide)
radius = 10;
model.roilabels = {'LeftAuditory', 'RightAuditory'};
model.roipos = [-52,-19,7;50,-21,7];
model.cortex = load('colincortex.mat');
XI = model.cortex.colincortex.Vertices;
for roiNum = 1:size(model.roipos,1)
    dists = sqrt( (XI(:,1)-model.roipos(roiNum, 1)).^2 + (XI(:,2)-model.roipos(roiNum, 2)).^2 + (XI(:,3)-model.roipos(roiNum, 3)).^2 );
    vidx = find(dists<radius);
    vertices = {vidx};
    model.vertices{roiNum} = vertices;
end
nroi = length(model.roilabels);
cmap = ROIcolors(nroi);
cortexFaceVertexCData = ones(20516, 3);
for i=1:nroi
    roi_vert_idx = model.vertices{i};
    cortexFaceVertexCData(roi_vert_idx{1}, :) = repmat(cmap(i,:), length(roi_vert_idx{1}),1);
end

hold on;
patch('SpecularStrength',0,'DiffuseStrength',0.8,...
    'FaceLighting','phong',...
    'Vertices',model.cortex.colincortex.Vertices,...
    'LineStyle','none',...
    'Faces',model.cortex.colincortex.Faces,...
    'FaceColor','interp',...
    'EdgeColor','none',...
    'FaceVertexCData',cortexFaceVertexCData);
alpha(0.2);

lightcolor = [0.6 0.6 0.6];
lighting phong;
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);
axis off;

graphLocationX = 250;
graphLocationY = 120;
graphSizeX = 400;
graphSizeY = 400;

for first = 1:size(dipoleData,1)
    for second = 1:size(dipoleData,2)
        for dipoleNum = 1:size(dipoleData{first,second})
            for leftRight = 1:size(dipoleData{first, second}, 2)                
                x = dipoleData{first, second}(dipoleNum, leftRight, 1);
                y = dipoleData{first, second}(dipoleNum, leftRight, 2);
                z = dipoleData{first, second}(dipoleNum, leftRight, 3);
                scatter3(x,y,z, 'MarkerEdgeColor', 'none', 'MarkerFaceColor', param.color{second, first});
            end
        end
    end
end

saveas(gcf, param.picture);
close;
new_slide.Shapes.AddPicture(char(param.picture),'msoFalse','msoTrue', graphLocationX, graphLocationY, graphSizeX, graphSizeY);
end

function [] = dipolePlot(param, dipoleData, new_slide)
radius = 10;
model.roilabels = {'LeftAuditory', 'RightAuditory'};
model.roipos = [-52,-19,7;50,-21,7];
model.cortex = load('colincortex.mat');
XI = model.cortex.colincortex.Vertices;
for roiNum = 1:size(model.roipos,1)
    dists = sqrt( (XI(:,1)-model.roipos(roiNum, 1)).^2 + (XI(:,2)-model.roipos(roiNum, 2)).^2 + (XI(:,3)-model.roipos(roiNum, 3)).^2 );
    vidx = find(dists<radius);
    vertices = {vidx};
    model.vertices{roiNum} = vertices;
end
nroi = length(model.roilabels);
cmap = ROIcolors(nroi);
cortexFaceVertexCData = ones(20516, 3);
for i=1:nroi
    roi_vert_idx = model.vertices{i};
    cortexFaceVertexCData(roi_vert_idx{1}, :) = repmat(cmap(i,:), length(roi_vert_idx{1}),1);
end

hold on;
patch('SpecularStrength',0,'DiffuseStrength',0.8,...
    'FaceLighting','phong',...
    'Vertices',model.cortex.colincortex.Vertices,...
    'LineStyle','none',...
    'Faces',model.cortex.colincortex.Faces,...
    'FaceColor','interp',...
    'EdgeColor','none',...
    'FaceVertexCData',cortexFaceVertexCData);
alpha(0.2);

lightcolor = [0.6 0.6 0.6];
lighting phong;
light('Position',[0 0 1],'color',lightcolor);
light('Position',[0 1 0],'color',lightcolor);
light('Position',[0 -1 0],'color',lightcolor);
axis off;

graphLocationX = 250;
graphLocationY = 120;
graphSizeX = 400;
graphSizeY = 400;

for first = 1:size(dipoleData,1)
    for second = 1:size(dipoleData,2)
        for leftRight = 1:size(dipoleData{first, second}, 1)
            x = dipoleData{first, second}(leftRight, 1);
            y = dipoleData{first, second}(leftRight, 2);
            z = dipoleData{first, second}(leftRight, 3);
            scatter3(x,y,z, 'MarkerEdgeColor', 'none', 'MarkerFaceColor', param.color{second, first});
        end
    end
end

saveas(gcf, param.picture);
close;
new_slide.Shapes.AddPicture(char(param.picture),'msoFalse','msoTrue', graphLocationX, graphLocationY, graphSizeX, graphSizeY);
end

function [] = cfcPlot(param, cfcData, new_slide)
cfcMean = [cfcData{1,1}; cfcData{1,2}; cfcData{1,3}; cfcData{2,1}; cfcData{2,2}; cfcData{2,3}];
cfcMeanAverage = mean(cfcMean(:), 'omitnan');
cfcMeanSTD = std(cfcMean(:), 'omitnan');

barLocationX = 750;
barLocationY = 100;
figure('OuterPosition', [750 500 300 700]);
positionVector = [0.1, 0.1, 0.8, 0.8];
subplot('Position',positionVector);
colorbar('Location', 'East')
axis off;
caxis([(cfcMeanAverage-cfcMeanSTD*2), (cfcMeanAverage+cfcMeanSTD*2)]);
saveas(gcf, param.picture);
close;
new_slide.Shapes.AddPicture(char(param.picture),'msoFalse','msoTrue', barLocationX, barLocationY, 200, 400);

graphLocationX = 25;
graphLocationY = 120;
graphSizeX = 800/size(cfcData, 1);
graphSizeY = 400/size(cfcData, 2);

Tstep = param.phaseBand(2)-param.phaseBand(1);
Fstep = param.amplitudeBand(2)-param.amplitudeBand(1);
T = param.phaseBand(1):Tstep/(size(cfcData{1,1},1)-1):param.phaseBand(2);
F = param.amplitudeBand(1):Fstep/(size(cfcData{1,1},2)-1):param.amplitudeBand(2);
[X, Y] = meshgrid(F, T);

for first = 1:size(cfcData,1)
    for second = 1:size(cfcData,2)
        Z = cfcData{first, second};
        surf(X, Y, Z);
        shading interp;
        view(0,90);
        set(gca, 'CLim', [(cfcMeanAverage-cfcMeanSTD*2), (cfcMeanAverage+cfcMeanSTD*2)]);
        
        saveas(gcf, param.picture);
        close;
        new_slide.Shapes.AddPicture(char(param.picture),'msoFalse','msoTrue', graphLocationX+graphSizeX*(first-1), graphLocationY+graphSizeY*(second-1), graphSizeX, graphSizeY);
    end
end
end

function [] = dtfPlot(param, dtfData, roiData, new_slide)
load('basicCortex.mat');
options.type = 'ROI';
model.roilabels = roiData.labels;
model.roipos = roiData.centers;
options.isadtf = 0;
options.srate = param.fs;
model.cortex = cortex;
options.usebem = 0;
model.vertices = roiData.vertices;

graphLocationX = 100;
graphLocationY = 120;
graphSizeX = 500/size(dtfData, 1);
graphSizeY = 600/size(dtfData, 2);

nroi = length(model.roilabels);
dtf.rois = 1:nroi;

options.dtf = true;

rois = dtf.rois;
nroi = length(rois);
roilab = model.roilabels;
roipos = model.roipos;

cmap = ROIcolors(nroi);

ArrowSizeLimit = [1 5];
SphereSizeLimit = [5 10];

options.channels = 'all';

for first = 1:size(dtfData,1)
    for second = 1:size(dtfData,2)
        cortexFaceVertexCData = ones(20516, 3);
        
        if isequal(options.type,'ROI')
            for i=1:nroi
                roi_vert_idx = model.vertices{i}{1};
                cortexFaceVertexCData(roi_vert_idx, :) = repmat(cmap(i,:), length(roi_vert_idx),1);
            end
        end
        
        % display the cortex with different ROIs having different colors.
        patch('SpecularStrength',0,'DiffuseStrength',0.8,...
            'FaceLighting','phong',...
            'Vertices',model.cortex.Vertices,...
            'LineStyle','none',...
            'Faces',model.cortex.Faces,...
            'FaceColor','interp',...
            'EdgeColor','none',...
            'FaceVertexCData',cortexFaceVertexCData);
        
        alpha(0.2);
        
        maxRoiPos = max(roipos);
        for i = 1:nroi
            linestart = roipos(i, :);
            lineend = [linestart(1)*1.1, linestart(2), maxRoiPos(3)*2];
            A = text(lineend(1), lineend(2), lineend(3), char(roilab{i}), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'FontSize', 13);
            set(A, 'interpreter', 'none');
        end
        
        currentdtfmatrix = dtfData{first,second};
        valmin = min(min(currentdtfmatrix));
        valmax = max(max(currentdtfmatrix));
        [row, col] = find(currentdtfmatrix==valmax, 1);
        options.whichchannel = [row col];
        options.displimits = [valmax*param.threshold, 1.0];
        opt = struct(  'Channels', options.channels,...
            'Whichchannel', options.whichchannel,...
            'ValLim', options.displimits,...
            'ArSzLt',ArrowSizeLimit,...
            'SpSzLt',SphereSizeLimit);
        
        drawdtfconngraph(currentdtfmatrix,roipos,opt);
        
        lightcolor = [0.6 0.6 0.6];
        lighting phong; % gouraud
        light('Position',[0 0 1],'color',lightcolor);
        light('Position',[0 1 0],'color',lightcolor);
        light('Position',[0 -1 0],'color',lightcolor);
        axis off;
        hold off;
        
        if param.axis == 1
            caxis([valmin, 1.0]);
            colorbar;
        end
        
        saveas(gcf, param.picture);
        close;
        new_slide.Shapes.AddPicture(char(param.picture),'msoFalse','msoTrue', graphLocationX+graphSizeX*(second-1), graphLocationY+graphSizeY*(first-1), graphSizeX, graphSizeY);
    end
end
end

function [] = questionnairePlot(param, temp, questionnaireData, responseKind, new_slide)
graphMeanMin = min(questionnaireData(:));
graphMeanMax = max(questionnaireData(:)*3);

graphLocationX = 30;
graphLocationY = 120;
graphSizeX = 300;
graphSizeY = 400;

for subConditionNum = 1:length(param.subCondition)
    currentData = squeeze(questionnaireData(:, subConditionNum,:));
    
    responseKindHelper = responseKind;
    [X, Y] = meshgrid(responseKind, temp.interestRegion);
    Z = shiftdim(currentData,1);
    if sum(isnan(Z(:))) ~= 0
        responseKindHelper(sum(isnan(Z)) ~= 0) = [];
        [X, Y] = meshgrid(responseKindHelper, temp.interestRegion);
        Z(:, sum(isnan(Z)) ~= 0) = [];
    end   
    
    % h = surf(X,Y,Z);
    
    Xq = responseKind(1):0.1:max(responseKind);
    Yq = temp.interestRegion(1):0.1:max(temp.interestRegion);
    [Xq, Yq] = meshgrid(Xq, Yq);
    % warning off;
    Zq = interp2(X,Y,Z,Xq,Yq,'spline');
    % warning on;
    h = surf(Xq, Yq, Zq);

    set(h, 'edgecolor', 'none');
    ylim([temp.interestRegion(1) temp.interestRegion(end)]);
    zlim([graphMeanMin graphMeanMax]);
    set(gca,'YDir','reverse');
    
    saveas(gcf, param.picture);
    close;
    new_slide.Shapes.AddPicture(char(param.picture),'msoFalse','msoTrue',graphLocationX+graphSizeX*(subConditionNum-1), graphLocationY, graphSizeX, graphSizeY);
end
end