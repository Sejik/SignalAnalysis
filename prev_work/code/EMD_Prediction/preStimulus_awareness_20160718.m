%% BIOMAG 2016 conference
% Does pre-stimulus brain activity predict conscious awareness?
% designed by Sejik Park (Korea University Undergraduated)
% e-mail: sejik6307@gmail.com

% Submission info
% Included:
    % SejikPark_BIOMAG2016.pptx (method & result)
    % SejikPark_BIOMAG2016.m (commented)
% Submission deadline: 31st August
% Organizers (listed alphabetically):
    % Mike X Cohen: mikexcohen@gmail.com
    % Karim Jerbi: karim.jerbi@umontreal.ca 
    % Matias Palva: matias.palva@helsinki.fi

% Conference info: http://mikexcohen.com/biomag_data_competition.html
% find pre-stimulus info (predict behavioral, upcoming stimuli): posterior alhpa oscillation
% MEG study: somatosensory stimulation -> source reconstructed level (9 datasets: each 30 minutes)
% quantitative: variance (R2), perceptual accuracy (hits + correction rejection vs. false alarms + misses)
% qualitative: novel, creative (neurophysiologically interpretation)

% Data info
% column 1: trial type (1=hit, 0=miss) 
% column 2: left-hand (1) or right-hand (2) stimulation 
% column 3: reaction time in seconds-after-stimulation onset (hist only) 
% column 4: trial onset time. You need this to create epochs

% contents
% 0. load data
% 1. preprocessing
    % baseline correction -> artifact rejection by ICA & PCA
% 2. main
    % channel selection (4 centers) -> individual average FFT (5 center
    % frequency) -> EMD -> CFC & DTF -> t-SNE
% 3. save result
    % variance (R2), perceptual accuracy
    % (hits + correction rejection vs. false alarms + misses)

%% Before process
clear; clc;

%% Parameters
rawDir = 'C:\Users\win\Desktop\Research\3. Analyze\Data\BIOMAG\MEG';
stimulusBeforeEpochLength = 500;
stimulusAfterEpochLength = 500;

%% 0. load data
cd(rawDir);
meg_files = dir('*.mat');

for megFileNum = 1:length(meg_files)
    load(meg_files(megFileNum).name);
    megData(megFileNum).dataim = dataim;
    megData(megFileNum).datare = datare;
    megData(megFileNum).timevec = timevec;
    megData(megFileNum).trialinfo = trialinfo;
    epochs = zeros(length(trialinfo),stimulusBeforeEpochLength + stimulusAfterEpochLength + 1,400);
    for triali=1:length(trialinfo)
        onset = dsearchn(timevec,trialinfo(triali,4));
        if onset-stimulusBeforeEpochLength > 0 && onset+stimulusAfterEpochLength < length(datare)
            epochs(triali,:,:) = datare(onset-stimulusBeforeEpochLength:onset+stimulusAfterEpochLength,:);
        end        
    end
     megData(megFileNum).epochs = epochs;
end
clearvars -except megData stimulusBeforeEpochLength stimulusAfterEpochLength

%% 1. Preprocessing
% baseline correction
for megFileNum = 1:length(megData)
    meanData = mean(megData(megFileNum).epochs(:,1:stimulusBeforeEpochLength,:),2);
    baseLineCorrectedData = megData(megFileNum).epochs - repmat(meanData,1,size(megData(megFileNum).epochs,2));
    megData(megFileNum).epochs = baseLineCorrectedData;
end
clearvars -except megData stimulusBeforeEpochLength stimulusAfterEpochLength
    
% artifact rejection by EMD & pearson correlation
megData(1).epochs;

%% 2. main
% before: -500ms-1ms & % after: 1ms-500ms
% ICA -> DTF&CFC -> tSNE
    

%% 3. save result
% average
% variance (R2), perceptual accuracy (hits + correction rejection vs. false alarms + misses)


% visualization
% load visualization.mat
% imagesc(brainimg), hold on
% scatter(locs(:,1),locs(:,2),120,squeeze(mean(epochs(:,600,:),1)),'filled')
% 
% plot3DPatch(1:400,1,400,400,0,0)

