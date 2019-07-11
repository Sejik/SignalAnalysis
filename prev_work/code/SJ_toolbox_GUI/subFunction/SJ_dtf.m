function [dtfResult] = SJ_dtf(param, data)
nreps = param.surrogateNum;
tvalue = 0.05;
tot_range = param.individualFreq{1}(1):1:param.individualFreq{size(param.individualFreq,2)}(2);
nfreq = length(tot_range);
    
for subjectNum = 1:size(data,1)
    roiData = squeeze(data(subjectNum, :, :));
    ts = shiftdim(roiData,1);
    nchan = size(ts,2);
    % optimal order calculation
    sbc_error = zeros(1,20);
    for i = 1:20
        [~,~,~,SBC,~] = arfit(ts,i,i);
        sbc_error(i) = SBC;
    end
    optimalorder = find(sbc_error == min(sbc_error),1);
    dt = 1/param.fs;
    % compute DTF
    
    [~,A] = arfit(ts,optimalorder, optimalorder);
    gamma2 = dtfCalc(A, tot_range, nfreq, nchan, dt, optimalorder);
    dtfmatrixs = gamma2;
    % surrogated calculation
    % basic variable
    sig_size = floor(tvalue * nreps)+1;
    new_gamma = zeros(sig_size-1,nchan,nchan,nfreq);
    % compute significant test
    newts = zeros(size(ts));
    for m=1:nreps
        for n=1:nchan
            Y = fft(ts(:,n));
            Pyy = sqrt(Y.*conj(Y));
            Phyy = Y./Pyy;
            index = 1:size(ts,1);
            index = surrogate(index);
            Y = Pyy.*Phyy(index);
            newts(:,n) = real(ifft(Y));
        end
        [~,A] = arfit(newts,optimalorder, optimalorder);
        gamma2 = dtfCalc(A, tot_range, nfreq, nchan, dt, optimalorder);
        new_gamma(sig_size,:,:,:) = gamma2;
        new_gamma = sort(new_gamma,'descend');
        new_gamma(sig_size,:,:,:) = [];
    end
    new_gamma2 = zeros(nchan,nchan,nfreq);
    for i = 1:nchan
        for j = 1:nchan
            for k = 1:nfreq
                new_gamma2(i,j,k) = new_gamma(sig_size-1,i,j,k);
            end
        end
    end
    sig_dtfmatrix = new_gamma2;
    gamma2 = DTFsigtest(dtfmatrixs, sig_dtfmatrix);
    dtfResult(subjectNum, :,:,:) = permute(gamma2, [3, 1, 2]);
end
end

function [gamma2] = dtfCalc(A, tot_range, nfreq, nchan, dt, optimalorder)
B = [];
B(:,:,1) = -eye(nchan);
for i=1:nchan
    for j=1:nchan
        B(i,j,2:optimalorder+1) = A(i,j:nchan:nchan*optimalorder);
    end
end
theta2 = [];
for k = 1:nfreq
    Af = zeros(nchan,nchan);
    fre = tot_range(k);
    for i = 1:nchan
        for j = 1:nchan
            for h = 1:optimalorder+1
                Af(i,j) = Af(i,j)-B(i,j,h)*exp(-pi*fre*dt*(h-1)*2i);
            end
        end
    end
    dett2 = det(Af);
    dett2 = dett2.*conj(dett2);
    for i = 1:nchan
        for j = 1:nchan
            Apf = Af;
            Apf(:,i) = [];
            Apf(j,:) = [];
            det2 = det(Apf);
            det2 = det2.*conj(det2);
            theta2(i,j,k) = det2/dett2;
        end
    end
end
gamma2 = [];
for k=1:nfreq
    for i=1:nchan
        for j=1:nchan
            gamma2(i,j,k) = theta2(i,j,k) / sum(theta2(i,:,k),2);
        end
    end
end
end