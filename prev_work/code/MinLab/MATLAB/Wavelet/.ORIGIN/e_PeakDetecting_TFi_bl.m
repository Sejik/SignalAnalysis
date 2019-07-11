%% PeakDetecting.m %%
% 최종 결과값인 Peak의 Amplitude와 Latency를 찾는 코드입니다. 
% Header에서 Timewindow, 관심있는 채널만 지정해주면 SPSS에 넣기 직전의 테이블 형태로 데이터가 저장됩니다.

%% 코드 시작하기 전 메모리를 비우고 매트랩에 켜져있는 팝업창들을 닫는 과정
clear;
close all

%% Header %%
% 실험 하나에 쓰이는 모든 코드에 동일하게 복사/붙이기 해놓는 것이 편합니다.
%
% channame: 1번 부터 32번 까지 각각 번호에 맞게 채널이름 지정. 분석에 직접적으로 필요하지는 않지만 사용하는 데이터가
% 어느 채널에서 왔는지 확인하거나 디스플레이할 때 쓰면 됩니다.
%
% dataname, trialname: 실험 패러다임에 따라 알맞게 유동적으로 바꿔주면 됩니다.
%
% subname: 피험자 리스트. Outlier가 생길 경우 이 리스트에서도 빼주면 됩니다.

channame={'Fp1','Fp2','F7','F3','Fz','F4','F8','FC5','FC1','FC2','FC6','T7','C3','Cz','C4','T8','EOG','CP5','CP1','CP2','CP6','NULL','P7','P3','Pz','P4','P8','PO9','O1','Oz','O2','PO10'};
dataname={'like', 'dislike'};
trialname={'Fav_USA', 'Neutral_Mexico', 'Unfav_paki'};
subname={'su02', 'su04', 'su07', 'su08', 'su09', 'su10', 'su12', 'su14', 'su16', 'su18', 'su19', 'su20', 'su21', 'su22', 'su25', 'su26', 'su27' , 'su28' , 'su29'};

% 아래 부분에서 필요한 부분을 수정하시면 됩니다.
% 여기서 주의하실 점이 있다면, 저같은 경우 주파수 데이터 종류 당 PeakDetecting 코드를 하나씩 만들어줍니다.
% 즉, PeakDetecting_TFi.m, PeakDetecing_TFebl.m 이런 식으로...
% 그 까닭은 TFe_bl alpha 대역에서의 분석 채널과 TFi alpha 대역에서의 분석 채널 등등이 달라질 수 있고,
% 데이터 종류 하나에 대해서 여러개의 Timewindow 나 분석 채널을 이용할 수도 있기 때문입니다.
% 저 같은 경우 헷갈리지 않게 하기 위해 따로 만드는 방법을 선호하고 추천하지만, 코드 하나에 다 표현하셔도 무방합니다.
% 이 코드의 경우는 TFe_bl 의 PeakDetecting 코드로 가정하겠습니다.
%
% 또, 제가 아직 이 실험에 대해 실제 분석을 한 것이 아니기 때문에, 아래의 분석 Timewindow 나 채널들은 제가 임의로 지정한
% 것입니다. 예시로서만 확인하시고, 실제 분석 시에는 수정하시기 바랍니다.

%% 분석 내용 %%
% 2015.3.2
% 
% TFe_bl_alpha 0-500ms     maximum      P3, P4, P7, P8
% TFe_bl_beta 0-500ms     maximum      Pz, P3, P4
% TFe_bl_theta 0-500ms    maximum      P3, P4, P7, P8  

% TFi_alpha -400-100ms   maximum     P3, P4, P7, P8, O1, O2
% TFi_alpha -400-100ms  mean     P3, P4, P7, P8, O1, O2

% TFi_bl_beta   0~1000ms    min     P3, P4, P7, P8, O1, O2

freqname={'beta2'};

% 위의 freqname에 있는 주파수 대역 명에 알맞는 주파수 대역을 지정해주셔야 합니다.
alpha1=8:1/2:13;
%alpha2=8:1/2:13;
beta1=13:1/2:30;
beta2=13:1/2:30;
theta=4:1/2:8;

ananame={'TFe_bl','TFi', 'TFi_bl'};

