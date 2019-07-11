function [] = SJ_excelAbstract(param, result)
if isfield(result, 'statistic')
    if 0 > 5
        if isfield(result.statistic, 'erp')
            for latencyNum = 1:length(param.interestLatency)
                fileName = strcat('erpAbstract-', param.interestLatencyName{latencyNum});
                SJ_excelAbstractLoop(param, result, fileName, squeeze(result.statistic.erp(:,:,:, latencyNum)));
            end
        end
        
        if isfield(result.statistic, 'fftIndividualFreq')
            for latencyNum = 1:length(param.interestLatency)
                fileName = strcat('fftAbstract-', param.interestLatencyName{latencyNum});
                SJ_excelAbstractLoop(param, result, fileName, squeeze(result.statistic.fftIndividualFreq(:,:,:, latencyNum, :)));
            end
        end
        
        if isfield(result.statistic, 'waveletIndividualLatency')
            for latencyNum = 1:length(param.interestLatency)
                fileName = strcat('waveletAbstract-', '-', param.interestLatencyName{latencyNum});
                SJ_excelAbstractLoop(param, result, fileName, squeeze(result.statistic.waveletIndividualLatency(:,:,:, latencyNum, freqNum)));
                
            end
        end
        
        if isfield(result.statistic, 'individualCFC')
            for latencyNum = 1:length(param.interestLatency)
                fileName = strcat('cfcAbstract-', param.interestLatencyName{latencyNum});
                SJ_excelAbstractLoop(param, result, fileName, squeeze(result.statistic.individualCFC(:,:,:, latencyNum)));
            end
        end
        
        if isfield(result.statistic, 'erpQuestionnaire')
            for interestChanNum = 1:length(param.interestChannel)
                currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
                for latencyNum = 1:length(param.interestLatency)
                    fileName = strcat('erpQuestionnaireAbstract-',param.interestChannel{interestChanNum}, '-', param.interestLatencyName{latencyNum});
                    SJ_questionnaireExcelLoop(param, result, fileName, squeeze(result.erp(:,currentChanNum, latencyNum)), squeeze(result.statistic.erpQuestionnaire(:,currentChanNum, latencyNum)));
                end
            end
        end
    end
    
    if isfield(result.statistic, 'fftIndividualFreqQuestionnaire')
        for interestChanNum = 1:length(param.interestChannel)
            currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
            for latencyNum = 1:length(param.interestLatency)
                fileName = strcat('fftIndividualFreqQuestionnaireAbstract-',param.interestChannel{interestChanNum}, '-', param.interestLatencyName{latencyNum});
                SJ_questionnaireExcelLoop(param, result, fileName, squeeze(result.fftIndividualFreq(:,currentChanNum, latencyNum, :)), squeeze(result.statistic.fftIndividualFreqQuestionnaire(:,currentChanNum, latencyNum, :)));
            end
        end
    end
end
end

