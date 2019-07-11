function p = z2p(zvals)

p = normcdf(-abs(zvals), 0, 1) .* 2;
