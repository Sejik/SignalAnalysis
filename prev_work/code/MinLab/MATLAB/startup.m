%% setting %% -> ���� ȣȯ��(���� matlab ����)���� strsplit, strjoin ��� ����
%pathdefs	=	strsplit(path, ':');			% ���� path�� ���
pathdefs	=	textscan(path, '%s', 'delimiter', ':');	% str -> cell
pathdefs	=	pathdefs{1}(:)';				% strsplit �� ����

%-------------------------------------------------------------------------------
% following setup is designed for HERMES
addpath('/usr/local/HERMES/');					% HERMES path : eeglab �浹���ɼ�

%-------------------------------------------------------------------------------
% following setup is designed for BrainNet Viewer
addpath('/usr/local/BrainNet/');				% BrainNet Viewer path ���

%-------------------------------------------------------------------------------
% following setup is designed for FieldTrip
%%addpath('/usr/local/fieldtrip/fieldtrip/');		% fieldtrip path ���
%%ft_defaults;									% fieldtrip �ʱ�ȭ

%path_ft		=	strsplit(path, ':');			% ���� path�� ���
path_ft		=	textscan(path, '%s', 'delimiter', ':');	% str -> cell
path_ft		=	path_ft{1}(:)';					% strsplit �� ����
[~, loc_ft]	=	ismember(path_ft, pathdefs);	% ���� �Ͱ� ����� �� �߸�
path_ft([ find(loc_ft) ])	=	[];				% remove identical path parts
% now, path_ft have only fieldtrip path parts.
%path_ft		=	strjoin(path_ft, ':');			% join to path string
path_ft		=	char(concatdata(cellfun(@(x)({[x ':']}), path_ft'))); % ==strjoin
path_ft		=	path_ft(1:end-1);				% ���� ':' ����

%-------------------------------------------------------------------------------
path(pathdef);			%% �ٽ� �ʱ�ȭ, CAUTION for order! <- matlab �⺻�� ����

%-------------------------------------------------------------------------------
% following setup is designed for bbci
curr_dir = pwd;

global BBCI;
cd ('/usr/local/bbci_public')
startup_bbci_toolbox(	'DataDir','/home/minlab/Projects/BMiN/Ref.BBCI/',		...
						'TmpDir','/tmp/')

cd (curr_dir)

%-------------------------------------------------------------------------------
path(localpathdef, path_ft);	%<UserPath>/localpathdef.m ����, �߰� path ���
% �ݵ�� �� �������� �����ؾ߸�, ����� �� path ������ ������

clear pathdefs path_ft loc_ft;					% remove unnecessity