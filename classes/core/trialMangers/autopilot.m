classdef autopilot <trialManager
    properties
        % nothing new defined here
    end
    
    methods
        function a = autopilot(varargin)
            switch nargin
                case 0
                    argin{1} = soundManager();
                    argin{2} = reinforcementManager();
                    argin{3} = delayManager();
                    argin{4} = false;
                    argin{5} = false;
                    argin{6} = 'center';
                    argin{7} = false;
                    argin{8} = false;
                    argin{9} = false;
                case 9
                    argin{1} = varargin{1};
                    argin{2} = varargin{2};
                    argin{3} = varargin{3};
                    argin{4} = varargin{4};
                    argin{5} = varargin{5};
                    argin{6} = varargin{6};
                    argin{7} = varargin{7};
                    argin{8} = varargin{8};
                    argin{9} = varargin{9};
            end
            a = a@trialManager(argin);
        end
        
        function out=stationOKForTrialManager(~,s)
            validateattributes(s,{'station'},{'nonempty'})
            out = getNumPorts(s)>=3;
        end
        
        function [tm, trialDetails, result, spec, rewardSizeULorMS, requestRewardSizeULorMS, ...
                msPuff, msRewardSound, msPenalty, msPenaltySound, floatprecision, textures, destRect] = ...
                updateTrialState(tm, ~, result, spec, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, floatprecision, ...
                textures, destRect, ~, ~)
            % autopilot updateTrialState does nothing!
            
            rewardSizeULorMS=0;
            requestRewardSizeULorMS=0;
            msPuff=0;
            msRewardSound=0;
            msPenalty=0;
            msPenaltySound=0;
            
            trialDetails=[];
            if strcmp(getPhaseLabel(spec),'intertrial luminance') && ischar(result) && strcmp(result,'timeout')
                % this should be the only allowable result in autopilot
                result='timedout'; % so we continue to next trial
            end
        end
        
        function [stimSpecs startingStimSpecInd] = createStimSpecsFromParams(trialManager,preRequestStim,...
                preResponseStim,discrimStim,postDiscrimStim,interTrialStim,...
                targetPorts,distractorPorts,requestPorts,interTrialLuminance,...
                hz,indexPulses)
            responseWindowMs=getResponseWindowMs(trialManager);
            dm = getDelayManager(trialManager);
            if ~isempty(dm)
                framesUntilOnset=floor(calcAutoRequest(dm)*hz/1000); % autorequest is in ms, convert to frames
            else
                framesUntilOnset=[]; % only if request port is triggered
            end
            % get responseWindow
            responseWindow=floor(responseWindowMs*hz/1000); % can you floor inf?
            
            startingStimSpecInd=1;
            i=1;

            % do autopilot stuff..
            % required discrim phase
            criterion={[],i+1,[targetPorts distractorPorts],i+1};
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
                framesUntilTimeout,discrimStim.autoTrigger,discrimStim.scaleFactor,0,hz,'discrim','discrim',false,true,indexPulses,[],discrimStim.ledON); % do not punish responses here
            i=i+1;
            % required final ITL phase
            criterion={[],i+1};
            stimSpecs{i} = stimSpec(interTrialLuminance,criterion,'cache',0,interTrialStim.duration,[],0,1,hz,'itl','intertrial luminance',false,false,[],false); % do not punish responses here
            i=i+1;
            
            
        end
    end
    
end