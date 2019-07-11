% parameter
trialPerclass = 40;
class = 6;
alpha_value = 0.1;

% main process
totalTrial = trialPerclass * class;
X_probability = 1/class;
p=(totalTrial*X_probability+2)/(totalTrial+4);
Z_value = norminv([alpha_value/2 1-alpha_value/2], 0, 1);
chanceLevel = p+sqrt(p*(1-p)/(totalTrial+4))*Z_value(2);

% result
chanceLevel