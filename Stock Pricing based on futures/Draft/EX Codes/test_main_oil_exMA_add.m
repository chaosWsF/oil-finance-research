%%%%%%%%%%%%%%%%%%%
% asset allocation
%%%%%%%%%%%%%%%%%%%

% Created by WSF: 04-14-2019
% Last modified by WSF: 04-17-2019

clear;
% load data
load('regression_data.mat');
period=size(y_h,1);
num_x=size(x_L,2);
num_y=size(y_h,2)/2;
ER_h=y_h(:,num_y+1:end,:);
R_f_h=rf_h;

% Take care of preliminaries

in_sample_period=200;   % months
out_of_sample_period=period-in_sample_period;
FC_RW=zeros(out_of_sample_period,num_y,length(h));
w_RW=nan(out_of_sample_period,num_y,length(h));
R_RW=nan(out_of_sample_period,num_y,length(h));
ER_RW=nan(out_of_sample_period,num_y,length(h));
FC_val=nan(out_of_sample_period,num_x,length(h),num_y);
w_val=nan(out_of_sample_period,num_x,length(h),num_y);
R_val=nan(out_of_sample_period,num_x,length(h),num_y);
ER_val=nan(out_of_sample_period,num_x,length(h),num_y);
R_BH=nan(out_of_sample_period,num_y,length(h));
ER_BH=nan(out_of_sample_period,num_y,length(h));
FC_vol=nan(out_of_sample_period,num_y,length(h));

window=120;
RRA=3;  % risk aversion coeff
w_LB=-0.5;
w_UB=1.5;

% out-of-sample

for o=1:out_of_sample_period
    for k=1:num_y
        disp([o,k])
        for j=1:length(h)
            % Volatility
            if in_sample_period+o-h(j)<=window-1
                ER_h_o=ER_h(in_sample_period+o-h(j),k,j);
                ER_h_0_nonan=ER_h_o(isfinite(ER_h_o));
                FC_vol(o,k,j)=std(ER_h_o_nonan);
            else
                ER_h_o=ER_h(in_sample_period+o-h(j)-(window-1)...
                    :in_sample_period+o-h(j),k,j);
                ER_h_o_nonan=ER_h_o(isfinite(ER_h_o));
                FC_vol(o,k,j)=std(ER_h_o_nonan);
            end
            % Predictive regression
            for i=1:num_x
                x_reg=x_L(1:in_sample_period+o-1-h(j),i);
                X_i_j_o=[ones(in_sample_period+o-1-h(j),1) x_reg];
                y_reg=ER_h(2:in_sample_period+o-h(j),k,j);
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

% Computing portfolio weights/returns

