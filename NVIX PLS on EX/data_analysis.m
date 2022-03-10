% some varibales here require being 
% pre-generated by running PLS_PM.m

%% Disaster Indicators plotting
DI_names = data_NVIX.Properties.VariableNames(3:end);
tsd = data_NVIX(trange_D, 1).Variables;
plot(tsd, D)
legend(DI_names)

%% Disaster Indicators summary
DI_names = data_NVIX.Properties.VariableNames(3:end);
rou_1 = NaN(1, size(D, 2));
for j=1:size(D, 2)
    acf = autocorr(D(:, j));
    rou_1(:, j) = acf(2);
end
DI_summary = [nanmean(D);nanstd(D);skewness(D);nanmedian(D);rou_1];
DI_tab = array2table(round(DI_summary', 2), ...
    'VariableNames', {'Mean', 'Std', 'Skew', 'Median', 'Rou_1'}, 'RowNames', DI_names);
DI_corr_tab = array2table(round(corrcov(nancov(D)), 2), ...
    'VariableNames', DI_names, 'RowNames', DI_names);
disp(DI_tab)
disp(DI_corr_tab)

%% EX time series plotting
index = 6;    % bad performance = [5 11 15 22 28 31], EUR = 6
ts = data_EX(trange_r, 1).Variables;
plot(ts, EX(:, index))
legend(country_names(index))

%% EX return plotting
index = 31;    % bad performance = [5 11 15 22 28 31], EUR = 6
ts = data_EX(trange_r, 1).Variables;
plot(ts(2:end), r(:, index))
legend(country_names(index))

%% EX return summary
rou_1 = NaN(1, size(r, 2));
for j=1:size(r, 2)
    acf = autocorr(r(:, j));
    rou_1(:, j) = acf(2);
end
r_summary = [nanmean(r);nanstd(r);skewness(r);nanmedian(r);rou_1];
r_tab = array2table(round(r_summary', 2), 'VariableNames', ...
    {'Mean', 'Std', 'Skew', 'Median', 'Rou_1'}, 'RowNames', country_names);
disp(r_tab)

%% EX return hist
histogram(r(:, 15))    % bad performance = [5 11 15 22 28 31], EUR = 6

%% EX return boxplot
index = [5 11 15 6 22 28 31];    % bad performance = [5 11 15 22 28 31], EUR = 6
boxplot(r(:, index), country_names(index))

%% Rare Disaster time series
index = [5 11 15 22 28 31];    % bad performance = [5 11 15 22 28 31], EUR = 6
tsd = data_NVIX(trange_D, 1).Variables;
plot(tsd, rare_disaster(:, index))
legend(country_names(index))

%% CSFE gain
ts = data_EX(trange_r, 1).Variables;
tso = ts(2:end);
tso = tso(R+1:end);
index = [5 11 15 22 28 31];    % bad performance = [5 11 15 22 28 31], EUR = 6
plot(tso, CSFE_gain(:, index))
legend(country_names(index))
