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
cd '/Users/sejik/Desktop/SJ_trigger/bbci_public-master';
% set directory
directory.input = '/Users/sejik/Desktop/SJ_trigger/raw';
directory.output = '/Users/sejik/Desktop/SJ_trigger/output';
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
triggerName{1} = 'S 21'; % acc
triggerName{2} = 'S 22'; % con
triggerName{3} = 'S 23'; % rest
triggerName{4} = 'S 30'; % question
triggerName{5} = 'S 31'; % accResponse
triggerName{6} = 'S 32'; % conResponse
parameter.frequency = 1000;
% basic function
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
% clear workspace
clearvars -except BTB cellfind parameter directory

%% 1. read eeg file name and creation time
fprintf('%s: read eeg file name and creation time\n', datestr(now));
% read eeg file name
cd(directory.input);
eeg_files = dir('*.eeg');
input.subjectNum = length(eeg_files);
for eegFileNum = 1:input.subjectNum
    input.eegName{eegFileNum} = strrep(eeg_files(eegFileNum).name,'.eeg',''); % eeg
end
clearvars -except BTB cellfind parameter directory input output

%% 2. trigger setting
fprintf('%s: trigger setting\n', datestr(now));
% read subject number
T = cell(500,15);
T{1,1} = 'eegFileName';
T{1,2} = 'acc RT';
T{1,3} = 'con RT';
for eegFileNum = 1:input.subjectNum
    cd(directory.input);
    [cnt, vmrk, hdr] = file_readBV(fullfile(directory.input, input.eegName{eegFileNum}));
    
    vmrk.className;
    for triggerNum = 1:size(vmrk.y,1)
        vmrk.y(triggerNum,:) = vmrk.y(triggerNum,:) .* triggerNum;
    end
    correctAccNum = 1;
    correctConNum = 1;
    for totalTriggerNum = 1:size(vmrk.y,2)
        if (sum(vmrk.y(:,totalTriggerNum)) == 1) && (totalTriggerNum+2 <= size(vmrk.y,2))
            if sum(vmrk.y(:,totalTriggerNum+2)) == 5
                accRT(correctAccNum) = vmrk.time(totalTriggerNum+2) - vmrk.time(totalTriggerNum+1);
                correctAccNum = correctAccNum + 1;
            end
        elseif (sum(vmrk.y(:,totalTriggerNum)) == 2) && (totalTriggerNum+2 <= size(vmrk.y,2))
            if sum(vmrk.y(:,totalTriggerNum+2)) == 6
                conRT(correctConNum) = vmrk.time(totalTriggerNum+2) - vmrk.time(totalTriggerNum+1);
                correctConNum = correctConNum + 1;
            end
        end
    end
    T{eegFileNum+1, 1} = input.eegName{eegFileNum};
    T{eegFileNum+1, 2} = mean(accRT);
    T{eegFileNum+1, 3} = mean(conRT);
    clearvars -except T BTB cellfind parameter directory input output eegFileNum averageAccRT averageConRT
end

resultT = cell2table(T);
cd(directory.output);
writetable(resultT, 'RT_Result.csv');

%% trigger code end
fprintf('%s: trigger code end\n', datestr(now));