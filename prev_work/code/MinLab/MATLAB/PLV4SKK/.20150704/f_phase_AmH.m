% please load eEEG for each experiment and condition:
clear;clc;


%% Header %%
fullPATH	=	'/home/minlab/PLV_theta';
channame	={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
removech	={'EOG', 'NULL' };	%������ ä��
%selchan		={};				%channame - removech
%
dataname	={'Fav_USA', 'Neutral_Mexico', 'Unfav_Paki'};
trialname	={'dislike', 'like'};
subname		={'su27', 'su28', 'su29'};
%data=[length(dataname)*length(trialname):3];  %[datanumb * trialnumb] * [f, t_start, t_fin]
FR			=	[4.0, 8.0];										%���ļ� ����, ��

%%

%data=load('inputusa1.txt');
%a=1;
for datanumb= 1:length(dataname)
	for trialnumb=1:length(trialname)
		for subnumb= 1:length(subname)
%			cd skk_tf;
			%���Ǹ� ���� ���ϸ��� ������ ��
			WORKNAME	=	[ char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) ];

			tic;											%������ preparing �ð��� �����Ѵ�.
			fprintf('Loading : %s''s TF data to WORKSPACE. ',	WORKNAME);	%'\n'���ϴ� ������ �Ʒ��� toc ����� ���� �پ���� �Ϸ���.
%			eval(['load(''TF_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '.mat'');']);
%			eval(['load(''TF_' WORKPATH '.mat'');']);
			eval(['load(''' fullPATH '/skk_tf/' 'TF_' WORKNAME '.mat'',''TF_origin'',''-mat'');']);

%			cd ..;
			TF			=	TF_origin;
			clear TF_origin;								% TF_origin�� ���� �ʿ������ ����
%			TF(:,:,:,length(channame)+1:size(TF,4))=	[];	%20150516A. ���� ����, �ּ� ä�θ� ����
			toc;											%�۾� ����ð� ���

%% 20150517B. TF �����Ϳ� ���� �⺻���� ó��/���� ����� �ʿ���.
			%��, 32�� ä�� ��ü�� �������� ��쿡��, ����ä���� �����ؾ� �Ѵ�.
			% ch17= EOG, ch22=NULL, ���� �κ��� ����. �ڿ��� ���� ������ ����� ó����. ->
			% 20150517C. ���� �� ������ ��������. �տ������� ������� ���� ����
			tic; fprintf('Finding : & remove a dummy channels on TF array. ');
			selchanname	=	channame;
			for f=1:length(removech)						%������ ä���� ������� �˻�
				ch1		=	find(strcmp(selchanname, removech(f)), 1);	%����ä���� �ε��� ã��
				if ~isempty(ch1) && size(TF,4)==length(selchanname),
					TF(:,:,:,ch1)	=	[];					%EOG�� Ÿä�� ���� ���赵 ������ ����
					selchanname(ch1)=	[];					%�ش� ä�ε� ����
				end											%����, TF�� chan �� index ���� ����
			end
			toc;											%�۾� ����ð� ���

			%TF ������ �� NaN �� ���� ������, �ش� ���� ���� ä�ΰ��� �񱳿���
			%�Ź� ������ ���� �����Ͽ�, ���� �м����� ����ġ�� ������.
			%����, �� ���� ���� ä���� �ִٸ�, Notify �ؾ� ��!!
			%TF �Ը� ������ �ؼ� , �ð��� �ҿ� �� �� �ִ�. 
			tic; fprintf('Search  : a NaN value on TF array\n');
			flagNaN			=	0;
%			for f=1:size(TF,1)	for t=1:size(TF,2)	for epoch=1:size(TF,3)	for ch=1:size(TF,4)
			for f=1:size(TF,1)	for ch=1:size(TF,4)
				if any(any(any(any(isnan(TF(f,:,:,ch)))))),	%4D �̹Ƿ� any*4 �ؾ� ��Į�� �� ��
					flagNaN		=	1;
%					fprintf('Notify: TF havs a undefined values at [FreqIdx(%d), TimeZone(%d), Epoch(%d), Ch(%d)]\n', f, t, epoch, ch);
					fprintf('Notify: TF has a undefined values at [FreqIdx(%d), Ch(%d)]\n', f, ch);
				end
			end
			end
			if flagNaN,		%NaN �� �߰�!
				fprintf('Press CTRL+C to stop or AnyKey to continue\n');
				pause;
			end
			fprintf('Search  : completed. ');	toc;		%�۾� ����ð� ���

%% �м� ����.
			tic; MinMinMin_phase7_AmH();	%call to tf2coh_min() that performance improved
%			cd skk_phase;
			fprintf('Analysis: completed. ');	toc;		%�۾� ���� �ð� ���

			fprintf('Storing : PLV & PLS data@COH(Phase) to %s\n', [ fullPATH '/skk_phase30' ]);
%			FILENAME = ['Phase_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb})]; 
%			FILENAME = ['Phase_' WORKPATH ]; 
%			save(FILENAME,'-v7.3')
%			cd ..;
%			cd 'x:\SKK_theta_anterior_only\skk_coh';			%coh�����͸� ������ ��_���_���� ���� path
			%��ü ������ ����, PLV, PLS �� ����
			save([fullPATH '/skk_phase30/' 'Phase_' WORKNAME '_x.mat'], 'channame', 'selchanname', 'PLV', 'PLS', '-v7.3');
		end
	end
 end