function [] = SJ_excelAbstractLoop(param, result, fileName, statisticWhole)
T = cell(500,15);
T{1,1} = 'response_statistic';
currentColumn = 1;
currentRow = 1;
for subjectGroupNum = 1:size(result.fileGroup, 2)
    
    for conditionNum = 1:size(result.fileGroup, 4)
        for interestChanNum = 1:length(param.interestChannel)
            currentChanNum = cellfun(param.cellfind(param.interestChannel{interestChanNum}), param.wholeChannel);
            
            
            if ndims(statisticWhole) > 3
                for freqNum = 1:size(statisticWhole, 4)
                    statistic = squeeze(statisticWhole(:,:, currentChanNum, freqNum));
                    
                end
            else
                statistic = squeeze(statisticWhole(:,:, currentChanNum));
                
            end
        end
        
        T{6, currentRow} = 'response_statistic';
        currentColumn = 7;
        if ~iscell(statistic{subjectGroupNum, conditionNum}(1).kind)
            T{currentColumn, currentRow} = statistic{subjectGroupNum, conditionNum}(1).kind;
            switch statistic{subjectGroupNum, conditionNum}(1).kind
                case 'ttest'
                    T{currentColumn, currentRow+2} = 'P';
                    for subConditionNum = 1:length(statistic{subjectGroupNum, conditionNum}(1).H)
                        T{currentColumn, currentRow} = param.subCondition{subConditionNum};
                        T{currentColumn, currentRow+2} = statistic{subjectGroupNum, conditionNum}(1).P(subConditionNum);
                        currentColumn = currentColumn + 1;
                    end
                case 'Wilcoxon-Mann-Whitney-test'
                    T{currentColumn, currentRow+2} = 'P';
                    for subConditionNum = 1:length(statistic{subjectGroupNum, conditionNum}(1).H)
                        T{currentColumn, currentRow} = param.subCondition{subConditionNum};
                        T{currentColumn, currentRow+2} = statistic{subjectGroupNum, conditionNum}(1).P(subConditionNum);
                    end
            end
        else
            for multiNum = 1:length(statistic{subjectGroupNum, conditionNum}(1).kind)
                T{currentColumn, currentRow} = statistic{subjectGroupNum, conditionNum}(1).kind{multiNum};
                switch statistic{subjectGroupNum, conditionNum}(1).kind{multiNum}
                    case {'anova', 'kruskalwallis'}
                        T{currentColumn, currentRow+3} = 'P';
                        currentColumn = currentColumn + 1;
                        T{currentColumn, currentRow} = param.subCondition{multiNum};
                        T{currentColumn, currentRow+3} = statistic{subjectGroupNum, conditionNum}(1).P(multiNum);
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
                    T{currentColumn, currentRow+2} = 'P';
                    currentColumn = currentColumn + 1;
                    for responseNum = 1:length(statistic{subjectGroupNum, conditionNum}(2).H)
                        T{currentColumn, currentRow} = num2str(responseNum);
                        T{currentColumn, currentRow+2} = statistic{subjectGroupNum, conditionNum}(2).P(responseNum);
                        currentColumn = currentColumn + 1;
                    end
                case 'Wilcoxon-Mann-Whitney-test'
                    T{currentColumn, currentRow+2} = 'P';
                    currentColumn = currentColumn + 1;
                    for responseNum = 1:length(statistic{subjectGroupNum, conditionNum}(2).H)
                        T{currentColumn, currentRow} = num2str(responseNum);
                        T{currentColumn, currentRow+2} = statistic{subjectGroupNum, conditionNum}(2).P(responseNum);
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
                        T{currentColumn, currentRow+3} = 'P';
                        currentColumn = currentColumn + 1;
                        T{currentColumn, currentRow} = num2str(multiNum);
                        T{currentColumn, currentRow+3} = statistic{subjectGroupNum, conditionNum}(2).P(multiNum);
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
    T{2,1} = 'Subject No.';
    T{2,2} = 'Score';
    currentRow = 3;
    for subConditionNum = 1:size(result.questionnaire, 4)
        for freqNum = 1:size(result.fftIndividualFreq, 4)
            T{2,currentRow} = strcat(param.subCondition{subConditionNum}, '_', param.freqName{freqNum});
            currentRow = currentRow + 1;
        end
    end
    for subjectNum = 1:length(result.subjectList)
        T{2+subjectNum, 1} = result.subjectList{subjectNum};
        T{2+subjectNum, 2} = result.responseList(subjectNum, questionNum);
    end
    for questionResponseNum = 1:length(result.questionnaireList{questionNum})
        currentRow = 3;
        for subConditionNum = 1:size(result.questionnaire, 4)
            currentFile = squeeze(result.questionnaire(:, questionNum, questionResponseNum, subConditionNum));
            currentNum = find(currentFile);
            for freqNum = 1:size(result.fftIndividualFreq, 4)
                for sameResponseNum = 1:length(currentNum)
                    tempNum = currentNum(sameResponseNum);
                    currentColumn = 2 + find(cellfun(param.cellfind(result.subjectName{tempNum}), result.subjectList));
                    currentData = raw(tempNum, freqNum);
                    T{currentColumn, currentRow} = currentData; 
                end
                currentRow = currentRow + 1;
            end
        end
    end
    currentColumn = 4+length(result.subjectList);
    T{currentColumn, 1} = 'questionnaire_statistic';
    T{currentColumn+1, 1} = 'Pearman';
    T{currentColumn+2, 1} = 'Pearman_pValue';
    T{currentColumn+3, 1} = 'Spearman';
    T{currentColumn+4, 1} = 'Spearman_pValue';
    currentRow = 3;
    for subConditionNum = 1:size(result.questionnaire, 4)
        for freqNum = 1:size(result.fftIndividualFreq, 4)
            T{currentColumn+1, currentRow} = statistic{questionNum, freqNum}(1).pearman_r(subConditionNum);
            T{currentColumn+2, currentRow} = statistic{questionNum, freqNum}(1).pearman_p(subConditionNum);
            T{currentColumn+3, currentRow} = statistic{questionNum, freqNum}(1).spearman_r(subConditionNum);
            T{currentColumn+4, currentRow} = statistic{questionNum, freqNum}(1).spearman_p(subConditionNum);
            currentRow = currentRow + 1;
        end
    end
    
    currentFileName = strcat(fileName, '-', result.questionnaireName{questionNum}, '.xls');
    resultT = cell2table(T);
    cd(param.outputDir);
    writetable(resultT, currentFileName);
end
end