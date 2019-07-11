%% setting %% -> 하위 호환성(예전 matlab 버전)위해 strsplit, strjoin 사용 중지
%pathdefs	=	strsplit(path, ':');			% 현재 path를 기억
pathdefs	=	textscan(path, '%s', 'delimiter', ':');	% str -> cell
pathdefs	=	pathdefs{1}(:)';				% strsplit 과 동일

%-------------------------------------------------------------------------------
% following setup is designed for HERMES
addpath('/usr/local/HERMES/');					% HERMES path : eeglab 충돌가능성

%-------------------------------------------------------------------------------
% following setup is designed for BrainNet Viewer
addpath('/usr/local/BrainNet/');				% BrainNet Viewer path 등록

%-------------------------------------------------------------------------------
% following setup is designed for FieldTrip
%%addpath('/usr/local/fieldtrip/fieldtrip/');		% fieldtrip path 등록
%%ft_defaults;									% fieldtrip 초기화

%path_ft		=	strsplit(path, ':');			% 변경 path를 기억
path_ft		=	textscan(path, '%s', 'delimiter', ':');	% str -> cell
path_ft		=	path_ft{1}(:)';					% strsplit 과 동일
[~, loc_ft]	=	ismember(path_ft, pathdefs);	% 기존 것과 공통된 것 추림
path_ft([ find(loc_ft) ])	=	[];				% remove identical path parts
% now, path_ft have only fieldtrip path parts.
%path_ft		=	strjoin(path_ft, ':');			% join to path string
path_ft		=	char(concatdata(cellfun(@(x)({[x ':']}), path_ft'))); % ==strjoin
path_ft		=	path_ft(1:end-1);				% 끝의 ':' 제거

%-------------------------------------------------------------------------------
path(pathdef);			%% 다시 초기화, CAUTION for order! <- matlab 기본만 잡힙

%-------------------------------------------------------------------------------
% following setup is designed for bbci
curr_dir = pwd;

global BBCI;
cd ('/usr/local/bbci_public')
startup_bbci_toolbox(	'DataDir','/home/minlab/Projects/BMiN/Ref.BBCI/',		...
						'TmpDir','/tmp/')

cd (curr_dir)

%-------------------------------------------------------------------------------
path(localpathdef, path_ft);	%<UserPath>/localpathdef.m 실행, 추가 path 등록
% 반드시 맨 마지막에 구동해야만, 제대로 된 path 순서가 맞춰짐

clear pathdefs path_ft loc_ft;					% remove unnecessity
