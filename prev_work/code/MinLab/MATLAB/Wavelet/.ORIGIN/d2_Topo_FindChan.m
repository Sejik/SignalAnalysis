%% Topo_FindChan.m %%
% 부가적인 코드 입니다.
% Analyzer를 이용하지 않고 바로 최대 Peak값을 갖는 토포를 그려보고자 하실 때 이용하시면 됩니다.
% 이 코드를 참고하여 토포를 그리는 방법을 공부해보셔도 됩니다. 분석에 직접적으로 쓰이는 코드는 아닙니다.


clear;
close all
%% Header

channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'like', 'dislike'};
trialname={'Fav_USA', 'Neutral_Mexico', 'Unfav_paki'};
subname={'su01', 'su02', 'su03', 'su04', 'su06', 'su07', 'su08', 'su09', 'su10', 'su11', 'su12', 'su13', 'su14', 'su15', 'su16', 'su17', 'su18', 'su19', };

freqname={'alpha', 'beta', 'theta'};

alpha=8:1/2:13;
beta=13:1/2:30;
theta=4:1/2:8;

chanlist=[1:16, 18:21, 23:32];

ananame={'TFi_bl'};

timelist=cell(3,1);
timelist{1,1}=[251:501];
timelist{2,1}=[51:201];
timelist{3,1}=[51:201];


for ananumb=1:length(ananame)
    
    timewindow=timelist{ananumb,1};
    
    for datanumb=1:length(dataname)
        for trialnumb=1:length(trialname)
            
            for freqnumb=1:length(freqname)
                eval(['freqband=' char(freqname{freqnumb}) ';']);
                freqindex=2*freqband-1;
                

                eval(['DataBuf = importdata(''Phase_' char(ananame{ananumb}) '_' char(freqname{freqnumb}) '_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.dat'');']);

                Potential_Buf=DataBuf(timewindow,:);
                [buf1 buf2]=max(Potential_Buf);
                [bufbuf1 bufbuf2]=max(buf1);
                
                MaxValue=bufbuf1;
                MaxTpoint= buf2(bufbuf2) + timewindow(1) -1 ;
                
                potential_topo=DataBuf(MaxTpoint, :);
                potential_topo(:,[17 22])=NaN;
                
                MaxMaxChan= bufbuf2;
                
                % TopoPlot
                figure;
                [h,z]=topoplot(double(potential_topo),'EEG_32chan.ced', 'style', 'map', 'electrodes', 'numbers');
                eval(['title(sprintf(''' char(ananame{ananumb}) ' ' char(trialname{trialnumb}) ' ' char(dataname{datanumb}) ' Frequency: %d ~ %d Hz\n Max Ch: %d (%d ms)'', freqband(1), freqband(end), MaxMaxChan, MaxTpoint*2 - 501));']);
                
                % caxis([-MaxMax, MaxMax]);
                colorbar;
                
                eval(['fname=''topo_SKK_GrandAveraged_' char(ananame{ananumb}) '_' char(freqname{freqnumb}) '_' char(trialname{trialnumb}) '_' char(dataname{datanumb})  '.jpg'';']);
                print('-djpeg', fname);
                %close all;
            end
        end
    end
end
                        