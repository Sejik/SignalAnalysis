clear all; close all; clc;

%% Header
channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'B', 'G', 'R', 'W'};
trialname={'B', 'G', 'R', 'W'};
subname={'su0001', 'su0002', 'su0003', 'su0004', 'su0005', 'su0006', 'su0007', 'su0009', 'su0010', 'su0011', 'su0013', 'su0017', 'su0018'};
selchanname={'P3', 'Pz', 'P4', 'O1', 'Oz', 'O2'};

TEST={;};
TEST{1,1}='Student'; TEST{1,2}='IF'; TEST{1,3}='IT'; TEST{1,4}='Power';
i=2;
%%
for datanumb= 1:length(dataname)
    for trialnumb=1:length(trialname)
        for subnumb= 1:length(subname)
            for selchannum= 1:length(selchanname)
                
             eval(['TFs = importdata(''TFs_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '_' char(selchanname{selchannum}) '.mat'');']);
             TF1=TFs(:, [50:200]);  % TFs(Frequency * Timepoint) 에서 STRIKE ZONE 을 설정함. 즉, 자극 후 (-50~-400ms : 50~200tp) evoked beta (13-30Hz : 1~35frequency point) 
             %%%%%%%%%%%%%%%%%%%%%%%%% power 최대값의 Frequency와 그 때의 Timepoint를 찾는과정
             [M, I] = max(TF1);
             [M2, I2] = max(max(TF1));
             I3 = I(find(max(M)));
             IF = (I3-1)*0.5+13;     % frequency point 말고 Hz로 보고함. 13Hz부터 strike zone 을 찾고있었으니까 +13

             M = double(M);         % 자꾸 오류남.. 추가.
             pks = findpeaks(M,'sortstr','descend');
             pksnum = length(pks);
             if pksnum == 0
                  b=I2;             % 만약 peakpoint가 없을 경우.. 그냥 power 최고점의 timepoint로. (10/11 최종수정) 
                  pks2 = M2;        % 그래서 피크점 power도 pks2에 값으로.
             else pks2 = pks(1);
                 [a,b] = ind2sub(size(M),find(M==pks2));
             end

             IT = (b-1)*0.002-0.400;       % time point 말고 msecond 로 보고함. sampling rate 500Hz = 0.002sec
             
             FILENAME = ['DTF_' char(dataname{datanumb}) '_' char(trialname{trialnumb}) '_' char(subname{subnumb}) '_' char(selchanname{selchannum})];
             TEST{i,1} = FILENAME;
             TEST{i,2} = IF;
             TEST{i,3} = IT;
             TEST{i,4} = pks2;
             i=i+1;
            end     
        end
    end
end

xlswrite('Dominant_Freq_Time.xls', TEST);
