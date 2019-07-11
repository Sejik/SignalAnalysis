% please load eEEG for each experiment and condition:
clear;clc;

%% setting %%
path(pathdef);		%<UserPath>�� �ִ� pathdef.m �� �����Ͽ� �߰����� path�� ���

%% Header %%
global	DAT_NAME;
global	NUMWORKERS;
global	WORKNAME;
global	TF;					%Time&Freq axis data = freq x time array

%%�ֿ� ���������� WorkSpace�� �����Ѵ�.@@@@@@@@@@@@@@@@@@@@@@@@@@
[	fullPATH, Regulation, channame, removech, dataname, trialname, subname,	...
	Freqs, fName, m, ki	]	=	A_globals_AmH();

%data=[length(dataname)*length(trialname):3];  %[datanumb * trialnumb] * [f, t_start, t_fin]
%Freqs		=[	4:1/2:8		];		% ��Ÿ�ĸ� ��� ��. step 0.5
%m	=7; ki	=	 5;					% wavelet �м��� ���� default ��
%CUATION!: epoch size mismatch for TF_USA_dislike_su20.mat(377 epoch)
%	so, tf2coh_min2_AmH_mex() do not cover this. because loop val is constant.
%CUATION!: file is damaged for
%	TF_Unfav_Paki_dislike_su19.mat
%	Neutral_Mexico_dislike_su25.mat

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

%%-------------------------------------------------------------------------------
% Analysis PLV using TF data
% -------------------------------------------------------------------------------
%data=load('inputusa1.txt');
%a=1;
for datanumb			=	1:length(dataname)
	for trialnumb		=	1:length(trialname)
		for subnumb		=	1:length(subname)
			%			cd skk_tf;
			%���Ǹ� ���� ���ϸ��� ������ ��
			WORKNAME	=[	char(subname{subnumb})		'_'					...
							Regulation					'_'					...
							char(dataname{datanumb})	'_'					...
							char(trialname{trialnumb})	];
%			WORKNAME	=[	char(dataname{datanumb})	'_'	...
%							char(trialname{trialnumb})	'_'	...
%							char(subname{subnumb})		];
			DAT_NAME	=[	fullPATH '/skk_dat/' 'skk_' WORKNAME '.dat'	];
			OUT_NAME	=[ fullPATH '/skk_PLV_' fName '/Phase_' WORKNAME '.mat'];

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

			tic;					%������ preparing �ð��� �����Ѵ�.
			fprintf('Convert : %s''s DAT to TF data on WORKSPACE.\n',WORKNAME);
			%'\n'���ϴ� ������ �Ʒ��� toc ����� ���� �پ���� �Ϸ���.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			%check & auto skip if not exist a 'dat file.
			fprintf('Checking: Source DAT file: ''%s''... ', DAT_NAME);
			if exist(DAT_NAME, 'file') <= 0					%skip
				fprintf('not! & SKIP converting this\n');
				continue;									%exist !!
			else
				fprintf('EXIST & Continue the converting\n');
			end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%-------------------------------------------------------------------------------
% Convert: DAT -> eEEG...mat
% -------------------------------------------------------------------------------
			[nChan,lChan,SDP,fSmpl]=load_ExpInfo_AmH([fullPATH '/skk_dat/skk_']);
			% nChan : ä�� ����
			% lChan : ä�� ���

			%% Subjects_All Epochs_bl
