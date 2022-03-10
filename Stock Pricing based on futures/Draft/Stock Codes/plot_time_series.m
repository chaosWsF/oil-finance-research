clear;

input_file='../../data/month_ara_bre_dub_fut_cus_mid_sh300.xlsx';
x_inputs=xlsread(input_file,'oil_last','b612:b793');

L=6;
x_period=size(x_inputs,1);
x_L=nan(x_period-(L-1),size(x_inputs,2));
for t=L:x_period
    x_t=x_inputs(t-(L-1):t,:);
    x_L(t-(L-1),:)=mean_without_nan(x_t);
end

hold on
t=datetime(2001,4,1)+calmonths(0:176);
plot(t,x_inputs(6:end),'--');
plot(t,x_L);
legend('Last Price', 'MA-6-Month', 'Location', 'northwest');
title('Price of Arabian Light Oil');
xlim([datetime(2001,4,1) datetime(2015,12,31)]);
hold off

% y_inputs=xlsread(input_file,'stock_last','d126:w341');
% t=datetime(2001,4,1)+calmonths(0:215);
% plot(t,y_inputs);
% title('Industry Index');
% legend('ind'+string(1:20),...
%     'Location','northwest','NumColumns',4,'FontSize',8);
% legend('boxoff');
% xlim([datetime(2001,4,1) datetime(2019,3,1)]);

xlabel('Date');
ylabel('Price');
xtickformat('yyyy');
xtickangle(30);
grid on;
ax=gca;
ax.XMinorGrid='on';