function [ BOOL ] = S_DTFwriter( hEEG, DTFS, ROITSS, SRCTSS )
	% ��Ŀ�� �̹� reader �� ���� ���ĵǾ� �����Ƿ�, ���⼭�� ��Ŀ �׷캰��
	% �з� (���� ����) �ؼ� ����ϴ� �۾� ����.
	% ��Ŀ ���� ������ �� epoch�� ��ȣ�� �����̸� ���� �ο���
	fprintf('--------------------------------------------------\n');
	fprintf('Write   : DTF to file by each epoch\n');

	% DTF�� frequency dimension�� ��ճ��� ������ ������ ��ó
	if hEEG.fgAvgDTF, DTFS	=	squeeze(mean(DTFS, 3));	end		% ���ļ� ���� X

	for ixEP		=	1:length(hEEG.eMRK);			% ep �� == ��Ŀ ��

		[DIR, OUT]	=	fileparts(hEEG.OutName);		% ������� ���� Ȯ�ο�
		% ��Ŀ���� ������ �����ؾ� �ϴ� ��쿡 ���� ��ó
		if hEEG.fgSplitEpoch & hEEG.fgReorder			% ��Ŀ�� name�� �ް�
			DIR		=	[ DIR '_' num2str(hEEG.eMRK(ixEP)) ]; % ������ ��Ŀ�߰�
		end
		if not(exist(DIR, 'dir')), mkdir(DIR); end		% ������ ���� ����

		% ������ ������ epoch ������ ����
		[DTF ROITS SRCTS]=deal(DTFS(:,:,ixEP),ROITSS(:,:,ixEP),SRCTSS(:,:,ixEP));

		% ������ ������ ������ ���� flag �� ��������, ���Ͽ� �����͸� ����
		OUT_NAME	=	fullfile(DIR, sprintf('%s_%03d', OUT, ixEP));	% ���ϸ�
		Var			=	{};
		if hEEG.fgSaveDTF, Var(end+1) = 'DTF'; end		% ���庯�� ��Ͽ� �߰�
		if hEEG.fgSaveROI, Var(end+1) = 'ROITS'; end	% ���庯�� ��Ͽ� �߰�
		if hEEG.fgSaveSRC, Var(end+1) = 'SRCTS'; end	% ���庯�� ��Ͽ� �߰�

		% ���� ��������.
		eval(['save(' OUT_NAME ',''' strjoin(Var, ''',''') ''', ''-v7.3'');']);
	end	% for ixEP

