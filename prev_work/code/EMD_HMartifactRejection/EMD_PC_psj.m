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
MyDataDir = 'C:/Users/win/Desktop/Research/3. Analyze/Tool/bbci_public-master/data';
MyTempDir = 'C:/Users/win/Desktop/Research/3. Analyze/Tool/bbci_public-master/tmp';
% download toolbox (setting toolbox)
startup_bbci_toolbox('DataDir', MyDataDir, 'TmpDir', MyTempDir);

%% set parameters
rawDir = 'VR'; % read input directory (.eeg)
bvaDir = 'BVA'; % save output directory (.eeg)

epochSize = 500;

%% initialize
% read file name
cd(fullfile(MyDataDir, rawDir));

folderName = dir();
for trialKind = folderName.name
    cd(fullfile(MyDataDir, rawDir));
    if strcmp(trialKind, '.') || strcmp(trialKind, '..')
        cd(trialKind);
        a = 11
    end
end

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
    
%     for channelNum = 1:size(cnt.x, 2)
%         k = rParabEmd__L(cnt.x(1:1000, channelNum), 50, 50, 1);
%     end
    
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
    file_writeBV(char(file), cnt, vmrk);    
end

% %%
% a = rParabEmd__L(lfp, 50, 50, 1);
% %%
% b = a;
% c1 = b(:,:);
% c2 = b(:,:);
% 
% [RHO,PVAL] = corr(c1,c2);
% c3 = PVAL;
% c3(find(c3 < 0.05)) = 0;
% c3(isnan(PVAL)) = 0;
% c3
% 
% %%
% subplot(2,1,2)
% b = a';
% b = b(5,:);
% plot(b)
% xlim([0 1000])
% set(gca,'fontsize',14)
% xlabel('time (ms)')
% ylabel('mV')