function amEMPlotAlignedCurveRecovery(ax, mprofile_pre, mmeancurvemean, mmeancurvecount, mmeancurvestd, ...
    measure, max_points, offset, align_wind, run_type, ex_start, sigmamethod, anchor, subplottitle)

% amEMPlotAlignedCurve - plots a latent curve for a given measure (pre and post alignment)

% initialise plot areas
xl = [offset.down - 0.5, align_wind + offset.up - 0.5];  % intervention starts at day 0
yl = [min((mmeancurvemean * .99)) ...
      max((mmeancurvemean * 1.01))];
  
if isnan(yl(1))
    yl(1) = 0;
end
if isnan(yl(2))
    yl(2) = 1;
end

yyaxis left;

[xl, yl] = plotLatentCurveRecovery(ax, offset, align_wind, (mprofile_pre), xl, yl, 'red', ':', 0.5, anchor);
%[xl, yl] = plotLatentCurve(ax, max_offset, align_wind, min_offset, smooth(mprofile_pre, 5), xl, yl, 'red', '-', 0.5, anchor);
[xl, yl] = plotLatentCurveRecovery(ax, offset, align_wind, movmean(mprofile_pre, 3, 'omitnan'), xl, yl, 'red', '-', 0.5, anchor);
[xl, yl] = plotLatentCurveRecovery(ax, offset, align_wind, (mmeancurvemean), xl, yl, 'blue', ':', 0.5, anchor);
%[xl, yl] = plotLatentCurve(ax, max_offset, align_wind, min_offset, smooth(mmeancurvemean, 5), xl, yl, 'blue', '-', 0.5, anchor);
[xl, yl] = plotLatentCurveRecovery(ax, offset, align_wind, movmean(mmeancurvemean, 3, 'omitnan'), xl, yl, 'blue', '-', 0.5, anchor);

if sigmamethod == 4
    [xl, yl] = plotLatentCurveRecovery(ax, offset, align_wind, (mmeancurvemean + mmeancurvestd), xl, yl, 'blue', ':', 0.5, anchor);
%   [xl, yl] = plotLatentCurve(ax, max_offset, align_wind, min_offset, smooth(mmeancurvemean + mmeancurvestd, 5), xl, yl, 'blue', '--', 0.5, anchor);
    [xl, yl] = plotLatentCurveRecovery(ax, offset, align_wind, movmean(mmeancurvemean + mmeancurvestd, 3, 'omitnan'), xl, yl, 'blue', '--', 0.5, anchor);
    [xl, yl] = plotLatentCurveRecovery(ax, offset, align_wind, (mmeancurvemean - mmeancurvestd), xl, yl, 'blue', ':', 0.5, anchor);
%   [xl, yl] = plotLatentCurve(ax, max_offset, align_wind, min_offset, smooth(mmeancurvemean - mmeancurvestd, 5), xl, yl, 'blue', '--', 0.5, anchor);
    [xl, yl] = plotLatentCurveRecovery(ax, offset, align_wind, movmean(mmeancurvemean - mmeancurvestd, 3, 'omitnan'), xl, yl, 'blue', '--', 0.5, anchor);
end

ax.XAxis.FontSize = 6;
xlabel('Days Post Intervention');
ax.YAxis(1).Color = 'blue';
ax.YAxis(1).FontSize = 6;
ylabel('Normalised Measure', 'FontSize', 6);

% if ex_start ~= 0
%     [~, ~] = plotVerticalLine(ax, ex_start, xl, yl, 'blue', '--', 0.5); % plot ex_start
% end

yyaxis right
ax.YAxis(2).Color = 'black';
ax.YAxis(2).FontSize = 6;
ylabel('Count of Data points');
if isequal(run_type,'Best Alignment')
    bar(offset.down : align_wind + offset.up-1, max_points, 1.0, 'EdgeColor', 'none', 'FaceColor', [0.3, 0.3, 0.3], 'FaceAlpha', 0.4);
end
hold on;
bar(offset.down : align_wind + offset.up-1, mmeancurvecount, 1.0, 'EdgeColor', 'none', 'FaceColor', 'black', 'FaceAlpha', 0.5, 'LineWidth', 0.2);
hold off;

if isequal(run_type,'Best Alignment')
    ylbar = [0 max(max_points) * 4];
else
    ylbar = [0 max(mmeancurvecount * 4)];
end

if isnan(ylbar(2)) || ylbar(2) == 0
    ylbar(2) = 100;
end
ylim(ylbar);

if measure.Mask == 1
    title(subplottitle, 'FontSize', 6, 'BackgroundColor', 'g');
else
    title(subplottitle, 'FontSize', 6);
end
    
end

