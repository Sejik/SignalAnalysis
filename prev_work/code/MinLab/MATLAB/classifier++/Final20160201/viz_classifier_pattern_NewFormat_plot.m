function []	=	viz_classifier_pattern_NewFormat_plot(PATH,	...
						Title,	condi,						...
						Freqs,	Band,	BOI,	sBOI,	className,	mnt,	...
						patterns_cov_avg,					...
						patterns_corr_avg,					...
						patterns_corr_max_y_avg)

%% plot patterns, (indivisual | averaged over) channels
if ~isempty(condi)&isempty(regexp(condi,'.*_$')), condi=[condi '_']; end

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
pat = patterns_corr_avg;
% pat = patterns_cov_avg;

figure
rows		=	2;
cols		=	length(BOI);

subplot(rows,cols,1:length(BOI))
bar(Freqs, (squeeze(mean(pat,2))))
xlim(Band)												% 전체 대역을 모두 훑기
legend(className)
xlabel('frequency [Hz]')
title({'classifier pattern, averaged across channels,',						...
		'over full frequency spectrum'})

for b = 1 : length(BOI)									% 관심주파수 cell 별 도식
	subplot(rows,cols, cols + b)
	[~,f_idx] = ismember( BOI{b}, Freqs );				% 저주파 대역만 구성
	bar(Freqs(f_idx), (squeeze(mean(pat(f_idx,:,:), 2))))
	xlim(Freqs(f_idx([1,end])) + 0.5*[-1,1])
	xlabel('frequency [Hz]')
	title({ Title, 'classifier pattern,', sBOI{b} })	% 종속 타이틀
	%BREAK
end

if save_figs & ( strcmp(Title, 'GrandAverage') | strcmp(Title, 'Average') )
	fname = sprintf('%s%s__classifier_pattern_avg_over_channels',	...
					condi, Title);
	my_save_fig(gcf, fullfile(fig_dir, fname), 35, 20)
end

%================================================================================
%% plot scalp maps, averaged over frequencies and classes

sc_opt = [];
sc_opt.ScalePos = 'none';
sc_opt.Contour = 0;
%sc_opt.Extrapolation = 0;					% 제거채널 부분 색칠 끄기 by tigoum

% CHOOSE THE FREQUENCIES OVER WHICH TO AVERAGE HERE
%AllBOI	=	{ BOI{:} Freqs };		% BOI들을 한통으로 묶음 추가
gBOI	=	cell2mat(BOI);					% BOI들을 한통으로 묶음
AllBOI	=	{ BOI{:} gBOI };				% gBOI가 grand average 용으로 가치!
for b = 1 : length(AllBOI)					% drawing topo for each BOI
%band_of_interest = [5:0.5:7.5 10:15]; % stim-frequencies and first harmonics
%band_of_interest = [5:0.5:7.5 10:0.5:15]; % stim-frequencies and first harmonics
%band_of_interest = [5:0.5:7.5 AllBOI]; % stim-frequencies and first harmonics
% band_of_interest = [5:0.5:7.5]; % only stim-frequencies
% band_of_interest = [10:15]; % only first harmonics
%band_of_interest = [ AllBOI ]; % stim-frequencies and first harmonics
%[~,f_idx] = ismember(band_of_interest, Freqs);
	[~,f_idx] = ismember(AllBOI{b}, Freqs);

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
	title({ Title,															...
	sprintf('%s : [%0.1f~%0.1f Hz]', condi, AllBOI{b}(1), AllBOI{b}(end) ),	...
			'classifier pattern', })

	if save_figs
		fname	=	sprintf(['%s[%04.1f~%04.1f]_%s__classifier_pattern_'	...
				'over_frequencies'], condi, AllBOI{b}(1), AllBOI{b}(end), Title);
		fname	=	regexprep(fname, '[.]', ',');		% convert '.' -> ','
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
end

return
