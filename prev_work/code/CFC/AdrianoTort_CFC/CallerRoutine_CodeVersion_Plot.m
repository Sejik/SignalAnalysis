%% Econnectome Automatic
% modify Adriano Tort's code by Sejik Park (Korea University Undergraduated)
% E-mail: sejik6307@gmail.com

%% Before start code
clear;
clc;

%% Parameter
% set path
dataDir = 'C:\Users\win\Desktop\test\pTIN_group2';
resultDir = 'C:\Users\win\Desktop\test';

% set parameter
PhaseFreqVector= 1:0.1:6; % 3:0.1:8; 3-8 => 1-6
AmpFreqVector= 25:0.1:65; % 8:0.1:13; => 3-8
PhaseFreq_BandWidth=4;
AmpFreq_BandWidth=10;

%% read Comodulogram data
cd(dataDir);
eeg_files = dir('*11.mat');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum} = eeg_files(eegFileNum).name;
end
clear eegFileNum eeg_files;
n_subjects = length(eeg_info);

%% CFC calculation
% main calculation

findwrongans = 0;
for eegFileNum = 1:n_subjects
    cd(dataDir);
    temp = load(char(eeg_info(eegFileNum)));
    for a = 1:size(temp.resultComodulogram,2)
        if sum(sum(isnan(temp.resultComodulogram{a}))) == 0
            individualComodulogram(a,:,:) = temp.resultComodulogram{a};
        end
    end
    grandAverageComodulogram(eegFileNum,:,:) = mean(individualComodulogram,1);
end
finalComodulogram = mean(grandAverageComodulogram,1);
finalComodulogram = reshape(finalComodulogram,51,401);
%% 

save('pTIN_group2_11', 'finalComodulogram');   
figure;
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,finalComodulogram',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
savefig('pTIN_group2_11');