% 현재 이 코드에서는 주파수 대역이 분석을 하는 가장 큰 틀입니다.(alpha1, alpha2, beta1, ...) -> 실험 및 코드에 따라 달라질 수 있으니 이 Header부분은 유동적으로 쓰셔야 합니다.
% 주파수 대역에 따라 Timewindow가 달라지는 것이라 볼 수 있으니, 각각에 따른 Timewindow, 총 5개 지정해줍니다.
timelist=cell(1,1);
%timelist{1,1}=[251:501];    % alpha1의 Timewindow. 0ms ~ 500ms
%timelist{2,1}=[51:201];     % alpha2의 Timewindow. -400ms ~ -100ms
%timelist{2,1}=[251:501];    % beta1의 Timewindow. 0ms ~ 500ms
timelist{1,1}=[251:751];    % beta2의 Timewindow. 0ms ~ 1000ms
%timelist{3,1}=[251:501];    % theta의 Timewindow. 0ms ~ 500ms

% 마찬가지로 주파수 대역에 따라 관심 채널이 달라지는 것이라 볼 수 있으니, 각각에 따른 채널 목록, 총 5개 지정해줍니다.
% 분석은 지정된 채널들의 Amplitude 및 Latency 값을 각각 추출하여 평균을 내는 방법으로 진행됩니다.
chanlist=cell(1,1);
%chanlist{1,1}=[23,24,26,27]; 
%chanlist{2,1}=[23,24,26,27,29,31]; 
%chanlist{2,1}=[24, 25, 26]; 
chanlist{1,1}=[23,24,26,27,29,31];
%chanlist{3,1}=[23,24,26,27]; 

% 이 코드는 TFe_bl 에 대한 분석만 진행하므로, ananame에 대해서는 for문을 돌리지 않고 ananumb=1 로
% 지정합니다. 그 외의 TFi 나 TFi_bl을 위한 코드에서도 ananumb을 그에 알맞게 2 나 3으로 지정하시면 됩니다.
ananumb=3;