%			cd skk_dat;
%			eval(['DataBuf = importdata(''' fullPATH '/skk_dat/skk_' char(subname{subnumb}) '_BaselineCorrection_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '.dat'');']);
%			eval(['DataBuf	=	importdata(''' fullPATH		...
%									'/skk_dat/skk_' DAT_NAME '.dat'');']);
			eval(['DataBuf	=	importdata(''' DAT_NAME ''');']);
			%*.dat ������ ù �ٿ� ����� ä�� ������ Ȯ���� ���ƾ� ��!

%			cd ..;
%			B			=	DataBuf.data;
%			B			=	shiftdim(B, 1);
%			eEEG		=	reshape(B, 1000, [], 32);
%			eEEG		=	reshape(DataBuf.data, 1000, [], 32);
			eEEG		=	reshape(DataBuf.data, SDP, [], nChan);
			% eEEG(timepoint * epochs * ch)

%			clear B DataBuf
			clear DataBuf

			eEEG(:,:,17)=	NaN;	% EOG
			eEEG(:,:,22)=	NaN;	% NULL

%			eval(['FILENAME=''skk_' char(subname{subnumb}) '_BaselineCorrection_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) ''';']);
%			eval(['FILENAME	=	''/skk_data/skk_' DAT_NAME ''';']);	%�⺻:*.mat
%			cd skk_mat;
%			save(FILENAME, 'eEEG');	% eEEG ��̸� ������.
%			cd ..
%%			save([fullPATH '/skk_data/skk_' DAT_NAME], 'eEEG');	% eEEG array ����
%%			clear eEEG

%%-------------------------------------------------------------------------------
% Convert: eEEG...mat -> partitioning	%-[
% -------------------------------------------------------------------------------
%			cd skk_mat;
%			eval(['load(''skk_' char(subname{subnumb}) '_BaselineCorrection_' char(dataname{datanumb}) '_' char(trialname{trialnumb})  '.mat'');']);
%			cd ..;

%+			eEEG1= eEEG(:,:,1:16);	% EOG ���� ������ eEEG array ����: ���ݺ�
%+			eEEG2= eEEG(:,:,17:32);	% EOG ���� ������ eEEG array ����: �Ĺݺ�
%+
%+			cd skk_eEEG;
%+			eval(['FILENAME=''eEEG_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) ''';']);
%+			save(FILENAME, 'eEEG');
%+
%+
%+			eval(['FILENAME=''eEEG_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '_1'';']);
%+			save(FILENAME, 'eEEG1');
%+
%+
%+			eval(['FILENAME=''eEEG_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '_2'';']);
%+			save(FILENAME, 'eEEG2');
%+			cd ..;
%+			clear eEEG eEEG1 eEEG2	%-]

%%-------------------------------------------------------------------------------
% Convert: eEEG...mat -> TF
% -------------------------------------------------------------------------------
%fsamp		=	 500;				% sampling point�� ����
%m	=7; ki	=	 5;					% wavelet �м��� ���� default ��
%			cd skk_eEEG;
%			eval(['eEEG = importdata(''eEEG_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '.mat'');']);
%			cd ..;

%+			% ERP �м�	%-[
%+			chs			=	 [1:32];			% ä��
%+			blEEG		=	eEEG;	%�ð��� �м� ERP, freq �м� ���� ��Ÿ ���� ��
%+			bl			=	zeros(size(eEEG,2),'single');%=timepoint * epoch * ch
%+			% baseline�� ����� ��: �ڱ� �������� ������ ��� ��� baseline��
%+			% ������. correction�� �Ѵ�. common reference ���� ����� ����.
%+			% �� ���� ��� ä���� �����ִ� ���� baseline.
%+			% ������ �м� �� ������ �ڱ� ������ baseline�� ������ �ʴ´�.
%+			% ���� ERP �� ������ 0.5-1.5 ���ļ� �м��� �� ������
%+			% -0.5 (���̾ ���� ������) ���̸� ����ִ� ���� �ʿ�
%+			% ���� �ð� ������ ��� ��. �ð�, ���� , ä��, (���߿� ���ļ�)
%+%			bl			=	single(bl); % single: ���� data ���� or ������??
%+
%+			ERP			=	zeros(size(eEEG,1),length(chs));
%+			% �Ͳ�? matlab���� ��� �ϱ����ؼ� dimension�� ������ִ� ��.
%+			% Ʋ ����� �ִ� ��
%+			% ERP ������ timepoint �� channel �ΰ����� ǥ����.
%+			% ������ ��� ��� 2�������� �پ���� ��
%+			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%+			% ERP ���ϴ� ��
%+			for ii		=	1:length(chs);
%+				ch					=	chs(ii);
%+				bl(1,:)				=	squeeze(mean(eEEG([1:250],:,ch),1));
%+				%�ڱ����� �� -500~0ms �� baseline �� ������.
%+
%+				%������ baseline ���� �� ä�κ��� ���־� correction ��.
%+				for yy	=	1:size(bl),
%+					blEEG(:,yy,ch)	=	squeeze(eEEG(:,yy,ch))-bl(1,yy);
%+					%���⼭ baseline correction�� ����.
%+					%squeeze�� ������ ������ �پ��� single ton
%+				end;
%+
%+				ERP(:,ch)			=	squeeze(mean(blEEG(:,:,ch),2));
%+				%�ð��� ä�θ� ���� (ERP ����)
%+			end;	%-]

			%%%%%%%%%%% Time-Frequency Analysis : Total activity = TFi
			% frequency�� �� �ʿ� �ٿ���
			% shift demension�� ����ؼ� ������ �ٲ� �� �ִ�.
%+			TF_origin	=	epoch2tf_min(eEEG,Freqs,fsamp,m,ki);
%+			TF_origin	=	epoch2tf_min_AmH(eEEG,Freqs,fsamp,m,ki);
			%TF�� ���� (total activity)
%+			tic; TF		=	single(TF_origin);	% 4D array : f,t,e,c
%			tic; TF		=	single( epoch2tf_min_AmH(eEEG,Freqs,fSmpl,m,ki) );
			tic; TF		=	epoch2tf_min_AmH(eEEG,Freqs,fSmpl,m,ki);
			TF			=	single(TF);			%TF_power���� single ó�� �ʿ�x

%+			%%%%%%%%%%% Time-Frequency Analysis : Evoked activity = TFe_bl %-[
%+			[TFi,TFP,TFA]=	tf2tfi_min(TF);		% iPA�� ����� �ִ� ��
%+										% induce�� total activity ���� �� �ִ�.
%+
%+			% evoked tf (without baseline_correction)
%+			TFe			=	zeros([length(Freqs) size(ERP)]);
%+			% �ð� ���ļ� �м������� evoked�� induced�� �߿��ϰ� �м��Ѵ�.
%+			for ch		=	1:size(ERP,2),
%+				[tf1,tfa1,tfc1]	=	tfmorlet_min(ERP(:,ch),fSmpl,Freqs,m,ki);
%+				%Evoked activity ���ϱ� ���� �� ä�� �� morlet wavelet �м� �ǽ�.
%+
%+				TFe(:,:,ch)		=	tf1;
%+			end; %wavelet�� baseline correction�ʿ�. edge�� �Ⱦ��� �񲸼� ���� ��
%+
%+			% evoked tf (with baseline_correction)
%+			TF_bl		=	squeeze(mean(TFe(:,51:200,:),2));
%+			% wavelet �м� �� -400~100ms ������ baseline���� �ٽ� correction ��.
%+			TFe_bl		=	TFe;
%+			fn			=	length(Freqs);
%+			chn			=	size(TFe,3);
%+			for i		=	1:chn,
%+				for f	=	1:fn,
%+					TFe_bl(f,:,i)	=	TFe(f,:,i)-TF_bl(f,i);
%+				end;
%+			end;
%+
%+			cd skk_tf;
%+			FILENAME = [fullPATH '/skk_tf/TF_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '_x' ]; 
%+			save(FILENAME, 'TF_origin', 'ERP', 'TFi', 'TFe_bl', '-v7.3');	%v7.3�ɼ��� ������ TF_origin �� 2G ũ�� �̻��� �� ���� ������.
%+			cd ..;
%+			clear TF_origin ERP TFi TFP TFA TFe_bl;
%+%			clearvars -except dataname datanumb trialname trialnumb subname subnumb chs
%+%			clc		%-]
			toc;							%�۾� ����ð� ���
%%-------------------------------------------------------------------------------
% Convert: eEEG...mat -> TF
% -------------------------------------------------------------------------------
%+			fprintf('Loading : %s''s TF data to WORKSPACE. ',	WORKNAME);	%'\n'���ϴ� ������ �Ʒ��� toc ����� ���� �پ���� �Ϸ���.
%			eval(['load(''TF_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '.mat'');']);
%			eval(['load(''TF_' WORKPATH '.mat'');']);
%+			eval(['load(''' fullPATH '/skk_tf/' 'TF_' WORKNAME '.mat'',''TF_origin'',''-mat'');']);

%			cd ..;
%+			TF			=	TF_origin;
%+			clear TF_origin;				% TF_origin�� ���� �ʿ������ ����
%			TF(:,:,:,length(channame)+1:size(TF,4))=	[];	%20150516A. ���� ����, �ּ� ä�θ� ����
%+			toc;							%�۾� ����ð� ���

%% 20150517B. TF �����Ϳ� ���� �⺻���� ó��/���� ����� �ʿ���.	%-[
			%��, 32�� ä�� ��ü�� �������� ��쿡��, ����ä���� �����ؾ� �Ѵ�.
			% ch17= EOG, ch22=NULL, ���� �κ��� ����. �ڿ��� ���� ������ ����� ó����. ->
			% 20150517C. ���� �� ������ ��������. �տ������� ������� ���� ����
			tic; fprintf('\nFinding : & remove a dummy channels on TF array. ');
			selchanname	=	channame;
			for f=1:length(removech)		%������ ä���� ������� �˻�
				ch1		=	find(strcmp(selchanname, removech(f)), 1);	%����ä���� �ε��� ã��
				if ~isempty(ch1) && size(TF,4)==length(selchanname),
					TF(:,:,:,ch1)	=	[];	%EOG�� Ÿä�� ���� ���赵 ������ ����
					selchanname(ch1)=	[];	%�ش� ä�ε� ����
				end							%����, TF�� chan �� index ���� ����
			end
			toc;							%�۾� ����ð� ���	%-]

			%TF ������ �� NaN �� ���� ������, �ش� ���� ���� ä�ΰ��� �񱳿���
			%�Ź� ������ ���� �����Ͽ�, ���� �м����� ����ġ�� ������.
			%����, �� ���� ���� ä���� �ִٸ�, Notify �ؾ� ��!!
			%TF �Ը� ������ �ؼ� , �ð��� �ҿ� �� �� �ִ�. 
			tic; fprintf('Search  : a NaN value on TF array\n');
			flagNaN		=	0;
%			for f=1:size(TF,1)	for t=1:size(TF,2)	for epoch=1:size(TF,3)	for ch=1:size(TF,4)
			for f=1:size(TF,1)	for ch=1:size(TF,4)
				if any(any(any(any(isnan(TF(f,:,:,ch)))))),	%4D �̹Ƿ� any*4 �ؾ� ��Į�� �� ��
					flagNaN	=	1;
%					fprintf('Notify: TF havs a undefined values at [FreqIdx(%d), TimeZone(%d), Epoch(%d), Ch(%d)]\n', f, t, epoch, ch);
					fprintf(['Notify: TF has a undefined values at ' ...
							'[FreqIdx(%d), Ch(%d)]\n'], f, ch);
				end
			end
			end
			if flagNaN,		%NaN �� �߰�!
				fprintf('Press CTRL+C to stop or AnyKey to continue\n');
				pause;
			end
			fprintf('Search  : completed. ');	toc;		%�۾� ����ð� ���

%%-------------------------------------------------------------------------------
%% �м� ����: parallel call to tf2coh_min by SPMD
% -------------------------------------------------------------------------------
%			TFwow			=	WorkerObjWrapper(TF);		%��Ŀ�� wrapper
			tic; [PLV, PLS]	=	MinMinMin_phase6A_AmH(Freqs);
%			tic; [PLV, PLS]	=	MinMinMin_phase8_AmH(TF, Freqs);
%			tic; [PLV, PLS]	=	MinMinMin_phase8_AmH(Freqs);
%			cd skk_phase;
			fprintf('Analysis: completed. ');	toc;		%�۾� ���� �ð� ���

			fprintf('Storing : PLV & PLS data@COH(Phase) to %s\n\n', OUT_NAME);
%			FILENAME = ['Phase_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb})]; 
%			FILENAME = ['Phase_' WORKPATH ]; 
%			save(FILENAME,'-v7.3')
%			cd ..;
%			cd 'x:\SKK_theta_anterior_only\skk_coh';			%coh�����͸� ������ ��_���_���� ���� path
			%��ü ������ ����, PLV, PLS �� ����
%			save([fullPATH '/skk_phase30/' 'Phase_' WORKNAME '.mat'], ...
%				'channame', 'selchanname', 'PLV', 'PLS', '-v7.3');
			save(OUT_NAME, 'channame', 'selchanname', 'PLV', 'PLS', '-v7.3');
		end
	end
end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%	clear	TFwow;
%%matlabpool close;
delete(POOL);	%toc is called by parent
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

quit

