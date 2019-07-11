function epo = load_SSVEP_Min_KU_data_new_format(path, sbj, condition_string, verbose)
% Loads all trials of the requested condition (1, 2, or 3) of the SSVEP data provided
% by Byoung-Kyong Min from Korea University (KU).
%

%% params

% HERE YOU HAVE TO SPECIFY THE FOLDER THAT CONTAINS THE SUBJECT DATA
%data_folder = '/home/sven/data/Data/BBCI_data/SSVEP_Min/SSVEP_NEW_Format/';
data_folder = [ path '/eEEG.Inlier/' ];

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
%    sbj_folder = sprintf('su%02d', sbj);
    
    if verbose
        fprintf('loading %s\n', file_name)
    end
%    dat = load(fullfile(data_folder, sbj_folder, file_name));
    dat = load(fullfile(data_folder, file_name));
    
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

	clab = {'Fp1' 'Fp2' 'F7' 'F3' 'Fz' 'F4' 'F8' 'FC5' 'FC1' 'FC2' 'FC6' 'T7' ...
			'C3' 'Cz' 'C4' 'T8'   'EOG'   'CP5' 'CP1' 'CP2' 'CP6'			...
			'P7' 'P3' 'Pz' 'P4' 'P8' 'PO9' 'O1' 'Oz' 'O2' 'PO10'};
%-------------------------------------------------------------------------------
%% 10:0.5:15 는 first harmonic && 가로와 세로의 주파수 합 포함!
%% 다른 방법: 가로+세로 주파수 합 only , 그리고 곱 only
%-------------------------------------------------------------------------------
BOIsum		=	[ 5+7.5 5.5+7 5.5+6 7.5+6 6.5+7 6.5+5 ];
BOImul		=	[ 5*7.5 5.5*7 5.5*6 7.5*6 6.5*7 6.5*5 ];
BOI			=	[ unique(BOIsum) unique(BOImul) ];

    epo_tmp = [];
    epo_tmp.x = dat.eEEG;
    epo_tmp.y = labels;
    epo_tmp.className = className;
    epo_tmp.fs = 500;
    epo_tmp.clab = clab;
	epo_tmp.band = [2, 50];
%	epo_tmp.band = [4, 50];
%	epo_tmp.band = [ 5, 7.5 ];	%[ 11.5, 13.5 ], [ 33, 45.5], [4, 50];
%	epo_tmp.band = [ 11.5, 13.5 ];	%, [ 33, 45.5], [4, 50];
%	epo_tmp.band = [ 33, 45.5];
    epo_tmp.t = (1:2500)/500;
	epo_tmp.bin = 1/2;		% freq gap is 0.5 Hz: ex) 4.0 4.5 5.0 5.5 / tigoum

    epo = proc_appendEpochs(epo, epo_tmp);
    
end

