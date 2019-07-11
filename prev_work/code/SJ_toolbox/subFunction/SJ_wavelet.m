function [waveletResult] = SJ_wavelet(param, data)
m = 7; ki = 5;
for subjectNum = 1:size(data,1)
    for channelNum = 1:size(data,2)
        for freqNum = 1:length(param.freqs)
            f0	=	param.freqs(freqNum);
            SD_t	=	m/(2*pi*f0);
            t		=	0:(1/param.fs):(ki*SD_t);
            t		=	[-t(end:-1:2), t];
            A		=	1/sqrt(SD_t*sqrt(pi));
            w		=	A .* exp(-t.^2 /(2*SD_t.^2)) .* exp(1i*2*pi*f0 .* t);
            tfcomplex = conv(squeeze(data(subjectNum, channelNum, :)),w,'same')/param.fs;
            waveletResult(subjectNum,channelNum,:,freqNum) = tfcomplex .* conj(tfcomplex);
        end
    end
end
end