function test_regression_data_daily(L, oil_type, stock_type)

    % ind -- 2001:04:03-2019:03:29
    % arabian & ind -- 2001:04:03-2015:12:31
    % green -- 1995:01:03-2019:03:29

    input_file='../../data/daily_data_all.xlsx';

    if strcmp(stock_type, 'ind')
        if strcmp(oil_type, 'brent')
            y_index = 'd2549:w6915';
            x_index='d'+string(2549-L)+':d6914';
        elseif strcmp(oil_type, 'oil_futures')
            y_index = 'd2549:w6915';
            x_index='e'+string(2549-L)+':e6914';
        else
            y_index = 'd2549:w6126';
            x_index = 'b' + string(2549-L) + ':b6125';
        end
    elseif strcmp(stock_type, 'green')
        y_index = 'aa1029:aa6915';
        if strcmp(oil_type, 'brent')
            x_index='d'+string(1029-L)+':d6914';
        elseif strcmp(oil_type, 'oil_futures')
            x_index='e'+string(1029-L)+':e6914';
        end
    end

    free_index = 'b2:b3121';
    x_inputs=xlsread(input_file,'oil',x_index);
    r_free=xlsread(input_file,'r_free',free_index);
    y_inputs=xlsread(input_file,'stock',y_index);

    x_period=size(x_inputs,1);
    x_L=nan(x_period-(L-1),size(x_inputs,2));
    for t=L:x_period
        x_t=x_inputs(t-(L-1):t,:);
        x_L(t-(L-1),:)=mean_without_nan(x_t);
    end
    x_L=log(x_L(2:end,:))-log(x_L(1:end-1,:));

    r_free = 1 + r_free / 252 / 100;
    if length(r_free) < size(y_inputs,1) - 1
        r_free = [ones(1,size(y_inputs,1)-1-length(r_free)) r_free']';
    end

    % log return & return
    y_inputs = y_inputs(2:end,:) ./ y_inputs(1:end-1,:);
    logR=log(y_inputs)-log(r_free);
    R=y_inputs-r_free;
    y=[logR R];
    y_period=size(y,1);

    % MA y t:t+h
    h=[1 3 6 12] * 21;
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
    
    output_data = 'regression_data_daily.mat';
    save(output_data,'x_L','y_h','h','rf_h');
