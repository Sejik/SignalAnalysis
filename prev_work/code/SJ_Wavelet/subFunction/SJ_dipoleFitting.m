function [dipoleResult, dipoleDistanceResult] = SJ_dipoleFitting(param, temp, data)
cd(param.subInputDir);
filename = param.conditionVHDR;
load('headmodel_eeg.mat');
load('mri_resliced_cm.mat');
x = [80.8000000000000;80.8000000000000;49.9000000000000;57.6000000000000;60.7000000000000;57.6000000000000;49.9000000000000;28.8000000000000;32.4000000000000;32.4000000000000;28.8000000000000;5.18000000000000e-15;3.87000000000000e-15;5.20000000000000e-15;3.87000000000000e-15;5.18000000000000e-15;-28.8000000000000;-32.4000000000000;-32.4000000000000;-28.8000000000000;-49.9000000000000;-57.6000000000000;-60.7000000000000;-57.6000000000000;-49.9000000000000;-61.5000000000000;-80.8000000000000;-85;-80.8000000000000;-61.5000000000000];
y = [26.1000000000000;-26.1000000000000;68.4000000000000;48.2000000000000;0;-48.1000000000000;-68.4000000000000;76.2000000000000;32.4000000000000;-32.4000000000000;-76.2000000000000;84.5000000000000;63.2000000000000;0;-63.2000000000000;-84.5000000000000;76.2000000000000;32.4000000000000;-32.4000000000000;-76.2000000000000;68.4000000000000;48.2000000000000;-7.44000000000000e-15;-48.1000000000000;-68.4000000000000;43.6000000000000;26.1000000000000;-1.04000000000000e-14;-26.1000000000000;-43.5000000000000];
z = [-4;-4;-7.49000000000000;39.9000000000000;59.5000000000000;39.9000000000000;-7.49000000000000;24.2000000000000;71.6000000000000;71.6000000000000;24.2000000000000;-8.85000000000000;56.9000000000000;85;56.9000000000000;-8.85000000000000;24.2000000000000;71.6000000000000;71.6000000000000;24.2000000000000;-7.49000000000000;39.9000000000000;59.5000000000000;39.9000000000000;-7.49000000000000;-39.3000000000000;-4;-1.79000000000000;-4;-39.3000000000000];
labels = {'Fp1';'Fp2';'F7';'F3';'Fz';'F4';'F8';'FC5';'FC1';'FC2';'FC6';'T7';'C3';'Cz';'C4';'T8';'CP5';'CP1';'CP2';'CP6';'P7';'P3';'Pz';'P4';'P8';'PO9';'O1';'Oz';'O2';'PO10'};
cfg = [];
cfg.dataset = filename;
data_eeg = ft_preprocessing(cfg);

for subjectNum = 1:size(data,1)
    data_eeg.trial{1} = squeeze(data(subjectNum,:,:));
    data_eeg.time{1} = temp.currentLatency(1):temp.currentLatency(2);
    data_eeg.time{1} = data_eeg.time{1}/param.fs;
    
    cfg = [];
    timelock_eeg_all = ft_timelockanalysis(cfg, data_eeg);
    
    timelock_eeg_all.elec.chanpos = [x y z];
    timelock_eeg_all.elec.elecpos = [x y z];
    timelock_eeg_all.elec.label = labels;
    
    cfg = [];
    cfg.numdipoles = 2;
    cfg.symmetry = 'x';
    cfg.grid.resolution = 1;
    cfg.grid.unit = 'cm';
    cfg.nonlinear = 'yes';
    cfg.gridsearch = 'yes';
    cfg.dipfit.display = 'off';
    cfg.vol = headmodel_eeg;
    cfg.senstype = 'eeg';
    cfg.channel = 'all';
    source_eeg = ft_dipolefitting(cfg, timelock_eeg_all);
    
    leftDistance = sqrt(sum((param.controlPoint{1} - source_eeg.dip.pos(1,:)*10).^2));
    rightDistance = sqrt(sum((param.controlPoint{2} - source_eeg.dip.pos(2,:)*10).^2));
    averageDistance = (leftDistance + rightDistance) / 2;
    
    dipoleResult(subjectNum,:, :) = source_eeg.dip.pos .* 10;
    dipoleDistanceResult(subjectNum) = averageDistance;
end
end