%% 실제 분석 코드
for freqnumb=1:length(freqname)
    % 관심 채널과 timewindow가 주파수 대역에 따라 바뀌게 되므로 chanlist와 timelist 안의 integer가
    % freqnumb 입니다.
    chancan=chanlist{freqnumb,1};
    timewindow=timelist{freqnumb,1};
    eval(['freqband=' char(freqname{freqnumb}) ';']);
    freqindex=2*freqband-1;
    
    % Header의 분석 내용을 다시 확인해 보시면, 주파수 대역별로 timewindow나 관심 채널 뿐만이 아니라
    % maximum, minimum 이 써져 있는 것을 확인할 수 있습니다.
    % 이는 Positive Peak를 찾는 것인지 Negative Peak를 찾는 것인지를 나타내며, 아래 코드에서 분석시
    % max함수를 이용할지, min함수를 이용할지 calcname에 지정해 줍니다.
    % 이번의 경우 theta(freqnumb=5)일 때만 min 을 이용하고 나머지 경우는 모두 max를 이용하므로, 아래와 같이
    % 코드를 작성합니다. 역시 이 부분도 유동적으로 사용하시면 됩니다.
    if freqnumb==5
        calcname='min';
    else
        calcname='min';
    end
    %%% 여기 까지가 실제로 Header. 실험 및 분석에 따라 여기까지 수정해 주시면 됩니다.
    %%% 아래로 이어지는 부분도 약간의 수정은 필요하겠지만 주로 load 나 save 등의 부분이며 실제 분석이 진행되는 코드가
    %%% 대부분입니다.
        
    
    for trialnumb= 1:length(trialname)
        for datanumb= 1:length(dataname)
            for subnumb= 1:length(subname)
                % 데이터 로드
                eval(['load(''Result_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '_' char(subname{subnumb}) '.mat'');']);
                
                
                %% Finding Maximum Frequency(Individual Frequency)
                % 지금 분석하려는 데이터 타입(TFe, TFi, TFi_bl 중 하나)를
                % Potential_Buf로 지정.
                % 이 때 관심있는 주파수 영역, timewindow, 채널 목록에 한정합니다.
                eval(['Potential_Buf=' char(ananame{ananumb}) '(freqindex,timewindow,chancan);']);
                
                % SaveFrequency에서 Individual Frequency를 찾는 방법과 동일 하나, Max과
                % 될 수도 있고 Min 이 될 수도 있으므로 eval함수와 calcname이 사용됩니다.
                eval(['buf= ' calcname '(Potential_Buf, [], 3);']);
                eval(['bufbuf= ' calcname '(buf, [], 2);']);
                eval(['[bufbufbuf1 bufbufbuf2]= ' calcname '(bufbuf);']);

                % Individual Frequency 저장.
                % freq는 실제 주파수 값, freq_index는 행 값.
                % 그러므로 실제로 코드에서 이용하는 값은 freq_index 값입니다.
                freq=freqband(bufbufbuf2);
                freq_index=freqindex(bufbufbuf2);
                
                
                %% Select Data by Individual Frequency and Channels of Interest
                % Individual Frequency 와 관심 채널에 따른 데이터를 추출하여 potential_topo 에 저장.
                eval(['potential_topo=double(squeeze(' char(ananame{ananumb}) '(freq_index,:,chancan)));']);
                
                
                %% Find Peak and Save
                % calcname에 따라 Positive 혹은 Negative Peak를 찾습니다.
                % 아래 코드는 calname이 max 일 때 실제로는 다음과 같습니다.
                % [peakBuf_list_max peak_list_time]= max(potential_topo(timewindow,:),[],1);
                eval(['[peakBuf_list_max peak_list_time]= ' calcname '(potential_topo(timewindow,:),[],1);']);

                % 추출된 각 채널들의 값을 평균냅니다.
                peak_mean= mean(peakBuf_list_max);
                peak_time= mean(peak_list_time);
                peak_time= peak_time + timewindow(1) -1;    % 저장된 peak_time은 우리가 설정한 timewindow를 기준으로 몇 번째 데이터 포인트인지 저장된 것이므로, 전체 데이터를 기준으로는 몇 번째 데이터 포인트인지 다시 지정합니다.
                                                            % 여기서 주의하실 점은,최종적으로 저장되는 Latency 값이 데이터 포인트 라는 것, 즉 단위가 시간(ms)이 아니기 때문에, SPSS에 넣기 전에 계산을 다시 해주거나, 시간으로 변환해주는 코드를 넣으셔야 합니다.
                                                            % ex) peak_time_ms = peak_time*2 - 502;
                
                Peak_list(subnumb,1)= peak_mean;
                Peak_list(subnumb,2)= peak_time;
                % Peak_list(subnumb,3)= peak_time_ms;   % 시간(ms)단위로 변환한 Latency 결과값.
                
                clear ERP_filt_bl TFe_bl TFi MaxTime MaxValue Max_All Max_Chan Max_Peak list1 list2 peakBuf_list peakBuf_list_max peak_mean peak_time Potential_Buf potential_topo
                close all
                
            end
            % 조건별 피험자 개개인의 데이터를 저장합니다.
            % 참고용으로, 최종적으로 사용하는 테이블은 아닙니다.
            eval(['FILENAME=''skk_PlotPeak_' char(ananame{ananumb}) '_MinimumPeakAveraged_' char(freqname{freqnumb}) '_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) ''';']);
            cd Peak;
            save(FILENAME, 'Peak_list');
            cd ..;
            clear Peak_list
            
        end
    end
end


 %% SPSS 테이블 생성
 % 최종 결과 데이터 테이블을 생성하는 부분입니다.
 % 여기서 나오는 결과를 SPSS 돌리거나, 교수님께 excel로 보내드리면 됩니다.
for freqnumb=1:length(freqname)
    i=1;
    for trialnumb=1:length(trialname)
        for datanumb=1:length(dataname)
            
            cd Peak;
            eval(['load(''skk_PlotPeak_' char(ananame{ananumb}) '_MinimumPeakAveraged_' char(freqname{freqnumb}) '_' char(trialname{trialnumb}) '_' char(dataname{datanumb}) '.mat'');']);
            cd ..;
            Peak_Total(:,i)=Peak_list(:,1);
            Time_Total(:,i)=Peak_list(:,2);
            % 위의 Time_Total은 타임포인트 의 결과값입니다. 시간(ms)단위로 저장하시려면 152행의 Peak_list(subnumb,3) 부분을 활성화한 후, 윗줄(179행)은 코멘트 처리하시고, 아랫줄(180행)을 추가 하시면 됩니다.
            % Time_Total(:,i)=Peak_list(:,3);
            i=i+1;
        end
    end
    
    % Time_Total은 Datapoint, TimeReal_Total은 실제 Latency값 입니다.
    % Sampling Rate나 Start Point에 따라 연산은 수정하셔야 합니다.
    TimeReal_Total=Time_Total*2-502;
    
    % 최종 결과 저장
    % 데이터명은 TotalPeak로 시작합니다.
    eval(['FILENAME=''skk_TotalPeak_' char(ananame{ananumb}) '_MinimumPeakAveraged_' char(freqname{freqnumb}) ''';']);
    cd Peak_total
    save(FILENAME, 'Peak_Total', 'Time_Total', 'TimeReal_Total');
    cd ..;
    clear Peak_Total Time_Total TimeReal_Total
end