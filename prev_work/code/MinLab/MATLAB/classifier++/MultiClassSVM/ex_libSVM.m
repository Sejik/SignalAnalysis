% libSVM version_1
% ref: stackoverflow.com/questions/16570579/full-example-of-multiple-class-svm-with-cross-validation-using-matlab

clear all;

load(['/usr/local/MATLAB/R2015b/toolbox/stats/statsdemos/' 'fisheriris'])
[~,~,labels]	= unique(species);			% Labels: 1/2/3
data			= zscore(meas);				% Scale features
numInst			= size(data,1);
numLabels		= max(labels);

%# Split training/testing
idx				= randperm(numInst);
numTrain		= 100; 
numTest			= numInst - numTrain;

trainData		= data(idx(1:numTrain),:);  
testData		= data(idx(numTrain+1:end),:);
size(trainData)
size(testData)
trainLabel		= labels(idx(1:numTrain)); 
testLabel		= labels(idx(numTrain+1:end));
size(trainLabel)
size(testLabel)
BREAK
%% Train [ one-against-all ] models
if 0
model			= cell(numLabels,1);
for k=1:numLabels
	model{k} = libsvmtrain(double(trainLabel==k), trainData, '-c 1 -g 0.2 -b 1');
end

%# Get probability estimates of test instances using each model
prob			= zeros(numTest,numLabels);
for k=1:numLabels
	[~,~,p]		= svmpredict(double(testLabel==k), testData, model{k}, '-b 1');
	prob(:,k)	= p(:,model{k}.Label==1);	% Probability of class==k
end

% Predict the class with the highest probability
[~,pred]		= max(prob,[],2);
acc				= sum(pred == testLabel) ./ numel(testLabel);	% Accuracy
C				= confusionmat(testLabel, pred); % Confusion matrix

else
model			= libsvmtrain(trainLabel, trainData, '-c 1 -g 0.2 -b 1');
[pLBL,acc,p]	= svmpredict(testLabel, testData, model, '-b 1');
C				= confusionmat(testLabel, pLBL); % Confusion matrix

end

fprintf('accuracy = %f\n', acc);
fprintf('classifier '); C