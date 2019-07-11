function runBatchExp_AllChannel_MultiClass()
% Src Code: 1411040001

subjects = 1:6;
subjectnum = size(subjects,2);

classes = 1:6;

classnum = size(classes,2);
RecordTimes = [10:-2.5:2.5];

signalPerSec = 500;
FullSecPerDatum = 10;
signalPerDatum = signalPerSec*FullSecPerDatum;

% for classification
features = [5:20];  % from 5Hz ~ 20Hz
featurenum = size(features, 2);

channelNum = 28;

tic
MultiClassAccuracies = zeros(subjectnum,size(RecordTimes,2));
MultiClassStdErrs = zeros(subjectnum,size(RecordTimes,2));
for iRT = 1:size(RecordTimes,2)
    RTLength = RecordTimes(iRT);
    load trainTestIndex    % TrIdxes TstIdxes CVNum datanumPerClass

    for isubNumIdx = 1:size(subjects,2)
%     for isubNumIdx = 1
            
        switch isubNumIdx
            case 1
                loadFileNamePrefix = sprintf('./in_su01/');
            case 2
                loadFileNamePrefix = sprintf('./in_su03/');
            case 3
                loadFileNamePrefix = sprintf('./in_su04/');
            case 4
                loadFileNamePrefix = sprintf('./out_su08/');
            case 5
                loadFileNamePrefix = sprintf('./out_su10/');
            case 6
                loadFileNamePrefix = sprintf('./out_su11/');
        end

        oneClassTotNum = datanumPerClass;
        totData = zeros(featurenum*channelNum, oneClassTotNum*classnum);
        totLabels = zeros(1, oneClassTotNum*classnum);
        for ilabel = 1:classnum
            totLabels((oneClassTotNum*(ilabel - 1) + 1):oneClassTotNum*ilabel) = classes(ilabel);

            switch classes(ilabel)
                case 1
                    loadFileName = [loadFileNamePrefix '1_R1_C3'];
                case 2
                    loadFileName = [loadFileNamePrefix '2_R3_C1'];
                case 3
                    loadFileName = [loadFileNamePrefix '3_R3_C2'];
                case 4
                    loadFileName = [loadFileNamePrefix '4_R1_C2'];
                case 5
                    loadFileName = [loadFileNamePrefix '5_R2_C1'];
                case 6
                    loadFileName = [loadFileNamePrefix '6_R2_C3'];
            end
            load(loadFileName);

            SecPerDatum = RTLength;
            for idataIdx = 1:datanumPerClass
                sprintf('iRT[%d] isubNumIdx[%d] ilabel[%d] idataIdx[%d], time[%d]', iRT, isubNumIdx, ilabel, idataIdx, toc)
                curSignalC3  = C3([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalC3,[],[],features,signalPerSec);
                
                curSignalC4  = C4([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalC4,[],[],features,signalPerSec)';
                
                curSignalCP5 = CP5([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalCP5,[],[],features,signalPerSec)';
                
                curSignalCP6 = CP6([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalCP6,[],[],features,signalPerSec)';
                
                curSignalCPz = CPz([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalCPz,[],[],features,signalPerSec)';
                
                curSignalCz  = Cz([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalCz,[],[],features,signalPerSec)';
                
                curSignalF3  = F3([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalF3,[],[],features,signalPerSec)';
                
                curSignalF4  = F4([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalF4,[],[],features,signalPerSec)';
                
                curSignalFz  = Fz([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalFz,[],[],features,signalPerSec)';
                
                curSignalO1  = O1([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalO1,[],[],features,signalPerSec)';
                
                curSignalO2  = O2([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalO2,[],[],features,signalPerSec)';
                
                curSignalOz  = Oz([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalOz,[],[],features,signalPerSec)';
                
                curSignalP1  = P1([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalP1,[],[],features,signalPerSec)';
                
                curSignalP2  = P2([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalP2,[],[],features,signalPerSec)';
                
                curSignalP3  = P3([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalP3,[],[],features,signalPerSec)';
                
                curSignalP4  = P4([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalP4,[],[],features,signalPerSec)';
                
                curSignalP5  = P5([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalP5,[],[],features,signalPerSec)';
                
                curSignalP6  = P6([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalP6,[],[],features,signalPerSec)';
                
                curSignalP7  = P7([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalP7,[],[],features,signalPerSec)';
                
                curSignalP8  = P8([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalP8,[],[],features,signalPerSec)';
                
                curSignalPO10= PO10([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalPO10,[],[],features,signalPerSec)';
                
                curSignalPO3 = PO3([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalPO3,[],[],features,signalPerSec)';
                
                curSignalPO4 = PO4([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalPO4,[],[],features,signalPerSec)';
                
                curSignalPO7 = PO7([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalPO7,[],[],features,signalPerSec)';
                
                curSignalPO8 = PO8([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalPO8,[],[],features,signalPerSec)';
                
                curSignalPO9 = PO9([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalPO9,[],[],features,signalPerSec)';
                
                curSignalPOz = POz([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalPOz,[],[],features,signalPerSec)';
                
                curSignalPz  = Pz([1 + (FullSecPerDatum - SecPerDatum)/2*signalPerSec: ...
                    signalPerDatum - (FullSecPerDatum - SecPerDatum)/2*signalPerSec], idataIdx)';
                ifeatureIdx = ifeatureIdx + 1;
                totData((ifeatureIdx - 1)*featurenum + [1:featurenum], (ilabel - 1)*oneClassTotNum + idataIdx) = pwelch(curSignalPz,[],[],features,signalPerSec)';
                
            end
        end
        % classify
        Accuracy1s = [];
        AvgAccuracy1 = 0;
        for iCV = 1:CVNum
            TrIdxesCV = [];
            TstIdxesCV = [];
            for iclass = 1:classnum
                TrIdxesCV = [TrIdxesCV oneClassTotNum*(iclass - 1) + TrIdxes(iCV,:)];
                TstIdxesCV = [TstIdxesCV oneClassTotNum*(iclass - 1) + TstIdxes(iCV,:)];
            end
            TrData = totData(:,TrIdxesCV);
            TrLabels = totLabels(TrIdxesCV);
            TstData = totData(:,TstIdxesCV);
            TstLabels = totLabels(TstIdxesCV);
            
            %%%% Preprocessing %%%%%
%             MeanForNormalization = mean(TrData, 2);
%             StdForNormalization = std(TrData, 1, 2);
%             TrData = (TrData - MeanForNormalization*ones(1,size(TrData,2)))./(StdForNormalization*ones(1,size(TrData,2)));
%             TstData = (TstData - MeanForNormalization*ones(1,size(TstData,2)))./(StdForNormalization*ones(1,size(TstData,2)));


            %%%%%%%%%%%%%%%%%%% FDA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % FDA
%             regConst = -1;
%             regConst = -2;
%             regConst = -3;
%             regConst = -4;
%             regConst = -5;
            regConst = -6;
%             regConst = -7;
            Sb = zeros(featurenum*channelNum);
            Sw = zeros(featurenum*channelNum);
            totMean = mean(TrData,2);
            for ilabel = 1:classnum
                CurClassTrDataIdxes = find(TrLabels == classes(ilabel));
                CurClassTrDataNum = size(CurClassTrDataIdxes, 2);
                curTrDataMean = mean(TrData(:,CurClassTrDataIdxes), 2);
                Sb = Sb + (curTrDataMean - totMean)*(curTrDataMean - totMean)'*CurClassTrDataNum;
                Sw = Sw + (TrData(:,CurClassTrDataIdxes) - curTrDataMean*ones(1,CurClassTrDataNum))* ...
                    (TrData(:,CurClassTrDataIdxes) - curTrDataMean*ones(1,CurClassTrDataNum))';
            end
            Sb = (Sb + Sb')/2;
            Sw = (Sw + Sw')/2;
            Sw = Sw + 10^regConst*trace(Sw)*eye(featurenum*channelNum);
            L = chol(Sw)';
            invL = inv(L);
            Met = invL*Sb*invL';
            Met = (Met + Met')/2;
            [V,D] = eig(Met);
            [sortedEval, sortedEvalIdx] = sort(diag(D)');

            FDAAxes = invL'*V(:,sortedEvalIdx(end:-1:end - (classnum - 1) + 1));


            % FDA classification
            totTstDataNum = size(TstData,2);
            DistSqToMeans = [];
            for ilabel = 1:classnum
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                DistSqToMeans = [DistSqToMeans; ...
                    sum((FDAAxes'*mean(TrData(:,find(TrLabels == classes(ilabel))), 2)*ones(1,totTstDataNum) - FDAAxes'*TstData).^2, 1)];
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 curClassIdx = find(TrLabels == classes(ilabel));
%                 curM = mean(FDAAxes'*TrData(:,curClassIdx), 2);
%                 curCov = FDAAxes'*TrData(:,curClassIdx)*TrData(:,curClassIdx)'*FDAAxes/size(curClassIdx,2) - curM*curM';
%                 DistSqToMeans = [DistSqToMeans; -getLogGaussian(FDAAxes'*TstData, curM, (curCov + curCov')/2)];
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
            [~,ClassifiedClassIdx] = min(DistSqToMeans, [], 1);
            Accuracy = mean(classes(ClassifiedClassIdx) == TstLabels);
            AvgAccuracy1 = AvgAccuracy1 + Accuracy/CVNum;
            Accuracy1s = [Accuracy1s Accuracy];
        end
        MultiClassAccuracies(isubNumIdx, iRT) = AvgAccuracy1;
        MultiClassStdErrs(isubNumIdx, iRT) = std(Accuracy1s, 1, 2)/sqrt(CVNum);
    end
end
MultiClassAccuracies
MultiClassStdErrs

ITRs = (MultiClassAccuracies.*log(MultiClassAccuracies)/log(2) + ...
    (1 - MultiClassAccuracies).*log((1 - MultiClassAccuracies)/(classnum - 1))/log(2) ...
    + log(classnum)/log(2))*60./(ones(subjectnum,1)*RecordTimes);
ITRs

save runBatchExp_AllChannel_Multiclass MultiClassAccuracies MultiClassStdErrs RecordTimes classes subjects ITRs



