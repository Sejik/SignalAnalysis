% B_reverseTime ver 0.10
% - reverse input mat (3D data form or econnectome form) to output
%
% usage: B_reverseTime( input file, output file )
%
%------------------------------------------------------
% first created at 2016/05/19
% last  updated at 2016/05/19
% by Ahn Min-Hee::tigoum@naver.com, Korea Univ. MinLAB.
%.....................................................
% ver 0.10 : reverse data at time series
%------------------------------------------------------

function [ BOOL ] = B_reverseTime( Infile, Outfile )

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Total			=	tic;		%��ü ���� �ð�

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	if ~exist(Infile, 'file'), error('File not found: %s', Infile); end

	% load data & get field
	DAT				=	load(Infile);
	Field			=	fieldnames(DAT);

	% extract each data
	if length(Field) == 1 & isstruct(DAT.(Field{1}))	% it is econ form
		EEG			=	DAT.(Field{1});
		[eEEG, eCHN, eFS, eMRK]	=	deal(EEG.data, EEG.labels, EEG.srate, []);
	else												% it is 3D form
		[eEEG, eCHN, eFS, eMRK]	=	deal(DAT.eEEG, DAT.eCHN, DAT.eFS, DAT.eMRK);
	end

	% finding data dimention & reverse process
	if ndims(eEEG) == 1									% single vector
		eEEGa		=	eEEG ([size(eEEG, 1):-1:1]);	% reverse time
		eEEGb		=	eEEGa([size(eEEGa,1):-1:1]);	% re-reverse time
	elseif ndims(eEEG) == 2								% its eCon
		if size(eEEG,1) < size(eEEG,2), eEEG = permute(eEEG, [2 1]); end %tp x ch
		eEEGa		=	eEEG ([size(eEEG,1):-1:1], :);
		eEEGb		=	eEEGa([size(eEEG,1):-1:1], :);
	elseif ndims(eEEG) == 3								% 3D form
		% find time dim
		[mxlen mxix]=	max(size(eEEG));				% max dim

		% select time dim & reverse
		ix			=	arrayfun(@(x) {':'}, 1:ndims(eEEG));% indexing slice
		ix{mxix}	=	'mxlen:-1:1';					% set max dim to new val
		eval(['eEEGa	=	eEEG (' strjoin(ix, ',') ');']);
		eval(['eEEGb	=	eEEGa(' strjoin(ix, ',') ');']);
	end

	% check result vaildation
	if isequal(eEEGb, eEEG)
		fprintf('[Pass]  : inversion data equal than origins...\n');
	else
		fprintf('Warning : inversion data mismatch than original data...\n');
	end
	eEEG			=	eEEGa;

	% storing
	if length(Field) == 1 & isstruct(DAT.(Field{1}))	% it is econ form
		SAVEeEEG2eCon( Outfile, eEEG, eCHN, eFS );
	else
		[DIR, name, ext]=	fileparts(Outfile);
		if ~isempty(DIR) & not(exist(DIR, 'dir')), mkdir(DIR); end

	if isempty(ext),save([Outfile '.mat'],'eEEG','eCHN','eFS','eMRK','-v7.3');...
	else,			save(Outfile,  'eEEG','eCHN','eFS','eMRK', '-v7.3'); end
	end

	return

%--------------------------------------------------------------------------------
function [ BOOL ] = SAVEeEEG2eCon( OUT_NAME, eEEG, eCHN, eFS )
	EEG				=	struct;

	EEG.name		=	OUT_NAME;					% the name for the EEG data
	EEG.org_dims	=	size(eEEG);					% ���� ����: dp x ch
	EEG.data		=	permute(eEEG, [2 1]);		% chan x data(dp)
%	EEG.data		=	reshape(EEG.data, EEG.org_dims(2), []);	% ch x (tr x dp)
		% a 2D array ([m,n]) for EEG time series where m = nbchan and n = points
	EEG.type		=	'EEG';	% the type of data, 'EEG'(����X), 'ECOG' or 'MEG'
	EEG.unit		=	'uV^2';						% data�� ����
	EEG.nbchan		=	EEG.org_dims(2);			% the number of channels
	EEG.points		=	size(EEG.data, 2);			% # of sampling points
	EEG.srate		=	eFS;						% sampling rate
	EEG.labeltype	=	'standard';					% channel location
													% 10-10, 10-20: 'standard'
													% �̿��� ��� 'custom' ǥ��
	EEG.labels		=	eCHN';						% a cell array of chan labels
				% channel name(������ ����ϴ� �� ���� �η��� �ƴ� �� ���� �Է�)
%	EEG.marker		=	eeg.eMRK';					% append by tigoum

	[DIR, name, ext]=	fileparts(OUT_NAME);
	if ~isempty(DIR) & not(exist(DIR, 'dir')), mkdir(DIR); end

	% �����Ŀ� ����: Ȯ����, ���嵥���� ����, ������ ���� ����Ͽ� ���
	if isempty(ext),	save([OUT_NAME '.mat'],'EEG', '-v7.3');				...
	else,				save(OUT_NAME, 'EEG', '-v7.3'); end

	BOOL			=	true;
	return

