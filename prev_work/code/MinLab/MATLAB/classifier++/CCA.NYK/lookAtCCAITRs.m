function lookAtCCAITRs()
% Src Code: 1404100001

subNum = 6;
timeNum = 4;

ITRs_Harmonics1 = zeros(subNum,timeNum);
load in_su01/forClassification_2p5s_HarmonicNum_1
ITRs_Harmonics1(1,4) = ITR;
load in_su01/forClassification_5s_HarmonicNum_1
ITRs_Harmonics1(1,3) = ITR;
load in_su01/forClassification_7p5s_HarmonicNum_1
ITRs_Harmonics1(1,2) = ITR;
load in_su01/forClassification_10s_HarmonicNum_1
ITRs_Harmonics1(1,1) = ITR;

load in_su03/forClassification_2p5s_HarmonicNum_1
ITRs_Harmonics1(2,4) = ITR;
load in_su03/forClassification_5s_HarmonicNum_1
ITRs_Harmonics1(2,3) = ITR;
load in_su03/forClassification_7p5s_HarmonicNum_1
ITRs_Harmonics1(2,2) = ITR;
load in_su03/forClassification_10s_HarmonicNum_1
ITRs_Harmonics1(2,1) = ITR;

load in_su04/forClassification_2p5s_HarmonicNum_1
ITRs_Harmonics1(3,4) = ITR;
load in_su04/forClassification_5s_HarmonicNum_1
ITRs_Harmonics1(3,3) = ITR;
load in_su04/forClassification_7p5s_HarmonicNum_1
ITRs_Harmonics1(3,2) = ITR;
load in_su04/forClassification_10s_HarmonicNum_1
ITRs_Harmonics1(3,1) = ITR;

load out_su08/forClassification_2p5s_HarmonicNum_1
ITRs_Harmonics1(4,4) = ITR;
load out_su08/forClassification_5s_HarmonicNum_1
ITRs_Harmonics1(4,3) = ITR;
load out_su08/forClassification_7p5s_HarmonicNum_1
ITRs_Harmonics1(4,2) = ITR;
load out_su08/forClassification_10s_HarmonicNum_1
ITRs_Harmonics1(4,1) = ITR;

load out_su10/forClassification_2p5s_HarmonicNum_1
ITRs_Harmonics1(5,4) = ITR;
load out_su10/forClassification_5s_HarmonicNum_1
ITRs_Harmonics1(5,3) = ITR;
load out_su10/forClassification_7p5s_HarmonicNum_1
ITRs_Harmonics1(5,2) = ITR;
load out_su10/forClassification_10s_HarmonicNum_1
ITRs_Harmonics1(5,1) = ITR;

load out_su11/forClassification_2p5s_HarmonicNum_1
ITRs_Harmonics1(6,4) = ITR;
load out_su11/forClassification_5s_HarmonicNum_1
ITRs_Harmonics1(6,3) = ITR;
load out_su11/forClassification_7p5s_HarmonicNum_1
ITRs_Harmonics1(6,2) = ITR;
load out_su11/forClassification_10s_HarmonicNum_1
ITRs_Harmonics1(6,1) = ITR;

ITRs_Harmonics1

ITRs_Harmonics2 = zeros(subNum,timeNum);
load in_su01/forClassification_2p5s_HarmonicNum_2
ITRs_Harmonics2(1,4) = ITR;
load in_su01/forClassification_5s_HarmonicNum_2
ITRs_Harmonics2(1,3) = ITR;
load in_su01/forClassification_7p5s_HarmonicNum_2
ITRs_Harmonics2(1,2) = ITR;
load in_su01/forClassification_10s_HarmonicNum_2
ITRs_Harmonics2(1,1) = ITR;

load in_su03/forClassification_2p5s_HarmonicNum_2
ITRs_Harmonics2(2,4) = ITR;
load in_su03/forClassification_5s_HarmonicNum_2
ITRs_Harmonics2(2,3) = ITR;
load in_su03/forClassification_7p5s_HarmonicNum_2
ITRs_Harmonics2(2,2) = ITR;
load in_su03/forClassification_10s_HarmonicNum_2
ITRs_Harmonics2(2,1) = ITR;

