%% wavelet_EXP.m %%
% Wavelet �ڵ�. ���迡 ���� Header�κ��� �޶����Ƿ�, wavelet �ڵ带 �� ���躰�� �ϳ��� ����� �νô� ��
% �����ϴ�.
% �� �ڵ带 �����Ű�� ���ؼ� �Ʒ��� �ٸ� m�ڵ� ���� �ݵ�� ���� ������ �־�� �մϴ�.
%
% epoch2erp_min.m, epoch2tf_min.m, tf2tfi_min.m, tfmorlet_min.m,
% wmorlet_min.m, readKRISSMEG_sev.m, spss_min.m
%
% Wavelet�� ������ �����ʹ� Average �����Ͱ� �ƴ� ��ü epoch�� �ִ� �������̹Ƿ� �� �ڵ忡���� ��ü epoch
% �����͸��� �ٷ�ϴ�.

%% �ڵ� �����ϱ� �� �޸𸮸� ���� ��Ʈ���� �����ִ� �˾�â���� �ݴ� ����
clear;
close all;

%% setting %%
path(localpathdef);	%<UserPath>�� �ִ� localpathdef.m ����, �߰����� path�� ���

%% Header %%
global	DAT_NAME;
global	NUMWORKERS;
global	WORKNAME;
% ���� �ϳ��� ���̴� ��� �ڵ忡 �����ϰ� ����/���̱� �س��� ���� ���մϴ�.
%
% channame: 1�� ���� 32�� ���� ���� ��ȣ�� �°� ä���̸� ����. �м��� ���������� �ʿ������� ������ ����ϴ� �����Ͱ�
% ��� ä�ο��� �Դ��� Ȯ���ϰų� ���÷����� �� ���� �˴ϴ�.
%
% dataname, trialname: ���� �з����ӿ� ���� �˸°� ���������� �ٲ��ָ� �˴ϴ�.
%
% subname: ������ ����Ʈ. Outlier�� ���� ��� �� ����Ʈ������ ���ָ� �˴ϴ�.

%A_globals_AmH();%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@@
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

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% local �ӽ� ��������, ���Ŀ����� ���� ���� �ھ� ����
tic; delete(gcp('nocreate'));

%matlabpool open 4;							% lagacy ���
%POOL		=	parpool('local');			% ���� �ӽ��� ���� core�� ����Ʈ ����
%----------
%http://vtchl.illinois.edu/node/537
myCluster				=	parcluster('local');	% �ű� profile �ۼ�
myCluster.NumWorkers	=	NUMWORKERS;				%'Modified' property now TRUE
saveProfile(myCluster);								% 'local' profile now updated
POOL					=	parpool('local', NUMWORKERS);	% �ִ� 48 core ���.

	%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	%20150709B. WOW ȣ��� ���ο��� �ڵ����� parpool ȣ��Ǵ� �̽�
	%����: WorkerObjWrapper()ȣ��� parpool �� open�Ǿ� ���� ������ ���ο��� �ڵ�
	%		���� ȣ���ϴ� ���� �߰ߵ�. �� ��� ������ handle(POOL)�� ���� ��
	%		����, ���� �ִ� CPU��(��: 20)�� �ƴ�, ���밡���� CPU��ŭ(��: 12)
	%		������ �Ҵ�� ���̾ �����̽��� �Բ� ���ߵ�.
	%�ع�: ������ parpool�� open �����ָ� WOW ���� ���� ����
%	TFwow				=	WorkerObjWrapper(TF);	%���� init���� pool ����!
	%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	fprintf('\nPooling : the parpool worker''s setup completed. '); toc;
	%!����: parent ���� ȣ�������� tic�� �����Ѵٴ� �����Ͽ�, toc ��� ��û��.
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

Total		=	tic;		%��ü ���� �ð�
for datanumb=1:length(dataname)
	for trialnumb=1:length(trialname)
		for subnumb=1:length(subname)

