classdef reinforcementManager
    
    properties
        msPenalty=0;
        fractionOpenTimeSoundIsOn=0;
        fractionPenaltySoundIsOn=0;
        scalar=1;
        msPuff=0;
        requestRewardSizeULorMS=0;
        requestMode='first'; % 'first','nonrepeats', or 'all'
    end
    
    methods
        function r=reinforcementManager(varargin)
            % REINFORCEMENTMANAGER  class constructor.  ABSTRACT CLASS-- DO NOT INSTANTIATE
            % r=rewardManager(msPenalty, msPuff, scalar, fractionOpenTimeSoundIsOn, fractionPenaltySoundIsOn, requestRewardSizeULorMS, requestMode)
            %
            % msPenalty - duration of the penalty
            % fractionOpenTimeSoundIsOn - fraction of reward during which sound is played
            % fractionPenaltySoundIsOn - fraction of penalty during which sound is played
            % scalar - reinforcement duration/size multiplier
            % msPuff - duration of the airpuff
            % requestRewardSizeULorMS - duration/size of the request reward
            % requestMode - one of the strings {'first', 'nonrepeats', 'all'} that specifies which requests should be rewarded within a trial
            %       'first' means only the first request is rewarded; 'nonrepeats' means all requests that are not same as previous request are rewarded
            %       'all' means all requests are rewarded
            switch nargin
                case 0
                    % if no input arguments, create a default obj
                case 1
                    % if single argument of this class type, return it
                    if (isa(varargin{1},'reinforcementManager'))
                        r = varargin{1};
                    else
                        error('Input argument is not a reinforcementManager object')
                    end
                case 7
                    r.msPenalty=varargin{1};
                    r.msPuff=varargin{2};
                    r.scalar=varargin{3};
                    r.fractionOpenTimeSoundIsOn=varargin{4};
                    r.fractionPenaltySoundIsOn=varargin{5};
                    r.requestRewardSizeULorMS=varargin{6};
                    r.requestMode=varargin{7};

                    if r.msPenalty>=0 && isreal(r.msPenalty) && isscalar(r.msPenalty)
                        %pass
                    else
                        error('msPenalty must a single real number be >=0')
                    end

                    if isreal(r.msPuff) && isscalar(r.msPuff) && r.msPuff>=0 && r.msPuff<=r.msPenalty
                        %pass
                    else
                        error('msPuff must be scalar real 0<= val <=msPenalty')
                    end

                    if isreal(r.scalar) && isscalar(r.scalar) && r.scalar>=0 && r.scalar<=100 
                        %pass
                    else
                        error('scalar must be >=0 and <=100')
                    end

                    if isreal(r.fractionOpenTimeSoundIsOn) && isscalar(r.fractionOpenTimeSoundIsOn) &&  r.fractionOpenTimeSoundIsOn>=0 && r.fractionOpenTimeSoundIsOn<=1
                        %pass
                    else
                        error('fractionOpenTimeSoundIsOn must be >=0 and <=1')
                    end

                    if isreal(r.fractionPenaltySoundIsOn) && isscalar(r.fractionPenaltySoundIsOn) && r.fractionPenaltySoundIsOn>=0 && r.fractionPenaltySoundIsOn<=1
                        %pass
                    else
                        error('fractionPenaltySoundIsOn must be >=0 and <=1')
                    end
                    if r.requestRewardSizeULorMS>=0 && isreal(r.requestRewardSizeULorMS) && isscalar(r.requestRewardSizeULorMS)
                        %pass
                    else
                        error('requestRewardSizeULorMS must a single real number be >=0')
                    end
                    if ischar(r.requestMode) && (strcmp(r.requestMode,'first') || strcmp(r.requestMode,'nonrepeats') || strcmp(r.requestMode,'all'))
                        %pass
                    else
                        error('requestMode must be ''first'',''nonrepeats'',or ''all''');
                    end

                otherwise
                    error('Wrong number of input arguments')
            end
        end
        
        function [rm updateRM] =cache(rm,trialRecords, subject)

            updateRM=0;
        end
        
        function [rewardSizeULorMS, requestRewardSizeULorMS, msPenalty, msPuff, msRewardSound, msPenaltySound] ...
    = calcCommonValues(r,base,baseRequest)
            rewardSizeULorMS= getScalar(r) * base;
            requestRewardSizeULorMS = getScalar(r) * baseRequest;
            msPenalty=getMsPenalty(r);
            msPuff=getMsPuff(r);
            msRewardSound=rewardSizeULorMS*r.fractionOpenTimeSoundIsOn;
            msPenaltySound=getMsPenalty(r)*r.fractionPenaltySoundIsOn;
        end
        
        function [r rewardSizeULorMS requestRewardSizeULorMS msPenalty msPuff msRewardSound msPenaltySound updateTM] = ...
    calcEarlyPenalty(r,trialRecords, subject)

            %currently only cuedGoNoGo+asymetricReinforcement relies on this, but in principle other tm that punish early responses could use it
            %... if that is the case consider factoring code out of
            %cuedGoNoGo.updateTrialState and into trialmanager.updateTrialState

            updateTM=0;

            %this is an early penalty and so base and base request are forced to 0
            base=0;
            baseRequest=0;
            [rewardSizeULorMS requestRewardSizeULorMS msPenalty msPuff msRewardSound msPenaltySound] = calcCommonValues(r,base,baseRequest);

        end
        
        function d=display(r)
            d=[sprintf('\n\t\t\tmsPenalty:\t\t\t\t\t\t%3.5g',r.msPenalty) ...
               sprintf('\n\t\t\tscalar:\t\t\t\t\t\t%3.3g',r.scalar) ...
               sprintf('\n\t\t\tfractionOpenTimeSoundIsOn:\t%3.3g',r.fractionOpenTimeSoundIsOn) ...
               sprintf('\n\t\t\tfractionPenaltySoundIsOn:\t%3.3g',r.fractionPenaltySoundIsOn) ...
               ];
        end
        
        function out=getFractionOpenTimeSoundIsOn(r)
            out=r.fractionOpenTimeSoundIsOn;
        end
        
        function out=getFractionPenaltySoundIsOn(r)
            out=r.fractionPenaltySoundIsOn;
        end
        
        function immutable=getImmutable(rm)
            %if the rm is immutable then trialManager can't overwrite it with
            %setReinforcementManager.  Default is changeable. i.e. mutable
            error('method defunct') %pmm 090112, can be deleted
            immutable=false;
        end
        
        function out=getMsPenalty(r)
            out=r.msPenalty;
        end
        
        function out=getMsPuff(r)
            out=r.msPuff;
        end
        
        function retval = getRequestMode(rm)
            % this function returns the requestMode field of the base class reinforcementManager
            retval = rm.requestMode;
        end 
        
        function retval = getRequestRewardSizeULorMS(r)
            % returns the requestRewardSizeULorMS field of the base reinforcementManager class
            retval = r.requestRewardSizeULorMS;

        end

   
        function out=getScalar(r)
            out=r.scalar;
        end
        
        function r=setMsPenalty(r, value)
            if all(size(value) == [1 1]) && isnumeric(value) && value>0
               r.msPenalty = value;
            else
                error('scalar must be a number > 0')
            end
        end
        
        function rm=setReinforcementParam(rm,param,val)

            try
                switch param
                    case {'penaltyMS','msPenalty'}
                        rm=setMsPenalty(rm,val);
                    case 'scalar'
                        rm=setScalar(rm,val);
                    case 'rewardULorMS'
                        rm=setRewardSizeULorMS(rm,val);
                    case 'requestRewardSizeULorMS'
                        rm=setRequestRewardSizeULorMS(rm,val);
                    otherwise
                        param
                        error('unrecognized param')
                end
            catch ex
                if strcmp(ex.identifier,'MATLAB:UndefinedFunction')
                    
                    warning(sprintf('can''t set %s for reinforcementManager of this class',param))
                else
                    param=param
                    value=val
                    rethrow(ex)
                end
            end
        end
        
        function r = setRequestRewardSizeULorMS(r,val)
            % sets the requestRewardSizeULorMS field of the base reinforcementManager class
            r.requestRewardSizeULorMS = val;

        end
        
        
        function r=setScalar(r, value)
            if all(size(value) == [1 1]) && isnumeric(value) && value>0
               r.scalar = value;
            else
                error('scalar must be a number > 0')
            end
        end     
        
        
    end
    
end

