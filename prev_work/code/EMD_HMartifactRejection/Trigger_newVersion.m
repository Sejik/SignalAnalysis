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
rawDir = 'HMD/RAW'; % read input directory (.eeg)
bvaDir = 'HMD/BVA'; % save output directory (.eeg)

%% initialize (read file name)
cd(fullfile(MyDataDir, rawDir));
eeg_files = dir('*.eeg'); % read all eeg file in raw directory (preprocessing in Brain Analzer)
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = eeg_files(eegFileNum).name; % eeg
    eeg_info{eegFileNum, 2} = strrep(eeg_info(eegFileNum,1),'.eeg', ''); % file name
end
exp13_eeg = eeg_info(1:end, 2);
clear eegFileNum eeg_files eeg_info;

%% load data (exp1)
for eegFileNum = 1:length(exp13_eeg)
    
    file = fullfile(rawDir, exp13_eeg{eegFileNum}(1));
    [cnt, vmrk, hdr] = file_readBV(file);
    
    excelData = xlsread(char(eegFile));
    
    vmrk.className{size(vmrk.className,2) + 1} = 'S 1';
    vmrk.y = zeros(size(vmrk.className,2), 2);
    vmrk.y(1,1) = 1;
    vmrk.y(2,2) = 1;
    
    for triggerNum = 1:size(excelData,1)
        if excelData(triggerNum, 2) == 1
            triggerTime = round(excelData(triggerNum, 1) * 1000, 0);
            nextTriggerNum = size(vmrk.time, 2) + 1;
            vmrk.time(nextTriggerNum) = triggerTime;
            vmrk.event.desc(nextTriggerNum) = 1;
            vmrk.event.type(nextTriggerNum) = {'Stimulus'};
            vmrk.event.length(nextTriggerNum) = 1;
            vmrk.event.chan(nextTriggerNum) = 0;
            vmrk.event.clock(nextTriggerNum) = {''};
            vmrk.y(3,nextTriggerNum) = 1;
        end
    end
    
    % classDef = {2:27; vmrk.className(2:27)};
    % mrk = mrk_defineClasses(vmrk, classDef); % remove garbage marker
    % classDef =  {11, 12, 13, 14, 15, 16 ; 'a', 'b', 'c', 'd', 'e', 'f'}; % topdown class reanalyze (make two group) '¤¡' or not
    % mrk = mrk_defineClasses(vmrk, classDef);
    
    file = fullfile(MyDataDir, bvaDir);
    file = fullfile(file, eegFile);
    file_writeBV(char(file), cnt, vmrk);    
end