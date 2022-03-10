function summary_regression_data(L)
    % This function is to read the regression data, calculate return and do
    % moving average on them. The input is the lag of trend on independent
    % variables (x). And the output data consists of trended independent
    % variables (x_L), moving average on dependent variables (y_h) for
    % robustness test and used lag list (h), risk-free data after moving
    % average by h.

    input_file = './data/monthly_data.xlsx';

    % industry 2001:04-2019:03, hs300 2002:01-2019:03
    x_index = 'e'+string(617 - L) + ':e832'; % oil_fut
    x_inputs = xlsread(input_file, 'oil_last', x_index);
    r_free = xlsread(input_file, 'r_free', 'b2:b151');
    y_inputs = xlsread(input_file, 'stock', 'c126:w341');

    % uncomment one of two block followed to test subsample
    % industry subsample1 2001:04-2010:03
%     x_index = 'e' + string(617 - L) + ':e724';
%     x_inputs = xlsread(input_file, 'oil_last', x_index);
%     r_free = xlsread(input_file, 'r_free', 'b2:b43');
%     y_inputs = xlsread(input_file, 'stock', 'c126:w233');

    % industry subsample2 2010:04-2019:03
%     x_index = 'e' + string(725 - L) + ':e832';
%     x_inputs = xlsread(input_file, 'oil_last', x_index);
%     r_free = xlsread(input_file, 'r_free', 'b44:b151');
%     y_inputs = xlsread(input_file, 'stock', 'c234:w341');

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

    output_data = 'regression_data.mat';
    save(output_data, 'x_L', 'y_h', 'h', 'rf_h');
