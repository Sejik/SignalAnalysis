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
MyDataDir = 'C:\Users\win\Desktop\test';
MyTempDir = 'C:\Users\win\Desktop\result';
% download toolbox (setting toolbox)
startup_bbci_toolbox('DataDir', MyDataDir, 'TmpDir', MyTempDir);

%% set parameters
rawDir = 'test'; % read input directory (.eeg)
PVALrejectPercent = 0.8; % Pearson correlation threshold
% basic function
cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));

%% Main
% read file name
cd(fullfile(MyDataDir, rawDir));

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
    
    file = fullfile(rawDir, eeg_name{eegFileNum}(1));
    resultFile = fullfile(rawDir, eeg_name{eegFileNum}(1));
    [cnt, vmrk, hdr] = file_readBV(file);
    
    for channelNum = 1:size(cnt.x, 2)
        emd{channelNum} = rParabEmd__L(cnt.x(:, channelNum), 50, 50, 1);
    end
    for emdNum = 1:length(emd)
        emdSize(emdNum) = size(emd{emdNum}, 2);
    end
    for corrNum = 1:min(emdSize)
        for emdNum = 1:length(emd)
            corrTemp(:, emdNum) = emd{emdNum}(:,corrNum);
        end
        [RHO, PVAL] = corr(corrTemp);
        corrPVAL(corrNum) = length(RHO(PVAL<0.05))/(size(RHO,1)*size(RHO,2));
    end
    highCorrArtifact = find((corrPVAL > PVALrejectPercent)==1);
    for emdNum = 1:length(emd)
        if length(highCorrArtifact) ~= 0
            for removeNum = length(highCorrArtifact):1
                emd{emdNum}(:, highCorrArtifact(removeNum)) = [];
            end
        end
    end
    for channelNum = 1:length(emd)
        emdSum(:,channelNum) = sum(emd{channelNum}, 2);
    end
    cnt.x = emdSum;
    
    file_writeBV(char(resultFile), cnt, vmrk);
    clearvars -except BTB cellfind eeg_name MyDataDir MyTempDir rawDir eegFileNum 
end