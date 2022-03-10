clear;

L = 6;
nlag = 36;

output_file = './results/summary.xlsx';
further_data(L);
data_file = 'regression_data_res.mat';
load(data_file);

results_eps = in_sample_reg(epsilon, x_L, nlag);
results_iv = in_sample_reg(IV, x_L, nlag);
results_is = in_sample_reg(IS, x_L, nlag);

output_sheet = 'RES_IV_IS';
xlswrite(output_file, results_eps, output_sheet, 'c3');
xlswrite(output_file, results_iv, output_sheet, 'f3');
xlswrite(output_file, results_is, output_sheet, 'i3');

function further_data(L)
    % This function is to read the regression data, calculate return and do
    % moving average on them. The input is the lag of trend on independent
    % variables (x). And the output data consists of trended independent
    % variables (x_L), and res_is_iv data.
    % data -- 2002:01-2019:03
    input_file = './data/monthly_data.xlsx';
    x_index = 'c'+string(625 - L) + ':c831';
    x_inputs = xlsread(input_file, 'oil_last', x_index);
    y_index = 'b2:u208';
    epsilon = xlsread(input_file, 'epsilon', y_index);
    IV = xlsread(input_file, 'IV', y_index);
    IS = xlsread(input_file, 'IS', y_index);

    x_period = size(x_inputs, 1);
    x_L = nan(x_period - (L - 1), size(x_inputs, 2));

    for t = L:x_period
        x_t = x_inputs(t - (L - 1):t, :);
        x_L(t - (L - 1), :) = mean_without_nan(x_t);
    end

    x_L = log(x_L(2:end, :)) - log(x_L(1:end - 1, :));

    output_data = 'regression_data_res.mat';
    save(output_data, 'x_L', 'epsilon', 'IV', 'IS');
end

function test_results = in_sample_reg(y, x, lag)
    % do the in-sample regression
    period = size(y, 1);
    num_x = size(x, 2);
    num_y = size(y, 2);

    test_results = nan(num_x * num_y, 3);
    row_num = 0;

    for k = 1:num_y

        for i = 1:num_x
            row_num = row_num + 1;
            x_reg = x(1:end - 1, i);
            X_i_k = [ones(period - 1, 1) x_reg];
            y_reg = y(2:end, k);
            del_nan = isfinite(x_reg) & isfinite(y_reg);
            X_i_k = X_i_k(del_nan, :);
            y_reg = y_reg(del_nan);
            % uncomment the following to use nwest regression
            %             nw_results_i_k=nwest(y_reg,X_i_k,lag);
            %             nw_p_value = 2 * normcdf(-abs(nw_results_i_k.tstat(2)));
            %             test_results(row_num,:)=[nw_results_i_k.beta(2)...
            %                 nw_p_value nw_results_i_k.rsqr*100];
            % uncomment the following to use ols regression
            results_i_k = ols(y_reg, X_i_k);
            p_value = 2 * normcdf(-abs(results_i_k.tstat(2)));
            test_results(row_num, :) = [results_i_k.beta(2) ...
                                    p_value results_i_k.rsqr * 100];
        end

    end

end
