function [meancurvesumsq, meancurvesum, meancurvecount, meancurvemean, meancurvestd, amInterventions, ...
    hstg, pdoffset, overall_hist, overall_pdoffset, ...
    animatedmeancurvemean, animatedoffsets, animatedlc, animated_overall_pdoffset, ...
    vshift, isOutlier, pptsstruct, qual, iter, miniiter] = ...
    amEMMCAlignCurvesRecovery(meancurvesumsq, meancurvesum, meancurvecount, amIntrCube, amHeldBackcube, ...
        animatedmeancurvemean, animatedoffsets, animatedlc, animated_overall_pdoffset, ...
        hstg, pdoffset, overall_hist, overall_pdoffset, vshift, isOutlier, ...
        amInterventions, outprior, measures, normstd, offset, align_wind, ...
        nmeasures, ninterventions, nlatentcurves, sigmamethod, smoothingmethod, ...
        runmode, countthreshold, aniterations, maxiterations, allowvshift, vshiftmax, miniiter, fnmodelrun)

% amEMMCAlignCurves - function to align measurement curves prior to
% intervention (allowing for multiple versions of the latent curves)

% iterate to convergence
pnt       = 1;
offsetcnt = 0;
lccnt     = 0;
iter      = 0;
smmpddiff = 100;
pddiffthreshold = 0.00001;
prior_overall_pdoffset = overall_pdoffset;

