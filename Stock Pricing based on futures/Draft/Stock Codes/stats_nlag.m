clear;
L = [1 2 3 6 12 18 24 30 36];

for l=1:length(L)
    
    % daily
    file = '../../data/results_daily/results_oil_ind_Lags/arabian/results_'+string(L(l))+'.xlsx';
    summary_lags = xlsread(file,'In-Sample','c3:c42');
    summary_lags_out = xlsread(file,'Out-of-Sample','c3:c42');
    
    % industry
    % file = '../../data/results/results_oil_ind_Lags/arabian/results_oil_ind_arabian_'+string(L(l))+'.xlsx';
    % file = '../../data/results/results_oil_ind_Lags/brent/results_oil_ind_brent_'+string(L(l))+'.xlsx';
    % file = '../../data/results/results_oil_ind_Lags/oilfut/results_oil_ind_oilfut_'+string(L(l))+'.xlsx';
    % summary_lags = xlsread(file,'In-sample results','c3:c42');
    % summary_lags_out = xlsread(file,'Out-of-sample statistics','c3:c42');

    % % % green
    % file = '../../data/results/results_oil_green_Lags/brent/results_oil_green_'+string(L(l))+'.xlsx';
    % % file = '../../data/results/results_oil_green_Lags/oilfut/results_oil_green_'+string(L(l))+'.xlsx';
    % summary_lags = xlsread(file,'In-sample results','c3:c4');
    % summary_lags_out = xlsread(file,'Out-of-sample statistics','c3:c4');
    
    indicator = 1.5*sum(abs(summary_lags) > 1.96)+sum(summary_lags_out > 1.96);
    disp([L(l),indicator])
end