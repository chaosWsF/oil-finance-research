clear;
set(gcf, 'Visible', 'off');

L = 6;
% L = 1;
start_date = datetime(2001,4,1);
in_sample_period = 6 * 12;
% in_sample_period = 4 * 12;  % subsample
window_size = 2 * 12; % calaculate the volatility
RRA = 3;  % risk aversion coeff
w_LB = 0;
w_UB = 1;

output_file='../../results/summary_ind_arabian.xlsx';
disp(output_file)

summary_regression_data(L);
data_file = 'regression_data.mat';
load(data_file);

period=size(y_h,1);
num_x=size(x_L,2);
num_y=size(y_h,2);

% out-of-sample
out_of_sample_period=period-in_sample_period;
FC_PM=nan(out_of_sample_period,num_y,length(h));
w_PM=nan(out_of_sample_period,num_y,length(h));
R_PM=nan(out_of_sample_period,num_y,length(h));
ER_PM=nan(out_of_sample_period,num_y,length(h));
FC_val=nan(out_of_sample_period,num_x,length(h),num_y);
w_val=nan(out_of_sample_period,num_x,length(h),num_y);
R_val=nan(out_of_sample_period,num_x,length(h),num_y);
ER_val=nan(out_of_sample_period,num_x,length(h),num_y);
FC_vol=nan(out_of_sample_period,num_y,length(h));
for o=1:out_of_sample_period
    disp(o)
    for k=1:num_y
        % Volatility
        if in_sample_period+o-h<=window_size-1
            FC_vol(o,k,1)=std_without_nan(y_h(in_sample_period+o-h,k,1));
        else
            FC_vol(o,k,1)=std_without_nan(y_h(in_sample_period+o-h...
                -(window_size-1):in_sample_period+o-h,k,1));
        end
        % Prevailing mean benchmark
        FC_PM(o,k,1)=mean_without_nan(y_h(1:in_sample_period+o-1,k,1));
        % Predictive regression
        for i=1:num_x
            x_reg=x_L(1:in_sample_period+o-1-h,i);
            X_i_o=[ones(in_sample_period+o-1-h,1) x_reg];
            y_reg=y_h(2:in_sample_period+o-h,k,1);
            del_nan=isfinite(x_reg)&isfinite(y_reg);
            X_i_o=X_i_o(del_nan,:);
            y_reg=y_reg(del_nan);
            if length(y_reg)>1
                results_i_k_o=ols(y_reg,X_i_o);
                FC_val(o,i,1,k)=[1 x_L(in_sample_period+o-1,i)]*...
                    results_i_k_o.beta;
            else
                FC_val(o,i,1,k)=nan;
            end
        end
    end
end

% Computing portfolio weights/returns
for t=1:out_of_sample_period/h
    for k=1:num_y
        FC_vol_k_t=FC_vol((t-1)*h+1,k,1);
        FC_PM_k_t=FC_PM((t-1)*h+1,k,1);
        w_PM_k_t=(1/RRA)*FC_PM_k_t/FC_vol_k_t^2;
        if w_PM_k_t>w_UB
            w_PM((t-1)*h+1,k,1)=w_UB;
        elseif w_PM_k_t<w_LB
            w_PM((t-1)*h+1,k,1)=w_LB;
        else
            w_PM((t-1)*h+1,k,1)=w_PM_k_t;
        end
        R_PM((t-1)*h+1,k,1)=rf_h(in_sample_period+(t-1)*h+1,....
            1)+w_PM((t-1)*h+1,k,1)*y_h(in_sample_period+...
            (t-1)*h+1,k,1);
        ER_PM((t-1)*h+1,k,1)=R_PM((t-1)*h+1,k,1)-...
            rf_h(in_sample_period+(t-1)*h+1,1);
        
        for i=1:num_x
            FC_val_i_k_t=FC_val((t-1)*h+1,i,1,k);
            w_val_i_k_t=(1/RRA)*FC_val_i_k_t/FC_vol_k_t^2;
            if w_val_i_k_t>w_UB
                w_val((t-1)*h+1,i,1,k)=w_UB;
            elseif w_val_i_k_t<w_LB
                w_val((t-1)*h+1,i,1,k)=w_LB;
            else
                w_val((t-1)*h+1,i,1,k)=w_val_i_k_t;
            end
            R_val((t-1)*h+1,i,1,k)=rf_h(in_sample_period+...
                (t-1)*h+1,1)+w_val((t-1)*h+1,i,1,k)*...
                y_h(in_sample_period+(t-1)*h+1,k,1);
            ER_val((t-1)*h+1,i,1,k)=R_val((t-1)*h+1,...
                i,1,k)-rf_h(in_sample_period+(t-1)*h+1,1);
        end
    end
end

% Compute CER gains and Sharpe ratios for full period
CER_gain=nan(num_x*num_y,length(h));
Sharpe_gain=nan(num_x*num_y,length(h));
AR=nan(num_x*num_y,length(h));
row_num=0;
for k=1:num_y
    R_PM_k=R_PM(:,k,1);
    ER_PM_k=ER_PM(:,k,1);
    CER_PM_k=(12/h)*(mean_without_nan(R_PM_k)- ...
        0.5*RRA*std_without_nan(R_PM_k)^2);
    Sharpe_PM_k=sqrt((12/h))*mean_without_nan(ER_PM_k)/ ...
        std_without_nan(ER_PM_k);
    for i=1:num_x
        row_num=row_num+1;
        R_val_i_k=R_val(:,i,1,k);
        plot_cr(R_PM_k, R_val_i_k,...
            start_date,in_sample_period,period,k);
        ER_val_i_k=ER_val(:,i,1,k);
        CER_val_i_k=(12/h)*(mean_without_nan(R_val_i_k)- ...
            0.5*RRA*std_without_nan(R_val_i_k)^2);
        Sharpe_val_i_k=sqrt((12/h))*mean_without_nan(ER_val_i_k)/...
            std_without_nan(ER_val_i_k);
        CER_gain(row_num,1)=100*(CER_val_i_k-CER_PM_k);
        Sharpe_gain(row_num,1)=Sharpe_val_i_k-Sharpe_PM_k;
        AR(row_num,1)=(12/h)*(mean_without_nan(R_val_i_k))*0.97;
    end
end

xlswrite(output_file,CER_gain,'CER & Sharpe','c2');
xlswrite(output_file,Sharpe_gain,'CER & Sharpe','d2');
xlswrite(output_file,AR,'CER & Sharpe','e2');

% xlswrite(output_file,CER_gain,'CER & Sharpe','h2');
% xlswrite(output_file,Sharpe_gain,'CER & Sharpe','i2');
% xlswrite(output_file,AR,'CER & Sharpe','j2');

function plot_cr(r_PM, r_val, start_date, in_sample, period, k)
    cr_val = cumsum(r_val,1);
    cr_PM = cumsum(r_PM,1);
    
    t = start_date + calmonths(in_sample:period-1);
    
    plot(t, cr_val, t, cr_PM, '--');
    legend('Model', 'Prevailing Mean');
    
    xlim([start_date+calmonths(in_sample) start_date+calmonths(period-1)]);
    title('Industry ' + string(k));
    xlabel('Date');
    ylabel('Cumulative Return');
    xtickformat('yyyy');
    xtickangle(30);
    
    grid on;
    ax = gca;
    ax.XMinorGrid = 'on';

    figname=sprintf('../../results/pictures/Cumulative Return/industry%1d.png',k);
    disp(figname)
    saveas(gcf, figname);
end