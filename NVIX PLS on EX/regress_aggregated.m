% load data
data_NVIX = readtable("./data/nvix_and_categories_timeseries_mar2016.xlsx", 'Sheet', 2);
data_NVIX.Date = datetime(string(data_NVIX.Date), 'InputFormat', "yyyyMMdd");
data_EX = readtable("./data/Belt_Road_EX_monthly.xlsx", 'Sheet', 2);
data_EX.Date = datetime(string(data_EX.Date), 'InputFormat', "yyyyMMdd");

% set range of time and used country
period = [datetime(2000, 1, 31) datetime(2016, 3, 31)];
country = 2:45;
fix_rate_country = [2 6 15 16 22 26 30 31 35 39];
rm_country = [21 17 9 42 32 45 13];
country = setdiff(country, [fix_rate_country rm_country]);
disp(data_EX.Properties.VariableNames(fix_rate_country) + " fix rate")
country_names = data_EX.Properties.VariableNames(country);
trange_D = isbetween(data_NVIX.Date, period(1), period(2));
NVIX = data_NVIX(trange_D, 2).Variables;
D = data_NVIX(trange_D, 3:end).Variables;
trange_r = isbetween(data_EX.Date, period(1), dateshift(period(2), 'end', 'month', 1));
EX = data_EX(trange_r, country).Variables;

% calculate EX return
% r = log(EX(2:end, :) ./ EX(1:end-1, :));
r = EX(2:end, :) ./ EX(1:end-1, :) - 1;

% remove NaN and normalize disaster indicators
[D, nan_index] = rmmissing(D, 1);
[T, N] = size(D);
D = normalize(D);
r = r(~nan_index, :);
missing_data_index = any(isnan(r));
if ~isempty(r(:, missing_data_index))
    r = r(:, ~missing_data_index);
    disp(country_names(missing_data_index) + " data are missing")
    country_names = country_names(~missing_data_index);
end

% D_agg = NVIX(~nan_index, 1);
% D_agg = mean(D, 2);
D_pca = pca(D);
D_agg = D * D_pca(:, 1);

R = 6 * 12;
P = T - R;    % OOS period
results = NaN(size(r, 2), 3);    % beta, pVal, rsqr(%)
results_oos = NaN(size(r, 2), 2);    % rsqr_oos(%), cwstat

tic;
parfor j=1:size(r, 2)
    r_j = r(:, j);
    
    % in-sample
    md = fitlm(D_agg, r_j);
    beta = md.Coefficients.Estimate(2);
    rsqr = md.Rsquared.Ordinary * 100;
    
    % modified pairs bootstrapping (flachaire1999)
    B = 2000;
    tstat0 = nw_tstat(D_agg, r_j);
    alpha = regress(r_j, ones(size(r_j)));
    resid = md.Residuals.Raw;
    rng('default');    % for reproducibility
    tstat_boot = bootstrp(B, @(u)nw_tstat(D_agg, alpha + u), resid);
    if tstat0 >= 0
        pVal = sum(tstat_boot > tstat0) / B;
    else
        pVal = sum(tstat_boot < tstat0) / B;
    end
    results(j, :) = [beta pVal rsqr];
    
    % out-of-sample
    FC_val = NaN(P, 1);
    FC_base = zeros(P, 1);    % random walk for EX
    for p=1:P
        X = [ones(R+p-1, 1) D_agg(1:R+p-1)];
        y = r_j(1:R+p-1);
        FC_val(p) = [1 D_agg(R+p)] * regress(y, X);
    end
    u_val = r_j(R+1:end) - FC_val;
    u_base = r_j(R+1:end) - FC_base;
    % R2_OOS (campbell2007)
    rsqr_oos = (1 -  sum(u_val.^2) / sum(u_base.^2)) * 100;
    % cwstat from MSPE_adjusted (clark2007)
    f_hat = u_base.^2 - u_val.^2 + (FC_base - FC_val).^2;
    cwstat = sqrt(P) * mean(f_hat) / std(f_hat);
    results_oos(j, :) = [rsqr_oos cwstat];
end
toc;

tb1 = array2table(results, 'VariableNames', {'beta', 'p_value', 'R2'}, ...
    'RowNames', country_names);
tb2 = array2table(results_oos, 'VariableNames', {'R2_OOS', 'MSPE_adj'}, ...
    'RowNames', country_names);

oil_ex = [5 10 14 15 18 20 24];
oil_im = setdiff(1:24, oil_ex);

% writetable(tb1(oil_ex, :), "EX_results.xlsx", 'Sheet', "In_Sample_NVIX", ...
%     'WriteRowNames', true, 'WriteVariableNames', false, 'Range', 'A3');
% writetable(tb1(oil_im, :), "EX_results.xlsx", 'Sheet', "In_Sample_NVIX", ...
%     'WriteRowNames', true, 'WriteVariableNames', false, 'Range', 'A13');
% writetable(tb2(oil_ex, :), "EX_results.xlsx", 'Sheet', "Out_of_Sample_NVIX", ...
%     'WriteRowNames', true, 'WriteVariableNames', false, 'Range', 'A3');
% writetable(tb2(oil_im, :), "EX_results.xlsx", 'Sheet', "Out_of_Sample_NVIX", ...
%     'WriteRowNames', true, 'WriteVariableNames', false, 'Range', 'A13');

% writetable(tb1(oil_ex, :), "EX_results.xlsx", 'Sheet', "In_Sample_Average", ...
%     'WriteRowNames', true, 'WriteVariableNames', false, 'Range', 'A3');
% writetable(tb1(oil_im, :), "EX_results.xlsx", 'Sheet', "In_Sample_Average", ...
%     'WriteRowNames', true, 'WriteVariableNames', false, 'Range', 'A13');
% writetable(tb2(oil_ex, :), "EX_results.xlsx", 'Sheet', "Out_of_Sample_Average", ...
%     'WriteRowNames', true, 'WriteVariableNames', false, 'Range', 'A3');
% writetable(tb2(oil_im, :), "EX_results.xlsx", 'Sheet', "Out_of_Sample_Average", ...
%     'WriteRowNames', true, 'WriteVariableNames', false, 'Range', 'A13');

writetable(tb1(oil_ex, :), "EX_results.xlsx", 'Sheet', "In_Sample_PCA", ...
    'WriteRowNames', true, 'WriteVariableNames', false, 'Range', 'A3');
writetable(tb1(oil_im, :), "EX_results.xlsx", 'Sheet', "In_Sample_PCA", ...
    'WriteRowNames', true, 'WriteVariableNames', false, 'Range', 'A13');
writetable(tb2(oil_ex, :), "EX_results.xlsx", 'Sheet', "Out_of_Sample_PCA", ...
    'WriteRowNames', true, 'WriteVariableNames', false, 'Range', 'A3');
writetable(tb2(oil_im, :), "EX_results.xlsx", 'Sheet', "Out_of_Sample_PCA", ...
    'WriteRowNames', true, 'WriteVariableNames', false, 'Range', 'A13');


function t=nw_tstat(X, y)
% newey west estimate (newey1987)
T = size(X, 1);
maxLag = floor(4*(T/100)^(2/9));
[~, se, coef] = hac(X, y, 'type', 'HAC', 'bandwidth', maxLag + 1, 'display', 'off');
tstat = coef ./ se;
t = tstat(2);
end