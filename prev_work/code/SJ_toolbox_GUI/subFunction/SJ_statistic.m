function [statisticResult] = SJ_statistic(param, result)
if isfield(result, 'erp')
    for channelNum = 1:size(result.erp, 2)
        for latencyNum = 1:size(result.erp, 3)
            statisticResult.erp(:,:,channelNum, latencyNum) = ...
                SJ_statisticLoop(result, squeeze(result.erp(:,channelNum, latencyNum)));
        end
    end
end

if isfield(result, 'fftIndividualFreq')
    for channelNum = 1:size(result.fftIndividualFreq, 2)
        for latencyNum = 1:size(result.fftIndividualFreq, 3)
            for freqNum = 1:size(result.fftIndividualFreq, 4)
                statisticResult.fftIndividualFreq(:,:,channelNum, latencyNum, freqNum) = ...
                    SJ_statisticLoop(result, squeeze(result.fftIndividualFreq(:,channelNum, latencyNum, freqNum)));
            end
        end
    end
end

% if isfield(result, 'wavelet')
%     for latencyNum = 1:floor(size(result.wavelet, 3) / param.fs)
%         temp.latencyAverageWavelet(:, :, latencyNum, :) = mean(result.wavelet(:, :, (param.fs*(latencyNum-1)+1):(param.fs*latencyNum), :),3);
%     end
%     temp.latencyAveragedWavelet = result.wavelet; % 51(fileNum) * 34(channel) * 1741(latency) * 99(frequency)
%     for channelNum = 1:size(result.wavelet, 2)
%         for latencyNum = 1:floor(size(result.wavelet,3) / param.fs)
%             for freqNum = 1:size(result.wavelet, 4)
%                 statisticResult.latencyAverageWavelet(:,:,:,:,:) = SJ_statisticLoop(result, squeeze(temp.latencyAverageWavelet(:,channelNum, latencyNum, freqNum)));
%             end
%         end
%     end
% end

if isfield(result, 'waveletIndividualLatency')
    for channelNum = 1:size(result.waveletIndividualLatency, 2)
        for latencyNum = 1:size(result.waveletIndividualLatency, 3)
            for freqNum = 1:size(result.waveletIndividualLatency, 4)
                statisticResult.waveletIndividualLatency(:,:,channelNum, latencyNum, freqNum) = ...
                    SJ_statisticLoop(result, squeeze(result.waveletIndividualLatency(:,channelNum, latencyNum, freqNum)));
            end
        end
    end
end

if isfield(result, 'dipoleDistance')
    for latencyNum = 1:size(result.dipoleDistance, 2)
        statisticResult.dipoleDistance(:,:,latencyNum) = ...
            SJ_statisticLoop(result, squeeze(result.dipoleDistance(:,latencyNum)));
    end
end

if isfield(result, 'individualCFC')
    for channelNum = 1:size(result.individualCFC, 2)
        for latencyNum = 1:size(result.individualCFC, 3)
            statisticResult.individualCFC(:,:,channelNum, latencyNum) = ...
                SJ_statisticLoop(result, squeeze(result.individualCFC(:,channelNum, latencyNum)));
        end
    end
end

if isfield(result, 'individualDTF')
    for latencyNum = 1:size(result.individualDTF, 2)
        for freqNum = 1:size(result.individualDTF, 3)
            for roi1Num = 1:size(result.individualDTF, 4)
                for roi2Num = 1:size(result.individualDTF, 5)
                    statisticResult.individualDTF(:,:,latencyNum, freqNum, roi1Num, roi2Num) = ...
                        SJ_statisticLoop(result, squeeze(result.individualDTF(:,latencyNum, freqNum, roi1Num, roi2Num)));
                end
            end
        end
    end
end