while (smmpddiff > pddiffthreshold && iter < maxiterations)
    ok = 1;
    
    % remove current intervention's curve from latent profile
    [meancurvesumsq, meancurvesum, meancurvecount] = RamEMMCRemoveFromMean(meancurvesumsq, meancurvesum, meancurvecount, ...
        overall_pdoffset, amIntrCube, amHeldBackcube, vshift, pnt, offset, align_wind, nmeasures, nlatentcurves);
    
    % find and keep track of points that have too few data points contributing 
    % to them 
    [pptsstruct] = RamEMMCFindProblemDataPoints(meancurvesumsq, meancurvesum, meancurvecount, measures.Mask, ...
        align_wind, nmeasures, countthreshold, nlatentcurves);
    
    % 1) add the adjustments to the various meancurve arrays 
    % 2) recalculate mean and std arrays
    [meancurvesumsq, meancurvesum, meancurvecount] = amEMMCAddAdjacentAdjustments(meancurvesumsq, meancurvesum, meancurvecount, pptsstruct, nlatentcurves);
    [meancurvemean, meancurvestd] = RamEMMCCalcMeanAndStd(meancurvesumsq, meancurvesum, meancurvecount);
     
    % 1)returns best offset, best curvelco
    % 2) returns distance, p(offset) -> per measure and summed/normalised
    % over all measures
    % 3) returns vshift and isOutlier
    if ok == 1
        [better_offset, better_curve, hstg, pdoffset, overall_hist, overall_pdoffset, vshift, isOutlier] = RamEMMCBestFit(meancurvemean, meancurvestd, amIntrCube, amHeldBackcube, ...
            measures.Mask, measures.OverallRange, normstd, hstg, pdoffset, overall_hist, overall_pdoffset, vshift, isOutlier, outprior, ...
            pnt, offset, align_wind, nmeasures, sigmamethod, smoothingmethod, runmode, nlatentcurves, allowvshift, vshiftmax);
    else
        better_offset = amInterventions.Offset(pnt);
        better_curve  = amInterventions.LatentCurve(pnt);
    end
    
    % log updates in offset or curve for the current offset, if applicable
    if better_offset ~= amInterventions.Offset(pnt) || better_curve ~= amInterventions.LatentCurve(pnt)
        offsetchg = false;
        lcchg = false;
        if better_offset ~= amInterventions.Offset(pnt)
            offsettext = sprintf('Offset: %2d to %2d', amInterventions.Offset(pnt), better_offset);
            offsetchg = true;
            offsetcnt = offsetcnt + 1;
            amInterventions.Offset(pnt) = better_offset;
        else
            offsettext = '                ';
        end
        if better_curve ~= amInterventions.LatentCurve(pnt)
            lctext = sprintf('Latent Curve: %d to %d', amInterventions.LatentCurve(pnt), better_curve);
            lcchg = true;
            lccnt = lccnt + 1;
            amInterventions.LatentCurve(pnt) = better_curve;
        else
            lctext = '                    ';
        end
        if offsetchg || lcchg
            fprintf('%3d: %s : %s\n', pnt, lctext, offsettext);
        end
        miniiter = miniiter+1;
        if miniiter < aniterations
            animatedmeancurvemean(:, :, :, miniiter)         = meancurvemean;
            animatedoffsets(:,miniiter)                      = amInterventions.Offset;
            animatedlc(:,miniiter)                           = amInterventions.LatentCurve;
            animated_overall_pdoffset(:, :, :, miniiter + 1) = overall_pdoffset;
        else
            fprintf('Exceeded storage for animated iterations\n');
        end
    end
    
    [meancurvesumsq, meancurvesum, meancurvecount] = amEMMCRemoveAdjacentAdjustments(meancurvesumsq, meancurvesum, meancurvecount, pptsstruct, nlatentcurves);
    [meancurvesumsq, meancurvesum, meancurvecount] = RamEMMCAddToMean(meancurvesumsq, meancurvesum, meancurvecount, ...
        overall_pdoffset, amIntrCube, amHeldBackcube, vshift, pnt,  offset, align_wind, nmeasures, nlatentcurves);
    [meancurvemean, meancurvestd] = RamEMMCCalcMeanAndStd(meancurvesumsq, meancurvesum, meancurvecount);
    
    for i = 1:ninterventions % map offsetval to offsetidx
        amInterventions.Offsetidx(i) = find(offset.down:offset.up == amInterventions.Offset(i));
    end
    
    pnt = pnt+1;
    % one full iteration accross all interventions done
    % 1) log the total dist (over all interventions)
    % 2) log number of changes and diff criterias wrt last iteration
    if pnt > ninterventions
        iter = iter + 1;
        pnt = pnt - ninterventions;
        miniiter = miniiter+1;
        if miniiter < aniterations
            animatedmeancurvemean(:, :, :, miniiter)         = meancurvemean;
            animatedoffsets(:,miniiter)                      = amInterventions.Offset;
            animatedlc(:,miniiter)                           = amInterventions.LatentCurve;
            animated_overall_pdoffset(:, :, :, miniiter + 1) = overall_pdoffset;
        else
            fprintf('Exceeded storage for animated iterations\n');
        end
        
        [smmpddiff, ssspddiff] = amEMMCCalcDiffOverallPD(overall_pdoffset, prior_overall_pdoffset);
        % compute the overall objective function each time we've iterated
        % through the full set of interventions
        % ** don't update the histogram here to avoid double counting on the best
        % offset day **
        update_histogram = 0;
        qual = 0;
        qualcount = 0;
        for i=1:ninterventions
            [meancurvesumsq, meancurvesum, meancurvecount] = RamEMMCRemoveFromMean(meancurvesumsq, meancurvesum, meancurvecount, ...
                overall_pdoffset, amIntrCube, amHeldBackcube, vshift, i, offset, align_wind, nmeasures, nlatentcurves);
            %[meancurvesumsq, meancurvesum, meancurvecount] = amEMMCAddAdjacentAdjustments(meancurvesumsq, meancurvesum, meancurvecount, pptsstruct, nlatentcurves);
            [meancurvemean, meancurvestd] = RamEMMCCalcMeanAndStd(meancurvesumsq, meancurvesum, meancurvecount);
            
            lc = amInterventions.LatentCurve(i);
            % when just calculating objfcn value, run without allowing
            % additional vertical shifting
            tmpallowvshift = false;
            [iqual, icount] = RamEMMCCalcObjFcn(meancurvemean(lc, :, :), meancurvestd(lc, :, :), amIntrCube, amHeldBackcube, ...
                vshift(lc, :, :, :), isOutlier(lc, :, :, :, :), outprior, measures.Mask, measures.OverallRange, normstd, hstg(lc, :, :, :), i, ...
                amInterventions.Offsetidx(i), offset, align_wind, nmeasures, update_histogram, sigmamethod, smoothingmethod, tmpallowvshift, vshiftmax); 
            
            qual = qual + iqual;
            qualcount = qualcount + icount;
            
            %fprintf('Intervention %d, qual = %.4f\n', i, qual/qualcount);
    
            %[meancurvesumsq, meancurvesum, meancurvecount] = amEMMCRemoveAdjacentAdjustments(meancurvesumsq, meancurvesum, meancurvecount, pptsstruct, nlatentcurves);
            [meancurvesumsq, meancurvesum, meancurvecount] = RamEMMCAddToMean(meancurvesumsq, meancurvesum, meancurvecount, ...
                overall_pdoffset, amIntrCube, amHeldBackcube, vshift, i, offset, align_wind, nmeasures, nlatentcurves);
            %[meancurvemean, meancurvestd] = amEMMCCalcMeanAndStd(meancurvesumsq, meancurvesum, meancurvecount);
        end
        
        qual = qual / qualcount;
        
        if offsetcnt == 0 && lccnt == 0
            fprintf('Iteration %d: No changes, obj fcn = %.8f, prob distrib diff: smm = %.6f sss = %.6f\n', iter, qual, smmpddiff, ssspddiff);
        else
            fprintf('Iteration %d: Changed %d latent curve sets and %d offsets, obj fcn = %.8f, prob distrib diff: smm = %.6f sss = %.6f\n', iter, lccnt, offsetcnt, qual, smmpddiff, ssspddiff);
        end
        offsetcnt = 0;
        lccnt = 0;
        prior_overall_pdoffset = overall_pdoffset;
        
        %temp = input('Continue ? ');
    end
end

%[meancurvesumsq, meancurvesum, meancurvecount] = amEMMCAddAdjacentAdjustments(meancurvesumsq, meancurvesum, meancurvecount, pptsstruct, nlatentcurves);
[meancurvemean, meancurvestd] = RamEMMCCalcMeanAndStd(meancurvesumsq, meancurvesum, meancurvecount);


end

