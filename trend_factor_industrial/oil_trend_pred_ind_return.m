clear;

% L_arr = [1, 3, 6, 12, 18, 24, 36, 48];
L_arr = [6];
in_sample_period = 16 * 12;

start_date = datetime(1987, 4, 1);
end_date = datetime(2019, 5, 1);  % day after real end
load('./dataset.mat');
oil_data = experiment.oil;
ind_code_arr = experiment.indcode;
num_x = experiment.numoil;
num_y = experiment(1).numcountry;

experiment_results = struct('L', {}, 'insample', {}, 'oos', {});

for l = 1:length(L_arr)
    L = L_arr(l);
    fprintf("L=%d\n", L)

    experiment_results(l).L = L;
    in_sample_results = nan(num_x * num_y, 3 * length(ind_code_arr));
    oos_results = nan(num_x * num_y, 2 * length(ind_code_arr));

    for ica = 1:length(ind_code_arr)
        ind_code = ind_code_arr(ica);
        fprintf("\t%s-->", ind_code)
        ind_data = experiment(ica).ind;

        [x_L, y] = process_data(oil_data, L, ind_data, start_date, end_date);
        period = size(y, 1);

        % in-sample: coeff, p_val, R2 (%)
        row_num = 0;

        for k = 1:num_y

            for i = 1:num_x
                row_num = row_num + 1;

                x_reg = x_L(1:end - 1, i);
                y_reg = y(2:end, k);

                del_nan = isfinite(x_reg) & isfinite(y_reg);
                x_reg = x_reg(del_nan);
                y_reg = y_reg(del_nan);
                
                md = fitlm(x_reg, y_reg);
                beta = md.Coefficients.Estimate(2);
                rsqr = md.Rsquared.Ordinary * 100;
                
                B = 1000;
                t0 = nw_tstat(x_reg, y_reg);
                alpha = regress(y_reg, ones(size(y_reg, 1), 1));
                resid = md.Residuals.Raw;
                rng('default');  % for reproducibility
                tboot = bootstrp(B, @(u)nw_tstat(x_reg, alpha + u), resid);
                if t0 >= 0
                    pVal = sum(tboot > t0) / B;
                else
                    pVal = sum(tboot < t0) / B;
                end
                
                in_sample_results(row_num, 3 * (ica - 1) + 1:3 * ica) = [beta pVal rsqr];
            end

        end

        fprintf("in-sample-->")

        % out-of-sample preparation
%         out_of_sample_period = period - in_sample_period;
%         FC_mean = nan(out_of_sample_period, num_y);
%         FC_val = nan(out_of_sample_period, num_x, num_y);
% 
%         for o = 1:out_of_sample_period
% 
%             for k = 1:num_y
%                 FC_mean(o, k) = nanmean(y(1:in_sample_period + o - 1, k));
% 
%                 for i = 1:num_x
%                     x_reg = x_L(1:in_sample_period + o - 2, i);
%                     X_i_o = [ones(in_sample_period + o - 2, 1) x_reg];
%                     y_reg = y(2:in_sample_period + o - 1, k);
% 
%                     del_nan = isfinite(x_reg) & isfinite(y_reg);
%                     X_i_o = X_i_o(del_nan, :);
%                     y_reg = y_reg(del_nan);
% 
%                     if length(y_reg) > 1
%                         results_i_k_o = ols(y_reg, X_i_o);
%                         FC_val(o, i, k) = [1 x_L(in_sample_period + o - 1, i)] * ...
%                             results_i_k_o.beta;
%                     else
%                         FC_val(o, i, k) = nan;
%                     end
% 
%                 end
% 
%             end
% 
%         end
% 
%         % OOS: R2OS (%), p_val
%         row_num = 0;
% 
%         for k = 1:num_y
%             actual_k = y(in_sample_period + 1:end, k);
%             u_mean_k = actual_k - FC_mean(1:end, k);
%             MSFE_mean_k = nansum(u_mean_k.^2);
% 
%             for i = 1:num_x
%                 row_num = row_num + 1;
%                 u_val_i_k = actual_k - FC_val(1:end, i, k);
%                 MSFE_val_i_k = nansum(u_val_i_k.^2);
%                 R2OS_val_i_k = (1 - MSFE_val_i_k / MSFE_mean_k) * 100;
%                 oos_results(row_num, 2 * ica - 1) = R2OS_val_i_k;
% 
%                 f_CW_i_k = u_mean_k.^2 - u_val_i_k.^2 + ...
%                     (FC_mean(1:end, k) - FC_val(1:end, i, k)).^2;
%                 f_CW_i_k = f_CW_i_k(isfinite(f_CW_i_k));
%                 results_CW_i_k = nwest(f_CW_i_k, ones(length(f_CW_i_k), 1), nlag2);
%                 oos_results(row_num, 2 * ica) = 1 - normcdf(results_CW_i_k.tstat);
%             end
% 
%         end

        fprintf("oos\n")

        experiment_results(l).insample = in_sample_results;
        experiment_results(l).oos = oos_results;
    end

end

save('./Results/results.mat', 'experiment_results');

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

    fprintf("y-->")
end

function t=nw_tstat(X, y)
% newey west estimate (newey1987)
T = size(X, 1);
maxLag = floor(4*(T/100)^(2/9));
[~, se, coef] = hac(X, y, 'type', 'HAC', 'bandwidth', maxLag + 1, 'display', 'off');
tstat = coef ./ se;
t = tstat(2);
end