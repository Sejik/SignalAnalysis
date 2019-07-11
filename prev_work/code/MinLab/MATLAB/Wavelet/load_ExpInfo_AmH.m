function	[ChanList, SDP, fSmpl] = load_ExpInfo_AmH(DAT_NAME)

	%% Loading Experimental Info in VHDR file	%-[
%Vhdl 데이터 구조	%-[
%  1:Brain Vision Data Exchange Header File Version 2.0
%  2:; Data created from history path: EXP_NEW_su0036/Raw Data/Filters/Formula Evaluator/OcularCorrection/Edit Markers 2/Segmentation 1/ExpectedTarget/BaselineCorrection/Artifact Rejection_Min/BaselineCorrection_GConv_ExpectedTarget
%  3:[Common Infos]
%  4:Codepage=UTF-8
%  5:DataFile=EXP_NEW_su0036_BaselineCorrection_GConv_ExpectedTarget.eeg
%  6:MarkerFile=EXP_NEW_su0036_BaselineCorrection_GConv_ExpectedTarget.vmrk
%  7:DataFormat=ASCII
%  8:; Data orientation: VECTORIZED=ch1,pt1, ch1,pt2..., MULTIPLEXED=ch1,pt1,ch2,pt1 ...
%  9:DataOrientation=MULTIPLEXED
% 10:DataType=TIMEDOMAIN
% 11:NumberOfChannels=32			-> nCH
% 12:DataPoints=217350
% 13:; Sampling interval in microseconds if time domain (convert to Hertz:
% 14:; 1000000 / SamplingInterval) or in Hertz if frequency domain:
% 15:SamplingInterval=2000			-> SpI
% 16:SegmentationType=MARKERBASED
% 17:SegmentDataPoints=1050			-> SDP
% 18:[User Infos]
		%그래서 [Common Infos]의 nCH, SpI, SDP 읽을 것
		%SpI : 샘플링 간격(sampling rate의 역수), 시간단위는 uS
		%SDP : epocking된 data수	= 시간범위/SpI(단위 일치 요망)
		%EpTm: epocking된 시간범위	= SDP * SpI(단위일치요망)
		%Smpl: 샘플링율				= 1 / SpI			%-]
	fVhdr		=	regexprep(DAT_NAME, '.[A-Za-z]*$', '.vhdr');
	eval(['Fp	=	fopen(''' fVhdr ''',''r'');']);
	lVhdr		=	textscan(Fp, '%s', 'delimiter', '');	%cell array
	%white-space를 문자열의 일부로 인식하도록 delimiter  설정함
	fclose(Fp);
%	lVhdr		=	fgetl(Fp);
	nChan		=	strncmp(lVhdr{1},'NumberOfChannels', 16); %검색
	nChan		=	find(nChan == 1);						%정확한 index 산출
	nChan		=	strsplit(char(lVhdr{1}(nChan)), '=');	%토큰분리
	nChan		=	str2num(char(nChan(2)));				%값 추출

	SpI			=	strncmp(lVhdr{1},'SamplingInterval', 16); %검색
	SpI			=	find(SpI == 1);							%정확한 index 산출
	SpI			=	strsplit(char(lVhdr{1}(SpI)), '=');		%토큰분리
	SpI			=	str2num(char(SpI(2)));					%값 추출
	fSmpl		=	1 / ( SpI * 1e-6);

	SDP			=	strncmp(lVhdr{1},'SegmentDataPoints',17); %검색
	SDP			=	find(SDP == 1);							%정확한 index 산출
	SDP			=	strsplit(char(lVhdr{1}(SDP)), '=');			%토큰분리
	SDP			=	str2num(char(SDP(2)));					%값 추출

	%다음은 채널 목록을 읽어온다. ordering이 중요하므로 반드시 순서 보존할 것!
	ChanList	=	cell(1, nChan);
	for ch = 1 : nChan
		if ch <= 9, L = 3; else L = 4; end
		ChN		=	strncmp(lVhdr{1}, ['Ch' num2str(ch) '='], L+1);	%검색
		ChN		=	find(ChN == 1);							%정확한 index 산출
		ChN		=	strsplit(char(lVhdr{1}(ChN(1))), '=');	%첫번째것:토큰분리
		ChN		=	strsplit(char(ChN(2)), ',');			%첫번째것:토큰분리
		ChN		=	char(ChN(1));							%값 추출

		ChanList{ch}	=	ChN;							%저장
	end	%for

%	clear			lVhdr Fp SpI	%-]

