function [] = SJ_excel(param, result)
if isfield(result, 'statistic')
    if isfield(result.statistic, 'erp')
        for interestChanNum = 1:length(param.interestChannel)
            currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
            for latencyNum = 1:length(param.interestLatency)
                fileName = strcat('erp-',param.interestChannel{interestChanNum}, '-', param.interestLatencyName{latencyNum});
                SJ_excelLoop(param, result, fileName, squeeze(result.erp(:,currentChanNum, latencyNum)), squeeze(result.statistic.erp(:,:,currentChanNum, latencyNum)));
            end
        end
    end
    
    if isfield(result.statistic, 'fftIndividualFreq')
        for interestChanNum = 1:length(param.interestChannel)
            currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
            for latencyNum = 1:length(param.interestLatency)
                for freqNum = 1:size(result.fftIndividualFreq, 4)
                    fileName = strcat('fft-',param.interestChannel{interestChanNum}, '-', param.interestLatencyName{latencyNum}, '-', param.freqName{freqNum});
                    SJ_excelLoop(param, result, fileName, squeeze(result.fftIndividualFreq(:,currentChanNum, latencyNum, freqNum)), squeeze(result.statistic.fftIndividualFreq(:,:,currentChanNum, latencyNum, freqNum)));
                end
            end
        end
    end
    
    if isfield(result.statistic, 'waveletIndividualLatency')
        for interestChanNum = 1:length(param.interestChannel)
            currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
            for latencyNum = 1:length(param.interestLatency)
                for freqNum = 1:size(result.waveletIndividualLatency, 4)
                    fileName = strcat('wavelet-',param.interestChannel{interestChanNum}, '-', param.interestLatencyName{latencyNum}, '-', param.freqName{freqNum});
                    SJ_excelLoop(param, result, fileName, squeeze(result.waveletIndividualLatency(:,currentChanNum, latencyNum, freqNum)), squeeze(result.statistic.waveletIndividualLatency(:,:,currentChanNum, latencyNum, freqNum)));
                end
            end
        end
    end
    
    if isfield(result.statistic, 'dipoleDistance')
        for latencyNum = 1:length(param.interestLatency)
            fileName = strcat('dipole-',param.interestLatencyName{latencyNum});
            SJ_excelLoop(param, result, fileName, squeeze(result.dipoleDistance(:,latencyNum)), squeeze(result.statistic.dipoleDistance(:,:,latencyNum)));
        end
    end
    
    if isfield(result.statistic, 'individualCFC')
        for interestChanNum = 1:length(param.interestChannel)
            currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
            for latencyNum = 1:length(param.interestLatency)
                fileName = strcat('cfc-',param.interestChannel{interestChanNum}, '-', param.interestLatencyName{latencyNum});
                SJ_excelLoop(param, result, fileName, squeeze(result.individualCFC(:,currentChanNum, latencyNum)), squeeze(result.statistic.individualCFC(:,:,currentChanNum, latencyNum)));
            end
        end
    end
    
    if isfield(result.statistic, 'individualDTF')
        for latencyNum = 1:length(param.interestLatency)
            for freqNum = 1:size(result.individualDTF, 3)
                for roi1Num = 1:size(result.individualDTF, 4)
                    for roi2Num = 1:size(result.individualDTF, 5)
                        fileName = strcat('dtf-', param.interestLatencyName{latencyNum}, '-', param.freqName{freqNum}, '-', param.roiName{roi1Num}, '-', param.roiName{roi2Num});
                        SJ_excelLoop(param, result, fileName, squeeze(result.individualDTF(:,latencyNum, freqNum, roi1Num, roi2Num)), squeeze(result.statistic.individualDTF(:,:,latencyNum, freqNum, roi1Num, roi2Num)));
                    end
                end
            end
        end
    end
    
    if isfield(result.statistic, 'erpQuestionnaire')
        for interestChanNum = 1:length(param.interestChannel)
            currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
            for latencyNum = 1:length(param.interestLatency)
                fileName = strcat('erpQuestionnaire-',param.interestChannel{interestChanNum}, '-', param.interestLatencyName{latencyNum});
                SJ_questionnaireExcelLoop(param, result, fileName, squeeze(result.erp(:,currentChanNum, latencyNum)), squeeze(result.statistic.erpQuestionnaire(:,currentChanNum, latencyNum)));
            end
        end
    end
    
    if isfield(result.statistic, 'fftIndividualFreqQuestionnaire')
        for interestChanNum = 1:length(param.interestChannel)
            currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
            for latencyNum = 1:length(param.interestLatency)
                for freqNum = 1:size(result.fftIndividualFreq, 4)
                    fileName = strcat('fftIndividualFreqQuestionnaire-',param.interestChannel{interestChanNum}, '-', param.interestLatencyName{latencyNum}, '-', param.freqName{freqNum});
                    SJ_questionnaireExcelLoop(param, result, fileName, squeeze(result.fftIndividualFreq(:,currentChanNum, latencyNum, freqNum)), squeeze(result.statistic.fftIndividualFreqQuestionnaire(:,currentChanNum, latencyNum, freqNum)));
                end
            end
        end
    end