if isfield(result, 'questionnaire')
    if isfield(result, 'erp')
        for channelNum = 1:size(result.erp, 2)
            for latencyNum = 1:size(result.erp, 3)
                statisticResult.erpQuestionnaire(:,channelNum, latencyNum) = ...
                    SJ_questionnaireStatisticLoop(result, squeeze(result.erp(:,channelNum, latencyNum)));
            end
        end
    end
    if isfield(result, 'fftIndividualFreq')
        for channelNum = 1:size(result.fftIndividualFreq, 2)
            for latencyNum = 1:size(result.fftIndividualFreq, 3)
                for freqNum = 1:size(result.fftIndividualFreq, 4)
                    statisticResult.fftIndividualFreqQuestionnaire(:,channelNum, latencyNum, freqNum) = ...
                        SJ_questionnaireStatisticLoop(result, squeeze(result.fftIndividualFreq(:,channelNum, latencyNum, freqNum)));
                end
            end
        end
    end
end
end

function [statisticLoopResult] = SJ_statisticLoop(result, raw)
for subjectGroupNum = 1:size(result.fileGroup, 2)
    for conditionNum = 1:size(result.fileGroup, 4)
        for responseNum = 1:size(result.fileGroup, 3)
            for subConditionNum = 1:size(result.fileGroup, 5)
                currentFile = squeeze(result.fileGroup(:, subjectGroupNum, responseNum, conditionNum, subConditionNum));
                currentData{responseNum, subConditionNum} = raw(logical(currentFile));
            end
        end
        statisticLoopResult{subjectGroupNum, conditionNum} = SJ_allStatistic(currentData);
    end
end
end

function [statistic] = SJ_allStatistic(raw)
raw = SJ_checkData(raw);

normality = 1;
for first = 1:size(raw,1)
    for second = 1:size(raw,2)
        statistic.M(first,second) = mean(raw{first,second});
        statistic.SD(first,second) = std(raw{first,second});
        statistic.N(first,second) = length(raw{first,second});
        normality = normality * normalityTest(raw{first,second});
    end
end

if size(raw,1) == 2
    if normality == 1
        statistic(1).kind = 'ttest';
        for second = 1:size(raw,2)
            X = [raw{1,second};raw{2,second}];
            group = [ones(size(raw{1,second}))*1;ones(size(raw{2,second}))*2];
            levene = vartestn(X, group, 'TestType', 'LeveneAbsolute', 'Display','off');
            if levene > 0.05
                [h,p,~,stats] = ttest2(raw{1, second}, raw{2, second});
            else
                [h,p,~,stats] = ttest2(raw{1, second}, raw{2, second},'Vartype','unequal');
            end
            statistic(1).H(second) = h;
            statistic(1).P(second) = p;
            statistic(1).T(second) = stats.tstat;
            statistic(1).DF(second) = stats.df;
            statistic(1).SD(second) = mean(stats.sd);
        end
    else
        statistic(1).kind = 'Wilcoxon-Mann-Whitney-test';
        for second = 1:size(raw,2)
            [p,h,stats] = ranksum(raw{1, second}, raw{2, second});
            statistic(1).H(second) = h;
            statistic(1).P(second) = p;
            statistic(1).LP(second) = ranksum(raw{1, second}, raw{2, second}, 'tail','left');
            statistic(1).RP(second) = ranksum(raw{1, second}, raw{2, second}, 'tail','right');
            if isfield(stats, 'zval')
                statistic(1).Z(second) = stats.zval;
            end
            statistic(1).RS(second) = stats.ranksum;
        end        
    end  
