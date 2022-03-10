clear;

L = 3;
nlag = 36;
% in_sample_period = 8 * 12;
in_sample_period = 1 * 12;

[x_L, y] = load_data(L);
period = size(y, 1);
num_x = size(x_L, 2);
num_y = size(y, 2);
start_date = datetime("2001/04/01");

% in-sample: coeff, p_val, R2 (%)
test_results = nan(num_x * num_y, 3);
row_num = 0;

for k = 1:num_y

    for i = 1:num_x
        row_num = row_num + 1;
        x_reg = x_L(1:end - 1, i);
        X_i_k = [ones(period - 1, 1) x_reg];
        y_reg = y(2:end, k);
        del_nan = isfinite(x_reg) & isfinite(y_reg);
        X_i_k = X_i_k(del_nan, :);
        y_reg = y_reg(del_nan);
        nw_results_i_k = nwest(y_reg, X_i_k, nlag);
        p_value = 2 * normcdf(-abs(nw_results_i_k.tstat(2)));
        test_results(row_num, :) = [nw_results_i_k.beta(2) ...
                                p_value nw_results_i_k.rsqr * 100];
    end

end

% out-of-sample preparation
out_of_sample_period = period - in_sample_period;
FC_mean = nan(out_of_sample_period, num_y);
FC_val = nan(out_of_sample_period, num_x, num_y);

for o = 1:out_of_sample_period
    disp(o)

    for k = 1:num_y

        for i = 1:num_x
            x_reg = x_L(1:in_sample_period + o - 2, i);
            X_i_o = [ones(in_sample_period + o - 2, 1) x_reg];
            y_reg = y(2:in_sample_period + o - 1, k);
            del_nan = isfinite(x_reg) & isfinite(y_reg);
            X_i_o = X_i_o(del_nan, :);
            y_reg = y_reg(del_nan);

            if length(y_reg) > 1
                results_i_k_o = ols(y_reg, X_i_o);
                FC_val(o, i, k) = [1 x_L(in_sample_period + o - 1, i)] * ...
                    results_i_k_o.beta;
            else
                FC_val(o, i, k) = nan;
            end

        end

        FC_mean(o, k) = mean_without_nan(y(1:in_sample_period + o - 1, k));
    end

end

% calculate p_val, R2OS (%)
R2OS = nan(num_x * num_y, 2, 1);
row_num = 0;

for k = 1:num_y
    actual_k = y(in_sample_period + 1:end, k);
    u_mean_k = actual_k - FC_mean(1:end, k);
    u_mean_k_nonan = u_mean_k(isfinite(u_mean_k));
    MSFE_mean_k = sum(u_mean_k_nonan.^2);

    for i = 1:num_x
        row_num = row_num + 1;
        u_val_i_k = actual_k - FC_val(1:end, i, k);
        u_val_i_k_nonan = u_val_i_k(isfinite(u_val_i_k));
        MSFE_val_i_k = sum(u_val_i_k_nonan.^2);
        R2OS_val_i_k = (1 - MSFE_val_i_k / MSFE_mean_k) * 100;
        R2OS(row_num, 2, 1) = R2OS_val_i_k';

        f_CW_i_k = u_mean_k.^2 - u_val_i_k.^2 + ...
            (FC_mean(1:end, k) - FC_val(1:end, ...
            i, k)).^2;
        f_CW_i_k = f_CW_i_k(isfinite(f_CW_i_k));
        results_CW_i_k = nwest(f_CW_i_k, ...
            ones(length(f_CW_i_k), 1), nlag);
        R2OS(row_num, 1, 1) = 1 - normcdf(results_CW_i_k.tstat);

        plot_CSFE(start_date, in_sample_period, u_mean_k, ...
            u_val_i_k, period, k);
    end

end

output_file = "./results/add/n1vol_reg/n1vol_reg.xlsx";
xlswrite(output_file, test_results, "In-Sample", "c2");
xlswrite(output_file, R2OS, "Out-of-sample", "c2");

function [x_L, y] = load_data(L)
    % This function is mainly to generate the regression data, exactly
    % generating skewness of oil"s daily return in different period (L). The
    % input is the lag of trend on independent variables (x). The output
    % data consists of trended independent variables (x_L), and dependent
    % variables (y).
    %
    % oil-skew -- 2001:04-2019:03 (start date should be L months ahead)
    % ind -- 2001:04-2019:03;
    % HS300 -- 2002:01-2019:03;
    % SHIBOR -- 2006:10-2019:03

    input_file = "./data/monthly_data.xlsx";
    r_free = xlsread(input_file, "r_free", 'b2:b151');
    y_inputs = xlsread(input_file, "stock", 'c126:w341');
    x_index = 'p'+string(618 - (L - 1)) + ':p833';
    x_inputs = xlsread(input_file, 'oil_add', x_index);

    x_period = size(x_inputs, 1);
    x_L = nan(x_period - (L - 1), size(x_inputs, 2));

    for t = L:x_period
        x_t = x_inputs(t - (L - 1):t, :);
        x_L(t - (L - 1), :) = mean_without_nan(x_t);
    end

    % imput the missing risk-free data
    if length(r_free) < size(y_inputs, 1)
        r_free = [ones(1, size(y_inputs, 1) - length(r_free)) r_free']';
    end

    y = log(y_inputs) - log(r_free);
end

function plot_CSFE(start_date, in_sample, u_mean, u_val, period, k)
    % The function can plot the figure of CSFE difference every industry index
    % and market index.

    names = ["MI", "EL", "RE", "AP", "PU", "MAC", "CO", "TR", "FI", "HF", ...
            "TB", "CS", "PE", "FB", "ME", "IT", "PB", "PA", "MA", "OT"];

    CSFE1 = cumsum(u_mean.^2);
    CSFE2 = cumsum(u_val.^2);
    CSFE_diff = CSFE1 - CSFE2;

    t = start_date + calmonths(in_sample:period - 1);

    if k == 1
        set(gcf, 'Visible', 'off');
        plot(t, CSFE_diff);

        xlim([start_date+calmonths(in_sample) start_date+calmonths(period-1)]);
        xtickformat('yyyy');
        xtickangle(30);

        grid on;
        ax = gca;
        ax.XMinorGrid = 'on';
        set(gcf, 'Visible', 'on');
    else
        subplot(5, 4, k - 1);
        plot(t, CSFE_diff);
        title(names(k - 1));

        xlim([start_date+calmonths(in_sample) start_date+calmonths(period-1)]);
        xtickformat('yyyy');
        xtickangle(30);

        grid on;
        ax = gca;
        ax.XMinorGrid = 'on';
    end

end