%% functions
% EMD
%% EMD
% designed by Sejik Park (Korea University Undergraduated)
% e-mail: sejik6307@gmail.com

% Empirical Mode Decomposition
% paper: Rato, R. T., Ortigueira, M. D., & Batista, A. G. (2008). On the
% HHT, its problems, and some solutions. Mechanical Systems and Signa
% Processing, 22(6), 1374-1394.

%   emdResult = EMD(raw, resolution, residualEnergy, gradientStepSize);
%       Input
%       raw: raw data (meg data)
%       resolution: 10*log(WSignal/Bias energy)
%       residualEnergy: 10*log(WSignal/WqResidual)
%       gradientStepSize
%       Output
%       emdResult: IMF matrix (+ residual line)


function emdResult = EMD (raw, resolution, residualEnergy, gradientStepSize)

if nargin < 4, gradientStepSize = 1; end
if nargin < 3, residualEnergy = 50; end
if nargin < 2, resolution = 50; end

% basic parameter
signal = raw(:);
signalEnergy= signal'*signal;
signalLength = length(signal);

% count Ocillation
oscillationNum= countOscillation(signal);

% signal to IMFs
emdResult= [];
rParabEmdCnt= 0;
qDbResid= 0;                 %Equal energies at start
while ((qDbResid<residualEnergy) && (oscillationNum>2) )   % c has some energy and oscilates
    kImf = signal; % at the beginning of the sifting process, kImf is the signal
    rPMOri= rGetPMaxs_s(kImf);     % rPM= [xM(M), yM(M)];
    rPmOri= rGetPMins_s(kImf);     % rPm= [xm(m), ym(m)];
    rPM= rPMaxExtrapol_s(rPMOri, rPmOri, signalLength);
    rPm= rPMinExtrapol_s(rPMOri, rPmOri, signalLength);
    quntLM= length(rPM);   quntLm= length(rPm);
    %    if (abs(quntLM-quntLm)>2), disp('Debug: Max-Min count mismatch.'),keyboard,end;
    if (abs(quntLM-quntLm)>2), disp('Debug: Max-Min count mismatch.'),end;
    if(sum(abs(diff(sign(rPM(1:min(quntLM,quntLm),1)- rPm(1:min(quntLM,quntLm),1)))))>0)
        %        disp('Debug: Max-Min sequence mismatch.'),keyboard;
        disp('Debug: Max-Min sequence mismatch.');
    end
    if(sum(abs(diff(sign(rPm(1:min(quntLM,quntLm),1)- rPM(1:min(quntLM,quntLm),1)))))>0)
        %        disp('Debug: Max-Min reverse sequence mismatch.'),keyboard;
        disp('Debug: Max-Min reverse sequence mismatch.');
    end
    bTenv= spline(rPM(:,1), rPM(:,2), 1:signalLength);          %  Top envelop: bTenv[n];
    bDenv= spline(rPm(:,1), rPm(:,2), 1:signalLength);          % Down envelop: bDenv[n];
    bBias= (bTenv+bDenv)/2;               %  first bias estimate
    while true(1)             % inner loop to find each IMF
        WImf= kImf'*kImf;                %current IMF  energy
        WBias= bBias*bBias';                  %bias energy
        if WBias*WImf<0 , warning('rParabEmd__L: Ooops, negative energy detected.'), end
        if WBias> 0, DbqResol= 10*log10(WImf/WBias); else DbqResol= Inf; end
        if (DbqResol>resolution),  break, end %Resolution reached
        %Resolution not reached. More work is needed
        kImf = kImf- gradientStepSize*bBias';                % subtract qAlfa bias from kImf
        rPMOri= rGetPMaxs_s(kImf);     % rPM= [xM(M), yM(M)];
        rPmOri= rGetPMins_s(kImf);     % rPm= [xm(m), ym(m)];
        rPM= rPMaxExtrapol_s(rPMOri, rPmOri, signalLength);
        rPm= rPMinExtrapol_s(rPMOri, rPmOri, signalLength);
        bTenv= spline(rPM(:,1), rPM(:,2), 1:signalLength);          % Top envelop: bTenv[n];
        bDenv= spline(rPm(:,1), rPm(:,2), 1:signalLength);          % Down envelop: bDenv[n];
        bBias= (bTenv+bDenv)/2;               %  new bias estimate
    end % Wend true
    %
    emdResult = [emdResult; kImf'];          % store the extracted rParabEmd in the matrix rParabEmd
    signal = signal - kImf;             % subtract the extracted rParabEmd from the signal
    oscillationNum= countOscillation(signal);
    
    rParabEmdCnt=rParabEmdCnt+1;
    if (signal'*signal)>0
        qDbResid= 10*log10(signalEnergy/(signal'*signal));
    else
        qDbResid = Inf
    end
    %
end % Wend ((DbR... ))
if ((signal'*signal)/signalEnergy)>(10^-12)
    emdResult=[emdResult; signal'];        %The residual is the last IMF
    rParabEmdCnt=rParabEmdCnt+1;
    NumOscqResiduais= countOscillation(signal);
end
emdResult= emdResult';

end %main function

function oscillationNum= countOscillation(signal)
diffSignal = diff(signal);
diffSignal(diffSignal<0) = -1;
diffSignal(diffSignal>=0) = 1;
oscillation = diff(diffSignal);
oscillation(oscillation ~= 2 || oscillation ~= -2) = 0;
oscillationNum = sum(oscillation,2);
end

%---------- make at 17-Jul-07 10:16:59.44
function rPMaxExtrapol= rPMaxExtrapol_s(rPM, rPm, quntL)
%rPMaxExtrapol_s                                             V1.00
%                                               build 2007407001
% Time-mirrored top extrema (Parabolic Maxs) extrapolation

%Init ------------------------------------
rPM= sortrows(rPM); %assumes nothing on rPM sort order
rPm= sortrows(rPm); %assumes nothing on rPm sort order

kTopTim1= rPM(:,1); kTopVal= rPM(:,2);
kDwnTim1= rPm(:,1); kDwnVal= rPm(:,2);

%Start extrapolation ---------------------
if ( (kTopTim1(1)== 1) && (kDwnTim1(1)== 1) )
    disp ('rPMaxExtrapol_s: Poliextrema at signal''s start');
elseif ( (kTopTim1(1)<1) || (kDwnTim1(1)< 1) )
    disp ('rPMaxExtrapol_s: Invalid extrema at signal''s start');
else
    kTopTim1=[2-kDwnTim1(1); kTopTim1];     % New first Top at the (one based) specular Min
    kTopVal=[kTopVal(1); kTopVal];          % Same Val as old first Top
end

% End extrapolation -----------------------
if ( (kTopTim1(end)== quntL) && (kDwnTim1(end)== quntL) )
    disp ('rPMaxExtrapol_s: Poliextrema at signal''s end');
elseif ( (kTopTim1(end)> quntL) || (kDwnTim1(end)> quntL) )
    disp ('rPMaxExtrapol_s: Invalid extrema at signal''s end');
else
    kTopTim1=[kTopTim1; (2*quntL - kDwnTim1(end))];     % New last Top at the specular Min
    kTopVal=[ kTopVal; kTopVal(end)];          % Same Val as old last Top
end

% return value ------------------------
rPMaxExtrapol= sortrows([kTopTim1, kTopVal]);

end
%-------------------------------------------------------------------------
%---------- make at 17-Jul-07 10:16:59.44
function rPMinExtrapol= rPMinExtrapol_s(rPM, rPm, quntL)
%rPMinExtrapol_s                                           V1.00
%                                               build 2007407001
% Time-mirrored down extrema (Parabolic Mins) extrapolation

%Init ------------------------------------
rPM= sortrows(rPM); %assumes nothing on rPM sort order
rPm= sortrows(rPm); %assumes nothing on rPm sort order

kTopTim1= rPM(:,1); kTopVal= rPM(:,2);
kDwnTim1= rPm(:,1); kDwnVal= rPm(:,2);

%Start extrapolation ---------------------
if ( (kTopTim1(1)== 1) && (kDwnTim1(1)== 1) )
    disp ('rPMinExtrapol_s: Poliextrema at signal''s start');
elseif ( (kTopTim1(1)<1) || (kDwnTim1(1)< 1) )
    disp ('rPMinExtrapol_s: Invalid extrema at signal''s start');
else
    kDwnTim1=[2-kTopTim1(1); kDwnTim1];     % New first Dwn at the (one based) specular Max
    kDwnVal=[kDwnVal(1); kDwnVal];          % Same Val as old first Dwn
end

% End extrapolation -----------------------
if ( (kTopTim1(end)== quntL) && (kDwnTim1(end)== quntL) )
    disp ('rPMinExtrapol_s: Poliextrema at signal''s end');
elseif ( (kTopTim1(end)> quntL) || (kDwnTim1(end)> quntL) )
    disp ('rPMinExtrapol_s: Invalid extrema at signal''s end');
else
    kDwnTim1=[kDwnTim1; (2*quntL - kTopTim1(end))];     % New last Dwn at the specular Max
    kDwnVal=[ kDwnVal; kDwnVal(end)];          % Same Val as old last Dwn
end

% return value ------------------------
rPMinExtrapol= sortrows([kDwnTim1, kDwnVal]);

end
%-------------------------------------------------------------------------
%---------- make at 17-Jul-07 10:16:59.44
function rPMax= rGetPMaxs_s(raw)         %Get Parabolic Maxs, plateaus out
signal = raw(:);
diffSignal = diff(signal);
diffSignal(diffSignal<0) = -1;
diffSignal(diffSignal>=0) = 1;
oscillation = diff(diffSignal);
oscillation(oscillation ~= 2 || oscillation ~= -2) = 0;
oscillationNum = sum(oscillation,2);




quntLenS=length(signal);
quntMaxCnt=0;
kSMNdx1= []; kSMVal=[];         %signal S Maxima indices and values
kSPMTim1= []; kSPMVal=[];       %signal S Parabolic Maxima times and values


if (quntLenS>2)     %if signal has enough length
    for Cnt=2:(quntLenS-1)  %search the Maxs
        if ( ((signal(Cnt) > signal(Cnt+1))) && ((signal(Cnt) >= signal(Cnt-1))) || ((signal(Cnt) >= signal(Cnt+1))) && ((signal(Cnt) > signal(Cnt-1))) )
            quntMaxCnt=quntMaxCnt+1;
            kSMNdx1= [kSMNdx1; Cnt];  kSMVal=[kSMVal; signal(Cnt)];
        end
    end
end

% Now we have the Maxs, lets get the Parabolic Maxs
oldxv= -Inf; oldyv= -Inf;
intGapMax= max(signal)-min(signal);
for jj=1:quntMaxCnt     %for all Maxs
    %xa= -1; xb= 0; xc= 1;
    ya= signal(kSMNdx1(jj)-1);  % Sample point before
    yb= signal(kSMNdx1(jj));    % Sample point, == kSMVal(jj)
    yc= signal(kSMNdx1(jj)+1);  % Sample point after
    D= (-4*yb+2*ya+2*yc);
    if (D==0), xv= kSMNdx1(jj);
    else xv= kSMNdx1(jj)+(ya-yc)/D; end; % Vertix abscissa
    D= (-16*yb+ 8*ya+ 8*yc);
    if (D==0), yv= yb;
    else yv= yb+ (2*yc*ya- ya*ya- yc*yc)/D; end;
    % Lets check for double maxima
    if ( (xv==oldxv)||(abs(yv-oldyv)/abs(xv-oldxv))> (2*intGapMax) )
        xv= (xv+ oldxv)/2; yv= max(yv,oldyv);   %Double found
        kSPMTim1(length(kSPMTim1))= xv; kSPMVal(length(kSPMVal))= yv;
    else
        kSPMTim1= [kSPMTim1; xv];  kSPMVal=[kSPMVal; yv];
    end
    oldxv= xv; oldyv= yv;
end % for jj=1:quntMaxCnt

if quntMaxCnt>0
    if ( signal(1) >= kSPMVal(1) )
        kSPMTim1= [1; kSPMTim1];  kSPMVal=[signal(1); kSPMVal ];    %Start must be included as a Max
    end
    if ( signal(end) >= kSPMVal(end))
        kSPMTim1= [kSPMTim1; quntLenS];  kSPMVal=[kSPMVal; signal(end)];   %End must be included as a Max
    end
end

if quntMaxCnt==0
    if ( signal(1) > signal(2) )
        kSPMTim1= [1; kSPMTim1];  kSPMVal=[signal(1); kSPMVal ];    %Start must be included as a Max
    end
    if ( signal(end) > signal(end-1))
        kSPMTim1= [kSPMTim1; quntLenS];  kSPMVal=[kSPMVal; signal(end)];   %End must be included as a Max
    end
end
if quntMaxCnt<0
    error('rGetPMaxs_s: Invalid MaxCnt value');
end


rPMax= sortrows([kSPMTim1, kSPMVal]);
end
%---------- make at 17-Jul-07 10:16:59.44
function rPMin= rGetPMins_s(aS)         %Get Parabolic Mins, plateaus out
%                                       build 20070612001
kS= aS(:);
quntLenS=length(kS);
quntMinCnt=0;
kSMNdx1= []; kSMVal=[];         %signal S Minima indices and values
kSPMTim1= []; kSPMVal=[];       %signal S Parabolic Minima times and values

if (quntLenS>2)     %if signal has enough length
    for Cnt=2:(quntLenS-1)  %search the Mins
        if ( ((kS(Cnt) < kS(Cnt+1))) && ((kS(Cnt) <= kS(Cnt-1))) || ((kS(Cnt) <= kS(Cnt+1))) && ((kS(Cnt) < kS(Cnt-1))) )
            quntMinCnt=quntMinCnt+1;
            kSMNdx1= [kSMNdx1; Cnt];  kSMVal=[kSMVal; kS(Cnt)];
        end
    end
end

% Now we have the Mins, lets get the Parabolic Mins
oldxv= -Inf; oldyv= -Inf;
intGapMax= max(kS)-min(kS);
for jj=1:quntMinCnt     %for all Mins
    %xa= -1; xb= 0; xc= 1;
    ya= kS(kSMNdx1(jj)-1);  % Sample point before
    yb= kS(kSMNdx1(jj));    % Sample point, == kSMVal(jj)
    yc= kS(kSMNdx1(jj)+1);  % Sample point after
    D= (-4*yb+2*ya+2*yc);
    if (D==0), xv= kSMNdx1(jj);
    else xv= kSMNdx1(jj)+(ya-yc)/D; end; % Vertix abscissa
    D= (-16*yb+ 8*ya+ 8*yc);
    if (D==0), yv= yb;
    else yv= yb+ (2*yc*ya- ya*ya- yc*yc)/D; end;
    % Lets check for double minima
    if ( (xv==oldxv)||(abs(yv-oldyv)/abs(xv-oldxv))> (2*intGapMax) )
        xv= (xv+ oldxv)/2; yv= min(yv,oldyv);   %Double found
        kSPMTim1(length(kSPMTim1))= xv; kSPMVal(length(kSPMVal))= yv;
    else
        kSPMTim1= [kSPMTim1; xv];  kSPMVal=[kSPMVal; yv];
    end
    oldxv= xv; oldyv= yv;
end % for jj=1:quntMinCnt

if quntMinCnt>0
    if ( kS(1) <= kSPMVal(1) )
        kSPMTim1= [1; kSPMTim1];  kSPMVal=[kS(1); kSPMVal ];    %Start must be included as a Min
    end
    if ( kS(end) <= kSPMVal(end))
        kSPMTim1= [kSPMTim1; quntLenS];  kSPMVal=[kSPMVal; kS(end)];   %End must be included as a Min
    end
end

if quntMinCnt==0
    if ( kS(1) < kS(2) )
        kSPMTim1= [1; kSPMTim1];  kSPMVal=[kS(1); kSPMVal];    %Start must be included as a Min
    end
    if ( kS(end) < kS(end-1))
        kSPMTim1= [kSPMTim1; quntLenS];  kSPMVal=[kSPMVal; kS(end)];   %End must be included as a Min
    end
end
if quntMinCnt<0
    error('rGetPMins_s: Invalid MinCnt value');
end


rPMin= sortrows([kSPMTim1, kSPMVal]);
end