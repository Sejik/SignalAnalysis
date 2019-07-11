function epo = load_SSVEP_Min_KU_data_new_format(sbj, condition_string, verbose)
% Loads all trials of the requested condition (1, 2, or 3) of the SSVEP data provided
% by Byoung-Kyong Min from Korea University (KU).
%

%% params

% HERE YOU HAVE TO SPECIFY THE FOLDER THAT CONTAINS THE SUBJECT DATA
data_folder = '/home/sven/data/Data/BBCI_data/SSVEP_Min/SSVEP_NEW_Format/';

if nargin < 3
    verbose = 0;
end

n_blocks = 4;

%% load the data
epo = [];
for block_idx=1:n_blocks
    
    
    %% create the filename and load the data of the current block
    file_name = sprintf('SSVEP_NEW_su%04d_%s_%d.mat', ...
        sbj, condition_string, block_idx);
    sbj_folder = sprintf('su%02d', sbj);
    
    if verbose
        fprintf('loading %s\n', file_name)
    end
    dat = load(fullfile(data_folder, sbj_folder, file_name));
    
    %% create class labels that match the BBCI toolbox format
    y = dat.eMRK;
    unique_markers = unique(y);
    n_classes = length(unique_markers);
    n_trials = length(y);
    labels = zeros(n_classes, n_trials);
    className = cell(1,n_classes);
    for c=1:n_classes
        labels(c, y==unique_markers(c) ) = 1;
        className{c} = sprintf('stimulus %d',c);
    end
    
    %% create the epoched data structure that matches the BBCI format

    clab = {'Fp1' 'Fp2' 'F7' 'F3' 'Fz' 'F4' 'F8' 'FC5' 'FC1' 'FC2' 'FC6' 'T7' 'C3' 'Cz' 'C4' 'T8' ...
        'EOG' 'CP5' 'CP1' 'CP2' 'CP6' 'P7' 'P3' 'Pz' 'P4' 'P8' 'PO9' 'O1' 'Oz' 'O2' 'PO10'};
    
    epo_tmp = [];
    epo_tmp.x = dat.eEEG;
    epo_tmp.y = labels;
    epo_tmp.className = className;
    epo_tmp.fs = 500;
    epo_tmp.clab = clab;
    epo_tmp.t = (1:2500)/500;

    epo = proc_appendEpochs(epo, epo_tmp);
    
end

