function []	=	viz_classifier_pattern_NewFormat_plot(PATH,	...
						Title,	condition,					...
						Freqs,	Band,	className,	mnt,	...
						patterns_cov_avg,					...
						patterns_corr_avg,					...
						patterns_corr_max_y_avg)

%% plot patterns, (indivisual | averaged over) channels
save_figs	=	1;							% save figures or not

fig_dir		=	fullfile(PATH, 'new_data_new_format');
if save_figs && not(exist(fig_dir, 'dir')), mkdir(fig_dir); end
%{
size(Freqs)
% when indivisual :  1     77			% freq_bins
% when grand avg  :  1     77
size(patterns_cov_avg)
% when indivisual :  77    30     6		% freq_bins x ch x class(condi)
size(patterns_corr_avg)
% when indivisual :  77    30     6
size(patterns_corr_max_y_avg)
% when indivisual :  77    30
%}
figure
rows		=	2;
cols		=	3;

pat = patterns_corr_avg;
% pat = patterns_cov_avg;

subplot(rows,cols,1:3)
bar(Freqs, (squeeze(mean(pat,2))))
xlim(Band)
legend(className)
xlabel('frequency [Hz]')
title({'classifier pattern, averaged across channels,', 'over full frequency spectrum'})

subplot(rows,cols, cols + 1)
[~,f_idx] = ismember( 5:0.5:7.5, Freqs);
bar(Freqs(f_idx), (squeeze(mean(pat(f_idx,:,:), 2))))
xlim(Freqs(f_idx([1,end])) + 0.5*[-1,1])
xlabel('frequency [Hz]')
title({Title, 'classifier pattern,','over stimulation frequencies'})
%BREAK
%-------------------------------------------------------------------------------
%% 10:0.5:15 는 first harmonic && 가로와 세로의 주파수 합 포함!
%% 다른 방법: 가로+세로 주파수 합 only , 그리고 곱 only
%-------------------------------------------------------------------------------
BOIsum		=	[ 5+7.5 5.5+7 5.5+6 7.5+6 6.5+7 6.5+5 ];
BOImul		=	[ 5*7.5 5.5*7 5.5*6 7.5*6 6.5*7 6.5*5 ];
BOI			=	[ unique(BOIsum) unique(BOImul) ];

subplot(rows,cols, cols + (2:3))
%[~,f_idx] = ismember( 10:15, Freqs);
%[~,f_idx] = ismember( 10:1/2:15, Freqs);
[~,f_idx] = ismember( BOI, Freqs);
bar(Freqs(f_idx), (squeeze(mean(pat(f_idx,:,:), 2))))
xlim(Freqs(f_idx([1,end])) + 0.5*[-1,1])
xlabel('frequency [Hz]')
title({	Title,			...
		'classifier pattern,','over first harmonics of stimulation frequencies'})

if save_figs & ( strcmp(Title, 'GrandAverage') | strcmp(Title, 'Average') )
	fname = sprintf('%s_%s__classifier_pattern_avg_over_channels',	...
					condition, Title);
	my_save_fig(gcf, fullfile(fig_dir, fname), 35, 20)
end

%================================================================================
%% plot scalp maps, averaged over frequencies and classes

sc_opt = [];
sc_opt.ScalePos = 'none';
sc_opt.Contour = 0;
%sc_opt.Extrapolation = 0;					% 제거채널 부분 색칠 끄기 by tigoum

% CHOOSE THE FREQUENCIES OVER WHICH TO AVERAGE HERE
%band_of_interest = [5:0.5:7.5 10:15]; % stim-frequencies and first harmonics
%band_of_interest = [5:0.5:7.5 10:0.5:15]; % stim-frequencies and first harmonics
band_of_interest = [5:0.5:7.5 BOI]; % stim-frequencies and first harmonics
% band_of_interest = [5:0.5:7.5]; % only stim-frequencies
% band_of_interest = [10:15]; % only first harmonics
[~,f_idx] = ismember(band_of_interest, Freqs);

pat = patterns_corr_avg;
% pat = patterns_cov_avg;

pat = max(pat, [], 3);

sc_opt = [];
% sc_opt.ScalePos = 'none';
sc_opt.Contour = 0;

figure
m = pat;
m = mean(m(f_idx, :, :),1); % average over frequency bins
m = mean(m,3); % average over classes
m = squeeze(m);
plot_scalp(mnt, m, sc_opt)
colormap jet
title({ Title, 'classifier pattern' })

if save_figs
	fname = sprintf('%s_%s__classifier_pattern_over_frequencies',	...
					condition, Title);
	my_save_fig(gcf, fullfile(fig_dir, fname), 15, 15)
end

% figure
% rows = 1;
% cols = n_classes;
% for c_idx=1:n_classes
%     subplot(rows,cols,c_idx)
%     m = squeeze(mean(pat(f_idx, :, c_idx),1));
%     plot_scalp(mnt, m, sc_opt)
%     colormap jet
% end

return
