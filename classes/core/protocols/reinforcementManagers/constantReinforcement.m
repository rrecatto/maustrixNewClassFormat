classdef constantReinforcement
    
    properties
        rewardSizeULorMS=0;
    end
    
    methods
        function r=constantReinforcement(varargin)
            % ||constantReinforcement||  class constructor.
            % r=constantReinforcement(rewardSizeULorMS,requestRewardSizeULorMS,requestMode,...
            %   msPenalty,fractionOpenTimeSoundIsOn,fractionPenaltySoundIsOn,scalar,msPuff)
            switch nargin
                case 0
                    % if no input arguments, create a default object


                    r = class(r,'constantReinforcement',reinforcementManager());
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'constantReinforcement'))
                        r = varargin{1};
                    else
                        error('Input argument is not a constantReinforcement object')
                    end
                case 8
                    r = class(r,'constantReinforcement',...
                        reinforcementManager(varargin{4},varargin{8},varargin{7},varargin{5},varargin{6},varargin{2},varargin{3}));
                    r = setRewardSizeULorMS(r,varargin{1});
                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function [r, rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound, updateRM] = ...
    calcReinforcement(r,trialRecords,compiledRecord, subject)

            [rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound] = ...
                calcCommonValues(r,r.rewardSizeULorMS,getRequestRewardSizeULorMS(r));

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

