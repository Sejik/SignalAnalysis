%% �� ����� grand avg �� ���� ������ ������ combination �� ��-avg ����
%% ����, �ݵ�� GrandAvg...m �� ���� �����Ͽ� grand average ����� �־�� ��

function [ ] = mLib_GrAvCombi_AmH(LoadPath, cCondiCombi,		SavePath)
% LoadPath		: �� ���� grand average .mat �� ��� folder
% cCondiCombi	: ������ ������ ����
%				ex) 'F__L' �� ���� ��ĥ ������ '_'���� ǥ��
%				ex) { 'FSH_', 'MA__' }
% SavePath		: ������ ���

clearvars -except LoadPath cCondiCombi SavePath
%clear;
%close all;

%% setting %%
%path(localpathdef);	%<UserPath>�� �ִ� localpathdef.m ����, �߰����� path�� ���
% FSHL
% If there is no node, it should work.

% ���� ���������� �䱸�� �� �����Ƿ�, param�� type�� �ǵ��ؾ� ��.
if ~iscell(cCondiCombi)
	cCondiCombi			=	{ cCondiCombi };
end

% load path �� �ִ� ��� data�� �б� ����, �켱 condition �� ���ϸ� Ȯ��
fName			=	ls([ LoadPath '/*_*.mat' ]);	% �ϳ��� ���ڿ��� �ö��
fName			=	regexprep(fName, '[ ]+', '\n');	% ����и� �׸��� ���α���
fName			=	strsplit(fName, '\n');			% ���Ϻ��� �и�
%fName			=	dir([ LoadPath '/*_*.mat' ]);	% �ϳ��� ���ڿ��� �ö��
%fName			=	struct2cell(fName);
%fName			=	fName(1, :);					% �����̸���

Total			=	tic;		%��ü ���� �ð�
% ===============================================================================
for c = 1 : length(cCondiCombi)
	sCondi		=	cCondiCombi{c};					% ��ü ���� �� ���� ����

	% scondi �� �ش��ϴ� ���ϸ�ϸ� ����
%	rCondi		=	regexprep(sCondi, '[_]', '.');	% '_' -> '.' ���� ����
	rCondi		=	regexprep(sCondi, '[_]', '[^_]');% '_' -> '[^_]'(_ �ȵ�) ����
	ix			=	regexp(fName, ['.*_' rCondi '[.]mat'], 'match'); % match ����
	ix			=	cellfun(@(x)( ~isempty(x) ), ix);	% �� ������ �������
	ix			=	find( ix );						% ������ �ִ� ���� index ��
	GetName		=	fName( ix );					% �ش� ���ϸ� Ȯ��

	if isempty(GetName)
		error('No File : exist for condition [%s] & SKIP this.\n', sCondi);
		return %continue
	end

	%% --------------------------------------------------
	fprintf('\nProcess : a data averaging for condition [%s]\n', sCondi);

AllTime			=	tic;		%���Ǻ� �ش� ��ü ���� ���� �ð�
% ===============================================================================
for f = 1 : length(GetName)
	load( GetName{f} );								% ���� �б�
	fprintf('Loading : file from %s\n', GetName{f});	% notify file name

	% ����: �о�� ������ �������� ������ ���Ե� ������.
	% ex) ERP_ESHL
	%% �׷���, sCondi ���� 'F..L' �� ���� pattern �̹Ƿ� ���������� ȣ��Ұ�!
	%% ����, whos sCondi �Ͽ� ������ Ȯ��
	eval( [ 'VAR = whos(''-regexp'', ''[A-Z]{3}_' rCondi ''');' ] ); % ��� ����
	VAR				=	struct2cell(VAR);			% ��������
	vName			=	VAR(1, :);					% ������ ����
	vSize			=	VAR(2, :);					% ũ�⸸ ����

	if size(vName) ~= 4								% ������ 4������ ���ų� ����
		error('Warning : abnormal # of variables: %s\n', strjoin(vName,', '));
	end

% ===============================================================================
for v = 1 : length(vName)
	InVar			=	vName(v);					% �Էº���
	OtVar			=	regexprep(InVar,'^([A-Z]{3})_.*',['$1_' sCondi]);%out����
	[InVar OtVar]	=	deal( char(InVar), char(OtVar) );

	nDim			=	length( size( vSize(v) ) );	% ������ ���� ����

	% ���ϵ鿡 �ִ� �� ������ �� �ջ��� ���� ������ ������ �ʱ�ȭ
	% ���������� �� ���� ������ �����ؾ� �ϹǷ�, ���� 1������ �� �߰� �ؾ� ��
	if ~exist(OtVar), eval( [ OtVar ' = zeros([ 0 size(' InVar ') ]);' ] ); end

%	eval( [ OtVar	'	=	' OtVar '+' InVar ';' ] );	% ���� ����
	eval( [ OtVar	'(end+1,:)	=	' InVar '(:);' ] );	% 1D �԰����� ����
	eval( [ 'clear ' InVar ] );						% remove conditioned var

end	% for var
	clear VAR vName vSize InVar nDim				% garbage ���� ���� ����

end % for file
	clear GetName

% ===============================================================================
	% ���� ���տ� �ش��ϴ� ��� ���ϵ��� ������ �ջ��Ͽ����Ƿ�, ���� ��� ����
%	VAR				=	whos('-regexp', '^[A-Z]{3}_[A-Z_]+$');	% ��� ����
	VAR				=	whos('-regexp', ['^[A-Z]{3}_' sCondi '$']);	% ��� ����
	if isempty(VAR)									% ���!! �ƹ��͵� ��ã��!!
	fprintf('\nWarning!: not found the Variables on workspace.\n\n');	% notify
	end
	% -----
	VAR				=	struct2cell(VAR);			% ��������
	vName			=	VAR(1, :);					% ������ ����
for v = 1 : length(vName)
	InVar			=	char(vName(v));				% �Էº���

%	eval( [ InVar	'	=	' InVar ' / length(GetName);' ] );	% ��� ���
	eval( [ InVar	'	=	squeeze(mean(' InVar ', 1));' ] );	% ��� ���
end	% for var

% ===============================================================================
	% ���� ����ҿ� ����
%	ssCondi			=	regexprep(sCondi, '[.]', '-');	% �����̸� ���� ����

	fprintf('Storing : file to %s\n', [SavePath '_' sCondi '.mat' ]);	% notify
	eval( [ 'save '	SavePath '_' sCondi '.mat'	' ' strjoin(vName,' ') ';'] );
	eval( [ 'clear VAR'							' ' strjoin(vName,' ') ';'] );
	fprintf('Complete: works of [%s] condition ', sCondi);	toc(AllTime);

end	% for condi
fprintf('\nFinished: total time is ');	toc(Total);

