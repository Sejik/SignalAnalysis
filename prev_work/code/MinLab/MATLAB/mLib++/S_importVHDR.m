% S_importDat ver 0.2
% - BVA(BrainVisionAnalyzer)���� export �� *.dat�� �������� �� *.vhdr �� ����
%
% Usage: [ChanList, SDP, fSmpl, Orient] = S_importVHDR(fullPATH)
%	-> param is must be hEEG style struct
%
% first created by tigoum 2016/01/01
% last  updated by tigoum 2016/01/10

function	[ChanList, SDP, fSmpl, Orient] = S_importVHDR(fullPATH)	%-[

	%%20151117A. �̽� �ذ��� ���� return�� �߰� Orient = 'MULTIPLEXED'

	%% Loading Experimental Info in VHDR file
%{
	Vhdl ������ ����	%-[
 1:Brain Vision Data Exchange Header File Version 2.0
 2:; Data created from history path: EXP_NEW_su0036/Raw Data/Filters/Formula Evaluator/OcularCorrection/Edit Markers 2/Segmentation 1/ExpectedTarget/BaselineCorrection/Artifact Rejection_Min/BaselineCorrection_GConv_ExpectedTarget
 3:[Common Infos]
 4:Codepage=UTF-8
 5:DataFile=EXP_NEW_su0036_BaselineCorrection_GConv_ExpectedTarget.eeg
 6:MarkerFile=EXP_NEW_su0036_BaselineCorrection_GConv_ExpectedTarget.vmrk
 7:DataFormat=ASCII
 8:; Data orientation: VECTORIZED=ch1,pt1, ch1,pt2..., MULTIPLEXED=ch1,pt1,ch2,pt1 ...
 9:DataOrientation=MULTIPLEXED
10:DataType=TIMEDOMAIN
11:NumberOfChannels=32			-> nCH
12:DataPoints=217350
13:; Sampling interval in microseconds if time domain (convert to Hertz:
14:; 1000000 / SamplingInterval) or in Hertz if frequency domain:
15:SamplingInterval=2000			-> SpI
16:SegmentationType=MARKERBASED
17:SegmentDataPoints=1050			-> SDP
18:
19:[User Infos]
20:; Each entry: Prop<Number>=<Type>,<Name>,<Value>,<Value2>,...,<ValueN>
21:; Property number must be unique. Types can be int, single, string, bool, byte, double, uint
22:; or arrays of those, indicated int-array etc
23:; Array types have more than one value, number of values determines size of array.
24:; Fields are delimited by commas, commas in strings are written \1
25:
26:[ASCII Infos]
27:; Decimal symbol for floating point numbers: the header file always uses a dot (.),
28:; however the data file might use a different one
29:DecimalSymbol=.
30:; SkipLines, SkipColumns: leading lines and columns with additional information.
31:SkipLines=1
32:SkipColumns=0
33:
34:[Channel Infos]
35:; Each entry: Ch<Channel number>=<Name>,<Reference channel name>,
36:; <Resolution in "Unit">,<Unit>, Future extensions...
37:; Fields are delimited by commas, some fields might be omitted (empty).
38:; Commas in channel names are coded as "\1".
39:Ch1=Fp1,,,µV
40:Ch2=Fp2,,,µV
41:Ch3=F7,,,µV
42:Ch4=F3,,,µV
43:Ch5=Fz,,,µV
44:Ch6=F4,,,µV
45:Ch7=F8,,,µV
46:Ch8=FC5,,,µV
47:Ch9=FC1,,,µV
48:Ch10=FC2,,,µV
49:Ch11=FC6,,,µV
50:Ch12=T7,,,µV
51:Ch13=C3,,,µV
52:Ch14=Cz,,,µV
53:Ch15=C4,,,µV
54:Ch16=T8,,,µV
55:Ch17=EOG,,,µV
56:Ch18=CP5,,,µV
57:Ch19=CP1,,,µV
58:Ch20=CP2,,,µV
59:Ch21=CP6,,,µV
60:Ch22=NULL,,,µV
61:Ch23=P7,,,µV
62:Ch24=P3,,,µV
63:Ch25=Pz,,,µV
64:Ch26=P4,,,µV
65:Ch27=P8,,,µV
66:Ch28=PO9,,,µV
67:Ch29=O1,,,µV
68:Ch30=Oz,,,µV
69:Ch31=O2,,,µV
70:Ch32=PO10,,,µV
71:
72:[Channel User Infos]
73:; Each entry: Prop<Number>=Ch<ChannelNumber>,<Type>,<Name>,<Value>,<Value2>,...,<ValueN>
74:; Property number must be unique. Types can be int, single, string, bool, byte, double, uint
75:; or arrays of those, indicated int-array etc
76:; Array types have more than one value, number of values determines size of array.
77:; Fields are delimited by commas, commas in strings are written \1
78:; Properties are assigned to channels using their channel number.
79:
80:[Coordinates]
81:; Each entry: Ch<Channel number>=<Radius>,<Theta>,<Phi>
82:Ch1=1,-90,-72
83:Ch2=1,90,72
84:Ch3=1,-90,-36
85:Ch4=1,-60,-51
86:Ch5=1,45,90
87:Ch6=1,60,51
88:Ch7=1,90,36
89:Ch8=1,-69,-21
90:Ch9=1,-31,-46
91:Ch10=1,31,46
92:Ch11=1,69,21
93:Ch12=1,-90,0
94:Ch13=1,-45,0
95:Ch14=1,0,0
96:Ch15=1,45,0
97:Ch16=1,90,0
98:Ch17=0,0,0
99:Ch18=1,-69,21
100:Ch19=1,-31,46
101:Ch20=1,31,-46
102:Ch21=1,69,-21
103:Ch22=0,0,0
104:Ch23=1,-90,36
105:Ch24=1,-60,51
106:Ch25=1,45,-90
107:Ch26=1,60,-51
108:Ch27=1,90,-36
109:Ch28=1,-113,54
110:Ch29=1,-90,72
111:Ch30=1,90,-90
112:Ch31=1,90,-72
113:Ch32=1,113,-54	%-]
%}
		%�׷��� [Common Infos]�� nCH, SpI, SDP ���� ��
		%SpI : ���ø� ����(sampling rate�� ����), �ð������� uS
		%SDP : epocking�� data��	= �ð�����/SpI(���� ��ġ ���)
		%EpTm: epocking�� �ð�����	= SDP * SpI(������ġ���)
		%Smpl: ���ø���				= 1 / SpI
	fVhdr		=	[ regexprep(fullPATH, '[.][A-Za-z]*$', '') '.vhdr' ];
	eval(['Fp	=	fopen(''' fVhdr ''',''r'');']);
	if Fp < 0, ChanList = []; SDP = 0; fSmpl = 0; Orient = ''; return; end
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
	SDP			=	strsplit(char(lVhdr{1}(SDP)), '=');		%��ū�и�
	SDP			=	str2num(char(SDP(2)));					%�� ����

	Orient		=	strncmp(lVhdr{1},'DataOrientation',15); %�˻�
	Orient		=	find(Orient == 1);						%��Ȯ�� index ����
	Orient		=	strsplit(char(lVhdr{1}(Orient)), '=');	%��ū�и�
	Orient		=	char(Orient(2));						%�� ����

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

