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
resultDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\TIN\TIN_whole\TIN_CFC\result1';
% set subpath
activeTarget = '11';
activeNonTarget = '12';
passiveTarget = '21';
passiveNontarget = '22';
% set parameter
data_length = 500;
srate = 1000;
selectPhaseChannel = 'Cz';
selectAmpChannel = 'Pz';
PhaseFreqVector= 1:0.1:11; % 3:0.1:13; 3-13 => 1-11
AmpFreqVector= 1:0.1:11; % 30:0.1:70; 30-70 => 25-65
PhaseFreq_BandWidth=4;
AmpFreq_BandWidth=10;
% basic parameter
channels = {'Fp1', 'Fp2', 'F7', 'F3', 'Fz', 'F4', 'F8', 'FC5', 'FC1', 'FC2', 'FC6','T7', 'C3', 'Cz', 'C4', 'T8', ...
            'EOG', 'CP5', 'CP1', 'CP2', 'CP6', 'P7', 'P3', 'Pz', 'P4', 'P8', 'PO9', 'O1', 'Oz', 'O2', 'PO10'};
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
    cd(amplitudeDIr);   
    amplitudeDataBuf = importdata(char(eeg_info(eegFileNum,1)));
    amplitudeData = amplitudeDataBuf.data;
    amplitudeData = reshape(amplitudeData, data_length, [], size(channels,2));
    cd(phaseDir);
    phaseDataBuf = importdata(char(eeg_info(eegFileNum,2)));
    phaseData = phaseDataBuf.data;
    phaseData = reshape(phaseData, data_length, [], size(channels,2));
    
    for comodulogramSize = 1:size(phaseData,2)
        ampChannel=amplitudeData(:,comodulogramSize, amplitudeChannelNum)';
        phaseChannel=phaseData(:,comodulogramSize, phaseChannelNum)';
        % comodulogram calculation
        Comodulogram=single(zeros(length(PhaseFreqVector),length(AmpFreqVector)));
        AmpFreqTransformed = zeros(length(AmpFreqVector), data_length);
        PhaseFreqTransformed = zeros(length(PhaseFreqVector), data_length);
        for ii=1:length(AmpFreqVector)
            Af1 = AmpFreqVector(ii);
            Af2=Af1+AmpFreq_BandWidth;
            AmpFreq=eegfilt(ampChannel,srate,Af1,Af2, data_length, 166); % just filtering
            AmpFreqTransformed(ii, :) = abs(hilbert(AmpFreq)); % getting the amplitude envelope
        end
        for jj=1:length(PhaseFreqVector)
            Pf1 = PhaseFreqVector(jj);
            Pf2 = Pf1 + PhaseFreq_BandWidth;
            PhaseFreq=eegfilt(phaseChannel,srate,Pf1,Pf2, data_length, 166); % this is just filtering
            PhaseFreqTransformed(jj, :) = angle(hilbert(PhaseFreq)); % this is getting the phase time series
        end
        counter1=0;
        for ii=1:length(PhaseFreqVector)
            counter1=counter1+1;
            counter2=0;
            for jj=1:length(AmpFreqVector)
                counter2=counter2+1;
                [MI,MeanAmp]=ModIndex_v2_psj(PhaseFreqTransformed(ii, :), AmpFreqTransformed(jj, :), position);
                Comodulogram(counter1,counter2)=MI;
            end
        end
        resultComodulogram(comodulogramSize,:,:) = Comodulogram;
    end
    
    cd(resultDir);
    individualAverageComodulogram = mean(resultComodulogram, 1,'omitnan');
    individualAverageComodulogram = reshape(individualAverageComodulogram,101,401);
    
    if strfind(char(eeg_info(eegFileNum,3)), '_11')
        cd(activeTarget);
        save(char(eeg_info(eegFileNum,3)), 'individualAverageComodulogram'); 
    end
    if strfind(char(eeg_info(eegFileNum,3)), '_12')
        cd(activeNonTarget);
        save(char(eeg_info(eegFileNum,3)), 'individualAverageComodulogram'); 
    end
    if strfind(char(eeg_info(eegFileNum,3)), '_21')
        cd(passiveTarget);
        save(char(eeg_info(eegFileNum,3)), 'individualAverageComodulogram'); 
    end
    if strfind(char(eeg_info(eegFileNum,3)), '_22')
        cd(passiveNontarget);
        save(char(eeg_info(eegFileNum,3)), 'individualAverageComodulogram'); 
    end
    
    clear resultComodulogram;
    finished = char(eeg_info(eegFileNum,3))
