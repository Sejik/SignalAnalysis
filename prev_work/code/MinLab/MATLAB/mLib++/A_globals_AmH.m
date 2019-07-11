function [	fullPATH, Regulation,											...
			channame, removech, dataname, trialname, subname				...
			Freqs, fName, m, ki, cedPATH	]	=	A_globals_AmH( )
%--------------------------------------------------------------------------------
%% �� m ���ϵ��� ����ϴ� ���������� �����ϵ��� �����Ѵ�.
%--------------------------------------------------------------------------------

global	NUMWORKERS;			%define global var for parallel tool box!!

% ���� �ϳ��� ���̴� ��� �ڵ忡 �����ϰ� ����/���̱� �س��� ���� ���մϴ�.
%
% channame: 1�� ���� 32�� ���� ���� ��ȣ�� �°� ä���̸� ����. �м��� ���������� �ʿ������� ������ ����ϴ� �����Ͱ�
% ��� ä�ο��� �Դ��� Ȯ���ϰų� ���÷����� �� ���� �˴ϴ�.
%
% dataname, trialname: ���� �з����ӿ� ���� �˸°� ���������� �ٲ��ָ� �˴ϴ�.
%
% subname: ������ ����Ʈ. Outlier�� ���� ��� �� ����Ʈ������ ���ָ� �˴ϴ�.

NUMWORKERS	=	20;
%fullPATH	=	'/home/minlab/PLV_theta';
%fullPATH	=	'/home2/minlab/PFC_64';
fullPATH	=	'/home2/minlab/TIN';
Regulation	=	'';	%'Condi'; %'BaselineCorrection_Imagery';
%{
channame	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5', };
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
%}
channame	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'FCz',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',  'PO10',...
				'AF7',	'AF3',	'AF4',	'AF8',	'F5',	'F1',	'F2',	'F6', ...
				'FT9',	'FT7',	'FC3',	'FC4',	'FT8',	'FT10',	'C5',	'C1', ...
				'C2',	'C6',	'TP7',	'CP3',	'CPz',	'CP4',	'TP8',	'P5', ...
				'P1',	'P2',	'P6',	'PO7',	'PO3',	'POz',	'PO4',	'PO8', };
%removech	={	'EOG'	};			%������ ä�� : Orignal Order spliter�� ����
removech	={	''	};				%������ ä�� : Orignal Order spliter�� ����
%selchan		={};				%channame - removech
%
subname		={																...
				{ 'su0001',		'su0001', },	...
				{ 'su0002',		'su0002', },	...
			};
%subname		={	{ 'su0004', 'su0004', },	};
%dataname	=[	11:16 21:26 31:36	];				% trial �׷���: �� 6 * 3 ��
dataname	={	''	};				% original ���� ����
trialname	=[	12 1	];			% stim ��ȣ, correct resp ��ȣ

Freqs		=[	500	];						% �� �뿪�� ��´�: step 0.5
fName		=AmHlib_get_freqname(Freqs);	% ���ļ� �뿪�� �̸��� �ĺ�
%m	=	7;	ki	=	5;						% wavelet �м��� ���� default ��
m	=	-1000;	ki	=	3500;				% �ٸ��뵵: epoch�� start, fin idx

%cedPATH		=	[ fullPATH '/../MATLAB/Standard-10-10-Cap32.ced' ];
cedPATH		=	[ fullPATH '/../MATLAB/EEG_32chan.ced' ];
