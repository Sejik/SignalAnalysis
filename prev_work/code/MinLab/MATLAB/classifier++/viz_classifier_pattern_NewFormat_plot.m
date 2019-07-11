function []	=	viz_classifier_pattern_NewFormat_plot(PATH,	...
					Title,	condi,						...
					Freqs,	Band,	Bins,	FOI,	sFOI,	className,	mnt, ...
					patterns_cov_avg,					...
					patterns_corr_avg,					...
					patterns_corr_max_y_avg,			...
					patterns_cov,						...		% se �� all data
					patterns_corr,						...		% se �� all data
					patterns_corr_max_y)						% se �� all data

%% plot patterns, (indivisual | averaged over) channels
if ~isempty(condi)&isempty(regexp(condi,'.*_$')), condi=[condi '_']; end

save_figs	=	1;							% save figures or not
%fig_dir		=	fullfile(PATH, 'new_data_new_format');
fig_dir			=	PATH;
if save_figs && not(exist(fig_dir, 'dir')), mkdir(fig_dir); end

if nargin < 16, patterns_corr_max_y = []; end
if nargin < 15, patterns_corr = []; end
if nargin < 14, patterns_cov = []; end
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
%pat = patterns_cov_avg;
org = patterns_corr;
%org = patterns_cov;

figure('Position',[0 0 1024 576]);
rows		=	2;
cols		=	length(FOI);

