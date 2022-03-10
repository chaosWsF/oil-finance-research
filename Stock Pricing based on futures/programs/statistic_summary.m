clear;

L = 6;
input_file = './data/monthly_data.xlsx';
outputFile = './results/summary.xlsx';
oil_index = sprintf("e%d:e832", 617 - L);
oilData = xlsread(input_file, 'oil_last', oil_index);
oil_all_index = sprintf("b%d:h832", 617 - L);
oilAllData = xlsread(input_file, 'oil_last', oil_all_index);
stockData = xlsread(input_file, 'stock', 'c126:w341');
marketCapData = xlsread(input_file, 'market_cap', 'b2:u4388');
r_stock = log(stockData);
summary_regression_data(L);
load('regression_data.mat');

summary_oil = summaryX(oilData);
summary_stock = summaryX(r_stock);
summary_oil_trend = summaryX(x_L);
xlswrite(outputFile, summary_stock, 'stat', 'b2');

covmat = nancov(r_stock);
corrmat = corrcov(covmat);
xlswrite(outputFile, corrmat, 'corr', 'b2');

summaryAuto_oil = autocorrX(oilData);
summaryAuto_stock = autocorrX(stockData);
summaryAuto_oil_trend = autocorrX(x_L);
xlswrite(outputFile, summaryAuto_oil, 'autocorr', 'b2');
xlswrite(outputFile, summaryAuto_oil_trend, 'autocorr', 'b3');
xlswrite(outputFile, summaryAuto_stock, 'autocorr', 'b4');

sumCap = sum(marketCapData, 2);
capProp = marketCapData ./ sumCap;
marketCap = mean(capProp, 1);
xlswrite(outputFile, marketCap', 'stat', 'k3');

oil_period = size(oilAllData, 1);
x_L = nan(oil_period - (L - 1), size(oilAllData, 2));

for t = L:oil_period
    x_t = oilAllData(t - (L - 1):t, :);
    x_L(t - (L - 1), :) = mean_without_nan(x_t);
end

x_L = log(x_L(2:end, :)) - log(x_L(1:end - 1, :));
x_L = x_L(:, [2, 4, 7]); % rm oil commodity
summary_all_oil = summaryX(x_L);
covmat = nancov(x_L);
corrmat = corrcov(covmat);
xlswrite(outputFile, summary_all_oil', 'oil_trend_stat', 'b3');
xlswrite(outputFile, corrmat, 'oil_trend_stat', 'b13');


function summ_stats = summaryX(dat)
    % calculate the statstics summary on data
    summ_stats = nan(size(dat, 2), 7);
    summ_stats(:, 1) = nanmean(dat)'; % Mean
    summ_stats(:, 2) = nanmedian(dat)'; % Median
    summ_stats(:, 3) = nanmax(dat)'; % Max
    summ_stats(:, 4) = nanmin(dat)'; % Min
    summ_stats(:, 5) = nanstd(dat)'; % Std
    summ_stats(:, 6) = kurtosis(dat)'; % Kurtosis
    summ_stats(:, 7) = skewness(dat)'; % Skewness
end

function autocorr_mat = autocorrX(dat)
    % calculate the coefficient of first-order autocorrelation on data
    lags = [1, 3, 6, 12, 24, 36];
    autocorr_mat = nan(size(dat, 2), length(lags));
    nlags = max(lags);

    for col = 1:size(dat, 2)
        acf = autocorr(dat(:, col), 'NumLags', nlags);
        acf = acf(2:end);

        for l = 1:length(lags)
            autocorr_mat(col, l) = acf(lags(l));
        end

    end

end
