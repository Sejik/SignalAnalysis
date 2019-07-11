% Designed by Sejik Park
% E-mail: sejik6307@gmail.com

%% clear before data
clear all;
clc;

%% download bbci
% go into folder where there is startup_bbci_toolbox
cd 'C:/Users/win/Desktop/Research/3. Analyze/Tool/bbci_public-master/bbci_public-master';
% set directory
MyDataDir = 'C:/Users/win/Desktop/Research/3. Analyze/Tool/bbci_public-master/data';
MyTempDir = 'C:/Users/win/Desktop/Research/3. Analyze/Tool/bbci_public-master/tmp';
% download toolbox (setting toolbox)
startup_bbci_toolbox('DataDir', MyDataDir, 'TmpDir', MyTempDir);

%% set parameters
rawDir = 'VR'; % read input directory (.eeg)
bvaDir = 'BVA'; % save output directory (.eeg)

%% initialize
% read file name
cd(fullfile(MyDataDir, rawDir));
eeg_files = dir('*.eeg'); % read all eeg file in raw directory (preprocessing in Brain Analzer)
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = eeg_files(eegFileNum).name; % eeg
    eeg_info{eegFileNum, 2} = strrep(eeg_info(eegFileNum,1),'.eeg', ''); % file name
end
eeg_name = eeg_info(1:end, 2);
clear eegFileNum eeg_files eeg_info;
% basic function
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));

%% trigger the data
for eegFileNum = 1:length(eeg_name)
    
    file = fullfile(rawDir, eeg_name{eegFileNum}(1));
    [cnt, vmrk, hdr] = file_readBV(file);
    excelData = xlsread(char(strcat(eeg_name{eegFileNum}(1), '.csv')));
        
    cnt.fs = 5000;
    triggerNum = 1;
    for timePoint = 1:size(excelData,1)
        if isnan(excelData(timePoint, 2)) ~= 1
            triggerTime(triggerNum) = round(excelData(timePoint, 1) * 5000);
            triggerType(triggerNum) = excelData(timePoint, 2);
            triggerNum = triggerNum + 1;
        end
    end
    totalTriggerTypeNum = unique(triggerType);
    stimulusName = 'S';
    totalTriggerTypeName = strrep(strcat(stimulusName, num2str(totalTriggerTypeNum(:))), 'S', 'S ');
    
    for triggerTypeNum = 1:size(totalTriggerTypeName)
        vmrk.className{size(vmrk.className, 2) + 1} = totalTriggerTypeName(triggerTypeNum,:);
        vmrk.y = zeros(size(vmrk.className,2), 1);        
    end
    
    for totalTriggerNum = 1:length(triggerTime)
        vmrk.time(totalTriggerNum) = triggerTime(totalTriggerNum);
        vmrk.event.desc(totalTriggerNum) = 1;
        vmrk.event.type(totalTriggerNum) = {'Stimulus'};
        vmrk.event.length(totalTriggerNum) = 1;
        vmrk.event.chan(totalTriggerNum) = 0;
        vmrk.event.clock(totalTriggerNum) = {''};
        
        eventSelected = find(cellfun(cellfind(cellstr(strrep(strcat(stimulusName, num2str(totalTriggerTypeNum(:))),'S', 'S '))), vmrk.className));
        
        vmrk.y(eventSelected,totalTriggerNum) = 1;
    end
    
    file_writeBV(char(strcat('0402_', eeg_name{eegFileNum}(1))), cnt, vmrk);    
end