end

%% CFC averaging
clear eeg_files eeg_info;
cd(result);
cd(11);
eeg_files = dir('*11.mat');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum} = eeg_files(eegFileNum).name;
end
clear eegFileNum eeg_files;
n_subjects = length(eeg_info);
for eegFileNum = 1:n_subjects
    currentData = char(eeg_info(eegFileNum,1));
    individualComodulogram = importdata(currentData);
    currentData = currentData(1:10);
    if strfind(experimentalGroup, currentData)
        experimentalGroupComodulogram(size(experimentalGroupComodulogram,1),:,:) = individualAverageComodulogram;
    end
    if strfind(controlGroup, currentData)
        controlGroupComodulogram(size(controlGroupComodulogram,1),:,:) = individualAverageComodulogram;
    end
    if strfind(experimentalSubgroupA, currentData)
        experimentalSubgroupAComodulogram(size(experimentalSubgroupAComodulogram,1),:,:) = individualAverageComodulogram;
    end
    if strfind(experimentalSubgroupB, currentData)
        experimentalSubgroupBComodulogram(size(experimentalSubgroupBComodulogram,1),:,:) = individualAverageComodulogram;
    end
end
cd(result);
experimentalGroupGrandaverage = reshape(mean(experimentalGroupComodulogram, 1,'omitnan'),101,401);
controlGroupGrandaverage = reshape(mean(controlGroupComodulogram, 1,'omitnan'),101,401);
experimentalSubgroupAGrandaverage = reshape(mean(experimentalSubgroupAComodulogram, 1,'omitnan'),101,401);
experimentalSubgroupBGrandaverage = reshape(mean(experimentalSubgroupBComodulogram, 1,'omitnan'),101,401);
save('grandaverage11', experimentalGroupGrandaverage, controlGroupGrandaverage, experimentalSubgroupAGrandaverage, experimentalSubgroupBGrandaverage);
figure;
subplot(1,4,1);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,experimentalGroupGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
subplot(1,4,2);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,controlGroupGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
subplot(1,4,3);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,experimentalSubgroupAGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
subplot(1,4,4);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,experimentalSubgroupBGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
savefig('grandaverage11');

clear eeg_files eeg_info;
cd(result);
cd(11);
eeg_files = dir('*12.mat');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum} = eeg_files(eegFileNum).name;
end
clear eegFileNum eeg_files;
n_subjects = length(eeg_info);
for eegFileNum = 1:n_subjects
    currentData = char(eeg_info(eegFileNum,1));
    individualComodulogram = importdata(currentData);
    currentData = currentData(1:10);
    if strfind(experimentalGroup, currentData)
        experimentalGroupComodulogram(size(experimentalGroupComodulogram,1),:,:) = individualAverageComodulogram;
    end
    if strfind(controlGroup, currentData)
        controlGroupComodulogram(size(controlGroupComodulogram,1),:,:) = individualAverageComodulogram;
    end
    if strfind(experimentalSubgroupA, currentData)
        experimentalSubgroupAComodulogram(size(experimentalSubgroupAComodulogram,1),:,:) = individualAverageComodulogram;
    end
    if strfind(experimentalSubgroupB, currentData)
        experimentalSubgroupBComodulogram(size(experimentalSubgroupBComodulogram,1),:,:) = individualAverageComodulogram;
    end
end
cd(result);
experimentalGroupGrandaverage = reshape(mean(experimentalGroupComodulogram, 1,'omitnan'),101,401);
controlGroupGrandaverage = reshape(mean(controlGroupComodulogram, 1,'omitnan'),101,401);
experimentalSubgroupAGrandaverage = reshape(mean(experimentalSubgroupAComodulogram, 1,'omitnan'),101,401);
experimentalSubgroupBGrandaverage = reshape(mean(experimentalSubgroupBComodulogram, 1,'omitnan'),101,401);
save('grandaverage12', experimentalGroupGrandaverage, controlGroupGrandaverage, experimentalSubgroupAGrandaverage, experimentalSubgroupBGrandaverage);
figure;
subplot(1,4,1);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,experimentalGroupGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
subplot(1,4,2);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,controlGroupGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
subplot(1,4,3);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,experimentalSubgroupAGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
subplot(1,4,4);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,experimentalSubgroupBGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
savefig('grandaverage12');

