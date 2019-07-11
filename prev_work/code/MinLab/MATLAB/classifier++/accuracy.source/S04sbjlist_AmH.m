function [AllSubject,Head,Common,Ext] = S04sbjlist_AmH(LoadPath, fgSubordination)
	%% 지정된 folder에 있는 모든 subject list를 구성해 준다.
	% 각 subject에 대한 리스트는 [ output, input ] 순서로 ordering 됨.
	% 물론 옵션에 따라서 조절이 되겠지만, 해당 subject의 종속 목록도 추적해 준다.
	% ------------------------------
	% Usage: [ AllSubject ] = S04sbjlist_AmH(LoadPath, fgSubordination)
	% >LoadPath	: 조사하려는 folder
	% >fgSubord..: 각 subject의 종속 목록 추적 여부 : default = true
	%
	% >AllSubject: cell 타입의 목록
	% ex) sub0002, sub0002, sub0002_1, sub0002_2

%clearvars -except LoadPath fgSubordination

	%Total			=	tic;		%전체 연산 시간

	if nargin < 2,	fgSubordination = true; end
	if nargin < 1,	help ('S04sbjlist_AmH'); return; end

	% load path 에 있는 모든 data를 읽기 위해, 우선 condition 별 파일명 확보
%	try,	fName	=	ls([ LoadPath '*.dat' ], '-1'); %단일 str로 올라옴
%	catch,	fName	=	ls([ LoadPath '*.mat' ], '-1');	% dat 실패시 mat로 재시도
%	end
	fName		=	'';
	sEXT		=	{ 'dat', 'txt', 'mat' };
	for ext		=	sEXT
		try, fn	=	ls([ LoadPath '/*.' char(ext) ], '-1'); catch, fn = ''; end
		fName	=	[ fName fn ];
	end

%	fName		=	regexprep(fName, '[ ]+', '\n');	% 공백분리 항목을 라인구분
	fName		=	strsplit(fName, '\n');			% 파일별로 분리
%	fName		=	struct2cell(fName);
%	fName		=	fName(1, :);					% 파일이름만
	Ext			=	regexprep(fName, '.*([.][a-zA-Z]+)$', '$1');	% 확장자
	[Ext, ix, Cnt]	=	unique(sort(Ext(find(~isempty(Ext)))));		% 정제
	Cnt			=	histcounts(Cnt);				% 중복갯수
	[~, ix]		=	max(Cnt);						% 최대 갯수
	Ext			=	char(Ext{ix});					% 최대 갯수인 value 선택

%	fName		=	regexprep(fName, [LoadPath '/(.*)[.][a-zA-Z]+$'], '$1');%이름
	fName		=	regexprep(fName, '.*/([^/]+)[.][a-zA-Z]+$', '$1');	%이름만
%	fName		=	regexprep(fName, ['^([A-Za-z_]+su[0-9]+).*'], '$1');%이름분리
	Common		=	fName;							% 후반의 공통 이름 찾기 용
	fName		=	regexprep(fName, ['^(.*)(su[0-9]+)(_[0-9]+)*.*$'], '$1$2$3');
	ix			=	regexp(fName, ['^[A-Za-z0-9_]+su[0-9]+'], 'match');
	ix			=	cellfun(@(x)( ~isempty(x) ), ix);	% 각 셀별로 비었는지
	ix			=	find( ix );						% 내용이 있는 것의 index 만
	fName		=	fName( ix );					% 해당 파일명 확보
	fName		=	unique(sort(fName));			% 이름이 중복 가능함

	% 뒷 이름이 단일하면 좋은데, 가끔 섞인 경우, 최대 갯수인 것을 선택한다.
	Common		=	regexprep(Common, ['^.*su[0-9]+(_[0-9]+)*'], '');	%앞 제거
	Common		=	regexprep(Common,['(_[^_]+)' '(_[a-zA-Z0-9]+)*$'],'$1');%뒷
%	Common		=	regexprep(Common,['_(.+[^\w])' '[a-zA-Z0-9]+$'],'$1')%뒷 이름
	Common		=	Common( ix );
	[Common, ix, Cnt]	=	unique(Common);			% 중복제거
	Cnt			=	histcounts(Cnt);				% 중복갯수
	ix			=	find( Cnt/sum(Cnt) > 0.8 );		% 80% 이상 비율 존재하면!
	if isempty( ix )								% 없으면 다른 의미 문자열 임
		Common	=	'';
	else
		Common	=	Common{ix};						% 최대 갯수인 value 선택
	end

	% 하나의 파일이름을 3개의 토큰으로 분리: 이름, 번호, 종속번호(문자포함 가능)
	lName		=	regexp(fName, ['^(.*)(su[0-9]+)(.*)$'], 'tokens'); % 3개 토큰
%	lName{1}{:}

	% 이름에 딸린 숫자로 그룹핑, 종속파일이 있을 수 있음
	lGroup		=	{;};
	ix			=	0;
%	for l = 1 : length(lName)
%		each	=	lName{l}{1};
	for l		=	lName
		each	=	l{1}{1};

		% 숫자별로 groupping 해야 함.
		if isempty(lGroup) | ~strcmp(lGroup{ix}{1}, each{1}) % 등록안된 신규이름
			ix	=	ix+1;
			lGroup{ix}{1}	=	each{1};
			lGroup{ix}{2}	=	each{2};				% output 이름에 해당
			lGroup{ix}{3}	=	{ [each{2} each{3}] };	% input 이름에 해당

		elseif ~strcmp(lGroup{ix}{2}, each{2})			% 등록안된 번호
			ix	=	ix+1;
			lGroup{ix}{1}	=	each{1};
			lGroup{ix}{2}	=	each{2};				% output 이름에 해당
			lGroup{ix}{3}	=	{ [each{2} each{3}] };	% input 이름에 해당

		elseif strcmp(lGroup{ix}{1}, each{1}) & strcmp(lGroup{ix}{2}, each{2})
			lGroup{ix}{3}	=	{ lGroup{ix}{3}{:} [each{2} each{3}] }; % 추가
		end
	end

	% groupping 다 됐으면, 그룹별로 목록화
%	HeadName	=	sprintf('HeadName = %s\n\n', lGroup{1}{1});
	Head		=	regexprep(lGroup{1}{1}, '[_]+$', '');	% 끝의 '_' 제거
	AllSubject	=	cell(1, length(lGroup));
	for g = 1 : length(lGroup)
		% { 'su0027',		'su0027', 'su0027_2', 'su0027_3', },	...
%		AllSubject{g}=	sprintf('\t''%s'',\t\t''%s'',\n',					...
%										char(lGroup{g}{2}),					...
%										strjoin(lGroup{g}{3:end}, ''', ''') );
		AllSubject{g}{1}	=	lGroup{g}{2};			% output 이름

		for in = 1 : length(lGroup{g}{3})				% input 이름 list
		AllSubject{g}{in+1}	=	lGroup{g}{3}{in};
		end
	end

	return
