clear;

load('regression_data.mat');

ex_code = 25;
oil_code = 5;
h_code = 3;

y = y_h(:, ex_code, h_code);
x = x_L(:, oil_code);

scatter(x, y);
xlabel('oil-Lag');
ylabel('EX');
grid on;
