classdef reinforcedAutopilot
    
    properties
        percentCorrectionTrials=0;
    end
    
    methods
        function t=reinforcedAutopilot(varargin)
            % REINFORCEDAUTOPILOT  class constructor.
            % t=reinforcedAutopilot(percentCorrectionTrials,soundManager,...
            %      rewardManager,[eyeController],[frameDropCorner],[dropFrames],[displayMethod],[requestPorts],[saveDetailedFramedrops],
            %	   [delayManager],[responseWindowMs],[showText])
            %
            % Used for the whiteNoise, bipartiteField, fullField, and gratings stims, which don't require any response to go through the trial
            % basically just play through the stims, with no sounds, no correction trials

            switch nargin
                case 0
                    % if no input arguments, create a default object

                    a=trialManager();
                    t = class(t,'reinforcedAutopilot',a);

                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'reinforcedAutopilot'))
                        t = varargin{1};
                    else
                        error('Input argument is not a reinforcedAutopilot object')
                    end
                case {3 4 5 6 7 8 9 10 11 12}
                    % percentCorrectionTrials
                    if varargin{1}>=0 && varargin{1}<=1
                        t.percentCorrectionTrials=varargin{1};
                    else
                        error('1 >= percentCorrectionTrials >= 0')
                    end

                    d=sprintf('reinforcedAutopilot');


                    for i=4:12
                        if i <= nargin
                            args{i}=varargin{i};
                        else
                            args{i}=[];
                        end
                    end

                    % requestPorts
                    if isempty(args{8})
                        args{8}='none'; % default autopilot requestPorts should be 'none'
                    end

                    a=trialManager(varargin{2},varargin{3},args{4},d,args{5},args{6},args{7},args{8},args{9},args{10},args{11},args{12});

                    t = class(t,'reinforcedAutopilot',a);

                otherwise
                    nargin
                    error('Wrong number of input arguments')
            end
        end
        
        function rewardValves = forceRewards(tm,rewardValves)
            %forceRewards only sets if the valves are set to [0 0 0]

            if ~any(rewardValves)
                rewardValves = [0 1 0];
            end

        end
        
        function out = getPercentCorrectionTrials(tm)
            out = tm.percentCorrectionTrials;
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
        
        function [tm, trialDetails, result, spec, rewardSizeULorMS, requestRewardSizeULorMS, ...
    msPuff, msRewardSound, msPenalty, msPenaltySound, floatprecision, textures, destRect,updateRM] = ...
    updateTrialState(tm, sm, result, spec, ports, lastPorts, ...
    targetPorts, requestPorts, lastRequestPorts, framesInPhase, trialRecords, window, station, ifi, ...
    floatprecision, textures, destRect, ...
    requestRewardDone, punishResponses,compiledRecords,subject)

            rewardSizeULorMS=0;
            requestRewardSizeULorMS = 0;
            msPuff=0;
            msRewardSound=0;
            msPenalty=0;
            msPenaltySound=0;
            updateRM = false;
            phaseType = getPhaseType(spec);
            framesUntilTransition=getFramesUntilTransition(spec);
            % now, if phaseType is 'reinforced', use correct and call updateRewards(tm,correct)
            % this trialManager-specific method should do the following:
            % - call calcReinforcement(RM)
            % - update msRewardOwed/msAirpuffOwed as necessary (depending on correctness and TM class)
            % - call errorStim(SM), correctStim(SM) as necessary and fill in the stimSpec's stimulus field

            if ~isempty(phaseType) && strcmp(phaseType,'reinforced') && framesInPhase==0
                % we only check to do rewards on the first frame of the 'reinforced' phase
                [rm, rewardSizeULorMS, ~, msPenalty, ~, msRewardSound, msPenaltySound, updateRM] =...
                    calcReinforcement(getReinforcementManager(tm),trialRecords,compiledRecords, []);
                if updateRM
                    tm=setReinforcementManager(tm,rm);
                end

                msPuff=0;
                msPenalty=0;
                msPenaltySound=0;

                if window>0
                    if isempty(framesUntilTransition)
                        framesUntilTransition = ceil((rewardSizeULorMS/1000)/ifi);
                    end
                    numCorrectFrames=ceil((rewardSizeULorMS/1000)/ifi);
                    if framesUntilTransition == 0
                        framesUntilTransition = 1; % preset this because 0 implied infinity
                    end
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
                [cStim, correctScale] = correctStim(sm,numCorrectFrames);
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


            end % end reward handling

            if strcmp(getPhaseLabel(spec),'intertrial luminance') && ischar(result) && strcmp(result,'timeout')
                % this should be the only allowable result in autopilot
                result='timedout'; % so we continue to next trial
            end

            trialDetails.correct=true;

            end  % end function
        
    end
    
end

