%% EMD_PC_artifactRejection_econnectomeFileFormat
% designed by Sejik Park (Korea University Undergraduated)
% e-mail: sejik6307@gmail.com

% EMD according to the parper
% Rato, R. T., Ortigueira, M. D., & Batista, A. G. (2008).
% On the HHT, its problems, and some solutions. Mechanical Systems and Signal Processing, 22(6), 1374-1394.

% 1. read dat file (e.g. averaged data export from brain vision analyzer)
% 2. EMD and pearson correlation to reject noise
% 3. export dat file
% after process: wavelet, econnectome, plotting

%% clear before data
clear;
clc;

%% set parameters
% directory (Dir)
Dir.raw_dat = 'C:\Users\win\Desktop\3.export'; % read input directory (.dat)
Dir.result_mat = 'C:\Users\win\Desktop\result'; % save output directory (.mat)
% parameter (Param)
Param.PC_THR = 0.8; % Pearson correlation rejection threshold
clearvars -except Dir Param Temp Result
%% Main
% read file name
cd(Dir.raw_dat);

% initialize
Temp.eeg_files = dir('*.dat'); % read all eeg file in raw directory (preprocessing in Brain Analzer)
for eegFileNum = 1:length(Temp.eeg_files)
    Temp.dat{eegFileNum} = Temp.eeg_files(eegFileNum).name; % dat
    Temp.mat{eegFileNum} = strrep(Temp.dat{eegFileNum},'.dat', '.mat'); % mat
end
clearvars -except Dir Param Temp Result;

% trigger the data
for eegFileNum = 1:length(Temp.dat)
    cd(Dir.raw_dat);
    raw = importdata(Temp.dat{eegFileNum,1});
    dat = raw.data;
    for channelNum = 1:size(dat, 2)
        emd{channelNum} = rParabEmd__L(dat(:, channelNum), 50, 50, 1);
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
    highCorrArtifact = find((corrPVAL > Param.PC_THR)==1);
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
    Result.fileName{eegFileNum} = Temp.mat{eegFileNum};
    Result.dat{eegFileNum} = emdSum;
    clearvars -except Dir Param Temp Result;
end
clearvars -except Dir Param Temp Result;

%% Save result
cd(Dir.result_mat);
for eegFileNum = 1:length(Result.fileName)
    fileName = Result.fileName{eegFileNum};
    dat = Result.dat{eegFileNum};
    save(fileName,'dat');
    clearvars -except Dir Param Temp Result;
end
clearvars -except Dir Param Temp Result;