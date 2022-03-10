% Calculate the R2os when R_ind > R_m
% And plot a figure of CSFE difference bewteen industry and market

clear;
% set(gcf, 'Visible', 'off');

L = 6;
in_sample_period = 7 * 12;
summary_regression_data(L);
load('regression_data.mat');
R_m = y_h(:, 1); % hs300
y_h = y_h(:, 2:end); % only 20 industries

start_date = datetime(2001, 4, 1);
period = size(y_h, 1);
num_x = size(x_L, 2);
num_y = size(y_h, 2);
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

R2OS = nan(num_x * num_y, 1, 1);
row_num = 0;

for k = 1:num_y
    actual_k = y_h(in_sample_period + 1:end - (h - 1), k, 1);
    u_mean_k = actual_k - FC_mean(1:end - (h - 1), k); % must no nan
    r2_index = actual_k > R_m(in_sample_period + 1:end - (h - 1)); % TODO
    u_mean_r = u_mean_k(r2_index);

    for i = 1:num_x
        row_num = row_num + 1;
        u_val_i_k = actual_k - FC_val(1:end - (h - 1), i, 1, k); % must no nan
        u_val_r = u_val_i_k(r2_index);
        MSFE_val = sum(u_val_r.^2);
        MSFE_mean = sum(u_mean_r.^2);
        R2OS_val = (1 - MSFE_val / MSFE_mean) * 100;

        plot_CSFE(start_date, in_sample_period, u_mean_k, ...
            u_val_i_k, period, k);
        R2OS(row_num, :, 1) = R2OS_val';
    end

end

% xlswrite('./results/summary.xlsx', R2OS, 'Recession', 'b2');

function plot_CSFE(start_date, in_sample, u_mean, u_val, period, k)
    % The function can plot the figure of CSFE difference
    % every industry index and market index
    names = ["MI", "EL", "RE", "AP", "PU", "MAC", "CO", "TR", "FI", "HF", ...
            "TB", "CS", "PE", "FB", "ME", "IT", "PB", "PA", "MA", "OT"];

    CSFE1 = cumsum(u_mean.^2);
    CSFE2 = cumsum(u_val.^2);
    CSFE_diff = CSFE1 - CSFE2;

    t = start_date + calmonths(in_sample:period - 1);

    subplot(5, 4, k);
    plot(t, CSFE_diff);
    title(names(k));

    xlim([start_date+calmonths(in_sample) start_date+calmonths(period-1)]);
    % xlabel('Date');
    % ylabel('$\Delta \mathrm{CSFE}$','interpreter','latex');
    xtickformat('yyyy');
    xtickangle(30);

    grid on;
    ax = gca;
    ax.XMinorGrid = 'on';

    % figname = sprintf('./results/CSFE/industry%1d.png', k);
    % disp(figname)
    % saveas(gcf, figname);
end
