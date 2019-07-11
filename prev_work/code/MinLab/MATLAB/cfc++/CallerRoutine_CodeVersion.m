%% Econnectome Automatic
% modify Adriano Tort's code by Sejik Park (Korea University Undergraduated)
% E-mail: sejik6307@gmail.com

%% Before start code
clear;
clc;

%% Parameter
% set path
dataDir = 'C:\Users\win\Desktop\TF';
resultDir = 'C:\Users\win\Desktop\CFCresult';
% set parameter
data_length = 500 * 6;
srate = 1000;
selectPhaseChannel = 'Cz';
selectAmpChannel = 'Pz';
PhaseFreqVector= 3:0.1:6; % 3:0.1:8; 3-8 => 1-6
AmpFreqVector= 3:0.1:8; % 8:0.1:13; => 3-8
PhaseFreq_BandWidth=4;
AmpFreq_BandWidth=10;
% basic parameter
channels = {'Fp1', 'Fp2', 'F7', 'F3', 'Fz', 'F4', 'F8', 'FC5', 'FC1', 'FC2', 'FC6','T7', 'C3', 'Cz', 'C4', 'T8', ...
            'CP5', 'CP1', 'CP2', 'CP6', 'P7', 'P3', 'Pz', 'P4', 'P8', 'PO9', 'O1', 'Oz', 'O2', 'PO10'};

%% read EEG data
% 30 channels
    % 1-5: Fp1, Fp2, F7, F3, Fz; 6-10: F4, F8, FC5, FC1, FC2
    % 11-15: FC6. T7, C3, Cz, C4; 16-20: T8, CP5, CP1, Cp2, Cp6
    % 21-25: P7, P3, Pz, P4, P8; 26-30: PO9, O1, Oz, O2, PO10

cd(dataDir);
eeg_files = dir('*.mat');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum} = eeg_files(eegFileNum).name;
end
clear eegFileNum eeg_files;
n_subjects = length(eeg_info);

cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
phaseChannelNum = find(cellfun(cellfind(selectPhaseChannel), channels));
ampChannelNum = find(cellfun(cellfind(selectAmpChannel), channels));

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
    cd(dataDir);
    tf = load(char(eeg_info(eegFileNum)));
    eeg = tf.ERP_filt_bl; % tf: ERP_filt_bl, TFe_bl, TFi, TFi_bl
    phaseChannel = eeg(501:1000,phaseChannelNum)';
    ampChannel = eeg(501:1000,ampChannelNum)';
    phaseChannel = [phaseChannel, phaseChannel, phaseChannel, phaseChannel, phaseChannel, phaseChannel];
    ampChannel = [ampChannel, ampChannel, ampChannel, ampChannel, ampChannel, ampChannel];
    
    % plot
    clf
    subplot(2,1,1);
    plot(phaseChannel);
    xlim([0 1500]);
    set(gca,'fontsize',14);
    xlabel('time (ms)');
    ylabel('mV');
    subplot(2,1,2);
    plot(ampChannel);
    xlim([0 1500]);
    set(gca,'fontsize',14);
    xlabel('time (ms)');
    ylabel('mV');
    
    
    % comodulogram calculation
    Comodulogram=single(zeros(length(PhaseFreqVector),length(AmpFreqVector)));
    AmpFreqTransformed = zeros(length(AmpFreqVector), data_length);
    PhaseFreqTransformed = zeros(length(PhaseFreqVector), data_length);    
    for ii=1:length(AmpFreqVector)
        Af1 = AmpFreqVector(ii);
        Af2=Af1+AmpFreq_BandWidth;
        AmpFreq=eegfilt(ampChannel,srate,Af1,Af2); % just filtering
        AmpFreqTransformed(ii, :) = abs(hilbert(AmpFreq)); % getting the amplitude envelope
    end    
    for jj=1:length(PhaseFreqVector)
        Pf1 = PhaseFreqVector(jj);
        Pf2 = Pf1 + PhaseFreq_BandWidth;
        PhaseFreq=eegfilt(phaseChannel,srate,Pf1,Pf2); % this is just filtering
        PhaseFreqTransformed(jj, :) = angle(hilbert(PhaseFreq)); % this is getting the phase time series
    end    
    counter1=0;
    for ii=1:length(PhaseFreqVector)
        counter1=counter1+1;
        counter2=0;
        for jj=1:length(AmpFreqVector)
            counter2=counter2+1;
            [MI,MeanAmp]=ModIndex_v2_repetition6(PhaseFreqTransformed(ii, :), AmpFreqTransformed(jj, :), position);
            Comodulogram(counter1,counter2)=MI;
        end
    end
    % save result
    cd (resultDir);
    save(char(eeg_info(eegFileNum)), 'Comodulogram');    
    
    figure;
    contourf(PhaseFreqVector+PhaseFreq_BandWidth/2,AmpFreqVector+AmpFreq_BandWidth/2,Comodulogram',30,'lines','none')
    set(gca,'fontsize',14)
    ylabel('Amplitude Frequency (Hz)')
    xlabel('Phase Frequency (Hz)')
    colorbar    
end