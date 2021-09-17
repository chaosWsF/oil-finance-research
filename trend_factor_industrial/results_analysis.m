clear;

load('./Results/results.mat');

num_row = size(experiment_results, 2);
L = nan(num_row, 1);
pval = nan(num_row, 1);
r2 = nan(num_row, 1);
r2os = nan(num_row, 1);

% used_id = 1:53;
% used_id = [54, 53, 19, 18, 28, 27, 9] - 2;  % G7
used_id = [11, 23, 24, 36, 7, 32, 37, 52, 51] - 2; % developing
% used_id=[3, 6, 8, 9, 12, 13, 18, 19, 22, 24, 25, 29, 32, 34, 35, 36, ...
%     37, 38, 39, 40, 41, 42, 43, 45, 49, 50];  % Belt and Road Initiative

for l = 1:size(experiment_results, 2)
    L(l) = experiment_results(l).L;
    in_sample = experiment_results(l).insample;
    oos = experiment_results(l).oos;

    in_p_val = in_sample(used_id, 2:3:end);
    in_r2 = in_sample(used_id, 3:3:end);
    oos_r2os = oos(used_id, 1:2:end);

    pval(l) = nanmean(in_p_val, 'all');
    r2(l) = nanmean(in_r2, 'all');
    r2os(l) = nanmean(oos_r2os, 'all');
end

analysis = table(L, pval, r2, r2os);
