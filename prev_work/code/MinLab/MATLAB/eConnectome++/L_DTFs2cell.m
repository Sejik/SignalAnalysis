% L_DTFs2cell ver 0.10
%% [여러개의 DTF 파일에서 DTF.matrix 만 추출하여 하나의 cell array 로 재구성]
%
% [*Input Parameter]--------------------------------------------------
% LoadPath: 단일 혹은 여러 path 나열
%	여러 paht: { 'su0001', 'su0002', ... }
%
% [*Output Parameter]--------------------------------------------------
% nFile: 처리 갯수
%
% ex) L_Elec2DTF( l_Elec2DTF_SSVEP_NEW )
%
%------------------------------------------------------
% first created at 2016/07/05
% last  updated at 2016/07/05
% by Ahn Min-Hee::tigoum@naver.com, Korea Univ. MinLAB.
%.....................................................
% ver 0.10 : 기본 구현
%------------------------------------------------------

function [ nFile ] = L_DTFs2cell(LoadPath, OUT_NAME)
%clearvars -except LoadPath fgSubordination
	if nargin < 2,	OUT_NAME = 'DTFall.mat'; end
	if nargin < 1,	help ('L_DTFs2cell'); return; end

	Total			=	tic;		%전체 연산 시간

	% load path 에 있는 모든 data를 읽기 위해, 우선 condition 별 파일명 확보
%	try,	fName	=	ls([ LoadPath '*.dat' ], '-1'); %단일 str로 올라옴
%	catch,	fName	=	ls([ LoadPath '*.mat' ], '-1');	% dat 실패시 mat로 재시도
%	end
	if iscell(LoadPath)									% 여러 path 가 주어짐
		nFile		=	0;
		for Single	=	LoadPath
			nFile	=	nFile + L_DTFs2cell_SingleFolder(Single, OUT_NAME);
		end
	else
		nFile		=	L_DTFs2cell_SingleFolder(LoadPath, OUT_NAME);
	end

	toc(Total);

function [ nProc ] = L_DTFs2cell_SingleFolder(LoadPath, OUT_NAME) % 폴더 1개 처리

	tic
try, fName		=	ls(fullfile(char(LoadPath), '/*.mat'), '-1');
catch, error('data(mat) file not found'); end

	% 하나의 string 을 파일목록으로 구분한다
%	fName			=	regexprep(fName, '[ ]+', '\n');	% ' '분리항목을 라인구분
	fName			=	strsplit(fName, '\n');		% 파일별로 분리
%	fName			=	struct2cell(fName);
%	fName			=	fName(1, :);				% 파일이름만
	fName			=	fName( ~cellfun(@isempty, fName) );			% 공백 제거

	% OUT_NAME 도 fn 에 포함될 수 있으므로, 제외해야 함.
	fName			=	fName( ~cellfun(@(x) strcmp(x,						...
									fullfile(LoadPath, OUT_NAME)), fName) );
%{
	Ext				=	regexprep(fName, '.*([.][a-zA-Z]+)$', '$1');% 확장자
%	[Ext, ix, Cnt]	=	unique(sort(Ext(find(~isempty(Ext)))));		% 정제
	[Ext, ix, Cnt]	=	unique(sort(Ext(~cellfun(@isempty, Ext))));	% 정제
	Cnt				=	histcounts(Cnt);			% 중복갯수
	[~, ix]			=	max(Cnt);					% 최대 갯수
	Ext				=	char(Ext{ix});				% 최대 갯수인 value 선택
%}

	% 파일을 모두 읽어서 내부에 있는 DTF.matrix 만 추출하여 cell array 에 담자
	DTF				=	cell(length(fName), 1);
	for ix			=	1: length(fName)
		each		=	load(fName{ix});

		% 만약 읽은 값에 matrix field 가 없으면 무시
		if ~isfield(each, 'DTF') | ~isfield(each.DTF, 'matrix'), continue; end

		DTF{ix}		=	each.DTF.matrix;			% matrix 만 추출해서 저장
	end

	% DTFMAT 중 [] 인 것 제거
	DTF				=	DTF( ~cellfun(@isempty, DTF) );

	save(fullfile(char(LoadPath), OUT_NAME), 'DTF', '-v7.3');

	nProc			=	length(DTF);		toc		% 처리 갯수 리턴
	return
