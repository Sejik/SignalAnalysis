function [fftResult] = SJ_fft(param, data)
fftData = fft(data,[],3);
for subjectNum = 1:size(data,1)
    for channelNum = 1:size(data,2)
        Y = fftData(subjectNum, channelNum,:);
        L = length(Y);
        P2 = abs(Y/L);
        P1 = P2(1:(floor(L/2)+1));
        P1(2:end-1) = 2*P1(2:end-1);
        f = param.fs*(0:(L/2))/L;
        for interpolationNum = 1:length(param.freqs)
            interestFreqBelow = find(f <= param.freqs(interpolationNum), 1, 'last');
            interestFreqOver = find(f >= param.freqs(interpolationNum), 1, 'first');
            interpolatedP1(interpolationNum) = (f(interestFreqBelow)*P1(interestFreqOver)+f(interestFreqOver)*...
                P1(interestFreqBelow))/(f(interestFreqBelow)+f(interestFreqOver));     
        end
        fftResult(subjectNum,channelNum, :) = interpolatedP1;
    end
end
end