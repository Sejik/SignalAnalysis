%% 복잡한 condition 조합 및 경우별 생략되는 데이터를 감안한 자동 grand avg 수행

% 코드 시작하기 전 메모리를 비우고 매트랩에 켜져있는 팝업창들을 닫는 과정
clear;
close all;

%% setting %%
path(localpathdef);	%<UserPath>에 있는 localpathdef.m 실행, 추가적인 path를 등록
% FSHL
% If there is no node, it should work.

%%주요 전역변수를 WorkSpace에 구성한다.@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki	]	=	A_globals_AmH();
	Freqs					={	1:1/2:50	};		% 전 대역을 잡는다: step 0.5
	%Freqs, fName이 cell array 일 경우: float vector로 변경 필요
	if iscell(Freqs)
		Freqs				=	Freqs{1};					% 1st 데이터만 취함
		fName				=	fName{1};
	end
	if ~isfloat(Freqs)
		error('"Freqs" is not float data or vector\n');
	end

MinEpoch					=	20;					% 처리가능 최소 epoch 하한선

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%%반드시 분석의 범위를 명시할 것. (예: 주파수 : 알파대역 등)
fprintf(['@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n'															...
'The processing parameters has:\n'											...
'\tFrequency: %4.2f ~ %4.2f ; step(%4.2f)\n'								...
'\tChannel  : total n(%d) ; REAL n(%d)\n'									...
'\tSubject  : n(%d)\n'														...
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n']																	...
,	Freqs(1), Freqs(end), (Freqs(end)-Freqs(1))/(length(Freqs)-1),			...
	length(channame), length(channame)-length(removech),					...
	length(subname)	);
%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

Total				=	tic;		%전체 연산 시간
for datanumb	=1:length(dataname)
for trialnumb	=1:length(trialname)
	sCondi			=	[ dataname{datanumb} trialname{trialnumb} ];

	eval( [ 'ERP_' sCondi '	=	[;; ];' ] );
	eval( [ 'EVK_' sCondi '	=	[;;;];' ] );
	eval( [ 'TOT_' sCondi '	=	[;;;];' ] );
	eval( [ 'TOA_' sCondi '	=	[;;;];' ] );
for subnumb		=1:length(subname)
	BOOL			=	true;									% default return

	lSubj			=	subname{subnumb};	% 배열 or 문자열

	FileInfo.Src	=	'/TF/Results_';
	FileInfo.Dest	=	'/GRD/Grand_';

	lSRCNAME		=	{};	% must be init!:아니면 아래 skip시 다른파일 혼합오류!
	if iscell(lSubj) && length(lSubj)>=3
		% 여러 파일들을 결합시켜야 한다. 최종 이름은 처음에 둠
		% 이때 요소갯수는 최소 3개 -> sub1(목적), sub1_1(src), sub1_2(src)
		for s		=	2 : length(lSubj)				% 1:최종 이름, 2:cut 기준
			WORKNAME=[	char(lSubj{s}) Regulation sCondi	];
			lSRCNAME{s-1}=[	fullPATH FileInfo.Src	WORKNAME '.mat'	]; %배열
		end
		% 최종적인 file명을 구성함
		WORKNAME	=[	char(lSubj{1}) Regulation sCondi	];

	elseif iscell(lSubj) && length(lSubj)<=2
		% 요소 갯수가 2개면, 최종=소스 이므로, 그냥 단일 파일처럼 처리 가능
		WORKNAME	=[	char(lSubj{2}) Regulation sCondi	];
		lSRCNAME{1}	=[	fullPATH FileInfo.Src	WORKNAME '.mat'	];%only 1

		% 최종적인 file명을 구성함
		WORKNAME	=[	char(lSubj{1}) Regulation sCondi	];

	else	%단일 파일명인 경우
		WORKNAME	=[	char(lSubj) Regulation sCondi	];
		lSRCNAME{1}	=[	fullPATH FileInfo.Src	WORKNAME '.mat'	];%only 1
	end

%		hEEG.FileInfo.WORK	=	WORKNAME;		% 파일이름 중 공통

	% 최종 출력 파일명 구성
%		OUT_NAME	=[	fullPATH	FileInfo.Dest	WORKNAME	'.mat' ];
		OUT_NAME	=[	fullPATH	FileInfo.Dest	sCondi	'.mat' ];
%		hEEG.FileInfo.OutFile	=	OUT_NAME;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	AllTime			=	tic;		%데이터 preparing 시간을 계측한다.

	%check result file & skip analysis if aleady exists.
%	fprintf('\nChecking: Analyzed result file: ''%s''...',[OUT_IMAG '.jpg']);
	fprintf('\nChecking: Analyzed result file: ''%s''...', OUT_NAME);
%	if exist([OUT_IMAG '.jpg'], 'file') > 0					%exist !!
	if exist(OUT_NAME, 'file') > 0					%exist !!
		fprintf('exist! & SKIP analyzing this\n');
		continue;									%skip
	else
		fprintf('NOT & Continue the Analyzing\n');
	end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	fprintf('--------------------------------------------------\n');
	fprintf('Loading : %s''s MAT to Array on WORKSPACE.\n', WORKNAME);
	%'\n'안하는 이유는 아래의 toc 결과가 끝에 붙어나오게 하려고.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% merging 기능: 만약 SubjInfo.Inlier 의 한 cell에 다수 개의 subj 
%	이름이 담겨 있다면, 이들을 순서대로 읽어서, 하나의 데이터로 합침
%	time 기준으로 concatenate 해야 함.
	ERP				=	[;];	% tp * ch
	EVK				=	[;;];	% fq * tp * ch
	TOT				=	[;;];	% fq * tp * ch
	TOA				=	[;;];	% fq * tp * ch

	for s			= 1 : length(lSRCNAME)				% 반드시 cell array 임!
		SRC_NAME	=	lSRCNAME{s};
%		hEEG.FileInfo.InFile	=	SRC_NAME;

		%check & auto skip if not exist a 'dat file.
		fprintf('Checking: Source file: ''%s''... ', SRC_NAME);
		if exist(SRC_NAME, 'file') <= 0					%skip
			fprintf('not! & SKIP converting this\n\n');
			continue;									%exist !!
		else
			fprintf('EXIST & Continue the converting\n\n');
		end

%%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% Convert: MAT -> Array
% -------------------------------------------------------------------------------
		load( SRC_NAME );

		% 읽어온 각 변수별로 앞서 읽은 것(읽은 것이 있다면)과 통합한다.
		% 단, concatenation을 하는게 아니라, 더하고 나눠서 평균화 시킴.
		if isempty(ERP),	ERP	=	ERP_filt_bl;
		else,				ERP	=	ERP + ERP_filt_bl;	end
		if isempty(EVK),	EVK	=	TFe_bl;
		else,				EVK	=	EVK + TFe_bl;		end
		if isempty(TOT),	TOT	=	TFi_bl;
		else,				TOT	=	TOT + TFi_bl;		end
		if isempty(TOA),	TOA	=	TFi;
		else,				TOA	=	TOA + TFi;			end

		clear ERP_filt_bl TFe_bl TFi_bl TFi;
	end;
	%% ----------
	if isempty(ERP), continue; end						% data 없으면 다음 subj로
	%% ----------

	% subject 의 집합에 대한 평균을 낸 후 기록 -> 2개의 묶음이면 2로 나눔
	%% 이때, 차원의 크기가 다른 경우는? (예: freq=0.5:1/2:70 vs 0.25:1/4:70)
	% 1. 주파수 차원: 배수 차이가 나면, 더 세분화된 것으로 보고 다운 샘플링
	% 2. 시간 차원: 마찬가지로 배수 차이일 때는 처리함. 배수차이 아니면 에러
	% 3. 채널 차원: 배수 차이 날 가능성 없음 -> 에러 출력
	% -> 이 때, grand 크기보다 indi가 더 큰 경우에만 적용
	% -> 반대의 경우 방법 없음 -> 에러 출력
	if ~isempty( eval([ 'ERP_' sCondi ]) )				% grand에 data있을 때만-[
		eval( [ '[S F T C] = size(EVK_' sCondi ');' ] );
		[f t c]		=	size(EVK);
		[Mf, Mt, Mc]=	deal( f/F, t/T, c/C );			% 배수 관계
		if mod(f,F)~=0 || mod(t,T)~=0 || mod(c,C)~=0	% 반드시: Grd < Indi
			fprintf(['Error   : mismatch dimenstions b/w Grand(%s) & '		...
	'Indivisual(%s)\n'], sprintf('%d,%d,%d',F,T,C), sprintf('%d,%d,%d',f,t,c));
		end
		% freq 에 대해, 정수배 크기이면 down sampling
		if 1<Mf && mod(f,F)==0,
%			ERP		=	ERP(Mf:Mf:end, :, :);			% ERP는 주파수 차원 없음
			EVK		=	EVK(Mf:Mf:end, :, :);			% 시작지점 중요:
			TOT		=	TOT(Mf:Mf:end, :, :);			% -> 1 아닌 배수값 부터
			TOA		=	TOA(Mf:Mf:end, :, :);			% -> 맞춰야 매칭됨
			fprintf('Regulate: Freq. dimension size for %d -> %d\n', f, F);
		elseif Mf<1, fprintf('Error   : a Indi size too small then Grand\n');
		end		% Mf 가 1 미만이면, indi 보다 grand 가 더 큰 경우임.
		if 1<Mt && mod(t,T)==0,
			ERP		=	ERP(Mt:Mt:end, :);
			EVK		=	EVK(:, Mt:Mt:end, :);
			TOT		=	TOT(:, Mt:Mt:end, :);
			TOA		=	TOA(:, Mt:Mt:end, :);
			fprintf('Regulate: Time. dimension size for %d -> %d\n', t, T);
		elseif Mt<1, fprintf('Error   : a Indi size too small then Grand\n');
		end
		if 1<Mc && mod(c,C)==0,
			ERP		=	ERP(:, Mc:Mc:end);
			EVK		=	EVK(:, :, Mc:Mc:end);
			TOT		=	TOT(:, :, Mc:Mc:end);
			TOA		=	TOA(:, :, Mc:Mc:end);
			fprintf('Regulate: Chan. dimension size for %d -> %d\n', c, C);
		elseif Mc<1, fprintf('Error   : a Indi size too small then Grand\n');
		end
	end	%-]

	% 이제 각 subject 의 데이터를 전체 array에 저장하자.
	eval( [ 'ERP_' sCondi '(end+1, :, :)	=	ERP / length(lSRCNAME);' ] );
	fprintf('Inject  : a Indivisual(ERP:%s) to Grand(ERP_%s:%s)\n',			...
	strjoin(arrayfun(@(x)({num2str(x)}), size(ERP)), ','),	sCondi,			...
	strjoin(arrayfun(@(x)({num2str(x)}), eval(['size(ERP_' sCondi ')'])), ','));

	eval( [ 'EVK_' sCondi '(end+1, :, :, :)	=	EVK / length(lSRCNAME);' ] );
	fprintf('Inject  : a Indivisual(EVK:%s) to Grand(EVK_%s:%s)\n',			...
	strjoin(arrayfun(@(x)({num2str(x)}), size(EVK)), ','),	sCondi,			...
	strjoin(arrayfun(@(x)({num2str(x)}), eval(['size(EVK_' sCondi ')'])), ','));

	eval( [ 'TOT_' sCondi '(end+1, :, :, :)	=	TOT / length(lSRCNAME);' ] );
	fprintf('Inject  : a Indivisual(TOT:%s) to Grand(TOT_%s:%s)\n',			...
	strjoin(arrayfun(@(x)({num2str(x)}), size(TOT)), ','),	sCondi,			...
	strjoin(arrayfun(@(x)({num2str(x)}), eval(['size(TOT_' sCondi ')'])), ','));

	eval( [ 'TOA_' sCondi '(end+1, :, :, :)	=	TOA / length(lSRCNAME);' ] );
	fprintf('Inject  : a Indivisual(TOA:%s) to Grand(TOA_%s:%s)\n',			...
	strjoin(arrayfun(@(x)({num2str(x)}), size(TOA)), ','),	sCondi,			...
	strjoin(arrayfun(@(x)({num2str(x)}), eval(['size(TOA_' sCondi ')'])), ','));

end	%for subj

%% ------------------------------------------------------------------------------

	% 다음은 특정 조건에 대한 전체 subject 의 grand average 를 구함.
	% 조건에 따라, 어떤 subject는 데이터가 없어서 loading 및 배열 저장 시,
	%	skip 되는 경우가 있는데, 이럴 경우에는 저장된 배열의 크기를 기준으로
	%	평균을 내면 문제없음.

	% skip 되는 경우를 감안한 averaging 정보를 log 에 출력
	if isempty(eval([ 'ERP_' sCondi ])), continue; end		% data 없으면 다음

	fprintf('\nAverage : all finded subjects(%d) for Condition(%s)\n',		...
			eval( [ 'size(ERP_' sCondi ',1)' ]), sCondi);
	% ----------
	eval( [ 'ERP_' sCondi '	=	squeeze(mean(ERP_' sCondi ', 1));' ] );
	eval( [ 'EVK_' sCondi '	=	squeeze(mean(EVK_' sCondi ', 1));' ] );
	eval( [ 'TOT_' sCondi '	=	squeeze(mean(TOT_' sCondi ', 1));' ] );
	eval( [ 'TOA_' sCondi '	=	squeeze(mean(TOA_' sCondi ', 1));' ] );

	% 평균값은 모두 한 파일에 저장
	fprintf('Storing : Grand average data to %s\n', OUT_NAME);
	eval( [ 'save '	OUT_NAME		' '										...
					'ERP_' sCondi	' '										...
					'EVK_' sCondi	' '										...
					'TOT_' sCondi	' '										...
					'TOA_' sCondi	' '										...
			';'] );

	eval( [ 'clear '				' '										...
					'ERP_' sCondi	' '										...
					'EVK_' sCondi	' '										...
					'TOT_' sCondi	' '										...
					'TOA_' sCondi	' '										...
			';'] );

%%-------------------------------------------------------------------------------
	fprintf('\nComplete: %s''s processing :: ',WORKNAME);	toc(AllTime);
	fprintf('\n');

end	%for trial
end	%for data

fprintf('\nFinished: total time is ');	toc(Total);