% Wavelet�� Header�� �߰��� �κ�����, �޸� ������ 16ä�ξ� ���� �����ͷ�
%	wavelet�� ������ ������ �߰��� �κ��Դϴ�.
%	���� �߶��� �������� ä�� ���� �ٲپ��ٸ� �� �κ��� �ٲپ� �ָ� �˴ϴ�.
			%���Ǹ� ���� ���ϸ��� ������ ��
			WORKNAME	=[	char(subname{subnumb})		'_'					...
							Regulation					'_'					...
							char(dataname{datanumb})	''					...
							char(trialname{trialnumb})	];
			WORKDEST	=[	char(subname{subnumb})		'_'					...
							char(dataname{datanumb})	''					...
							char(trialname{trialnumb})	];
			DAT_NAME	=[	fullPATH '_dat/' 'skk_' WORKNAME '.dat'	];
			OUT_NAME	=[	fullPATH '_tf/' 'ERP_Evk_Tot_' WORKDEST '.mat' ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			%check result file & skip analysis if aleady exists.
			fprintf('\nChecking: Analyzed result file: ''%s''... ', OUT_NAME);
			if exist(OUT_NAME, 'file') > 0					%exist !!
				fprintf('exist! & SKIP analyzing this\n');
				continue;									%skip
			else
				fprintf('NOT & Continue the Analyzing\n');
			end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			AllTime		=	tic;		%������ preparing �ð��� �����Ѵ�.
			fprintf('--------------------------------------------------\n');
			fprintf('Convert : %s''s DAT to TF data on WORKSPACE.\n', WORKNAME);
			%'\n'���ϴ� ������ �Ʒ��� toc ����� ���� �پ���� �Ϸ���.

%%-------------------------------------------------------------------------------
% Convert: DAT -> eEEG...mat
% -------------------------------------------------------------------------------
			%check & auto skip if not exist a 'dat file.
			%20151030A. ����� �������� ������ ����, �����Ͱ� �߻� �Ұ� ����
			%����: ���� ���ǿ� ���� Ʈ���Ű� ���� ���,
			%	Ư�� segment �� �߻����� ���� �� �ִ�.
			%	��: Unfav_like ���� �������� ���� ������ ��ǰ�� ������ ����
			%		������, �������� ���� �� �־ Ʈ���Ű� �߻����� �ʰ� ��.
			%ó��: ����, DAT�� ���� ��쿡 ��� �ϰ�, �̿� �����ϴ� ��ġ�ʿ�
			%	-> ��ü sub ���� n ���� �ϳ� �پ��� ���� ������ ó�� �ʿ�
			fprintf('Checking: Source DAT file: ''%s''... ', DAT_NAME);
			if exist(DAT_NAME, 'file') <= 0					%skip
				fprintf('not! & SKIP converting this\n');
				fprintf(['WANRNING: %s is not found. It maybe be correct..\n' ...
				'\tBut recommanded to double checking. please.\n'], DAT_NAME);
				continue;									%exist !!
			else
				fprintf('EXIST & Continue the converting\n');
			end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			%% 20151120A. ��� ������ src file üũ �� �д� ���� ����!!
			[lChan,SDP,fSmpl]	=	load_ExpInfo_AmH(DAT_NAME);
			MxChn		=	length(lChan);			% MxChn : ä�� ����
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			%% Subjects_All Epochs_bl
%			cd skk_dat;
%			eval(['BAdat = importdata(''' fullPATH '/skk_dat/skk_' char(subname{subnumb}) '_BaselineCorrection_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '.dat'');']);
%			eval(['BAdat	=	importdata(''' fullPATH		...
%									'/skk_dat/skk_' DAT_NAME '.dat'');']);
			eval(['BAdat	=	importdata(''' DAT_NAME ''');']);
%			cd ..;
			if isstruct(BAdat)							%dat���� ù��:ch����
%				B		=	BAdat.data;
%				B		=	shiftdim(B, 1);
%				eEEGa	=	reshape(B, 1000, [], 32);
%				eEEGa	=	reshape(BAdat.data, 1000, [], 32);
				fprintf('Detected: [struct] type for .DAT\n');
				BAdat	=	BAdat.data;
			elseif isnumeric(BAdat)						%ù�ٿ� ch ���� X
				fprintf('Detected: [numeric] type for .DAT\n');
				BAdat	=	BAdat;
			else
				fprintf('Warning : unkown the .DAT type\n');
				BAdat	=	double(BAdat);
			end

%			eEEGa		=	reshape(BAdat, SDP, [], MxChn); % t * ep * ch
			if		size(BAdat,2) == MxChn
				fprintf('Detected: MULTIPLEXED orientation for .DAT\n');
				eEEGa	=	reshape(BAdat, SDP, [], MxChn);	%% time * ep * ch

			elseif	size(BAdat,1) == MxChn
				fprintf('Detected: VECTORIZED orientation for .DAT\n');
				eEEGa	=	reshape(BAdat, MxChn, SDP, []);	%% ch * time * ep
				eEEGa	=	shiftdim(eEEGa, 1);				% tm x ep x ch
			end
			% eEEGa(timepoint * epochs * ch)
%			clear B BAdat
			clear BAdat

%%-------------------------------------------------------------------------------
			if size(eEEGa,2) < MinEpoch,	continue;	end	 % trial �� �����ϸ�
%			eEEGa(:,:,17)=	NaN;	% EOG
%			eEEGa(:,:,22)=	NaN;	% NULL
%%			eEEGa(:,:,[17 22])	=	0;	% EOG, NULL

%			liveChIdx	=	find( ~ismember(channame, removech) );	% live��
			liveChIdx	=	find( ismember(lChan, channame) );	% live��
			if MxChn > length(liveChIdx)					% ä�� �� �� ����
%				channame=	channame( [ liveChIdx ] );		% ����ִ� ä�θ�
				lChan	=	channame;						% ����ִ� ä�θ�
				eEEGa	=	eEEGa(:,:, [ liveChIdx ]);		% live ä�θ� ����
				MxChn	=	size(eEEGa,3);					% ä�μ��� ����
			end
%%-------------------------------------------------------------------------------

%			eval(['load eEEG_' char(trialname{trialnumb}) '_'			...
%				char(dataname{datanumb}) '_' char(subname{subnumb}) '.mat']);
%			eEEGa= eEEG1;
%			clear eEEG1;

			% Butterworth Filtering �κ�. �Ϲ������� �����Ͻ� �κ��� ������
			% fSmpl�� Sampling Rate�̹Ƿ� �츮 ���� ������ �����Ͱ� �ƴ� MEG ������ ���� ���
			% Sampling Rate�� �޶����Ƿ� ��������� �մϴ�.
			% SKK ���� ������ sampling rate : 500Khz
%			fSmpl		=	500;
			[bbb, aaa]	=	butter(1, [0.5 30]/(fSmpl/2),'bandpass');

%%%�Ʒ� �κ��� ���� comment ó�� �Ǿ� �ִ� �κ�.. �׳� ����ġ�ŵ� �� �� �մϴ�%%%
			% baseline correction
			% for x=1:40,
			% channame(1,x)=cellstr(EEG.chanlocs(1,x).labels);
			% end;
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

			% 1~50Hz �� ������ 0.5Hz ������ �м��� ���̹Ƿ� �̸� ������ �ݴϴ�.
%			Freqs		=	[1:1/2:50];

			% ������ �κо���.
%			m			=	7;	ki	=	5;

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
			CPB			=	1;	%ch per blk(parallel size)
								%��üä���� ����ó�� ũ��:�⺻ 1�� ��(all ó��)
			lERP		=	cell(1, CPB);	%ERP_filt_bl
			lTFe		=	cell(1, CPB);	%TFe_bl ; �ڱ��� , _bl(Baseline corr)
			lTFi		=	cell(1, CPB);	%TFi	; �ڱ���
			lTFib		=	cell(1, CPB);	%TFi_bl	; �ڱ���

while true
%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%			lChns		={	[1:16], [17:32]	};	%ä�� ����
			lChns		=	cell(1, CPB);		%�ѹ��� ������ ä�� list ����
			for CH = 1 : CPB,	lChns{CH}=[MxChn/CPB*(CH-1)+1:MxChn/CPB*CH]; end
%--------------------------------------------------------------------------------
			for CH = 1 : CPB %mem����(64G�ε� ���ڶ�)���� ä�� ����
fprintf('\nParts   : (%d/%d) of eEEG data Let''s GO!\n', CH, CPB);

			chs			=	cell2mat( lChns(CH) );

			% 1~16�� ä�� �����ʹ� eEEG1����, 17~32�� ä�� �����ʹ� eEEG2�� ����.
%			eEEG1		=	eEEG(:,:,1:16);
%			eEEG2		=	eEEG(:,:,17:32);
%			eEEG		=	eEEGa(:,:,chs);
			eEEG		=	eEEGa(:,:, MxChn/CPB*(CH-1)+1:MxChn/CPB*CH);
%			eEEG		=	eEEGa(:,:, 1:MxChn/CPB);	%blk ó�� ��
%			eEEGa		=	eEEGa(:,:, MxChn/CPB+1:end);%�������� shift
			%�޸� �Ҹ� �ּ�ȭ �ϱ� ����, eEEGa �����͸� copy ��� move ��Ŵ

			%%% header
			% Baseline Correction �� Timewindow�� �����ϴ� �κ�.
			% �� �κ��� Ȯ���ϼž� �˴ϴ�.
			% ERP�� �ַ� -500 ~ -100ms,
			% Frequency�м��� �ַ� -400 ~ -100ms �� �����մϴ�.
%			ERP_blTimWin=[1:200];	% -500 ~ -100ms, (fSmpl==500, thus 2ms ����)
			ERP_blTimWin=[1:250];	% -500 ~ 0ms, (20151102A. ������ ����)
			TF_blTimWin	=[51:200];  % -400 ~ -100ms

			% ���� ������ �� ���� �����Ͻ� �κ� �����ϴ�.
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ERP analysis
tic;	fprintf('Engagement: ERP Analysis');
%{
			% bl=zeros(size(id'));bl=single(bl);	%-[
			blEEG		=	eEEG;
			ERP			=	zeros(size(eEEG,1), size(chs,2));
			ERP_filt	=	ERP;
			ERP_filt_bl	=	ERP;

%			for ii		=	1:length(chs)
			for ch		=	1:length(chs)	%chs()�� ä�ι�ȣ, eEEG�� 1���� ����
%				ch		=	chs(ii);		%����, chs(1)==17==eEEG(1)

%				bl(1,:)	=	squeeze(mean(eEEG([ERP_blTimWin],:,ch),1));
%???????????????????????????????????????????????????????????????????????????????
%				for yy	=	1:size(bl),
%20150806A. yy==1 �� loop �� ���� ���� Ž��!!!
%����: �� �ڵ带 ����:
%		size(bl) == [1 epoch] �̹Ƿ�
%		������ �ڵ�: for yy = 1:1, �� �����ϰ� ��!!
%����: ���� loop���� ERP ��꿡 ������ �ݿ���.
%		���� �ܰ迡�� evoked, total power�� ��꿡 ERP �������� �ݿ���.
%		�ᱹ ��ü wavelet �м� ����� ����ȭ!!
%�ع�: size(bl,2)�� ����ϸ� ��.
%???????????????????????????????????????????????????????????????????????????????
%				for yy	=	1:size(bl,2),	%epoch iter ���ؼ� ��Ȯ ũ�� ����!
%					blEEG(:,yy,ch)	=	squeeze(eEEG(:,yy,ch)) - bl(1,yy);
%				end;
				bl=repmat(mean(eEEG([ERP_blTimWin],:,ch),1),[size(eEEG,1),1,1]);
				blEEG(:,:,ch)	=	eEEG(:,:,ch) - bl(:,:,1);	%matrix�� ����ȭ

				ERP(:,ch)		= squeeze(mean(blEEG(:,:,ch),2)); %t*ep -> t * ch
				ERP_filt(:,ch)	=	filtfilt(bbb,aaa,ERP(:,ch));
				ERP_filt_bl(:,ch)=	ERP_filt(:,ch)						...
										-mean(ERP_filt([ERP_blTimWin],ch));
			end;	toc;	%-]
%}
%			bl	=	repmat(mean(eEEG([ERP_blTimWin],:,:)), [size(eEEG,1),1,1]);
%			blEEG		=	eEEG - bl;						%matrix�� ����ȭ
			blEEG=eEEG-repmat(mean(eEEG([ERP_blTimWin],:,:)),[size(eEEG,1),1,1]);

			ERP			=	squeeze(mean(blEEG(:,:,:), 2));	%t*ep -> t * ch
%[bbb, aaa]	=	butter(1, [0.5 30]/(fSmpl/2),'bandpass');
			ERP_filt	=	filtfilt(bbb, aaa, ERP);
			ERP_filt_bl	=	ERP_filt										...
				- repmat(mean(ERP_filt([ERP_blTimWin],:)),[size(ERP_filt,1),1]);
			toc;

			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Time-Frequency Analysis
tic;	fprintf('Engagement: Time-Frequency Analysis');
			% evoked tf (without baseline_correction)
			TFe			=	zeros([length(Freqs) size(ERP)]);	%f x t x ch
			for ch		=	1:size(ERP,2),						%loop the all-ch
%				[tf1,tfa1,tfc1]		=	tfmorlet_min(ERP(:,ch),fSmpl,Freqs,m,ki);
				tf1			=	tfmorlet_min_AmH(ERP(:,ch),fSmpl,Freqs,m,ki);
				TFe(:,:,ch)	=	tf1;							%power�� ����
%				fnout=['su' num2str2(su) '_cond' num2str(cond) '_trg' num2str(n) '_' channame{1,ch} '.mat'];
%				save(fnout,'TFe');
			end;	toc;

			%%%%%%%%
			%%%%%%%%
tic;	fprintf('Engagement: Evoked TF with Baseline correction');
			% evoked tf (with baseline_correction)
%			TFes_bl		=	squeeze(mean(TFe(:,TF_blTimWin,:),2));	% -> f * ch
%			TFe_bl		=	TFe;								% f * t * ep
%			for ii		=	1:size(TFe,3),						% all ch
%				for f	=	1:length(Freqs),
%					TFe_bl(f,:,ii)	=	TFe(f,:,ii)-TFes_bl(f,ii);	%shift
%				end;
%			end;	toc;
%tic;	fprintf('Comparison: Evoked TF with Baseline correction');
			%% �׽�Ʈ ���, �� for / for ����� 10.3608�� �ɸ���,
			%% �Ʒ� matrix ������ 0.08723�� �ɸ�: 118�� ����
			TFes_bl = repmat(mean(TFe(:,TF_blTimWin,:),2), [1,size(TFe,2),1]);
			% mean()���� f x 1 x ch -> t �� n�� Ȯ�� : f x t x ch (���� % ũ��ȭ)
			TFe_bl		=	TFe - TFes_bl; toc;	% 100��+ ����	% signal shift

tic; fprintf('Engagement: Total TF with BaselineCorrection,except alpha band\n');
			% total tf (with baseline_correction: except alpha band)
%			[TF, TF_power]=epoch2tf_min(eEEG,Freqs,fSmpl,m,ki);
%			TF=single(TF);									%complex�� ���
%			TF			=	single( epoch2tf_min_AmH(eEEG,Freqs,fSmpl,m,ki) );
			TF			=	epoch2tf_min_AmH(eEEG,Freqs,fSmpl,m,ki);
			TF			=	single(TF);		%TF�� singleȭ ó���� �� �ӵ� ����
%			[TFi,TFP,TFA]=	tf2tfi_min(TF);
			TFi			=	tf2tfi_min(TF);

%			TFis_bl		=	squeeze(mean(TFi(:,TF_blTimWin,:),2));
%			TFi_bl		=	TFi;
%			for ii		=	1:size(TFi,3),
%				for f	=	1:length(Freqs),
%					TFi_bl(f,:,ii)	=	TFi(f,:,ii)-TFis_bl(f,ii);
%				end;
%			end;	toc;
			TFis_bl = repmat(mean(TFi(:,TF_blTimWin,:),2), [1,size(TFe,2),1]);
			TFi_bl		=	TFi - TFis_bl; toc;					%signal shift
			%%%%%%%%
			%%%%%%%%

			%----------
			%ä�κи��� �����͸� ���� ���� -> ���� ������� �ϳ��� ���� �� ����
			lERP{CH}	=	ERP_filt_bl;
			lTFe{CH}	=	TFe_bl;
			lTFi{CH}	=	TFi;
			lTFib{CH}	=	TFi_bl;
			end				%for CH = 1 :
			%----------
			break;							%ó������ ��������. while() Ż��!

try		%�޸� ���� �� �ڿ� �Ѱ�� ó�� �Ұ� ���� �߻� ��, ���� ����
%--------------------------------------------------------------------------------
%catch	exception
%	if strcmp(exception.identifier,		...
%		'MATLAB:catenate:dimentionMismatch'),	???;	end
catch	exception	%���� ���� ������ ���̹Ƿ� (���� ����msg �м��� �õ��� ��)
					%���� ä�� ���� �� ����ȭ �ؼ� �����ϵ��� ����
			if CPB < MxChn					%CPB�� �ִ�� ���� ���� ���
%				fprintf('\nFailure!  : %s\n', exception.message);
				disp(exception.message);
				fprintf('\n\nRegulating: CH-partition %d->%d\n', CPB, CPB*2);
				CPB		=	CPB * 2;		%2��� �� �� ����
%				continue;					%���� ����(CPB)�� �ٽ� ����
			else							%ä��1�� ����(��ǻ� ����) ����
				fprintf('\nAbort     : the Analysis by resource lack.(PAUSE)\n');
				toc(AllTime);	quit;
			end
end			% try - catch
end			% while
%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%--------------------------------------------------------------------------------
			%���� ����
			ERP_filt_bl	=	[ lERP{:} ];			%���� �Ϸ�
			TFe_bl		=	lTFe{1};				%1st �迭 ���� �� like strcat
			TFi			=	lTFi{1};
			TFi_bl		=	lTFib{1};

			ChNext		=	length(lChns{1})+1;		%���� �۾��� ä�� index
			for CH		=	2 : CPB
			for k		=	1 : length(lChns{CH})	%���� ������ ���� ���� ����
			TFe_bl	(:,:,ChNext)	=	lTFe{CH}	(:,:,k);
			TFi		(:,:,ChNext)	=	lTFi{CH}	(:,:,k);
			TFi_bl	(:,:,ChNext)	=	lTFib{CH}	(:,:,k);
			ChNext		=	ChNext + 1;				%�۾��� ��ŭ ä�μ� ����
			end
			end				%for integrated loop

%--------------------------------------------------------------------------------
			% 1~32�� ä�� wavelet ���� �����͸� ����
			% �����ʹ� 4 ������, ERP_filt_bl, TFi, TFe_bl, TFi_bl �Դϴ�.
			% �� �� ���� wavelet�� ����� ���ļ� �����ʹ� TFi, TFe_bl, TFi_bl �̰�
			% ERP_filt_bl �� ERP ������ �Դϴ�.
			% ���� ���� ������ ������ȴ� �Ͱ� ����, ���⼭�� ERP_filt_bl �����ʹ� ���͸��� �ѹ� �� ��
			% �������̹Ƿ� �м����� ���� �ʰ�, analyzer���� export�� Average �����ͷ� �м��Ͻø� �˴ϴ�.

			% 'Result_' �� �����ϴ� mat���Ϸ� ����
%			cd result;
%			eval(['FILENAME=''Result_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) ''';']);
%			save(FILENAME, 'ERP_filt_bl', 'TFi', 'TFe_bl', 'TFi_bl');
%			save([fullPATH '/skk_tf/' 'ERP_Evk_Tot_' WORKDEST '.mat'],		...
%							'ERP_filt_bl', 'TFi', 'TFe_bl', 'TFi_bl');
			save(OUT_NAME,	'ERP_filt_bl', 'TFi', 'TFe_bl', 'TFi_bl');

			fprintf('\nComplete: %s''s processing :: ',WORKNAME);	toc(AllTime);

			clearvars -except	fullPATH	Regulation						...
								dataname	datanumb	subname		subnumb	...
								trialname	trialnumb	channame	removech ...
								Freqs		m			ki					...
								lChns		MxChn		CPB			Total	...
								NUMWORKERS	DAT_NAME	WORKNAME	WORKDEST ...
								POOL		MinEpoch						...
%			cd ..;
%			clc
			% ���� 'clearvars -except' ��, �� �ڵ忡�� ���� variable�� �ʹ� ���� ������ �ϳ��ϳ� �� ���� ���� ���� �����͸� ���� �� ������ variable�� �����ϰ� ������
			% variable ���� ��� clear �϶�� ��ɾ� �Դϴ�.
		end
	end
end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%	clear	TFwow;
%%matlabpool close;
delete(POOL);	%toc is called by parent
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

fprintf('\nFinished: total time is ');	toc(Total);
