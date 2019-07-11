cd D:\2011_LG\data\final;

subnums=[1:2 4 8:13 15 18 20:25 28:30]; %% New finally for condition 2
% subnums=[1 8:11 13 18:25 28:30]; %% finally for condition 2
% subnums=[1 6 8:11 13 18:25 28:30]; %% roughly for condition 2

% subnums=[1:2 4:12 14:16 18 20:23 25:26 28:30]; %% except for su03, (su13), su17; (su19); (su24); su27
% subnums=[1:2 4:16 18:26 28:30]; %% Analysis purpose except for su03, su17; su27
% subnums=[1:2 4:9 11:18 20:23];
% subnums=[4:5 7:9 11:12 14 16:18 20:21];
conds= [1:4];
trigs={char('3132'), char('5152'), char('7172')};

ch=9;
% FZ:9, Cz:19, Pz:30, Oz:35
% FP1:3, FP2:4, F3:8, F4:10, F7:7, F8:11, FT7:12, FC3:13, FCZ:14, FC4:15, FT8: 16,

timewin=50:200;
tw_P1=290:310; % P200 +/-40ms (160ms to 240ms)
tw_N1=275:295; % N140 +/-40ms (100ms to 180ms)
freqwin=7:19;
sl=length(subnums);
LG_spss=zeros(sl,36);
LG_spss_ERP=zeros(sl,48);
load channame.mat;

for jj=1:length(subnums);
       su=subnums(jj);
      
    for xx=1:length(conds);
        cond=conds(xx);
    
    for x=1:length(trigs);
        trig=trigs{x};
    
eval(['load LG' num2str2(su) '_cond' num2str(cond) '_trg' trig '.mat;']);

aTFi=squeeze(TFi(:,:,ch)); 
eval(['TFi_su' num2str2(su) '_cond' num2str(cond) '_trg' trig '_' channame{1,ch} '=aTFi;']);

[M1, I1]=max(aTFi(freqwin, timewin));
[M5, I5]=max(max(aTFi(freqwin, timewin)));
eval(['max_su' num2str2(su) '_cond' num2str(cond) '_trg' trig '_' channame{1,ch} '=M5;']);
I2=I1(find(max(M1))); ITF=(I2-1)*0.5+4;
eval(['ITF_su' num2str2(su) '_cond' num2str(cond) '_trg' trig '_' channame{1,ch} '=ITF;']);

eval(['mean_su' num2str2(su) '_cond' num2str(cond) '_trg' trig '_' channame{1,ch} '=mean(aTFi((ITF*2)-1, timewin));']);

ERP_filt_bl=squeeze(ERP_filt_bl(:,ch)); 
eval(['ERP_su' num2str2(su) '_cond' num2str(cond) '_trg' trig '_' channame{1,ch} '=ERP_filt_bl;']);

[P1max, P1idx]=max(ERP_filt_bl(tw_P1));
P1lat=(P1idx+tw_P1(1)-1)*(1/250)-1;
[N1max, N1idx]=max((-1)*ERP_filt_bl(tw_N1));
N1min=-N1max;
N1lat=(N1idx+tw_N1(1)-1)*(1/250)-1;

