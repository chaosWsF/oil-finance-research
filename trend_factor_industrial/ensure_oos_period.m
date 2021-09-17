clear;
warning('off');

L = 6;
in_sample_period = 16 * 12;
testing_oos = 1;

% nwest lag
nlag1 = 36; % in-sample
nlag2 = 36; % cw-test

start_date = datetime("1987/04/01");
end_date = datetime("2019/05/01"); % day after real end
period = split(between(start_date, end_date, 'months'), 'month');
out_of_sample_period = period - in_sample_period;

load('./dataset.mat');
oil_data = experiment.oil;
ind_code_arr = experiment.indcode;
num_x = experiment.numoil;
num_y = experiment(1).numcountry;

in_sample_results = nan(num_x * num_y, 3 * length(ind_code_arr));
oos_results = nan(num_x * num_y, 2 * length(ind_code_arr));
csfe_results = nan(out_of_sample_period, length(ind_code_arr));

for ica = 1:length(ind_code_arr)
    ind_code = ind_code_arr(ica);
    fprintf("\t%s-->", ind_code)
    ind_data = experiment(ica).ind;

    [x_L, y] = process_data(oil_data, L, ind_data, start_date, end_date);

    % in-sample: coeff, p_val, R2 (%)
    row_num = 0;

    for k = 1:num_y

        for i = 1:num_x
            row_num = row_num + 1;

            x_reg = x_L(1:end - 1, i);
            X_i = [ones(period - 1, 1) x_reg];
            y_reg = y(2:end, k);

            del_nan = isfinite(x_reg) & isfinite(y_reg);
            X_i = X_i(del_nan, :);
            y_reg = y_reg(del_nan);

            nw_results_i_k = nwest(y_reg, X_i, nlag1);
            p_value = 2 * normcdf(-abs(nw_results_i_k.tstat(2)));
            in_sample_results(row_num, 3 * (ica - 1) + 1:3 * ica) = ...
                [nw_results_i_k.beta(2) p_value nw_results_i_k.rsqr*100];
        end

    end

    fprintf("in-sample-->")

    % out-of-sample preparation
    FC_mean = nan(out_of_sample_period, num_y);
    FC_val = nan(out_of_sample_period, num_x, num_y);

    for o = 1:out_of_sample_period

        for k = 1:num_y
            FC_mean(o, k) = nanmean(y(1:in_sample_period + o - 1, k));

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

        end

    end

    % OOS: R2OS (%), p_val
    row_num = 0;

    for k = 1:num_y
        actual_k = y(in_sample_period + 1:end, k);
        u_mean_k = actual_k - FC_mean(1:end, k);
        MSFE_mean_k = nansum(u_mean_k.^2);

        for i = 1:num_x
            row_num = row_num + 1;
            u_val_i_k = actual_k - FC_val(1:end, i, k);
            MSFE_val_i_k = nansum(u_val_i_k.^2);
            R2OS_val_i_k = (1 - MSFE_val_i_k / MSFE_mean_k) * 100;
            oos_results(row_num, 2 * ica - 1) = R2OS_val_i_k;

            f_CW_i_k = u_mean_k.^2 - u_val_i_k.^2 + ...
                (FC_mean(1:end, k) - FC_val(1:end, i, k)).^2;
            f_CW_i_k = f_CW_i_k(isfinite(f_CW_i_k));
            results_CW_i_k = nwest(f_CW_i_k, ones(length(f_CW_i_k), 1), nlag2);
            oos_results(row_num, 2 * ica) = 1 - normcdf(results_CW_i_k.tstat);

            if k == 9
                CSFE1 = cumsum(u_mean_k.^2, 'omitnan');
                CSFE2 = cumsum(u_val_i_k.^2, 'omitnan');
                CSFE_diff = CSFE1 - CSFE2;
            end

        end

    end

    csfe_results(:, ica) = CSFE_diff;
    fprintf("oos\n")
end

if testing_oos
    plot_CSFE(csfe_results, start_date, in_sample_period, period, ind_code_arr);
