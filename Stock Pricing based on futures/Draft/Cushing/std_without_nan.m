function Xstd = std_without_nan(X)
    % This function can calculate the std of a matrix without its nan values.
    % The std is calculated by row (DIM = 1);
    % And the number of nonan values are used to calculate the std.
    num = sum(isfinite(X));
    Xmean = mean_without_nan(X);
    X2mean = mean_without_nan(X.^2);
    Xstd = sqrt(num * (X2mean - Xmean^2) / (num - 1));
