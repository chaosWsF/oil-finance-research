% load data
data_NVIX = readtable("./data/nvix_and_categories_timeseries_mar2016.xlsx", 'Sheet', 2);
data_NVIX.Date = datetime(string(data_NVIX.Date), 'InputFormat', "yyyyMMdd");
data_CI = readtable("./data/CI.xlsx", 'Sheet', 2);
data_CI.Date = datetime(string(data_CI.Date), 'InputFormat', "yyyyMMdd");

% set used indices, range of time and in-sample period
% % commodity index (AQR, Goldsachs)
% ci_index = 2:11;
% period = [datetime(1970, 1, 31) datetime(2016, 3, 31)];
% R = 20 * 12;
% oil and oil futures
ci_index = 12:18;
period = [datetime(1988, 7, 31) datetime(2015, 12, 31)];
R = 10 * 12;

ci_names = data_CI.Properties.VariableNames(ci_index);
trange_D = isbetween(data_NVIX.Date, period(1), period(2));
NVIX = data_NVIX(trange_D, 2).Variables;
D = data_NVIX(trange_D, 3:end).Variables;
trange_r = isbetween(data_CI.Date, period(1), period(2));
r = data_CI(trange_r, ci_index).Variables;

% remove NaN and normalize disaster indicators
[D, nan_index] = rmmissing(D, 1);
D = normalize(D);
r = r(~nan_index, :);
% D_agg = NVIX(~nan_index, 1) .^ 2;
% D_agg = mean(D, 2);
D_pca = pca(D);
D_agg = D * D_pca(:, 1);

[T, N] = size(D_agg);
P = T - R;    % OOS period
K = size(r, 2);
results = NaN(K, 3);    % beta, pVal, rsqr(%)
results_oos = NaN(K, 2);    % rsqr_oos(%), cwstat
CSFE_gain = NaN(P, K);

parfor j=1:K
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
    FC_base = NaN(P, 1);    % historical average for CI
    for p=1:P
        X = [ones(R+p-1, 1) D_agg(1:R+p-1)];
        y = r_j(1:R+p-1);
        FC_val(p) = [1 D_agg(R+p)] * regress(y, X);
        FC_base(p) = mean(y);
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

tb1 = array2table(results, 'VariableNames', {'beta', 'p_value', 'R2'}, ...
    'RowNames', ci_names);
tb2 = array2table(results_oos, 'VariableNames', {'R2_OOS', 'MSPE_adj'}, ...
    'RowNames', ci_names);
disp("in-sample")
disp(tb1)
disp("out-of-sample")
disp(tb2)

% % NVIX^2, CI
% writetable(tb1, "CI_results.xlsx", 'Sheet', "In_Sample_NVIX", 'WriteRowNames', true, ...
%     'WriteVariableNames', false, 'Range', 'A2')
% writetable(tb2, "CI_results.xlsx", 'Sheet', "Out_of_Sample_NVIX", 'WriteRowNames',true,...
%     'WriteVariableNames', false, 'Range', 'A2')

% % NVIX^2, oil
% writetable(tb1, "CI_results.xlsx", 'Sheet', "In_Sample_NVIX", 'WriteRowNames', true, ...
%     'WriteVariableNames', false, 'Range', 'A12')
% writetable(tb2, "CI_results.xlsx", 'Sheet', "Out_of_Sample_NVIX", 'WriteRowNames',true,...
%     'WriteVariableNames', false, 'Range', 'A12')

% % Mean, CI
% writetable(tb1, "CI_results.xlsx", 'Sheet', "In_Sample_Average", 'WriteRowNames', true,...
%     'WriteVariableNames', false, 'Range', 'A2')
% writetable(tb2, "CI_results.xlsx", 'Sheet', "Out_of_Sample_Average", 'WriteRowNames', ...
%     true, 'WriteVariableNames', false, 'Range', 'A2')

% % Mean, oil
% writetable(tb1, "CI_results.xlsx", 'Sheet', "In_Sample_Average", 'WriteRowNames', true,...
%     'WriteVariableNames', false, 'Range', 'A12')
% writetable(tb2, "CI_results.xlsx", 'Sheet', "Out_of_Sample_Average", 'WriteRowNames', ...
%     true, 'WriteVariableNames', false, 'Range', 'A12')

% % PCA, CI
% writetable(tb1, "CI_results.xlsx", 'Sheet', "In_Sample_PCA", 'WriteRowNames', true, ...
%     'WriteVariableNames', false, 'Range', 'A2')
% writetable(tb2, "CI_results.xlsx", 'Sheet', "Out_of_Sample_PCA", 'WriteRowNames', true,...
%     'WriteVariableNames', false, 'Range', 'A2')

% PCA, oil
writetable(tb1, "CI_results.xlsx", 'Sheet', "In_Sample_PCA", 'WriteRowNames', true, ...
    'WriteVariableNames', false, 'Range', 'A12')
writetable(tb2, "CI_results.xlsx", 'Sheet', "Out_of_Sample_PCA", 'WriteRowNames', true,...
    'WriteVariableNames', false, 'Range', 'A12')


function t=nw_tstat(X, y)
% newey west estimate (newey1987)
T = size(X, 1);
maxLag = floor(4*(T/100)^(2/9));
[~, se, coef] = hac(X, y, 'type', 'HAC', 'bandwidth', maxLag + 1, 'display', 'off');
tstat = coef ./ se;
t = tstat(2);
end