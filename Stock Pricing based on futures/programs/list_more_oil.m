clear;

L = 6;
nlag = 36;

[x_L, y] = generate_data(L);

period = size(y, 1);
num_x = size(x_L, 2);
num_y = size(y, 2);

beta_lists = nan(num_y, num_x);

for k = 1:num_y

    for i = 1:num_x
        x_reg = x_L(1:end - 1, i);
        X_i = [ones(period - 1, 1) x_reg];
        y_reg = y(2:end, k);
        del_nan = isfinite(x_reg) & isfinite(y_reg);
        X_i = X_i(del_nan, :);
        y_reg = y_reg(del_nan);
        nw_results_i_k = nwest(y_reg, X_i, nlag);
        beta_lists(k, i) = nw_results_i_k.beta(2);
    end

end

output_file = './results/table_add.xlsx';
output_sheet = 'Oil Futrues beta';
xlswrite(output_file, beta_lists, output_sheet, 'b2');


function [x_L, y] = generate_data(L)

    input_file = './data/monthly_data.xlsx';
    x_index = 'b'+string(617 - L) + ':h832';
    x_inputs = xlsread(input_file, 'oil_last', x_index);
    x_inputs = x_inputs(:, [2, 4, 7]);
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
    
    y = log(y_inputs) - log(r_free);

end
