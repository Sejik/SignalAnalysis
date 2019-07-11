%% GVS_artifact_rejection
% designed by Sejik Park
% sejik6307@gmail.com

% Preprocessing
% read EEG data by BBCI tool box

% Process
% (based on "Wavelet-Based Artifact Identification and Separation Technique
%   for EEG Signals during Galvanic Vestibular Stimulation")
% 1. SWT (DB4 mother wavelet) - 12 frequency band
% 2. artifact rejection (time-domain regression model) - nonlinear
% Hammerstein-Weiner order2
% 3. combine

% Final
% save combine EEG

%% Parameters
bbciDir = 'D:\Research\3. Analyze\Tool\bbci_public-master\bbci_public-master';
MyDataDir = 'D:\Research\3. Analyze\Tool\bbci_public-master\data';
MyTempDir = 'D:\Research\3. Analyze\Tool\bbci_public-master\tmp';
rawDir = 'GVS';

%% Preprocessing
cd(bbciDir);
startup_bbci_toolbox('DataDir', MyDataDir, 'TmpDir', MyTempDir);
cd(fullfile(MyDataDir, rawDir));
eeg_files = dir('*.eeg');
for eegFileNum = 1:length(eeg_files)
    eeg_info{eegFileNum, 1} = strrep(eeg_files(eegFileNum).name, '.eeg', ''); % eeg
end
n_subjects = length(eeg_info);
for eegFileNum = 1:n_subjects
    file = fullfile(rawDir, eeg_info(eegFileNum));
    [cnt, vmrk, hdr] = file_readBV(file);
    data{eegFileNum} = cnt.x;
end

clear bbciDir BTB cnt eeg_files eeg_info eegFileNum file hdr MyDataDir MyTempDir n_subjects rawDir vmrk;
%% 1. SWT (DB4 mother wavelet) - 12 frequency band
% stationary wavelet tranfrom (SWT) with DB4 mother wavelet
wname = 'db4'; % set daubechies wavelet name
for subject = 1:size(data,2)
    for channel = 1:size(data{subject}, 2)
        point = size(data{subject}(1:end, channel)) - mod(size(data{subject}(1:end, channel)), 2^12);
        [swa, swd] = swt(data{subject}(1:point, channel), 12, wname); % matrix EEG_Data at level 12
                           % data length % 2^level = 0 --> cut time domain
                           % SWC = [SWA, SWD] = [approximation coefficient, detail coefficients]
        swc{channel} = [swa, swd];
    end
    frequency_data{subject} = swc;
end

%% 2. artifact rejection (time-domain regression model)
% nonlinear Hammerstein-Weiner order 2
% using ident function to know how to regression


%% 3. combine

%% Final