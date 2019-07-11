files = {
    fullfile('VPibv_10_11_02','calibration_CenterSpellerMVEP_VPibv')
    fullfile('VPibq_10_09_24','calibration_CenterSpellerMVEP_VPibq')
    fullfile('VPiac_10_10_13','calibration_CenterSpellerMVEP_VPiac')
    };


%% Define some settings
disp_ival= [-200 1000];
ref_ival= [-200 0];
crit_maxmin= 70;
crit_ival= [100 800];
crit_clab= {'F9,z,10','AF3,4'};
clab= {'Cz','PO7'};
colOrder= [1 0 1; 0.4 0.4 0.4];

%% load all data sets
nsub = length(files);
for isub = 1:nsub
    file = files{isub};
    file= fullfile(BTB.DataDir, 'demoMat', file);
    
    %% Load data
    fprintf('loading %s \n', file)
    
    [cnt, mrk, mnt] = file_loadMatlab(file);
        
    %% Apply highpass filter to reduce drifts
    b= procutil_firlsFilter(0.5, cnt.fs);
    cnt= proc_filtfilt(cnt, b);
    
    %% Artifact rejection based on variance criterion
    mrk= reject_varEventsAndChannels(cnt, mrk, disp_ival, 'verbose', 1);
    
    %% Segmentation
    epo= proc_segmentation(cnt, mrk, disp_ival);
    
    %% Artifact rejection based on maxmin difference criterion on frontal chans
    [epo iArte] = proc_rejectArtifactsMaxMin(epo, crit_maxmin, 'Clab',crit_clab, ...
        'Ival',crit_ival, 'Verbose',1);
    
    %% Baseline subtraction, and calculation of a measure of discriminability
    epo= proc_baseline(epo, ref_ival);
    
    epos_av{isub} = proc_average(epo, 'Stats', 1);
    
    % three different but almost equivalent ways to make statistics about class differences
    epos_diff{isub} = proc_classmeanDiff(epo, 'Stats', 1);
    epos_r{isub} = proc_rSquareSigned(epo, 'Stats', 1);
    epos_auc{isub} = proc_aucValues(epo, 'Stats', 1);
    
end


%% grand average
epo_av = proc_grandAverage(epos_av, 'Average', 'INVVARweighted', 'Stats', 1, 'Bonferroni', 1, 'Alphalevel', 0.01);
epo_r = proc_grandAverage(epos_r, 'Average', 'INVVARweighted', 'Stats', 1, 'Bonferroni', 1, 'Alphalevel', 0.01);
epo_diff = proc_grandAverage(epos_diff, 'Average', 'INVVARweighted', 'Stats', 1, 'Bonferroni', 1, 'Alphalevel', 0.01);
epo_auc = proc_grandAverage(epos_auc, 'Average', 'INVVARweighted', 'Stats', 1, 'Bonferroni', 1, 'Alphalevel', 0.01);

%% Select some discriminative intervals, with constraints to find N2, P2, P3 like components.
constraint= ...
    {{-1, [100 300], {'I#','O#','PO7,8','P9,10'}, [50 300]}, ...
    {1, [200 350], {'P3-4','CP3-4','C3-4'}, [200 400]}, ...
    {1, [400 500], {'P3-4','CP3-4','C3-4'}, [350 600]}};
[ival_scalps, nfo]= ...
    procutil_selectTimeIntervals(epo_r, 'Visualize', 0, 'VisuScalps', 1, ...
    'Title', util_untex(file), ...
    'Clab',{'not','E*'}, ...
    'Constraint', constraint);
%printFigure('r_matrix', [18 13]);
ival_scalps= visutil_correctIvalsForDisplay(ival_scalps, 'fs',epo.fs);

%% plot classwise grand-average ERPs
fig_set(1);
H= plot_scalpEvolutionPlusChannel(epo_av, mnt, clab, ival_scalps, defopt_scalp_erp, ...
    'ColorOrder',colOrder);
grid_addBars(epo_r);
%printFigure(['erp_topo'], [20  4+5*size(epo.y,1)]);

%% plot difference of the class means
fig_set(2, 'Resize',[1 2/3]);
plot_scalpEvolutionPlusChannel(epo_diff, mnt, clab, ival_scalps, defopt_scalp_r);
%printFigure(['erp_topo_r'], [20 9]);

% plot signed log10 p-values of the null hypothesis
% that the difference of the class means is zero
% interpretation: abs(sgnlogp) > 1   <-->  p < 0.1
%                 abs(sgnlogp) > 2   <-->  p < 0.01
%                 abs(sgnlogp) > 3   <-->  p < 0.001 , and so on
fig_set(3, 'Resize',[1 2/3]);
epo_diff_sgnlogp = epo_diff;
epo_diff_sgnlogp.x = epo_diff_sgnlogp.sgnlogp;
epo_diff_sgnlogp.yUnit = 'sgnlogp';
plot_scalpEvolutionPlusChannel(epo_diff_sgnlogp, mnt, clab, ival_scalps, defopt_scalp_r);
%printFigure(['erp_topo_r'], [20 9]);

%% now plot differences again, with all insignificant results set to zero
epo_diff.x = epo_diff.x.*epo_diff.sigmask;
fig_set(4, 'Resize',[1 2/3]);
plot_scalpEvolutionPlusChannel(epo_diff, mnt, clab, ival_scalps, defopt_scalp_r);

