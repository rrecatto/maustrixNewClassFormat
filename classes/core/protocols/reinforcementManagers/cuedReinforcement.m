classdef cuedReinforcement<reinforcementManager

    properties
        rewardSizeULorMS=0;
    end
    
    methods
        function r=cuedReinforcement(varargin)
            % ||constantReinforcement||  class constructor.
            % r=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,...
            %   msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msPuff)

            switch nargin
                case 0
                    % if no input arguments, create a default object


                    
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'cuedReinforcement'))
                        r = varargin{1};
                    else
                        error('Input argument is not a cuedReinforcement object')
                    end
                case 8
                    
            %         r = setRewardSizeULorMS(r,varargin{1}); % not needed b/c we never look at this value! - stim manager cuedCoherentDots
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function [r rewardSizeULorMS requestRewardSizeULorMS msPenalty msPuff msRewardSound msPenaltySound updateRM] = ...
    calcReinforcement(r,trialRecords,compiledRecord, subject)
            verbose=0;

            reward = trialRecords(end).stimDetails.selectedTrialValue;

            [rewardSizeULorMS requestRewardSizeULorMS msPenalty msPuff msRewardSound msPenaltySound] = ...
                calcCommonValues(r,reward,getRequestRewardSizeULorMS(r));

            updateRM=0;
        end
        
        function d=display(r)
            d=[sprintf('\n\t\t\trewardSizeULorMS:\t\t%3.3g',r.rewardSizeULorMS) ...
               ];

           %add on the superclass 
            d=[d sprintf('\n\t\treinforcementManager:\t') display(r.reinforcementManager)];
        end
        
        
        function r=setRewardSizeULorMS(r, v)
            if v>=0 && isreal(v) && isscalar(v) && isnumeric(v)
                r.rewardSizeULorMS=v;
            else
                error('rewardSizeULorMS must be real numeric scalar >=0')
            end
        end
        
        function d=shortDisp(r)
            d=sprintf('reward: %g\tpenalty: %g',r.rewardSizeULorMS, r.msPenalty);
        end
        
        
    end
    
end