elseif size(raw,1) > 2
    for second = 1:size(raw,2)
        X = raw{1, second};
        group = ones(size(raw{1, second}));
        for first = 2:size(raw,1)
            X = [X;raw{first,second}];
            group = [group;ones(size(raw{first,second}))*first];
        end
        if normality == 1
            statistic(1).kind{second} = 'anova';
            if length(unique(X)) ~= 1
                [p,tbl,stats] = anova1(X, group, 'off');
                statistic(1).F(second) = tbl{2,5};
                statistic(1).P(second) = p;
                statistic(1).DFG(second) = tbl{2,3};
                statistic(1).DFE(second) = tbl{2,3};
                if p < 0.05
                    statistic(1).H(second) = true;
                    levene = vartestn(X, group, 'TestType', 'LeveneAbsolute', 'Display','off');
                    if levene > 0.05
                        c = multcompare(stats, 'CType', 'scheffe', 'Display', 'off');
                        statistic(1).postHoc(second).p = c(:,[1,2,6]);                        
                    else
                        postP = dunnett(stats);
                        statistic(1).postHoc(second).p = postP;
                    end
                else
                    statistic(1).H(second) = false;
                end
            else
                statistic(1).kind{second} = 'singularData';
            end
        else
            statistic(1).kind{second} = 'kruskalwallis';
            if length(unique(X)) ~= 1
                [p,tbl,~] = kruskalwallis(X, group, 'off');
                statistic(1).F(second) = tbl{2,5};
                statistic(1).P(second) = p;
                statistic(1).DFG(second) = tbl{2,3};
                statistic(1).DFE(second) = tbl{3,3};
                if p < 0.05
                    statistic(1).H(second) = true;
                    postP = multWilconxon(X, group);
                    statistic(1).postHoc(second).p = postP;
                else
                    statistic(1).H(second) = false;
                end
            else
                statistic(1).kind = 'singularData';
            end
        end
    end
else
    statistic(1).kind = 'noGroup';
end

if size(raw,2) == 2
    if normality == 1
        statistic(2).kind = 'ttest';
        for first = 1:size(raw,1)
            X = [raw{first, 1};raw{first, 2}];
            group = [ones(size(raw{first, 1}))*1;ones(size(raw{first, 2}))*2];
            levene = vartestn(X, group, 'TestType', 'LeveneAbsolute', 'Display','off');
            if levene > 0.05
                [h,p,~,stats] = ttest2(raw{first,1}, raw{first,2});
            else
                [h,p,~,stats] = ttest2(raw{first,1}, raw{first,2},'Vartype','unequal');
            end
            statistic(2).H(first) = h;
            statistic(2).P(first) = p;
            statistic(2).T(first) = stats.tstat;
            statistic(2).DF(first) = stats.df;
            statistic(2).SD(first) = mean(stats.sd);
        end
    else
        statistic(2).kind = 'Wilcoxon-Mann-Whitney-test';
        for first = 1:size(raw,1)
            [p,h,stats] = ranksum(raw{first,1}, raw{first,2});
            statistic(2).H(first) = h;
            statistic(2).P(first) = p;
            statistic(2).LP(first) = ranksum(raw{first,1}, raw{first,2},'tail','left');
            statistic(2).RP(first) = ranksum(raw{first,1}, raw{first,2},'tail','right');
            if isfield(stats, 'zval')
                statistic(2).Z(first) = stats.zval;
            end
            statistic(2).RS(first) = stats.ranksum;
        end
    end
elseif size(raw,2) > 2
    for first = 1:size(raw,1)
        X = raw{first,1};
        group = ones(size(raw{first,1}));
        for second = 2:size(raw,2)
            X = [X;raw{first,second}];
            group = [group;ones(size(raw{first,second}))*second];
        end
        if normality == 1
            statistic(2).kind{first} = 'anova';
            if length(unique(X)) ~= 1
                [p,tbl,stats] = anova1(X, group, 'off');
                statistic(2).F(first) = tbl{2,5};
                statistic(2).P(first) = p;
                statistic(2).DFG(first) = tbl{2,3};
                statistic(2).DFE(first) = tbl{2,3};
                if p < 0.05
                    statistic(2).H(first) = true;
                    levene = vartestn(X, group, 'TestType', 'LeveneAbsolute', 'Display','off');
                    if levene > 0.05
                        c = multcompare(stats, 'CType', 'scheffe', 'Display', 'off');
                        statistic(2).postHoc(first).p = c(:,[1,2,6]);
                    else
                        postP = dunnett(stats);
                        statistic(2).postHoc(first).p = postP;
                    end                    
                else
                    statistic(2).H(first) = false;
                end
            else
                statistic(2).kind{first} = 'singularData';
            end
        else
            statistic(2).kind{first} = 'kruskalwallis';
            if length(unique(X)) ~= 1
                [p,tbl,~] = kruskalwallis(X, group, 'off');
                statistic(2).F(first) = tbl{2,5};
                statistic(2).P(first) = p;
                statistic(2).DFG(first) = tbl{2,3};
                statistic(2).DFE(first) = tbl{3,3};
                if p < 0.05
                    statistic(2).H(first) = true;
                    postP = multWilconxon(X, group);
                    statistic(2).postHoc(first).p = postP;
                else
                    statistic(2).H(first) = false;
                end
            else
                statistic(2).kind{first} = 'singularData';
            end
        end
    end
