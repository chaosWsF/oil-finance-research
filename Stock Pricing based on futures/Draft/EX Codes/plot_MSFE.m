function plot_MSFE(in_sample, u_mean, u_val, k)
    
    CSFE1 = cumsum(u_mean.^2);
    CSFE2 = cumsum(u_val.^2);
    CSFE_diff = CSFE2 - CSFE1;

    t = datetime(0, 1, 1) + calmonths(0:size(CSFE_diff,1)-1);
    x_axis = datetime(0, 1, 1) + calmonths(0:60:size(CSFE_diff,1)-1);
    
    plot(t, CSFE_diff);
    title('Country ' + string(k));
    xlabel('Date');
    ylabel('CSFE difference');
    xticklabels(datestr(x_axis, 'yyyy-mm'));
    xtickangle(30);

    grid on;
    ax = gca;
    ax.XAxis.MinorTick = 'on';
    ax.XAxis.MinorTickValues = x_axis;
    ax.XMinorGrid = 'on';

    figname = sprintf('./figures/ex/%1d/country%2d.png', in_sample / 12, k);
    % figname = sprintf('./figures/real_ex/%1d/country%2d.png', in_sample / 12, k);
    disp(figname)
    saveas(gcf, figname);
    