load in_su04/forClassification_2p5s_HarmonicNum_2
ITRs_Harmonics2(3,4) = ITR;
load in_su04/forClassification_5s_HarmonicNum_2
ITRs_Harmonics2(3,3) = ITR;
load in_su04/forClassification_7p5s_HarmonicNum_2
ITRs_Harmonics2(3,2) = ITR;
load in_su04/forClassification_10s_HarmonicNum_2
ITRs_Harmonics2(3,1) = ITR;

load out_su08/forClassification_2p5s_HarmonicNum_2
ITRs_Harmonics2(4,4) = ITR;
load out_su08/forClassification_5s_HarmonicNum_2
ITRs_Harmonics2(4,3) = ITR;
load out_su08/forClassification_7p5s_HarmonicNum_2
ITRs_Harmonics2(4,2) = ITR;
load out_su08/forClassification_10s_HarmonicNum_2
ITRs_Harmonics2(4,1) = ITR;

load out_su10/forClassification_2p5s_HarmonicNum_2
ITRs_Harmonics2(5,4) = ITR;
load out_su10/forClassification_5s_HarmonicNum_2
ITRs_Harmonics2(5,3) = ITR;
load out_su10/forClassification_7p5s_HarmonicNum_2
ITRs_Harmonics2(5,2) = ITR;
load out_su10/forClassification_10s_HarmonicNum_2
ITRs_Harmonics2(5,1) = ITR;

load out_su11/forClassification_2p5s_HarmonicNum_2
ITRs_Harmonics2(6,4) = ITR;
load out_su11/forClassification_5s_HarmonicNum_2
ITRs_Harmonics2(6,3) = ITR;
load out_su11/forClassification_7p5s_HarmonicNum_2
ITRs_Harmonics2(6,2) = ITR;
load out_su11/forClassification_10s_HarmonicNum_2
ITRs_Harmonics2(6,1) = ITR;

ITRs_Harmonics2

ITRs_Harmonics3 = zeros(subNum,timeNum);
load in_su01/forClassification_2p5s_HarmonicNum_3
ITRs_Harmonics3(1,4) = ITR;
load in_su01/forClassification_5s_HarmonicNum_3
ITRs_Harmonics3(1,3) = ITR;
load in_su01/forClassification_7p5s_HarmonicNum_3
ITRs_Harmonics3(1,2) = ITR;
load in_su01/forClassification_10s_HarmonicNum_3
ITRs_Harmonics3(1,1) = ITR;

load in_su03/forClassification_2p5s_HarmonicNum_3
ITRs_Harmonics3(2,4) = ITR;
load in_su03/forClassification_5s_HarmonicNum_3
ITRs_Harmonics3(2,3) = ITR;
load in_su03/forClassification_7p5s_HarmonicNum_3
ITRs_Harmonics3(2,2) = ITR;
load in_su03/forClassification_10s_HarmonicNum_3
ITRs_Harmonics3(2,1) = ITR;

load in_su04/forClassification_2p5s_HarmonicNum_3
ITRs_Harmonics3(3,4) = ITR;
load in_su04/forClassification_5s_HarmonicNum_3
ITRs_Harmonics3(3,3) = ITR;
load in_su04/forClassification_7p5s_HarmonicNum_3
ITRs_Harmonics3(3,2) = ITR;
load in_su04/forClassification_10s_HarmonicNum_3
ITRs_Harmonics3(3,1) = ITR;

load out_su08/forClassification_2p5s_HarmonicNum_3
ITRs_Harmonics3(4,4) = ITR;
load out_su08/forClassification_5s_HarmonicNum_3
ITRs_Harmonics3(4,3) = ITR;
load out_su08/forClassification_7p5s_HarmonicNum_3
ITRs_Harmonics3(4,2) = ITR;
load out_su08/forClassification_10s_HarmonicNum_3
ITRs_Harmonics3(4,1) = ITR;

