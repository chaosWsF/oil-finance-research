clear;

L = [1 2 3 6 12 18 24 30 36] * 21;
nlag = 36 * 21;

oilType = 'arabian';
% oilType = 'brent';
% oilType = 'oil_futures';
stockType = 'ind';
% stockType = 'green';

if strcmp(stockType, 'ind')
    in_sample_period = 6 * 12 * 21;
elseif strcmp(stockType, 'green')
    in_sample_period = 2 * 12 * 21;
end

for l=1:length(L)
    % load data
    test_regression_data_daily(L(l),oilType,stockType);

    output_file='../../data/results_daily/results_oil_%s_Lags/%s/results_%d.xlsx';
    output_file = sprintf(output_file,stockType,oilType,L(l)/21);
    disp(output_file)

    data_file = 'regression_data_daily.mat';
    load(data_file);
    period=size(y_h,1);
    num_x=size(x_L,2);
    num_y=size(y_h,2);

    % in-sample  test_results <- beta-hat t-stat R2
    test_results=nan(num_x*num_y,3,length(h));
    for j=1:length(h)
        row_num=0;
        for k=1:num_y
            for i=1:num_x
                row_num=row_num+1;
                x_reg=x_L(1:end-h(j),i);
                X_i_j=[ones(period-h(j),1) x_reg];
                y_reg=y_h(2:end-(h(j)-1),k,j);
                del_nan=isfinite(x_reg)&isfinite(y_reg);
                X_i_j=X_i_j(del_nan,:);
                y_reg=y_reg(del_nan);
                nw_results_i_j_k=nwest(y_reg,X_i_j,nlag);
                test_results(row_num,:,j)=[nw_results_i_j_k.beta(2)...
                    nw_results_i_j_k.tstat(2) nw_results_i_j_k.rsqr];
            end
        end
    end

    output_sheet='In-Sample';
    xlswrite(output_file,test_results(:,:,1),output_sheet,'b3');
    xlswrite(output_file,test_results(:,:,2),output_sheet,'f3');
    xlswrite(output_file,test_results(:,:,3),output_sheet,'j3');
    xlswrite(output_file,test_results(:,:,4),output_sheet,'n3');

    % out-of-sample
    out_of_sample_period=period-in_sample_period;
    FC_RW=zeros(out_of_sample_period,num_y);
    FC_val=nan(out_of_sample_period,num_x,length(h),num_y);
    for o=1:out_of_sample_period
        disp(o)
        for k=1:num_y
            for j=1:length(h)
                for i=1:num_x
                    x_reg=x_L(1:in_sample_period+o-1-h(j),i);
                    X_i_j_o=[ones(in_sample_period+o-1-h(j),1) x_reg];
                    y_reg=y_h(2:in_sample_period+o-h(j),k,j);
                    del_nan=isfinite(x_reg)&isfinite(y_reg);
                    X_i_j_o=X_i_j_o(del_nan,:);
                    y_reg=y_reg(del_nan);
                    if length(y_reg)>1
                        results_i_j_k_o=ols(y_reg,X_i_j_o);
                        FC_val(o,i,j,k)=[1 x_L(in_sample_period+o-1,i)]*...
                            results_i_j_k_o.beta;
                    else
                        FC_val(o,i,j,k)=nan;
                    end
                end
            end
        end
    end

    % R2OS
    R2OS=nan(num_x*num_y,2,length(h));
    for j=1:length(h)
        row_num=0;
        for k=1:num_y
            actual_j_k=y_h(in_sample_period+1:end-(h(j)-1),k,j);
            u_mean_j_k=actual_j_k-FC_RW(1:end-(h(j)-1),k);
            u_mean_j_k_nonan=u_mean_j_k(isfinite(u_mean_j_k));
            MSFE_mean_j_k=sum(u_mean_j_k_nonan.^2);
            for i=1:num_x
                row_num=row_num+1;
                u_val_i_j_k=actual_j_k-FC_val(1:end-(h(j)-1),i,j,k);
                u_val_i_j_k_nonan=u_val_i_j_k(isfinite(u_val_i_j_k));
                MSFE_val_i_j_k=sum(u_val_i_j_k_nonan.^2);
                R2OS_val_i_j_k=1-MSFE_val_i_j_k/MSFE_mean_j_k;
                R2OS(row_num,1,j)=R2OS_val_i_j_k';

                f_CW_i_j_k=u_mean_j_k.^2-u_val_i_j_k.^2+...
                    (FC_RW(1:end-(h(j)-1),k)-FC_val(1:end-(h(j)-1),...
                    i,j,k)).^2;
                f_CW_i_j_k=f_CW_i_j_k(isfinite(f_CW_i_j_k));
                results_CW_i_j_k=nwest(f_CW_i_j_k,...
                    ones(length(f_CW_i_j_k),1),nlag);
                R2OS(row_num,2,j)=results_CW_i_j_k.tstat;
            end
        end
    end

    output_sheet='Out-of-Sample';
    xlswrite(output_file,R2OS(:,:,1),output_sheet,'b3');
    xlswrite(output_file,R2OS(:,:,2),output_sheet,'e3');
    xlswrite(output_file,R2OS(:,:,3),output_sheet,'h3');
    xlswrite(output_file,R2OS(:,:,4),output_sheet,'k3');
end