end
end

function [] = SJ_excelLoop(param, result, fileName, raw, statistic)
for subjectGroupNum = 1:size(result.fileGroup, 2)
    for conditionNum = 1:size(result.fileGroup, 4)
        T = cell(500,15);
        currentRow = 1;
        for responseNum = 1:size(result.fileGroup, 3)
            for subConditionNum = 1:size(result.fileGroup, 5)
                currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                currentData = raw(logical(currentFile));
                T{1, currentRow} = strcat(num2str(responseNum),'-',param.subCondition{subConditionNum});
                for dataNum = 1:length(currentData)
                    T{1+dataNum, currentRow} = currentData(dataNum);
                end
                currentRow = currentRow + 1;
            end
        end
        
        currentRow = currentRow + 1;
        statisticRow = currentRow;
        T{2, currentRow} = 'M';
        T{3, currentRow} = 'SD';
        T{4, currentRow} = 'N';
        currentRow = currentRow + 1;
        for responseNum = 1:size(statistic{subjectGroupNum, conditionNum}(1).M, 1)
            for subConditionNum = 1:size(statistic{subjectGroupNum, conditionNum}(1).M, 2)
                T{1, currentRow} = strcat(num2str(responseNum),'-',param.subCondition{subConditionNum});
                T{2, currentRow} = statistic{subjectGroupNum, conditionNum}(1).M(responseNum, subConditionNum);
                T{3, currentRow} = statistic{subjectGroupNum, conditionNum}(1).SD(responseNum, subConditionNum);
                T{4, currentRow} = statistic{subjectGroupNum, conditionNum}(1).N(responseNum, subConditionNum);
                currentRow = currentRow + 1;
            end
        end
        
        currentRow = statisticRow;
        
        T{6, currentRow} = 'response_statistic';
        currentColumn = 7;
        if ~iscell(statistic{subjectGroupNum, conditionNum}(1).kind)
            T{currentColumn, currentRow} = statistic{subjectGroupNum, conditionNum}(1).kind;
            switch statistic{subjectGroupNum, conditionNum}(1).kind
                case 'ttest'
                    T{currentColumn, currentRow+1} = 'H';
                    T{currentColumn, currentRow+2} = 'P';
                    T{currentColumn, currentRow+3} = 'T';
                    T{currentColumn, currentRow+4} = 'DF';
                    T{currentColumn, currentRow+5} = 'SD';
                    currentColumn = currentColumn + 1;
                    for subConditionNum = 1:length(statistic{subjectGroupNum, conditionNum}(1).H)
                        T{currentColumn, currentRow} = param.subCondition{subConditionNum};
                        T{currentColumn, currentRow+1} = statistic{subjectGroupNum, conditionNum}(1).H(subConditionNum);
                        T{currentColumn, currentRow+2} = statistic{subjectGroupNum, conditionNum}(1).P(subConditionNum);
                        T{currentColumn, currentRow+3} = statistic{subjectGroupNum, conditionNum}(1).T(subConditionNum);
                        T{currentColumn, currentRow+4} = statistic{subjectGroupNum, conditionNum}(1).DF(subConditionNum);
                        T{currentColumn, currentRow+5} = statistic{subjectGroupNum, conditionNum}(1).SD(subConditionNum);
                        currentColumn = currentColumn + 1;
                    end
                case 'Wilcoxon-Mann-Whitney-test'
                    T{currentColumn, currentRow+1} = 'H';
                    T{currentColumn, currentRow+2} = 'P';
                    T{currentColumn, currentRow+3} = 'LP';
                    T{currentColumn, currentRow+4} = 'RP';
                    T{currentColumn, currentRow+5} = 'Z';
                    T{currentColumn, currentRow+6} = 'RS';
                    currentColumn = currentColumn + 1;
                    for subConditionNum = 1:length(statistic{subjectGroupNum, conditionNum}(1).H)
                        T{currentColumn, currentRow} = param.subCondition{subConditionNum};
                        T{currentColumn, currentRow+1} = statistic{subjectGroupNum, conditionNum}(1).H(subConditionNum);
                        T{currentColumn, currentRow+2} = statistic{subjectGroupNum, conditionNum}(1).P(subConditionNum);
                        T{currentColumn, currentRow+3} = statistic{subjectGroupNum, conditionNum}(1).LP(subConditionNum);
                        T{currentColumn, currentRow+4} = statistic{subjectGroupNum, conditionNum}(1).RP(subConditionNum);
                        if isfield(statistic{subjectGroupNum, conditionNum}(1), 'Z')
                            T{currentColumn, currentRow+5} = statistic{subjectGroupNum, conditionNum}(1).Z(subConditionNum);
                        end
                        T{currentColumn, currentRow+6} = statistic{subjectGroupNum, conditionNum}(1).RS(subConditionNum);
                        currentColumn = currentColumn + 1;
                    end
            end
        else
            for multiNum = 1:length(statistic{subjectGroupNum, conditionNum}(1).kind)
                T{currentColumn, currentRow} = statistic{subjectGroupNum, conditionNum}(1).kind{multiNum};
                switch statistic{subjectGroupNum, conditionNum}(1).kind{multiNum}
                    case {'anova', 'kruskalwallis'}
                        T{currentColumn, currentRow+1} = 'H';
                        T{currentColumn, currentRow+2} = 'F';
                        T{currentColumn, currentRow+3} = 'P';
                        T{currentColumn, currentRow+4} = 'DFG';
                        T{currentColumn, currentRow+5} = 'DFE';
                        T{currentColumn, currentRow+6} = 'postHoc';
                        currentColumn = currentColumn + 1;
                        T{currentColumn, currentRow} = param.subCondition{multiNum};
                        T{currentColumn, currentRow+1} = statistic{subjectGroupNum, conditionNum}(1).H(multiNum);
                        T{currentColumn, currentRow+2} = statistic{subjectGroupNum, conditionNum}(1).F(multiNum);
                        T{currentColumn, currentRow+3} = statistic{subjectGroupNum, conditionNum}(1).P(multiNum);
                        T{currentColumn, currentRow+4} = statistic{subjectGroupNum, conditionNum}(1).DFG(multiNum);
                        T{currentColumn, currentRow+5} = statistic{subjectGroupNum, conditionNum}(1).DFE(multiNum);
                        if statistic{subjectGroupNum, conditionNum}(1).P(multiNum) < 0.05
                            for pHnum = 1:size(statistic{subjectGroupNum, conditionNum}(1).postHoc(multiNum).p, 1)
                                pHname = strcat(num2str(statistic{subjectGroupNum, conditionNum}(1).postHoc(multiNum).p(pHnum, 1)), '_', num2str(statistic{subjectGroupNum, conditionNum}(1).postHoc(multiNum).p(pHnum, 2)));
                                T{currentColumn, currentRow + 4 + pHnum*2} = pHname;
                                T{currentColumn, currentRow + 5 + pHnum*2} = statistic{subjectGroupNum, conditionNum}(1).postHoc(multiNum).p(pHnum, 3);
                            end
                        end
                        currentColumn = currentColumn + 1;
                    case {'singularData', 'noGroup'}
                        currentColumn = currentColumn + 1;
                end
            end
        end
        
        currentColumn = currentColumn + 1;
        T{currentColumn, currentRow} = 'subCondition_statistic';
        currentColumn = currentColumn + 1;
        if ~iscell(statistic{subjectGroupNum, conditionNum}(2).kind)
            T{currentColumn, currentRow} = statistic{subjectGroupNum, conditionNum}(2).kind;
            switch statistic{subjectGroupNum, conditionNum}(2).kind
                case 'ttest'
                    T{currentColumn, currentRow+1} = 'H';
                    T{currentColumn, currentRow+2} = 'P';
                    T{currentColumn, currentRow+3} = 'T';
                    T{currentColumn, currentRow+4} = 'DF';
                    T{currentColumn, currentRow+5} = 'SD';
                    currentColumn = currentColumn + 1;
                    for responseNum = 1:length(statistic{subjectGroupNum, conditionNum}(2).H)
                        T{currentColumn, currentRow} = num2str(responseNum);
                        T{currentColumn, currentRow+1} = statistic{subjectGroupNum, conditionNum}(2).H(responseNum);
                        T{currentColumn, currentRow+2} = statistic{subjectGroupNum, conditionNum}(2).P(responseNum);
                        T{currentColumn, currentRow+3} = statistic{subjectGroupNum, conditionNum}(2).T(responseNum);
                        T{currentColumn, currentRow+4} = statistic{subjectGroupNum, conditionNum}(2).DF(responseNum);
                        T{currentColumn, currentRow+5} = statistic{subjectGroupNum, conditionNum}(2).SD(responseNum);
                        currentColumn = currentColumn + 1;
                    end
                case 'Wilcoxon-Mann-Whitney-test'
                    T{currentColumn, currentRow+1} = 'H';
                    T{currentColumn, currentRow+2} = 'P';
                    T{currentColumn, currentRow+3} = 'LP';
                    T{currentColumn, currentRow+4} = 'RP';
                    T{currentColumn, currentRow+5} = 'Z';
                    T{currentColumn, currentRow+6} = 'RS';
                    currentColumn = currentColumn + 1;
                    for responseNum = 1:length(statistic{subjectGroupNum, conditionNum}(2).H)
                        T{currentColumn, currentRow} = num2str(responseNum);
                        T{currentColumn, currentRow+1} = statistic{subjectGroupNum, conditionNum}(2).H(responseNum);
                        T{currentColumn, currentRow+2} = statistic{subjectGroupNum, conditionNum}(2).P(responseNum);
                        T{currentColumn, currentRow+3} = statistic{subjectGroupNum, conditionNum}(2).LP(responseNum);
                        T{currentColumn, currentRow+4} = statistic{subjectGroupNum, conditionNum}(2).RP(responseNum);
                        if isfield(statistic{subjectGroupNum, conditionNum}(2), 'Z')
                            T{currentColumn, currentRow+5} = statistic{subjectGroupNum, conditionNum}(2).Z(responseNum);
                        end
                        T{currentColumn, currentRow+6} = statistic{subjectGroupNum, conditionNum}(2).RS(responseNum);
                        currentColumn = currentColumn + 1;
                    end
            end
        else
            for multiNum = 1:length(statistic{subjectGroupNum, conditionNum}(2).kind)
                T{currentColumn, currentRow} = statistic{subjectGroupNum, conditionNum}(2).kind{multiNum};
                switch statistic{subjectGroupNum, conditionNum}(2).kind{multiNum}
                    case {'anova', 'kruskalwallis'}
                        T{currentColumn, currentRow+1} = 'H';
                        T{currentColumn, currentRow+2} = 'F';
                        T{currentColumn, currentRow+3} = 'P';
                        T{currentColumn, currentRow+4} = 'DFG';
                        T{currentColumn, currentRow+5} = 'DFE';
                        T{currentColumn, currentRow+6} = 'postHoc';
                        currentColumn = currentColumn + 1;
                        T{currentColumn, currentRow} = num2str(multiNum);
                        T{currentColumn, currentRow+1} = statistic{subjectGroupNum, conditionNum}(2).H(multiNum);
                        T{currentColumn, currentRow+2} = statistic{subjectGroupNum, conditionNum}(2).F(multiNum);
                        T{currentColumn, currentRow+3} = statistic{subjectGroupNum, conditionNum}(2).P(multiNum);
                        T{currentColumn, currentRow+4} = statistic{subjectGroupNum, conditionNum}(2).DFG(multiNum);
                        T{currentColumn, currentRow+5} = statistic{subjectGroupNum, conditionNum}(2).DFE(multiNum);
                        if statistic{subjectGroupNum, conditionNum}(2).P(multiNum) < 0.05
                            for pHnum = 1:size(statistic{subjectGroupNum, conditionNum}(2).postHoc(multiNum).p, 1)
                                pHname = strcat(param.subCondition{statistic{subjectGroupNum, conditionNum}(2).postHoc(multiNum).p(pHnum, 1)}, '_', param.subCondition{statistic{subjectGroupNum, conditionNum}(2).postHoc(multiNum).p(pHnum, 2)});
                                T{currentColumn, currentRow + 4 + pHnum*2} = pHname;
                                T{currentColumn, currentRow + 5 + pHnum*2} = statistic{subjectGroupNum, conditionNum}(2).postHoc(multiNum).p(pHnum, 3);
                            end
                        end
                        currentColumn = currentColumn + 1;
                    case {'singularData', 'noGroup'}
                        currentColumn = currentColumn + 1;
                end
            end
        end
        
        currentFileName = strcat(fileName, '-', result.groupName{subjectGroupNum}, '-', param.condition{conditionNum}, '.xls');
        resultT = cell2table(T);
        cd(param.outputDir);
        writetable(resultT, currentFileName);
    end