load out_su10/forClassification_2p5s_HarmonicNum_3
ITRs_Harmonics3(5,4) = ITR;
load out_su10/forClassification_5s_HarmonicNum_3
ITRs_Harmonics3(5,3) = ITR;
load out_su10/forClassification_7p5s_HarmonicNum_3
ITRs_Harmonics3(5,2) = ITR;
load out_su10/forClassification_10s_HarmonicNum_3
ITRs_Harmonics3(5,1) = ITR;

load out_su11/forClassification_2p5s_HarmonicNum_3
ITRs_Harmonics3(6,4) = ITR;
load out_su11/forClassification_5s_HarmonicNum_3
ITRs_Harmonics3(6,3) = ITR;
load out_su11/forClassification_7p5s_HarmonicNum_3
ITRs_Harmonics3(6,2) = ITR;
load out_su11/forClassification_10s_HarmonicNum_3
ITRs_Harmonics3(6,1) = ITR;

ITRs_Harmonics3

ITRs_Harmonics4 = zeros(subNum,timeNum);
load in_su01/forClassification_2p5s_HarmonicNum_4
ITRs_Harmonics4(1,4) = ITR;
load in_su01/forClassification_5s_HarmonicNum_4
ITRs_Harmonics4(1,3) = ITR;
load in_su01/forClassification_7p5s_HarmonicNum_4
ITRs_Harmonics4(1,2) = ITR;
load in_su01/forClassification_10s_HarmonicNum_4
ITRs_Harmonics4(1,1) = ITR;

load in_su03/forClassification_2p5s_HarmonicNum_4
ITRs_Harmonics4(2,4) = ITR;
load in_su03/forClassification_5s_HarmonicNum_4
ITRs_Harmonics4(2,3) = ITR;
load in_su03/forClassification_7p5s_HarmonicNum_4
ITRs_Harmonics4(2,2) = ITR;
load in_su03/forClassification_10s_HarmonicNum_4
ITRs_Harmonics4(2,1) = ITR;

load in_su04/forClassification_2p5s_HarmonicNum_4
ITRs_Harmonics4(3,4) = ITR;
load in_su04/forClassification_5s_HarmonicNum_4
ITRs_Harmonics4(3,3) = ITR;
load in_su04/forClassification_7p5s_HarmonicNum_4
ITRs_Harmonics4(3,2) = ITR;
load in_su04/forClassification_10s_HarmonicNum_4
ITRs_Harmonics4(3,1) = ITR;

load out_su08/forClassification_2p5s_HarmonicNum_4
ITRs_Harmonics4(4,4) = ITR;
load out_su08/forClassification_5s_HarmonicNum_4
ITRs_Harmonics4(4,3) = ITR;
load out_su08/forClassification_7p5s_HarmonicNum_4
ITRs_Harmonics4(4,2) = ITR;
load out_su08/forClassification_10s_HarmonicNum_4
ITRs_Harmonics4(4,1) = ITR;

load out_su10/forClassification_2p5s_HarmonicNum_4
ITRs_Harmonics4(5,4) = ITR;
load out_su10/forClassification_5s_HarmonicNum_4
ITRs_Harmonics4(5,3) = ITR;
load out_su10/forClassification_7p5s_HarmonicNum_4
ITRs_Harmonics4(5,2) = ITR;
load out_su10/forClassification_10s_HarmonicNum_4
ITRs_Harmonics4(5,1) = ITR;

load out_su11/forClassification_2p5s_HarmonicNum_4
ITRs_Harmonics4(6,4) = ITR;
load out_su11/forClassification_5s_HarmonicNum_4
ITRs_Harmonics4(6,3) = ITR;
load out_su11/forClassification_7p5s_HarmonicNum_4
ITRs_Harmonics4(6,2) = ITR;
load out_su11/forClassification_10s_HarmonicNum_4
ITRs_Harmonics4(6,1) = ITR;

ITRs_Harmonics4

ITRs_Harmonics5 = zeros(subNum,timeNum);
load in_su01/forClassification_2p5s_HarmonicNum_5
ITRs_Harmonics5(1,4) = ITR;
load in_su01/forClassification_5s_HarmonicNum_5
ITRs_Harmonics5(1,3) = ITR;
load in_su01/forClassification_7p5s_HarmonicNum_5
ITRs_Harmonics5(1,2) = ITR;
load in_su01/forClassification_10s_HarmonicNum_5
ITRs_Harmonics5(1,1) = ITR;

