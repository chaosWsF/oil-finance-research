function regression_data(L, data_class)
    input_file='../../EX/EX.xlsx';
    x_index='b'+string(362-L)+':b792';
    x_inputs=xlsread(input_file,'oil_last',x_index);
    r_free=xlsread(input_file,'r_free','c2:c169');
    y_inputs=xlsread(input_file,data_class,'b2:bb432');

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
    y=logR;
    y_period=size(y,1);

    % MA y t:t+h
    h=[1 3 6 12];
    y_h=nan(y_period,size(y,2),length(h));
    rf_h=nan(y_period,length(h));
    for j=1:length(h)
        for t=1:y_period-(h(j)-1)
            logR_t_h=logR(t:t+h(j)-1,:);
            y_h(t,:,j)=mean_without_nan(logR_t_h);
        end
    end

    save('regression_data.mat','x_L','y_h','h','rf_h');
end