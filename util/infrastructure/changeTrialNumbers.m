minTrialNumber = 29136;
pathToSave = {'\\ghosh-nas.ucsd.edu\ghosh\Behavior\Box5\Permanent\259';...
    '\\ghosh-nas.ucsd.edu\ghosh\Behavior\VarDur2\Permanent\259'};
whichFiles = {'\\ghosh-nas.ucsd.edu\ghosh\Behavior\Box5\Permanent\259\trialRecords_898-1147_20150612T143437-20150612T151813.mat';...
    '\\ghosh-nas.ucsd.edu\ghosh\Behavior\Box5\Permanent\259\trialRecords_1148-1212_20150612T151830-20150612T153100.mat'};

for recNum = 1:length(whichFiles)
    temp = load(whichFiles{recNum});
    parsedInput = parseRecordName(whichFiles{recNum});
    for i = 1:length(temp.trialRecords)
        temp.trialRecords(i).trialNumber = temp.trialRecords(i).trialNumber+minTrialNumber;
    end
    
    trialRecords = temp.trialRecords;
    fieldsInLUT = temp.fieldsInLUT;
    sessionLUT = temp.sessionLUT;
    
    newName = sprintf('trialRecords_%d-%d_%s-%s.mat',min([trialRecords.trialNumber]),max([trialRecords.trialNumber]),parsedInput.timestampBegin,parsedInput.timestampEnd);
    for  j = 1:length(pathToSave)
        save(fullfile(pathToSave{j},newName),'trialRecords','fieldsInLUT','sessionLUT');
    end
    
end

