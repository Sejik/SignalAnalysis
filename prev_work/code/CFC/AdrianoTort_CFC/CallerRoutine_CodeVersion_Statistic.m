%% Econnectome Automatic
% modify Adriano Tort's code by Sejik Park (Korea University Undergraduated)
% E-mail: sejik6307@gmail.com

%% Before start code
clear;
clc;

%% Parameter
% set path
resultDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN_whole\TIN_CFC\result_theta_alpha';

% set parameter
condition = {'11', '12', '21', '22'};
PhaseFreqVector = 1:0.1:11; % low_high condition & theta_alpha condition
% AmpFreqVector = 25:0.1:65; % low_high condition
AmpFreqVector = 1:0.1:11; % theta_alpha condition
PhaseFreq_BandWidth=4;
AmpFreq_BandWidth=10;

% group parameter
controlGroup = {'pTIN_su0019', 'pTIN_su0021', 'pTIN_su0024', 'TIN_su0004', 'TIN_su0007', 'TIN_su0009', ...
    'TIN_su0001', 'TIN_su0011', 'TIN_su0013', 'TIN_su0014', 'TIN_su0015', 'TIN_su0019', 'TIN_su0020', ...
    'TIN_su0023'};
experimentalGroup = {'pTIN_su0001', 'pTIN_su0002', 'pTIN_su0003', 'pTIN_su0004', 'pTIN_su0006', 'pTIN_su0007', ...
    'pTIN_su0008', 'pTIN_su0009', 'pTIN_su0010', 'pTIN_su0011', 'pTIN_su0014', 'pTIN_su0017', 'pTIN_su0018', ...
    'pTIN_su0025'};
experimentalSubgroupA = {'pTIN_su0002', 'pTIN_su0004', 'pTIN_su0006', 'pTIN_su0008', 'pTIN_su0010', 'pTIN_su0011', ...
    'pTIN_su0017'};
experimentalSubgroupB = {'pTIN_su0001', 'pTIN_su0003', 'pTIN_su0007', 'pTIN_su0009', 'pTIN_su0014', 'pTIN_su0018', ...
    'pTIN_su0025'};
% basic function
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));

%% read & plot
cd(resultDir);
for conditionNum = 1:size(condition,2)
    % read Comodulogram data
    cd(resultDir);
    cd(condition{conditionNum});
    findFileName = strcat('*', condition{conditionNum}, '.mat');
    eeg_files = dir(findFileName);    
    for eegFileNum = 1:length(eeg_files)
        eeg_info{eegFileNum} = eeg_files(eegFileNum).name;
    end
    clear eegFileNum eeg_files;
    
    for eegFileNum = 1:length(eeg_info)
        currentData = char(eeg_info(eegFileNum));
        individualAverageComodulogram = importdata(currentData);
        currentData = currentData(1:11);
        if currentData(1) == 'T'
            currentData = currentData(1:10);
        end
        if sum(cellfun(cellfind(cellstr(currentData)), experimentalGroup)) == 1
            experimentalGroupComodulogram(1,:,:) = individualAverageComodulogram;
            experimentalGroupComodulogram(size(experimentalGroupComodulogram,1)+1,:,:) = individualAverageComodulogram;
        end
        if sum(cellfun(cellfind(cellstr(currentData)), controlGroup)) == 1
            controlGroupComodulogram(1,:,:) = individualAverageComodulogram;
            controlGroupComodulogram(size(controlGroupComodulogram,1)+1,:,:) = individualAverageComodulogram;
        end
        if sum(cellfun(cellfind(cellstr(currentData)), experimentalSubgroupA)) == 1
            experimentalSubgroupAComodulogram(1,:,:) = individualAverageComodulogram;
            experimentalSubgroupAComodulogram(size(experimentalSubgroupAComodulogram,1)+1,:,:) = individualAverageComodulogram;
        end
        if sum(cellfun(cellfind(cellstr(currentData)), experimentalSubgroupB)) == 1
            experimentalSubgroupBComodulogram(1,:,:) = individualAverageComodulogram;
            experimentalSubgroupBComodulogram(size(experimentalSubgroupBComodulogram,1)+1,:,:) = individualAverageComodulogram;
        end
    end
    
    experimentalGroupComodulogram(1,:,:) = [];
    controlGroupComodulogram(1,:,:) = [];
    experimentalSubgroupAComodulogram(1,:,:) = [];
    experimentalSubgroupBComodulogram(1,:,:) = [];
    
    A = reshape(max(experimentalGroupComodulogram,[],2),size(experimentalGroupComodulogram,1),size(experimentalGroupComodulogram,3));
    A = max(A, [], 2);
    B = reshape(max(controlGroupComodulogram,[],2),size(controlGroupComodulogram,1),size(controlGroupComodulogram,3));
    B = max(B, [], 2);
    C = reshape(max(experimentalSubgroupAComodulogram,[],2),size(experimentalSubgroupAComodulogram,1),size(experimentalSubgroupAComodulogram,3));
    C = max(C, [], 2);
    D = reshape(max(experimentalSubgroupBComodulogram,[],2),size(experimentalSubgroupBComodulogram,1),size(experimentalSubgroupBComodulogram,3));
    D = max(D, [], 2);
    A
    B
    C
    D
    clear experimentalGroupComodulogram controlGroupComodulogram experimentalSubgroupAComodulogram experimentalSubgroupBComodulogram
end