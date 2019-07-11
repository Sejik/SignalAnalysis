subdir_list= textread(['session_list'], '%s');
data_path = '/home/data/SSVEP_BKM/Mat/';

for sbj=1:length(subdir_list)

%load data of one subject:
[cnt,mrk,mnt] = eegfile_loadMatlab([data_path subdir_list{sbj}]); 

%%%%%%%%%%%%%%%%%%%%%%%
% filterbank approach %
%%%%%%%%%%%%%%%%%%%%%%%

% 111: 5Hz + 7.5Hz
% 112: 5.5Hz + 7Hz
% 113: 5.5Hz + 6Hz
% 114: 6Hz + 7.5Hz
% 115: 6.5Hz + 7Hz
% 116: 5Hz + 6.5Hz

% define a number of filterbanks
nFilts = 6;
filt_order=5;
cf=[5 5.5 6 6.5 7 7.5];
filt_a= cell(1, nFilts);
filt_b= cell(1, nFilts);

for i=1:nFilts
    sf=cf(i)-0.25;
    ef= cf(i)+0.25;
    [filt_b{i},filt_a{i}]= butter(5, [sf ef]/cnt.fs*2);
end

cnt_flt=proc_filterbank(cnt, filt_b, filt_a);

epo=cntToEpo(cnt_flt,mrk,[0 5000]);

clear xval_loss
for xv=1:10

% split the data into train and test:
% but maintain ratio of classes
train_perc=0.9;
inx_tr=[];inx_te=[];
for i=1:6
    inx=find(epo.y(i,:)==1);
    N=length(inx);
    r_inx=randperm(N);
    stopat=ceil(train_perc*N);
    inx_tr=[inx_tr inx(r_inx(1:stopat))];
    inx_te=[inx_te inx(r_inx(stopat+1:end))];
    length(inx(r_inx(1:stopat)));
    length(inx(r_inx(stopat+1:end)));
end

epo_tr=proc_selectEpochs(epo,inx_tr);
epo_te=proc_selectEpochs(epo,inx_te);

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CSP for each frequency: %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% trials where 5Hz occurs are targets, others non-targets

% csp1 - 5Hz - targets are classes 111 and 116
% select channels with 5Hz:
epo1=proc_selectChannels(epo_tr,'*_flt1');
%combine classes that have specific frequency:
epo1 = proc_combineClasses(epo1,{'1','6'},{'2','3','4','5'});
%calculate csp:
[fv1,csp1]=proc_csp3(epo1,'patterns',2);


%csp2 - 5.5Hz - targets are classes 112 and 113
% select channels with 5.5Hz:
epo2=proc_selectChannels(epo_tr,'*_flt2');
%combine classes that have specific frequency:
epo2 = proc_combineClasses(epo2,{'2','3'},{'1','4','5','6'});
%calculate csp:
[fv2,csp2]=proc_csp3(epo2,'patterns',2);

%csp3 - 6Hz - targets are classes 113 and 114
% select channels with 6Hz:
epo3=proc_selectChannels(epo_tr,'*_flt3');
%combine classes that have specific frequency:
epo3 = proc_combineClasses(epo3,{'3','4'},{'1','2','5','6'});
%calculate csp:
[fv3,csp3]=proc_csp3(epo3,'patterns',2);

%csp4 - 6.5Hz - targets are classes 115 and 116
% select channels with 6.5Hz:
epo4=proc_selectChannels(epo_tr,'*_flt4');
%combine classes that have specific frequency:
epo4 = proc_combineClasses(epo4,{'5','6'},{'1','2','3','4'});
%calculate csp:
[fv4,csp4]=proc_csp3(epo4,'patterns',2);

%csp5 - 7Hz - targets are classes 112 and 115
% select channels with 7Hz:
epo5=proc_selectChannels(epo_tr,'*_flt5');
%combine classes that have specific frequency:
epo5 = proc_combineClasses(epo5,{'2','5'},{'1','3','4','6'});
%calculate csp:
[fv5,csp5]=proc_csp3(epo5,'patterns',2);

%csp6 - 7.5Hz - targets are classes 111 and 114
% select channels with 7.5Hz:
epo6=proc_selectChannels(epo_tr,'*_flt6');
%combine classes that have specific frequency:
epo6 = proc_combineClasses(epo6,{'1','4'},{'2','3','5','6'});
%calculate csp:
[fv6,csp6]=proc_csp3(epo6,'patterns',2);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%estimate classifier for each class %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 111: 5Hz + 7.5Hz
% 112: 5.5Hz + 7Hz
% 113: 5.5Hz + 6Hz
% 114: 6Hz + 7.5Hz
% 115: 6.5Hz + 7Hz
% 116: 5Hz + 6.5Hz
A=zeros(size(csp1));
%111 (5Hz + 7.5Hz): csp1+csp6
FV1=proc_combineClasses(epo_tr,'1',{'2','3','4','5','6'});
FV1=proc_selectChannels(FV1,{'*_flt1','*_flt6'});
FV1=proc_linearDerivation(FV1,[csp1 A ; A csp6]);
FV1=proc_variance(FV1);
FV1=proc_logarithm(FV1);
C1=train_LDA(squeeze(FV1.x),FV1.y);