% ----------
subplot(rows,cols,1:length(FOI))
	pat_avg	=	squeeze(mean(pat,2));					% ch �� ���� ���
	maxmin	=	max(abs(pat_avg(:)));					% �������� �ִ�ġ
	h		=	bar(Freqs, pat_avg);					% handle Ȯ��
	hold on;
	legend(className', 'Location','Best', 'Orientation','horizontal')
	title({'classifier pattern, averaged across channels,',					...
			'over full frequency spectrum'})
	xlabel('Frequency [Hz]')
	ylabel('Correlation coefficient')
	%% display standard error on bar graph
	if ~isempty(org),									% SE���� all data ������
	% sd�� ���ϱ� ���� �ڷ� ����: grand average�̹Ƿ�, subject�� ���� ���ؾ� ��
	% �̶�, ä�ε� ���� ���еǾ� �����Ƿ�(��� pat_avg ���ϴ� �ڵ庸�� ä��
	% ����� ����), ���� ä�θ� ��ճ� ��, subject�� ���� sd ���ؾ� �Ѵ�.
	yb		=	cat(1, h.YData);						% vector ���� �ϳ��� ����
	xb		=	bsxfun(@plus, h(1).XData, [h.XOffset]');%x bar�� �߰���ġ
					% ����, xb(b, f) ����, b == bar/freq, f == freq
	dat		=	squeeze(mean(org, 3));					% ch���:sbj x fq x class
	dat		=	permute(dat, [1 3 2]);					% sbj x class x fq
	SE		=	squeeze(std(dat) ./ sqrt(size(dat,1)-1));	% SE ���
	W		=	(xb(2,end)-xb(1,end))/2 * 0.8;			% ���� bar �� width/2
	for f	=	1 : size(yb,2)							% freq
	for b	=	1 : length(yb(:,1))						% bar(class) / freq
		plot([xb(b,f)-W xb(b,f)+W],[yb(b,f)+SE(b,f) yb(b,f)+SE(b,f)],'-k');%^����
		plot([xb(b,f)	xb(b,f)],  [yb(b,f)-SE(b,f) yb(b,f)+SE(b,f)],'-k');%|����
		plot([xb(b,f)-W xb(b,f)+W],[yb(b,f)-SE(b,f) yb(b,f)-SE(b,f)],'-k');%_����
	end	% for b
	end	% for f

	maxmin	=	max(abs(pat_avg(:))) + max(SE(:));		% �������� �ִ�ġ
	end	% if

%	xlim(Band)											% ��ü �뿪�� ��� �ȱ�
	xlim(Band([1,end]) + Bins*0.8*[-1,1])				% ���� ���� ���� �ֱ�
	set(gca, 'xTick', [Band(1):Bins:Band(end)]);
	ylim([-maxmin maxmin] + maxmin*0.1*[-1,1])			% ���� ���� ���� �ֱ�
	yTick	=	get(gca, 'yTick');
	if length(find(yTick>0)) <= 2						% tick������ �ʹ� ����
		yBin=	max(yTick) / 5;							% 5 ��� ����
		set(gca, 'yTick', [min(yTick):yBin:max(yTick)]);% �� ����
	end
	set(gca, 'yGrid','on');
	set(gca, 'TickDir','Out', 'TickLength',[0 0]) % tick ��輱 �۹���, ���� ����
	set(gca, 'LooseInset', get(gca, 'TightInset'));		% subplot ���� ��������

% ----------
for B = 1 : length(FOI)									% �������ļ� cell �� ����
subplot(rows,cols, cols + B)
	[~,f_idx] = ismember( FOI{B}, Freqs );				% ������ �뿪�� ����
	h		=	bar(Freqs(f_idx), squeeze(mean(pat(f_idx,:,:),2)));
	hold on;
	title({ [Title ': classifier pattern,'], sFOI{B} })	% ���� Ÿ��Ʋ
	xlabel('Frequency [Hz]')
	ylabel('Correlation coefficient')
	%% display standard error on bar graph
	if ~isempty(org),									% se���� all data ������
	yb		=	cat(1, h.YData);						% vector ���� �ϳ��� ����
	xb		=	bsxfun(@plus, h(1).XData, [h.XOffset]');%x bar�� �߰���ġ
					% ����, xb(b, f) ����, b == bar/freq, f == freq
	dat		=	squeeze(mean(org, 3));					% ch���:sbj x fq x class
	dat		=	permute(dat, [1 3 2]);					% sbj x class x fq
	dat		=	dat(:,:,f_idx);							% �ش� fq ���� data
	se		=	squeeze(std(dat) ./ sqrt(size(dat,1)-1));	% se ���
	W		=	(xb(2,end)-xb(1,end))/2 * 0.8;			% ���� bar �� width/2
	for f	=	1 : size(yb,2)							% freq
	for b	=	1 : length(yb(:,1))						% bar(class) / freq
		plot([xb(b,f)-W xb(b,f)+W],[yb(b,f)+se(b,f) yb(b,f)+se(b,f)],'-k');%^����
		plot([xb(b,f)	xb(b,f)],  [yb(b,f)-se(b,f) yb(b,f)+se(b,f)],'-k');%|����
		plot([xb(b,f)-W xb(b,f)+W],[yb(b,f)-se(b,f) yb(b,f)-se(b,f)],'-k');%_����
	end	% for b
	end	% for f
	end	% if

	if isequal(FOI{B}, [FOI{B}(1): Bins :FOI{B}(end)])	% ���?
		xlim(Freqs(f_idx([1,end])) + Bins*0.8*[-1,1])	% ���� ���� ���� �ֱ�
		set(gca, 'xTick', [Freqs(f_idx(1)):Bins:Freqs(f_idx(end))]);
	else	% ����� �ƴϸ�, �����Ͱ��� ������ �ٽ� ��� ��, ���� �� ���� ���
		mxBin=	arrayfun(@(x,y) x-y, FOI{B}(2:end), FOI{B}(1:end-1)); % gap
		mxBin=	max(abs(mxBin(:)));
		xlim(Freqs(f_idx([1,end])) + mxBin*0.8*[-1,1])	% ���� ���� ���� �ֱ�
		set(gca, 'xTick', [Freqs(f_idx)]);
	end
	ylim([-maxmin maxmin] + maxmin*0.1*[-1,1])			% ���� ���� ���� �ֱ�
	yTick	=	get(gca, 'yTick');
	if length(find(yTick>0)) <= 2						% tick������ �ʹ� ����
		yBin=	max(yTick) / 5;							% 5 ��� ����
		set(gca, 'yTick', [min(yTick):yBin:max(yTick)]);% �� ����
	end
	set(gca, 'TickDir','Out', 'TickLength',[0 0]) % tick ��輱 �۹���, ���� ����
	set(gca, 'yGrid','on');
	set(gca, 'LooseInset', get(gca, 'TightInset'));
	%BREAK
end

if save_figs & ( strcmp(Title, 'GrandAverage') | strcmp(Title, 'Average') )
	fname = sprintf('%s%s__classifier_pattern_avg_over_channels',	...
					condi, Title);
	my_save_fig(gcf, fullfile(fig_dir, fname), 35, 20)
end

%================================================================================
%% plot scalp maps, averaged over frequencies and classes

pat		=	patterns_corr_avg;			% fBins x ch x class
%pat	=	patterns_cov_avg;				% fBins x ch x class

pat		=	max(pat, [], 3);

sc_opt	=	[];
% sc_opt.ScalePos = 'none';
sc_opt.Contour = 0;
% sc_opt.Extrapolation = 0;					% ����ä�� �κ� ��ĥ ���� by tigoum

% CHOOSE THE FREQUENCIES OVER WHICH TO AVERAGE HERE
%AllFOI	=	{ FOI{:} Freqs };				% FOI���� �������� ���� �߰�
gFOI	=	cell2mat(FOI);					% FOI���� �������� ����
AllFOI	=	{ FOI{:} gFOI };				% gFOI�� grand average ������ ��ġ!
%AllFOI	=	table2cell(unique(cell2table(AllFOI')))';		% ��ұ��� ���� ����
AllFOI	=	cellfun(@(x) { num2str(x) }, AllFOI);			% ���ڿ� cell�� ��ȯ
AllFOI	=	unique(AllFOI);									% �ߺ�����
AllFOI	=	cellfun(@(x) { str2num(x) }, AllFOI);			% �ٽ� matrix ��ȯ
for B = 1 : length(AllFOI)					% drawing topo for each FOI
%band_of_interest = [5:0.5:7.5 10:15]; % stim-frequencies and first harmonics
%band_of_interest = [5:0.5:7.5 10:0.5:15]; % stim-frequencies and first harmonics
%band_of_interest = [5:0.5:7.5 AllFOI]; % stim-frequencies and first harmonics
% band_of_interest = [5:0.5:7.5]; % only stim-frequencies
% band_of_interest = [10:15]; % only first harmonics
%band_of_interest = [ AllFOI ]; % stim-frequencies and first harmonics
%[~,f_idx] = ismember(band_of_interest, Freqs);
	[~,f_idx] = ismember(AllFOI{B}, Freqs);

	figure
	m = pat;
	m = mean(m(f_idx, :, :),1); % average over frequency bins
	m = mean(m,3); % average over classes
	m = squeeze(m);
	plot_scalp(mnt, m, sc_opt)
	colormap jet

if isequal(AllFOI{B}, [AllFOI{B}(1): Bins :AllFOI{B}(end)])	% ���
	gapFreq	=	sprintf('[%04.1f~%04.1f]', AllFOI{B}(1), AllFOI{B}(end) );
else
	gapFreq	=	sprintf('[%04.1f,Sparse,%04.1f]', AllFOI{B}(1), AllFOI{B}(end) );
end
	title({ Title, sprintf('%s : %sHz', condi, gapFreq), 'classifier pattern', })

	if save_figs
		fname	=	sprintf('%s%s_%s__classifier_pattern_over_frequencies',	...
							gapFreq, condi, Title);
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
