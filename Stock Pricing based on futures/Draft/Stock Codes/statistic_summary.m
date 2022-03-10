clear;

input_file='../../data/month_ara_bre_dub_fut_cus_mid_sh300.xlsx';    
x_inputs=xlsread(input_file,'oil_last','b610:b792');
y_inputs=xlsread(input_file,'stock','d126:w302');
r_ind = log(y_inputs);
summary_regression_data(6);
load('regression_data.mat');

summary_oil = summaryX(x_inputs);
summary_ind = summaryX(r_ind);
summary_oil_trend = summaryX(x_L);

covmat=nancov(r_ind);
corrmat = corrcov(covmat);

% TODO autocorr
summaryAuto_oil = autocorrX(x_inputs);
summaryAuto_ind = autocorrX(y_inputs);
summaryAuto_oil_trend = autocorrX(x_L);

latex_table1_1 = mat2latex(summary_oil,4);
latex_table1_2 = mat2latex(summary_ind,4);
latex_table1_3 = mat2latex(summary_oil_trend,4);
latex_table2 = mat2latex(corrmat,3);
latex_table3_1 = mat2latex(summaryAuto_oil,4);
latex_table3_2 = mat2latex(summaryAuto_ind,4);
latex_table3_3 = mat2latex(summaryAuto_oil_trend,4);

function summ_stats=summaryX(dat)
    summ_stats = nan(size(dat,2), 7);
    summ_stats(:,1) = nanmean(dat)';  % Mean
    summ_stats(:,2) = nanmedian(dat)';  % Median
    summ_stats(:,3) = nanmax(dat)';  % Max
    summ_stats(:,4) = nanmin(dat)';  % Min
    summ_stats(:,5) = nanstd(dat)';  % Std
    summ_stats(:,6) = kurtosis(dat)';  % Kurtosis
    summ_stats(:,7) = skewness(dat)';  % Skewness
end

function autocorr_mat=autocorrX(dat)
    lags = [1, 3, 6, 12, 24, 36];
    autocorr_mat = nan(size(dat,2),length(lags));
    nlags = max(lags);
    for col=1:size(dat,2)
        acf = autocorr(dat(:,col),'NumLags',nlags);
        acf = acf(2:end);
        for l=1:length(lags)
            autocorr_mat(col,l) = acf(lags(l));
        end
    end
end

function latexstr=mat2latex(mat,prec)
    latexstr = latex(vpa(sym(mat),prec));
end