clear eeg_files eeg_info;
cd(result);
cd(11);
eeg_files = dir('*21.mat');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum} = eeg_files(eegFileNum).name;
end
clear eegFileNum eeg_files;
n_subjects = length(eeg_info);
for eegFileNum = 1:n_subjects
    currentData = char(eeg_info(eegFileNum,1));
    individualComodulogram = importdata(currentData);
    currentData = currentData(1:10);
    if strfind(experimentalGroup, currentData)
        experimentalGroupComodulogram(size(experimentalGroupComodulogram,1),:,:) = individualAverageComodulogram;
    end
    if strfind(controlGroup, currentData)
        controlGroupComodulogram(size(controlGroupComodulogram,1),:,:) = individualAverageComodulogram;
    end
    if strfind(experimentalSubgroupA, currentData)
        experimentalSubgroupAComodulogram(size(experimentalSubgroupAComodulogram,1),:,:) = individualAverageComodulogram;
    end
    if strfind(experimentalSubgroupB, currentData)
        experimentalSubgroupBComodulogram(size(experimentalSubgroupBComodulogram,1),:,:) = individualAverageComodulogram;
    end
end
cd(result);
experimentalGroupGrandaverage = reshape(mean(experimentalGroupComodulogram, 1,'omitnan'),101,401);
controlGroupGrandaverage = reshape(mean(controlGroupComodulogram, 1,'omitnan'),101,401);
experimentalSubgroupAGrandaverage = reshape(mean(experimentalSubgroupAComodulogram, 1,'omitnan'),101,401);
experimentalSubgroupBGrandaverage = reshape(mean(experimentalSubgroupBComodulogram, 1,'omitnan'),101,401);
save('grandaverage21', experimentalGroupGrandaverage, controlGroupGrandaverage, experimentalSubgroupAGrandaverage, experimentalSubgroupBGrandaverage);
figure;
subplot(1,4,1);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,experimentalGroupGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
subplot(1,4,2);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,controlGroupGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
subplot(1,4,3);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,experimentalSubgroupAGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
subplot(1,4,4);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,experimentalSubgroupBGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
savefig('grandaverage21');

clear eeg_files eeg_info;
cd(result);
cd(11);
eeg_files = dir('*22.mat');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum} = eeg_files(eegFileNum).name;
end
clear eegFileNum eeg_files;
n_subjects = length(eeg_info);
for eegFileNum = 1:n_subjects
    currentData = char(eeg_info(eegFileNum,1));
    individualComodulogram = importdata(currentData);
    currentData = currentData(1:10);
    if strfind(experimentalGroup, currentData)
        experimentalGroupComodulogram(size(experimentalGroupComodulogram,1),:,:) = individualAverageComodulogram;
    end
    if strfind(controlGroup, currentData)
        controlGroupComodulogram(size(controlGroupComodulogram,1),:,:) = individualAverageComodulogram;
    end
    if strfind(experimentalSubgroupA, currentData)
        experimentalSubgroupAComodulogram(size(experimentalSubgroupAComodulogram,1),:,:) = individualAverageComodulogram;
    end
    if strfind(experimentalSubgroupB, currentData)
        experimentalSubgroupBComodulogram(size(experimentalSubgroupBComodulogram,1),:,:) = individualAverageComodulogram;
    end
end
cd(result);
experimentalGroupGrandaverage = reshape(mean(experimentalGroupComodulogram, 1,'omitnan'),101,401);
controlGroupGrandaverage = reshape(mean(controlGroupComodulogram, 1,'omitnan'),101,401);
experimentalSubgroupAGrandaverage = reshape(mean(experimentalSubgroupAComodulogram, 1,'omitnan'),101,401);
experimentalSubgroupBGrandaverage = reshape(mean(experimentalSubgroupBComodulogram, 1,'omitnan'),101,401);
save('grandaverage22', experimentalGroupGrandaverage, controlGroupGrandaverage, experimentalSubgroupAGrandaverage, experimentalSubgroupBGrandaverage);
figure;
subplot(1,4,1);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,experimentalGroupGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
subplot(1,4,2);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,controlGroupGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
subplot(1,4,3);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,experimentalSubgroupAGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
subplot(1,4,4);
contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,experimentalSubgroupBGrandaverage',30,'lines','none')
set(gca,'fontsize',14)
ylabel('Amplitude Frequency (Hz)')
xlabel('Phase Frequency (Hz)')
colorbar
savefig('grandaverage22');