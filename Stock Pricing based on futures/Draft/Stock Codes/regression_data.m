function regression_data(L)
    input_file='../../data/month_ara_bre_dub_fut_cus_mid_sh300.xlsx';
    
    x_index='b'+string(616-L)+':b792';
    x_inputs=xlsread(input_file,'oil_last',x_index);
    r_free=xlsread(input_file,'r_free','b2:b112');
    y_inputs=xlsread(input_file,'stock','d126:w302');
    
    % % deal with industry
    % x_index='c'+string(616-L)+':c831';    % brent
    % % x_index='e'+string(616-L)+':e831';  % oil_futures
    % x_inputs=xlsread(input_file,'oil_last',x_index);
    % r_free=xlsread(input_file,'r_free','b2:b151');
    % y_inputs=xlsread(input_file,'stock','d126:w341');

    % % deal with green
    % x_index='c'+string(528-L)+':c831';  % brent
    % % x_index='e'+string(528-L)+':e831';    % oil_futures
    % x_inputs=xlsread(input_file,'oil_last',x_index);
    % r_free=xlsread(input_file,'r_free','b2:b151');
    % y_inputs=xlsread(input_file,'stock','aa38:aa341');

    x_period=size(x_inputs,1);
    x_L=nan(x_period-(L-1),size(x_inputs,2));
    for t=L:x_period
        x_t=x_inputs(t-(L-1):t,:);
        x_L(t-(L-1),:)=mean_without_nan(x_t);
    end
    x_L=log(x_L(2:end,:))-log(x_L(1:end-1,:));

    if length(r_free) < size(y_inputs,1)
        r_free = [ones(1,size(y_inputs,1)-length(r_free)) r_free']';
    end

    % log return & return
    logR=log(y_inputs)-log(r_free);
    R=y_inputs-r_free;
    y=[logR R];
    y_period=size(y,1);

    % MA y t:t+h
    h=[1 3 6 12];
    y_h=nan(y_period,size(y,2),length(h));
    rf_h=nan(y_period,length(h));
    for j=1:length(h)
        for t=1:y_period-(h(j)-1)
            half=size(y,2)/2;
            logR_t_h=logR(t:t+h(j)-1,:);
            y_h(t,1:half,j)=mean_without_nan(logR_t_h);
            temp1=y_inputs(t:t+h(j)-1,:);
            temp2=r_free(t:t+h(j)-1);
            if any([isfinite(temp1) isfinite(temp2)])
                y_h(t,half+1:end,j)=prod(temp1,1,'omitnan')-...
                    prod(temp2,'omitnan');
                rf_h(t,j)=prod(temp2,'omitnan');
            end
        end
    end
    
    output_data = 'regression_data.mat';
    save(output_data,'x_L','y_h','h','rf_h');