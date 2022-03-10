clear;

% plot r2 with different h
L = 6;
h = 1:12;
% plot r2 with different L
% L=[1 2 3 6 12 18 24 30 36];
% h=1;

nlag = 36; % for nwest
in_sample_period = 6 * 12;

for l = 1:length(L)

    if length(L) > 1
        regression_data(L(l), h);
    else
        regression_data(L, h);
    end

    load("regression_data.mat");

    y_h = y_h(:, 1:20, :);
    period = size(y_h, 1);
    num_x = size(x_L, 2);
    num_y = size(y_h, 2);

    if length(L) == 1
        r2_h = nan(num_x * num_y, length(h));

        for j = 1:length(h)
            row_num = 0;

            for k = 1:num_y

                for i = 1:num_x
                    row_num = row_num + 1;
                    x_reg = x_L(1:end - h(j), i);
                    X_i_j = [ones(period - h(j), 1) x_reg];
                    y_reg = y_h(2:end - (h(j) - 1), k, j);
                    del_nan = isfinite(x_reg) & isfinite(y_reg);
                    X_i_j = X_i_j(del_nan, :);
                    y_reg = y_reg(del_nan);
                    nw_results_i_j_k = nwest(y_reg, X_i_j, nlag);
                    r2_h(row_num, j) = nw_results_i_j_k.rsqr * 100;
                end

            end

        end

    else
        row_num = 0;

        for k = 1:num_y

            for i = 1:num_x
                row_num = row_num + 1;
                x_reg = x_L(1:end - h, i);
                X_i_j = [ones(period - h, 1) x_reg];
                y_reg = y_h(2:end - (h - 1), k, 1);
                del_nan = isfinite(x_reg) & isfinite(y_reg);
                X_i_j = X_i_j(del_nan, :);
                y_reg = y_reg(del_nan);
                nw_results_i_j_k = nwest(y_reg, X_i_j, nlag);
                r2_L(row_num, l) = nw_results_i_j_k.rsqr * 100;
            end

        end

    end

end

if length(L) == 1
    subplotR2(h, r2_h)
else
    subplotR2(L * 30, r2_L)
end

function subplotR2(x, y)
    % This function can plot the in-sample r2 with different Lags (on x or y)
    names = ["MI", "EL", "RE", "AP", "PU", "MAC", "CO", "TR", "FI", "HF", ...
            "TB", "CS", "PE", "FB", "ME", "IT", "PB", "PA", "MA", "OT"];
    num_y = size(y, 1);
    num_row = ceil(sqrt(num_y));
    num_col = ceil(num_y / num_row);
    % text_x=max(x) - 2;
    % text_x=max(x) - 5 * 30;  % used for R2_L figure
    lw = 2;  % linewidth
    for loc = 1:num_y
        subplot(num_row, num_col, loc)
        plot(x, y(loc, :),'Linewidth',lw)
        % text_y=max(y(loc,:)) - 1;
        % text(text_x,text_y,names(loc))
        title(names(loc));
    end

end
