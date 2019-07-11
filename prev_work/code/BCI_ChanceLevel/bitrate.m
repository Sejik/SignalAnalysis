% parameter
p = 0.4242;
N = 6;
decisionNum = 1;
durationMinutes = 1/12;

% main
bit_rate = p*log2(p)+(1-p)*log2((1-p)/(N-1)) + log2(N);
ITR = decisionNum/durationMinutes * bit_rate;

% result
ITR