classdef subject
    
    properties
        id = '';
        
        protocol = [];
        trainingStepNum=uint8(0);
        
        protocolVersion=uint8(0);
        manualVersion=uint8(0);
        
        history = {};
    end
    
    methods
        function s = subject(id)
            validateattributes(id,{'char'},{'nonempty'});
            s.id = id;
        end
        
        function [subject r]=changeAllPercentCorrectionTrials(subject,newValue,r,comment,auth)
            
            validateattributes(r,{'ratrix'},{'nonempty'});
            assert(~isempty(getSubjectFromID(r,subject.id)))
            
            for i=1:subject.protocol.numTrainingSteps
                sm = subject.protocol.trainingSteps{i}.stimManager;
                updatable =hasUpdatablePercentCorrectionTrial(sm);
                if updatable
                    sm=setPercentCorrectionTrials(sm,newValue);
                    ts=setStimManager(ts,sm);
                end
                subject.protocol.trainingSteps{i}=ts;
            end
            
            [subject, r]=setProtocolAndStep(subject,protocol(getName(subject.protocol),steps),0,1,0,subject.trainingStepNum,r,comment,auth);
        end
        
        function [subject r]=setReinforcementParam(subject,param,val,stepNums,r,comment,auth)
            validateattributes(r,{'ratrix'},{'nonempty'});
            assert(~isempty(getSubjectFromID(r,subject.id)));
            
            switch stepNums
                case 'all'
                    steps=uint8(1:getNumTrainingSteps(subject.protocol));
                case 'current'
                    steps=subject.trainingStepNum;
                otherwise
                    if isvector(stepNums) && isNearInteger(stepNums) && all(stepNums>0 & stepNums<=getNumTrainingSteps(subject.protocol))
                        steps=uint8(stepNums);
                    else
                        error('stepNums must be ''all'', ''current'', or an integer vector of stepnumbers between 1 and numSteps')
                    end
            end
            
            for i=steps
                ts=getTrainingStep(subject.protocol,i);
                
                ts=setReinforcementParam(ts,param,val);
                [subject, r]=changeProtocolStep(subject,ts,r,comment,auth,i);
            end
        end
        
        function [subject r]=changeProtocolStep(subject,ts,r,comment,auth,stepNum)
            
            validateattributes(ts,{'trainingStep'},{'nonempty'});
            validateattributes(r,{'ratrix'},{'nonempty'});
            
            assert(~isempty(getSubjectFromID(r,subject.id)));
            
            if ~exist('stepNum','var')||isempty(stepNum)
                stepNum=subject.trainingStepNum;
            end
            
            if ~isempty(subject.protocol) && isscalar(stepNum) && isinteger(stepNum) && stepNum>0 && stepNum<=subject.protocol.numTrainingSteps
                if authorCheck(r,auth)
                    newProtocol = changeStep(subject.protocol, ts, stepNum);
                    
                    [subject, r]=setProtocolAndStep(subject,newProtocol,0,1,0,subject.trainingStepNum,r,comment,auth);
                else
                    error('author failed authentication')
                end
            else
                error('subject does not have a protocol, or stepNum is not a valid index of trainingSteps in the protocol')
            end
            
        end
        
        function s=decache(s)
            if ~isempty(s.protocol)
                s.protocol=decache(s.protocol);
            end
        end
        
        function display(s,str) 
            fprintf('id:\t\t%s\t%s',s.id,str);
        end
        
        function [subject, r, keepWorking, secsRemainingTilStateFlip, trialRecords, station] = doTrial(subject,r,station,rn,trialRecords,sessionNumber,compiledRecords)
            
            if isa(r,'ratrix') && isa(station,'station') && (isempty(rn) || isa(rn,'rnet'))
                [p t]=getProtocolAndStep(subject);
                if t>0
                    ts=getTrainingStep(p,t);
                    
                    [graduate, keepWorking, secsRemainingTilStateFlip, subject, r, trialRecords, station, manualTs] ...
                        =doTrial(ts,station,subject,r,rn,trialRecords,sessionNumber,compiledRecords);
                    %'subject'
                    %         newTrialRecords
                    
                    % 1/22/09 - if newTsNum is not empty, this means we want to manually move the trainingstep (not graduate)
                    if manualTs
                        newTsNum=[];
                        [proto currentTsNum]=getProtocolAndStep(subject);
                        validTs=[1:getNumTrainingSteps(p)];
                        validInputs{1}=validTs;
                        type='manual ts';
                        typeParams.currentTsNum=currentTsNum;
                        typeParams.trainingStepNames={};
                        for i=validTs
                            typeParams.trainingStepNames{end+1}=generateStepName(getTrainingStep(proto,i),'','');
                        end
                        newTsNum = userPrompt(getPTBWindow(station),validInputs,type,typeParams);
                        trialRecords(end).result=[trialRecords(end).result ' ' num2str(newTsNum)];
                        if newTsNum~=currentTsNum
                            [subject r]=setStepNum(subject,newTsNum,r,sprintf('manually setting to %d',newTsNum),'ratrix');
                        end
                        keepWorking=1;
                    end
                    
                    if graduate && ~manualTs % 6/11/09 - dont graduate if manual k+t switching to new training step
                        if getNumTrainingSteps(p)>=t+1
                            [subject r]=setStepNum(subject,t+1,r,'graduated!','ratrix');
                        else
                            if isLooped(p)
                                t
                                [subject r]=setStepNum(subject,uint16(1),r,'looping back to 1','ratrix'); % for looped protocols, the step is sent back to 1
                            else
                                [subject r]=setStepNum(subject,t,r,'can''t graduate because no more steps defined!','ratrix');
                            end
                        end
                    end
                elseif t==0
                    keepWorking=0;
                    secsRemainingTilStateFlip=-1;
                    newStep=[];
                    updateStep=0;
                else
                    error('training step is negative')
                end
            else
                error('need ratrix and station and rnet objects')
            end
            
        end
        
        function s=setProtocolVersion(s,protocolVersion)
            validateattributes(protocolVersion,{'uint8','scalar'})
            s.protocolVersion=protocolVersion;
        end
        
        function [s r]=setStepNum(s,i,r,comment,auth)
            validateattributes(r,{'ratrix'},{'nonempty'});
            assert(~isempty(getSubjectFromID(r,s.id)));
            assert(~subjectIDRunning(r,s.id));
            
            [p, t]=getProtocolAndStep(s);
            
            if isscalar(i) && isinteger(i) && i<=getNumTrainingSteps(p) && i>=0
                if authorCheck(r,auth)
                    [s, r]=setProtocolAndStep(s,p,0,0,1,i,r,comment,auth);
                else
                    error('author failed authentication')
                end
            else
                error('need a valid integer step number')
            end
        end
    end
end