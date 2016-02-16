classdef probabilisticConstantReinforcement
    
    properties
        rewardSizeULorMS=0;
        rewardProbability = 0;
    end
    
    methods
        function r=probabilisticConstantReinforcement(varargin)
            % ||constantReinforcement||  class constructor.
            % r=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,...
            %   msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msPuff)
            switch nargin
                case 0
                    % if no input arguments, create a default object


                    r = class(r,'probabilisticConstantReinforcement',reinforcementManager());
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'probabilisticConstantReinforcement'))
                        r = varargin{1};
                    else
                        error('Input argument is not a probabilisticConstantReinforcement object')
                    end
                case 9
                    r = class(r,'probabilisticConstantReinforcement',...
                        reinforcementManager(varargin{5},varargin{9},varargin{8},varargin{6},varargin{7},varargin{3},varargin{4}));
                    r = setRewardSizeULorMSAndRewardProbability(r,varargin{1},varargin{2});
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function [r, rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound, updateRM] = ...
    calcReinforcement(r,trialRecords,compiledRecord, subject)

            [rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound] = ...
                calcCommonValues(r,r.rewardSizeULorMS,getRequestRewardSizeULorMS(r));
            rewardSizeULorMS = rewardSizeULorMS*double(rand<r.rewardProbability);
            updateRM=0;
        end
        
        function d=display(r)
            d=[sprintf('\n\t\t\trewardSizeULorMS:\t%3.3g\trewardProbabaility:\t%3.3g',r.rewardSizeULorMS, r.rewardProbability) ...
               ];

           %add on the superclass 
            d=[d sprintf('\n\t\treinforcementManager:\t') display(r.reinforcementManager)];
        end
        
        
        function r=setRewardSizeULorMSAndRewardProbability(r, v, p)

            if v>=0 && isreal(v) && isscalar(v) && isnumeric(v)
                r.rewardSizeULorMS=v;
            else
                error('rewardSizeULorMS must be real numeric scalar >=0')
            end

            if isscalar(p) && p>=0 && p<=1
                r.rewardProbability = p;
            else
                error('reward probability should be a scalar between 0 and 1');
            end
        end
        
        function d=shortDisp(r)
            d=sprintf('reward: %g\tpenalty: %g',r.rewardSizeULorMS, r.msPenalty);
        end
        
        
    end
    
end

