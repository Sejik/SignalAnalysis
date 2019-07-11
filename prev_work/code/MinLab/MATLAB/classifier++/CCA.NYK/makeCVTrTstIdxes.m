function makeCVTrTstIdxes(CVNum, datanumPerClass)
% Src Cdoe: 1311130002
% makeCVTrTstIdxes(5,80)
% makeCVTrTstIdxes(8,80)

TstDataNumPerCV = floor(datanumPerClass/CVNum);
TrIdxes = zeros(CVNum, TstDataNumPerCV*(CVNum - 1));
TstIdxes = zeros(CVNum, TstDataNumPerCV);
for icnt = 1:CVNum
    TrIdxes(icnt,:) = [1:(icnt-1)*TstDataNumPerCV icnt*TstDataNumPerCV+1:CVNum*TstDataNumPerCV];
    TstIdxes(icnt,:) = (icnt-1)*TstDataNumPerCV+1:icnt*TstDataNumPerCV;
end

saveFileName = 'trainTestIndex';
save(saveFileName, 'TrIdxes', 'TstIdxes', 'CVNum', 'datanumPerClass');
