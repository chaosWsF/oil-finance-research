clear;
L = [1 2 3 6 12 18 24 30 36];

for l=1:length(L)
    % real_ex
    file = '../../EX/results/results_oil_real_ex/results_oil_real_ex_'+string(L(l))+'.xlsx';
    summary_lags = xlsread(file,'In-sample results','c3:c55');
    summary_lags_out = xlsread(file,'Out-of-sample statistics','c3:c55');

    % ex
    % output_file = '../../EX/results/results_oil_ex/results_oil_ex_'+string(L)+'.xlsx';
    % summary_lags = xlsread(file,'In-sample results','c3:c108');
    % summary_lags_out = xlsread(file,'Out-of-sample statistics','c3:c108');

    indicator = 1.5*sum(abs(summary_lags) > 1.96)+sum(summary_lags_out > 1.96);
    disp([L(l),indicator])
end
