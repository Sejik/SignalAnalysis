function z = p2z(pvals)

if any(pvals > 1)
    error('p-values should be between 0 and 1!');
end

if any(pvals < 0)
    error('p-values should be between 0 and 1!');
end

z = abs(norminv(pvals / 2));
