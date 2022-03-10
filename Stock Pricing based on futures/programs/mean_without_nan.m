function Xmean = mean_without_nan(X)
    % This function can calculate the mean of a matrix without its nan values.
    % The mean is calculated by row (DIM = 1);
    % And the number of nonan values are used to calculate the mean.
    if size(X, 1) ~= 1
        num = sum(isfinite(X));
        SX = sum(X, 'omitnan');
        Xmean = SX ./ num;
    else
        Xmean = X;
    end
