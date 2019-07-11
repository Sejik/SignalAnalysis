% demo on filters/patterns and how to obtain patterns for the LDA
% classifier in eeglab/bcilab
% 
% Stefan Haufe, 2014

M = 10; %number of features
N = 500; %number of trials
Nplus = 350; %number of trials in positive class

% labels
targets = [ones(Nplus, 1); -ones(N-Nplus, 1)];

% generate data for two classes according to LDA model
% create a random covariance matrix
O = orth(randn(M));
cov_theo = O*diag(exp(2*randn(M, 1)))*O'; 
cov_theo = cov_theo ./ norm(cov_theo);
% create offset: class means differ only in first five features, not in the
% last five
% this is the vector we want to recover, and which only the pattern will
% give us, not the filter
offset = zeros(1, M); offset(1:5) = 1*randn(1, 5); 
% generate data finally
trials = randn(N, M)*sqrtm(cov_theo) + [repmat(offset, Nplus, 1); zeros(N-Nplus, M)];

% plot trials of two classes in 1st and 6th dimension
% distributions differ only in the 1st, but not in the 6th
plot(trials(1:Nplus, 1), trials(1:Nplus, 6), 'b.')
hold on
plot(trials(Nplus+1:N, 1), trials(Nplus+1:N, 6), 'r.')



% train LDA, obtain filter
model = ml_trainlda(trials, targets);
w = model.w;

% obtain pattern 
a = w*cov(trials);

% compare filters, patterns, and the original classmean differences we want
% to recover
figure;
plot(zscore(offset), 'b')
hold on
plot(zscore(w), 'r')
plot(zscore(a), 'g')
legend('true offset', 'filter', 'pattern')

pause

% As I mentioned earlier, for the LDA classifier (without regularization),
% the pattern is particularly simple, and can be computed without actually
% performing the LDA classification. All we have to do to get the pattern
% is to compute the difference of the sum of the feature vectors of the two
% classes
% But: try this with a different classifier, and it may not necessarily
% work, so the pattern in line 40 is the safe choice for all classifiers
a2 = sum(trials(1:Nplus, :))-sum(trials(Nplus+1:N, :));
plot(zscore(a2), 'c--')
legend('true offset', 'filter', 'pattern', 'classdiffpattern')


