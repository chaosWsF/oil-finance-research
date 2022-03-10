% load data
data_NVIX = readtable("./data/nvix_and_categories_timeseries_mar2016.xlsx", 'Sheet', 2);
data_NVIX.Date = datetime(string(data_NVIX.Date), 'InputFormat', "yyyyMMdd");
data_EX = readtable("./data/Belt_Road_EX_monthly.xlsx", 'Sheet', 2);
data_EX.Date = datetime(string(data_EX.Date), 'InputFormat', "yyyyMMdd");
data_rf = readtable("./data/Shibor_1_Month.xlsx");    % daily
data_rf.Date = datetime(string(data_rf.Date), 'InputFormat', "yyyyMMdd");
data_rf = groupsummary(data_rf, 'Date', 'month', 'mean');

% set range of time and used country
period = [datetime(2000, 1, 31) datetime(2016, 3, 31)];
country = 2:45;
fix_rate_country = [2 6 15 16 22 26 30 31 35 39];
rm_country = [21 17 9 42 32 45 13];
country = setdiff(country, [fix_rate_country rm_country]);
disp(data_EX.Properties.VariableNames(fix_rate_country) + " fix rate")
country_names = data_EX.Properties.VariableNames(country);
trange_D = isbetween(data_NVIX.Date, period(1), period(2));
D = data_NVIX(trange_D, 3:end).Variables;
trange_r = isbetween(data_EX.Date, period(1), dateshift(period(2), 'end', 'month', 1));
EX = data_EX(trange_r, country).Variables;
trange_rf = isbetween(categories(data_rf{:, 1}), ... 
    dateshift(period(1), 'end', 'month', 1), dateshift(period(2), 'end', 'month', 1));
rf_0 = data_rf(trange_rf, 3).Variables;

% calculate EX return, fill missing data of SHIBOR
% r = log(EX(2:end, :) ./ EX(1:end-1, :));
r = EX(2:end, :) ./ EX(1:end-1, :) - 1;
rf = NaN(size(r, 1), 1);
rf(end - size(rf_0, 1) + 1:end) = rf_0 / 1200;    % percent per anum
rf = fillmissing(rf, 'constant', mean(rf_0));

% remove NaN and normalize disaster indicators
[D, nan_index] = rmmissing(D, 1);
T = size(D, 1);
D = normalize(D);
r = r(~nan_index, :);
rf = rf(~nan_index);
missing_data_index = any(isnan(r));
if ~isempty(r(:, missing_data_index))
    r = r(:, ~missing_data_index);
    disp(country_names(missing_data_index) + " missing data")
    country_names = country_names(~missing_data_index);
end

% get out-of-sample predictions
R = 6 * 12;
P = T - R;    % OOS period
K = size(r, 2);
FC_val = NaN(P, K);
for j=1:K
    r_j = r(:, j);
    % three-pass regression (kelly2015)
    [~, ~, ~, ~, BETA1] = plsregress(r_j, D);
    [~, ~, ~, ~, BETA2] = plsregress(BETA1(2, :)', D');
    latent = BETA2(2, :)';    % real measure of rare disaster
    
    for p=1:P
        X = [ones(R+p-1, 1) latent(1:R+p-1)];
        y = r_j(1:R+p-1);
        FC_val(p, j) = [1 latent(R+p)] * regress(y, X);
    end
end

% calculate weights, maximum performance fee and breakeven transaction costs
window = 5 * 12;    % estimate variance
vols = [0.08 0.1 0.12];
w_bound = [-inf inf; -inf inf; -1 2];
RRA = 2;
rf_oos = rf(R+1:T);
er_excess = FC_val - rf_oos;
% one way transaction costs (neely2009)
c = linspace(100, 10, T + 1) * 1e-4;
results = NaN(size(vols, 2), 2, size(w_bound, 1));    % annualized fee(%), tao BE (bps)
r_p = NaN(P, size(vols, 2));
prop_tc1 = NaN(P, size(vols, 2));
prop_tc2 = NaN(P, size(vols, 2));
for v=1:size(vols, 2)
    vol = vols(v);
    weights = NaN(P, K);
    for b=1:size(w_bound, 1)
        w_low = w_bound(b, 1);
        w_high = w_bound(b, 2);
        for p=1:P
            var_est = cov(r(R+p-window:R+p-1, :));
            C = er_excess(p, :) / var_est * er_excess(p, :)';
            w = (vol / sqrt(C) * (var_est \ er_excess(p, :)'))';
            weights(p, :) = w;
            w(w < w_low) = w_low;
            w(w > w_high) = w_high;
            r_p_t = w * r(R+p, :)' + (1 - sum(w)) * rf_oos(p);
            r_p(p, v) = r_p_t;
            
            % total proportional transaction cost
            tmp = NaN(1, K);
            for j=1:K
                if r_p_t >= r(R+p, j)
                    tmp(j) = log((1 + c(R + p - 1)) / (1 - c(R + p)));
                else
                    tmp(j) = log((1 - c(R + p - 1)) / (1 + c(R + p)));
                end
            end
            prop_tc1(p, v) = sum((w - w .* (1 + r(R + p, :))) .* tmp / (1 + r_p_t));
            prop_tc2(p, v) = sum(abs(w - w .* (1 + r(R + p, :)) / (1 + r_p_t)));
        end

        if b > 1
            fee = log(mean(((1+r_p(:,v)-prop_tc1(:,v))./(1+rf_oos)).^(1-RRA)))/(1-RRA)*100;
            tao = (mean(r_p(:, v)) - mean(rf_oos)) / mean(prop_tc2(:, v)) * 1e4;
        else
            fee = log(mean(((1+r_p(:,v))./(1+rf_oos)).^(1-RRA)))/(1 - RRA)*100;
            tao = NaN;
        end
        results(v, :, b) = [fee tao] * 12;
    end
end

results = reshape(results, size(vols, 2), 2 * size(w_bound, 1));
tb = array2table(results, 'VariableNames', ...
    {'Fee_1', 'Tao_BE_1', 'Fee_2', 'Tao_BE_2', 'Fee_3', 'Tao_BE_3'}, ...
    'RowNames', {'vol_8', 'vol_10', 'vol_12'});

disp("assets-allocation")
disp(tb)

writetable(tb, "EX_results.xlsx", 'Sheet', "Assets_Allocation", ...
    'WriteRowNames', true, 'WriteVariableNames', false, 'Range', 'A3');
