%% ������ condition ���� �� ��캰 �����Ǵ� �����͸� ������ �ڵ� grand avg ����

% �ڵ� �����ϱ� �� �޸𸮸� ���� ��Ʈ���� �����ִ� �˾�â���� �ݴ� ����
clear;
close all;

%% setting %%
path(localpathdef);	%<UserPath>�� �ִ� localpathdef.m ����, �߰����� path�� ���
% FSHL
% If there is no node, it should work.

%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki	]	=	A_globals_AmH();
	Freqs					={	1:1/2:50	};		% �� �뿪�� ��´�: step 0.5
	%Freqs, fName�� cell array �� ���: float vector�� ���� �ʿ�
	if iscell(Freqs)
		Freqs				=	Freqs{1};					% 1st �����͸� ����
		fName				=	fName{1};
	end
	if ~isfloat(Freqs)
		error('"Freqs" is not float data or vector\n');
	end

MinEpoch					=	20;					% ó������ �ּ� epoch ���Ѽ�

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%%�ݵ�� �м��� ������ ����� ��. (��: ���ļ� : ���Ĵ뿪 ��)
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

Total				=	tic;		%��ü ���� �ð�
for datanumb	=1:length(dataname)
for trialnumb	=1:length(trialname)
	sCondi			=	[ dataname{datanumb} trialname{trialnumb} ];

	eval( [ 'ERP_' sCondi '	=	[;; ];' ] );
	eval( [ 'EVK_' sCondi '	=	[;;;];' ] );
	eval( [ 'TOT_' sCondi '	=	[;;;];' ] );
	eval( [ 'TOA_' sCondi '	=	[;;;];' ] );
for subnumb		=1:length(subname)
	BOOL			=	true;									% default return

	lSubj			=	subname{subnumb};	% �迭 or ���ڿ�

	FileInfo.Src	=	'/TF/Results_';
	FileInfo.Dest	=	'/GRD/Grand_';

	lSRCNAME		=	{};	% must be init!:�ƴϸ� �Ʒ� skip�� �ٸ����� ȥ�տ���!
	if iscell(lSubj) && length(lSubj)>=3
		% ���� ���ϵ��� ���ս��Ѿ� �Ѵ�. ���� �̸��� ó���� ��
		% �̶� ��Ұ����� �ּ� 3�� -> sub1(����), sub1_1(src), sub1_2(src)
		for s		=	2 : length(lSubj)				% 1:���� �̸�, 2:cut ����
			WORKNAME=[	char(lSubj{s}) Regulation sCondi	];
			lSRCNAME{s-1}=[	fullPATH FileInfo.Src	WORKNAME '.mat'	]; %�迭
		end
		% �������� file���� ������
		WORKNAME	=[	char(lSubj{1}) Regulation sCondi	];

	elseif iscell(lSubj) && length(lSubj)<=2
		% ��� ������ 2����, ����=�ҽ� �̹Ƿ�, �׳� ���� ����ó�� ó�� ����
		WORKNAME	=[	char(lSubj{2}) Regulation sCondi	];
		lSRCNAME{1}	=[	fullPATH FileInfo.Src	WORKNAME '.mat'	];%only 1

		% �������� file���� ������
		WORKNAME	=[	char(lSubj{1}) Regulation sCondi	];

	else	%���� ���ϸ��� ���
		WORKNAME	=[	char(lSubj) Regulation sCondi	];
		lSRCNAME{1}	=[	fullPATH FileInfo.Src	WORKNAME '.mat'	];%only 1
	end

%		hEEG.FileInfo.WORK	=	WORKNAME;		% �����̸� �� ����

	% ���� ��� ���ϸ� ����
%		OUT_NAME	=[	fullPATH	FileInfo.Dest	WORKNAME	'.mat' ];
		OUT_NAME	=[	fullPATH	FileInfo.Dest	sCondi	'.mat' ];
%		hEEG.FileInfo.OutFile	=	OUT_NAME;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	AllTime			=	tic;		%������ preparing �ð��� �����Ѵ�.

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
	%'\n'���ϴ� ������ �Ʒ��� toc ����� ���� �پ���� �Ϸ���.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% merging ���: ���� SubjInfo.Inlier �� �� cell�� �ټ� ���� subj 
