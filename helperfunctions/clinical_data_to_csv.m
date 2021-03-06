%% Write in excel file
writetable(brPatient, fullfile(basedir, 'breatheclinicaldata.xls'), 'Sheet', 'brPatient')
writetable(brAdmissions, fullfile(basedir, 'breatheclinicaldata.xls'), 'Sheet', 'brAdmissions')
writetable(brAntibiotics, fullfile(basedir, 'breatheclinicaldata.xls'), 'Sheet', 'brAntibiotics')
writetable(brDrugTherapy, fullfile(basedir, 'breatheclinicaldata.xls'), 'Sheet', 'brDrugTherapy')
writetable(brHghtWght, fullfile(basedir, 'breatheclinicaldata.xls'), 'Sheet', 'brHghtWght')
writetable(brCRP, fullfile(basedir, 'breatheclinicaldata.xls'), 'Sheet', 'brCRP')
writetable(brClinicVisits, fullfile(basedir, 'breatheclinicaldata.xls'), 'Sheet', 'brClinicVisits')
writetable(brOtherVisits, fullfile(basedir, 'breatheclinicaldata.xls'), 'Sheet', 'brOtherVisits')
writetable(brMicrobiology, fullfile(basedir, 'breatheclinicaldata.xls'), 'Sheet', 'brMicrobiology')
writetable(brPFT, fullfile(basedir, 'breatheclinicaldata.xls'), 'Sheet', 'brPFT')
writetable(brUnplannedContact, fullfile(basedir, 'breatheclinicaldata.xls'), 'Sheet', 'brUnplannedContact')

%% Write in csv files

writetable(brPatient, fullfile(basedir, 'brPatient.csv'))
writetable(brAdmissions, fullfile(basedir, 'brAdmissions.csv'))
writetable(brAntibiotics, fullfile(basedir, 'brAntibiotics.csv'))
writetable(brDrugTherapy, fullfile(basedir, 'brDrugTherapy.csv'))
writetable(brHghtWght, fullfile(basedir, 'brHghtWght.csv'))
writetable(brCRP, fullfile(basedir, 'brCRP.csv'))
writetable(brClinicVisits, fullfile(basedir, 'brClinicVisits.csv'))
writetable(brOtherVisits, fullfile(basedir, 'brOtherVisits.csv'))
writetable(brMicrobiology, fullfile(basedir, 'brMicrobiology.csv'))
writetable(brPFT, fullfile(basedir, 'brPFT.csv'))
writetable(brUnplannedContact, fullfile(basedir, 'brUnplannedContact.csv'))