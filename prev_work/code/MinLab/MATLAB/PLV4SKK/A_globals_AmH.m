%--------------------------------------------------------------------------------
%% < CAUTION >
%% 개요: A_globals_AmH.m 파일만으로 matlab script를 구동하기 위해서는 메인 코드가
%% 담겨 있는 폴더의 path를 미리 'matlab 설정파일에' 등록해 두어야 함.
%% 그래야, 실행 개시 시점에서 메인 코드 폴더를 탐색하여 자동으로 실행이 진행됨
%
%% 실행을 위한 요구파일: A_globals_AmH.m 및 Makefile
%
%% 등록방법:
%% 1. ~/.matlab/R2015a/matlab.settings 파일을 찾는다.
% (없을 경우, 터미널 커맨드 라인 상에서 matlab을 실행 한 뒤, exit 하면 생김)
%% 2. vim 으로 열어서 아래 라인이 존재하는 지 확인 한다.
%% 3. 12번째 라인부터(반드시 12라인부터 나오지 않을 수 있으므로 이후도 확인)
%    <key name="UserPath">
%        <string>
%            <value><![CDATA[/home/minlab/MATLAB/PLV4SKK]]></value>
%        </string>
%    </key>
%% 4. 만약 없다면, 위 라인을 추가 및 저장 한다.
%% 5. A_globals_AmH.m 파일이 있는 폴더로 돌아와서, make 를 실행한다.
%--------------------------------------------------------------------------------

function [	fullPATH, Regulation,											...
			channame, removech, dataname, trialname, subname				...
			Freqs, fName, m, ki	]	=	A_globals_AmH( )
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
fullPATH	=	'/home/minlab/SKK';
Regulation	=	'BaselineCorrection';
channame	={	'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
				'EOG',	'CP5',	'CP1',	'CP2',	'CP6',	'NULL',	'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
removech	={	'EOG',	'NULL' };	%제거할 채널
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

%Freqs		=[	4:1/2:8		];		% 세타파를 잡는다: step 0.5
%Freqs		=[	8:1/2:13		];	% 알파파를 잡는다: step 0.5
Freqs		=[	13:1/2:30		];	% 베타파를 잡는다: step 0.5
%Freqs		=[	30:1/2:50		];	% 감마파를 잡는다: step 0.5
fName		=A_get_freqname(Freqs);	% 주파수 대역의 이름을 식별
m	=	7;	ki	=	5;				% wavelet 분석을 위한 default 값

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

