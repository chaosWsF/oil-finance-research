function regression_data(L, h)
    % This function is to read the regression data, calculate return and do
    % moving average on them. The input are the lag of trend on independent
    % variables (x), and the lag list of dependent varibales (y). The output
    % data consists of trended independent variables (x_L), moving average on
    % dependent variables (y_h) for robustness test and used lag list (h),
    % risk-free data after moving average by h.

    input_file = './data/monthly_data.xlsx';

    x_index = 'f'+string(616 - L) + ':f831';
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

    % log return & return
    logR = log(y_inputs) - log(r_free);
    R = y_inputs - r_free;
    y = [logR R];
    y_period = size(y, 1);

    % MA y t:t+h
    y_h = nan(y_period, size(y, 2), length(h));
    rf_h = nan(y_period, length(h));

    for j = 1:length(h)

        for t = 1:y_period - (h(j) - 1)
            half = size(y, 2) / 2;
            logR_t_h = logR(t:t + h(j) - 1, :);
            y_h(t, 1:half, j) = mean_without_nan(logR_t_h);
            temp1 = y_inputs(t:t + h(j) - 1, :);
            temp2 = r_free(t:t + h(j) - 1);

            if any([isfinite(temp1) isfinite(temp2)])
                y_h(t, half + 1:end, j) = prod(temp1, 1, 'omitnan') - ...
                    prod(temp2, 'omitnan');
                rf_h(t, j) = prod(temp2, 'omitnan');
            end

        end

    end

    output_data = 'regression_data.mat';
    save(output_data, 'x_L', 'y_h', 'h', 'rf_h');
