clear;

L = 6;
in_sample_period = 5 * 12;
nlag = 36;
p = 5; % exlude p% extreme

output_file = './results/summary.xlsx';
disp(output_file)
extreme_regression_data(L, p);
load('regression_data_extreme.mat');

period = size(y_h, 1);
num_x = size(x_L, 2);
num_y = size(y_h, 2);

test_results = nan(num_x * num_y, 5, length(h));

% in-sample
row_num = 0;

for k = 1:num_y

    for i = 1:num_x
        row_num = row_num + 1;
        x_reg = x_L(1:end - h, i);
        X_i = [ones(period - h, 1) x_reg];
        y_reg = y_h(2:end - (h - 1), k, 1);
        del_nan = isfinite(x_reg) & isfinite(y_reg);
        X_i = X_i(del_nan, :);
        y_reg = y_reg(del_nan);
        nw_results_i_k = nwest(y_reg, X_i, nlag);
        test_results(row_num, 1, 1) = nw_results_i_k.beta(2);
        tstat = nw_results_i_k.tstat(2);
        dfe = nw_results_i_k.nobs - nw_results_i_k.nvar;
        p_value = 2 * tcdf(-abs(tstat), dfe);
        test_results(row_num, 2, 1) = p_value;
        test_results(row_num, 3, 1) = nw_results_i_k.rsqr * 100;
    end

end

% out-of-sample
out_of_sample_period = period - in_sample_period;
FC_mean = nan(out_of_sample_period, num_y);
FC_val = nan(out_of_sample_period, num_x, length(h), num_y);

for o = 1:out_of_sample_period
    disp(o)

    for k = 1:num_y

        for i = 1:num_x
            x_reg = x_L(1:in_sample_period + o - 1 - h, i);
            X_i_o = [ones(in_sample_period + o - 1 - h, 1) x_reg];
            y_reg = y_h(2:in_sample_period + o - h, k, 1);
            del_nan = isfinite(x_reg) & isfinite(y_reg);
            X_i_o = X_i_o(del_nan, :);
            y_reg = y_reg(del_nan);

            if length(y_reg) > 1
                results_i_k_o = ols(y_reg, X_i_o);
                FC_val(o, i, 1, k) = [1 x_L(in_sample_period + o - 1, i)] * ...
                    results_i_k_o.beta;
            else
                FC_val(o, i, 1, k) = nan;
            end

        end

        FC_mean(o, k) = mean_without_nan(y_h(1:in_sample_period + o - 1, k, 1));
    end

end

row_num = 0;

for k = 1:num_y
    actual_k = y_h(in_sample_period + 1:end - (h - 1), k, 1);
    u_mean_k = actual_k - FC_mean(1:end - (h - 1), k);
    u_mean_k_nonan = u_mean_k(isfinite(u_mean_k));
    MSFE_mean_k = sum(u_mean_k_nonan.^2);

    for i = 1:num_x
        row_num = row_num + 1;
        u_val_i_k = actual_k - FC_val(1:end - (h - 1), i, 1, k);
        u_val_i_k_nonan = u_val_i_k(isfinite(u_val_i_k));
        MSFE_val_i_k = sum(u_val_i_k_nonan.^2);
        R2OS_val_i_k = (1 - MSFE_val_i_k / MSFE_mean_k) * 100;
        test_results(row_num, 5, 1) = R2OS_val_i_k';

        f_CW_i_k = u_mean_k.^2 - u_val_i_k.^2 + ...
            (FC_mean(1:end - (h - 1), k) - FC_val(1:end - (h - 1), ...
            i, 1, k)).^2;
        f_CW_i_k = f_CW_i_k(isfinite(f_CW_i_k));
        results_CW_i_k = nwest(f_CW_i_k, ...
            ones(length(f_CW_i_k), 1), 1);
        tstat = results_CW_i_k.tstat;
        dfe = results_CW_i_k.nobs - results_CW_i_k.nvar;
        test_results(row_num, 4, 1) = 1 - tcdf(tstat, dfe);
    end

end

output_sheet = 'extreme_oilprice';
xlswrite(output_file, test_results, output_sheet, 'b3');

function extreme_regression_data(L, p)
    % This function is to read the regression data, calculate return and do
    % moving average on them. The input is the lag of trend on independent
    % variables (x). And the output data consists of trended independent
    % variables (x_L), moving average on dependent variables (y_h) for
    % robustness test and used lag list (h). Then the function will exculde the
    % p% extreme data.
    input_file = './data/monthly_data.xlsx';

    % industry 2001:04-2019:03, hs300 2002:01-2019:03
    x_index = 'e'+string(617 - L) + ':e832';
    x_inputs = xlsread(input_file, 'oil_last', x_index);
    r_free = xlsread(input_file, 'r_free', 'b2:b151');
    y_inputs = xlsread(input_file, 'stock', 'c126:w341');

    x_period = size(x_inputs, 1);
    x_L = nan(x_period - (L - 1), size(x_inputs, 2));

    for t = L:x_period
        x_t = x_inputs(t - (L - 1):t, :);
        x_L(t - (L - 1), :) = mean_without_nan(x_t);
    end

    x_L = log(x_L(2:end, :)) - log(x_L(1:end - 1, :));

    if length(r_free) < size(y_inputs, 1)
        r_free = [ones(1, size(y_inputs, 1) - length(r_free)) r_free']';
    end

    logrf = log(r_free);
    logR = log(y_inputs) - logrf;
    y = logR;
    y_period = size(y, 1);
    h = 1;
    y_h = nan(y_period, size(y, 2), length(h));
    rf_h = nan(y_period, length(h));

    for t = 1:y_period - (h - 1)
        logR_t_h = logR(t:t + h - 1, :);
        y_h(t, :, 1) = mean_without_nan(logR_t_h);
        logrf_t_h = logrf(t:t + h - 1, :);
        rf_h(t, 1) = mean_without_nan(logrf_t_h);
    end

    refData = x_inputs(L + 1:end, :);
    head = refData >= prctile(refData, 100 - p / 2, 1);
    tail = refData <= prctile(refData, p / 2, 1);
    extreme_index = head | tail;
    x_L = x_L(~extreme_index);
    y_h = y_h(~extreme_index, :);

    output_data = 'regression_data_extreme.mat';
    save(output_data, 'x_L', 'y_h', 'h');
end