load in_su03/forClassification_2p5s_HarmonicNum_5
ITRs_Harmonics5(2,4) = ITR;
load in_su03/forClassification_5s_HarmonicNum_5
ITRs_Harmonics5(2,3) = ITR;
load in_su03/forClassification_7p5s_HarmonicNum_5
ITRs_Harmonics5(2,2) = ITR;
load in_su03/forClassification_10s_HarmonicNum_5
ITRs_Harmonics5(2,1) = ITR;

load in_su04/forClassification_2p5s_HarmonicNum_5
ITRs_Harmonics5(3,4) = ITR;
load in_su04/forClassification_5s_HarmonicNum_5
ITRs_Harmonics5(3,3) = ITR;
load in_su04/forClassification_7p5s_HarmonicNum_5
ITRs_Harmonics5(3,2) = ITR;
load in_su04/forClassification_10s_HarmonicNum_5
ITRs_Harmonics5(3,1) = ITR;

load out_su08/forClassification_2p5s_HarmonicNum_5
ITRs_Harmonics5(4,4) = ITR;
load out_su08/forClassification_5s_HarmonicNum_5
ITRs_Harmonics5(4,3) = ITR;
load out_su08/forClassification_7p5s_HarmonicNum_5
ITRs_Harmonics5(4,2) = ITR;
load out_su08/forClassification_10s_HarmonicNum_5
ITRs_Harmonics5(4,1) = ITR;

load out_su10/forClassification_2p5s_HarmonicNum_5
ITRs_Harmonics5(5,4) = ITR;
load out_su10/forClassification_5s_HarmonicNum_5
ITRs_Harmonics5(5,3) = ITR;
load out_su10/forClassification_7p5s_HarmonicNum_5
ITRs_Harmonics5(5,2) = ITR;
load out_su10/forClassification_10s_HarmonicNum_5
ITRs_Harmonics5(5,1) = ITR;

load out_su11/forClassification_2p5s_HarmonicNum_5
ITRs_Harmonics5(6,4) = ITR;
load out_su11/forClassification_5s_HarmonicNum_5
ITRs_Harmonics5(6,3) = ITR;
load out_su11/forClassification_7p5s_HarmonicNum_5
ITRs_Harmonics5(6,2) = ITR;
load out_su11/forClassification_10s_HarmonicNum_5
ITRs_Harmonics5(6,1) = ITR;

ITRs_Harmonics5

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FreqSumITRs_Harmonics1 = zeros(subNum,timeNum);
load in_su01/forClassification_FreqSum_2p5s_HarmonicNum_1
FreqSumITRs_Harmonics1(1,4) = ITR;
load in_su01/forClassification_FreqSum_5s_HarmonicNum_1
FreqSumITRs_Harmonics1(1,3) = ITR;
load in_su01/forClassification_FreqSum_7p5s_HarmonicNum_1
FreqSumITRs_Harmonics1(1,2) = ITR;
load in_su01/forClassification_FreqSum_10s_HarmonicNum_1
FreqSumITRs_Harmonics1(1,1) = ITR;

load in_su03/forClassification_FreqSum_2p5s_HarmonicNum_1
FreqSumITRs_Harmonics1(2,4) = ITR;
load in_su03/forClassification_FreqSum_5s_HarmonicNum_1
FreqSumITRs_Harmonics1(2,3) = ITR;
load in_su03/forClassification_FreqSum_7p5s_HarmonicNum_1
FreqSumITRs_Harmonics1(2,2) = ITR;
load in_su03/forClassification_FreqSum_10s_HarmonicNum_1
FreqSumITRs_Harmonics1(2,1) = ITR;

load in_su04/forClassification_FreqSum_2p5s_HarmonicNum_1
FreqSumITRs_Harmonics1(3,4) = ITR;
load in_su04/forClassification_FreqSum_5s_HarmonicNum_1
FreqSumITRs_Harmonics1(3,3) = ITR;
load in_su04/forClassification_FreqSum_7p5s_HarmonicNum_1
FreqSumITRs_Harmonics1(3,2) = ITR;
load in_su04/forClassification_FreqSum_10s_HarmonicNum_1
FreqSumITRs_Harmonics1(3,1) = ITR;

