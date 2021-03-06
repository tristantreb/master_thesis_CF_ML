% run a model with a manually selected subset of interventions
% 
% it creates all subset of x interventions at once and then run a model for 
% each of them based on a reference parameter file. 
% currently 5 general groups for segmentation:
% - behaviour during intervention
% - volumes
% - treatment type and CFTR modulator therapies
% - data quality and duration
% 
% Note: in the end only faillist was used, not enough data for most others
% 
% Input:
% ------
% BRTreatmentsObservation.xlsx        excel file with results of expert eye observation
% clinical and home measurements data
% parameter file
% 
% Output: x models run with runFastAlignmentModelEMMCRecoveryFcn
% -------

init;
subfolder = 'ExcelFiles';
filename = 'BRTreatmentsObservation.xlsx';
treatobs = readtable(fullfile(basedir, subfolder, filename), 'Sheet', 'recovery new');

% get labels
before = getLabelsCount(treatobs.LabelBeforeTreatment);
during = getLabelsCount(treatobs.LabelDuringTreatment);
after = getLabelsCount(treatobs.LabelAfterTreatment);

% load brphysdata for volume segmentation
subfolder = 'MatlabSavedVariables';
[datamatfile, clinicalmatfile, ~] = getRawDataFilenamesForStudy(study);
[brphysdata, broffset, ~] = loadAndHarmoniseMeasVars(datamatfile, subfolder, study);
cdPatient = loadAndHarmoniseClinVars(clinicalmatfile, subfolder, study);


%% treatobs statistics

ninterventions = size(treatobs,1);
fprintf('Before: %i decline, %i stable, %i improves, %i undefined\n', before.d, before.s, before.i,ninterventions-before.d-before.s-before.i);
fprintf('During: %i decline, %i stable, %i improves, %i undefined\n', during.d, during.s, during.i, ninterventions-during.d-during.s-during.i);
fprintf('After: %i decline, %i stable, %i improves, %i undefined\n', after.d, after.s, after.i, ninterventions-after.d-after.s-after.i);

fprintf('average measures per day %.1f +/- %.1f, days with measures %.1f +/- %.1f\n', mean(treatobs.DaysWithMeasures), std(treatobs.DaysWithMeasures), mean(treatobs.AvgMeasuresPerDay), std(treatobs.AvgMeasuresPerDay));
fprintf('interventions with few measures (<4 per day) %i\n', sum(treatobs.AvgMeasuresPerDay<4));

%% behaviour during intervention

% with ape, without ape
[intr.tb_apelist, intr.tb_apenolist, tb_apenbr] = getLists(contains(treatobs.LabelBeforeTreatment,"d"), treatobs);

% improvement during
[intr.tb_improvlist, intr.tb_improvnolist, tb_improvnbr] = getLists( contains(treatobs.LabelDuringTreatment,"i"), treatobs);

% successful recovery, i during and i or s after
[intr.tb_successlist, intr.tb_successnolist, tb_successnbr] = getLists( contains(treatobs.LabelDuringTreatment,"i") ...
    & not(contains(treatobs.LabelAfterTreatment,"i")) & not(contains(treatobs.LabelAfterTreatment,"s")), treatobs);

% decline after or during 
[intr.tb_faillist, intr.tb_failnolist, tb_failnbr] = getLists( contains(treatobs.LabelAfterTreatment,"d") ...
    | contains(treatobs.LabelDuringTreatment,"d"), treatobs);

%% treatment type and CFTR modulator therapies

%IVPBO, Oral, IV
t1_ivpbomask = contains(treatobs.Route, "IVPBO");
t1_oralmask = contains(treatobs.Route, "Oral");
t1_ivpbo_nbr = sum(t1_ivpbomask);
intr.t1_ivpbolist = treatobs.IntrNbr(t1_ivpbomask);
t1_iv_nbr = sum(not(t1_ivpbomask|t1_oralmask));
intr.t1_ivlist = treatobs.IntrNbr(not(t1_ivpbomask|t1_oralmask));
t1_oral_nbr = sum(t1_oralmask);
intr.t1_orallist = treatobs.IntrNbr(t1_oralmask);

