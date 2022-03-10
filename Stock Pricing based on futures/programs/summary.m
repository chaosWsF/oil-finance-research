clear;

L = 6;
% L = 1;  % nontrend (the codes for writing should be uncommented.)
in_sample_period = 7 * 12;
nlag = 36;  % in-sample

output_file = './results/summary.xlsx';
disp(output_file)
summary_regression_data(L);
load('regression_data.mat');

period = size(y_h, 1);
num_x = size(x_L, 2);
num_y = size(y_h, 2);

% in-sample: coeff, p_val, R2 (%)
test_results = nan(num_x * num_y, 3, length(h));
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
        dfe = nw_results_i_k.nobs - nw_results_i_k.nvar;
        beta = nw_results_i_k.beta(2);
        tstat = nw_results_i_k.tstat(2);
        rsqr = nw_results_i_k.rsqr * 100;
        p_value = 2 * tcdf(-abs(tstat), dfe);
        test_results(row_num, :, 1) = [beta p_value rsqr];
    end

end

% out-of-sample preparation
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

% return p_val, R2OS (%)
R2OS = nan(num_x * num_y, 2, 1);
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
        R2OS(row_num, 2, 1) = R2OS_val_i_k';

        f_CW_i_k = u_mean_k.^2 - u_val_i_k.^2 + ...
            (FC_mean(1:end - (h - 1), k) - FC_val(1:end - (h - 1), ...
            i, 1, k)).^2;
        f_CW_i_k = f_CW_i_k(isfinite(f_CW_i_k));
        results_CW_i_k = nwest(f_CW_i_k, ...
            ones(length(f_CW_i_k), 1), 1);
        dfe = results_CW_i_k.nobs - results_CW_i_k.nvar;
        tstat = results_CW_i_k.tstat;
        R2OS(row_num, 1, 1) = 1 - tcdf(tstat, dfe);
    end

end

output_sheet = 'In-Sample';
xlswrite(output_file, test_results, output_sheet, 'c3');
output_sheet = 'Out-of-sample';
xlswrite(output_file, R2OS, output_sheet, 'c3');

% uncomment the following codes for writing nontrend results
% output_sheet = 'In-Sample';
% xlswrite(output_file, test_results, output_sheet, 'f3');
% output_sheet = 'Out-of-sample';
% xlswrite(output_file, R2OS, output_sheet, 'h3');

% ("summary_regression_data.m" should be changed firstly)
% the following two line codes are for subsample test
% xlswrite(output_file, test_results, 'subsample', 'b3');
% xlswrite(output_file, test_results, 'subsample', 'e3');
