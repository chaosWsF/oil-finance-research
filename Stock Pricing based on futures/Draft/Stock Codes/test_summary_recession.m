clear;
set(gcf, 'Visible', 'off');

L = 6;
in_sample_period = 6 * 12;
nlag = 36;
summary_regression_data(L);
data_file = 'regression_data.mat';
load(data_file);

recessions = [
        datetime(2001,6,15),datetime(2005,6,6);
        datetime(2007,10,17),datetime(2008,10,28);
        datetime(2009,8,5),datetime(2014,6,20);
        datetime(2016,2,29),datetime(2016,11,15)
        ];

start_date = datetime(2001,4,1);
period = size(y_h, 1);
num_x = size(x_L, 2);
num_y = size(y_h, 2);
out_of_sample_period = period - in_sample_period;
FC_mean = nan(out_of_sample_period, num_y);
FC_val = nan(out_of_sample_period, num_x, length(h), num_y);
for o=1:out_of_sample_period
    disp(o)
    for k=1:num_y
        for i=1:num_x
            x_reg = x_L(1:in_sample_period+o-1-h, i);
            X_i_o = [ones(in_sample_period+o-1-h, 1) x_reg];
            y_reg = y_h(2:in_sample_period+o-h, k, 1);
            del_nan = isfinite(x_reg) & isfinite(y_reg);
            X_i_o = X_i_o(del_nan,:);
            y_reg = y_reg(del_nan);
            if length(y_reg) > 1
                results_i_k_o = ols(y_reg, X_i_o);
                FC_val(o,i,1,k) = [1 x_L(in_sample_period+o-1,i)]*...
                    results_i_k_o.beta;
            else
                FC_val(o,i,1,k) = nan;
            end
        end
        FC_mean(o,k) = mean_without_nan(y_h(1:in_sample_period+o-1,k,1));
    end
end

R2OS = nan(num_x*num_y, size(recessions,1), length(h));
row_num = 0;
for k=1:num_y
    actual_k = y_h(in_sample_period+1:end-(h-1), k, 1);
    u_mean_k = actual_k - FC_mean(1:end-(h-1), k);  % must no nan
    for i=1:num_x
        row_num = row_num + 1;
        u_val_i_k = actual_k - FC_val(1:end-(h-1),i,1,k); % must no nan
        f_CW_i_k = u_mean_k.^2-u_val_i_k.^2+...
            (FC_mean(1:end-(h-1),k)-FC_val(1:end-(h-1),...
            i,1,k)).^2; % must no nan
        plot_MSFE(start_date, in_sample_period, u_mean_k, ...
            u_val_i_k, period, k, recessions);
        R2OS(row_num,:,1) = calr2os(u_mean_k, u_val_i_k, ...
            start_date, in_sample_period, recessions);
    end
end

xlswrite('./results/summary.xlsx',R2OS,'Recession','b2');

function r2os=calr2os(u_mean,u_val,start_date,in_sample,recessions)
    r2os = nan(size(recessions,1),1);
    start_date = start_date + calmonths(in_sample); % out-of-sample start
    for r=1:size(recessions,1)
        if (recessions(r,1) < start_date) && (recessions(r,2)>start_date)
            recessions(r,1) = start_date;
        end
        try
            recession_start = split(caldiff([start_date,recessions(r,1)],...
                'months'),'m') + 1;
            recession_end = split(caldiff([start_date,recessions(r,2)],...
                'months'),'m') + 1;
            u_mean_r = u_mean(recession_start:recession_end);
            u_val_r = u_val(recession_start:recession_end);

            MSFE_val = sum(u_val_r.^2);
            MSFE_mean = sum(u_mean_r.^2);
            R2OS_val = (1 - MSFE_val/MSFE_mean) * 100;
            r2os(r,1) = R2OS_val';
        catch
             fprintf('Missing %s-%s\n', string(recessions(r,1)), ...
                 string(recessions(r,2)));
        end
     end
end

function plot_MSFE(start_date, in_sample, u_mean, u_val, period, k, recessions)
    
    CSFE1 = cumsum(u_mean.^2);
    CSFE2 = cumsum(u_val.^2);
    CSFE_diff = CSFE1 - CSFE2;

    t = start_date + calmonths(in_sample:period-1);
    
    plot(t, CSFE_diff);
    
    % % Recessions Data: [begin1,stop1;begin2,end2;...]
    % recessionplot('recessions',recessions);
    
    xlim([start_date+calmonths(in_sample) start_date+calmonths(period-1)]);
    xlabel('Date');
    ylabel('$\Delta \mathrm{CSFE}$','interpreter','latex');
    xtickformat('yyyy');
    xtickangle(30);

    grid on;
    ax = gca;
    ax.XMinorGrid = 'on';

    figname = sprintf('./results/CSFE/industry%1d.png', k-1);
    disp(figname)
    saveas(gcf, figname);
end