% under triple therapy
[intr.t2_tripllist, intr.t2_nottriplelist, t2_triple_nbr] = getLists( contains(treatobs.DrugTherapy,"Triple Therapy"), treatobs);

%% volumes
FEV1PrctPredicted = calcBRFEV1PrctPredicted(brphysdata,cdPatient);

% <40%
[intr.v50andunderlist, v50andunder_nbr] = getVolumeList(FEV1PrctPredicted.Value<50, FEV1PrctPredicted, treatobs);
% >=40% to <70%
[intr.v5080list, v5080_nbr] = getVolumeList(FEV1PrctPredicted.Value>=50 & FEV1PrctPredicted.Value<80, FEV1PrctPredicted, treatobs);
% >= 70%
[intr.v80andoverlist, v80andover_nbr] = getVolumeList(FEV1PrctPredicted.Value>=80, FEV1PrctPredicted, treatobs);

%% data quality and duration

[intr.td_avg4, intr.td_notavg4, td_avg4_nbr] = getLists(treatobs.AvgMeasuresPerDay >= 4, treatobs);

% look at sequential interventions - sum(contains(treatobs.Sequential,'Y'));

%% run specific interventions

% check if amInterventions and treatobs are the same arrays. This is
% necessary to be able to transfer the indexes of treatobs to amIntr...
subfolder = 'MatlabSavedVariables';
filename = 'BRalignmentmodelinputs_recovery_gap10_datawind20.mat';
load(fullfile(basedir,subfolder, filename),'amInterventions');

tempdate = split(string(treatobs.StartDate),"'");
if sum(amInterventions.IVStartDate == datetime(tempdate(:,2))) == size(amInterventions, 1)
    % get parameter file
    subfolder = 'DataFiles/Recovery';
    parameterfile = 'BRRunParameters_gp10_reference.xlsx';
    amRunParameters = readtable(fullfile(basedir, subfolder, parameterfile));

    % get the names of the fields
    fields = fieldnames(intr);
    % loop over fields
    for nfield=1:length(fields)
        interventions = getfield(intr, fields{nfield});

        runFastAlignmentModelEMMCRecoveryFcn(amRunParameters,interventions,string(fields(nfield)+"_"));
    end
else
    fprintf("Cannot run, amInterventions and treatobs don't match\n")
end

%% write treatobs table

%  writetable(treatobs, fullfile(basedir, subfolder, filename),'Sheet','recovery new');
 
 
%% estimate acceptable offset amount at boundaries
% 
% % an offset can be found only for treatments that have show an "i" during
% % treatment
% % when offset can't be found -> permanent decline shifted down, permanent
% % improve shifted up
% proportion_no_offset = 1-during.i/(during.d + during.i + during.i);
% 
% % let's calculate what's the reasonnable amount of interventions where the
% % offset cannot be found 
% sum(Count)*proportion_no_offset
% 
% % 34/2 + 8 = 25 is acceptable

%% functions
function labels = getLabelsCount(list)
labels.d = sum(contains(list,"d"));
labels.s = sum(contains(list,"s"));
labels.i = sum(contains(list,"i"));
labels.no = sum(contains(list,"") | contains(list,"-")); % check this one
end

function [yeslist, nolist, s] = getLists(mask, table)
s = sum(mask);
yeslist = table.IntrNbr(mask);
nolist = table.IntrNbr(not(mask));
end

function [yeslist, s] = getVolumeList(mask, Vtable, IntrTable)
s = sum(mask);
% get id
idlist = Vtable.ID(mask);
% get intervention number
yeslist = IntrTable.IntrNbr(ismember(IntrTable.ID, idlist));
end