classdef stimManager
    
    properties
        maxWidth=0;
        maxHeight=0;
        scaleFactor=[];
        interTrialLuminance=0;
        interTrialDuration=1;
    end
    
    methods
        function s=stimManager(varargin)
            % STIMMANAGER  class constructor. ABSTRACT CLASS -- DO NOT INSTANTIATE
            % s = stimManager(maxWidth,maxHeight,scaleFactor,interTrialLuminance)
            switch nargin
                case 0
                    % if no input arguments, create a default object
                    
                    s = class(s,'stimManager');
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'stimManager'))
                        s = varargin{1};
                    else
                        error('Input argument is not a stimManager object')
                    end
                case 4
                    if varargin{1}>0 && varargin{2}>0
                        s.maxWidth=varargin{1};
                        s.maxHeight=varargin{2};

                    else
                        error('maxWidth and maxHeight must be positive')
                    end

                    if (length(varargin{3})==2 && all(varargin{3}>0)) || (length(varargin{3})==1 && varargin{3}==0)
                        s.scaleFactor=varargin{3};
                    else
                        error('scale factor is either 0 (for scaling to full screen) or [width height] positive values')
                    end

                    if isnumeric(varargin{4})
                        if varargin{4}>=0 && varargin{4}<=1
                            s.interTrialLuminance=varargin{4};
                            s.interTrialDuration=1;
                        else
                            error('interTrailLuminance must be >=0 and <=1')
                        end
                    elseif iscell(varargin{4}) && length(varargin{4})==2
                        if varargin{4}{1}>=0 && varargin{4}{1}<=1
                            s.interTrialLuminance=varargin{4}{1};
                        else
                            error('interTrailLuminance must be >=0 and <=1')
                        end

                        if varargin{4}{2}>0
                            s.interTrialDuration=varargin{4}{2};
                        else
                            error('interTrialDuration must be >=0')
                        end

                    else
                        error('either numeric background only or cell with background and duration')
                    end

                    s = class(s,'stimManager');
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function analysis(sm,detailRecords,subjectID)
            %base stim manager detailed analysis does nothing
        end
        
        function out = boxOKForStimManager(stimManager,b,r)
            if isa(b,'box') && isa(r,'ratrix')
                out=1;
                stations=getStationsForBoxID(r,getID(b));
                for i=1:length(stations)
                    if ~stationOKForStimManager(stimManager,stations(i))
                        out=0;
                    end
                end
            else
                error('need a box and ratrix object')
            end
        end % end function
        
        function    [value]  = canForceStimDetails(stimManager,forceStimDetails)
            % returns true if the stimulus manager has a optional arguument in calcStim
            % that forces the stimulus details to apply. Only managers that impliment
            % this feature should return true, and they should be able to error check
            % the force detail requests to confrim that they are valid requests... for
            % example, you can request a field to change that does not exist on that
            % stimulus

              value = false;
        end
        
        function out=checkTargetIsPresent(sm,details)
            %By default this will error for all stimManager unless they overwrite this
            %method in order to express the appropriate logic

            class(sm)

            error('This stimManager has not defined if a target is present or absent.');
            %asymetricReinforcement probably would also handle an output of empty or
            %nan, but just erroring here is just more conservative

            %out=[];
        end
        
        function commonName = commonNameForStim(stimType,params)
            % default practice when you dont know how to treat the stim
            classType = class(stimType);
            commonName = classType;
        end
        
        function [isIdent diffIn] = compareStimRecords(stimType,params1,params2)
            % this function will automatically assume that the trials are different.
            % but diffIn will still be empty!
            isIdent = false;
            diffIn = {};
        end

        function [out, scale] = correctStim(stimManager,numFrames)
            scale=0;

            out = double(getInterTrialLuminance(stimManager));
        end
        
        function out = createAnalysis(sm,c)
            if parameters.checkCurrUnit
                d = dir(parameters.singleUnitPath);
                d = d(~ismember({d.name},{'.','..'}));
                [junk order] = sort([d.datenum]);
                d = d(order);
                temp = load(fullfile(parameters.singleUnitPath,d(end).name));
                currentUnit = temp.currentUnit;

                c = cumulativedata;
                c.stimInfo = stimInfo;

                switch sweptParameterThis{1}
                    case 'pixPerCycs'
                        sfAnalysis = sfGratings(parameters.subjectID,trialNumbers,c);
                        currentUnit = addAnalysis(currentUnit,sfAnalysis);
                    case 'driftfrequencies'
                        tfAnalysis = tfGratings(parameters.subjectID,trialNumbers,c);
                        currentUnit = addAnalysis(currentUnit,tfAnalysis);
                    case 'orientations'
                        orAnalysis = orGratings(parameters.subjectID,trialNumbers,c);
                        currentUnit = addAnalysis(currentUnit,orAnalysis);
                    case 'contrasts'
                        cntrAnalysis = cntrGratings(parameters.subjectID,trialNumbers,c);
                        currentUnit = addAnalysis(currentUnit,cntrAnalysis);
                    case {'startPhases','durations','radii','annuli'};
                        % do nothing
                    otherwise
                        error('unknown parameter');
                end
                save(fullfile(parameters.singleUnitPath,d(end).name),'currentUnit');
            end
        end
        
        function s=decache(s)
        end
        
        function [t] = display(stim)
            t = class(stim);
        end
        
        function displayCumulativePhysAnalysis(sm,cumulativeData)
            % called by analysis manager when overwrite spikes is false, and analsis
            % has generates a cumulative data for this range.  allows for display,
            % without recomputation

            %does nothing by default
        end

        function retval = enableChunkedPhysAnalysis(sm)
            % returns true if physAnalysis knows how to deal with, and wants each chunk
            % as it comes.  true for getting each chunk, false for getting the
            % combination of all chunks after analysisManagerByChunk has detected
            % spikes, sorted them, and rebundled them as spikes in their chunked format

            retval=false; %stim managers could sub class this method if they want to run on EVERY CHUNK, as opposed to the end of the trial

        end % end function

        function retval = enableCumulativePhysAnalysis(sm)
            % returns true if physAnalysis knows how to deal with, and wants each chunk
            % as it comes.  true for getting each chunk, false for getting the
            % combination of all chunks after analysisManagerByChunk has detected
            % spikes, sorted them, and rebundled them as spikes in their chunked format

            retval=false; %stim managers could sub class this method if they want to run on EVERY CHUNK, as opposed to the end of the trial

        end % end function
        
        function [out scale] = errorStim(stimManager,numFrames)
            scale=0;
            x = double(rand(1,1,numFrames)>.5);
            errorStimIsOnlyBlack = true;
            if errorStimIsOnlyBlack 
                out = zeros(size(x));
            else
                out = x;
            end
        end
        
        function expertPostTrialCleanUp(stimManager)
            % this function is used in expert mode to perform user-defined cleanup tasks between phases
            % default behavior is to call Screen('Close') to clear all textures and close offscreen windows (but leave onscreen window!)

            Screen('Close')
        end
        
        function [out compiledLUT]=extractBasicFields(sm,trialRecords,compiledLUT)
            %note many of these are actually restricted by the trialManager -- ie
            %nAFC has scalar targetPorts, but freeDrinks doesn't.

            bloat=false;
            % fields to extract from trialRecords:
            %   trialNumber
            %   sessionNumber
            %   date
            %   station.soundOn
            %   station.physicalLocation
            %   station.numPorts
            %   trainingStepNum
            %   trainingStepName
            %   protocolName
            %   numStepsInProtocol
            %   protocolVersion.manualVersion
            %   protocolVersion.autoVersion
            %   protocolVersion.protocolDate
            %   correct
            %   trialManagerClass
            %   stimManagerClass
            %   schedulerClass
            %   criterionClass
            %   reinforcementManagerClass
            %   scaleFactor
            %   type
            %   targetPorts
            %   distractorPorts
            %   response
            %   containedManualPokes
            %   didHumanResponse
            %   containedForcedRewards
            %   didStochasticResponse

            % ==============================================================================================
            % start extracting fields
            [out.trialNumber, compiledLUT]                                =extractFieldAndEnsure(trialRecords,{'trialNumber'},'scalar',compiledLUT);
            [out.sessionNumber, compiledLUT]                              =extractFieldAndEnsure(trialRecords,{'sessionNumber'},'scalar',compiledLUT);
            [out.date, compiledLUT]                                       =extractFieldAndEnsure(trialRecords,{'date'},'datenum',compiledLUT);
            [out.soundOn, compiledLUT]                                    =extractFieldAndEnsure(trialRecords,{'station','soundOn'},'scalar',compiledLUT);
            [out.physicalLocation, compiledLUT]                           =extractFieldAndEnsure(trialRecords,{'station','physicalLocation'},'equalLengthVects',compiledLUT);
            [out.numPorts, compiledLUT]                                   =extractFieldAndEnsure(trialRecords,{'station','numPorts'},'scalar',compiledLUT);
            [out.step, compiledLUT]                                       =extractFieldAndEnsure(trialRecords,{'trainingStepNum'},'scalar',compiledLUT);
            [out.trainingStepName, compiledLUT]                           =extractFieldAndEnsure(trialRecords,{'trainingStepName'},'scalarLUT',compiledLUT);
            [out.protocolName, compiledLUT]                               =extractFieldAndEnsure(trialRecords,{'protocolName'},'scalarLUT',compiledLUT);
            [out.numStepsInProtocol, compiledLUT]                         =extractFieldAndEnsure(trialRecords,{'numStepsInProtocol'},'scalar',compiledLUT);
            [out.manualVersion, compiledLUT]                              =extractFieldAndEnsure(trialRecords,{'protocolVersion','manualVersion'},'scalar',compiledLUT);
            [out.autoVersion, compiledLUT]                                =extractFieldAndEnsure(trialRecords,{'protocolVersion','autoVersion'},'scalar',compiledLUT);
            [out.protocolDate, compiledLUT]                               =extractFieldAndEnsure(trialRecords,{'protocolVersion','date'},'datenum',compiledLUT);
            % change correct to be something that needs to be computed if trialManagerClass=nAFC
            [out.correct, compiledLUT]                                    =extractFieldAndEnsure(trialRecords,{},'correct',compiledLUT);

            [out.trialManagerClass, compiledLUT]                          =extractFieldAndEnsure(trialRecords,{'trialManagerClass'},'scalarLUT',compiledLUT);
            [out.stimManagerClass, compiledLUT]                           =extractFieldAndEnsure(trialRecords,{'stimManagerClass'},'scalarLUT',compiledLUT);
            [out.schedulerClass, compiledLUT]                             =extractFieldAndEnsure(trialRecords,{'schedulerClass'},'scalarLUT',compiledLUT);
            [out.criterionClass, compiledLUT]                             =extractFieldAndEnsure(trialRecords,{'criterionClass'},'scalarLUT',compiledLUT);
            [out.reinforcementManagerClass, compiledLUT]                  =extractFieldAndEnsure(trialRecords,{'reinforcementManagerClass'},'scalarLUT',compiledLUT);
            % [out.scaleFactor compiledLUT]                                =extractFieldAndEnsure(trialRecords,{'scaleFactor'},'equalLengthVects',compiledLUT);
            % [out.type compiledLUT]                                       =extractFieldAndEnsure(trialRecords,{'type'},'mixed',compiledLUT);
            [out.targetPorts, compiledLUT]                                =extractFieldAndEnsure(trialRecords,{'targetPorts'},{'bin2dec',num2cell(out.numPorts)},compiledLUT);
            [out.distractorPorts, compiledLUT]                            =extractFieldAndEnsure(trialRecords,{'distractorPorts'},{'bin2dec',num2cell(out.numPorts)},compiledLUT);
            try
                out.result                                                   =ensureScalar(cellfun(@encodeResult,{trialRecords.result},num2cell(out.targetPorts),num2cell(out.distractorPorts),num2cell(out.correct),'UniformOutput',false));
            catch
                ple
                out.result=ones(1,length(trialRecords))*nan;
            end
            [out.containedAPause, compiledLUT]                            =extractFieldAndEnsure(trialRecords,{'containedAPause'},'scalar',compiledLUT);
            [out.containedManualPokes, compiledLUT]                       =extractFieldAndEnsure(trialRecords,{'containedManualPokes'},'scalar',compiledLUT);
            [out.didHumanResponse, compiledLUT]                           =extractFieldAndEnsure(trialRecords,{'didHumanResponse'},'scalar',compiledLUT);
            [out.containedForcedRewards, compiledLUT]                     =extractFieldAndEnsure(trialRecords,{'containedForcedRewards'},'scalar',compiledLUT);
            [out.didStochasticResponse, compiledLUT]                      =extractFieldAndEnsure(trialRecords,{'didStochasticResponse'},'scalar',compiledLUT);
            % 1/13/09 - need to peek into stimDetails to get correctionTrial (otherwise analysis defaults correctionTrial=0)
            % need a try-catch here because this is potentially dangerous (stimDetails may not be the same for all trials, in which case this will error
            % from the vector indexing
            try
            %     if strcmp(LUTlookup(compiledLUT,unique(out.trialManagerClass)),'nAFC')
                    [out.correctionTrial, compiledLUT]                            =extractFieldAndEnsure(trialRecords,{'stimDetails','correctionTrial'},'scalar',compiledLUT);
            %     else
            %         out.correctionTrial=ones(1,length(trialRecords))*nan;
            %     end
            catch
                out.correctionTrial=ones(1,length(trialRecords))*nan;
            end    
            % 1/14/09 - added numRequestLicks and firstILI
            [out.numRequests, compiledLUT]                                =extractFieldAndEnsure(trialRecords,{},'numRequests',compiledLUT);
            [out.firstIRI, compiledLUT]                                   =extractFieldAndEnsure(trialRecords,{},'firstIRI',compiledLUT);
            [out.responseTime, compiledLUT]                               =extractFieldAndEnsure(trialRecords,{},'responseTime',compiledLUT);
            [out.actualRewardDuration, compiledLUT]                       =extractFieldAndEnsure(trialRecords,{},'actualRewardDuration',compiledLUT);
            [out.proposedRewardDuration, compiledLUT]                       =extractFieldAndEnsure(trialRecords,{},'proposedRewardDuration',compiledLUT);
            [out.proposedPenaltyDuration, compiledLUT]                       =extractFieldAndEnsure(trialRecords,{},'proposedPenaltyDuration',compiledLUT);

            % adding code to get details about reinforcement
            [out.potentialRewardMS,compiledLUT]                             = extractFieldAndEnsure(trialRecords, {'reinforcementManager','rewardSizeULorMS'},'scalar',compiledLUT);
            [out.potentialRequestRewardMS,compiledLUT]                             = extractFieldAndEnsure(trialRecords, {'reinforcementManager','reinforcementManager','requestRewardSizeULorMS'},'scalar',compiledLUT);
            [out.potentialRewardScalar,compiledLUT]                         = extractFieldAndEnsure(trialRecords, {'reinforcementManager','reinforcementManager','scalar'},'scalar',compiledLUT);
            [out.potentialPenalty,compiledLUT]                              = extractFieldAndEnsure(trialRecords, {'reinforcementManager','reinforcementManager','msPenalty'},'scalar',compiledLUT);


            % 3/5/09 - we need to calculate a 'response' field for analysis based either on trialRecords.response (old-style)
            % or trialRecords.phaseRecords.responseDetails.tries (new-style) for the phase labeled 'discrim'
            [out.response]                                               =getResponseFromTrialRecords(trialRecords);
            [out.responseTime]                                           =getResponseTimeFromTrialRecords(trialRecords);

            %12/10/09 - access to more lick info... only do it for goNoGos to prevent bloat
            % this would be reasonable: any(strcmp(trialRecords(1).trialManagerClass,{'cuedGoNoGo','goNoGo'}))
            % but only have the ID of the trialManger=26 without the LUT, thus using the
            % presense of the responseWindowMs instead
            try
                x=trialRecords(1).trialManager.trialManager;
                if isfield(x,'responseWindowMs') && ~isempty(x.responseWindowMs) && ~isinf(x.responseWindowMs(2))
                    %OLD
                    %[out.lickTimes compiledLUT] = extractFieldAndEnsure(trialRecords,{},'lickTimesInCell',compiledLUT); % wrt discrimStart
                    %[out.discrimStart compiledLUT] = extractFieldAndEnsure(trialRecords,{},'discrimStart',compiledLUT); % wrt trial start

                    %NEW
                    [out.lickTimes compiledLUT]= extractFieldAndEnsure(trialRecords,{},'lickTimesInMatrix',compiledLUT);
                    [out.preResponseStartRaw compiledLUT]= extractFieldAndEnsure(trialRecords,{},'preResponseStartRaw',compiledLUT);
                    [out.discrimStartRaw compiledLUT]= extractFieldAndEnsure(trialRecords,{},'discrimStartRaw',compiledLUT);
                    [out.trialStartRaw compiledLUT]= extractFieldAndEnsure(trialRecords,{},'trialStartRaw',compiledLUT);

                    [out.expectedPreRequestDurSec compiledLUT]= extractFieldAndEnsure(trialRecords,{},'expectedPreRequestDurSec',compiledLUT);
                    [out.responseWindowStartSec compiledLUT]= extractFieldAndEnsure(trialRecords,{},'responseWindowStartSec',compiledLUT);
                    [out.responseWindowStopSec compiledLUT]= extractFieldAndEnsure(trialRecords,{},'responseWindowStopSec',compiledLUT);
                    [out.discrimStart compiledLUT] = extractFieldAndEnsure(trialRecords,{},'discrimStart',compiledLUT); % prob want this too

                else
                    % this may error if rats run on something else after a goNoGo task... leaving the
                    %field undefined... might have to define cells of nan's for all rats,
                    %but trying to avoid that
                    %[out.lickTimes]=nans
                    %[out.discrimStart]=nans
                end
            end

            % out.numRequests=ones(1,length(trialRecords))*nan;
            % for i=1:length(trialRecords)
            %     if isfield(trialRecords(i),'responseDetails') && isfield(trialRecords(i).responseDetails,'tries') && ...
            %             ~isempty(trialRecords(i).responseDetails.tries) % if this field exists, overwrite the nan
            %         out.numRequests(i)=size(trialRecords(i).responseDetails.tries,2)-1;
            %     end
            % end
            % out.firstIRI=ones(1,length(trialRecords))*nan;
            % for i=1:length(trialRecords)
            %     if isfield(trialRecords(i),'responseDetails') && isfield(trialRecords(i).responseDetails,'times') && ...
            %             ~isempty(trialRecords(i).responseDetails.times) && size(trialRecords(i).responseDetails.times,2)-1>=2
            %         out.firstIRI(i)=diff(cell2mat(trialRecords(i).responseDetails.times(1:2)));
            %     end
            % end
            try
            verifyAllFieldsNCols(out,length(trialRecords));
            catch
                keyboard
            end
        end


% ==================================================================
% HELPER FUNCTIONS

        function out=encodeResult(result,targs,dstrs,correct)

            if isa(result,'double') && all(result==1 | result==0)
                warning('edf sees double rather than logical response on osx 01.21.09 -- why?')
                result=logical(result);
            end
            if targs==0 %empty target ports (in decimal representation)
                targs=[];
            end
            if dstrs==0 % empty distractor ports (in decimal representation)
                dstrs=[];
            end
            % if we do decide to re-implement errorchecking on targets/distractors, keep in mind that
            % targs/dstrs are in DECIMAL format (ie targetPorts [1,3] = '101' = 5)

            if ischar(result)
                switch result
                    case 'nominal'
                        out=1;
                    case 'timedout'
                        out=2;
                    case 'multiple ports'
                        out=-1;
                    case 'none'
                        out=-2;
                    case 'manual kill'
                        out=0;
                    case 'shift-2 kill'
                        out=-4;
                    case 'server kill'
                        out=-5;
                    case 'manual flushPorts'
                        out=-8;
                    otherwise
                        % 1/22/09 - if the response is 'manual training step %d'
                        match=regexp(result,'manual training step \d+','match');
                        if ~isempty(match)
                            out=-7; % manually set training step
                        else
                            out=-6;
                            result
                            warning('unrecognized response')
                        end
                end
            else
                result
                class(result)
                error('unrecognized result type')
            end

            % if ismember(out,targs) == correct
            %     %pass
            % else
            %     out
            %     targs
            %     correct
            %     error('bad correct calc')
            % end

            if all(isempty(intersect(dstrs,targs)))
                %pass
            else
                error('found intersecting targets and distractors')
            end

        end


        function [out compiledLUT] = ensureScalarOrAddCellToLUT(fieldArray, compiledLUT)
            % this function either returns a scalar array, or if it finds that fieldArray is a cell array, performs LUT processing on the fieldArray
            % this allows extractBasicFields to support versions of trialRecords that dont use a LUT
            try
                out=ensureScalar(fieldArray);
            catch
                ensureTypedVector(fieldArray,'char'); % ensure that this is cell array of characters, otherwise no point using a LUT
                [out compiledLUT] = addOrFindInLUT(compiledLUT, fieldArray);
            end

            end % end function

            function out = getResponseFromTrialRecords(trialRecords)
            % Get the trialRecords.response field if it exists, otherwise look for trialRecords.phaseRecords.responseDetails.tries
            % return -1 if neither exists...uh oh
            out=ones(1,length(trialRecords))*-1;
            if isfield(trialRecords,'response')
                out=cell2mat(cellfun(@decideResponse,{trialRecords.response},'UniformOutput',false));
            end
            if isfield(trialRecords,'phaseRecords') && isfield(trialRecords,'result') && ...
                    ~all(cellfun(@isempty,{trialRecords.phaseRecords})) % these two 'if' cases should be mutually exclusive in latest code, but not always been the case
                out=cell2mat(cellfun(@getResponseFromTries,{trialRecords.phaseRecords},'UniformOutput',false));
            end
            end

            function out = getResponseTimeFromTrialRecords(trialRecords)
            % Get the trialRecords.responseTime field if it exists, otherwise look for trialRecords.phaseRecords.responseDetails.tries
            % return -1 if neither exists...uh oh
            out=ones(1,length(trialRecords))*-1;
            if isfield(trialRecords,'responseTime')
                out=cell2mat({trialRecords.responseTime});
            end
            if isfield(trialRecords,'phaseRecords') && isfield(trialRecords,'result') && ...
                    ~all(cellfun(@isempty,{trialRecords.phaseRecords})) % these two 'if' cases should be mutually exclusive in latest code, but not always been the case
                out=cell2mat(cellfun(@getResponseTimeFromPhaseRecords,{trialRecords.phaseRecords},'UniformOutput',false));
            end
            end

            function out = decideResponse(response)
            resp=find(response);
            if length(resp)==1 && ~ischar(response)
                out=resp;
            else
                out=-1;
            end
            end % end function

            function out = getResponseTimeFromPhaseRecords(phaseRecords)
            % #define response time = start of discrim phase to start of reinforced
            % phase
            % designed by balaji Aug 17 2012
            phaseTypes = {phaseRecords.phaseType};
            % remove emptys
            phaseTypes = phaseTypes(~cellfun(@isempty,phaseTypes));
            whichDiscrim = ismember(phaseTypes,'discrim');
            whichReinf = ismember(phaseTypes,'reinforced');
            if ~any(whichDiscrim) || ~any(whichReinf)
                out = NaN;
            elseif length(find(whichDiscrim))>1 || length(find(whichReinf))>1
                error('you need to support multiple reinfs or discrims separately');
            else
                out = phaseRecords(whichReinf).responseDetails.startTime-phaseRecords(whichDiscrim).responseDetails.startTime;
            end
            % keyboard
            end

            function out = getResponseFromTries(phaseRecords)
            found = false;

            try
                pInd=find(strcmp({phaseRecords.phaseLabel},'discrim'));
                % we assume the last try of the 'discrim' phase to be the response
                if length(pInd)==1
                    tries=phaseRecords(pInd).responseDetails.tries;
                    response=tries{end};
                    out=decideResponse(response);
                    found = true;
                end
            catch 
                disp('failed probably because the reponse was in the post-discrim phase...')
            end

            if ~found
                % it is possible that the actual response is in the post-discrim
                pIndAlt=find(strcmp({phaseRecords.phaseType},'post-discrim'));
                for i = 1:length(pIndAlt)
                    if ~found
                        try
                            triesAlt = phaseRecords(pIndAlt(i)).responseDetails.tries;
                            responseAlt=triesAlt{end};
                            out=decideResponse(responseAlt);
                            found = true;
                        catch
                            disp('didnt catch on this phase, trying another phase');
                        end
                    end
                end
            end


            if ~found
                out = -1;
            end
        end % end function

        function [out newLUT]=extractDetailFields(sm,basicRecords,trialRecords,LUTparams)
            out=struct;
            newLUT=LUTparams.compiledLUT;
            %out=struct('a',num2cell(1:length(trialRecords)));
            %out=rmfield(out,'a'); %makes a 1xn struct array with no fields (any nicer way to make this?)

            verifyAllFieldsNCols(out,length(trialRecords));
        end

        function    [value]  = getCurrentShapedValue(t)
            % currently returns empty. If shaping, see method on one of Philip's flanker stims.

              value = [];

        end
        
        %this needs to have access class 'protected' (subclasses need to use it,
        %but others should not be allowed to access it).  but have to upgrade to
        %matlab's new OOP architecture to get protected members.
        function i=getInterTrialDuration(s)
            i=s.interTrialDuration;
        end
        
        %this needs to have access class 'protected' (subclasses need to use it,
        %but others should not be allowed to access it).  but have to upgrade to
        %matlab's new OOP architecture to get protected members.
        function i=getInterTrialLuminance(s)
            i=s.interTrialLuminance;
        end
    
        function out = getLEDParams(sm)
            out = sm.LEDParams;
        end
        
        function h=getMaxHeight(s)
            h=s.maxHeight;
        end
        
        function w=getMaxWidth(s)
            w=s.maxWidth;
        end
        
        function outStr = getNameFragment(stimManager)
            % returns abbreviated class name
            % should be overriden by stimManager-specific strings
            % used to generate names for trainingSteps

            outStr = class(stimManager);
        end % end function
        
        function    [value]  = getPercentCorrectionTrials(t)
            value = nan ;  % this is not  DEFINED ACCESS FOR THE DEFAULT STIM MANAGER
        end
        
        function a=getPhysAnalysis(s,physRecords,filePaths)
         % a default object, with default methods
            a=physiologyAnalysis(physRecords,filePaths);
        end
        
        function out = getPhysAnalysisObject(sm,subject,trials,channels,dataPath,stim,c)
                    %      getPhysAnalysisObject(sm,s.subject,trials,chans,dataPath,physRecords,c);
            if ~exist('c','var')||isempty(c)
                c = struct([]);
            end
            out = physiologyAnalysis(subject,trials,channels,dataPath,stim,c);
        end
        
        function sf=getScaleFactor(sm)
            sf=sm.scaleFactor;
        end
        
        function soundsToPlay = getSoundsToPlay(stimManager, ports, lastPorts, phase, phaseType, stepsInPhase,msRewardSound, msPenaltySound, ...
    targetOptions, distractorOptions, requestOptions, playRequestSoundLoop, trialManagerClass, trialDetails, stimDetails)
            % see doc in stimManager.calcStim.txt

            playLoopSounds={};
            playSoundSounds={};

            % nAFC/goNoGo setup:
            if strcmp(trialManagerClass, 'nAFC') || ...
                    strcmp(trialManagerClass,'biasedNAFC') || ...
                    strcmp(trialManagerClass,'goNoGo') || ...
                    strcmp(trialManagerClass,'oddManOut') || ...
                    strcmp(trialManagerClass,'cuedGoNoGo') || ...
                    strcmp(trialManagerClass,'changeDetectorTM')
                % play trial start sound
                if phase==1 && stepsInPhase <=0
                    playSoundSounds{end+1} = {'trialStartSound', 50};
                elseif strcmp(phaseType,'pre-request') && (any(ports(targetOptions)) || any(ports(distractorOptions)) || ...
                    (any(ports) && isempty(requestOptions))) 
                    % play white noise (when responsePort triggered during phase 1)
                    playLoopSounds{end+1} = 'trySomethingElseSound';
                elseif ismember(phaseType,{'discrim','pre-response'}) && any(ports(requestOptions))  
                    % play stim sound (when stim is requested during phase 2)
                    playLoopSounds{end+1} = 'keepGoingSound';
                elseif strcmp(phaseType,'reinforced') && stepsInPhase <= 0 && trialDetails.correct
                    % play correct sound
                    playSoundSounds{end+1} = {'correctSound', msRewardSound};
                elseif strcmp(phaseType,'reinforced') && stepsInPhase <= 0 && ~trialDetails.correct
                    % play wrong sound
                    playSoundSounds{end+1} = {'wrongSound', msPenaltySound};
                elseif strcmp(phaseType,'earlyPenalty') %&& stepsInPhase <= 0 what does stepsInPhase do? I don't think we need this for this phase
                    % play wrong sound
                    playSoundSounds{end+1} = {'wrongSound', msPenaltySound};
                end

            % freeDrinks setup
            % this will have to be fixed for passiveViewing (either as a flag on freeDrinks or as a new trialManager)
            elseif strcmp(trialManagerClass, 'freeDrinks') || strcmp(trialManagerClass, 'freeDrinksCenterOnly') || strcmp(trialManagerClass, 'freeDrinksSidesOnly') || strcmp(trialManagerClass, 'freeDrinksAlternate')
                if phase==1 && stepsInPhase <=0
                    playSoundSounds{end+1} = {'trialStartSound', 50};
                elseif ismember(phaseType,{'discrim','pre-response'}) && ~isempty(targetOptions) && any(ports(setdiff(1:length(ports), targetOptions))) % normal freeDrinks
                    % play white noise (when any port that is not a target is triggered)
                    playLoopSounds{end+1} = 'trySomethingElseSound';
                elseif ismember(phaseType,{'discrim','pre-response'}) && ~isempty(requestOptions) && any(ports(requestOptions)) % passiveViewing freeDrinks
                    % check that the requestMode and requestRewardDone also pass 
                    % same logic as in the request reward handling, but for sound
                    % play keepGoing sound?
                    if playRequestSoundLoop
                        playLoopSounds{end+1} = 'keepGoingSound';
                    end
                end
                % play correct/error sound
                if strcmp(phaseType,'reinforced') && stepsInPhase <= 0
                    if ~isempty(msRewardSound) && msRewardSound>0
                        playSoundSounds{end+1} = {'correctSound', msRewardSound};
                    elseif ~isempty(msPenaltySound) && msPenaltySound>0
                        playSoundSounds{end+1} = {'wrongSound', msPenaltySound};
                    end
                end
            elseif ismember(trialManagerClass, {'autopilot','reinforcedAutopilot'})
                % do nothing because we don't play any sounds in this case
                 if phase==1 && stepsInPhase <=0
                    playSoundSounds{end+1} = {'trialStartSound', 50};
                 end
            else
                trialManagerClass
                error('default getSoundsToPlay should only be for non-phased cases');
            end

            soundsToPlay = {playLoopSounds, playSoundSounds};

        end % end function
        
        function out=handleExtractDetailFieldsException(sm,ex,trialRecords)
            ex
            out=struct; %official way to bail
            if ismember(ex.identifier,{'MATLAB:catenate:structFieldBad'})
                warning('bailing: stimDeatils have varying field names')
            elseif ismember(ex.identifier,{'MATLAB:nonExistentField'})
                [trialRecords.stimDetails]
                warning('bailing: apparently fields missing from stimDetails')
            elseif ismember(ex.identifier,{'MATLAB:nonStrucReference'}) %this occurs if we are sent zero trials in the input when we try to look past the first struct level down (which doesn't exist) -- eg   [stimDetails.HFdetails]
                if length(trialRecords)~=0
                    size(trialRecords)
                    warning('bailing: got MATLAB:nonStrucReference even though there were trialRecords -- expect this only when trialRecords has length zero and we try to access nested structure fields that can''t be present in zero record structs')
                else
                    warning('you got a MATLAB:nonStrucReference (as expected) because trialRecords was empty -- should never happen because we never send empty trialRecords to extractDetailFields')
                end
            else
                rethrow(ex);
            end
        end
        
        function    [value]  = hasUpdatablePercentCorrectionTrial(sm)
            % returns false unless a stim subclass overrides it. Then can use
            % changeAllPercentCorrectionTrials

              value = false;
        end
        
        function [analysisdata cumulativedata] = physAnalysis(stimManager,spikeRecord,stimData,plotParameters,parameters,cumulativedata,eyeData,LFPRecord)
            % default function returns unchanged analysisdata
            warning('using default physAnalysis that does nothing');
            analysisdata=[];
        end % end function

        function [stimulus updateSM stimulusDetails]=postScreenResetCheckAndOrCache(stimulus,updateSM,stimulusDetails);
            %by default, this method does nothing.  some stims can check or cache
            %things
        end
        
        function [image details]= sampleStimFrame(stimManager,trialManagerClass,forceStimDetails,responsePorts,height,width)
            %returns a single image from calc stim movie

            if ~exist('trialManagerClass','var') || isempty(trialManagerClass)
                trialManagerClass='nAFC'
            end

            if ~exist('forceStimDetails','var') || isempty(forceStimDetails)
                doForce=0;
            else
                doForce=1;
            end

            if ~exist('responsePorts') || isempty(responsePorts)
                responsePorts=[3];
            end

            if ~exist('height') || isempty(height)
                height=getMaxHeight(stimManager);
            end

            if ~exist('width') || isempty(width)
                width=getMaxWidth(stimManager);
            end

                %defaults
                totalPorts=[3];
                trialRecords=[];
                %trialManagerClass = 'nAFC'
                frameRate = [];
                frame=1;
                displaySize=[]; % to fix 1/8/09
                LUTbits=[];     % to fix 1/8/09
                resolutions=[]; % to fix 1/8/09
                allowRepeats=1; % to fix 4/19/09
                % also note that this function doesn't actually use PTB - so why do the resInd stuff? - we really shouldnt

                if ~doForce
                    %basic calcstim
                       [stimulus,updateSM,resolutionIndex,preOnsetStim,preResponseStim,discrimStim,LUT,targetPorts,distractorPorts,details,interTrialLuminance,text,indexPulses]=...
                            calcStim(stimManager,trialManagerClass,allowRepeats,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords);
                else
                    if canForceStimDetails(stimManager,forceStimDetails)
                            [stimulus,updateSM,resolutionIndex,preOnsetStim,preResponseStim,discrimStim,LUT,targetPorts,distractorPorts,details,interTrialLuminance,text,indexPulses]=...
                            calcStim(stimManager,trialManagerClass,allowRepeats,resolutions,displaySize,LUTbits,responsePorts,totalPorts,trialRecords,forceStimDetails);
                    else
                        class(stimManager)
                        error('can''t force these stim details')
                    end
                end

            stimvideo=discrimStim.stimulus;
            image = reshape(stimvideo(:, :, frame), size(stimvideo,1), size(stimvideo,2));
        end
        
        function s=setMaxWidthAndHeight(s,width,height)
            if iswholenumber(width) && all(size(width)==1) && width>0
                s.maxWidth=width;
            else
                width
                error('bad width')
            end

            if iswholenumber(height) && all(size(height)==1) && height>0
                s.maxHeight=height;
            else
                height
                error('bad height')
            end
        end

        function out=stationOKForStimManager(stimManager,s)
            out=1;
    
        end % end function

        function retval = worthPhysAnalysis(sm,quality,analysisExists,overwriteAll,isLastChunkInTrial)
            % returns true if worth spike sorting given the values in the quality struct
            % default method for all stims - can be overriden for specific stims
            %
            % quality.passedQualityTest (from analysisManager's getFrameTimes)
            % quality.frameIndices
            % quality.frameTimes
            % quality.frameLengths (this was used by getFrameTimes to calculate passedQualityTest)

            if length(quality.passedQualityTest)>1 && ~enableChunkedPhysAnalysis(sm)
                %if many chunks, the last one might have no frames or spikes, but the
                %analysis should still complete if the the previous chunks are all
                %good. to be very thourough, a stim manager may wish to confirm that
                %the reason for last chunk failing, if it did, is an acceptable reason.
                qualityOK=all(quality.passedQualityTest(1:end-1));
                %&& size(quality.chunkIDForFrames,1)>0
            else
                %if there is only one, or you will try to analyze each chunk as you get it, then only check this one
                qualityOK=quality.passedQualityTest(end);
            end

            retval=qualityOK && ...
                (isLastChunkInTrial || enableChunkedPhysAnalysis(sm)) &&...    
                (overwriteAll || ~analysisExists);

            warning('setting retval to true');
            retval = true;

        end % end function

        
    end
    
end