load out_su08/forClassification_FreqSum_2p5s_HarmonicNum_1
FreqSumITRs_Harmonics1(4,4) = ITR;
load out_su08/forClassification_FreqSum_5s_HarmonicNum_1
FreqSumITRs_Harmonics1(4,3) = ITR;
load out_su08/forClassification_FreqSum_7p5s_HarmonicNum_1
FreqSumITRs_Harmonics1(4,2) = ITR;
load out_su08/forClassification_FreqSum_10s_HarmonicNum_1
FreqSumITRs_Harmonics1(4,1) = ITR;

load out_su10/forClassification_FreqSum_2p5s_HarmonicNum_1
FreqSumITRs_Harmonics1(5,4) = ITR;
load out_su10/forClassification_FreqSum_5s_HarmonicNum_1
FreqSumITRs_Harmonics1(5,3) = ITR;
load out_su10/forClassification_FreqSum_7p5s_HarmonicNum_1
FreqSumITRs_Harmonics1(5,2) = ITR;
load out_su10/forClassification_FreqSum_10s_HarmonicNum_1
FreqSumITRs_Harmonics1(5,1) = ITR;

load out_su11/forClassification_FreqSum_2p5s_HarmonicNum_1
FreqSumITRs_Harmonics1(6,4) = ITR;
load out_su11/forClassification_FreqSum_5s_HarmonicNum_1
FreqSumITRs_Harmonics1(6,3) = ITR;
load out_su11/forClassification_FreqSum_7p5s_HarmonicNum_1
FreqSumITRs_Harmonics1(6,2) = ITR;
load out_su11/forClassification_FreqSum_10s_HarmonicNum_1
FreqSumITRs_Harmonics1(6,1) = ITR;

FreqSumITRs_Harmonics1

FreqSumITRs_Harmonics2 = zeros(subNum,timeNum);
load in_su01/forClassification_FreqSum_2p5s_HarmonicNum_2
FreqSumITRs_Harmonics2(1,4) = ITR;
load in_su01/forClassification_FreqSum_5s_HarmonicNum_2
FreqSumITRs_Harmonics2(1,3) = ITR;
load in_su01/forClassification_FreqSum_7p5s_HarmonicNum_2
FreqSumITRs_Harmonics2(1,2) = ITR;
load in_su01/forClassification_FreqSum_10s_HarmonicNum_2
FreqSumITRs_Harmonics2(1,1) = ITR;

load in_su03/forClassification_FreqSum_2p5s_HarmonicNum_2
FreqSumITRs_Harmonics2(2,4) = ITR;
load in_su03/forClassification_FreqSum_5s_HarmonicNum_2
FreqSumITRs_Harmonics2(2,3) = ITR;
load in_su03/forClassification_FreqSum_7p5s_HarmonicNum_2
FreqSumITRs_Harmonics2(2,2) = ITR;
load in_su03/forClassification_FreqSum_10s_HarmonicNum_2
FreqSumITRs_Harmonics2(2,1) = ITR;

load in_su04/forClassification_FreqSum_2p5s_HarmonicNum_2
FreqSumITRs_Harmonics2(3,4) = ITR;
load in_su04/forClassification_FreqSum_5s_HarmonicNum_2
FreqSumITRs_Harmonics2(3,3) = ITR;
load in_su04/forClassification_FreqSum_7p5s_HarmonicNum_2
FreqSumITRs_Harmonics2(3,2) = ITR;
load in_su04/forClassification_FreqSum_10s_HarmonicNum_2
FreqSumITRs_Harmonics2(3,1) = ITR;

load out_su08/forClassification_FreqSum_2p5s_HarmonicNum_2
FreqSumITRs_Harmonics2(4,4) = ITR;
load out_su08/forClassification_FreqSum_5s_HarmonicNum_2
FreqSumITRs_Harmonics2(4,3) = ITR;
load out_su08/forClassification_FreqSum_7p5s_HarmonicNum_2
FreqSumITRs_Harmonics2(4,2) = ITR;
load out_su08/forClassification_FreqSum_10s_HarmonicNum_2
FreqSumITRs_Harmonics2(4,1) = ITR;

