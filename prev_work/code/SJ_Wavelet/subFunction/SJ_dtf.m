function [dtfResult] = SJ_dtf(param, data)
for subjectNum = 1:size(data,1)
    tot_range = param.interestFreq(1):param.interestFreq(2);
    roiData = squeeze(data(subjectNum, :, :));
    nfre = length(tot_range);
    ts = shiftdim(roiData,1);
    nchan = size(ts,2);
    % optimal order calculation
    fpe_error = [];
    sbc_error = [];
    j = 1;
    for i = 1:20
        [~,~,~,SBC,FPE] = arfit(ts,i,i);
        fpe_error(j) = real(FPE);
        sbc_error(j) = SBC;
        j = j+1;
    end
    minsbc = min(sbc_error);
    sbc_optorder = find(sbc_error == minsbc,1);
    optimalorder = sbc_optorder;
    % compute DTF
    dt = 1/param.fs;
    [~,A] = arfit(ts,optimalorder, optimalorder);
    B = [];
    B(:,:,1) = -eye(nchan);
    for i=1:nchan
        for j=1:nchan
            B(i,j,2:optimalorder+1) = A(i,j:nchan:nchan*optimalorder);
        end
    end
    theta2 = [];
    for k = 1:nfre
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
    for k=1:nfre
        for i=1:nchan
            for j=1:nchan
                gamma2(i,j,k) = theta2(i,j,k) / sum(theta2(i,:,k),2);
            end
        end
    end
    dtfmatrixs = gamma2;
    % surrogated calculation
    % basic variable
    nreps = param.surrogateNum;
    tvalue = 0.05;
    tot_range = param.interestFreq(1):1:param.interestFreq(2);
    nfreq = length(tot_range);
    sig_size = floor(tvalue * nreps)+1;
    new_gamma = zeros(sig_size-1,nchan,nchan,nfreq);
    % compute significant test
    for m=1:nreps
        for n=1:nchan
            Y = fft(ts(:,j));
            Pyy = sqrt(Y.*conj(Y));
            Phyy = Y./Pyy;
            index = 1:size(ts,1);
            index = surrogate(index);
            Y = Pyy.*Phyy(index);
            newts(:,j) = real(ifft(Y));
        end
        dt = 1/param.fs;
        [~,A] = arfit(newts,optimalorder, optimalorder);
        B = [];
        B(:,:,1) = -eye(nchan);
        for i=1:nchan
            for j=1:nchan
                B(i,j,2:optimalorder+1) = A(i,j:nchan:nchan*optimalorder);
            end
        end
        theta2 = [];
        for k = 1:nfre
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
        for k=1:nfre
            for i=1:nchan
                for j=1:nchan
                    gamma2(i,j,k) = theta2(i,j,k) / sum(theta2(i,:,k),2);
                end
            end
        end
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