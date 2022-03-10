clear;
set(gcf, 'Visible', 'off');

L = 2;
in_sample_period = 20 * 12;   % months
nlag = 6;

% ex
% regression_data_summary(L,'EX');
% output_file = '../../results/summary_nominal.xlsx';
% mkdir('./figures/ex/'+string(in_sample_period / 12));
% real_ex
regression_data_summary(L,'real_ex');
output_file = '../../results/summary_real.xlsx';
mkdir('./figures/real_ex/'+string(in_sample_period / 12));
disp(output_file)

load('regression_data.mat');
period=size(y_h,1);
num_x=size(x_L,2);
num_y=size(y_h,2);

% in-sample
test_results=nan(num_x*num_y,3,1);
row_num=0;
for k=1:num_y
    for i=1:num_x
        row_num=row_num+1;
        x_reg=x_L(1:end-h,i);
        X_i=[ones(period-h,1) x_reg];
        y_reg=y_h(2:end-(h-1),k,1);
        del_nan=isfinite(x_reg)&isfinite(y_reg);
        X_i=X_i(del_nan,:);
        y_reg=y_reg(del_nan);
        nw_results_i_j_k=nwest(y_reg,X_i,nlag);
        p_value = 2 * normcdf(-abs(nw_results_i_j_k.tstat(2)));
        test_results(row_num,:,1)=[nw_results_i_j_k.beta(2)...
            p_value nw_results_i_j_k.rsqr];
    end
end

% out-of-sample
out_of_sample_period=period-in_sample_period;
FC_RW=zeros(out_of_sample_period,num_y);
FC_val=nan(out_of_sample_period,num_x,1,num_y);
for o=1:out_of_sample_period
    disp(o)
    for k=1:num_y
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
% R2OS
R2OS=nan(num_x*num_y,2,1);
row_num=0;
for k=1:num_y
    actual_k=y_h(in_sample_period+1:end-(h-1),k,1);
    u_mean_k=actual_k-FC_RW(1:end-(h-1),k);
    u_mean_k_nonan=u_mean_k(isfinite(u_mean_k));
    MSFE_mean_k=sum(u_mean_k_nonan.^2);
    for i=1:num_x
        row_num=row_num+1;
        u_val_i_k=actual_k-FC_val(1:end-(h-1),i,1,k);
        u_val_i_k_nonan=u_val_i_k(isfinite(u_val_i_k));
        try
            plot_MSFE(in_sample_period, u_mean_k_nonan, ...
                u_val_i_k_nonan, k);
        catch
            disp(k)
        end
        MSFE_val_i_k=sum(u_val_i_k_nonan.^2);
        R2OS_val_i_k=1-MSFE_val_i_k/MSFE_mean_k;
        R2OS(row_num,2,1)=R2OS_val_i_k';

        f_CW_i_k=u_mean_k.^2-u_val_i_k.^2+...
            (FC_RW(1:end-(h-1),k)-FC_val(1:end-(h-1),...
            i,1,k)).^2;
        f_CW_i_k=f_CW_i_k(isfinite(f_CW_i_k));
        results_CW_i_k=nwest(f_CW_i_k,...
            ones(length(f_CW_i_k),1),nlag);
        p_value_out = 1 - normcdf(results_CW_i_k.tstat);
        R2OS(row_num,1,1)=p_value_out;
    end
end

output_sheet='In-Sample';
xlswrite(output_file,test_results(:,:,1),output_sheet,'c2');
output_sheet='Out-of-Sample';
xlswrite(output_file,R2OS(:,:,1),output_sheet,'c2');