%	�̸��� ��� �ִٸ�, �̵��� ������� �о, �ϳ��� �����ͷ� ��ħ
%	time �������� concatenate �ؾ� ��.
	ERP				=	[;];	% tp * ch
	EVK				=	[;;];	% fq * tp * ch
	TOT				=	[;;];	% fq * tp * ch
	TOA				=	[;;];	% fq * tp * ch

	for s			= 1 : length(lSRCNAME)				% �ݵ�� cell array ��!
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

		% �о�� �� �������� �ռ� ���� ��(���� ���� �ִٸ�)�� �����Ѵ�.
		% ��, concatenation�� �ϴ°� �ƴ϶�, ���ϰ� ������ ���ȭ ��Ŵ.
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
	if isempty(ERP), continue; end						% data ������ ���� subj��
	%% ----------

	% subject �� ���տ� ���� ����� �� �� ��� -> 2���� �����̸� 2�� ����
	%% �̶�, ������ ũ�Ⱑ �ٸ� ����? (��: freq=0.5:1/2:70 vs 0.25:1/4:70)
	% 1. ���ļ� ����: ��� ���̰� ����, �� ����ȭ�� ������ ���� �ٿ� ���ø�
	% 2. �ð� ����: ���������� ��� ������ ���� ó����. ������� �ƴϸ� ����
	% 3. ä�� ����: ��� ���� �� ���ɼ� ���� -> ���� ���
	% -> �� ��, grand ũ�⺸�� indi�� �� ū ��쿡�� ����
	% -> �ݴ��� ��� ��� ���� -> ���� ���
	if ~isempty( eval([ 'ERP_' sCondi ]) )				% grand�� data���� ����-[
		eval( [ '[S F T C] = size(EVK_' sCondi ');' ] );
		[f t c]		=	size(EVK);
		[Mf, Mt, Mc]=	deal( f/F, t/T, c/C );			% ��� ����
		if mod(f,F)~=0 || mod(t,T)~=0 || mod(c,C)~=0	% �ݵ��: Grd < Indi
			fprintf(['Error   : mismatch dimenstions b/w Grand(%s) & '		...
	'Indivisual(%s)\n'], sprintf('%d,%d,%d',F,T,C), sprintf('%d,%d,%d',f,t,c));
		end
		% freq �� ����, ������ ũ���̸� down sampling
		if 1<Mf && mod(f,F)==0,
%			ERP		=	ERP(Mf:Mf:end, :, :);			% ERP�� ���ļ� ���� ����
			EVK		=	EVK(Mf:Mf:end, :, :);			% �������� �߿�:
			TOT		=	TOT(Mf:Mf:end, :, :);			% -> 1 �ƴ� ����� ����
			TOA		=	TOA(Mf:Mf:end, :, :);			% -> ����� ��Ī��
			fprintf('Regulate: Freq. dimension size for %d -> %d\n', f, F);
		elseif Mf<1, fprintf('Error   : a Indi size too small then Grand\n');
		end		% Mf �� 1 �̸��̸�, indi ���� grand �� �� ū �����.
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

	% ���� �� subject �� �����͸� ��ü array�� ��������.
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

	% ������ Ư�� ���ǿ� ���� ��ü subject �� grand average �� ����.
	% ���ǿ� ����, � subject�� �����Ͱ� ��� loading �� �迭 ���� ��,
	%	skip �Ǵ� ��찡 �ִµ�, �̷� ��쿡�� ����� �迭�� ũ�⸦ ��������
	%	����� ���� ��������.

	% skip �Ǵ� ��츦 ������ averaging ������ log �� ���
	if isempty(eval([ 'ERP_' sCondi ])), continue; end		% data ������ ����

	fprintf('\nAverage : all finded subjects(%d) for Condition(%s)\n',		...
			eval( [ 'size(ERP_' sCondi ',1)' ]), sCondi);
	% ----------
	eval( [ 'ERP_' sCondi '	=	squeeze(mean(ERP_' sCondi ', 1));' ] );
	eval( [ 'EVK_' sCondi '	=	squeeze(mean(EVK_' sCondi ', 1));' ] );
	eval( [ 'TOT_' sCondi '	=	squeeze(mean(TOT_' sCondi ', 1));' ] );
	eval( [ 'TOA_' sCondi '	=	squeeze(mean(TOA_' sCondi ', 1));' ] );

	% ��հ��� ��� �� ���Ͽ� ����
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

