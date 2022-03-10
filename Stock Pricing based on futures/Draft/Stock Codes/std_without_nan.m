function Xstd=std_without_nan(X)
    num = sum(isfinite(X));
    Xmean = mean_without_nan(X);
    X2mean = mean_without_nan(X.^2);
    Xstd = sqrt(num * (X2mean - Xmean^2) / (num-1));