eval(['P1max_su' num2str2(su) '_cond' num2str(cond) '_trg' trig '_' channame{1,ch} '=P1max;']);
eval(['P1lat_su' num2str2(su) '_cond' num2str(cond) '_trg' trig '_' channame{1,ch} '=P1lat;']);
eval(['N1min_su' num2str2(su) '_cond' num2str(cond) '_trg' trig '_' channame{1,ch} '=N1min;']);
eval(['N1lat_su' num2str2(su) '_cond' num2str(cond) '_trg' trig '_' channame{1,ch} '=N1lat;']);

    end;
    end;
    
    eval(['LG_spss(' num2str(jj) ',:)=[ITF_su' num2str2(su) '_cond1_trg3132_FZ max_su' num2str2(su) '_cond1_trg3132_FZ mean_su' num2str2(su) '_cond1_trg3132_FZ ITF_su' num2str2(su) '_cond1_trg5152_FZ max_su' num2str2(su) '_cond1_trg5152_FZ mean_su' num2str2(su) '_cond1_trg5152_FZ ITF_su' num2str2(su) '_cond1_trg7172_FZ max_su' num2str2(su) '_cond1_trg7172_FZ mean_su' num2str2(su) '_cond1_trg7172_FZ ITF_su' num2str2(su) '_cond2_trg3132_FZ max_su' num2str2(su) '_cond2_trg3132_FZ mean_su' num2str2(su) '_cond2_trg3132_FZ ITF_su' num2str2(su) '_cond2_trg5152_FZ max_su' num2str2(su) '_cond2_trg5152_FZ mean_su' num2str2(su) '_cond2_trg5152_FZ ITF_su' num2str2(su) '_cond2_trg7172_FZ max_su' num2str2(su) '_cond2_trg7172_FZ mean_su' num2str2(su) '_cond2_trg7172_FZ ITF_su' num2str2(su) '_cond3_trg3132_FZ max_su' num2str2(su) '_cond3_trg3132_FZ mean_su' num2str2(su) '_cond3_trg3132_FZ ITF_su' num2str2(su) '_cond3_trg5152_FZ max_su' num2str2(su) '_cond3_trg5152_FZ mean_su' num2str2(su) '_cond3_trg5152_FZ ITF_su' num2str2(su) '_cond3_trg7172_FZ max_su' num2str2(su) '_cond3_trg7172_FZ mean_su' num2str2(su) '_cond3_trg7172_FZ ITF_su' num2str2(su) '_cond4_trg3132_FZ max_su' num2str2(su) '_cond4_trg3132_FZ mean_su' num2str2(su) '_cond4_trg3132_FZ ITF_su' num2str2(su) '_cond4_trg5152_FZ max_su' num2str2(su) '_cond4_trg5152_FZ mean_su' num2str2(su) '_cond4_trg5152_FZ ITF_su' num2str2(su) '_cond4_trg7172_FZ max_su' num2str2(su) '_cond4_trg7172_FZ mean_su' num2str2(su) '_cond4_trg7172_FZ];']);      
    eval(['LG_spss_ERP(' num2str(jj) ',:)=[P1max_su' num2str2(su) '_cond1_trg3132_FZ P1lat_su' num2str2(su) '_cond1_trg3132_FZ N1min_su' num2str2(su) '_cond1_trg3132_FZ N1lat_su' num2str2(su) '_cond1_trg3132_FZ P1max_su' num2str2(su) '_cond1_trg5152_FZ P1lat_su' num2str2(su) '_cond1_trg5152_FZ N1min_su' num2str2(su) '_cond1_trg5152_FZ N1lat_su' num2str2(su) '_cond1_trg5152_FZ P1max_su' num2str2(su) '_cond1_trg7172_FZ P1lat_su' num2str2(su) '_cond1_trg7172_FZ N1min_su' num2str2(su) '_cond1_trg7172_FZ N1lat_su' num2str2(su) '_cond1_trg7172_FZ P1max_su' num2str2(su) '_cond2_trg3132_FZ P1lat_su' num2str2(su) '_cond2_trg3132_FZ N1min_su' num2str2(su) '_cond2_trg3132_FZ N1lat_su' num2str2(su) '_cond2_trg3132_FZ P1max_su' num2str2(su) '_cond2_trg5152_FZ P1lat_su' num2str2(su) '_cond2_trg5152_FZ N1min_su' num2str2(su) '_cond2_trg5152_FZ N1lat_su' num2str2(su) '_cond2_trg5152_FZ P1max_su' num2str2(su) '_cond2_trg7172_FZ P1lat_su' num2str2(su) '_cond2_trg7172_FZ N1min_su' num2str2(su) '_cond2_trg7172_FZ N1lat_su' num2str2(su) '_cond2_trg7172_FZ P1max_su' num2str2(su) '_cond3_trg3132_FZ P1lat_su' num2str2(su) '_cond3_trg3132_FZ N1min_su' num2str2(su) '_cond3_trg3132_FZ N1lat_su' num2str2(su) '_cond3_trg3132_FZ  P1max_su' num2str2(su) '_cond3_trg5152_FZ P1lat_su' num2str2(su) '_cond3_trg5152_FZ N1min_su' num2str2(su) '_cond3_trg5152_FZ N1lat_su' num2str2(su) '_cond3_trg5152_FZ P1max_su' num2str2(su) '_cond3_trg7172_FZ P1lat_su' num2str2(su) '_cond3_trg7172_FZ N1min_su' num2str2(su) '_cond3_trg7172_FZ N1lat_su' num2str2(su) '_cond3_trg7172_FZ P1max_su' num2str2(su) '_cond4_trg3132_FZ P1lat_su' num2str2(su) '_cond4_trg3132_FZ N1min_su' num2str2(su) '_cond4_trg3132_FZ N1lat_su' num2str2(su) '_cond4_trg3132_FZ P1max_su' num2str2(su) '_cond4_trg5152_FZ P1lat_su' num2str2(su) '_cond4_trg5152_FZ N1min_su' num2str2(su) '_cond4_trg5152_FZ N1lat_su' num2str2(su) '_cond4_trg5152_FZ P1max_su' num2str2(su) '_cond4_trg7172_FZ P1lat_su' num2str2(su) '_cond4_trg7172_FZ N1min_su' num2str2(su) '_cond4_trg7172_FZ N1lat_su' num2str2(su) '_cond4_trg7172_FZ];']);
         
end;

save LG_SPSS_FZ.mat LG_spss LG_spss_ERP;
% figure;plotscatter(OCD,{'alp_c_FZ','alp_s_FZ','alp_c_Oz','alp_s_Oz','the_c_FZ','the_s_FZ','the_c_Oz','the_s_Oz'})
% plot(OCD')