load out_su10/forClassification_FreqSum_2p5s_HarmonicNum_2
FreqSumITRs_Harmonics2(5,4) = ITR;
load out_su10/forClassification_FreqSum_5s_HarmonicNum_2
FreqSumITRs_Harmonics2(5,3) = ITR;
load out_su10/forClassification_FreqSum_7p5s_HarmonicNum_2
FreqSumITRs_Harmonics2(5,2) = ITR;
load out_su10/forClassification_FreqSum_10s_HarmonicNum_2
FreqSumITRs_Harmonics2(5,1) = ITR;

load out_su11/forClassification_FreqSum_2p5s_HarmonicNum_2
FreqSumITRs_Harmonics2(6,4) = ITR;
load out_su11/forClassification_FreqSum_5s_HarmonicNum_2
FreqSumITRs_Harmonics2(6,3) = ITR;
load out_su11/forClassification_FreqSum_7p5s_HarmonicNum_2
FreqSumITRs_Harmonics2(6,2) = ITR;
load out_su11/forClassification_FreqSum_10s_HarmonicNum_2
FreqSumITRs_Harmonics2(6,1) = ITR;

FreqSumITRs_Harmonics2

FreqSumITRs_Harmonics3 = zeros(subNum,timeNum);
load in_su01/forClassification_FreqSum_2p5s_HarmonicNum_3
FreqSumITRs_Harmonics3(1,4) = ITR;
load in_su01/forClassification_FreqSum_5s_HarmonicNum_3
FreqSumITRs_Harmonics3(1,3) = ITR;
load in_su01/forClassification_FreqSum_7p5s_HarmonicNum_3
FreqSumITRs_Harmonics3(1,2) = ITR;
load in_su01/forClassification_FreqSum_10s_HarmonicNum_3
FreqSumITRs_Harmonics3(1,1) = ITR;

load in_su03/forClassification_FreqSum_2p5s_HarmonicNum_3
FreqSumITRs_Harmonics3(2,4) = ITR;
load in_su03/forClassification_FreqSum_5s_HarmonicNum_3
FreqSumITRs_Harmonics3(2,3) = ITR;
load in_su03/forClassification_FreqSum_7p5s_HarmonicNum_3
FreqSumITRs_Harmonics3(2,2) = ITR;
load in_su03/forClassification_FreqSum_10s_HarmonicNum_3
FreqSumITRs_Harmonics3(2,1) = ITR;

load in_su04/forClassification_FreqSum_2p5s_HarmonicNum_3
FreqSumITRs_Harmonics3(3,4) = ITR;
load in_su04/forClassification_FreqSum_5s_HarmonicNum_3
FreqSumITRs_Harmonics3(3,3) = ITR;
load in_su04/forClassification_FreqSum_7p5s_HarmonicNum_3
FreqSumITRs_Harmonics3(3,2) = ITR;
load in_su04/forClassification_FreqSum_10s_HarmonicNum_3
FreqSumITRs_Harmonics3(3,1) = ITR;

load out_su08/forClassification_FreqSum_2p5s_HarmonicNum_3
FreqSumITRs_Harmonics3(4,4) = ITR;
load out_su08/forClassification_FreqSum_5s_HarmonicNum_3
FreqSumITRs_Harmonics3(4,3) = ITR;
load out_su08/forClassification_FreqSum_7p5s_HarmonicNum_3
FreqSumITRs_Harmonics3(4,2) = ITR;
load out_su08/forClassification_FreqSum_10s_HarmonicNum_3
FreqSumITRs_Harmonics3(4,1) = ITR;

load out_su10/forClassification_FreqSum_2p5s_HarmonicNum_3
FreqSumITRs_Harmonics3(5,4) = ITR;
load out_su10/forClassification_FreqSum_5s_HarmonicNum_3
FreqSumITRs_Harmonics3(5,3) = ITR;
load out_su10/forClassification_FreqSum_7p5s_HarmonicNum_3
FreqSumITRs_Harmonics3(5,2) = ITR;
load out_su10/forClassification_FreqSum_10s_HarmonicNum_3
FreqSumITRs_Harmonics3(5,1) = ITR;

