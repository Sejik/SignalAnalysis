function	[ChanList, SDP, fSmpl] = load_ExpInfo_AmH(DAT_NAME)

	%% Loading Experimental Info in VHDR file	%-[
%Vhdl ������ ����	%-[
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
		%�׷��� [Common Infos]�� nCH, SpI, SDP ���� ��
		%SpI : ���ø� ����(sampling rate�� ����), �ð������� uS
		%SDP : epocking�� data��	= �ð�����/SpI(���� ��ġ ���)
		%EpTm: epocking�� �ð�����	= SDP * SpI(������ġ���)
		%Smpl: ���ø���				= 1 / SpI			%-]
	fVhdr		=	regexprep(DAT_NAME, '.[A-Za-z]*$', '.vhdr');
	eval(['Fp	=	fopen(''' fVhdr ''',''r'');']);
	lVhdr		=	textscan(Fp, '%s', 'delimiter', '');	%cell array
	%white-space�� ���ڿ��� �Ϻη� �ν��ϵ��� delimiter  ������
	fclose(Fp);
%	lVhdr		=	fgetl(Fp);
	nChan		=	strncmp(lVhdr{1},'NumberOfChannels', 16); %�˻�
	nChan		=	find(nChan == 1);						%��Ȯ�� index ����
	nChan		=	strsplit(char(lVhdr{1}(nChan)), '=');	%��ū�и�
	nChan		=	str2num(char(nChan(2)));				%�� ����

	SpI			=	strncmp(lVhdr{1},'SamplingInterval', 16); %�˻�
	SpI			=	find(SpI == 1);							%��Ȯ�� index ����
	SpI			=	strsplit(char(lVhdr{1}(SpI)), '=');		%��ū�и�
	SpI			=	str2num(char(SpI(2)));					%�� ����
	fSmpl		=	1 / ( SpI * 1e-6);

	SDP			=	strncmp(lVhdr{1},'SegmentDataPoints',17); %�˻�
	SDP			=	find(SDP == 1);							%��Ȯ�� index ����
	SDP			=	strsplit(char(lVhdr{1}(SDP)), '=');			%��ū�и�
	SDP			=	str2num(char(SDP(2)));					%�� ����

	%������ ä�� ����� �о�´�. ordering�� �߿��ϹǷ� �ݵ�� ���� ������ ��!
	ChanList	=	cell(1, nChan);
	for ch = 1 : nChan
		if ch <= 9, L = 3; else L = 4; end
		ChN		=	strncmp(lVhdr{1}, ['Ch' num2str(ch) '='], L+1);	%�˻�
		ChN		=	find(ChN == 1);							%��Ȯ�� index ����
		ChN		=	strsplit(char(lVhdr{1}(ChN(1))), '=');	%ù��°��:��ū�и�
		ChN		=	strsplit(char(ChN(2)), ',');			%ù��°��:��ū�и�
		ChN		=	char(ChN(1));							%�� ����

		ChanList{ch}	=	ChN;							%����
	end	%for

%	clear			lVhdr Fp SpI	%-]
