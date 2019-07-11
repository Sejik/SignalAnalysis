%% EMD2ArtifactRejection
% designed by Sejik Park

% EMD according to the parper
% Rato, R. T., Ortigueira, M. D., & Batista, A. G. (2008).
% On the HHT, its problems, and some solutions. Mechanical Systems and Signal Processing, 22(6), 1374-1394.

% 1. trigger point
% 2. preprocessing with brain vision analyzer 
    % time delay matching, topographic interpolation, band filter
    % ocular correction
% 3. EMD and pearson correlation to reject noise
% 4. average with brain vision analyzer

%% clear before data
clear;
clc;

%% download bbci
% go into folder where there is startup_bbci_toolbox
cd 'C:/Users/win/Desktop/Research/3. Analyze/Tool/bbci_public-master/bbci_public-master';
% set directory
MyDataDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\VR';
MyTempDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\VR\4. TriggerRaw14';
% download toolbox (setting toolbox)
startup_bbci_toolbox('DataDir', MyDataDir, 'TmpDir', MyTempDir);

%% set parameters
rawDir = '3. RAW14'; % read input directory (.eeg)

% basic function
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));

%% Main
% read file name
cd(fullfile(MyDataDir, rawDir));

folderName = dir();
for trialKind = 1:length(folderName);
    cd(fullfile(MyDataDir, rawDir));
    if (strcmp(folderName(trialKind).name, '.') || strcmp(folderName(trialKind).name, '..')) ~= 1
        cd(folderName(trialKind).name);
        % initialize
        eeg_files = dir('*.eeg'); % read all eeg file in raw directory (preprocessing in Brain Analzer)
        for eegFileNum = 1:length(eeg_files)
            eeg_info{eegFileNum, 1} = eeg_files(eegFileNum).name; % eeg
            eeg_info{eegFileNum, 2} = strrep(eeg_info(eegFileNum,1),'.eeg', ''); % file name
        end
        eeg_name = eeg_info(1:end, 2);
        clear eegFileNum eeg_files eeg_info;
        
        % trigger the data        
        for eegFileNum = 1:length(eeg_name)
            
            file = fullfile(rawDir, folderName(trialKind).name, eeg_name{eegFileNum}(1));
            resultFile = fullfile(rawDir, eeg_name{eegFileNum}(1));
            [cnt, vmrk, hdr] = file_readBV(file);
            
            excelData = xlsread(char(strcat(eeg_name{eegFileNum}(1), '.csv')));
            
            triggerNum = 1;
            for timePoint = 1:size(excelData,1)
                if isnan(excelData(timePoint, 2)) ~= 1
                    triggerTime(triggerNum) = round(excelData(timePoint, 1) * 1000, 0);
                    triggerType(triggerNum) = excelData(timePoint, 2);
                    triggerNum = triggerNum + 1;
                end
            end
            totalTriggerTypeNum = unique(triggerType);
            totalTriggerType = vmrk.className;
            currentTrigger = totalTriggerType;
            for triggerNum = 1:size(totalTriggerTypeNum, 2)
                totalTriggerType{triggerNum} = 'S  *';
                totalTriggerType(triggerNum) = strrep(totalTriggerType(triggerNum), '*', num2str(totalTriggerTypeNum(triggerNum)));
            end
            
            vmrk.className = totalTriggerType;
            currentTrigger{1} = 'S  *';
            
            for totalTriggerNum = 1:length(triggerTime)
                vmrk.time(totalTriggerNum) = triggerTime(totalTriggerNum);
                vmrk.event.desc(totalTriggerNum) = 1;
                vmrk.event.type(totalTriggerNum) = {'Stimulus'};
                vmrk.event.length(totalTriggerNum) = 1;
                vmrk.event.chan(totalTriggerNum) = 0;
                vmrk.event.clock(totalTriggerNum) = {''};
                
                eventSelected = find(cellfun(cellfind(strrep(currentTrigger{1}, '*', num2str(triggerType(totalTriggerNum)))), vmrk.className));
                vmrk.y(eventSelected,totalTriggerNum) = 1;
            end
            
            vmrk.event.desc = triggerType;
            cnt.fs = 5000;
            resultFile = strrep(resultFile, 'VR_ex01', folderName(trialKind).name);
            resultFile = strrep(resultFile, 'VR_ex02', folderName(trialKind).name);
            resultFile = strrep(resultFile, 'VR_ex03', folderName(trialKind).name);
            resultFile = strrep(resultFile, 'VR_ex04', folderName(trialKind).name);
            file_writeBV(char(resultFile), cnt, vmrk);
            clearvars -except BTB cellfind eeg_name folderName MyDataDir MyTempDir rawDir eegFileNum trialKind
        end
    end
end