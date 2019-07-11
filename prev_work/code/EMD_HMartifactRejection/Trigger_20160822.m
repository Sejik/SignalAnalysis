%% Automatic Trigger Input with excel
% designed by Sejik Park

% contents
% 1. read eeg file name and creation time
% 2. trigger setting
%   2-1. read experiment excel file
%   2-2. read eeg file by bbci toolbox
%   2-3. trigger setting

%% clear before data
clear;
clc;

%% trigger code start
fprintf('%s: trigger code start\n', datestr(now));

%% download bbci
fprintf('%s: download bbci toolbox\n', datestr(now));
% go into folder where there is startup_bbci_toolbox
cd 'C:/Users/win/Desktop/Research/3. Analyze/Tool/bbci_public-master/bbci_public-master';
% set directory
directory.input = 'C:\Users\win\Desktop\VR_20160812';
directory.output = 'C:\Users\win\Desktop\output';
% download toolbox (setting toolbox)
startup_bbci_toolbox('DataDir', directory.input, 'TmpDir', directory.output);

%% set parameters
fprintf('%s: parameter setting\n', datestr(now));
% input directory
directory.eegDir = 'data'; % eeg file directory (.eeg)
directory.experiment{1} = 'ex01_01_SaccadeWithEyeMovementOnlyWithNoFeedback\ExerciseSuccaade_NonFixtation_Data'; % first experiment type directory (.csv)
directory.experiment{2} = 'ex01_02_SaccadeWithEyeMovementOnly\ExerciseSuccaade_NonFixtation_Data'; % second experiment
directory.experiment{3} = 'ex01_03_SaccadeWithHeadMovementOnly\ExerciseSuccaade_FixtationTriger_Data';
directory.experiment{4} = 'ex01_04_SaccadeWithEyeAndHeadMovement\ExerciseSuccaade_NonFixtation_Data';
directory.experiment{5} = 'ex02_01_PursuitWithEyeMovementOnlyWithNoFeedback\ExercisePursuit_NonFixtation_Data';
directory.experiment{6} = 'ex02_02_PursuitWithEyeMovementOnly\ExercisePursuit_NonFixtation_Data';
directory.experiment{7} = 'ex02_03_PursuitWithHeadMovementOnly\ExercisePursuit_FixtationTriger_Data';
directory.experiment{8} = 'ex02_04_PursuitWithEyeAndHeadMovement\ExercisePursuit_NonFixtation_Data';
directory.experiment{9} = 'ex03_01_VectionWithFW\ExerciseVectionFWBW_Data';
directory.experiment{10} = 'ex03_02_VectionWithFW\ExerciseVectionFWBW_Data';
directory.experiment{11} = 'ex03_03_VectionWithBW\ExerciseVectionFWBW_Data';
directory.experiment{12} = 'ex03_04_VectionWithBW\ExerciseVectionFWBW_Data';
directory.experiment{13} = 'ex04_01_VectionWithCW\ExerciseVectionCWCCW_Data';
directory.experiment{14} = 'ex04_02_VectionWithCW\ExerciseVectionCWCCW_Data';
directory.experiment{15} = 'ex04_03_VectionWithCCW\ExerciseVectionCWCCW_Data';
directory.experiment{16} = 'ex04_04_VectionWithCCW\ExerciseVectionCWCCW_Data';
% parameter
parameter.frequency = 1000;
% basic function
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
% clear workspace
clearvars -except BTB cellfind parameter directory

%% 1. read eeg file name and creation time
fprintf('%s: read eeg file name and creation time\n', datestr(now));
% read eeg file name
cd(fullfile(directory.input, directory.eegDir));
eeg_files = dir('*.eeg');
input.subjectNum = length(eeg_files);
for eegFileNum = 1:input.subjectNum
    input.eegName{eegFileNum} = eeg_files(eegFileNum).name; % eeg
    tempName = fullfile(directory.input,directory.eegDir, input.eegName{eegFileNum});
    tempName = strrep(tempName, '\', '\\');
    systemCommand = 'wmic datafile where name="" get creationdate | findstr /brc:[0-9]';
    systemCommand = strrep(systemCommand, '""', strcat('"',tempName,'"'));
    [~,date] = system(systemCommand);
    input.eegCreationTime{eegFileNum} = str2double(date(9:10)) * 60 * 60 + str2double(date(11:12)) * 60 + str2double(date(13:18));
    output.eegName{eegFileNum} = strrep(eeg_files(eegFileNum).name,'.eeg', ''); % file name
end
clearvars -except BTB cellfind parameter directory input output

%% 2. trigger setting
fprintf('%s: trigger setting\n', datestr(now));
% read subject number
for eegFileNum = 1:input.subjectNum
    cd(fullfile(directory.input, directory.eegDir));
    subjectNum = strfind(input.eegName{eegFileNum}, 'su') + 3;
    subjectName = strcat('su',input.eegName{eegFileNum}((subjectNum + 1):(subjectNum + 2)));
    [cnt, vmrk, hdr] = file_readBV(fullfile(directory.input, directory.eegDir,output.eegName{eegFileNum}));
    
    currentExperiment = cell(length(directory.experiment),1);
    for experimentNum = 1:length(directory.experiment)
        cd(fullfile(directory.input, directory.experiment{experimentNum}));
        excel_file = dir(strcat('*',subjectName,'.csv'));
        tempName = fullfile(directory.input,directory.experiment{experimentNum}, excel_file.name);
        tempName = strrep(tempName, '\', '\\');
        systemCommand = 'wmic datafile where name="" get creationdate | findstr /brc:[0-9]';
        systemCommand = strrep(systemCommand, '""', strcat('"',tempName,'"'));
        [~,date] = system(systemCommand);
        excelCreationTime = str2double(date(9:10)) * 60 * 60 + str2double(date(11:12)) * 60 + str2double(date(13:18));
        currentExperiment{experimentNum} = xlsread(tempName);
        currentExperiment{experimentNum} = currentExperiment{experimentNum}(:,1:2);
        currentExperiment{experimentNum}(1:end,1) = currentExperiment{experimentNum}(1:end,1) + (excelCreationTime - input.eegCreationTime{eegFileNum});
        currentExperiment{experimentNum}(1:end,2) = experimentNum*10 + currentExperiment{experimentNum}(1:end,2);
    end
    currentTotalExperiment = currentExperiment{1};
    for experimentNum = 2:length(directory.experiment)
        currentTotalExperiment = [currentTotalExperiment; currentExperiment{experimentNum}];
    end
    triggerNum = 1;
    for timePoint = 1:length(currentTotalExperiment)
        if isnan(currentTotalExperiment(timePoint, 2)) ~= 1
            triggerTime(triggerNum) = round(currentTotalExperiment(timePoint, 1) * parameter.frequency,0);
            triggerType(triggerNum) = currentTotalExperiment(timePoint, 2);
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
    
    cnt.fs = parameter.frequency;
    file_writeBV(fullfile(directory.output, output.eegName{eegFileNum}), cnt, vmrk);
    fprintf('%s: %s is created; total: %5.2f %% done\n', datestr(now), output.eegName{eegFileNum}, ((eegFileNum/input.subjectNum)*100));
    
    clearvars -except BTB cellfind parameter directory input output eegFileNum
end

%% trigger code end
fprintf('%s: trigger code end\n', datestr(now));