%112 (5.5Hz + 7Hz): csp2+csp5
FV2=proc_combineClasses(epo_tr,'2',{'1','3','4','5','6'});
FV2=proc_selectChannels(FV2,{'*_flt2','*_flt5'});
FV2=proc_linearDerivation(FV2,[csp2 A ; A csp5]);
FV2=proc_variance(FV2);
FV2=proc_logarithm(FV2);
C2=train_LDA(squeeze(FV2.x),FV2.y);

%113 (5.5Hz + 6Hz): csp2+csp3
FV3=proc_combineClasses(epo_tr,'3',{'1','2','4','5','6'});
FV3=proc_selectChannels(FV3,{'*_flt2','*_flt3'});
FV3=proc_linearDerivation(FV3,[csp2 A ; A csp3]);
FV3=proc_variance(FV3);
FV3=proc_logarithm(FV3);
C3=train_LDA(squeeze(FV3.x),FV3.y);

%114 (6Hz + 7.5Hz): csp3+csp6
FV4=proc_combineClasses(epo_tr,'4',{'1','2','3','5','6'});
FV4=proc_selectChannels(FV4,{'*_flt3','*_flt6'});
FV4=proc_linearDerivation(FV4,[csp3 A ; A csp6]);
FV4=proc_variance(FV4);
FV4=proc_logarithm(FV4);
C4=train_LDA(squeeze(FV4.x),FV4.y);

%115 (6.5Hz + 7Hz): csp4+csp5
FV5=proc_combineClasses(epo_tr,'5',{'1','2','3','4','6'});
FV5=proc_selectChannels(FV5,{'*_flt4','*_flt5'});
FV5=proc_linearDerivation(FV5,[csp4 A ; A csp5]);
FV5=proc_variance(FV5);
FV5=proc_logarithm(FV5);
C5=train_LDA(squeeze(FV5.x),FV5.y);

%116 (5Hz + 6.5Hz): csp1+csp4
FV6=proc_combineClasses(epo_tr,'6',{'1','2','3','4','5'});
FV6=proc_selectChannels(FV6,{'*_flt1','*_flt4'});
FV6=proc_linearDerivation(FV6,[csp1 A ; A csp4]);
FV6=proc_variance(FV6);
FV6=proc_logarithm(FV6);
C6=train_LDA(squeeze(FV6.x),FV6.y);

%%%%%%%%%%%%%%%%%%%%%%%%%%
% now comes the testing: %
%%%%%%%%%%%%%%%%%%%%%%%%%%


% generate six outputs, write into matrix, then do winner takes all:

% output for 111:
FV1=proc_selectChannels(epo_te,{'*_flt1','*_flt6'});
FV1=proc_linearDerivation(FV1,[csp1 A ; A csp6]);
FV1=proc_variance(FV1);
FV1=proc_logarithm(FV1);
out(1,:)=apply_separatingHyperplane(C1,squeeze(FV1.x));
% output for 112:
FV2=proc_selectChannels(epo_te,{'*_flt2','*_flt5'});
FV2=proc_linearDerivation(FV2,[csp2 A ; A csp5]);
FV2=proc_variance(FV2);
FV2=proc_logarithm(FV2);
out(2,:)=apply_separatingHyperplane(C2,squeeze(FV2.x));
% output for 113:
FV3=proc_selectChannels(epo_te,{'*_flt2','*_flt3'});
FV3=proc_linearDerivation(FV3,[csp2 A ; A csp3]);
FV3=proc_variance(FV3);
FV3=proc_logarithm(FV3);
out(3,:)=apply_separatingHyperplane(C3,squeeze(FV3.x));
% output for 114:
FV4=proc_selectChannels(epo_te,{'*_flt3','*_flt6'});
FV4=proc_linearDerivation(FV4,[csp3 A ; A csp6]);
FV4=proc_variance(FV4);
FV4=proc_logarithm(FV4);
out(4,:)=apply_separatingHyperplane(C4,squeeze(FV4.x));
% output for 115:
FV5=proc_selectChannels(epo_te,{'*_flt4','*_flt5'});
FV5=proc_linearDerivation(FV5,[csp4 A ; A csp5]);
FV5=proc_variance(FV5);
FV5=proc_logarithm(FV5);
out(5,:)=apply_separatingHyperplane(C5,squeeze(FV5.x));
% output for 116:
FV6=proc_selectChannels(epo_te,{'*_flt1','*_flt4'});
FV6=proc_linearDerivation(FV6,[csp1 A ; A csp4]);
FV6=proc_variance(FV6);
FV6=proc_logarithm(FV6);
out(6,:)=apply_separatingHyperplane(C6,squeeze(FV6.x));

xval_loss(xv)=mean(loss_0_1(epo_te.y,-out));
1-xval_loss(xv)
end
xval_loss_subj(sbj)=mean(xval_loss)
end

