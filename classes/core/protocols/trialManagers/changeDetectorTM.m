classdef changeDetectorTM<trialManager
    
    properties
    end
    
    methods
        function t=changeDetectorTM(varargin)
            % CHANGEDETECTORTM  class constructor.
            % t=changeDetectorTM(soundManager,percentCatchTrials,rewardManager,
            %         [eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %		  [delayManager],[responseWindowMs],[showText])

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    a=trialManager();
                    t.percentCatchTrials=0;
                    

                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'changeDetectorTM'))
                        t = varargin{1};
                    else
                        error('Input argument is not a changeDetectorTM object')
                    end
                case {3 4 5 6 7 8 9 10 11 12}

                    % percentCorrectionTrials
                    if varargin{2}>=0 && varargin{2}<=1
                        t.percentCatchTrials=varargin{2};
                    else
                        error('1 >= percentCatchTrials >= 0')
                    end

                    d=sprintf(['n changeDetectorTM' ...
                        '\n\t\t\tpercentCatchTrials:\t%g'], ...
                        t.percentCatchTrials);

                    for i=4:12
                        if i <= nargin
                            args{i}=varargin{i};
                        else
                            args{i}=[];
                        end
                    end

                    % requestPorts
                    if isempty(args{8})
                        args{8}='center'; % ONLY changeDetectorTM requestPorts should be 'center'
                    elseif ~strcmp(args{8},'center')
                        requestPort=args{8};
                        error('changeDetectorTM requires a center requestPort');
                    end

                    a=trialManager(varargin{1},varargin{3},args{4},d,args{5},args{6},args{7},args{8},args{9},args{10},args{11},args{12});

                    

                otherwise
                    nargin
                    error('Wrong number of input arguments')
            end
        end
        
        function out = checkPorts(tm,targetPorts,distractorPorts)

            if isempty(targetPorts) && isempty(distractorPorts)
                error('targetPorts and distractorPorts cannot both be empty in nAFC');
            end

            out=true;

        end % end function
        
        function [stimSpecs, startingStimSpecInd] = createStimSpecsFromParams(trialManager,preRequestStim,preResponseStim,discrimStim,postDiscrimStim,...
    targetPorts,distractorPorts,requestPorts,interTrialLuminance,hz,indexPulses)
            %	INPUTS:
            %		trialManager - the trialManager object (contains the delayManager and responseWindow params)
            %		preRequestStim - a struct containing params for the preOnset phase
            %		preResponseStim - a struct containing params for the preResponse phase
            %		discrimStim - a struct containing params for the discrim phase
            %		targetPorts - the target ports for this trial
            %		distractorPorts - the distractor ports for this trial
            %		requestPorts - the request ports for this trial
            %		interTrialLuminance - the intertrial luminance for this trial (used for the 'final' phase, so we hold the itl during intertrial period)
            %		hz - the refresh rate of the current trial
            %		indexPulses - something to do w/ indexPulses, apparently only during discrim phases
            %	OUTPUTS:
            %		stimSpecs, startingStimSpecInd

            % there are two ways to have no pre-request/pre-response phase:
            %	1) have calcstim return empty preRequestStim/preResponseStim structs to pass to this function!
            %	2) the trialManager's delayManager/responseWindow params are set so that the responseWindow starts at 0
            %		- NOTE that this cannot affect the preOnset phase (if you dont want a preOnset, you have to pass an empty out of calcstim)

            % should the stimSpecs we return be dependent on the trialManager class? - i think so...because autopilot does not have reinforcement, but for now nAFC/freeDrinks are the same...

            % check for empty preRequestStim/preResponseStim and compare to values in trialManager.delayManager/responseWindow
            % if not compatible, ERROR
            % nAFC should not be allowed to have an empty preRequestStim (but freeDrinks can)
            if isempty(preRequestStim) && strcmp(class(trialManager),'changeDetectorTM')
                error('changeDetectorTM cannot have an empty preRequestStim'); % i suppose we could default to the ITL here, but really shouldnt
            end
            responseWindowMs=getResponseWindowMs(trialManager);
            if isempty(preResponseStim) && responseWindowMs(1)~=0
                error('cannot have nonzero start of responseWindow with no preResponseStim');
            end

            % get an optional autorequest from the delayManager
            dm = getDelayManager(trialManager);
            if ~isempty(dm)
                framesUntilOnset=floor(calcAutoRequest(dm)*hz/1000); % autorequest is in ms, convert to frames
            else
                framesUntilOnset=[]; % only if request port is triggered
            end
            % get responseWindow
            responseWindow=floor(responseWindowMs*hz/1000); % can you floor inf?

            % now generate our stimSpecs
            startingStimSpecInd=1;
            i=1;
            addedPreResponsePhase=0;
            addedPostDiscrimPhase=0;
            addedDiscrimPhase = 0;

            if ~isempty(preResponseStim) && responseWindow(1)~=0
                addedPreResponsePhase=addedPreResponsePhase+1;
            end

            if ~isempty(postDiscrimStim)
                addedPostDiscrimPhase=addedPostDiscrimPhase+1;
            end

            if ~isempty(discrimStim)
                addedDiscrimPhase=addedDiscrimPhase+1;
            end


            % optional preOnset phase
            if ~isempty(preRequestStim) % only some classes have the pre-request phase if no delayManager in 'nAFC' class
                if preRequestStim.punishResponses
                    criterion={[],i+1,requestPorts,i+1,[targetPorts distractorPorts],i+1+addedPreResponsePhase};  %was:i+2+addedPhases ;  i+1+addedPreResponsePhase? or i+2+addedPreResponsePhase?
                else
                    criterion={[],i+1,requestPorts,i+1};
                end
                stimSpecs{i} = stimSpec(preRequestStim.stimulus,criterion,preRequestStim.stimType,preRequestStim.startFrame,...
                    framesUntilOnset,preRequestStim.autoTrigger,preRequestStim.scaleFactor,0,hz,'pre-request','pre-request',preRequestStim.punishResponses,false);
                i=i+1;
                if isempty(requestPorts) && isempty(framesUntilOnset)
                    error('cannot have empty requestPorts with no auto-request!');
                end
            end

            % required preResponse phase
            if isempty(preResponseStim)
                error('cannot have changeDetectorTM and have empty preResponseStim');
            end
            if ~preResponseStim.punishResponses
                error('changeDetectorTM forces punishResponses in preResponsePhase');
            end
            if ~isscalar(preResponseStim.framesUntilTimeout)
                error('preResponseStim should timeout at some point in time');
            end
            criterion={[],i+1,[targetPorts distractorPorts],i+2+addedPostDiscrimPhase}; % balaji was i+2 earlier but added postDiscrimPhase
            stimSpecs{i} = stimSpec(preResponseStim.stimulus,criterion,preResponseStim.stimType,preResponseStim.startFrame,...
                preResponseStim.framesUntilTimeout,preResponseStim.autoTrigger,preResponseStim.scaleFactor,0,hz,'pre-response','pre-response',preResponseStim.punishResponses,false);
            i=i+1;

            % for changeDetectorTM, discrim stim may be optional (for catch
            % trials)

            criterion={[],i+1,[targetPorts distractorPorts],i+1+addedPostDiscrimPhase};
            if isinf(responseWindow(2))
                framesUntilTimeout=[];
            else
                framesUntilTimeout=responseWindow(2);
            end
            if isfield(discrimStim,'framesUntilTimeout') && ~isempty(discrimStim.framesUntilTimeout)
                if ~isempty(framesUntilTimeout)
                    error('had a finite responseWindow but also defined framesUntilTimeout in discrimStim - CANNOT USE BOTH!');
                else
                    framesUntilTimeout=discrimStim.framesUntilTimeout;
                end
            end

            stimSpecs{i} = stimSpec(discrimStim.stimulus,criterion,discrimStim.stimType,discrimStim.startFrame,...
                framesUntilTimeout,discrimStim.autoTrigger,discrimStim.scaleFactor,0,hz,'discrim','discrim',false,true,indexPulses); % do not punish responses here
            i=i+1;

            % optional postDiscrim Phase
            if ~isempty(postDiscrimStim) % currently just check for existence. lets figure out a more complicated set of requirements later
                % criterion is the similar as for discrim
                criterion={[],i+1,[targetPorts distractorPorts],i+1};

                % cannot punish responses in postDiscrimStim
                if postDiscrimStim.punishResponses
                    error('cannot punish responses in postDiscrimStim');
                end
                if isfield(postDiscrimStim,'framesUntilTimeOut') && ~isempty(postDiscrimStim.framesUntilTimeout)
                    if ~isinf(framesUntilTimeout)
                        framesUntilTimeoutPostDiscrim = postDiscrim.framesUntilTimeout;
                    else
                        error('cannot both specify a discrim noninf frames until timeout and a postDiscrimPhase')
                    end
                else
                    framesUntilTimeoutPostDiscrim = inf; % asume that the framesuntiltimeout is inf
                end
                stimSpecs{i} = stimSpec(postDiscrimStim.stimulus,criterion,postDiscrimStim.stimType,postDiscrimStim.startFrame,...
                    framesUntilTimeoutPostDiscrim,postDiscrimStim.autoTrigger,postDiscrimStim.scaleFactor,0,hz,'post-discrim','post-discrim',postDiscrimStim.punishResponses,false);
                i=i+1;
            end


            % required reinforcement phase
            criterion={[],i+1};
            stimSpecs{i} = stimSpec([],criterion,'cache',0,[],[],0,0,hz,'reinforced','reinforcement',false,false); % do not punish responses here
            i=i+1;
            % required final ITL phase
            criterion={[],i+1};
            stimSpecs{i} = stimSpec(interTrialLuminance,criterion,'cache',0,1,[],0,1,hz,'itl','intertrial luminance',false,false); % do not punish responses here
            i=i+1;

        end
        
        function out = getPercentCatchTrials(tm)
            out = tm.percentCatchTrials;
        end
        
        
        function out=getRequestRewardSizeULorMS(trialManager)

            out=trialManager.requestRewardSizeULorMS;
        end
        
        function out=getResponsePorts(trialManager,totalPorts)

            out=setdiff(1:totalPorts,getRequestPorts(trialManager,totalPorts)); % old: response ports are all non-request ports
            % 5/4/09 - what if we want nAFC L/R target/distractor, but no request port (using delayManager instead)
            % responsePorts then still needs to only be L/R, not all ports (since request ports is empty)

            enableCenterPortResponseWhenNoRequestPort=false; %nAFC removes the center port
            if ~enableCenterPortResponseWhenNoRequestPort
                if isempty(getRequestPorts(trialManager,totalPorts)) % removes center port if no requestPort defined
                    out(ceil(length(out)/2))=[];
                end
            end
        end
        
        function out=stationOKForTrialManager(t,s)
            if isa(s,'station')
                out = getNumPorts(s)>=3;
            else
                error('need a station object')
            end
        end
        
        function [tm trialDetails result spec rewardSizeULorMS requestRewardSizeULorMS ...
    msPuff msRewardSound msPenalty msPenaltySound floatprecision textures destRect, updateRM] = ...
    updateTrialState(tm, sm, result, spec, ports, lastPorts, ...
    targetPorts, requestPorts, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
    floatprecision, textures, destRect, ...
    requestRewardDone, punishResponses,compiledRecords,subject)
            % This function is a tm-specific method to update trial state before every flip.
            % Things done here include:
            %   - set trialRecords.correct and trialRecords.result as necessary
            %   - call RM's calcReinforcement as necessary
            %   - update the stimSpec as necessary (with correctStim() and errorStim())
            %   - update the TM's RM if neceesary
            updateRM = false;
            rewardSizeULorMS=0;
            msPuff=0;
            msRewardSound=0;
            msPenalty=0;
            msPenaltySound=0;

            if isfield(trialRecords(end),'trialDetails') && isfield(trialRecords(end).trialDetails,'correct')
                correct=trialRecords(end).trialDetails.correct;
            else
                correct=[];
            end

            % ========================================================
            % if the result is a port vector, and we have not yet assigned correct, then the current result must be the trial response
            % because phased trial logic returns the 'result' from previous phase only if it matches a target/distractor
            % 3/13/09 - we rely on nAFC's phaseify to correctly assign stimSpec.phaseLabel to identify where to check for correctness
            % call parent's updateTrialState() to do the request reward handling and check for 'timeout' flag
            [tm.trialManager possibleTimeout result garbage garbage requestRewardSizeULorMS, updateRM1] = ...
                updateTrialState(tm.trialManager, sm, result, spec, ports, lastPorts, ...
                targetPorts, requestPorts, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
                floatprecision, textures, destRect, ...
                requestRewardDone, punishResponses,compiledRecords,subject);
            if isempty(possibleTimeout)		
                if ~isempty(result) && ~ischar(result) && isempty(correct) && strcmp(getPhaseLabel(spec),'reinforcement')
                    resp=find(result);
                    if length(resp)==1
                        correct = ismember(resp,targetPorts);
                        if punishResponses % this means we got a response, but we want to punish, not reward
                            correct=0; % we could only get here if we got a response (not by request or anything else), so it should always be correct=0
                        end
                        result = 'nominal';
                    else
                        correct = 0;
                        result = 'multiple ports';
                    end
                end
            else
                correct=possibleTimeout.correct;
            end

            % ========================================================
            phaseType = getPhaseType(spec);
            framesUntilTransition=getFramesUntilTransition(spec);
            % now, if phaseType is 'reinforced', use correct and call updateRewards(tm,correct)
            % this trialManager-specific method should do the following:
            % - call calcReinforcement(RM)
            % - update msRewardOwed/msAirpuffOwed as necessary (depending on correctness and TM class)
            % - call errorStim(SM), correctStim(SM) as necessary and fill in the stimSpec's stimulus field
            updateRM2 = false;
            if ~isempty(phaseType) && strcmp(phaseType,'reinforced') && ~isempty(correct) && framesInPhase==0
                % we only check to do rewards on the first frame of the 'reinforced' phase
                [rm,rewardSizeULorMS, garbage, msPenalty, msPuff, msRewardSound, msPenaltySound, updateRM2] =...
                    calcReinforcement(getReinforcementManager(tm),trialRecords,compiledRecords, []);
                if updateRM2
                    tm=setReinforcementManager(tm,rm);
                end

                if correct
                    msPuff=0;
                    msPenalty=0;
                    msPenaltySound=0;

                    if window>0
                        if isempty(framesUntilTransition)
                            framesUntilTransition = ceil((rewardSizeULorMS/1000)/ifi);
                        end
                        numCorrectFrames=ceil((rewardSizeULorMS/1000)/ifi);

                    elseif strcmp(getDisplayMethod(tm),'LED')
                        if isempty(framesUntilTransition)
                            framesUntilTransition=ceil(getHz(spec)*rewardSizeULorMS/1000);
                        else
                            framesUntilTransition
                            error('LED needs framesUntilTransition empty for reward')
                        end
                        numCorrectFrames=ceil(getHz(spec)*rewardSizeULorMS/1000);
                    else
                        error('huh?')
                    end
                    spec=setFramesUntilTransition(spec,framesUntilTransition);
                    [cStim correctScale] = correctStim(sm,numCorrectFrames);
                    spec=setScaleFactor(spec,correctScale);
                    strategy='noCache';
                    if window>0
                        [floatprecision cStim] = determineColorPrecision(tm, cStim, strategy);
                        textures = cacheTextures(tm,strategy,cStim,window,floatprecision);
                        destRect = determineDestRect(tm, window, station, correctScale, cStim, strategy);
                    elseif strcmp(getDisplayMethod(tm),'LED')
                        floatprecision=[];
                    else
                        error('huh?')
                    end
                    spec=setStim(spec,cStim);
                else
                    rewardSizeULorMS=0;
                    msRewardSound=0;
                    msPuff=0; % for now, we don't want airpuffs to be automatic punishment, right?

                    if window>0
                        if isempty(framesUntilTransition)
                            framesUntilTransition = ceil((msPenalty/1000)/ifi);
                        end
                        numErrorFrames=ceil((msPenalty/1000)/ifi);

                    elseif strcmp(getDisplayMethod(tm),'LED')
                        if isempty(framesUntilTransition)
                            framesUntilTransition=ceil(getHz(spec)*msPenalty/1000);
                        else
                            framesUntilTransition
                            error('LED needs framesUntilTransition empty for reward')
                        end
                        numErrorFrames=ceil(getHz(spec)*msPenalty/1000);
                    else
                        error('huh?')
                    end
                    spec=setFramesUntilTransition(spec,framesUntilTransition);
                    [eStim errorScale] = errorStim(sm,numErrorFrames);
                    spec=setScaleFactor(spec,errorScale);
                    strategy='noCache';
                    if window>0
                        [floatprecision eStim] = determineColorPrecision(tm, eStim, strategy);
                        textures = cacheTextures(tm,strategy,eStim,window,floatprecision);
                        destRect=Screen('Rect',window);
                    elseif strcmp(getDisplayMethod(tm),'LED')
                        floatprecision=[];
                    else
                        error('huh?')
                    end
                    spec=setStim(spec,eStim);
                end

            end % end reward handling

            trialDetails.correct=correct;
            updateRM = updateRM1 || updateRM2;


        end  % end function


        
    end
    
end

