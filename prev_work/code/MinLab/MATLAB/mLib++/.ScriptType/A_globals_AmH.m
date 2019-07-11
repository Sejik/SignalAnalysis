function [	fullPATH, Regulation,											...
			channame, removech, dataname, trialname, subname				...
			Freqs, fName, m, ki, cedPATH	]	=	A_globals_AmH( )
%--------------------------------------------------------------------------------
%% 각 m 파일들이 사용하는 전역변수를 공유하도록 구성한다.
%--------------------------------------------------------------------------------

global	NUMWORKERS;			%define global var for parallel tool box!!

% 실험 하나에 쓰이는 모든 코드에 동일하게 복사/붙이기 해놓는 것이 편합니다.
%
% channame: 1번 부터 32번 까지 각각 번호에 맞게 채널이름 지정. 분석에 직접적으로 필요하지는 않지만 사용하는 데이터가
% 어느 채널에서 왔는지 확인하거나 디스플레이할 때 쓰면 됩니다.
%
% dataname, trialname: 실험 패러다임에 따라 알맞게 유동적으로 바꿔주면 됩니다.
%
% subname: 피험자 리스트. Outlier가 생길 경우 이 리스트에서도 빼주면 됩니다.

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
%removech	={	'EOG'	};			%제거할 채널 : Orignal Order spliter는 무시
removech	={	''	};				%제거할 채널 : Orignal Order spliter는 무시
%selchan		={};				%channame - removech
%
subname		={																...
				{ 'su0001',		'su0001', },	...
				{ 'su0002',		'su0002', },	...
			};
%subname		={	{ 'su0004', 'su0004', },	};
%dataname	=[	11:16 21:26 31:36	];				% trial 그룹핑: 총 6 * 3 개
dataname	={	''	};				% original 측정 순서
trialname	=[	12 1	];			% stim 번호, correct resp 번호

Freqs		=[	500	];						% 전 대역을 잡는다: step 0.5
fName		=AmHlib_get_freqname(Freqs);	% 주파수 대역의 이름을 식별
%m	=	7;	ki	=	5;						% wavelet 분석을 위한 default 값
m	=	-1000;	ki	=	3500;				% 다른용도: epoch의 start, fin idx

%cedPATH		=	[ fullPATH '/../MATLAB/Standard-10-10-Cap32.ced' ];
cedPATH		=	[ fullPATH '/../MATLAB/EEG_32chan.ced' ];
