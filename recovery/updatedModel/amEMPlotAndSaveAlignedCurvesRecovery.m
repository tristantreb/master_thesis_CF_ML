function amEMPlotAndSaveAlignedCurvesRecovery(profile_pre, meancurvemean, meancurvecount, meancurvestd, offsets, ...
    measures, max_points, offset, align_wind, nmeasures, run_type, ex_start, sigmamethod, plotname, plotsubfolder)

% amEMPlotAndSaveAlignedCurves - plots the curves pre and post alignment for
% each measure, and the histogram of offsets

if (nmeasures + 1) <= 9
    plotsacross = 3;
else
    plotsacross = 4;
end
plotsdown = ceil((nmeasures + 1) / plotsacross);

plottitle = sprintf('%s - %s', plotname, run_type);
anchor = 1; % latent curve is to be anchored on the plot (right side at offset.min)

[f, p] = createFigureAndPanel(plottitle, 'portrait', 'a4');

for m = 1:nmeasures    
    subplottitle = measures.DisplayName{m};
    ax = subplot(plotsdown,plotsacross,m,'Parent',p);
    amEMPlotAlignedCurveRecovery(ax, profile_pre(:, m), meancurvemean(:, m), meancurvecount(:, m), meancurvestd(:, m), ...
        measures(m, :), max_points, offset, align_wind, run_type, ex_start, sigmamethod, anchor, subplottitle); 
end

ax = subplot(plotsdown, plotsacross, nmeasures + 1, 'Parent', p);
amEMPlotOffsetHistogramRecovery(ax, offsets);

% save plot
savePlotInDir(f, plottitle, plotsubfolder);
close(f);

end