function runBatchExp_MultiClass()
% Src Code: 1403100003
% Use data projected onto CCA directions

subjects = 1:6;
subjectnum = size(subjects,2);

classes = 1:6;

classnum = size(classes,2);
RecordTimes = [10:-2.5:2.5];

features = [5:20];
featurenum = size(features, 2);

MultiClassAccuracies = zeros(subjectnum,size(RecordTimes,2));
MultiClassStdErrs = zeros(subjectnum,size(RecordTimes,2));
for iRT = 1:size(RecordTimes,2)
    RTLength = RecordTimes(iRT);
    load trainTestIndex    % TrIdxes TstIdxes CVNum datanumPerClass

    for isubNumIdx = 1:size(subjects,2)
%     for isubNumIdx = 1

        switch isubNumIdx
            case 1
                if floor(RTLength) == RTLength
%                     loadFileName = sprintf('./in_su01/forClassification_%ds', RTLength);
                    loadFileName = sprintf('./in_su01/forClassification_%ds_HarmonicNum_1', RTLength);
%                     loadFileName = sprintf('./in_su01/forClassification_%ds_HarmonicNum_2', RTLength);
                else
%                     loadFileName = sprintf('./in_su01/forClassification_%dp5s', floor(RTLength));
                    loadFileName = sprintf('./in_su01/forClassification_%dp5s_HarmonicNum_1', floor(RTLength));
%                     loadFileName = sprintf('./in_su01/forClassification_%dp5s_HarmonicNum_2', floor(RTLength));
                end
            case 2
                if floor(RTLength) == RTLength
%                     loadFileName = sprintf('./in_su03/forClassification_%ds', RTLength);
                    loadFileName = sprintf('./in_su03/forClassification_%ds_HarmonicNum_1', RTLength);
%                     loadFileName = sprintf('./in_su03/forClassification_%ds_HarmonicNum_2', RTLength);
                else
%                     loadFileName = sprintf('./in_su03/forClassification_%dp5s', floor(RTLength));
                    loadFileName = sprintf('./in_su03/forClassification_%dp5s_HarmonicNum_1', floor(RTLength));
%                     loadFileName = sprintf('./in_su03/forClassification_%dp5s_HarmonicNum_2', floor(RTLength));
                end
            case 3
                if floor(RTLength) == RTLength
%                     loadFileName = sprintf('./in_su04/forClassification_%ds', RTLength);
                    loadFileName = sprintf('./in_su04/forClassification_%ds_HarmonicNum_1', RTLength);
%                     loadFileName = sprintf('./in_su04/forClassification_%ds_HarmonicNum_2', RTLength);
                else
%                     loadFileName = sprintf('./in_su04/forClassification_%dp5s', floor(RTLength));
                    loadFileName = sprintf('./in_su04/forClassification_%dp5s_HarmonicNum_1', floor(RTLength));
%                     loadFileName = sprintf('./in_su04/forClassification_%dp5s_HarmonicNum_2', floor(RTLength));
                end
            case 4
                if floor(RTLength) == RTLength
%                     loadFileName = sprintf('./out_su08/forClassification_%ds', RTLength);
                    loadFileName = sprintf('./out_su08/forClassification_%ds_HarmonicNum_1', RTLength);
%                     loadFileName = sprintf('./out_su08/forClassification_%ds_HarmonicNum_2', RTLength);
                else
%                     loadFileName = sprintf('./out_su08/forClassification_%dp5s', floor(RTLength));
                    loadFileName = sprintf('./out_su08/forClassification_%dp5s_HarmonicNum_1', floor(RTLength));
%                     loadFileName = sprintf('./out_su08/forClassification_%dp5s_HarmonicNum_2', floor(RTLength));
                end
            case 5
                if floor(RTLength) == RTLength
%                     loadFileName = sprintf('./out_su10/forClassification_%ds', RTLength);
                    loadFileName = sprintf('./out_su10/forClassification_%ds_HarmonicNum_1', RTLength);
%                     loadFileName = sprintf('./out_su10/forClassification_%ds_HarmonicNum_2', RTLength);
                else
%                     loadFileName = sprintf('./out_su10/forClassification_%dp5s', floor(RTLength));
                    loadFileName = sprintf('./out_su10/forClassification_%dp5s_HarmonicNum_1', floor(RTLength));
%                     loadFileName = sprintf('./out_su10/forClassification_%dp5s_HarmonicNum_2', floor(RTLength));
                end
            case 6
                if floor(RTLength) == RTLength
%                     loadFileName = sprintf('./out_su11/forClassification_%ds', RTLength);
                    loadFileName = sprintf('./out_su11/forClassification_%ds_HarmonicNum_1', RTLength);
%                     loadFileName = sprintf('./out_su11/forClassification_%ds_HarmonicNum_2', RTLength);
                else
%                     loadFileName = sprintf('./out_su11/forClassification_%dp5s', floor(RTLength));
                    loadFileName = sprintf('./out_su11/forClassification_%dp5s_HarmonicNum_1', floor(RTLength));
%                     loadFileName = sprintf('./out_su11/forClassification_%dp5s_HarmonicNum_2', floor(RTLength));
                end
        end
        load(loadFileName);

        oneClassTotNum = size(R1_C3,2);
        totData = zeros(featurenum, oneClassTotNum*size(classes,2));
        totLabels = zeros(1, oneClassTotNum*size(classes,2));
        for ilabel = 1:classnum
            totLabels((oneClassTotNum*(ilabel - 1) + 1):oneClassTotNum*ilabel) = classes(ilabel);
            switch classes(ilabel)
                case 1
                    totData(:,(oneClassTotNum*(ilabel - 1) + 1):oneClassTotNum*ilabel) = R1_C3(features,:);
                case 2
                    totData(:,(oneClassTotNum*(ilabel - 1) + 1):oneClassTotNum*ilabel) = R3_C1(features,:);
                case 3
                    totData(:,(oneClassTotNum*(ilabel - 1) + 1):oneClassTotNum*ilabel) = R3_C2(features,:);
                case 4
                    totData(:,(oneClassTotNum*(ilabel - 1) + 1):oneClassTotNum*ilabel) = R1_C2(features,:);
                case 5
                    totData(:,(oneClassTotNum*(ilabel - 1) + 1):oneClassTotNum*ilabel) = R2_C1(features,:);
                case 6
                    totData(:,(oneClassTotNum*(ilabel - 1) + 1):oneClassTotNum*ilabel) = R2_C3(features,:);
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
%             regConst = -2;
            regConst = -3;
%             regConst = -4;
%             regConst = -5;
            Sb = zeros(featurenum);
            Sw = zeros(featurenum);
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
            Sw = Sw + 10^regConst*trace(Sw)*eye(featurenum);
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

save runBatchExp_Multiclass MultiClassAccuracies MultiClassStdErrs RecordTimes classes subjects ITRs

