classdef goNoGo<trialManager
    
    properties
        percentCorrectionTrials=0;
        responseLockoutMs=[];
    end
    
    methods
        function t=goNoGo(varargin)
            % goNoGo  class constructor.
            % t=goNoGo(soundManager,percentCorrectionTrials,responseLockoutMs,rewardManager,
            %         [eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %		  [delayFunction],[responseWindowMs],[showText])

            switch nargin
                case 0
                    % if no input arguments, create a default object
                    a=trialManager();
                    

                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'goNoGo'))
                        t = varargin{1};
                    else
                        error('Input argument is not a goNoGo object')
                    end
                case {4 5 6 7 8 9 10 11 12 13}

                    % percentCorrectionTrials
                    if varargin{2}>=0 && varargin{2}<=1
                        t.percentCorrectionTrials=varargin{2};
                    else
                        error('1 >= percentCorrectionTrials >= 0')
                    end

                     if t.percentCorrectionTrials~=0
                        t.percentCorrectionTrials
                        error('you probably don''t want correction trials on goNoGo')
                    end

                    if isscalar(varargin{3}) && varargin{3}>=0
                        t.responseLockoutMs=varargin{3};
                    elseif isempty(varargin{3})
                        t.responseLockoutMs=[];
                    else
                        error('responseLockoutMs must be a real scalar or empty');
                    end

                    d=sprintf(['goNoGo' ...
                        '\n\t\t\tpercentCorrectionTrials:\t%g'], ...
                        t.percentCorrectionTrials);

                    for i=5:13
                        if i <= nargin
                            args{i}=varargin{i};
                        else
                            args{i}=[];
                        end
                    end

                    % requestPorts
                    if isempty(args{9})
                        args{9}='none'; % default goNoGo requestPorts should be 'none' (all ports are targetPorts?)
                    end

                    a=trialManager(varargin{1},varargin{4},args{5},d,args{6},args{7},args{8},args{9},args{10},args{11},args{12},args{13});

                    

                otherwise
                    nargin
                    error('Wrong number of input arguments')
            end
        end
        
        function out = getPercentCorrectionTrials(tm)
            out = tm.percentCorrectionTrials;
        end
        
        function out=getRequestRewardSizeULorMS(trialManager)

            out=trialManager.requestRewardSizeULorMS;
        end

        function out = getResponseLockoutMs(tm)
            out=tm.responseLockoutMs;
        end

        function out=getResponsePorts(trialManager,totalPorts)

            out=setdiff(1:totalPorts,getRequestPorts(trialManager,totalPorts));
        end
        
        function out=stationOKForTrialManager(t,s)
            if isa(s,'station')
                out = getNumPorts(s)>=3;
            else
                error('need a station object')
            end
        end
        
        function [tm trialDetails result spec rewardSizeULorMS requestRewardSizeULorMS ...
    msPuff msRewardSound msPenalty msPenaltySound floatprecision textures destRect,updateRM] = ...
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

            rewardSizeULorMS=0;
            msPuff=0;
            msRewardSound=0;
            msPenalty=0;
            msPenaltySound=0;
            updateRM = false;

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
            updateRM2=false;
            if ~isempty(phaseType) && strcmp(phaseType,'reinforced') && ~isempty(correct) && framesInPhase==0
                % we only check to do rewards on the first frame of the 'reinforced' phase
                [rm rewardSizeULorMS garbage msPenalty msPuff msRewardSound msPenaltySound updateRM2] =...
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

            trialDetails
            struct(spec)

        end  % end function
        
    end
    
end

