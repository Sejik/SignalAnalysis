% Matlab build-in SVM version_1
% ref: stackoverflow.com/questions/16570579/full-example-of-multiple-class-svm-with-cross-validation-using-matlab

clear all;

load(['/usr/local/MATLAB/R2015b/toolbox/stats/statsdemos/' 'fisheriris'])
[g, gn]				= grp2idx(species);		% Nominal class to numeric

% Split training and testing sets
[trainIdx, testIdx]	= crossvalind('HoldOut', species, 1/3);

pairwise			= nchoosek(1:length(gn),2);			% 1-vs-1 pairwise models
svmModel			= cell(size(pairwise,1),1);			% Store binary-classifers
predTest			= zeros(sum(testIdx),numel(svmModel));%Store binary predictions

%% classify using [ one-against-one ] approach, SVM with 3rd degree poly kernel
for k=1:numel(svmModel)
	%# get only training instances belonging to this pair
	idx				= trainIdx & any( bsxfun(@eq, g, pairwise(k,:)) , 2 );

	%# train
	svmModel{k}		= svmtrain(meas(idx,:), g(idx), ...
		'BoxConstraint',2e-1, 'Kernel_Function','polynomial', 'Polyorder',3);

	%# test
	predTest(:,k)	= svmclassify(svmModel{k}, meas(testIdx,:));
end
pred = mode(predTest,2);   % Voting: clasify as the class receiving most votes

%# performance
cmat				= confusionmat(g(testIdx),pred);
acc					= 100*sum(diag(cmat))./sum(cmat(:));
fprintf('SVM (1-against-1):\naccuracy = %.2f%%\n', acc);
fprintf('Confusion Matrix:\n'), disp(cmat)
