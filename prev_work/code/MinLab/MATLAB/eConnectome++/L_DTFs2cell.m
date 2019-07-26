% L_DTFs2cell ver 0.10
%% [�������� DTF ���Ͽ��� DTF.matrix �� �����Ͽ� �ϳ��� cell array �� �籸��]
%
% [*Input Parameter]--------------------------------------------------
% LoadPath: ���� Ȥ�� ���� path ����
%	���� paht: { 'su0001', 'su0002', ... }
%
% [*Output Parameter]--------------------------------------------------
% nFile: ó�� ����
%
% ex) L_Elec2DTF( l_Elec2DTF_SSVEP_NEW )
%
%------------------------------------------------------
% first created at 2016/07/05
% last  updated at 2016/07/05
% by Ahn Min-Hee::tigoum@naver.com, Korea Univ. MinLAB.
%.....................................................
% ver 0.10 : �⺻ ����
%------------------------------------------------------

function [ nFile ] = L_DTFs2cell(LoadPath, OUT_NAME)
%clearvars -except LoadPath fgSubordination
	if nargin < 2,	OUT_NAME = 'DTFall.mat'; end
	if nargin < 1,	help ('L_DTFs2cell'); return; end

	Total			=	tic;		%��ü ���� �ð�

	% load path �� �ִ� ��� data�� �б� ����, �켱 condition �� ���ϸ� Ȯ��
%	try,	fName	=	ls([ LoadPath '*.dat' ], '-1'); %���� str�� �ö��
%	catch,	fName	=	ls([ LoadPath '*.mat' ], '-1');	% dat ���н� mat�� ��õ�
%	end
	if iscell(LoadPath)									% ���� path �� �־���
		nFile		=	0;
		for Single	=	LoadPath
			nFile	=	nFile + L_DTFs2cell_SingleFolder(Single, OUT_NAME);
		end
	else
		nFile		=	L_DTFs2cell_SingleFolder(LoadPath, OUT_NAME);
	end

	toc(Total);

function [ nProc ] = L_DTFs2cell_SingleFolder(LoadPath, OUT_NAME) % ���� 1�� ó��

	tic
try, fName		=	ls(fullfile(char(LoadPath), '/*.mat'), '-1');
catch, error('data(mat) file not found'); end

	% �ϳ��� string �� ���ϸ������ �����Ѵ�
%	fName			=	regexprep(fName, '[ ]+', '\n');	% ' '�и��׸��� ���α���
	fName			=	strsplit(fName, '\n');		% ���Ϻ��� �и�
%	fName			=	struct2cell(fName);
%	fName			=	fName(1, :);				% �����̸���
	fName			=	fName( ~cellfun(@isempty, fName) );			% ���� ����

	% OUT_NAME �� fn �� ���Ե� �� �����Ƿ�, �����ؾ� ��.
	fName			=	fName( ~cellfun(@(x) strcmp(x,						...
									fullfile(LoadPath, OUT_NAME)), fName) );
%{
	Ext				=	regexprep(fName, '.*([.][a-zA-Z]+)$', '$1');% Ȯ����
%	[Ext, ix, Cnt]	=	unique(sort(Ext(find(~isempty(Ext)))));		% ����
	[Ext, ix, Cnt]	=	unique(sort(Ext(~cellfun(@isempty, Ext))));	% ����
	Cnt				=	histcounts(Cnt);			% �ߺ�����
	[~, ix]			=	max(Cnt);					% �ִ� ����
	Ext				=	char(Ext{ix});				% �ִ� ������ value ����
%}

	% ������ ��� �о ���ο� �ִ� DTF.matrix �� �����Ͽ� cell array �� ����
	DTF				=	cell(length(fName), 1);
	for ix			=	1: length(fName)
		each		=	load(fName{ix});

		% ���� ���� ���� matrix field �� ������ ����
		if ~isfield(each, 'DTF') | ~isfield(each.DTF, 'matrix'), continue; end

		DTF{ix}		=	each.DTF.matrix;			% matrix �� �����ؼ� ����
	end

	% DTFMAT �� [] �� �� ����
	DTF				=	DTF( ~cellfun(@isempty, DTF) );

	save(fullfile(char(LoadPath), OUT_NAME), 'DTF', '-v7.3');

	nProc			=	length(DTF);		toc		% ó�� ���� ����
	return