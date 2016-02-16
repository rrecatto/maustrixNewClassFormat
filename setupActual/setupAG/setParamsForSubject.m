function setParamsForSubject

dataPath=fullfile(fileparts(fileparts(getRatrixPath)),'ratrixData',filesep);
defaultLoc=fullfile(dataPath, 'ServerData');

d=dir(fullfile(defaultLoc, 'db.mat'));

if length(d)==1
    rx=ratrix(defaultLoc,0);
    fprintf('loaded ratrix from default location\n')
else
    error('you are doing something dangerous - are you sure you know what you are doing?');
end

try
    [success, mac]=getMACaddress();
    if ~success
        mac='000000000000';
    end
catch ex
    getReport(ex)
    mac='000000000000';
end

pReturn = @mouseTraining_Return;
pOD = @mouseTraining_OD;
pBias = @mouseTraining_bias;
pOD_Rec = @mouseTraining_OD_Rec;
pAdaptiveTest = @mouseTraining_OD_RecAdapt;


try
    remoteFileLocation = '\\ghosh-nas.ucsd.edu\ghosh\Behavior\changeParams';
    
    changeParamsFile = fullfile(remoteFileLocation,[mac '.mat']);
    clear subjectChanges
    temp = load(changeParamsFile);
    subjectChanges = temp.subjectChanges;
    
    for i = 1:length(subjectChanges)
        
        subjectID = subjectChanges{i}{1};
        switch class(subjectID)
            case 'char'
                disp(subjectID);
                sub = getSubjectFromID(rx,subjectID);
                [~, step] = getProtocolAndStep(sub);
                newProt = subjectChanges{i}{2};
                newStep = subjectChanges{i}{3};
            case 'subject'
                tempID = getID(subjectID);
                disp(tempID);
                if isSubjectInRatrix(rx,tempID)
                    sub = getSubjectFromID(rx,subjectID);
                    [~, step] = getProtocolAndStep(sub);
                    newProt = subjectChanges{i}{2};
                    newStep = subjectChanges{i}{3};
                else
                    rx = addSubject(rx,sub,'bas');
                    newProt = subjectChanges{i}{2};
                    newStep = subjectChanges{i}{3};
                    if ~isnumeric(newStep)
                        error('nope. cannot use it this way');
                    end
                end
        end

        if strcmp(newStep,'step')
            % do nothing to step
        else
            step = newStep;
        end
        
        switch newProt
            case 'pReturn'
                [~, rx]=setProtocolAndStep(sub,pReturn(subjectID),true,true,true,step,rx,'mouseTraining_Return','bas');
            case 'pOD'
                [~, rx]=setProtocolAndStep(sub,pOD(subjectID),true,true,true,step,rx,'mouseTraining_OD','bas');
            case 'pBias'
                [~, rx]=setProtocolAndStep(sub,pBias(subjectID),true,true,true,step,rx,'mouseTraining_Bias','bas');
            case 'pOD_Rec'
                [~, rx]=setProtocolAndStep(sub,pOD_Rec(subjectID),true,true,true,step,rx,'mouseTraining_OD_Rec','bas');
            case 'pAdaptiveTest'
                [~, rx]=setProtocolAndStep(sub,pAdaptiveTest(subjectID),true,true,true,step,rx,'mouseTraining_OD_RecAdapt','bas');
        end
    end
    
    % once all subject changes are done replace file with empty data
    subjectChanges = {};
    save(changeParamsFile,'subjectChanges');
catch ex
    c = clock;
    message = {sprintf('Failed for subject::%s at time::%d:%d on %d-%d-%d',subjectID,c(4),c(5),c(2),c(3),c(1)),getReport(ex,'extended','hyperlinks','off')};
    switch mac
        case 'A41F7278B4DE' %gLab-Behavior1
            errIn = 'Error in Rig 1';
        case 'A41F729213E2' %gLab-Behavior2
            errIn = 'Error in Rig 2';
        case 'A41F726EC11C' %gLab-Behavior3
            errIn = 'Error in Rig 3';
        case '7845C4256F4C' %gLab-Behavior4
            errIn = 'Error in Rig 4';
        case '7845C42558DF' %gLab-Behavior5
            errIn = 'Error in Rig 5';
        case 'A41F729211B1' %gLab-Behavior6
            errIn = 'Error in Rig 6';
        otherwise
            errIn = 'Error in Some Rig';
    end
    gmail('sbalaji1984@gmail.com',errIn,message);
end
end