for j=1:length(h)
    for t=1:out_of_sample_period/h(j)
        for k=1:num_y
            FC_vol_j_k_t=FC_vol((t-1)*h(j)+1,k,j);

            FC_RW_j_k_t=FC_RW((t-1)*h(j)+1,k,j);
            w_RW_j_k_t=(1/RRA)*FC_RW_j_k_t/FC_vol_j_k_t^2;
            if w_RW_j_k_t>w_UB
                w_RW((t-1)*h(j)+1,k,j)=w_UB;
            elseif w_RW_j_k_t<w_LB
                w_RW((t-1)*h(j)+1,k,j)=w_LB;
            else
                w_RW((t-1)*h(j)+1,k,j)=w_RW_j_k_t;
            end
            R_RW((t-1)*h(j)+1,k,j)=R_f_h(in_sample_period+(t-1)*h(j)+1,....
                j)+w_RW((t-1)*h(j)+1,k,j)*ER_h(in_sample_period+...
                (t-1)*h(j)+1,k,j);
            ER_RW((t-1)*h(j)+1,k,j)=R_RW((t-1)*h(j)+1,k,j)-...
                R_f_h(in_sample_period+(t-1)*h(j)+1,j);
            for i=1:num_x
                FC_val_i_j_k_t=FC_val((t-1)*h(j)+1,i,j,k);
                w_val_i_j_k_t=(1/RRA)*FC_val_i_j_k_t/FC_vol_j_k_t^2;
                if w_val_i_j_k_t>w_UB
                    w_val((t-1)*h(j)+1,i,j,k)=w_UB;
                elseif w_val_i_j_k_t<w_LB
                    w_val((t-1)*h(j)+1,i,j,k)=w_LB;
                else
                    w_val((t-1)*h(j)+1,i,j,k)=w_val_i_j_k_t;
                end
                R_val((t-1)*h(j)+1,i,j,k)=R_f_h(in_sample_period+...
                    (t-1)*h(j)+1,j)+w_val((t-1)*h(j)+1,i,j,k)*...
                    ER_h(in_sample_period+(t-1)*h(j)+1,k,j);
                ER_val((t-1)*h(j)+1,i,j,k)=R_val((t-1)*h(j)+1,...
                    i,j,k)-R_f_h(in_sample_period+(t-1)*h(j)+1,j);
            end
            R_BH((t-1)*h(j)+1,k,j)=R_f_h(in_sample_period+(t-1)*h(j)+1,...
                j)+ER_h(in_sample_period+(t-1)*h(j)+1,k,j);
            ER_BH((t-1)*h(j)+1,k,j)=ER_h(in_sample_period+(t-1)*h(j)+1,...
                k,j);
        end
    end
end

% Compute CER gains and Sharpe ratios for full period

CER_gain=nan(num_x*num_y+1,length(h));
Sharpe=nan(num_x*num_y+2,length(h));
for j=1:length(h)
    row_num=1;
    for k=1:num_y
        R_RW_j_k=R_RW(:,k,j);
        R_RW_j_k=R_RW_j_k(isfinite(R_RW_j_k));
        ER_RW_j_k=ER_RW(:,k,j);
        ER_RW_j_k=ER_RW_j_k(isfinite(ER_RW_j_k));
        CER_RW_j_k=(12/h(j))*(mean(R_RW_j_k)-0.5*RRA*std(R_RW_j_k)^2);
        Sharpe(1,j)=sqrt((12/h(j)))*mean(ER_RW_j_k)/std(ER_RW_j_k);
        R_BH_j_k=R_BH(:,k,j);
        R_BH_j_k=R_BH_j_k(isfinite(R_BH_j_k));
        ER_BH_j_k=ER_BH(:,k,j);
        ER_BH_j_k=ER_BH_j_k(isfinite(ER_BH_j_k));
        CER_BH_j_k=(12/h(j))*(mean(R_BH_j_k)-0.5*RRA*std(R_BH_j_k)^2);
        CER_gain(1,j)=100*(CER_BH_j_k-CER_RW_j_k);
        Sharpe(2,j)=sqrt((12/h(j)))*mean(ER_BH_j_k)/std(ER_BH_j_k);
        for i=1:num_x
            row_num=row_num+1;
            R_val_i_j_k=R_val(:,i,j,k);
            R_val_i_j_k=R_val_i_j_k(isfinite(R_val_i_j_k));
            ER_val_i_j_k=ER_val(:,i,j,k);
            ER_val_i_j_k=ER_val_i_j_k(isfinite(ER_val_i_j_k));
            CER_val_i_j_k=(12/h(j))*(mean(R_val_i_j_k)-...
                0.5*RRA*std(R_val_i_j_k)^2);
            CER_gain(row_num,j)=100*(CER_val_i_j_k-CER_RW_j_k);
            Sharpe(row_num+1,j)=sqrt((12/h(j)))*mean(ER_val_i_j_k)/...
                std(ER_val_i_j_k);
        end
    end
end

output_file='../../EX/results/results_oil_ex.xlsx';
xlswrite(output_file,CER_gain,'Asset allocation CER','b5');
xlswrite(output_file,Sharpe,'Asset allocation Sharpe','b5');
