clear;

filePath = './data/monthly_data.xlsx';
outputFile = './results/summary.xlsx';
gdp = xlsread(filePath, 'macro', 'b33:b357'); % 1992:03-2019:03, seasonly
cpi = xlsread(filePath, 'macro', 'c7:c357'); % 1990:01-2019:03, monthly
ppi = xlsread(filePath, 'macro', 'd88:d357'); % 1996:10-2019:03, monthly
une = xlsread(filePath, 'macro', 'e162:e357'); % 2002:12-2019:03, seasonly
M2 = xlsread(filePath, 'macro', 'f78:f357'); % 1995:12-2019:03, monthly
keqiang = xlsread(filePath, 'macro', 'g241:g357'); % 2009:07-2019:03, monthly
ip = xlsread(filePath, 'macro', 'h7:h357'); % 1990:01-2019:03, monthly

% load data: 1988:06-2019:03
oil = xlsread(filePath, 'oil_last', 'f463:f832');
L = 6;
period = size(oil, 1);
oil_L = nan(period - (L - 1), 1);

for t = L:period
    oil_t = oil(t - (L - 1):t, 1);
    oil_L(t - (L - 1), 1) = mean(oil_t);
end

summary_table_marco = nan(7, 3);

x = log(oil_L(49 - (L - 1):3:end) ./ oil_L(46 - (L - 1):3:end - 3));
y = log(gdp(4:3:end) ./ gdp(1:3:end - 3));
summary_table_marco(1, :) = ols_summary(y, x);

x = log(oil_L(20 - (L - 1):end) ./ oil_L(19 - (L - 1):end - 1));
y = cpi / 100;
summary_table_marco(2, :) = ols_summary(y, x);

x = log(oil_L(101 - (L - 1):end) ./ oil_L(100 - (L - 1):end - 1));
y = ppi / 100;
summary_table_marco(3, :) = ols_summary(y, x);

x = log(oil_L(175 - (L - 1):3:end) ./ oil_L(172 - (L - 1):3:end - 3));
y = une(1:3:end) / 100;
summary_table_marco(4, :) = ols_summary(y, x);

x = log(oil_L(92 - (L - 1):end) ./ oil_L(91 - (L - 1):end - 1));
y = log(M2(2:end) ./ M2(1:end - 1));
summary_table_marco(5, :) = ols_summary(y, x);

x = log(oil_L(254 - (L - 1):end) ./ oil_L(253 - (L - 1):end - 1));
y = keqiang / 100;
summary_table_marco(6, :) = ols_summary(y, x);

x = log(oil_L(20 - (L - 1):end) ./ oil_L(19 - (L - 1):end - 1));
y = ip / 100;
summary_table_marco(7, :) = ols_summary(y, x);

xlswrite(outputFile, summary_table_marco, 'macro', 'c3')

earnings = xlsread(filePath, 'earnings', 'b2:u73'); % 2001:06-2019:03, seasonly
summary_fundamental = nan(size(earnings, 2) + 1, 3);
x = log(oil_L(160 - (L - 1):3:end) ./ oil_L(157 - (L - 1):3:end - 3));

for i = 1:size(earnings, 2)
    y = log(earnings(2:end, i) ./ earnings(1:end - 1, i));
    summary_fundamental(i, :) = ols_summary(y, x);
end

marketEarn = xlsread(filePath, 'earnings', 'v18:v73'); % 2005:06-2019:03, seasonly
x = log(oil_L(208 - (L - 1):3:end) ./ oil_L(205 - (L - 1):3:end - 3));
y = log(marketEarn(2:end) ./ marketEarn(1:end - 1));
summary_fundamental(end, :) = ols_summary(y, x);

xlswrite(outputFile, summary_fundamental, 'macro', 'c11')

% control market earnings
summary_regression_data(L);
load('regression_data.mat');
x1 = log(oil_L(208 - (L - 1):3:end) ./ oil_L(205 - (L - 1):3:end - 3));
x2 = log(marketEarn(2:end) ./ marketEarn(1:end - 1));
y = y_h(51:3:end, :, 1);
test_results = nan(size(y, 2), 5);

for k = 1:size(y, 2)
    X_k = [ones(size(x1, 1), 1), x1, x2];
    y_k = y(2:end, k);
    results_k = ols(y_k, X_k);
    p_value_1 = 2 * normcdf(-abs(results_k.tstat(2))); % oil
    p_value_2 = 2 * normcdf(-abs(results_k.tstat(3))); % earnings
    test_results(k, :) = [results_k.beta(2) p_value_1 ...
                        results_k.beta(3) p_value_2 results_k.rsqr * 100];
end

xlswrite(outputFile, test_results, 'control_var', 'b3');

% business cycle
% GDP
x1 = log(gdp(112:3:end) ./ gdp(109:3:end - 3));
x2 = log(oil_L(157 - (L - 1):3:end) ./ oil_L(154 - (L - 1):3:end - 3));
y = y_h(3:3:end, :, 1);
summary_business_cycle_1 = ols_summary2(y, x1, x2);
xlswrite(outputFile, summary_business_cycle_1, 'business_cycle', 'b3');

% IP
x1 = ip(136:end) / 100;
x2 = log(oil_L(155 - (L - 1):end) ./ oil_L(154 - (L - 1):end - 1));
y = y_h(:, :, 1);
summary_business_cycle_2 = ols_summary2(y, x1, x2);
xlswrite(outputFile, summary_business_cycle_2, 'business_cycle', 'f3');

function summary = ols_summary(y, x)
    % this function is used to do ols and return summary details
    x = x(isfinite(y));
    y = y(isfinite(y));
    X = [ones(size(x, 1), 1) x];
    result = ols(y, X);
    coeff = result.beta(2);
    p_val = 2 * normcdf(-abs(result.tstat(2)));
    rsqr = result.rsqr * 100;
    summary = [coeff p_val rsqr];
end

function summary = ols_summary2(y, x1, x2)
    summary = nan(size(y, 2), 4);
    for k = 1:size(y, 2)
        X_k = [ones(size(x1, 1), 1), x1];
        y_k = y(2:end, k);
        X_k = X_k(isfinite(y_k), :);
        y_k = y_k(isfinite(y_k));
        results_k = ols(y_k, X_k);
        p_value = 2 * normcdf(-abs(results_k.tstat(2)));
        summary(k, 1:2) = [results_k.beta(2) p_value];

        X_k = [ones(size(x1, 1), 1), x1, x2];
        y_k = y(2:end, k);
        X_k = X_k(isfinite(y_k), :);
        y_k = y_k(isfinite(y_k));
        results_k = ols(y_k, X_k);
        p_value_1 = 2 * normcdf(-abs(results_k.tstat(2)));
        summary(k, 3:4) = [results_k.beta(2) p_value_1];
    end
end