end

function [x_L, y] = process_data(oil_data, L, ind_data, start_date, end_date)

    % This function is mainly to generate the regression data, exactly
    % generating monthly trend of oil future's close price (x) at last day
    % and calculate return on dependent variables (y) with some preprocess.
    % x will be trended in different period (L).
    %
    % Used data:
    % Oil futures: oil_futures;
    % Industry: ind_code;
    % Index Class: ind_path.
    %
    % data range:
    % Oil Futures: start_date-(L-1) to the last month of end_date;
    % Industry: start_date to the last month of end_date;
    % Market Index: ;
    % Risk-Free:  .

    period = split(between(start_date, end_date, 'months'), 'month');
    ahead_date = start_date + calmonths(-L);
    used = (oil_data.date >= ahead_date) & (oil_data.date < end_date);
    oil_data = oil_data(used, :);

    % do moving average on last day price and then calculate return
    dates = oil_data.date;
    last_days = nan(period + L, 1);

    for t = 1:period + L
        tmp = dates(dates < ahead_date + calmonths(t));
        last_days(t) = length(tmp);
    end

    x = oil_data(last_days, 2).Variables;
    x_L = nan(period + 1, size(x, 2));

    for t = 1:period + 1
        x_t = x(t:t + L - 1, :);
        x_L(t, :) = nanmean(x_t);
    end

    x_L = log(x_L(2:end, :) ./ x_L(1:end - 1, :));

    % do moving average on daily return
    %     return_date = oil_data.date(3:end);
    %     x_return = oil_data(2:end, 2).Variables;
    %     x_return = log(x_return(2:end, :) ./ x_return(1:end-1, :));
    %     x_L = nan(period, size(x_return, 2));
    %     for t=1:period
    %         date1 = ahead_date + calmonths(t);
    %         date2 = start_date + calmonths(t);
    %         date_index = (return_date >= date1) & (return_date < date2);
    %         x_L(t, :) = nanmean(x_return(date_index, :));
    %     end

    fprintf("x_L-->")

    % calculate monthly return on industry
    used = (ind_data.date >= start_date) & (ind_data.date < end_date);
    ind_data = ind_data(used, :);
    dates = ind_data.date;
    last_days = nan(period, 1);

    for t = 1:period
        tmp = dates(dates < start_date + calmonths(t));
        last_days(t) = length(tmp);
    end

    first_days = [1 (last_days(1:end-1)+1)'];
    y = ind_data([first_days last_days'], 2:end).Variables;
    y = log(y(2:2:end, :) ./ y(1:2:end - 1, :));
    fprintf("y-->")

    % calculate monthly return on industry through last day
    %     ahead_date = start_date + calmonths(-1);
    %     used = (ind_data.date >= ahead_date) & (ind_data.date < end_date);
    %     ind_data = ind_data(used, :);
    %     dates = ind_data.date;
    %     last_days = nan(period + 1, 1);
    %
    %     for t = 1:period + 1
    %         tmp = dates(dates < ahead_date + calmonths(t));
    %         last_days(t) = length(tmp);
    %     end
    %
    %     y = ind_data(last_days, 2:end).Variables;
    %     y = log(y(2:end, :) ./ y(1:end - 1, :));
    %     fprintf("y-->")
end

function plot_CSFE(csfe_results, start_date, in_sample, period, ind_names)
    % The function can plot the figure of CSFE difference
    % every industry index and benchmark index

    t = start_date + calmonths(in_sample:period - 1);

    for k = 1:length(ind_names)
        CSFE_diff = csfe_results(:, k);

        subplot(5, 4, k);
        plot(t, CSFE_diff);
        title(ind_names(k));

        xlim([start_date+calmonths(in_sample) start_date+calmonths(period-1)]);
        % xlabel('Date');
        % ylabel('$\Delta \mathrm{CSFE}$','interpreter','latex');
        xtickformat('yyyy');
        xtickangle(30);

        grid on;
        ax = gca;
        ax.XMinorGrid = 'on';
    end

end
