classdef freeDrinks
    
    properties
        freeDrinkLikelihood=0;
        allowRepeats=false;
    end
    
    methods
        function t=freeDrinks(varargin)
            % FREEDRINKS  class constructor.
            % t=freeDrinks(soundManager,freeDrinkLikelihood,allowRepeats,reinforcementManager, 
            %   [eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %	[delayManager],[responseWindowMs],[showText])

            switch nargin
                case 0
                    % if no input arguments, create a default object

                    
                    a=trialManager();
                    t = class(t,'freeDrinks',a);
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'freeDrinks'))
                        t = varargin{1};
                    else
                        error('Input argument is not a freeDrinks object')
                    end
                case {4 5 6 7 8 9 10 11 12 13}

                    % freeDrinkLikelihood
                    if varargin{2}>=0
                        t.freeDrinkLikelihood=varargin{2};
                    else
                        error('freeDrinkLikelihood must be >= 0')
                    end
                    % allowRepeats
                    if islogical(varargin{3})
                        t.allowRepeats=varargin{3};
                    else
                        error('allowRepeats must be logical');
                    end

                    d=sprintf('free drinks\n\t\t\tfreeDrinkLikelihood: %g',t.freeDrinkLikelihood);


                    for i=5:13
                        if i <= nargin
                            args{i}=varargin{i};
                        else
                            args{i}=[];
                        end
                    end

                    % requestPorts
                    if isempty(args{9})
                        args{9}='none'; % default freeDrinks requestPorts should be 'none'
                    end

                    a=trialManager(varargin{1},varargin{4},args{5},d,args{6},args{7},args{8},args{9},args{10},args{11},args{12},args{13});

                    t = class(t,'freeDrinks',a);
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function out = checkPorts(tm,targetPorts,distractorPorts)

            if isempty(targetPorts) && ~isempty(distractorPorts)
                error('cannot have distractor ports without target ports in freeDrinks');
            end

            out=true;

        end % end function
        
        function out=getAllowRepeats(tm)
            out=tm.allowRepeats;
        end
        
        function out = getFreeDrinkLikelihood( tm )
            out=tm.freeDrinkLikelihood;
        end
        
        function out = getPctStochasticReward(tm)
            out=tm.pctStochasticReward;
        end
        
        function out=getResponsePorts(trialManager,totalPorts)

            out=setdiff(1:totalPorts,getRequestPorts(trialManager,totalPorts));
        end
        
        function out=stationOKForTrialManager(t,s)
            if isa(s,'station')
                out = getNumPorts(s)>=2;
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
            requestRewardSizeULorMS=0;
            msPuff=0;
            msRewardSound=0;
            msPenalty=0;
            msPenaltySound=0;
            updateRM = false;
            % ========================================================
            % if the result is a port vector, and we have not yet assigned correct, then the current result must be the trial response
            % because phased trial logic returns the 'result' from previous phase only if it matches a target/distractor
            % call parent's updateTrialState() to do the request reward handling and check for 'timeout' flag
            [tm.trialManager possibleTimeout result garbage garbage requestRewardSizeULorMS, updateRM1] = ...
                updateTrialState(tm.trialManager, sm, result, spec, ports, lastPorts, ...
                targetPorts, requestPorts, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
                floatprecision, textures, destRect, ...
                requestRewardDone,punishResponses,compiledRecords,subject);
            if ~isempty(result) && ~ischar(result)
                resp=find(result);
                if length(resp)==1
                    result = 'nominal';
                    correct=1;
                    if punishResponses
                        correct=0;
                    end
                else
                    correct=0;
                    result = 'multiple ports';
                end
                trialDetails.correct=correct;
            elseif ischar(result) && ismember(result,{'timedout','multiple ports'})
                correct=0;
                trialDetails.correct=correct;
            elseif ischar(result) && ismember(result,{'nominal'})
                correct=1;
                trialDetails.correct=correct;
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
            if ~isempty(phaseType) && strcmp(phaseType,'reinforced') && framesInPhase==0
                % we only check to do rewards on the first frame of the 'reinforced' phase
                [rm rewardSizeULorMS garbage msPenalty msPuff msRewardSound msPenaltySound updateRM2 ]=...
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

                elseif ~correct
                    % this only happens when multiple ports are triggered
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

            updateRM = updateRM1 || updateRM2;


            trialDetails=[];
        end  % end function

        
        
    end
    
end

