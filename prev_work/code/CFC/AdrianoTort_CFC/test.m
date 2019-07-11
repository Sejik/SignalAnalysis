%% Econnectome Automatic
% modify Adriano Tort's code by Sejik Park (Korea University Undergraduated)
% E-mail: sejik6307@gmail.com

%% Before start code
clear;
clc;

%% Parameter
% set path
amplitudeDIr = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN_whole\TIN_CFC\amplitude'; 
phaseDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN_whole\TIN_CFC\phase';
resultDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN_whole\CFC_result';
% set parameter
data_length = 500;
srate = 1000;
selectPhaseChannel = 'Cz';
selectAmpChannel = 'Pz';
PhaseFreqVector= 1:0.1:6; % 3:0.1:8; 3-8 => 1-6
AmpFreqVector= 25:0.1:65; % 8:0.1:13; => 3-8
PhaseFreq_BandWidth=4;
AmpFreq_BandWidth=10;
% basic parameter
channels = {'Fp1', 'Fp2', 'F7', 'F3', 'Fz', 'F4', 'F8', 'FC5', 'FC1', 'FC2', 'FC6','T7', 'C3', 'Cz', 'C4', 'T8', ...
            'EOG', 'CP5', 'CP1', 'CP2', 'CP6', 'P7', 'P3', 'Pz', 'P4', 'P8', 'PO9', 'O1', 'Oz', 'O2', 'PO10'};

%% read EEG data
% 30 channels
    % 1-5: Fp1, Fp2, F7, F3, Fz; 6-10: F4, F8, FC5, FC1, FC2
    % 11-15: FC6. T7, C3, Cz, C4; 16-20: T8, CP5, CP1, Cp2, Cp6
    % 21-25: P7, P3, Pz, P4, P8; 26-30: PO9, O1, Oz, O2, PO10

cd(amplitudeDIr);
eeg_files = dir('*.dat');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = eeg_files(eegFileNum).name;
    eeg_info(eegFileNum, 2) = strrep(eeg_info(eegFileNum,1),'amplitude', 'phase');
    eeg_info(eegFileNum, 3) = strrep(strrep(eeg_info(eegFileNum,1),'_amplitude', ''),'.dat', '');
end
clear eegFileNum eeg_files;
n_subjects = length(eeg_info);

cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
phaseChannelNum = find(cellfun(cellfind(selectPhaseChannel), channels));
amplitudeChannelNum = find(cellfun(cellfind(selectAmpChannel), channels));

%% CFC calculation
% basic calculation
nbin = 18;
position=zeros(1,nbin);
winsize = 2*pi/nbin;
for j=1:nbin 
    position(j) = -pi+(j-1)*winsize; 
end
% main calculation
for eegFileNum = 1:n_subjects
    tic;
    cd(amplitudeDIr);   
    amplitDataBuf = importdata(char(eeg_info(eegFileNum,1)));
    amplitudeData = amplitDataBuf.data;
    amplitudeData = reshape(amplitudeData, data_length, [], size(channels,2));
    cd(phaseDir);
    phaseDataBuf = importdata(char(eeg_info(eegFileNum,2)));
    phaseData = phaseDataBuf.data;
    phaseData = reshape(phaseData, data_length, [], size(channels,2));
    
    size(phaseData,2)
end