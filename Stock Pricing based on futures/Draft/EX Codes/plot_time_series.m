clear;

load('regression_data.mat');

t=datetime(1980,2,1)+calmonths(0:469);
x_axis=datetime(1980,2,1)+calmonths(0:7:469);

plot(t,x_L);
title('Six Oil Price Index from 1980:02-2019:03');
xlabel('Date');
ylabel('Oil Price');
legend('arabian','brent','dubai','oil-futures',...
    'WTI-cushing','WTI-MidLand','Location','northwest','NumColumns',2);
grid on;
ax=gca;
ax.XAxis.MinorTick='on';
ax.XAxis.MinorTickValues=x_axis;
ax.XMinorGrid='on';
