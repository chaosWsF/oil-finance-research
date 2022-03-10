clear;

input_file = './data/monthly_data.xlsx';
x_inputs = xlsread(input_file, 'oil_last', 'e612:e832');

L = 6;
x_period = size(x_inputs, 1);
x_L = nan(x_period - (L - 1), size(x_inputs, 2));

for t = L:x_period
    x_t = x_inputs(t - (L - 1):t, :);
    x_L(t - (L - 1), :) = mean_without_nan(x_t);
end

lw = 1.5; % linewidth

% plot oil price
% hold on
% t=datetime(2001,4,1)+calmonths(0:215);
% plot(t,x_inputs(6:end),'--b','Linewidth',lw);
% plot(t,x_L,'-r','Linewidth',lw);
% legend('Last Price', 'Trend', 'Location', 'northwest');
% xlim([datetime(2001,4,1) datetime(2019,3,1)]);
% hold off

% plot return of oil price
% (uncomment the codes of ylabel)
% hold on
% t = datetime(2001, 5, 1) + calmonths(0:214);
% ret_x_inputs = log(x_inputs(7:end) ./ x_inputs(6:end - 1));
% ret_x_L = log(x_L(2:end) ./ x_L(1:end - 1));
% plot(t, ret_x_inputs, '--');
% plot(t, ret_x_L);
% legend('Last Price', 'Trend', 'Location', 'northwest');
% xlim([datetime(2001, 5, 1) datetime(2019, 3, 1)]);
% hold off

% plot 20 industries and HS300 returns
% (uncomment the codes of ylabel)
y_inputs = xlsread(input_file, 'stock', 'c135:w341');
hold on
t = datetime(2002, 1, 1) + calmonths(0:206);
Rmarket = log(y_inputs(:, 1));
Rind = log(y_inputs(:, 2:end));
plot(t, cumsum(Rmarket), '-b', 'Linewidth', lw); % HS300
plot(t, cumsum(Rind(:, 2:11)), ':g', 'Linewidth', lw);
plot(t, cumsum(Rind(:, 12:end)), ':r', 'Linewidth', lw);
xlim([datetime(2002, 1, 1) datetime(2019, 3, 1)]);
hold off

xlabel('Date');
% ylabel('Price');
ylabel('Return');
xtickformat('yyyy');
xtickangle(30);
grid on;
ax = gca;
ax.XMinorGrid = 'on';
