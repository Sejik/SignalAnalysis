% please load eEEG for each experiment and condition:
clear;clc;


%% Header %%
fullPATH	=	'/home/minlab/PLV_theta';
channame	={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
removech	={'EOG', 'NULL' };	%제거할 채널
%selchan		={};				%channame - removech
%
dataname	={'Fav_USA', 'Neutral_Mexico', 'Unfav_Paki'};
trialname	={'dislike', 'like'};
subname		={'su27', 'su28', 'su29'};
%data=[length(dataname)*length(trialname):3];  %[datanumb * trialnumb] * [f, t_start, t_fin]
FR			=	[4.0, 8.0];										%주파수 시작, 끝

%%

%data=load('inputusa1.txt');
%a=1;
for datanumb= 1:length(dataname)
	for trialnumb=1:length(trialname)
		for subnumb= 1:length(subname)
%			cd skk_tf;
			%편의를 위해 파일명을 구성해 둠
			WORKNAME	=	[ char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) ];

			tic;											%데이터 preparing 시간을 계측한다.
			fprintf('Loading : %s''s TF data to WORKSPACE. ',	WORKNAME);	%'\n'안하는 이유는 아래의 toc 결과가 끝에 붙어나오게 하려고.
%			eval(['load(''TF_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '.mat'');']);
%			eval(['load(''TF_' WORKPATH '.mat'');']);
			eval(['load(''' fullPATH '/skk_tf/' 'TF_' WORKNAME '.mat'',''TF_origin'',''-mat'');']);

%			cd ..;
			TF			=	TF_origin;
			clear TF_origin;								% TF_origin은 이제 필요없으니 삭제
%			TF(:,:,:,length(channame)+1:size(TF,4))=	[];	%20150516A. 실험 위해, 최소 채널만 남김
			toc;											%작업 종료시간 출력

%% 20150517B. TF 데이터에 대한 기본적인 처리/점검 기능이 필요함.
			%단, 32개 채널 전체를 수행했을 경우에는, 더미채널을 제거해야 한다.
			% ch17= EOG, ch22=NULL, 없는 부분을 날림. 뒤에서 부터 날려야 제대로 처리됨. ->
			% 20150517C. 이젠 이 제약은 없어졌음. 앞에서부터 순서대로 제거 가능
			tic; fprintf('Finding : & remove a dummy channels on TF array. ');
			selchanname	=	channame;
			for f=1:length(removech)						%제거할 채널을 대상으로 검색
				ch1		=	find(strcmp(selchanname, removech(f)), 1);	%더미채널의 인덱스 찾기
				if ~isempty(ch1) && size(TF,4)==length(selchanname),
					TF(:,:,:,ch1)	=	[];					%EOG와 타채널 간의 관계도 조사해 보자
					selchanname(ch1)=	[];					%해당 채널도 제거
				end											%따라서, TF와 chan 간 index 동일 유지
			end
			toc;											%작업 종료시간 출력

			%TF 데이터 중 NaN 인 것이 있으면, 해당 값을 가진 채널과의 비교에서
			%매번 엉뚱한 값을 생성하여, 종전 분석과의 불일치를 유발함.
			%따라서, 이 값을 가진 채널이 있다면, Notify 해야 함!!
			%TF 규모가 광범위 해서 , 시간이 소요 될 수 있다. 
			tic; fprintf('Search  : a NaN value on TF array\n');
			flagNaN			=	0;
%			for f=1:size(TF,1)	for t=1:size(TF,2)	for epoch=1:size(TF,3)	for ch=1:size(TF,4)
			for f=1:size(TF,1)	for ch=1:size(TF,4)
				if any(any(any(any(isnan(TF(f,:,:,ch)))))),	%4D 이므로 any*4 해야 스칼라 값 됨
					flagNaN		=	1;
%					fprintf('Notify: TF havs a undefined values at [FreqIdx(%d), TimeZone(%d), Epoch(%d), Ch(%d)]\n', f, t, epoch, ch);
					fprintf('Notify: TF has a undefined values at [FreqIdx(%d), Ch(%d)]\n', f, ch);
				end
			end
			end
			if flagNaN,		%NaN 값 발견!
				fprintf('Press CTRL+C to stop or AnyKey to continue\n');
				pause;
			end
			fprintf('Search  : completed. ');	toc;		%작업 종료시간 출력

%% 분석 개시.
			tic; MinMinMin_phase7_AmH();	%call to tf2coh_min() that performance improved
%			cd skk_phase;
			fprintf('Analysis: completed. ');	toc;		%작업 종료 시간 출력

			fprintf('Storing : PLV & PLS data@COH(Phase) to %s\n', [ fullPATH '/skk_phase30' ]);
%			FILENAME = ['Phase_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb})]; 
%			FILENAME = ['Phase_' WORKPATH ]; 
%			save(FILENAME,'-v7.3')
%			cd ..;
%			cd 'x:\SKK_theta_anterior_only\skk_coh';			%coh데이터를 저장할 랩_백업_서버 상의 path
			%전체 데이터 말고, PLV, PLS 만 저장
			save([fullPATH '/skk_phase30/' 'Phase_' WORKNAME '_x.mat'], 'channame', 'selchanname', 'PLV', 'PLS', '-v7.3');
		end
	end
 end
