% S_paraOpen ver 0.1
%% parallel ������ ���ؼ�, ���� parallel pool handle�� Ȯ���Ѵ�.
%
% usage: B_parapOpen( fgForce, nForce )
%	fgForce: force re-open, default: false
%	nForce : explicit open # of 'nForce' core
%
% first created by tigoum 2016/01/18
% last  updated by tigoum 2016/04/10

function [ POOL ] = S_paraOpen(fgForce, nForce)
% �̹� �ռ��� pool �� ���� �ִٸ�, ���� �ڵ��� Ȯ���ϴ� ��� ����
%	-> �ɼǿ� ����, �ڵ��� �����ϰ� ���� �� ���� ����
%	-> fgForce = true (default is false)

	if nargin < 1,	[fgForce, nForce]	=	deal(false, 0);	end
	if nargin < 2,	nForce				=	0;	end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	% �̹� �ռ��� pool �� ���� �ִٸ�, ���� �ڵ��� Ȯ��
	if ~fgForce & ~isempty(gcp('nocreate'))		% �̹� �ڵ��� ���� ����
		POOL			=	gcp;
%		NUMWORKERS		=	POOL.NumWorkers;
		return

	elseif ~isempty(gcp('nocreate'))			% �̹� ���� �ڵ��� ���� ��
		delete(gcp('nocreate'));
	end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	%% if fgForce == true | isempty(gcp('nocreate'))
	tic;

%	chmod 600 ~/.smpd							% must be set for correctly work
%	NUMWORKERS			=	20;					%'Modified' property now TRUE
%	NUMWORKERS			=	feature('numcores');
	[status, result]	=	system('nproc');	% return to available # core
	nCore				=	[ str2num(result), nForce ];	% �䱸 �ھ� �� ���
	NUMWORKERS			=	min( nCore( nCore > 0 ) );		% 1�̻� & �ּҰ�
	%% local �ӽ� ��������, ���Ŀ����� ���� ���� �ھ� ����

%	matlabpool open 4;							% lagacy ���
%	POOL				=	parpool('local');	% �ӽ��� ���� core�� ����Ʈ ����
	%----------
%	http://vtchl.illinois.edu/node/537
	myCluster			=	parcluster('local');	% �ű� profile �ۼ�
	myCluster.NumWorkers=	NUMWORKERS;				%'Modified' property now TRUE
	saveProfile(myCluster);							% 'local' profile now updated
	POOL				=	parpool('local', NUMWORKERS);	% �ִ� 48 core ���.
	fprintf('\nPooling : the parpool worker''s setup completed. '); toc;
%	!����: parent ���� ȣ�������� tic�� �����Ѵٴ� �����Ͽ�, toc ��� ��û��.
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	return

	%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	%20150709B. WOW ȣ��� ���ο��� �ڵ����� parpool ȣ��Ǵ� �̽�
	%����: WorkerObjWrapper()ȣ��� parpool �� open�Ǿ� ���� ������ ���ο��� �ڵ�
	%		���� ȣ���ϴ� ���� �߰ߵ�. �� ��� ������ handle(POOL)�� ���� ��
	%		����, ���� �ִ� CPU��(��: 20)�� �ƴ�, ���밡���� CPU��ŭ(��: 12)
	%		������ �Ҵ�� ���̾ �����̽��� �Բ� ���ߵ�.
	%�ع�: ������ parpool�� open �����ָ� WOW ���� ���� ����
%	TFwow				=	WorkerObjWrapper(TF);	%���� init���� pool ����!
	%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