load out_su11/forClassification_FreqSum_2p5s_HarmonicNum_3
FreqSumITRs_Harmonics3(6,4) = ITR;
load out_su11/forClassification_FreqSum_5s_HarmonicNum_3
FreqSumITRs_Harmonics3(6,3) = ITR;
load out_su11/forClassification_FreqSum_7p5s_HarmonicNum_3
FreqSumITRs_Harmonics3(6,2) = ITR;
load out_su11/forClassification_FreqSum_10s_HarmonicNum_3
FreqSumITRs_Harmonics3(6,1) = ITR;

FreqSumITRs_Harmonics3

FreqSumITRs_Harmonics4 = zeros(subNum,timeNum);
load in_su01/forClassification_FreqSum_2p5s_HarmonicNum_4
FreqSumITRs_Harmonics4(1,4) = ITR;
load in_su01/forClassification_FreqSum_5s_HarmonicNum_4
FreqSumITRs_Harmonics4(1,3) = ITR;
load in_su01/forClassification_FreqSum_7p5s_HarmonicNum_4
FreqSumITRs_Harmonics4(1,2) = ITR;
load in_su01/forClassification_FreqSum_10s_HarmonicNum_4
FreqSumITRs_Harmonics4(1,1) = ITR;

load in_su03/forClassification_FreqSum_2p5s_HarmonicNum_4
FreqSumITRs_Harmonics4(2,4) = ITR;
load in_su03/forClassification_FreqSum_5s_HarmonicNum_4
FreqSumITRs_Harmonics4(2,3) = ITR;
load in_su03/forClassification_FreqSum_7p5s_HarmonicNum_4
FreqSumITRs_Harmonics4(2,2) = ITR;
load in_su03/forClassification_FreqSum_10s_HarmonicNum_4
FreqSumITRs_Harmonics4(2,1) = ITR;

load in_su04/forClassification_FreqSum_2p5s_HarmonicNum_4
FreqSumITRs_Harmonics4(3,4) = ITR;
load in_su04/forClassification_FreqSum_5s_HarmonicNum_4
FreqSumITRs_Harmonics4(3,3) = ITR;
load in_su04/forClassification_FreqSum_7p5s_HarmonicNum_4
FreqSumITRs_Harmonics4(3,2) = ITR;
load in_su04/forClassification_FreqSum_10s_HarmonicNum_4
FreqSumITRs_Harmonics4(3,1) = ITR;

load out_su08/forClassification_FreqSum_2p5s_HarmonicNum_4
FreqSumITRs_Harmonics4(4,4) = ITR;
load out_su08/forClassification_FreqSum_5s_HarmonicNum_4
FreqSumITRs_Harmonics4(4,3) = ITR;
load out_su08/forClassification_FreqSum_7p5s_HarmonicNum_4
FreqSumITRs_Harmonics4(4,2) = ITR;
load out_su08/forClassification_FreqSum_10s_HarmonicNum_4
FreqSumITRs_Harmonics4(4,1) = ITR;

load out_su10/forClassification_FreqSum_2p5s_HarmonicNum_4
FreqSumITRs_Harmonics4(5,4) = ITR;
load out_su10/forClassification_FreqSum_5s_HarmonicNum_4
FreqSumITRs_Harmonics4(5,3) = ITR;
load out_su10/forClassification_FreqSum_7p5s_HarmonicNum_4
FreqSumITRs_Harmonics4(5,2) = ITR;
load out_su10/forClassification_FreqSum_10s_HarmonicNum_4
FreqSumITRs_Harmonics4(5,1) = ITR;

load out_su11/forClassification_FreqSum_2p5s_HarmonicNum_4
FreqSumITRs_Harmonics4(6,4) = ITR;
load out_su11/forClassification_FreqSum_5s_HarmonicNum_4
FreqSumITRs_Harmonics4(6,3) = ITR;
load out_su11/forClassification_FreqSum_7p5s_HarmonicNum_4
FreqSumITRs_Harmonics4(6,2) = ITR;
load out_su11/forClassification_FreqSum_10s_HarmonicNum_4
FreqSumITRs_Harmonics4(6,1) = ITR;

