clear;

filePath = '../../data/month_ara_bre_dub_fut_cus_mid_sh300.xlsx';
gdp = xlsread(filePath, 'macro', 'b33:b318');   % 1992:03-2015:12, seasonly
cpi = xlsread(filePath, 'macro', 'c7:c318');    % 1990:01-2015:12, monthly
ppi = xlsread(filePath, 'macro', 'd88:d318');   % 1996:10-2015:12, monthly
une = xlsread(filePath, 'macro', 'e162:e318');  % 2002:12-2015:12, seasonly
M2 = xlsread(filePath, 'macro', 'f78:f318');    % 1995:12-2015:12, monthly
keqiang = xlsread(filePath, 'macro', 'g241:g318');  % 2009:07-2015:12, monthly
ip = xlsread(filePath, 'macro', 'h7:h318');     % 1990:01-2015:12, monthly

% load data: 1988:06-2015:12
arabian = xlsread(filePath, 'oil_last', 'b463:c793');
L = 6;
period = size(arabian,1);
arabian_L = nan(period-(L-1),1);
for t=L:period
    arabian_t = arabian(t-(L-1):t,1);
    arabian_L(t-(L-1),1) = mean(arabian_t);
end

summary_table_marco = nan(7, 3);

x = log(arabian_L(49-(L-1):3:end) ./ arabian_L(46-(L-1):3:end-3));
y = log(gdp(4:3:end) ./ gdp(1:3:end-3));
summary_table_marco(1, :) = ols_summary(y, x);

x = log(arabian_L(20-(L-1):end) ./ arabian_L(19-(L-1):end-1));
y = cpi / 100;
summary_table_marco(2, :) = ols_summary(y, x);

x = log(arabian_L(101-(L-1):end) ./ arabian_L(100-(L-1):end-1));
y = ppi / 100;
summary_table_marco(3, :) = ols_summary(y, x);

x = log(arabian_L(175-(L-1):3:end) ./ arabian_L(172-(L-1):3:end-3));
y = une(1:3:end) / 100;
summary_table_marco(4, :) = ols_summary(y, x);

x = log(arabian_L(92-(L-1):end) ./ arabian_L(91-(L-1):end-1));
y = log(M2(2:end) ./ M2(1:end-1));
summary_table_marco(5, :) = ols_summary(y, x);

x = log(arabian_L(254-(L-1):end) ./ arabian_L(253-(L-1):end-1));
y = keqiang / 100;
summary_table_marco(6, :) = ols_summary(y, x);

x = log(arabian_L(20-(L-1):end) ./ arabian_L(19-(L-1):end-1));
y = ip / 100;
summary_table_marco(7, :) = ols_summary(y, x);

xlswrite('../../results/summary_macro.xlsx', summary_table_marco, 'macro', 'c2')

earnings = xlsread(filePath, 'earnings', 'b2:u60');  % 2001:06-2015:12, seasonly
summary_fundamental = nan(size(earnings,2),3);
x = log(arabian_L(160-(L-1):3:end) ./ arabian_L(157-(L-1):3:end-3));
for i=1:size(earnings,2)
    y = log(earnings(2:end, i) ./ earnings(1:end-1, i));
    summary_fundamental(i, :) = ols_summary(y, x);
end
xlswrite('../../results/summary_macro.xlsx', summary_fundamental, 'earnings', 'c2')

function summary=ols_summary(y, x)
    x = x(isfinite(y));    
    y = y(isfinite(y));
    X = [ones(size(x, 1), 1) x];
    result = ols(y, X);
    coeff = result.beta(2);
    p_val = 2 * normcdf(-abs(result.tstat(2)));
    rsqr = result.rsqr;
    summary = [coeff p_val rsqr];
end