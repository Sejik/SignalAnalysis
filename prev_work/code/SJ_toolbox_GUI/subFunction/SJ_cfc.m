function [cfcResult] = SJ_cfc(param, data)
for subjectNum = 1:size(data,1)
    F = squeeze(data(subjectNum,:,:));
    [nSignals, nTime] = size(F);
    bandNesting = param.phaseBand;
    bandNested = param.amplitudeBand;
    fmin = min(bandNesting);
    sRate = param.fs; 
    fmax = sRate/3;
    numfreqs = round(sRate/9);
    fstep = 0.75;
    temp1 = (0:numfreqs-1) * fstep;
    temp2 = logspace(log10(fmin), log10(fmax), numfreqs);
    temp2 = (temp2-temp2(1)) * ((temp2(end)-temp1(end)) / temp2(end)) + temp2(1);
    chirpCenterFreqs = temp1 + temp2;
    chirpCenterFreqs(chirpCenterFreqs > max(bandNested)) = [];
    chirpCenterFreqs((chirpCenterFreqs < min(bandNested)) & (chirpCenterFreqs >= max(bandNesting))) = [];
    hfreq = find( chirpCenterFreqs >= min(bandNested));
    lfreq = find(chirpCenterFreqs < max(bandNesting));
    
    [chirpF, Freqs] = bst_chirplet(sRate, nTime, chirpCenterFreqs);
    
    bandLow  = min(bandNesting(1)*.5, sRate/2);
    bandHigh = min(bandNested(end)*1.5, sRate/2 - min(20, sRate/2 * 0.2) - 1);
    F = bst_bandpass_fft(F, sRate, bandLow, bandHigh);
    
    F_fft = fft(F, length(Freqs), 2);
    F_fft(:,Freqs<0) = 0;
    F_fft(:,Freqs>0) = 2 * F_fft(:,Freqs>0);
    
    [~,scol] = find(F_fft ~= 0);
    scol = max(scol)+1;
    [chirprow,~] = find(squeeze(chirpF(1,:,:)) ~= 0);
    chirprow = max(chirprow)+1;
    % Minimal number of frequency coefficients
    nfcomponents = min(chirprow,scol);
    
    F_fft = bsxfun(@times, F_fft(:, 1:nfcomponents, ones(1,length(chirpCenterFreqs))), ...
        chirpF(1,1:nfcomponents,:));
    fs = ifft(F_fft, length(Freqs), 2);
    
    AMP = abs( fs(:, 1:nTime, hfreq ) );
    PHASE = exp(1i * angle( fs(:, 1:nTime, lfreq)));
    
    DirectPAC = zeros(nSignals, length(lfreq), length(hfreq));
    for ihf = 1:length(hfreq)
        DirectPAC(:,:,ihf) = reshape(sum(bsxfun(@times, PHASE, AMP(:,:,ihf)), 2 ), [nSignals, length(lfreq)]);
    end
    
    tmp2 = sqrt( ( sum(AMP.*AMP, 2) ) );
    DirectPAC = abs(DirectPAC) ./ tmp2(:,ones(1,size(DirectPAC,2)),:);
    DirectPAC = DirectPAC / sqrt(nTime);
    LowFreqs  = chirpCenterFreqs(lfreq);
    HighFreqs = chirpCenterFreqs(hfreq);
    invalidMask = double(repmat(HighFreqs, length(LowFreqs), 1) > 2 * repmat(LowFreqs', 1, length(HighFreqs)));
    invalidMask = reshape(invalidMask, 1, size(invalidMask,1), size(invalidMask,2));
    DirectPAC = bsxfun(@times, DirectPAC, invalidMask);
    cfcResult(subjectNum,:,:,:) = DirectPAC;
end
end

function [chirpF, Freqs] = bst_chirplet(sRate, nTime, chirpCenterFreqs)
if (nTime > 2^23)
    nFreq = nTime;
else
    nFreq = 2^ceil(log2(nTime)); 
end
Freqs = (sRate/nFreq) * (0:nFreq-1);
inds = Freqs > (sRate/2);
Freqs(inds) = Freqs(inds) - sRate;
chirpF = zeros(1, nFreq, length(chirpCenterFreqs));
fbw = 0.15; 
for iif = 1:length(chirpCenterFreqs)
    v0 = chirpCenterFreqs(iif);
    c0 = 0;
    s0 = log((2*log(2)) / (fbw^2*pi*v0^2));
    std_multiple = 6;
    vstd = sqrt((exp(-s0) + c0^2*exp(s0)) / (4*pi));
    v = Freqs;
    iFreq = find(...
        (v0 - std_multiple * vstd <= v) & ...
        (v <= v0 + std_multiple * vstd));
    v = v(iFreq);
    Gk = 2^(1/4)*sqrt(-1i*c0+exp(-s0))^-1 * exp(-s0/4 + (exp(s0)*pi*(v-v0).^2)/(-1+1i*c0*exp(s0)));
    n1 = sqrt(length(Freqs)) / norm(Gk);
    Gk = n1 * Gk;
    chirpF(1, iFreq, iif) = Gk;
end
end

function x = bst_bandpass_fft(x, Fs, HighPass, LowPass)
Norig = size(x,2);
Nmirror = Norig;
Fnorm = Fs/2;
if rem(size(x,2),2)
    if (Nmirror == Norig)
        x = [x(:,Nmirror:-1:1), x, x(:,end:-1:end-Nmirror+2)];
    else
        x = [x(:,Nmirror:-1:1), x, x(:,end:-1:end-Nmirror)];
    end
else
    x = [x(:,Nmirror:-1:1), x, x(:,end:-1:end-Nmirror+1)];
end
HighStop = HighPass - min(2, HighPass / 2);
LowStop = LowPass + min(10, LowPass * 0.2);
N = size(x,2);
fir2fcn = @fir2; % fir2fcn = @oc_fir2;
H = fir2fcn(N-1, [0 HighStop HighPass LowPass LowStop Fnorm] ./ Fnorm, [0 0 1 1 0 0]);
H = abs(fft(H));
H(1) = 0;
H(end) = 0;
x = real(ifft(bsxfun(@times, fft(x,[],2), H),[],2));
x = x(:,Nmirror + (1:Norig));
end