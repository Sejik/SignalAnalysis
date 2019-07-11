%--------------------------------------------------------------------------------
%% < CAUTION >
%% ����: A_globals_AmH.m ���ϸ����� matlab script�� �����ϱ� ���ؼ��� ���� �ڵ尡
%% ��� �ִ� ������ path�� �̸� 'matlab �������Ͽ�' ����� �ξ�� ��.
%% �׷���, ���� ���� �������� ���� �ڵ� ������ Ž���Ͽ� �ڵ����� ������ �����
%
%% ������ ���� �䱸����: A_globals_AmH.m �� Makefile
%
%% ��Ϲ��:
%% 1. ~/.matlab/R2015a/matlab.settings ������ ã�´�.
% (���� ���, �͹̳� Ŀ�ǵ� ���� �󿡼� matlab�� ���� �� ��, exit �ϸ� ����)
%% 2. vim ���� ��� �Ʒ� ������ �����ϴ� �� Ȯ�� �Ѵ�.
%% 3. 12��° ���κ���(�ݵ�� 12���κ��� ������ ���� �� �����Ƿ� ���ĵ� Ȯ��)
%    <key name="UserPath">
%        <string>
%            <value><![CDATA[/home/minlab/MATLAB/PLV4SKK]]></value>
%        </string>
%    </key>
%% 4. ���� ���ٸ�, �� ������ �߰� �� ���� �Ѵ�.
%% 5. A_globals_AmH.m ������ �ִ� ������ ���ƿͼ�, make �� �����Ѵ�.
%--------------------------------------------------------------------------------

function [	fullPATH, Regulation,											...
			channame, removech, dataname, trialname, subname				...
			Freqs, fName, m, ki	]	=	A_globals_AmH( )
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
fullPATH	=	'/home/minlab/SKK';
Regulation	=	'BaselineCorrection';
channame	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
removech	={	'EOG',	'NULL' };	%������ ä��
%selchan		={};				%channame - removech
%
dataname	={	'Fav_USA', 'Neutral_Mexico', 'Unfav_Paki'};
trialname	={	'dislike', 'like'};
subname		={	'su02',		'su04',		'su06',		'su07',					...
				'su08',		'su09',		'su10',		'su11',					...
				'su12',		'su13',		'su14',		'su15',					...
				'su16',		'su17',		'su18',		'su19',					...
				'su20',		'su21',		'su22',		'su24',					...
				'su25',		'su26',		'su27',		'su28',		'su29'		};

%Freqs		=[	4:1/2:8		];		% ��Ÿ�ĸ� ��´�: step 0.5
%Freqs		=[	8:1/2:13		];	% �����ĸ� ��´�: step 0.5
Freqs		=[	13:1/2:30		];	% ��Ÿ�ĸ� ��´�: step 0.5
%Freqs		=[	30:1/2:50		];	% �����ĸ� ��´�: step 0.5
fName		=A_get_freqname(Freqs);	% ���ļ� �뿪�� �̸��� �ĺ�
m	=	7;	ki	=	5;				% wavelet �м��� ���� default ��

%%===============================================================================
function [ FreqName ] = A_get_freqname(f)
% detect band of array f, and return band name
	if		0< f(1) && f(end)<= 4,	FreqName	=	'delta';
	elseif	4<=f(1) && f(end)<= 8,	FreqName	=	'theta';
	elseif	8<=f(1) && f(end)<=13,	FreqName	=	'alpha';
	elseif 13<=f(1) && f(end)<=30,	FreqName	=	'beta';
	elseif 30<=f(1) && f(end)<=50,	FreqName	=	'gamma';
	else,							FreqName	=	'unknonw';
	end