else
    statistic(2).kind = 'noGroup';
end
end

function [checkedRaw] = SJ_checkData(raw)
firstCheck = size(raw,1);
for first = 1:size(raw,1)
    if isempty(raw{first,1})
        firstCheck = first-1;
        break;
    end
end
secondCheck = size(raw,2);
for second = 1:size(raw,2)
    if isempty(raw{1,second})
        secondCheck = second-1;
        break;
    end
end
for first = 1:firstCheck
    for second = 1:secondCheck
        checkedRaw{first,second} = raw{first,second};
    end
end
end

function [H] = normalityTest(x)
if length(x) < 3
    H = 0;
elseif length(x) < 5000
    alpha = 0.05;
    x       =   sort(x);
    n       =   length(x);
    mtilde  =   norminv(((1:n)' - 3/8) / (n + 1/4));
    weights =   zeros(n,1);
    if kurtosis(x) > 3
        weights =   1/sqrt(mtilde'*mtilde) * mtilde;
        W   =   (weights' * x)^2 / ((x - mean(x))' * (x - mean(x)));
        nu      =   log(n);
        u1      =   log(nu) - nu;
        u2      =   log(nu) + 2/nu;
        mu      =   -1.2725 + (1.0521 * u1);
        sigma   =   1.0308 - (0.26758 * u2);
        newSFstatistic  =   log(1 - W);
        NormalSFstatistic =   (newSFstatistic - mu) / sigma;
        pValue   =   1 - normcdf(NormalSFstatistic, 0, 1);
    else
        c    =   1/sqrt(mtilde'*mtilde) * mtilde;
        u    =   1/sqrt(n);
        PolyCoef_1   =   [-2.706056 , 4.434685 , -2.071190 , -0.147981 , 0.221157 , c(n)];
        PolyCoef_2   =   [-3.582633 , 5.682633 , -1.752461 , -0.293762 , 0.042981 , c(n-1)];
        PolyCoef_3   =   [-0.0006714 , 0.0250540 , -0.39978 , 0.54400];
        PolyCoef_4   =   [-0.0020322 , 0.0627670 , -0.77857 , 1.38220];
        PolyCoef_5   =   [0.00389150 , -0.083751 , -0.31082 , -1.5861];
        PolyCoef_6   =   [0.00303020 , -0.082676 , -0.48030];        
        PolyCoef_7   =   [0.459 , -2.273];        
        weights(n)   =   polyval(PolyCoef_1 , u);
        weights(1)   =   -weights(n);
        if n > 5
            weights(n-1) =   polyval(PolyCoef_2 , u);
            weights(2)   =   -weights(n-1);
            count  =   3;
            phi    =   (mtilde'*mtilde - 2 * mtilde(n)^2 - 2 * mtilde(n-1)^2) / ...
                (1 - 2 * weights(n)^2 - 2 * weights(n-1)^2);
        else
            count  =   2;
            phi    =   (mtilde'*mtilde - 2 * mtilde(n)^2) / ...
                (1 - 2 * weights(n)^2);
        end
        if n == 3
            weights(1)  =   1/sqrt(2);
            weights(n)  =   -weights(1);
            phi = 1;
        end        
        weights(count : n-count+1)  =  mtilde(count : n-count+1) / sqrt(phi);
        W   =   (weights' * x) ^2 / ((x - mean(x))' * (x - mean(x)));
        newn    =   log(n);
        if (n >= 4) && (n <= 11)            
            mu      =   polyval(PolyCoef_3 , n);
            sigma   =   exp(polyval(PolyCoef_4 , n));
            gam     =   polyval(PolyCoef_7 , n);            
            newSWstatistic  =   -log(gam-log(1-W));            
        elseif n > 11            
            mu      =   polyval(PolyCoef_5 , newn);
            sigma   =   exp(polyval(PolyCoef_6 , newn));            
            newSWstatistic  =   log(1 - W);            
        elseif n == 3
            mu      =   0;
            sigma   =   1;
            newSWstatistic  =   0;
        end
        NormalSWstatistic   =   (newSWstatistic - mu) / sigma;
        pValue       =   1 - normcdf(NormalSWstatistic, 0, 1);
        if n == 3
            pValue  =   6/pi * (asin(sqrt(W)) - asin(sqrt(3/4)));
        end        
    end
    H  = (alpha >= pValue);
else
    H = kstest(x);
end
end

function [postP]= dunnett(stats)
DF = stats.df;
n_expt_groups = length(stats.means)-1;
current_idx = 0;
for ctrl_idx = 1:(length(stats.means)-1)
    for expt_idx = (ctrl_idx+1):length(stats.means)
        current_idx = current_idx + 1;
        postP(current_idx, 1) = ctrl_idx;
        postP(current_idx, 2) = expt_idx;        
        mean_ctrl = stats.means(ctrl_idx);
        n_ctrl = stats.n(ctrl_idx);        
        mean_expt = stats.means(expt_idx);
        n_expt = stats.n(expt_idx);        
        if(abs(mean_ctrl)<=eps('single') && abs(mean_expt)<=eps('single'))
            postP(current_idx, 3) = 1;
        else
            T = (mean_ctrl - mean_expt)/(stats.s*sqrt(1/n_ctrl + 1/n_expt));
            Q=abs(T);
            if (DF > 2000)
                postP(current_idx, 3) = 1 - dun(Q, n_expt_groups,TP,BT);
            else
                R = n_expt/(n_expt+n_ctrl);
                BT=sqrt(1-R);
                TP=sqrt(R);
                A1=0;
                S=0.14/sqrt(DF);
                X0=1;
                F0=dun(Q*X0,n_expt_groups,TP,BT)*sd(X0,DF);
                ctr=0;
                SUB = 1;
                while(A1/SUB < 1e7 || ctr==0)
                    Xl=X0+S;
                    F1=dun(Q*Xl,n_expt_groups,TP,BT)*sd(Xl,DF);
                    X2=Xl+S;
                    F2=dun(Q*X2,n_expt_groups,TP,BT)*sd(X2,DF);
                    SUB=S/3*(F0+4*F1+F2);
                    A1=A1+SUB;
                    X0=X2;
                    F0=F2;
                    S=S*1.05;
                    ctr=ctr+1;
                end                
                A2 = 0;
                S = -0.14/sqrt(DF);
                XINC = 1.05;
                if(DF <= 12)
                    S = -0.03125;
                    XINC = 1;
                end
                X0=1;
                F0=dun(Q*X0,n_expt_groups,TP,BT)*sd(X0,DF);
                for KK=1:16
                    X1=X0+S;
                    F1=dun(Q*X1,n_expt_groups,TP,BT)*sd(X1,DF);
                    X2=X1+S;
                    F2=dun(Q*X2,n_expt_groups,TP,BT)*sd(X2,DF);
                    SUB = -S/3*(F0+4*F1+F2);
                    A2 = A2+SUB;
                    if(A2/SUB > 1e7)
                        break;
                    end
                    X0 = X2;
                    F0 = F2;
                    S = S*XINC;
                end
                postP(current_idx, 3) = 1 - A1 - A2;
                if(postP(current_idx, 3) < 0)
                    postP(current_idx, 3)=0;
                end
            end            
        end
    end
end
end

function [dn] = dun(Q,n_expt_groups, TP, BT)
if(Q < 0)
    dn = 0;
else
    SP = sqrt(1/(2*pi));
    AREA = 0;
    sig = 0.07;
    x0 = 0;
    f0 = SP*exp(-x0*x0/2)*(zprb((TP*x0+Q)/BT)-zprb((TP*x0-Q)/BT))^n_expt_groups;    
    ct=0;
    sub=1;
    while(AREA/sub < 1e7 || ct==0)
        x1=x0+sig;
        f1=SP*exp(-x1*x1/2)*(zprb((TP*x1+Q)/BT)-zprb((TP*x1-Q)/BT))^n_expt_groups;
        x2=x1+sig;
        f2=SP*exp(-x2*x2/2)*(zprb((TP*x2+Q)/BT)-zprb((TP*x2-Q)/BT))^n_expt_groups;
        sub=sig/3*(f0+4*f1+f2);
        AREA=AREA+sub;
        x0=x2;
        f0=f2;
        sig=sig*1.05;
        ct=ct+1;
    end    
    dn=2*AREA;
end
end

function [g] = sd(S, DF)
g = ((DF^(DF/2))*(S^(DF-1))*exp(-DF*S*S/2))/(gamma(DF/2)*2^(DF/2-1));
end

function [zprb] = zprb(Z)
x=abs(Z);
zprb=0;
if(x > 12)
    if (Z > 0)
        zprb=1-zprb;
    end
else
    q=sqrt(1/(2*pi))*exp(-x*x/2);
    if(x > 3.7)
        zprb=q*(sqrt(4+x*x)-x)/2;
        if (Z > 0)
            zprb=1-zprb;
        end
    else
        t=1/(1.+0.2316419*x);
        P=0.31938153*t;
        P=P-0.356563782*t^2;
        P=P+1.78147937*t^3;
        P=P-1.821255978*t^4;
        P=P+1.330274429*t^5;
        zprb=q*P;        
        if (Z > 0)
            zprb=1-zprb;
        end
    end
end
end

function [postP] = multWilconxon(X, group)
groupKind = unique(group);
current_idx = 0;
for ctrl_idx = 1:(length(unique(group)-1))
    for expt_idx = (ctrl_idx+1):length(unique(group))
        current_idx = current_idx + 1;
        postP(current_idx, 1) = ctrl_idx;
        postP(current_idx, 2) = expt_idx;        
        ctrl_group = X(group == groupKind(ctrl_idx));
        expt_group = X(group == groupKind(expt_idx));
        postP(current_idx, 3) = ranksum(ctrl_group, expt_group);
    end
end
end

function [questionnaireStatisticLoopResult] = SJ_questionnaireStatisticLoop(result, raw)
for questionNum = 1:size(result.questionnaire,2)
    for questionResponseNum = 1:length(result.questionnaireList{questionNum})
        for subConditionNum = 1:size(result.questionnaire, 4)
            currentFile = squeeze(result.questionnaire(:, questionNum, questionResponseNum, subConditionNum));
            currentData{questionResponseNum, subConditionNum} = raw(logical(currentFile));
        end
    end
    questionnaireStatisticLoopResult{questionNum} = SJ_questionnaireStatistic(currentData, result.questionnaireList{questionNum});
    clear currentData;
end
end

function [statistic] = SJ_questionnaireStatistic(raw, responseKind)
for second = 1:size(raw,2)
    dataNum = 1;
    for first = 1:size(raw,1)        
        statistic.M(first,second) = mean(raw{first,second});
        statistic.SD(first,second) = std(raw{first,second});
        statistic.N(first,second) = length(raw{first,second});
        for responseNum = 1:length(raw{first,second})
            x(dataNum) = responseKind(first);
            y(dataNum) = raw{first,second}(responseNum);
            dataNum = dataNum + 1;
        end
    end
    [statistic.pearman_r(second), statistic.pearman_p(second)] = corr(x',y', 'type', 'Pearson');
    [statistic.spearman_r(second), statistic.spearman_p(second)] = corr(x',y', 'type', 'Spearman');
end
end