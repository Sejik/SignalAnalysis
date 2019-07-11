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
load('excel_eeg.mat');

%% load data (exp1)
for eegFileNum = 1:length(exp1_eeg)
    eegFile = exp1_eeg(eegFileNum);
    excelFile = exp1_excel(eegFileNum);
    delay = exp1_delay(eegFileNum);
    
    eegFile = strrep(eegFile, '.eeg', '');
    file = fullfile(rawDir, eegFile);
    [cnt, vmrk, hdr] = file_readBV(file);
    
    excelData = xlsread(char(excelFile));
    
    vmrk.className{size(vmrk.className,2) + 1} = 'S 1';
    vmrk.y = zeros(size(vmrk.className,2), 2);
    vmrk.y(1,1) = 1;
    vmrk.y(2,2) = 1;
    
    for triggerNum = 1:size(excelData,1)
        if excelData(triggerNum, 2) == 1
            triggerTime = round(excelData(triggerNum, 1) * 1000 + delay, 0);
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