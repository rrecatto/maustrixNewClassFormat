classdef subject
    
    properties
        id='';
        species='';
        strain='';
        geneticBackground = '';
        geneticModification = '';
        gender='';
        birthDate=[];
        receivedDate=[];
        litterID='';
        supplier='';
        protocol=[];
        trainingStepNum=uint8(0);
        protocolVersion=[];
    end
    
    methods
        function s=subject(varargin)
            % SUBJECT  class constructor.
            % s = subject(id,species,strain,gender,birthDate,receivedDate,litterID,supplier)
            s.protocolVersion.manualVersion=0;

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'subject'))
                        s = varargin{1};
                    else
                        error('Input argument is not a subject object')
                    end
                case 8
                    % create object using specified values

                    s.id=lower(varargin{1});
                    if (strcmpi(varargin{2},'rat') && strcmpi(varargin{3},'long-evans')) || ...
                            (strcmpi(varargin{2},'squirrel') && strcmpi(varargin{3},'wild caught')) || ...
                            (strcmpi(varargin{2},'mouse') && (strcmpi(varargin{3},'c57bl/6j') || strcmpi(varargin{3},'dba/2j') || strcmpi(varargin{3},'b6d2f1/j') )) || ...
                            (strcmpi(varargin{2},'degu') && strcmpi(varargin{3},'none')) || ...
                            (strcmpi(varargin{2},'human') && strcmpi(varargin{3},'none'))
                        s.species=varargin{2};
                        s.strain=varargin{3};
                    else
                        error('species must be ''rat'' (strain ''long-evans''), ''squirrel'' (strain ''wild''), ''mouse'' (strains ''c57bl/6j'' ''dba/2j'' ''B6D2F1/J''), ''degu'' (strain ''none''), or ''human'' (strain ''none'')')
                    end

                    if strcmpi(varargin{4},'male') || strcmpi(varargin{4},'female')
                        s.gender=varargin{4};
                    else
                        error('gender must be male or female')
                    end

                    dtb = datevec(varargin{5},'mm/dd/yyyy');
                    if ~strcmpi(varargin{6},'unknown')
                        dtr = datevec(varargin{6},'mm/dd/yyyy');
                    else
                        dtr=varargin{6};
                    end
                    if dtb(1)>=2005 && dtb(4) == 0 && dtb(5) == 0 && dtb(6) == 0 && (strcmp(dtr,'unknown') || (dtr(1)>=2005 && dtr(4) == 0 && dtr(5) == 0 && dtr(6) == 0))
                        s.birthDate=dtb;
                        s.receivedDate=dtr;
                    else
                        error('dates must be supplied as mm/dd/yyyy and no earlier than 2005 (acq date may be ''unknown'')')
                    end

                    s.litterID=varargin{7};
                    if strcmpi(s.litterID,'unknown') || (isstrprop(s.litterID(1), 'alpha') && isstrprop(s.litterID(1), 'lower') && s.litterID(2)==' ' && all(varargin{5}==s.litterID(3:end)))
                        %nothing
                    else
                        ['''' s.litterID '''']
                        error('litterID must be ''unknown'' or supplied as ''[single lower case letter] DOB(mm/dd/yyyy -- must match DOB supplied)'' -- ex: ''a 01/01/2007''')
                    end

                    if ismember(varargin{8},{'wild caught','Jackson Laboratories','Harlan Sprague Dawley'})
                        s.supplier=varargin{8};
                    else
                        error('supplier must be ''wild caught'' or ''Jackson Laboratories'' or ''Harlan Sprague Dawley''')
                    end

            %         s.protocol=[];
            %         s.trainingStepNum=0;
            %         s.protocolVersion.manualVersion=0;
                 
                case 10 % created to save mouse genetic details
                    % create object using specified values

                    s.id=lower(varargin{1});
                    if (strcmpi(varargin{2},'rat') && strcmpi(varargin{3},'long-evans')) || ...
                            (strcmpi(varargin{2},'squirrel') && strcmpi(varargin{3},'wild caught')) || ...
                            (strcmpi(varargin{2},'mouse') && (strcmpi(varargin{3},'c57bl/6j') || strcmpi(varargin{3},'dba/2j') || strcmpi(varargin{3},'b6d2f1/j') )) || ...
                            (strcmpi(varargin{2},'degu') && strcmpi(varargin{3},'none')) || ...
                            (strcmpi(varargin{2},'human') && strcmpi(varargin{3},'none')) || ...
                            (strcmpi(varargin{2},'virtual'))
                        s.species=varargin{2};
                        s.strain=varargin{3};
                    else
                        keyboard
                        error('species must be ''rat'' (strain ''long-evans''), ''squirrel'' (strain ''wild''), ''mouse'' (strains ''c57bl/6j'' ''dba/2j'' ''B6D2F1/J''), ''degu'' (strain ''none''), ''human'' (strain ''none''), or ''virtual'' (strain ''none'',''N/A'','''')')
                    end

                    if strcmpi(varargin{4},'male') || strcmpi(varargin{4},'female')
                        s.gender=varargin{4};
                    elseif strcmp(varargin{2},'virtual') % for virtuals, dont check anything
                        s.gender = varargin{4};
                    else
                        error('gender must be male or female')
                    end

                    dtb = datevec(varargin{5},'mm/dd/yyyy');
                    if ~strcmp(varargin{6},'unknown')
                        dtr = datevec(varargin{6},'mm/dd/yyyy');
                    else
                        dtr=varargin{6};
                    end
                    if dtb(1)>=2005 && dtb(4) == 0 && dtb(5) == 0 && dtb(6) == 0 && (strcmp(dtr,'unknown') || (dtr(1)>=2005 && dtr(4) == 0 && dtr(5) == 0 && dtr(6) == 0))
                        s.birthDate=dtb;
                        s.receivedDate=dtr;
                    else
                        error('dates must be supplied as mm/dd/yyyy and no earlier than 2005 (acq date may be ''unknown'')')
                    end

                    s.litterID=varargin{7};
                    if strcmp(s.litterID,'unknown') || (isstrprop(s.litterID(1), 'alpha') && isstrprop(s.litterID(1), 'lower') && s.litterID(2)==' ' && all(varargin{5}==s.litterID(3:end)))
                        %nothing
                    else
                        ['''' s.litterID '''']
                        error('litterID must be ''unknown'' or supplied as ''[single lower case letter] DOB(mm/dd/yyyy -- must match DOB supplied)'' -- ex: ''a 01/01/2007''')
                    end

                    if ismember(varargin{8},{'wild caught','Jackson Laboratories','Harlan Sprague Dawley','Bred In-house'})
                        s.supplier=varargin{8};
                    else
                        error('supplier must be ''wild caught'' or ''Jackson Laboratories'' or ''Harlan Sprague Dawley''')
                    end

                    if ischar(varargin{9})
                        s.geneticBackground = varargin{9};
                    else
                        error('geneticBackground needs to be a string');
                    end

                    if ischar(varargin{10})
                        s.geneticModification = varargin{10};
                    else
                        error('geneticModification needs to be a string');
                    end
            %         s.protocol=[];
            %         s.trainingStepNum=0;
            %         s.protocolVersion.manualVersion=0;
                    

                otherwise
                    error('Wrong number of input arguments')
            end
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
        
       function out=display(s)
        if strcmp(s.receivedDate,'unknown')
            rd=s.receivedDate;
        else
            rd=datestr(s.receivedDate,'mm/dd/yyyy');
        end
            out=sprintf('id:\t\t%s\nspecies:\t%s\nstrain:\t\t%s\ngender:\t\t%s\nbirth:\t\t%s\nacquired:\t%s\nlitterID:\t%s\nsupplier:\t%s',...
                         s.id,s.species,s.strain,s.gender,datestr(s.birthDate,'mm/dd/yyyy'),rd,s.litterID,s.supplier);
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
        
        function out = getID(s)
            out = s.id;
        end
        
        function out=getLitterID(s)
            out=s.litterID;
        end
        
        function [p t]=getProtocolAndStep(s)
            p=s.protocol;
            t=s.trainingStepNum;
        end
        
        function [s r]=setProtocolAndStep(s,p,thisIsANewProtocol,thisIsANewTrainingStep,thisIsANewStepNum,i,r,comment,auth)
            % INPUTS
            %   s                       subject object
            %   p                       protocol (eg from setProtocol)
            %   thisIsANewProtocol  	if FALSE, does not rewrite protocol descr to log
            %   thisIsANewTrainingStep  if FALSE, does not rewrite trainingstep descr to log
            %   thisIsANewStepNum       if FALSE, does not log setting of new step number
            %   i                       index of training step
            %   r                       ratrix object
            %   comment                 string that will be saved to log file
            %   auth                    string which must be an authorized user id
            %                           (see ratrix.authorCheck)
            % OUTPUTS
            % s     subject object
            % r     ratrix object
            %
            % example call
            %     [subj r]=setProtocolAndStep(subj,p,1,0,1,1,r,'first try','edf');

            if isa(p,'protocol') && isa(r,'ratrix') && ~isempty(getSubjectFromID(r,s.id)) && ~subjectIDRunning(r,s.id)
                %     i
                %     getNumTrainingSteps(p)

                if i<=getNumTrainingSteps(p) && i>=0 && isscalar(i) && mod(i,1)==0 %mod(i,1)==0 checks that i is an integer (even as a double type)
                    if authorCheck(r,auth)
                        s.protocol=p;
                        s.trainingStepNum=uint8(i); % 1/9/09 - force to uint8 to pass isinteger tests down the line

                        if strcmp(auth,'ratrix')
                            s.protocolVersion.autoVersion=s.protocolVersion.autoVersion+1;
                        else
                            s.protocolVersion.autoVersion=1;
                            s.protocolVersion.manualVersion=s.protocolVersion.manualVersion+1;
                        end
                        s.protocolVersion.date=datevec(now);
                        s.protocolVersion.author=auth;

                        r=updateSubjectProtocol(r,s,comment,auth,thisIsANewProtocol,thisIsANewTrainingStep,thisIsANewStepNum);

                    else
                        error('author failed authentication')
                    end
                else
                    error('need a valid integer step number')
                end
            else
                isa(p,'protocol')
                isa(r,'ratrix')
                ~isempty(getSubjectFromID(r,s.id))
                ~subjectIDRunning(r,s.id)
                error('need a protocol object, a valid ratrix with that contains this subject, and this subject can''t be running')
            end
        end
        
    end
end