FreqSumITRs_Harmonics4

FreqSumITRs_Harmonics5 = zeros(subNum,timeNum);
load in_su01/forClassification_FreqSum_2p5s_HarmonicNum_5
FreqSumITRs_Harmonics5(1,4) = ITR;
load in_su01/forClassification_FreqSum_5s_HarmonicNum_5
FreqSumITRs_Harmonics5(1,3) = ITR;
load in_su01/forClassification_FreqSum_7p5s_HarmonicNum_5
FreqSumITRs_Harmonics5(1,2) = ITR;
load in_su01/forClassification_FreqSum_10s_HarmonicNum_5
FreqSumITRs_Harmonics5(1,1) = ITR;

load in_su03/forClassification_FreqSum_2p5s_HarmonicNum_5
FreqSumITRs_Harmonics5(2,4) = ITR;
load in_su03/forClassification_FreqSum_5s_HarmonicNum_5
FreqSumITRs_Harmonics5(2,3) = ITR;
load in_su03/forClassification_FreqSum_7p5s_HarmonicNum_5
FreqSumITRs_Harmonics5(2,2) = ITR;
load in_su03/forClassification_FreqSum_10s_HarmonicNum_5
FreqSumITRs_Harmonics5(2,1) = ITR;

load in_su04/forClassification_FreqSum_2p5s_HarmonicNum_5
FreqSumITRs_Harmonics5(3,4) = ITR;
load in_su04/forClassification_FreqSum_5s_HarmonicNum_5
FreqSumITRs_Harmonics5(3,3) = ITR;
load in_su04/forClassification_FreqSum_7p5s_HarmonicNum_5
FreqSumITRs_Harmonics5(3,2) = ITR;
load in_su04/forClassification_FreqSum_10s_HarmonicNum_5
FreqSumITRs_Harmonics5(3,1) = ITR;

load out_su08/forClassification_FreqSum_2p5s_HarmonicNum_5
FreqSumITRs_Harmonics5(4,4) = ITR;
load out_su08/forClassification_FreqSum_5s_HarmonicNum_5
FreqSumITRs_Harmonics5(4,3) = ITR;
load out_su08/forClassification_FreqSum_7p5s_HarmonicNum_5
FreqSumITRs_Harmonics5(4,2) = ITR;
load out_su08/forClassification_FreqSum_10s_HarmonicNum_5
FreqSumITRs_Harmonics5(4,1) = ITR;

load out_su10/forClassification_FreqSum_2p5s_HarmonicNum_5
FreqSumITRs_Harmonics5(5,4) = ITR;
load out_su10/forClassification_FreqSum_5s_HarmonicNum_5
FreqSumITRs_Harmonics5(5,3) = ITR;
load out_su10/forClassification_FreqSum_7p5s_HarmonicNum_5
FreqSumITRs_Harmonics5(5,2) = ITR;
load out_su10/forClassification_FreqSum_10s_HarmonicNum_5
FreqSumITRs_Harmonics5(5,1) = ITR;

load out_su11/forClassification_FreqSum_2p5s_HarmonicNum_5
FreqSumITRs_Harmonics5(6,4) = ITR;
load out_su11/forClassification_FreqSum_5s_HarmonicNum_5
FreqSumITRs_Harmonics5(6,3) = ITR;
load out_su11/forClassification_FreqSum_7p5s_HarmonicNum_5
FreqSumITRs_Harmonics5(6,2) = ITR;
load out_su11/forClassification_FreqSum_10s_HarmonicNum_5
FreqSumITRs_Harmonics5(6,1) = ITR;

FreqSumITRs_Harmonics5

save lookAtCCAITRs ITRs_Harmonics2 FreqSumITRs_Harmonics2 ...
    ITRs_Harmonics3 FreqSumITRs_Harmonics3 ...
    ITRs_Harmonics4 FreqSumITRs_Harmonics4 ...
    ITRs_Harmonics5 FreqSumITRs_Harmonics5

