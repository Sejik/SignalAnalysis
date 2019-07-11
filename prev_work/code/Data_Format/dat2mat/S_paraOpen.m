% S_paraOpen ver 0.1
%% parallel 연산을 위해서, 먼저 parallel pool handle을 확보한다.
%
% usage: B_parapOpen( fgForce, nForce )
%	fgForce: force re-open, default: false
%	nForce : explicit open # of 'nForce' core
%
% first created by tigoum 2016/01/18
% last  updated by tigoum 2016/04/10

function [ POOL ] = S_paraOpen(fgForce, nForce)
% 이미 앞서서 pool 이 열려 있다면, 열린 핸들을 확보하는 방법 강구
%	-> 옵션에 따라서, 핸들을 삭제하고 새로 열 수도 있음
%	-> fgForce = true (default is false)

	if nargin < 1,	[fgForce, nForce]	=	deal(false, 0);	end
	if nargin < 2,	nForce				=	0;	end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	% 이미 앞서서 pool 이 열려 있다면, 열린 핸들을 확보
	if ~fgForce & ~isempty(gcp('nocreate'))		% 이미 핸들이 열려 있음
		POOL			=	gcp;
%		NUMWORKERS		=	POOL.NumWorkers;
		return

	elseif ~isempty(gcp('nocreate'))			% 이미 열린 핸들을 꺼야 함
		delete(gcp('nocreate'));
	end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	%% if fgForce == true | isempty(gcp('nocreate'))
	tic;

%	chmod 600 ~/.smpd							% must be set for correctly work
%	NUMWORKERS			=	20;					%'Modified' property now TRUE
%	NUMWORKERS			=	feature('numcores');
	[status, result]	=	system('nproc');	% return to available # core
	nCore				=	[ str2num(result), nForce ];	% 요구 코어 수 목록
	NUMWORKERS			=	min( nCore( nCore > 0 ) );		% 1이상 & 최소값
	%% local 머신 범위에서, 병렬연산을 위한 가용 코어 설정

%	matlabpool open 4;							% lagacy 방식
%	POOL				=	parpool('local');	% 머신의 가용 core로 디폴트 설정
	%----------
%	http://vtchl.illinois.edu/node/537
	myCluster			=	parcluster('local');	% 신규 profile 작성
	myCluster.NumWorkers=	NUMWORKERS;				%'Modified' property now TRUE
	saveProfile(myCluster);							% 'local' profile now updated
	POOL				=	parpool('local', NUMWORKERS);	% 최대 48 core 고려.
	fprintf('\nPooling : the parpool worker''s setup completed. '); toc;
%	!주의: parent 에서 호출직전에 tic를 수행한다는 가정하에, toc 출력 요청함.
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	return

	%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	%20150709B. WOW 호출시 내부에서 자동으로 parpool 호출되는 이슈
	%현상: WorkerObjWrapper()호출시 parpool 이 open되어 있지 않으면 내부에서 자동
	%		으로 호출하는 동작 발견됨. 이 경우 문제는 handle(POOL)을 얻을 수
	%		없고, 또한 최대 CPU수(예: 20)가 아닌, 가용가능한 CPU만큼(예: 12)
	%		정도가 할당될 뿐이어서 성능이슈도 함께 유발됨.
	%해법: 사전에 parpool로 open 시켜주면 WOW 내부 구동 없음
%	TFwow				=	WorkerObjWrapper(TF);	%내부 init에서 pool 생성!
	%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

