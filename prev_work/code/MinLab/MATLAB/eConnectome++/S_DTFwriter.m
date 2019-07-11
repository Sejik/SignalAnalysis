function [ BOOL ] = S_DTFwriter( hEEG, DTFS, ROITSS, SRCTSS )
	% 마커는 이미 reader 에 의해 정렬되어 있으므로, 여기서는 마커 그룹별로
	% 분류 (폴더 생성) 해서 출력하는 작업 시행.
	% 마커 폴더 내에서 각 epoch의 번호는 파일이름 끝에 부여됨
	fprintf('--------------------------------------------------\n');
	fprintf('Write   : DTF to file by each epoch\n');

	% DTF의 frequency dimension을 평균내서 제거할 것인지 조처
	if hEEG.fgAvgDTF, DTFS	=	squeeze(mean(DTFS, 3));	end		% 주파수 차원 X

	for ixEP		=	1:length(hEEG.eMRK);			% ep 수 == 마커 수

		[DIR, OUT]	=	fileparts(hEEG.OutName);		% 출력파일 존재 확인용
		% 마커별로 폴더를 생성해야 하는 경우에 대한 조처
		if hEEG.fgSplitEpoch & hEEG.fgReorder			% 마커를 name에 달것
			DIR		=	[ DIR '_' num2str(hEEG.eMRK(ixEP)) ]; % 폴더명에 마커추가
		end
		if not(exist(DIR, 'dir')), mkdir(DIR); end		% 없으면 폴더 생성

		% 저장한 변수를 epoch 단위로 추출
		[DTF ROITS SRCTS]=deal(DTFS(:,:,ixEP),ROITSS(:,:,ixEP),SRCTSS(:,:,ixEP));

		% 저장할 데이터 종류에 대한 flag 를 기준으로, 파일에 데이터를 저장
		OUT_NAME	=	fullfile(DIR, sprintf('%s_%03d', OUT, ixEP));	% 파일명
		Var			=	{};
		if hEEG.fgSaveDTF, Var(end+1) = 'DTF'; end		% 저장변수 목록에 추가
		if hEEG.fgSaveROI, Var(end+1) = 'ROITS'; end	% 저장변수 목록에 추가
		if hEEG.fgSaveSRC, Var(end+1) = 'SRCTS'; end	% 저장변수 목록에 추가

		% 이제 저장하자.
		eval(['save(' OUT_NAME ',''' strjoin(Var, ''',''') ''', ''-v7.3'');']);
	end	% for ixEP

