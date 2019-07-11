function epo = load_Min_KU_data_new_format(PATH, com, sbj, condi,	...
								blocks_list, fwin, ts, twin, nchan, verbose)
% Loads all trials of the requested condition (1, 2, or 3) of the data provided
% by Byoung-Kyong Min from Korea University (KU).
% CAUTION: n_block type changed! : number(ex:4) -> vector(ex:[1:4])
%	and name changed n_blocks -> blocks_list
% PARAM: ts == whole time series, entire time range

%% params

% HERE YOU HAVE TO SPECIFY THE FOLDER THAT CONTAINS THE SUBJECT DATA
%data_folder	= '/home/sven/data/Data/BBCI_data/SSVEP_Min/SSVEP_NEW_Format/';
%data_folder	= [ path '/eEEG.Inlier/' ];
data_folder		= PATH;

if nargin < 4,	verbose = 0; end
if ~isempty(com) & isempty(regexp(com,  '.*_$')), com =[ com   '_']; end % 끝'_'+
if ~isempty(condi)&isempty(regexp(condi,'.*_$')), condi=[condi '_']; end

%% load the data
epo = [];
%for block_idx=1:n_blocks
for block_idx = blocks_list

    %% create the filename and load the data of the current block
%	file_name = sprintf('SSVEP_NEW_su%04d_%s_%d.mat', ...
%						sbj, condi, block_idx);
	file_name = sprintf('%s%s_%s%d.mat', com, sbj, condi, block_idx);
%	sbj_folder = sprintf('su%02d', sbj);

	if verbose
		fprintf('loading %s\n', file_name)
	end
%	dat = load(fullfile(data_folder, sbj_folder, file_name));
	dat			=	load(fullfile(data_folder, file_name));

	%% create marker labels that match the BBCI toolbox format
	y			=	dat.eMRK;
	classes		=	unique(y);
	n_classes	=	length(classes);
	n_trials	=	length(y);
	labels		=	zeros(n_classes, n_trials);
	className	=	cell(1,n_classes);
%	for c=1:n_classes
%		labels(c, y==classes(c) ) = 1;
%		className{c} = sprintf('stimulus %d',c);
%	end
	labels		=	repmat(unique(y)', 1, n_trials) == repmat(y, n_classes, 1);
	className	=	arrayfun(@(x)({ sprintf('stimulus %d', x) }), [1:n_classes]);

	%% create the epoched data structure that matches the BBCI format
if nchan + 1 == 31					% 30 + EOG
	clab	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',			'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
elseif nchan + 1 == 64				% 63 + EOG
	clab	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'FCz',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',  'PO10',...
				'AF7',	'AF3',	'AF4',	'AF8',	'F5',	'F1',	'F2',	'F6', ...
				'FT9',	'FT7',	'FC3',	'FC4',	'FT8',	'FT10',	'C5',	'C1', ...
				'C2',	'C6',	'TP7',	'CP3',	'CPz',	'CP4',	'TP8',	'P5', ...
				'P1',	'P2',	'P6',	'PO7',	'PO3',	'POz',	'PO4',	'PO8' };

elseif nchan + 0 == 2				% for Brodmann area ( not EEG electrode 1)
	clab	={	'BA10L', 'BA10R', };
end

%--------------------------------------------------------------------------------
	fs					= dat.eFS;
	epo_tmp				= [];
	epo_tmp.clab		= clab;
%	epo_tmp.band		= [4, 50];
%	epo_tmp.band		= [ 5, 7.5 ];	%[ 11.5, 13.5 ], [ 33, 45.5], [4, 50];
%	epo_tmp.band		= [ 11.5, 13.5 ];		%, [ 33, 45.5], [4, 50];
%	epo_tmp.band		= [ 33, 45.5];
	epo_tmp.band		= fwin;
	epo_tmp.fs			= fs;

%	tidx				= [twin(1)*(fs/1000)+1:twin(2)*(fs/1000)];	%index구성
%	epo_tmp.t			= (1:2500)/500;
%	epo_tmp.t			= tidx / fs;			% index 기준으로 샘플링 시간 구성
												% (1:2500)/500 , (1001:3000)/500;
	epo_tmp.t			= [twin(1)/1000: 1/fs : (twin(2)-1)/1000]; % 시간구간구성

%	epo_tmp.marker		= dat.eMRK;				% eEEG의 epoch 수와 대응
	epo_tmp.className	= className;			% 자극 갯수

	tidx				= find(ismember([ts(1)  : 1000/fs : ts(2)],		...
										[twin(1): 1000/fs : twin(2)-1]));
%	epo_tmp.x			= dat.eEEG;
	epo_tmp.x			= dat.eEEG(tidx,:,:);	% 유효data만 추출, tp x ch x ep
	epo_tmp.y			= labels;				% marker * trial

	marker				=	dat.eMRK;
	if isfield(epo, 'marker')					% marker 도 append 해줘야 함
		marker			=	[ epo.marker marker ];	% append
	end

	epo = proc_appendEpochs(epo, epo_tmp);
	epo.marker			=	marker;				% 추가 및 append 값 갱신
end