end
end

function [] = SJ_questionnaireExcelLoop(param, result, fileName, raw, statistic)
for questionNum = 1:size(result.questionnaire,2)
    T = cell(500,100);
    currentRow = 1;
    for questionResponseNum = 1:length(result.questionnaireList{questionNum})
        for subConditionNum = 1:size(result.questionnaire, 4)
            currentFile = squeeze(result.questionnaire(:, questionNum, questionResponseNum, subConditionNum));
            currentData = raw(logical(currentFile));
            T{1, currentRow} = strcat(num2str(result.questionnaireList{questionNum}(questionResponseNum)),'-',param.subCondition{subConditionNum});
            for dataNum = 1:length(currentData)
                T{1+dataNum, currentRow} = currentData(dataNum);
            end
            currentRow = currentRow + 1;
        end
    end
    
    currentRow = currentRow + 1;
    statisticRow = currentRow;
    T{2, currentRow} = 'M';
    T{3, currentRow} = 'SD';
    T{4, currentRow} = 'N';
    currentRow = currentRow + 1;
    for questionResponseNum = 1:length(result.questionnaireList{questionNum})
        for subConditionNum = 1:size(result.questionnaire, 4)
            T{1, currentRow} = strcat(num2str(result.questionnaireList{questionNum}(questionResponseNum)),'-',param.subCondition{subConditionNum});
            T{2, currentRow} = statistic{questionNum}(1).M(questionResponseNum, subConditionNum);
            T{3, currentRow} = statistic{questionNum}(1).SD(questionResponseNum, subConditionNum);
            T{4, currentRow} = statistic{questionNum}(1).N(questionResponseNum, subConditionNum);
            currentRow = currentRow + 1;
        end
    end
    
    currentRow = statisticRow;
    T{6, currentRow} = 'questionnaire_statistic';
    currentColumn = 7;
    
    T{6, currentRow+1} = 'RSQ';
    for subConditionNum = 1:size(result.questionnaire, 4)
        T{currentColumn, currentRow} = param.subCondition{subConditionNum};
        T{currentColumn, currentRow+1} = statistic{questionNum}(1).RSQ(subConditionNum);
        currentColumn = currentColumn + 1;
    end
    
    currentFileName = strcat(fileName, '-', result.questionnaireName{questionNum}, '.xls');
    resultT = cell2table(T);
    cd(param.outputDir);
    writetable(resultT, currentFileName);
end
end