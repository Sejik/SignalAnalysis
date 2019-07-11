function [AllSubject,Head,Common,Ext] = S04sbjlist_AmH(LoadPath, fgSubordination)
	%% ������ folder�� �ִ� ��� subject list�� ������ �ش�.
	% �� subject�� ���� ����Ʈ�� [ output, input ] ������ ordering ��.
	% ���� �ɼǿ� ���� ������ �ǰ�����, �ش� subject�� ���� ��ϵ� ������ �ش�.
	% ------------------------------
	% Usage: [ AllSubject ] = S04sbjlist_AmH(LoadPath, fgSubordination)
	% >LoadPath	: �����Ϸ��� folder
	% >fgSubord..: �� subject�� ���� ��� ���� ���� : default = true
	%
	% >AllSubject: cell Ÿ���� ���
	% ex) sub0002, sub0002, sub0002_1, sub0002_2

%clearvars -except LoadPath fgSubordination

	%Total			=	tic;		%��ü ���� �ð�

	if nargin < 2,	fgSubordination = true; end
	if nargin < 1,	help ('S04sbjlist_AmH'); return; end

	% load path �� �ִ� ��� data�� �б� ����, �켱 condition �� ���ϸ� Ȯ��
%	try,	fName	=	ls([ LoadPath '*.dat' ], '-1'); %���� str�� �ö��
%	catch,	fName	=	ls([ LoadPath '*.mat' ], '-1');	% dat ���н� mat�� ��õ�
%	end
	fName		=	'';
	sEXT		=	{ 'dat', 'txt', 'mat' };
	for ext		=	sEXT
		try, fn	=	ls([ LoadPath '/*.' char(ext) ], '-1'); catch, fn = ''; end
		fName	=	[ fName fn ];
	end

%	fName		=	regexprep(fName, '[ ]+', '\n');	% ����и� �׸��� ���α���
	fName		=	strsplit(fName, '\n');			% ���Ϻ��� �и�
%	fName		=	struct2cell(fName);
%	fName		=	fName(1, :);					% �����̸���
	Ext			=	regexprep(fName, '.*([.][a-zA-Z]+)$', '$1');	% Ȯ����
	[Ext, ix, Cnt]	=	unique(sort(Ext(find(~isempty(Ext)))));		% ����
	Cnt			=	histcounts(Cnt);				% �ߺ�����
	[~, ix]		=	max(Cnt);						% �ִ� ����
	Ext			=	char(Ext{ix});					% �ִ� ������ value ����

%	fName		=	regexprep(fName, [LoadPath '/(.*)[.][a-zA-Z]+$'], '$1');%�̸�
	fName		=	regexprep(fName, '.*/([^/]+)[.][a-zA-Z]+$', '$1');	%�̸���
%	fName		=	regexprep(fName, ['^([A-Za-z_]+su[0-9]+).*'], '$1');%�̸��и�
	Common		=	fName;							% �Ĺ��� ���� �̸� ã�� ��
	fName		=	regexprep(fName, ['^(.*)(su[0-9]+)(_[0-9]+)*.*$'], '$1$2$3');
	ix			=	regexp(fName, ['^[A-Za-z0-9_]+su[0-9]+'], 'match');
	ix			=	cellfun(@(x)( ~isempty(x) ), ix);	% �� ������ �������
	ix			=	find( ix );						% ������ �ִ� ���� index ��
	fName		=	fName( ix );					% �ش� ���ϸ� Ȯ��
	fName		=	unique(sort(fName));			% �̸��� �ߺ� ������

	% �� �̸��� �����ϸ� ������, ���� ���� ���, �ִ� ������ ���� �����Ѵ�.
	Common		=	regexprep(Common, ['^.*su[0-9]+(_[0-9]+)*'], '');	%�� ����
	Common		=	regexprep(Common,['(_[^_]+)' '(_[a-zA-Z0-9]+)*$'],'$1');%��
%	Common		=	regexprep(Common,['_(.+[^\w])' '[a-zA-Z0-9]+$'],'$1')%�� �̸�
	Common		=	Common( ix );
	[Common, ix, Cnt]	=	unique(Common);			% �ߺ�����
	Cnt			=	histcounts(Cnt);				% �ߺ�����
	ix			=	find( Cnt/sum(Cnt) > 0.8 );		% 80% �̻� ���� �����ϸ�!
	if isempty( ix )								% ������ �ٸ� �ǹ� ���ڿ� ��
		Common	=	'';
	else
		Common	=	Common{ix};						% �ִ� ������ value ����
	end

	% �ϳ��� �����̸��� 3���� ��ū���� �и�: �̸�, ��ȣ, ���ӹ�ȣ(�������� ����)
	lName		=	regexp(fName, ['^(.*)(su[0-9]+)(.*)$'], 'tokens'); % 3�� ��ū
%	lName{1}{:}

	% �̸��� ���� ���ڷ� �׷���, ���������� ���� �� ����
	lGroup		=	{;};
	ix			=	0;
%	for l = 1 : length(lName)
%		each	=	lName{l}{1};
	for l		=	lName
		each	=	l{1}{1};

		% ���ں��� groupping �ؾ� ��.
		if isempty(lGroup) | ~strcmp(lGroup{ix}{1}, each{1}) % ��Ͼȵ� �ű��̸�
			ix	=	ix+1;
			lGroup{ix}{1}	=	each{1};
			lGroup{ix}{2}	=	each{2};				% output �̸��� �ش�
			lGroup{ix}{3}	=	{ [each{2} each{3}] };	% input �̸��� �ش�

		elseif ~strcmp(lGroup{ix}{2}, each{2})			% ��Ͼȵ� ��ȣ
			ix	=	ix+1;
			lGroup{ix}{1}	=	each{1};
			lGroup{ix}{2}	=	each{2};				% output �̸��� �ش�
			lGroup{ix}{3}	=	{ [each{2} each{3}] };	% input �̸��� �ش�

		elseif strcmp(lGroup{ix}{1}, each{1}) & strcmp(lGroup{ix}{2}, each{2})
			lGroup{ix}{3}	=	{ lGroup{ix}{3}{:} [each{2} each{3}] }; % �߰�
		end
	end

	% groupping �� ������, �׷캰�� ���ȭ
%	HeadName	=	sprintf('HeadName = %s\n\n', lGroup{1}{1});
	Head		=	regexprep(lGroup{1}{1}, '[_]+$', '');	% ���� '_' ����
	AllSubject	=	cell(1, length(lGroup));
	for g = 1 : length(lGroup)
		% { 'su0027',		'su0027', 'su0027_2', 'su0027_3', },	...
%		AllSubject{g}=	sprintf('\t''%s'',\t\t''%s'',\n',					...
%										char(lGroup{g}{2}),					...
%										strjoin(lGroup{g}{3:end}, ''', ''') );
		AllSubject{g}{1}	=	lGroup{g}{2};			% output �̸�

		for in = 1 : length(lGroup{g}{3})				% input �̸� list
		AllSubject{g}{in+1}	=	lGroup{g}{3}{in};
		end
	end

	return
